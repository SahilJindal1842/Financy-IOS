// xcode: set sdk=iOS

import SwiftUI

@main
struct FinPilotAIApp: App {
    init() {
        // Keeps user on Login/Sign Up after clicking Get Started
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .preferredColorScheme(.light)
        }
    }
}

struct AppCoordinatorView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
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
        .animation(.easeInOut(duration: 0.4), value: hasSeenSplashScreen)
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}
