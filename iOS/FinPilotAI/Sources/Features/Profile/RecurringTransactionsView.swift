import SwiftUI

struct RecurringTransactionsView: View {
    @State private var transactions: [RecurringTransaction] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Active", "Upcoming"]
    
    var filteredTransactions: [RecurringTransaction] {
        switch selectedFilter {
        case "Active":
            return transactions.filter { $0.status?.lowercased() == "active" || $0.status == nil }
        case "Upcoming":
            let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            return transactions.filter { $0.nextDate <= nextWeek && $0.nextDate >= Date() }
        default:
            return transactions
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Pill Toggle
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter)
                            .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .regular))
                            .foregroundColor(selectedFilter == filter ? .white : FinPilotColors.textSecondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedFilter == filter ? FinPilotColors.primary : Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(FinPilotColors.primary.opacity(0.3), lineWidth: selectedFilter == filter ? 0 : 1)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                if filteredTransactions.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(Color.gray.opacity(0.5))
                            Text("No transactions found.")
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                    }
                    .refreshable {
                        await fetchRecurring()
                    }
                } else {
                    List {
                        ForEach(filteredTransactions) { tx in
                            RecurringTransactionCard(transaction: tx)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTransaction(tx)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await fetchRecurring()
                    }
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationTitle("Recurring Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FinPilotColors.primary)
                    }
                }
            }
            .task {
                await fetchRecurring()
            }
            .loadingOverlay(isLoading: isLoading, message: "Syncing Data...")
        }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringTransactionView(onSave: {
                await fetchRecurring()
            })
        }
    }
    
    private func deleteTransaction(_ tx: RecurringTransaction) {
        Task {
            isLoading = true
            do {
                struct EmptyRes: Codable {}
                let _: EmptyRes = try await APIManager.shared.request(endpoint: "/recurring/\(tx.id)", method: "DELETE")
                await fetchRecurring()
            } catch {
                print("Failed to delete recurring transaction: \(error)")
            }
            isLoading = false
        }
    }
    
    private func fetchRecurring() async {
        isLoading = true
        do {
            let fetched: [RecurringTransaction] = try await APIManager.shared.request(endpoint: "/recurring")
            transactions = fetched
        } catch {
            print("Failed to load recurring transactions: \(error)")
        }
        isLoading = false
    }
}

struct RecurringTransactionCard: View {
    let transaction: RecurringTransaction
    
    private var uiCategory: String {
        let n = transaction.merchant?.lowercased() ?? ""
        if n.contains("rent") || n.contains("home") { return "Rent" }
        if n.contains("bill") || n.contains("electricity") || n.contains("internet") { return "Bill" }
        if n.contains("netflix") || n.contains("spotify") || n.contains("prime") || n.contains("insurance") { return "Subscription" }
        return "Other"
    }
    
    private var uiColor: Color {
        switch uiCategory {
        case "Rent": return .red
        case "Bill": return .teal
        case "Subscription": return .orange
        default: return .blue
        }
    }
    
    private var uiIcon: String {
        switch uiCategory {
        case "Rent": return "house.fill"
        case "Bill": return "lightbulb.fill"
        case "Subscription": return "play.tv.fill"
        default: return "bag.fill"
        }
    }
    
    private var pillBg: Color {
        uiColor.opacity(0.15)
    }
    
