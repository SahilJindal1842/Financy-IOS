import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                            
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
                        NavigationLink(destination: RecurringTransactionsView()) {
                            SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Recurring Transactions", color: .indigo)
                        }
                        SettingsRow(icon: "person.fill", title: "Account", color: .blue)
                        NavigationLink(destination: ManageCategoriesView()) {
                            SettingsRow(icon: "tag.fill", title: "Manage Categories", color: .pink)
                        }
                        NavigationLink(destination: NotificationsView()) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                        }
                        SettingsRow(icon: "arrow.down.doc.fill", title: "Export Data", color: .purple)
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                        SettingsRow(icon: "info.circle.fill", title: "About", color: .gray)
                        
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
    
    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink(destination: EditCategoryView(category: category, onUpdate: { fetchCategories() })) {
                    HStack(spacing: 16) {
                        Image(systemName: category.icon ?? "tag.fill")
                            .foregroundColor(colorForHexString(category.color))
                            .frame(width: 32, height: 32)
                            .background(colorForHexString(category.color).opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .font(FinPilotTypography.body)
                                .foregroundColor(FinPilotColors.textPrimary)
                            Text(category.type.capitalized)
                                .font(FinPilotTypography.caption)
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Manage Categories")
        .task {
            fetchCategories()
        }
        .overlay(Group {
            if isLoading && categories.isEmpty {
                ProgressView("Loading...")
            }
        })
    }
    
    private func fetchCategories() {
        isLoading = true
        Task {
            do {
                let roots: [Category] = try await APIManager.shared.request(endpoint: "/categories")
                var flat: [Category] = []
                func flatten(cats: [Category]) {
                    for cat in cats {
                        flat.append(cat)
                        if let subs = cat.subcategories { flatten(cats: subs) }
                    }
                }
                flatten(cats: roots)
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
}

struct EditCategoryView: View {
    let category: Category
    let onUpdate: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isSaving = false
    
    let defaultIcons = ["tag.fill", "fork.knife", "car.fill", "bag.fill", "doc.text.fill", "heart.fill", "cart.fill", "airplane", "house.fill", "gamecontroller.fill", "bolt.fill", "star.fill", "graduationcap.fill", "gift.fill"]
    let defaultColors = [
        ("#ff5733", Color.orange),
        ("#33ff57", Color.green),
        ("#3357ff", Color.blue),
        ("#ff33a1", Color.pink),
        ("#a133ff", Color.purple),
        ("#ffc300", Color.yellow)
    ]
    
    init(category: Category, onUpdate: @escaping () -> Void) {
        self.category = category
        self.onUpdate = onUpdate
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon ?? "tag.fill")
        _selectedColor = State(initialValue: category.color ?? "#3357ff")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Category Name", text: $name)
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
                        Text("Save Changes")
                            .bold()
                    }
                    Spacer()
                }
            }
            .disabled(isSaving || name.isEmpty)
        }
        .navigationTitle("Edit Category")
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let payload = ["name": name, "icon": selectedIcon, "color": selectedColor]
                let data = try JSONSerialization.data(withJSONObject: payload)
                let _: Category = try await APIManager.shared.request(endpoint: "/categories/\(category.id)", method: "PUT", body: data)
                
                await MainActor.run {
                    isSaving = false
                    onUpdate()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to save: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}
