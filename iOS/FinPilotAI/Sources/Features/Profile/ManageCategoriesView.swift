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