    private var pillText: Color {
        uiColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: uiIcon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(uiColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.merchant ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("₹\(Int(transaction.amount)) • \(transaction.frequency.capitalized)")
                    .font(.system(size: 13))
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Text("Next: \(formatDate(transaction.nextDate))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FinPilotColors.primary)
            }
            
            Spacer()
            
            VStack {
                Text(uiCategory)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(pillText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(pillBg)
                    .cornerRadius(12)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}


struct AddRecurringTransactionView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    @State private var frequency = "Monthly"
    @State private var nextDueDate = Date()
    @State private var autoCreate = true
    @State private var notes = ""
    @State private var isLoading = false
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: String = ""
    @State private var selectedMerchantName: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    let frequencies = ["Daily", "Weekly", "Monthly", "Yearly"]
    let onSave: () async -> Void
    
    private var selectedCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryId })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        amountSection
                        categorySection
                        scheduleSection
                        automationSection
                        notesSection
                        
                        // Extra bottom spacing for floating button
                        Spacer().frame(height: 70)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                
                VStack {
                    Spacer()
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                    }
                }
            }
            .loadingOverlay(isLoading: isLoading)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unexpected error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                await fetchRecurringCategories()
            }
        }
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundColor(FinPilotColors.primary)
                    Text("RECURRING AMOUNT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .tracking(0.8)
                }
                Spacer()
                Text(frequency.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FinPilotColors.primary.opacity(0.12))
                    .foregroundColor(FinPilotColors.primary)
                    .cornerRadius(8)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("₹")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                TextField("0", text: $amount)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        .background(FinPilotColors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Category / Merchant Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MERCHANT / CATEGORY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinPilotColors.textSecondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
            
            if categories.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Recurring Categories")
                            .font(FinPilotTypography.headline)
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Create a category with type 'Recurring' first in More > Manage Categories.")
                            .font(FinPilotTypography.caption)
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            } else {
                Menu {
                    ForEach(categories) { cat in
                        Button(action: {
                            selectedCategoryId = cat.id
                            selectedMerchantName = cat.name
                        }) {
                            HStack {
                                Text(cat.name)
                                if cat.id == selectedCategoryId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 14) {
                        let catIcon = selectedCategory?.icon ?? "tag.fill"
                        let catColor = Color(hex: selectedCategory?.color ?? "#0F9D58")
                        
                        ZStack {
                            Circle()
                                .fill(catColor.opacity(0.16))
                                .frame(width: 46, height: 46)
                            
                            Image(systemName: catIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(catColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Merchant Name")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Text(selectedCategory?.name ?? "Select Category")
                                .font(FinPilotTypography.headline)
                                .foregroundColor(selectedCategory == nil ? FinPilotColors.textSecondary : FinPilotColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .padding(.trailing, 4)
                    }
                    .padding(16)
                    .background(FinPilotColors.surface)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                }
            }
        }
    }
    
    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FREQUENCY & SCHEDULE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinPilotColors.textSecondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
            
            VStack(spacing: 14) {
                // Frequency Pills
                HStack(spacing: 8) {
                    ForEach(frequencies, id: \.self) { freq in
                        let isSelected = frequency == freq
                        Button(action: {
                            frequency = freq
                        }) {
                            Text(freq)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? FinPilotColors.primary : FinPilotColors.background)
                                .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
                
                Divider()
                
                // Next Due Date row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(FinPilotColors.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(FinPilotColors.primary)
                    }
                    
                    Text("First Due Date")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $nextDueDate, displayedComponents: .date)
                        .labelsHidden()
                        .accentColor(FinPilotColors.primary)
                }
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }
    
    // MARK: - Automation Section
    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOMATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinPilotColors.textSecondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
            
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bolt.badge.automatic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Auto-create Transaction")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("Auto-deduct on every billing cycle")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $autoCreate)
                    .labelsHidden()
                    .tint(FinPilotColors.primary)
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES (OPTIONAL)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FinPilotColors.textSecondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .foregroundColor(FinPilotColors.textSecondary)
                    .font(.system(size: 16))
                
                TextField("e.g. Standard 4K plan, yearly discount", text: $notes)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            Task {
                isLoading = true
                await saveTransaction()
                isLoading = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Save Recurring Expense")
                    .font(FinPilotTypography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [FinPilotColors.primaryLight, FinPilotColors.primary]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: FinPilotColors.primary.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .disabled(selectedCategoryId.isEmpty || amount.isEmpty || isLoading)
        .opacity((selectedCategoryId.isEmpty || amount.isEmpty || isLoading) ? 0.55 : 1.0)
    }
    
    // MARK: - API Helpers
    private func fetchRecurringCategories() async {
        do {
            let fetched: [Category] = try await APIManager.shared.request(endpoint: "/categories")
            let recurringCats = fetched.filter { $0.type.lowercased() == "recurring" }
            await MainActor.run {
                self.categories = recurringCats
                if let first = recurringCats.first {
                    self.selectedCategoryId = first.id
                    self.selectedMerchantName = first.name
                }
            }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }

    private func saveTransaction() async {
        var payload: [String: Any] = [
            "type": "expense",
            "amount": Double(amount) ?? 0.0,
            "merchant": selectedMerchantName,
            "frequency": frequency.lowercased(),
            "next_due_date": nextDueDate.ISO8601Format().components(separatedBy: "T")[0],
            "auto_create": autoCreate,
            "category_id": selectedCategoryId
        ]
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["notes"] = notes
        }
        
        do {
            struct EmptyRes: Codable {}
            let data = try JSONSerialization.data(withJSONObject: payload)
            let _: EmptyRes = try await APIManager.shared.request(endpoint: "/recurring", method: "POST", body: data)
            await onSave()
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Failed to save: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
