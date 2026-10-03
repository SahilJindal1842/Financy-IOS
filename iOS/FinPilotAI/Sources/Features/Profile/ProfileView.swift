import PhotosUI

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddCategorySheet = false
    
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
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        .offset(y: 40) // Overlap the header
                    }
                    .padding(.bottom, 60) // Space for the overlapping card
                    
                    // Settings List
                    VStack(spacing: 16) {
                        NavigationLink(destination: SavingsGoalsView()) {
                            SettingsRow(icon: "target", title: "Savings Goals", color: .teal)
                        }
                        NavigationLink(destination: ReportsView()) {
                            SettingsRow(icon: "sparkles", title: "AI Insights", color: .indigo)
                        }
                        NavigationLink(destination: EditProfileView()) {
                            SettingsRow(icon: "person.fill", title: "Account", color: .blue)
                        }
                        Button(action: { showAddCategorySheet = true }) {
                            SettingsRow(icon: "plus.circle.fill", title: "Create New Category", color: .green)
                        }
                        NavigationLink(destination: ManageCategoriesView()) {
                            SettingsRow(icon: "list.bullet", title: "Manage Categories", color: .pink)
                        }
                        NavigationLink(destination: NotificationsView()) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
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
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddCategorySheet) {
                NavigationView {
                    EditCategoryView(category: nil as Category?, onUpdate: { })
                }
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
        .background(Color.white)
        .cornerRadius(16)
    }
}
import SwiftUI


struct ManageCategoriesView: View {
    @State private var categories: [Category] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && categories.isEmpty {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if categories.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No categories yet")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("Tap the button above to create one.")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List {
                    ForEach(categories) { category in
                        NavigationLink(destination: EditCategoryView(category: category, onUpdate: { fetchCategories() })) {
                            HStack(spacing: 16) {
                                Image(systemName: category.icon ?? "tag.fill")
                                    .foregroundColor(colorForHexString(category.color))
                                    .frame(width: 32, height: 32)
                                    .background(colorForHexString(category.color).opacity(0.15))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(FinPilotTypography.body)
                                        .foregroundColor(FinPilotColors.textPrimary)
                                    Text(category.type.capitalized)
                                        .font(FinPilotTypography.caption)
                                        .foregroundColor(FinPilotColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(category.type.capitalized)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(typeColor(category.type))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(typeColor(category.type).opacity(0.12))
                                    .cornerRadius(8)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(FinPilotColors.background)
        .navigationTitle("Manage Categories")
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
    
    private func colorForHexString(_ hex: String?) -> Color {
        guard let hex = hex else { return .blue }
        switch hex.lowercased() {
        case "#ff5733": return .orange
        case "#33ff57": return .green
        case "#3357ff": return .blue
        case "#ff33a1": return .pink
        case "#a133ff": return .purple
        case "#ffc300": return .yellow
        default: return .blue
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
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    let defaultIcons = ["tag.fill", "fork.knife", "car.fill", "bag.fill", "doc.text.fill", "heart.fill", "cart.fill", "airplane", "house.fill", "gamecontroller.fill", "bolt.fill", "star.fill", "graduationcap.fill", "gift.fill"]
    let defaultColors = [
        ("#ff5733", Color.orange),
        ("#33ff57", Color.green),
        ("#3357ff", Color.blue),
        ("#ff33a1", Color.pink),
        ("#a133ff", Color.purple),
        ("#ffc300", Color.yellow)
    ]
    
    init(category: Category?, onUpdate: @escaping () -> Void) {
        self.category = category
        self.onUpdate = onUpdate
        
        if let cat = category {
            _name = State(initialValue: cat.name)
            _selectedIcon = State(initialValue: cat.icon ?? "tag.fill")
            _selectedColor = State(initialValue: cat.color ?? "#3357ff")
            _categoryType = State(initialValue: cat.type)
        } else {
            _name = State(initialValue: "")
            _selectedIcon = State(initialValue: "tag.fill")
            _selectedColor = State(initialValue: "#ff5733")
            _categoryType = State(initialValue: "expense")
        }
        _isSaving = State(initialValue: false)
        _errorMessage = State(initialValue: nil)
        _showErrorAlert = State(initialValue: false)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Category Name", text: $name)
                Picker("Type", selection: $categoryType) {
                    Text("Expense").tag("expense")
                    Text("Income").tag("income")
                    Text("Recurring").tag("recurring")
                }
            }
            
            Section(header: Text("Icon")) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(defaultIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(selectedIcon == icon ? Color.gray.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Color")) {
                HStack(spacing: 20) {
                    ForEach(defaultColors, id: \.0) { colorPair in
                        Circle()
                            .fill(colorPair.1)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColor == colorPair.0 ? 3 : 0)
                            )
                            .onTapGesture {
                                selectedColor = colorPair.0
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Button(action: saveChanges) {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Category")
                            .bold()
                    }
                    Spacer()
                }
            }
            .disabled(isSaving || name.isEmpty)
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .toolbar {
            if category == nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let payload = [
                    "name": name,
                    "icon": selectedIcon,
                    "color": selectedColor,
                    "type": categoryType
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
                print("Failed to save: \(error)")
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddCategorySheet = false
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var avatar: String? = nil
    @State private var currency: String = ""
    @State private var monthlyIncome: String = ""
    @State private var primaryGoal: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Personal Info")) {
                AvatarPickerView(avatarBase64: $avatar)
                TextField("Name", text: $name)
            }
            
            Section(header: Text("Financial Setup"), footer: Text("Set your baseline monthly income to correctly calculate your dashboard balance.")) {
                TextField("Monthly Income", text: $monthlyIncome)
                    .keyboardType(.decimalPad)
                
                TextField("Currency (e.g. USD, INR)", text: $currency)
                    .autocapitalization(.allCharacters)
                
                TextField("Primary Goal", text: $primaryGoal)
            }
            
            Button(action: saveProfile) {
                HStack {
                    Spacer()
                    if authViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Save Profile")
                            .bold()
                    }
                    Spacer()
                }
            }
            .disabled(authViewModel.isLoading)
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            if let user = authViewModel.currentUser {
                name = user.name
                avatar = user.avatar
                currency = user.currency ?? "USD"
                primaryGoal = user.primaryGoal ?? ""
                if let income = user.monthlyIncome {
                    monthlyIncome = income > 0 ? String(format: "%.2f", income) : ""
                }
            }
        }
    }
    
    private func saveProfile() {
        // Replace empty with "0"
        let finalIncome = monthlyIncome.isEmpty ? "0" : monthlyIncome
        Task {
            let success = await authViewModel.updateProfile(name: name, currency: currency, monthlyIncome: finalIncome, primaryGoal: primaryGoal, avatar: avatar)
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
