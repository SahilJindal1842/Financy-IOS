import SwiftUI
import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

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
    
    // Account linking state when existing account collision occurs
    @Published var pendingLinkToken: String? = nil
    @Published var pendingLinkEmail: String? = nil
    @Published var pendingLinkProvider: String? = nil
    @Published var showLinkAccountSheet = false
    
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

    private func firebaseBackendLogin(firebaseUid: String, email: String, name: String? = nil, avatar: String? = nil) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/firebase-login") else { return false }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
            var payload: [String: Any] = [
                "firebaseUid": firebaseUid,
                "email": email
            ]
            if let name = name, !name.isEmpty { payload["name"] = name }
            if let avatar = avatar, !avatar.isEmpty { payload["avatar"] = avatar }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                try KeychainManager.shared.save(token: token, for: "user_token")
                await fetchProfile()
                self.isAuthenticated = true
                return true
            }
        } catch {
            print("Firebase backend login error: \(error)")
        }
        return false
    }

    func login(email: String? = nil, mobile: String? = nil, password: String) async {
        isLoading = true
        error = nil
        
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMobile = mobile?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Try Firebase Authentication if email is provided
        if let userEmail = trimmedEmail, !userEmail.isEmpty {
            do {
                let authResult = try await Auth.auth().signIn(withEmail: userEmail, password: password)
                let backendSuccess = await firebaseBackendLogin(
                    firebaseUid: authResult.user.uid,
                    email: userEmail,
                    name: authResult.user.displayName
                )
                if backendSuccess {
                    isLoading = false
                    return
                }
            } catch {
                print("Firebase signIn failed or user not on Firebase yet: \(error.localizedDescription)")
            }
        }
        
        // 2. Fallback / Standard Backend Login (for pre-existing backend users or mobile logins)
        do {
            guard let url = URL(string: "\(baseURL)/login") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
            var payload: [String: String] = ["password": password]
            if let userEmail = trimmedEmail, !userEmail.isEmpty {
                payload["email"] = userEmail
            } else if let userMobile = trimmedMobile, !userMobile.isEmpty {
                payload["mobile"] = userMobile
                payload["mobile_number"] = userMobile
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    UserDefaults.standard.set(0, forKey: "selectedMainTab")
                    NotificationCenter.default.post(name: .navigateToTab, object: 0)
                    await fetchProfile()
                    isAuthenticated = true
                    
                    // Sync user to Firebase Auth in background so future logins use Firebase
                    if let userEmail = trimmedEmail, !userEmail.isEmpty {
                        Task {
                            try? await Auth.auth().createUser(withEmail: userEmail, password: password)
                        }
                    }
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
        
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMobile = mobile?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Standard backend signup: generates OTP and dispatches to email via Supabase/SMTP
        do {
            guard let url = URL(string: "\(baseURL)/signup") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
            var payload: [String: String] = [
                "name": fullName,
                "fullName": fullName,
                "password": password
            ]
            if let userEmail = trimmedEmail, !userEmail.isEmpty {
                payload["email"] = userEmail
            }
            if let userMobile = trimmedMobile, !userMobile.isEmpty {
                payload["mobile"] = userMobile
                payload["mobile_number"] = userMobile
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                self.signupEmail = trimmedEmail ?? ""
                self.signupMobile = trimmedMobile ?? ""
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
        
        // 1. Attempt Firebase Authentication for this social account
        let dummyPassword = "FirebaseSocial_2026!"
        do {
            let authResult = try? await Auth.auth().signIn(withEmail: email, password: dummyPassword)
            if authResult == nil {
                _ = try? await Auth.auth().createUser(withEmail: email, password: dummyPassword)
            }
        } catch {
            print("Firebase social auth attempt: \(error)")
        }
        
        // 2. Complete backend social login/signup
        do {
            guard let url = URL(string: "\(baseURL)/social-login") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
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
                    UserDefaults.standard.set(0, forKey: "selectedMainTab")
                    NotificationCenter.default.post(name: .navigateToTab, object: 0)
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
            request.timeoutInterval = 60
            
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
            request.timeoutInterval = 60
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
            try? Auth.auth().signOut()
            try KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(false, forKey: "hasSeenSplashScreen")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            currentUser = nil
            signupEmail = ""
            isAuthenticated = false
            currentFlow = .login
            NotificationCenter.default.post(name: .userLoggedOut, object: nil)
        } catch {
            print("Failed to logout: \(error)")
        }
    }

    
    func updateProfile(
        name: String,
        currency: String,
        monthlyIncome: String,
        primaryGoal: String,
        avatar: String? = nil,
        email: String? = nil,
        mobileNumber: String? = nil,
        savingsTarget: String? = nil,
        notificationsEnabled: Bool? = nil,
        biometricsEnabled: Bool? = nil
    ) async -> Bool {
        isLoading = true
        error = nil
        do {
            var payload: [String: Any] = [
                "name": name,
                "currency": currency,
                "monthlyIncome": monthlyIncome,
                "primaryGoal": primaryGoal
            ]
            if let avatar = avatar {
                payload["avatar"] = avatar
            }
            if let email = email, !email.isEmpty {
                payload["email"] = email
            }
            if let mobileNumber = mobileNumber {
                payload["mobileNumber"] = mobileNumber
            }
            if let savingsTarget = savingsTarget, !savingsTarget.isEmpty {
                payload["savingsTarget"] = savingsTarget
            }
            if let notif = notificationsEnabled {
                payload["notificationsEnabled"] = notif
            }
            if let bio = biometricsEnabled {
                payload["biometricsEnabled"] = bio
            }
            
            let data = try JSONSerialization.data(withJSONObject: payload)
            
            struct UpdateProfileResponse: Decodable {
                let message: String?
            }
            let _: UpdateProfileResponse = try await APIManager.shared.request(endpoint: "/users/profile", method: "PUT", body: data)
            
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
    
    func deleteAccount() async -> Bool {
        isLoading = true
        error = nil
        do {
            struct DelRes: Codable {
                let success: Bool?
                let message: String?
            }
            let _: DelRes = try await APIManager.shared.request(endpoint: "/users/profile", method: "DELETE")
            logout()
            isLoading = false
            return true
        } catch {
            print("Failed to delete account: \(error)")
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func subscribe() async -> Bool {
        isLoading = true
        error = nil
        do {
            struct SubResponse: Codable {
                let success: Bool?
                let message: String?
            }
            let _: SubResponse = try await APIManager.shared.request(endpoint: "/users/subscribe", method: "POST")
            await fetchProfile()
            isLoading = false
            return true
        } catch {
            print("Failed to subscribe: \(error)")
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    var isSubscribed: Bool {
        currentUser?.isSubscribed ?? false
    }
    
    var isTrialExpired: Bool {
        currentUser?.isTrialExpired ?? false
    }
    
    var trialDaysRemaining: Int {
        currentUser?.trialDaysRemaining ?? 7
    }
    
    func resendOTP() async {
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(baseURL)/signup") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
            var payload: [String: String] = [
                "name": "User",
                "password": "Password123!"
            ]
            if !signupEmail.isEmpty { payload["email"] = signupEmail }
            if !signupMobile.isEmpty { payload["mobile_number"] = signupMobile }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                // OTP resent successfully via email
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? "Failed to resend code."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Social Authentication Actions
    func startSocialAuth(provider: String) {
        let normalized = provider.lowercased()
        isLoading = true
        error = nil
        
        Task {
            if normalized.contains("apple") {
                await self.authenticateWithApple()
            } else if normalized.contains("google") {
                await self.authenticateWithGoogle()
            } else if normalized.contains("facebook") {
                await self.authenticateWithFacebook()
            }
        }
    }
    
    func authenticateWithApple() async {
        isLoading = true
        error = nil
        do {
            let creds = try await SocialAuthManager.shared.signInWithApple()
            var payload: [String: Any] = [
                "identityToken": creds.identityToken,
                "userIdentifier": creds.userIdentifier
            ]
            if let fullName = creds.fullName {
                payload["fullName"] = fullName
            }
            if let email = creds.email {
                payload["email"] = email
            }
            await self.sendSocialAuthRequest(endpoint: "/apple", payload: payload, providerName: "Apple")
        } catch {
            isLoading = false
            let nsErr = error as NSError
            if nsErr.domain == ASAuthorizationErrorDomain && nsErr.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            self.error = "Apple Sign In: \(error.localizedDescription)"
        }
    }
    
    func authenticateWithGoogle() async {
        isLoading = true
        error = nil
        do {
            let idToken = try await SocialAuthManager.shared.signInWithGoogle()
            let payload: [String: Any] = ["idToken": idToken]
            await self.sendSocialAuthRequest(endpoint: "/google", payload: payload, providerName: "Google")
        } catch {
            isLoading = false
            let nsErr = error as NSError
            if nsErr.domain == "com.google.GIDSignIn" && nsErr.code == -5 {
                return
            }
            self.error = "Google Sign In: \(error.localizedDescription)"
        }
    }
    
    func authenticateWithFacebook() async {
        isLoading = true
        error = nil
        do {
            let accessToken = try await SocialAuthManager.shared.signInWithFacebook()
            let payload: [String: Any] = ["accessToken": accessToken]
            await self.sendSocialAuthRequest(endpoint: "/facebook", payload: payload, providerName: "Facebook")
        } catch {
            isLoading = false
            let nsErr = error as NSError
            if nsErr.domain == ASWebAuthenticationSessionErrorDomain && nsErr.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                return
            }
            self.error = "Facebook Sign In: \(error.localizedDescription)"
        }
    }
    
    private func sendSocialAuthRequest(endpoint: String, payload: [String: Any], providerName: String) async {
        do {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    UserDefaults.standard.set(0, forKey: "selectedMainTab")
                    NotificationCenter.default.post(name: .navigateToTab, object: 0)
                    await fetchProfile()
                    await EntitlementManager.shared.checkEntitlement()
                    self.isAuthenticated = true
                } else {
                    self.error = "Invalid response format from server."
                }
            } else if httpResponse.statusCode == 409 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let linkToken = json["linkToken"] as? String {
                    self.pendingLinkToken = linkToken
                    self.pendingLinkEmail = json["email"] as? String
                    self.pendingLinkProvider = json["provider"] as? String ?? providerName
                    self.showLinkAccountSheet = true
                } else {
                    self.error = "An account with this email already exists."
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "\(providerName) sign in failed."
                } else {
                    self.error = "\(providerName) sign in failed."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func submitLinkAccount(password: String) async {
        guard let linkToken = pendingLinkToken else { return }
        isLoading = true
        error = nil
        do {
            guard let url = URL(string: "\(baseURL)/link-account") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60
            
            let payload: [String: String] = [
                "linkToken": linkToken,
                "password": password
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    try KeychainManager.shared.save(token: token, for: "user_token")
                    self.pendingLinkToken = nil
                    self.pendingLinkEmail = nil
                    self.pendingLinkProvider = nil
                    self.showLinkAccountSheet = false
                    UserDefaults.standard.set(0, forKey: "selectedMainTab")
                    NotificationCenter.default.post(name: .navigateToTab, object: 0)
                    await fetchProfile()
                    await EntitlementManager.shared.checkEntitlement()
                    self.isAuthenticated = true
                } else {
                    self.error = "Invalid server response."
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.error = (json["error"] as? String) ?? (json["message"] as? String) ?? "Password verification failed."
                } else {
                    self.error = "Password verification failed."
                }
            }
        } catch {
            self.error = "Network Error: \(error.localizedDescription)"
        }
        isLoading = false
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

// MARK: - Native Social Authentication Manager
struct AppleCredentials {
    let identityToken: String
    let userIdentifier: String
    let fullName: [String: String]?
    let email: String?
}

@MainActor
final class SocialAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = SocialAuthManager()
    
    private var webAuthSession: ASWebAuthenticationSession?
    private var appleCompletion: ((Result<AppleCredentials, Error>) -> Void)?
    
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow }) ?? scenes.flatMap { $0.windows }.first ?? UIWindow()
                return window
            }
        } else {
            return DispatchQueue.main.sync {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow }) ?? scenes.flatMap { $0.windows }.first ?? UIWindow()
                return window
            }
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow }) ?? scenes.flatMap { $0.windows }.first ?? UIWindow()
        return window
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() async throws -> AppleCredentials {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            self.appleCompletion = { result in
                continuation.resume(with: result)
            }
            controller.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let cred = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let tokenData = cred.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                appleCompletion?(.failure(NSError(domain: "AppleAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to read Apple identity token"])))
                appleCompletion = nil
                return
            }
            
            var nameDict: [String: String]? = nil
            if let fullName = cred.fullName {
                var dict: [String: String] = [:]
                if let given = fullName.givenName { dict["givenName"] = given }
                if let family = fullName.familyName { dict["familyName"] = family }
                if !dict.isEmpty { nameDict = dict }
            }
            
            let credentials = AppleCredentials(
                identityToken: identityToken,
                userIdentifier: cred.user,
                fullName: nameDict,
                email: cred.email
            )
            appleCompletion?(.success(credentials))
        } else {
            appleCompletion?(.failure(NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-in failed"])))
        }
        appleCompletion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleCompletion?(.failure(error))
        appleCompletion = nil
    }
    
    // MARK: - Sign in with Google (Official GoogleSignIn SDK)
    func signInWithGoogle() async throws -> String {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active view controller found for Google Sign In"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract Google ID token"])
        }
        return idToken
    }
    
    // MARK: - Sign in with Facebook (Secure Meta OAuth Dialog)
    func signInWithFacebook() async throws -> String {
        let callbackScheme = "financy"
        let redirectURI = "financy://oauth-callback"
        let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        let fbAppId = "1067204895180000" // Financy Meta App ID
        let urlString = "https://www.facebook.com/v19.0/dialog/oauth?client_id=\(fbAppId)&redirect_uri=\(encodedRedirect)&response_type=token&scope=email,public_profile"
        guard let authURL = URL(string: urlString) else {
            throw NSError(domain: "FacebookAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Facebook auth URL"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callback = callbackURL else {
                    continuation.resume(throwing: NSError(domain: "FacebookAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "No callback received"]))
                    return
                }
                
                var token: String? = nil
                if let fragment = callback.fragment {
                    let items = fragment.components(separatedBy: "&")
                    for item in items {
                        let pair = item.components(separatedBy: "=")
                        if pair.count == 2 && pair[0] == "access_token" {
                            token = pair[1]
                            break
                        }
                    }
                }
                
                if token == nil, let comps = URLComponents(url: callback, resolvingAgainstBaseURL: false) {
                    token = comps.queryItems?.first(where: { $0.name == "access_token" })?.value
                }
                
                if let validToken = token, !validToken.isEmpty {
                    continuation.resume(returning: validToken)
                } else {
                    continuation.resume(throwing: NSError(domain: "FacebookAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to extract Facebook access token"]))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }
    }
}
