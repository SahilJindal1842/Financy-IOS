with open("iOS/FinPilotAI/Sources/Features/Main/MainTabView.swift", "r") as f:
    content = f.read()

old_body = """        .tint(FinPilotColors.primary)
    }"""

new_body = """        .tint(FinPilotColors.primary)
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
    }"""

content = content.replace(old_body, new_body)

with open("iOS/FinPilotAI/Sources/Features/Main/MainTabView.swift", "w") as f:
    f.write(content)

