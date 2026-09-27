import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)
            
            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "banknote")
                }
                .tag(2)
            
            ReportsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(FinPilotColors.primary)
        .onAppear {
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
    }
}
