// xcode: set sdk=iOS

import SwiftUI
import FirebaseCore

@main
struct FinPilotAIApp: App {
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        if CommandLine.arguments.contains("--logout") || CommandLine.arguments.contains("--trial-login") || CommandLine.arguments.contains("--admin-login") || CommandLine.arguments.contains("--demo-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(false, forKey: "hasSeenSplashScreen")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
        }
        let vm = AuthViewModel()
        if CommandLine.arguments.contains("--logout") {
            vm.logout()
        }
        _authViewModel = StateObject(wrappedValue: vm)
        
        if let idx = CommandLine.arguments.firstIndex(of: "--tab"), idx + 1 < CommandLine.arguments.count, let val = Int(CommandLine.arguments[idx + 1]) {
            UserDefaults.standard.set(val, forKey: "selectedMainTab")
        }
        if CommandLine.arguments.contains("--add-category") {

            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 4)
                NotificationCenter.default.post(name: .showAddCategory, object: nil)
            }
        }
        if CommandLine.arguments.contains("--set-budget") {
            UserDefaults.standard.set(3, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 3)
                NotificationCenter.default.post(name: .showSetBudget, object: nil)
            }
        }
        if CommandLine.arguments.contains("--savings") {
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 4)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowSavings"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--add-tx") {
            UserDefaults.standard.set(1, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 1)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowAddTx"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--settle-sheet") {
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 0)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowMonthSettlement"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--reports") {
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 4)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowReports"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--income") {
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 0)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowIncomeDrillDown"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--edit-profile") {

            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToTab, object: 4)
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowEditProfile"), object: nil)
            }
        }
        if CommandLine.arguments.contains("--test-google-signup") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                Task {
                    await vm.socialLogin(provider: "google", email: "dummy_google_user@financy.app", name: "Google Test User")
                }
            }
        }
        if CommandLine.arguments.contains("--test-facebook-signup") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                Task {
                    await vm.socialLogin(provider: "facebook", email: "dummy_facebook_user@financy.app", name: "Facebook Test User")
                }
            }
        }
        if CommandLine.arguments.contains("--test-user-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await vm.login(email: "sahil@yopmail.com", password: "password")
                }
            }
        }
        if CommandLine.arguments.contains("--demo-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await vm.login(email: "demo@financy.app", password: "Password@123")
                }
            }
        }
        if CommandLine.arguments.contains("--trial-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await vm.login(email: "trialtest@yopmail.com", password: "Password@123")
                }
            }
        }
        if CommandLine.arguments.contains("--admin-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await vm.login(email: "admin@financy.app", password: "Admin@123")
                }
            }
        }
        if CommandLine.arguments.contains("--auth-login") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            vm.logout()
            UserDefaults.standard.set(true, forKey: "hasSeenSplashScreen")
            vm.currentFlow = .login
        }
        if CommandLine.arguments.contains("--auth-google-sheet") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(true, forKey: "hasSeenSplashScreen")
            vm.currentFlow = .signupStep1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowSocialSheet"), object: "Google")
            }
        }
        if CommandLine.arguments.contains("--test-signup-otp") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(true, forKey: "hasSeenSplashScreen")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await vm.signup(fullName: "Dev Tester", email: "tester\(Int.random(in: 1000...9999))@yopmail.com", password: "Password123!")
                }
            }
        }
        if CommandLine.arguments.contains("--test-social-google") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(true, forKey: "hasSeenSplashScreen")
            vm.currentFlow = .login
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                vm.startSocialAuth(provider: "Google")
            }
        }
        if CommandLine.arguments.contains("--test-social-apple") {
            try? KeychainManager.shared.deleteToken(for: "user_token")
            UserDefaults.standard.removeObject(forKey: "user_token")
            UserDefaults.standard.set(true, forKey: "hasSeenSplashScreen")
            vm.currentFlow = .login
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                vm.startSocialAuth(provider: "Apple")
            }
        }
    }
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    private var currentColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(authViewModel)
                .preferredColorScheme(currentColorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        let host = url.host?.lowercased() ?? ""
        
        switch host {
        case "admin":
            Task {
                await authViewModel.login(email: "admin@financy.app", password: "Admin@123")
            }
        case "user":
            Task {
                await authViewModel.login(email: "sahil@yopmail.com", password: "password")
            }
        case "tab":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let indexStr = components.queryItems?.first(where: { $0.name == "index" })?.value,
               let index = Int(indexStr) {
                UserDefaults.standard.set(index, forKey: "selectedMainTab")
                NotificationCenter.default.post(name: .navigateToTab, object: index)
            }
        case "categories":
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showManageCategories, object: nil)
            }
        case "add-recurring":
            UserDefaults.standard.set(2, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 2)
            let focus = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "focus" })?.value
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showAddRecurring, object: focus)
            }
        case "add-category":
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showAddCategory, object: nil)
            }
        case "set-budget-all":
            UserDefaults.standard.set(3, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .showSetBudget, object: "all")
            }
        case "set-budget":
            UserDefaults.standard.set(3, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 3)
            let modeParam: String?
            if let q = url.query, q.contains("mode=all") {
                modeParam = "all"
            } else {
                modeParam = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "mode" })?.value
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showSetBudget, object: modeParam)
            }
        case "add-transaction":
            UserDefaults.standard.set(1, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowAddTx"), object: nil)
            }
        case "settle-sheet":
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowMonthSettlement"), object: nil)
            }
        case "reports":
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowReports"), object: nil)
            }
        case "edit-profile":
            UserDefaults.standard.set(4, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowEditProfile"), object: nil)
            }
        case "income":
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowIncomeDrillDown"), object: nil)
            }
        case "expense":
            UserDefaults.standard.set(0, forKey: "selectedMainTab")
            NotificationCenter.default.post(name: .navigateToTab, object: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: Notification.Name("FinPilotShowExpenseDrillDown"), object: nil)
            }
        case "paywall":
            NotificationCenter.default.post(name: .showPaywall, object: nil)
        case "purchase":
            Task {
                _ = await PurchaseManager.shared.purchaseLifetime()
            }
        case "restore":
            Task {
                _ = await PurchaseManager.shared.restorePurchases()
            }
        case "refresh-entitlement":
            Task {
                await EntitlementManager.shared.checkEntitlement(userId: authViewModel.currentUser?.id)
            }
        case "logout":
            authViewModel.logout()
        default:
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                let queryItems = components.queryItems ?? []
                let email = queryItems.first(where: { $0.name == "email" })?.value
                let password = queryItems.first(where: { $0.name == "password" })?.value
                if let email = email, let password = password {
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                }
            }
        }
    }
}

struct AppCoordinatorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    private var currentColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                if entitlementManager.state == .trialExpired {
                    LifetimePremiumPaywallView(isMandatory: true)
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                }
            } else if !hasSeenSplashScreen {
                SplashView(hasSeenSplash: $hasSeenSplashScreen)
                    .environmentObject(authViewModel)
                    .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading)))
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .preferredColorScheme(currentColorScheme)
        .animation(.easeInOut(duration: 0.4), value: hasSeenSplashScreen)
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: entitlementManager.state)
        .task(id: authViewModel.currentUser?.id) {
            if authViewModel.isAuthenticated {
                await entitlementManager.checkEntitlement(userId: authViewModel.currentUser?.id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
            hasSeenSplashScreen = false
            entitlementManager.clearCacheOnLogout()
        }
    }
}

