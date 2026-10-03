import SwiftUI
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Auth States for the UI flow
    enum AuthFlow {
        case login
        case signupStep1
        case signupStep2 // OTP
        case signupStep3 // Profile
    }
    
    @Published var currentFlow: AuthFlow = .login
    @Published var signupEmail = ""
    @Published var signupMobile = ""
    @Published var currentUser: User? = nil
    
    // Internal user states as requested
    enum UserState: String {
        case pendingEmailVerification = "PENDING_EMAIL_VERIFICATION"
        case emailVerified = "EMAIL_VERIFIED"
        case profileCompleted = "PROFILE_COMPLETED"
    }
    
    private let baseURL = NetworkConfig.authBaseURL

    init() {
        checkAuthStatus()
    }

    func login(email: String? = nil, mobile: String? = nil, password: String) async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/login") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            
            var payload: [String: String] = ["password": password]
            if let email = email, !email.isEmpty {
                payload["email"] = email
            } else if let mobile = mobile, !mobile.isEmpty {
                payload["mobile"] = mobile
                payload["mobile_number"] = mobile
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    await fetchProfile()
                    isAuthenticated = true
                } else {
                    self.error = "Invalid response format from server."
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "Invalid credentials."
                } else {
                    self.error = "Invalid credentials."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func signup(fullName: String, email: String? = nil, mobile: String? = nil, password: String) async {
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(baseURL)/signup") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            
            var payload: [String: String] = [
                "name": fullName,
                "fullName": fullName,
                "password": password
            ]
            if let email = email, !email.isEmpty {
                payload["email"] = email
            }
            if let mobile = mobile, !mobile.isEmpty {
                payload["mobile"] = mobile
                payload["mobile_number"] = mobile
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                self.signupEmail = email ?? ""
                self.signupMobile = mobile ?? ""
                self.currentFlow = .signupStep2
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "Signup failed."
                } else {
                    self.error = "Signup failed."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func socialLogin(provider: String, email: String, name: String, avatar: String? = nil) async {
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(baseURL)/social-login") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            
            var payload: [String: String] = [
                "provider": provider,
                "email": email,
                "name": name
            ]
            if let avatar = avatar {
                payload["avatar"] = avatar
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    await fetchProfile()
                    self.isAuthenticated = true
                } else {
                    self.error = "Invalid server response."
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "Social login failed."
                } else {
                    self.error = "Social login failed."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func verifyOTP(code: String) async {
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(baseURL)/verify-otp") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            
            var payload: [String: String] = [
                "otp": code
            ]
            if !signupEmail.isEmpty {
                payload["email"] = signupEmail
            } else if !signupMobile.isEmpty {
                payload["mobile_number"] = signupMobile
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                }
                self.currentFlow = .signupStep3
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "OTP verification failed."
                } else {
                    self.error = "OTP verification failed."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func completeProfile(currency: String, monthlyIncome: String, primaryGoal: String, avatar: String? = nil) async {
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(NetworkConfig.baseURLString)/users/profile") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            if let token = try? KeychainManager.shared.getToken(for: "user_token") {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            var payload: [String: String] = [
                "currency": currency,
                "monthlyIncome": monthlyIncome,
                "primaryGoal": primaryGoal
            ]
            if let avatar = avatar {
                payload["avatar"] = avatar
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                await fetchProfile()
                self.isAuthenticated = true
            } else {
                await fetchProfile()
                self.isAuthenticated = true 
            }
        } catch {
            await fetchProfile()
            self.isAuthenticated = true
        }
        isLoading = false
    }
    
    func fetchProfile() async {
        guard let token = try? KeychainManager.shared.getToken(for: "user_token"), !token.isEmpty else {
            return
        }
        do {
            guard let url = URL(string: "\(NetworkConfig.baseURLString)/users/profile") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            struct ProfileResponse: Codable {
                let user: User
            }
            
            let decoder = JSONDecoder.appDecoder
            if let decoded = try? decoder.decode(ProfileResponse.self, from: data) {
                self.currentUser = decoded.user
            }
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }
    
    func logout() {
        do {
            try KeychainManager.shared.deleteToken(for: "user_token")
            currentUser = nil
            signupEmail = ""
            isAuthenticated = false
            currentFlow = .login
            NotificationCenter.default.post(name: .userLoggedOut, object: nil)
        } catch {
            print("Failed to logout: \(error)")
        }
    }
    
    func updateProfile(name: String, currency: String, monthlyIncome: String, primaryGoal: String, avatar: String? = nil) async -> Bool {
        isLoading = true
        error = nil
        do {
            var payload: [String: String] = [
                "name": name,
                "currency": currency,
                "monthlyIncome": monthlyIncome,
                "primaryGoal": primaryGoal
            ]
            if let avatar = avatar {
                payload["avatar"] = avatar
            }
            let data = try JSONSerialization.data(withJSONObject: payload)
            
            // Re-use completeProfile endpoint which does PUT /users/profile
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await APIManager.shared.request(endpoint: "/users/profile", method: "PUT", body: data)
            
            await fetchProfile()
            isLoading = false
            return true
        } catch {
            print("Failed to update profile: \(error)")
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func checkAuthStatus() {
        if let token = try? KeychainManager.shared.getToken(for: "user_token"), !token.isEmpty {
            isAuthenticated = true
            Task {
                await fetchProfile()
            }
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
}
