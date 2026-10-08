import PhotosUI

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appTheme") private var appTheme: String = "system"
    @State private var showAddCategorySheet = false
    @State private var showPaywall = false
    @State private var showManageCategoriesSheet = false
    @State private var showSavingsSheet = false
    @State private var showDeleteAccountConfirm = false
    @State private var showReportsSheet = false
    @State private var showEditProfileSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Green Background
                    ZStack(alignment: .bottom) {
                        // Dark Green Extended Header
                        FinPilotColors.primaryDark
                            .frame(height: 250)
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack(spacing: 12) {
                            if let avatarStr = authViewModel.currentUser?.avatar, !avatarStr.isEmpty {
                                if avatarStr.starts(with: "/") {
                                    let fullUrlStr = NetworkConfig.baseURLString.replacingOccurrences(of: "/api", with: "") + avatarStr
                                    AsyncImage(url: URL(string: fullUrlStr)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                } else if let data = Data(base64Encoded: avatarStr), let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(FinPilotTypography.title2)
                                .foregroundColor(.white)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(FinPilotTypography.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 60)
                        
                        // Overlapping Financial Health Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Financial Health")
                                    .font(FinPilotTypography.subheadline)
                                    .foregroundColor(FinPilotColors.textSecondary)
                                Text("Good")
                                    .font(FinPilotTypography.headline)
                                    .foregroundColor(FinPilotColors.success)
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(FinPilotColors.success)
                        }
                        .padding(20)
                        .background(FinPilotColors.surface)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        .offset(y: 40) // Overlap the header
                    }
                    .padding(.bottom, 60) // Space for the overlapping card
                    
                    // Subscription & Trial Status Card
                    trialStatusCard
                    
                    // Settings List
                    VStack(spacing: 16) {
                        // Appearance & Dark Mode Selector
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: appTheme == "dark" ? "moon.fill" : (appTheme == "light" ? "sun.max.fill" : "circle.righthalf.filled"))
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                    .frame(width: 40, height: 40)
                                    .background(Color.purple.opacity(0.15))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Appearance")
                                        .font(FinPilotTypography.headline)
                                        .foregroundColor(FinPilotColors.textPrimary)
                                    Text(appTheme == "system" ? "Device System Mode" : (appTheme == "dark" ? "Dark Mode" : "Light Mode"))
                                        .font(FinPilotTypography.caption)
                                        .foregroundColor(FinPilotColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Picker("Theme", selection: $appTheme) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(FinPilotColors.surface)
                        .cornerRadius(16)
                        
                        NavigationLink(destination: SavingsModuleView()) {
                            SettingsRow(icon: "banknote.fill", title: "Savings Module & Reserves", color: .teal)
                        }
                        NavigationLink(destination: MonthlyExpenseReportsView()) {
                            SettingsRow(icon: "doc.text.magnifyingglass", title: "Monthly Expense Reports", color: .indigo)
                        }
                        NavigationLink(destination: ReportsView()) {
                            SettingsRow(icon: "sparkles", title: "AI Insights", color: .indigo)
                        }
                        NavigationLink(destination: EditProfileView()) {
                            SettingsRow(icon: "person.fill", title: "Account & Profile", color: .blue)
                        }
                        Button(action: { showAddCategorySheet = true }) {
                            SettingsRow(icon: "plus.circle.fill", title: "Create New Category", color: .green)
                        }
                        NavigationLink(destination: ManageCategoriesView()) {
                            SettingsRow(icon: "list.bullet", title: "Manage Categories", color: .pink)
                        }
                        NavigationLink(destination: NotificationsView()) {
                            SettingsRow(icon: "bell.fill", title: "Activity Notifications", color: .orange)
                        }
                        Button(action: {
                            exportData()
                        }) {
                            SettingsRow(icon: "arrow.down.doc.fill", title: "Export Data", color: .purple)
                        }
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                        NavigationLink(destination: AboutView()) {
                            SettingsRow(icon: "info.circle.fill", title: "About", color: .gray)
                        }
                        
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.title3)
                                    .foregroundColor(FinPilotColors.error)
                                    .frame(width: 40, height: 40)
                                    .background(FinPilotColors.error.opacity(0.15))
                                    .clipShape(Circle())
                                
                                Text("Log Out")
                                    .font(FinPilotTypography.headline)
                                    .foregroundColor(FinPilotColors.error)
                                
                                Spacer()
                            }
                            .padding()
                            .background(FinPilotColors.surface)
                            .cornerRadius(16)
                        }
                        
                        Button(action: {
                            showDeleteAccountConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Circle())
                                
                                Text("Delete Account")
                                    .font(FinPilotTypography.subheadline)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding()
                            .background(FinPilotColors.surface)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .alert(isPresented: $showDeleteAccountConfirm) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your Financy account? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete Account")) {
                        Task {
                            _ = await authViewModel.deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddCategorySheet) {
                NavigationView {
                    EditCategoryView(category: nil as Category?, onUpdate: { })
                }
            }
            .sheet(isPresented: $showPaywall) {
                LifetimePremiumPaywallView(isMandatory: false)
            }
            .sheet(isPresented: $showManageCategoriesSheet) {
                NavigationView {
                    ManageCategoriesView()
                }
            }
            .sheet(isPresented: $showSavingsSheet) {
                NavigationView {
                    SavingsModuleView()
                }
            }
            .sheet(isPresented: $showReportsSheet) {
                NavigationView {
                    MonthlyExpenseReportsView()
                }
            }
            .sheet(isPresented: $showEditProfileSheet) {
                NavigationView {
                    EditProfileView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showManageCategories)) { _ in
                showManageCategoriesSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { _ in
                showPaywall = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .showAddCategory)) { _ in
                showAddCategorySheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowSavings"))) { _ in
                showSavingsSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowReports"))) { _ in
                showReportsSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowEditProfile"))) { _ in
                showEditProfileSheet = true
            }
        }
    }
    
    private var trialStatusCard: some View {
        Group {
            if authViewModel.isSubscribed {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#FFD700").opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#FF9900"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Financy Pro Lifetime")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("All features unlocked forever")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    
                    Spacer()
                        
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(FinPilotColors.primary)
                        .font(.system(size: 22))
                }
                .padding(14)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            } else {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(authViewModel.isTrialExpired ? Color.red.opacity(0.15) : FinPilotColors.primary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: authViewModel.isTrialExpired ? "exclamationmark.shield.fill" : "gift.fill")
                            .font(.system(size: 20))
                            .foregroundColor(authViewModel.isTrialExpired ? .red : FinPilotColors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authViewModel.isTrialExpired ? "7-Day Free Trial Expired" : "\(authViewModel.trialDaysRemaining) Days Left in Free Trial")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text(authViewModel.isTrialExpired ? "Subscribe for $9.99 lifetime" : "One-time $9.99 for lifetime access")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showPaywall = true }) {
                        Text("Upgrade")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(authViewModel.isTrialExpired ? Color.red : FinPilotColors.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(14)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(authViewModel.isTrialExpired ? Color.red.opacity(0.3) : FinPilotColors.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func exportData() {
        Task {
            do {
                let txs: [Transaction] = try await APIManager.shared.request(endpoint: "/transactions")
                
                var csvString = "Expense Date,Category,Note,Amount\n"
                
                let dateFormatter = DateFormatter()
                // Convert from ISO or decode directly? tx.date is a Date object.
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                for tx in txs {
                    let dateStr = dateFormatter.string(from: tx.date)
                    let categoryStr = (tx.categoryId ?? "Uncategorized").replacingOccurrences(of: "\"", with: "\"\"")
                    let noteStr = (tx.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                    let amountStr = String(format: "%.2f", abs(tx.amount)) // Positive amount for export readability, or leave as is
                    
                    let line = "\(dateStr),\"\(categoryStr)\",\"\(noteStr)\",\(amountStr)\n"
                    csvString.append(line)
                }
                
                let fileName = "Transactions_\(dateFormatter.string(from: Date())).csv"
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        
                        if let popover = activityVC.popoverPresentationController {
                            popover.sourceView = rootVC.view
                            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                            popover.permittedArrowDirections = []
                        }
                        
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                print("Failed to export data: \(error)")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(FinPilotTypography.headline)
                .foregroundColor(FinPilotColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(FinPilotColors.textSecondary)
                .font(.caption)
        }
        .padding()
        .background(FinPilotColors.surface)
        .cornerRadius(16)
    }
}
import SwiftUI


struct ManageCategoriesView: View {
    @State private var categories: [Category] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""
    @State private var categoryToEdit: Category? = nil
    @State private var showDeleteConfirm = false
    @State private var categoryToDelete: Category? = nil
    
    let filterOptions = ["All", "Expense", "Income", "Recurring"]
    
    var filteredCategories: [Category] {
        categories.filter { cat in
            let matchesFilter: Bool
            if selectedFilter == "All" {
                matchesFilter = true
            } else {
                matchesFilter = cat.type.lowercased() == selectedFilter.lowercased()
            }
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = cat.name.localizedCaseInsensitiveContains(searchText)
            }
            
            return matchesFilter && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top "Add New Category" Banner Card
            Button(action: {
                categoryToEdit = nil
                showAddSheet = true
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(FinPilotColors.primary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FinPilotColors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add New Category")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Tap to create a new expense, income, or recurring category")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FinPilotColors.primary)
                }
                .padding(14)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FinPilotColors.primary.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: FinPilotColors.primary.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FinPilotColors.textSecondary)
                TextField("Search categories...", text: $searchText)
                    .font(.system(size: 14))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(FinPilotColors.surface)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filterOptions, id: \.self) { filter in
                        let isSelected = selectedFilter == filter
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(isSelected ? FinPilotColors.primary : FinPilotColors.surface)
                                .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            
            // Category List
            if isLoading && categories.isEmpty {
                Spacer()
                ProgressView("Loading categories...")
                Spacer()
            } else if filteredCategories.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No categories found")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("Try changing filters or tap + above to create one.")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredCategories) { category in
                        Button(action: {
                            categoryToEdit = category
                            showAddSheet = true
                        }) {
                            HStack(spacing: 14) {
                                let catColor = Color(hex: category.color ?? "#0F9D58")
                                Image(systemName: category.icon ?? "tag.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(catColor)
                                    .frame(width: 40, height: 40)
                                    .background(catColor.opacity(0.15))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(category.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(FinPilotColors.textPrimary)
                                    
                                    HStack(spacing: 6) {
                                        Text(category.type.capitalized)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(typeColor(category.type))
                                        
                                        if category.parentId != nil {
                                            Text("• Subcategory")
                                                .font(.system(size: 11))
                                                .foregroundColor(FinPilotColors.textSecondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if category.isSystem == true {
                                    HStack(spacing: 3) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 9))
                                        Text("Default")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                } else {
                                    Text(category.type.capitalized)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(typeColor(category.type))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(typeColor(category.type).opacity(0.12))
                                        .cornerRadius(8)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if category.isSystem != true {
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(FinPilotColors.background)
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    categoryToEdit = nil
                    showAddSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FinPilotColors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                EditCategoryView(category: categoryToEdit, onUpdate: {
                    fetchCategories()
                })
            }
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Delete Category"),
                message: Text("Are you sure you want to delete \"\(categoryToDelete?.name ?? "this category")\"?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let cat = categoryToDelete {
                        deleteCategory(id: cat.id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            fetchCategories()
        }
    }
    
    private func fetchCategories() {
        isLoading = true
        Task {
            do {
                let roots: [Category] = try await APIManager.shared.request(endpoint: "/categories")
                var flat: [Category] = []
                for cat in roots {
                    flat.append(cat)
                    if let subs = cat.subcategories {
                        for sub in subs { flat.append(sub) }
                    }
                }
                await MainActor.run {
                    self.categories = flat
                    self.isLoading = false
                }
            } catch {
                print("Error loading categories: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func deleteCategory(id: String) {
        Task {
            do {
                struct EmptyRes: Codable { let success: Bool? }
                let _: EmptyRes = try await APIManager.shared.request(endpoint: "/categories/\(id)", method: "DELETE")
                fetchCategories()
            } catch {
                print("Failed to delete category: \(error)")
            }
        }
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "income": return .green
        case "recurring": return .orange
        default: return .red
        }
    }
}

struct EditCategoryView: View {
    let category: Category?
    let onUpdate: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var categoryType: String
    @State private var selectedTab: IconCategoryTab = .popular
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    enum IconCategoryTab: String, CaseIterable, Identifiable {
        case popular = "Popular"
        case money = "Money"
        case food = "Food & Drink"
        case transit = "Transit"
        case home = "Home"
        case leisure = "Lifestyle"
        
        var id: String { rawValue }
        
        var icons: [String] {
            switch self {
            case .popular:
                return ["tag.fill", "creditcard.fill", "cart.fill", "fork.knife", "house.fill", "car.fill", "heart.fill", "gift.fill", "sparkles", "star.fill", "briefcase.fill", "bag.fill"]
            case .money:
                return ["banknote.fill", "dollarsign.circle.fill", "wallet.pass.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis", "building.columns.fill", "percent", "arrow.triangle.swap", "centsign.circle.fill", "bitcoinsign.circle.fill", "arrow.up.right.circle.fill", "shield.fill"]
            case .food:
                return ["fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill", "carrot.fill", "fish.fill"]
            case .transit:
                return ["car.fill", "fuelpump.fill", "airplane", "bus.fill", "tram.fill", "bicycle", "scooter", "ferry.fill", "map.fill", "parkingsign", "figure.walk", "figure.run"]
            case .home:
                return ["house.fill", "bolt.fill", "drop.fill", "wifi", "flame.fill", "wrench.and.screwdriver.fill", "tv.fill", "iphone", "laptopcomputer", "bed.double.fill", "lightbulb.fill", "printer.fill"]
            case .leisure:
                return ["play.tv.fill", "music.note", "gamecontroller.fill", "film.fill", "book.fill", "ticket.fill", "camera.fill", "headphones", "paintpalette.fill", "theatermasks.fill", "cross.case.fill", "figure.walk"]
            }
        }
    }
    
    struct PresetItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: String
    }
    
    var presetsForCurrentType: [PresetItem] {
        switch categoryType {
        case "income":
            return [
                PresetItem(name: "Salary", icon: "banknote.fill", color: "#0F9D58"),
                PresetItem(name: "Freelance", icon: "laptopcomputer", color: "#2563EB"),
                PresetItem(name: "Investments", icon: "chart.line.uptrend.xyaxis", color: "#8B5CF6"),
                PresetItem(name: "Bonus", icon: "gift.fill", color: "#F59E0B"),
                PresetItem(name: "Dividends", icon: "dollarsign.circle.fill", color: "#14B8A6"),
                PresetItem(name: "Rental", icon: "house.fill", color: "#06B6D4")
            ]
        case "recurring":
            return [
                PresetItem(name: "Netflix", icon: "play.tv.fill", color: "#EF4444"),
                PresetItem(name: "Spotify", icon: "music.note", color: "#0F9D58"),
                PresetItem(name: "Gym", icon: "dumbbell.fill", color: "#F97316"),
                PresetItem(name: "Broadband", icon: "wifi", color: "#2563EB"),
                PresetItem(name: "iCloud", icon: "bolt.fill", color: "#06B6D4"),
                PresetItem(name: "Amazon Prime", icon: "bag.fill", color: "#4F46E5"),
                PresetItem(name: "Rent", icon: "house.fill", color: "#8B5CF6")
            ]
        default: // expense
            return [
                PresetItem(name: "Groceries", icon: "cart.fill", color: "#0F9D58"),
                PresetItem(name: "Dining Out", icon: "fork.knife", color: "#F97316"),
                PresetItem(name: "Shopping", icon: "bag.fill", color: "#EC4899"),
                PresetItem(name: "Fuel / Gas", icon: "fuelpump.fill", color: "#EF4444"),
                PresetItem(name: "Rent & Bills", icon: "house.fill", color: "#4F46E5"),
                PresetItem(name: "Travel", icon: "airplane", color: "#06B6D4"),
                PresetItem(name: "Healthcare", icon: "cross.case.fill", color: "#EF4444"),
                PresetItem(name: "Coffee", icon: "cup.and.saucer.fill", color: "#F59E0B")
            ]
        }
    }
    
    let curatedColors = [
        ("#0F9D58", Color(hex: "#0F9D58")), // Emerald Green
        ("#2563EB", Color(hex: "#2563EB")), // Royal Blue
        ("#4F46E5", Color(hex: "#4F46E5")), // Indigo
        ("#8B5CF6", Color(hex: "#8B5CF6")), // Purple
        ("#EC4899", Color(hex: "#EC4899")), // Hot Pink
        ("#EF4444", Color(hex: "#EF4444")), // Crimson Red
        ("#F97316", Color(hex: "#F97316")), // Sunset Orange
        ("#F59E0B", Color(hex: "#F59E0B")), // Warm Amber
        ("#EAB308", Color(hex: "#EAB308")), // Gold
        ("#14B8A6", Color(hex: "#14B8A6")), // Teal
        ("#06B6D4", Color(hex: "#06B6D4")), // Cyan
        ("#64748B", Color(hex: "#64748B"))  // Slate
    ]
    
    init(category: Category?, defaultType: String? = nil, onUpdate: @escaping () -> Void) {
        self.category = category
        self.onUpdate = onUpdate
        
        if let cat = category {
            _name = State(initialValue: cat.name)
            _selectedIcon = State(initialValue: cat.icon ?? "tag.fill")
            _selectedColor = State(initialValue: cat.color ?? "#0F9D58")
            _categoryType = State(initialValue: cat.type.lowercased())
        } else {
            _name = State(initialValue: "")
            _selectedIcon = State(initialValue: "tag.fill")
            _selectedColor = State(initialValue: "#0F9D58")
            _categoryType = State(initialValue: defaultType?.lowercased() ?? "expense")
        }
        _isSaving = State(initialValue: false)
        _errorMessage = State(initialValue: nil)
        _showErrorAlert = State(initialValue: false)
    }
    
    var currentColor: Color {
        Color(hex: selectedColor)
    }
    
    func typeIcon(_ type: String) -> String {
        switch type {
        case "income": return "arrow.up.right.circle.fill"
        case "recurring": return "arrow.triangle.2.circlepath.circle.fill"
        default: return "arrow.down.forward.circle.fill"
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Hero Live Preview Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [currentColor.opacity(0.28), currentColor.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(currentColor.opacity(0.35), lineWidth: 1.5)
                            )
                            .shadow(color: currentColor.opacity(0.25), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: selectedIcon)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(currentColor)
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 6) {
                        Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Category Name" : name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? FinPilotColors.textSecondary.opacity(0.6) : FinPilotColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 6) {
                            Image(systemName: typeIcon(categoryType))
                                .font(.system(size: 11, weight: .bold))
                            Text(categoryType.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .tracking(0.8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(currentColor.opacity(0.12))
                        .foregroundColor(currentColor)
                        .clipShape(Capsule())
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(FinPilotColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(currentColor.opacity(0.18), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                
                // MARK: - Category Name & Type Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("CATEGORY DETAILS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .tracking(1.0)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 14) {
                        // Name textfield
                        HStack(spacing: 12) {
                            Image(systemName: "tag.fill")
                                .foregroundColor(currentColor)
                                .font(.system(size: 16))
                            TextField("Enter category name", text: $name)
                                .font(.system(size: 15, weight: .medium))
                            
                            if !name.isEmpty {
                                Button(action: { name = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(14)
                        .background(FinPilotColors.background)
                        .cornerRadius(14)
                        
                        // Type Selector Pills
                        HStack(spacing: 8) {
                            ForEach(["expense", "income", "recurring"], id: \.self) { t in
                                let isSelected = categoryType == t
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        categoryType = t
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: typeIcon(t))
                                            .font(.system(size: 12, weight: .bold))
                                        Text(t.capitalized)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(isSelected ? currentColor : FinPilotColors.background)
                                    .foregroundColor(isSelected ? .white : FinPilotColors.textSecondary)
                                    .cornerRadius(12)
                                    .shadow(color: isSelected ? currentColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        
                        // Popular Suggestions Carousel
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("QUICK PRESETS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FinPilotColors.textSecondary)
                                    .tracking(0.6)
                                Spacer()
                                Text("Tap to auto-fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(FinPilotColors.textSecondary.opacity(0.7))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(presetsForCurrentType) { preset in
                                        let isChosen = name.lowercased() == preset.name.lowercased()
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                name = preset.name
                                                selectedIcon = preset.icon
                                                selectedColor = preset.color
                                            }
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: preset.icon)
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text(preset.name)
                                                    .font(.system(size: 12, weight: isChosen ? .bold : .medium))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(isChosen ? currentColor.opacity(0.18) : FinPilotColors.background)
                                            .foregroundColor(isChosen ? currentColor : FinPilotColors.textPrimary)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(isChosen ? currentColor : Color.clear, lineWidth: 1.2)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                }
                
                // MARK: - Curated Icon Selector with Tabs
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("SELECT ICON")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(1.0)
                        Spacer()
                        Text(selectedTab.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(currentColor)
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        // Category Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(IconCategoryTab.allCases) { tab in
                                    let isSelected = selectedTab == tab
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTab = tab
                                        }
                                    }) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(isSelected ? currentColor.opacity(0.15) : FinPilotColors.background)
                                            .foregroundColor(isSelected ? currentColor : FinPilotColors.textSecondary)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Icon Grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                            ForEach(selectedTab.icons, id: \.self) { icon in
                                let isSelected = selectedIcon == icon
                                Button(action: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                        selectedIcon = icon
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ? currentColor : FinPilotColors.background)
                                            .frame(height: 46)
                                            .shadow(color: isSelected ? currentColor.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                }
                
                // MARK: - Color Palette
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT COLOR ACCENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .tracking(1.0)
                        .padding(.horizontal, 4)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 14) {
                        ForEach(curatedColors, id: \.0) { hexColor, colorVal in
                            let isSelected = selectedColor.lowercased() == hexColor.lowercased()
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                    selectedColor = hexColor
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(colorVal)
                                        .frame(width: 38, height: 38)
                                        .shadow(color: colorVal.opacity(0.35), radius: 4, x: 0, y: 2)
                                    
                                    if isSelected {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 36, height: 36)
                                        
                                        Circle()
                                            .stroke(colorVal, lineWidth: 2)
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 46, height: 46)
                            }
                        }
                    }
                    .padding(16)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                }
                
                // MARK: - Save Button
                Button(action: saveChanges) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                            Text("Saving...")
                                .font(.system(size: 16, weight: .bold))
                        } else {
                            Image(systemName: category == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(category == nil ? "Create Category" : "Save Changes")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: name.trimmingCharacters(in: .whitespaces).isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [currentColor, currentColor.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: name.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : currentColor.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let payload = [
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "icon": selectedIcon,
                    "color": selectedColor,
                    "type": categoryType.lowercased()
                ]
                let data = try JSONSerialization.data(withJSONObject: payload)
                
                if let cat = category {
                    let _: Category = try await APIManager.shared.request(endpoint: "/categories/\(cat.id)", method: "PUT", body: data)
                } else {
                    let _: Category = try await APIManager.shared.request(endpoint: "/categories", method: "POST", body: data)
                }
                
                await MainActor.run {
                    isSaving = false
                    onUpdate()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to save category: \(error)")
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Subscription Paywall View
struct SubscriptionPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isProcessing = false
    @State private var purchaseSuccess = false
    @State private var errorMessage: String? = nil
    @State private var showError = false

    var body: some View {
        ZStack {
            FinPilotColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Crown & Banner
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFD700").opacity(0.3), Color(hex: "#FFA500").opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 86, height: 86)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 42))
                                .foregroundColor(Color(hex: "#FF9900"))
                        }
                        
                        Text("FINANCY PRO")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2.0)
                            .foregroundColor(FinPilotColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(FinPilotColors.primary.opacity(0.12))
                            .cornerRadius(12)
                        
                        Text("Unlock Lifetime Access")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(authViewModel.isTrialExpired ? "Your 7-day trial has ended. Continue managing your finances with unlimited Pro features forever." : "Enjoy a 7-day free trial, or unlock lifetime access right now for a single one-time payment.")
                            .font(.system(size: 14))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    // Lifetime Pricing Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LIFETIME MEMBERSHIP")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(FinPilotColors.primary)
                                    .tracking(1.0)
                                Text("Pay Once, Own Forever")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                Text("No recurring charges or subscriptions")
                                    .font(.system(size: 12))
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$9.99")
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                Text("ONE-TIME")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FinPilotColors.primary, lineWidth: 2)
                    )
                    .shadow(color: FinPilotColors.primary.opacity(0.12), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("WHAT'S INCLUDED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(1.0)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 14) {
                            PaywallFeatureRow(icon: "checkmark.circle.fill", title: "Unlimited Income & Expense Tracking", desc: "Never hit any limits on transactions")
                            PaywallFeatureRow(icon: "sparkles", title: "AI-Powered Financial Insights", desc: "Personalized tips to cut expenses and save more")
                            PaywallFeatureRow(icon: "repeat.circle.fill", title: "Automated Recurring Bills & Subscriptions", desc: "Never miss a due date or payment")
                            PaywallFeatureRow(icon: "chart.pie.fill", title: "Custom Category Budgeting", desc: "Build tailored budgets for every life category")
                            PaywallFeatureRow(icon: "icloud.and.arrow.up.fill", title: "Encrypted Cloud Backup & Multi-device Sync", desc: "Safe, private and secure finance storage")
                        }
                        .padding(18)
                        .background(FinPilotColors.surface)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Button
                    VStack(spacing: 12) {
                        Button(action: handleSubscribe) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "lock.open.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Get Lifetime Access — $9.99")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [FinPilotColors.primaryLight, FinPilotColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(color: FinPilotColors.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isProcessing)
                        
                        HStack(spacing: 16) {
                            Button("Restore Purchases") {
                                Task {
                                    await authViewModel.fetchProfile()
                                    if authViewModel.isSubscribed {
                                        dismiss()
                                    }
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                            
                            Text("•")
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                            
                            Button("Terms & Privacy") {
                                // Info only
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .alert(isPresented: $purchaseSuccess) {
            Alert(
                title: Text("🎉 Welcome to Financy Pro!"),
                message: Text("Your lifetime access has been unlocked. Enjoy all features with no limits forever!"),
                dismissButton: .default(Text("Continue")) {
                    dismiss()
                }
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Purchase Failed"),
                message: Text(errorMessage ?? "An error occurred while upgrading."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func handleSubscribe() {
        Task {
            isProcessing = true
            let success = await authViewModel.subscribe()
            isProcessing = false
            if success {
                purchaseSuccess = true
            } else {
                errorMessage = authViewModel.error ?? "Failed to complete subscription."
                showError = true
            }
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(FinPilotColors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var avatar: String? = nil
    @State private var currency: String = "INR"
    @State private var monthlyIncome: String = ""
    @State private var savingsTarget: String = ""
    @State private var primaryGoal: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var biometricsEnabled: Bool = false
    @State private var showDeleteConfirm: Bool = false
    
    let currencyOptions = [
        ("INR", "₹ Indian Rupee (INR)"),
        ("USD", "$ US Dollar (USD)"),
        ("EUR", "€ Euro (EUR)"),
        ("GBP", "£ British Pound (GBP)"),
        ("AED", "د.إ UAE Dirham (AED)"),
        ("CAD", "$ Canadian Dollar (CAD)"),
        ("AUD", "$ Australian Dollar (AUD)"),
        ("JPY", "¥ Japanese Yen (JPY)"),
        ("SGD", "$ Singapore Dollar (SGD)")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                AvatarPickerView(avatarBase64: $avatar)
                
                HStack {
                    Text("Full Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Enter name", text: $name)
                }
                
                HStack {
                    Text("Email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Enter email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                HStack {
                    Text("Mobile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    TextField("Enter mobile number", text: $mobileNumber)
                        .keyboardType(.phonePad)
                }
            }
            
            Section(header: Text("Financial Setup"), footer: Text("Your baseline monthly income and savings target power balance, budget, and month-end settlement tracking.")) {
                Picker("Currency", selection: $currency) {
                    ForEach(currencyOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
                
                HStack {
                    Text("Monthly Income")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 120, alignment: .leading)
                    TextField("e.g. 50000", text: $monthlyIncome)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("Savings Target")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 120, alignment: .leading)
                    TextField("e.g. 15000", text: $savingsTarget)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("Primary Goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(width: 120, alignment: .leading)
                    TextField("e.g. Emergency Fund / House", text: $primaryGoal)
                }
            }
            
            Section(header: Text("Preferences & Security")) {
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                        Text("Activity & Budget Alerts")
                    }
                }
                
                Toggle(isOn: $biometricsEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .foregroundColor(.blue)
                        Text("Face ID / Biometric Lock")
                    }
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if authViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(FinPilotColors.primary)
                    .cornerRadius(12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .disabled(authViewModel.isLoading)
            }
            
            Section(header: Text("Account Management")) {
                Button(role: .destructive, action: {
                    showDeleteConfirm = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Delete FinPilot Account")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to permanently delete your account and all associated data? This action cannot be undone."),
                primaryButton: .destructive(Text("Yes, Delete")) {
                    Task {
                        _ = await authViewModel.deleteAccount()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                name = user.name
                email = user.email ?? ""
                mobileNumber = user.mobileNumber ?? ""
                avatar = user.avatar
                currency = user.currency ?? "INR"
                primaryGoal = user.primaryGoal ?? ""
                notificationsEnabled = user.notificationsEnabled ?? true
                biometricsEnabled = user.biometricsEnabled ?? false
                
                if let income = user.monthlyIncome, income > 0 {
                    monthlyIncome = String(format: "%.2f", income)
                }
                if let target = user.savingsTarget, target > 0 {
                    savingsTarget = String(format: "%.2f", target)
                }
            }
        }
    }
    
    private func saveProfile() {
        let finalIncome = monthlyIncome.isEmpty ? "0" : monthlyIncome
        let finalTarget = savingsTarget.isEmpty ? "0" : savingsTarget
        Task {
            let success = await authViewModel.updateProfile(
                name: name,
                currency: currency,
                monthlyIncome: finalIncome,
                primaryGoal: primaryGoal,
                avatar: avatar,
                email: email,
                mobileNumber: mobileNumber,
                savingsTarget: finalTarget,
                notificationsEnabled: notificationsEnabled,
                biometricsEnabled: biometricsEnabled
            )
            if success {
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FinPilotColors.primary)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Text("About Financy")
                    .font(FinPilotTypography.title2)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("Financy is a personal finance management app designed to help you take control of your money in one place.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Text("Track your income and expenses, manage budgets, monitor saving goals, and understand your spending habits with simple and meaningful financial insights.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Divider().padding(.vertical, 8)
                
                Text("What you can do with Financy")
                    .font(FinPilotTypography.title3)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    AboutFeatureRow(icon: "💰", text: "Track income and expenses")
                    AboutFeatureRow(icon: "📊", text: "Manage monthly and category-wise budgets")
                    AboutFeatureRow(icon: "🎯", text: "Set and track saving goals")
                    AboutFeatureRow(icon: "📈", text: "Monitor your financial progress")
                    AboutFeatureRow(icon: "🧾", text: "Organize transactions by category")
                    AboutFeatureRow(icon: "🔐", text: "Keep your financial data private and secure")
                    AboutFeatureRow(icon: "👤", text: "Manage your personal financial profile")
                }
                
                Divider().padding(.vertical, 8)
                
                Text("Financy is built to make personal finance simple, organized, and easier to understand, helping you make better decisions about your everyday money.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Text("Financy — Track. Budget. Save. Grow.")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.primary)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(24)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            Text(text)
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textPrimary)
        }
    }
}
import SwiftUI
import PhotosUI

struct AvatarPickerView: View {
    @Binding var avatarBase64: String?
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()) {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let b64 = avatarBase64, !b64.isEmpty {
                            if b64.starts(with: "/") {
                                let fullUrlStr = NetworkConfig.baseURLString.replacingOccurrences(of: "/api", with: "") + b64
                                AsyncImage(url: URL(string: fullUrlStr)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else if let data = Data(base64Encoded: b64), let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                            if let uiImage = UIImage(data: data),
                               let resizedData = uiImage.jpegData(compressionQuality: 0.5) {
                                avatarBase64 = resizedData.base64EncodedString()
                            }
                        }
                    }
                }
                
                if avatarBase64 != nil && !avatarBase64!.isEmpty || selectedImageData != nil {
                    Button(role: .destructive, action: {
                        avatarBase64 = ""
                        selectedImageData = nil
                        selectedItem = nil
                    }) {
                        Text("Remove Photo")
                            .font(FinPilotTypography.caption)
                            .foregroundColor(FinPilotColors.error)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical)
    }
}
