import SwiftUI

struct MainTabView: View {
    @AppStorage("selectedMainTab") private var selectedTab = 0
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    private var currentColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)
            
            RecurringTransactionsView()
                .tabItem {
                    Label("Recurring", systemImage: "calendar.badge.clock")
                }
                .tag(2)
            
            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "banknote")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .tag(4)
        }
        .tint(FinPilotColors.primary)
        .preferredColorScheme(currentColorScheme)
        .onAppear {
            let hasExplicitFlag = CommandLine.arguments.contains("--tab") ||
                                  CommandLine.arguments.contains("--add-tx") ||
                                  CommandLine.arguments.contains("--reports") ||
                                  CommandLine.arguments.contains("--edit-profile") ||
                                  CommandLine.arguments.contains("--savings")
            if !hasExplicitFlag {
                selectedTab = 0
            }
            if let idx = CommandLine.arguments.firstIndex(of: "--tab"), idx + 1 < CommandLine.arguments.count, let val = Int(CommandLine.arguments[idx + 1]) {
                selectedTab = val
            }
            if CommandLine.arguments.contains("--add-tx") {
                selectedTab = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("FinPilotShowAddTx"), object: nil)
                }
            }
            if CommandLine.arguments.contains("--settle-sheet") {
                selectedTab = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("FinPilotShowMonthSettlement"), object: nil)
                }
            }
            if CommandLine.arguments.contains("--reports") {
                selectedTab = 4
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("FinPilotShowReports"), object: nil)
                }
            }
            if CommandLine.arguments.contains("--edit-profile") {
                selectedTab = 4
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("FinPilotShowEditProfile"), object: nil)
                }
            }
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(FinPilotColors.surface)
            
            // Set unselected colors
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray3
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray3]
            
            // Set selected colors
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(FinPilotColors.primary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(FinPilotColors.primary)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notif in
            if let index = notif.object as? Int {
                withAnimation {
                    selectedTab = index
                }
            }
        }
    }
}
