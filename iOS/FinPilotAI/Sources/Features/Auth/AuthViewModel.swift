import SwiftUI
import Foundation
import FirebaseAuth
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var devOTP: String? = nil
    
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

    private func firebaseBackendLogin(firebaseUid: String, email: String, name: String? = nil, avatar: String? = nil) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/firebase-login") else { return false }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            
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
            request.timeoutInterval = 15
            
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
        
        // 1. Try Firebase Authentication Sign-up if email is provided
        if let userEmail = trimmedEmail, !userEmail.isEmpty {
            do {
                let authResult = try await Auth.auth().createUser(withEmail: userEmail, password: password)
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try? await changeRequest.commitChanges()
                
                let backendSuccess = await firebaseBackendLogin(
                    firebaseUid: authResult.user.uid,
                    email: userEmail,
                    name: fullName
                )
                if backendSuccess {
                    self.signupEmail = userEmail
                    self.signupMobile = trimmedMobile ?? ""
                    self.currentFlow = .signupStep3
                    isLoading = false
                    return
                }
            } catch {
                print("Firebase createUser note: \(error.localizedDescription)")
                let msg = error.localizedDescription
                if msg.localizedCaseInsensitiveContains("already in use") {
                    self.error = "This email is already in use. Please log in instead."
                    isLoading = false
                    return
                }
            }
        }
        
        // 2. Fallback to standard backend OTP signup
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
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let otpCode = json["otp"] as? String {
                    self.devOTP = otpCode
                } else {
                    self.devOTP = nil
                }
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
            request.timeoutInterval = 15
            
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
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["otp"] as? String {
                    self.devOTP = code
                }
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

    func startSocialAuth(provider: String) {
        let normalized = provider.lowercased()
        isLoading = true
        error = nil
        
        Task {
            if normalized.contains("apple") {
                do {
                    let (email, name) = try await SocialAuthManager.shared.signInWithApple()
                    await self.socialLogin(provider: "apple", email: email, name: name)
                } catch {
                    self.isLoading = false
                    let nsErr = error as NSError
                    if nsErr.domain == ASAuthorizationErrorDomain && nsErr.code == ASAuthorizationError.canceled.rawValue {
                        return
                    }
                    self.error = "Apple Sign In: \(error.localizedDescription)"
                }
            } else {
                do {
                    let (email, name) = try await SocialAuthManager.shared.signInWithWebOAuth(provider: normalized)
                    await self.socialLogin(provider: normalized, email: email, name: name)
                } catch {
                    self.isLoading = false
                    let nsErr = error as NSError
                    if nsErr.domain == ASWebAuthenticationSessionErrorDomain && nsErr.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return
                    }
                    self.error = "\(provider) Sign In: \(error.localizedDescription)"
                }
            }
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

// MARK: - Native & Web Social Authentication Manager
@MainActor
final class SocialAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = SocialAuthManager()
    
    private var webAuthSession: ASWebAuthenticationSession?
    private var appleCompletion: ((Result<(String, String), Error>) -> Void)?
    
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
    func signInWithApple() async throws -> (String, String) {
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
            let email = cred.email ?? "apple_user_\(cred.user.prefix(6))@privaterelay.appleid.com"
            let first = cred.fullName?.givenName ?? ""
            let last = cred.fullName?.familyName ?? ""
            let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            let finalName = name.isEmpty ? "Apple User" : name
            appleCompletion?(.success((email, finalName)))
        } else {
            appleCompletion?(.failure(NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign-in failed"])))
        }
        appleCompletion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleCompletion?(.failure(error))
        appleCompletion = nil
    }
    
    // MARK: - Sign in with Google / Facebook via Web Redirection
    func signInWithWebOAuth(provider: String) async throws -> (String, String) {
        let normalized = provider.lowercased()
        let authURL: URL
        let callbackScheme = "financy"
        
        if normalized.contains("google") {
            let redirectURI = "financy://oauth-callback"
            let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
            let urlString = "https://accounts.google.com/o/oauth2/v2/auth?client_id=427668842020-ios.apps.googleusercontent.com&redirect_uri=\(encodedRedirect)&response_type=token%20id_token&scope=email%20profile%20openid&prompt=select_account"
            authURL = URL(string: urlString) ?? URL(string: "https://accounts.google.com")!
        } else {
            let redirectURI = "financy://oauth-callback"
            let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
            let urlString = "https://www.facebook.com/v19.0/dialog/oauth?client_id=1067204895180000&redirect_uri=\(encodedRedirect)&response_type=token&scope=email,public_profile"
            authURL = URL(string: urlString) ?? URL(string: "https://m.facebook.com")!
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var email: String? = nil
                var name: String? = nil
                if let callback = callbackURL, let comps = URLComponents(url: callback, resolvingAgainstBaseURL: false) {
                    email = comps.queryItems?.first(where: { $0.name == "email" })?.value
                    name = comps.queryItems?.first(where: { $0.name == "name" })?.value
                }
                
                let defaultName = normalized.contains("google") ? "Google User" : "Facebook User"
                let defaultEmail = normalized.contains("google") ? "google_user@gmail.com" : "facebook_user@facebook.com"
                
                continuation.resume(returning: (email ?? defaultEmail, name ?? defaultName))
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }
    }
}
