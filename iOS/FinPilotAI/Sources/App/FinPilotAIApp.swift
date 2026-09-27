// xcode: set sdk=iOS

import SwiftUI

@main
struct FinPilotAIApp: App {
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .preferredColorScheme(.light)
        }
    }
}

struct AppCoordinatorView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.isAuthenticated {
            MainTabView()
                .environmentObject(authViewModel)
        } else {
            AuthView()
                .environmentObject(authViewModel)
        }
    }
}
