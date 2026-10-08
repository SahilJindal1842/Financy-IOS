import SwiftUI

struct RecurringTransactionsView: View {
    @State private var transactions: [RecurringTransaction] = []
    @State private var allCategories: [Category] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedFilter = "All"
    @State private var initialFocusTarget: String? = nil
    
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
                .background(FinPilotColors.surface)
                
                if filteredTransactions.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 54))
                                .foregroundColor(FinPilotColors.primary.opacity(0.7))
                            Text("No recurring transactions found")
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textPrimary)
                            Text("Track your recurring bills and subscriptions like Netflix, Spotify, Rent, and Gym.")
                                .font(FinPilotTypography.caption)
                                .foregroundColor(FinPilotColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                            
                            Button(action: { showAddSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Add Recurring Transaction")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(FinPilotColors.primary)
                                .cornerRadius(14)
                                .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
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
                            RecurringTransactionCard(transaction: tx, categories: allCategories)
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
            AddRecurringTransactionView(initialFocus: initialFocusTarget, onSave: {
                await fetchRecurring()
            })
            .id(initialFocusTarget ?? "default")
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddRecurring)) { notif in
            initialFocusTarget = notif.object as? String
            showAddSheet = true
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
            async let fetchedTx: [RecurringTransaction] = APIManager.shared.request(endpoint: "/recurring")
            async let fetchedCats: [Category] = APIManager.shared.request(endpoint: "/categories")
            
            let (txs, roots) = try await (fetchedTx, fetchedCats)
            var flat: [Category] = []
            func collect(_ list: [Category]) {
                for c in list {
                    flat.append(c)
                    if let subs = c.subcategories {
                        collect(subs)
                    }
                }
            }
            collect(roots)
            
            await MainActor.run {
                self.transactions = txs
                self.allCategories = flat
            }
        } catch {
            print("Failed to load recurring transactions: \(error)")
        }
        isLoading = false
    }
}

struct RecurringTransactionCard: View {
    let transaction: RecurringTransaction
    var categories: [Category] = []
    
    private var linkedCategory: Category? {
        categories.first(where: { $0.id == transaction.categoryId })
    }
    
    private var cardColor: Color {
        if let cat = linkedCategory, let c = cat.color {
            return Color(hex: c)
        }
        let n = transaction.merchant?.lowercased() ?? ""
        if n.contains("rent") || n.contains("home") { return .red }
        if n.contains("bill") || n.contains("electricity") || n.contains("internet") { return .teal }
        if n.contains("netflix") || n.contains("spotify") || n.contains("prime") || n.contains("insurance") { return .orange }
        return FinPilotColors.primary
    }
    
    private var cardIcon: String {
        if let cat = linkedCategory, let icon = cat.icon, !icon.isEmpty {
            return icon
        }
        let n = transaction.merchant?.lowercased() ?? ""
        if n.contains("rent") || n.contains("home") { return "house.fill" }
        if n.contains("bill") || n.contains("electricity") || n.contains("internet") { return "lightbulb.fill" }
        if n.contains("netflix") || n.contains("spotify") || n.contains("prime") { return "play.tv.fill" }
        return "repeat.circle.fill"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(cardColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: cardIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(cardColor)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                if let uName = transaction.userName, !uName.isEmpty {
                    Text("👤 \(uName)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FinPilotColors.primary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(FinPilotColors.primary.opacity(0.1))
                        .cornerRadius(4)
                }

                Text(transaction.merchant ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("₹\(Int(transaction.amount)) • \(transaction.frequency.capitalized)")
                    .font(.system(size: 13))
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Text("Next: \(formatDate(transaction.nextDate))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FinPilotColors.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                if transaction.autoCreate == true {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(linkedCategory?.name ?? "Auto")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cardColor.opacity(0.14))
                    .foregroundColor(cardColor)
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Reminder")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.12))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
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
    var initialFocus: String? = nil
    
    @State private var amount = ""
    @State private var frequency = "Monthly"
    @State private var nextDueDate = Date()
    @State private var autoCreate = true
    @State private var notes = ""
    @State private var isLoading = false
    
    // Categories
    @State private var recurringCategories: [Category] = []
    @State private var expenseCategories: [Category] = []
    
    // Selected Recurring Merchant Category
    @State private var selectedRecurringCategoryId: String = ""
    @State private var selectedMerchantName: String = ""
    
    // Selected Expense Category for Auto-Creation
    @State private var selectedExpenseCategoryId: String = ""
    
    // Sheets for creating new categories
    @State private var showCreateRecurringCategorySheet = false
    @State private var showCreateExpenseCategorySheet = false
    
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    let frequencies = ["Daily", "Weekly", "Monthly", "Yearly"]
    let onSave: () async -> Void
    
    private var selectedRecurringCategory: Category? {
        recurringCategories.first(where: { $0.id == selectedRecurringCategoryId })
    }
    
    private var selectedExpenseCategory: Category? {
        expenseCategories.first(where: { $0.id == selectedExpenseCategoryId })
    }
    
    private var smartSuggestedExpenseCategory: Category? {
        let m = selectedMerchantName.lowercased()
        guard !m.isEmpty else { return nil }
        
        if m.contains("netflix") || m.contains("spotify") || m.contains("prime") || m.contains("youtube") || m.contains("hotstar") || m.contains("movie") || m.contains("stream") {
            return expenseCategories.first(where: { 
                let name = $0.name.lowercased()
                return name.contains("entertain") || name.contains("subscri") || name.contains("streaming")
            }) ?? expenseCategories.first(where: { $0.name.lowercased().contains("shop") || $0.name.lowercased().contains("util") })
        }
        
        if m.contains("wifi") || m.contains("internet") || m.contains("electric") || m.contains("bill") || m.contains("water") || m.contains("gas") || m.contains("icloud") || m.contains("cloud") || m.contains("phone") || m.contains("recharge") {
            return expenseCategories.first(where: { 
                let name = $0.name.lowercased()
                return name.contains("utilit") || name.contains("bill")
            })
        }
        
        if m.contains("rent") || m.contains("maintenance") || m.contains("house") {
            return expenseCategories.first(where: { 
                let name = $0.name.lowercased()
                return name.contains("rent") || name.contains("hous") || name.contains("utilit")
            })
        }
        
        if m.contains("gym") || m.contains("cult") || m.contains("fitness") || m.contains("yoga") {
            return expenseCategories.first(where: { 
                let name = $0.name.lowercased()
                return name.contains("health") || name.contains("fit") || name.contains("person")
            })
        }
        
        if m.contains("uber") || m.contains("ola") || m.contains("metro") || m.contains("pass") || m.contains("fuel") || m.contains("car") {
            return expenseCategories.first(where: { 
                let name = $0.name.lowercased()
                return name.contains("travel") || name.contains("trans") || name.contains("car")
            })
        }
        
        return nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            amountSection
                            merchantSection
                            scheduleSection
                            automationSection
                                .id("automationSection")
                            notesSection
                            
                            saveButton
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .onAppear {
                        if initialFocus == "automation" {
                            for delay in [0.4, 0.8, 1.2] {
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("automationSection", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: autoCreate) { val in
                        if val {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring()) {
                                    proxy.scrollTo("automationSection", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .showAddRecurring)) { notif in
                        if let focusStr = notif.object as? String, focusStr == "automation" {
                            for delay in [0.1, 0.4, 0.8] {
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("automationSection", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
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
            .sheet(isPresented: $showCreateRecurringCategorySheet) {
                NavigationView {
                    EditCategoryView(category: nil as Category?, defaultType: "recurring", onUpdate: {
                        Task {
                            await fetchCategories()
                        }
                    })
                }
            }
            .sheet(isPresented: $showCreateExpenseCategorySheet) {
                NavigationView {
                    EditCategoryView(category: nil as Category?, defaultType: "expense", onUpdate: {
                        Task {
                            await fetchCategories()
                        }
                    })
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
                await fetchCategories()
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
    
    // MARK: - Merchant / Recurring Service Section
    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MERCHANT / SERVICE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(0.8)
                
                Spacer()
                
                Button(action: { showCreateRecurringCategorySheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Service")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.horizontal, 4)
            
            if recurringCategories.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Recurring Services")
                            .font(FinPilotTypography.headline)
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Tap 'New Service' above to add your first subscription or bill provider.")
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
                    ForEach(recurringCategories) { cat in
                        Button(action: {
                            selectedRecurringCategoryId = cat.id
                            selectedMerchantName = cat.name
                            applySmartExpenseCategorySuggestion()
                        }) {
                            HStack {
                                Text(cat.name)
                                if cat.id == selectedRecurringCategoryId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: { showCreateRecurringCategorySheet = true }) {
                        Label("Add New Service...", systemImage: "plus")
                    }
                } label: {
                    HStack(spacing: 14) {
                        let catIcon = selectedRecurringCategory?.icon ?? "repeat.circle.fill"
                        let catColor = Color(hex: selectedRecurringCategory?.color ?? "#0F9D58")
                        
                        ZStack {
                            Circle()
                                .fill(catColor.opacity(0.16))
                                .frame(width: 46, height: 46)
                            
                            Image(systemName: catIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(catColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Service Provider / Merchant")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Text(selectedMerchantName.isEmpty ? (selectedRecurringCategory?.name ?? "Select Service") : selectedMerchantName)
                                .font(FinPilotTypography.headline)
                                .foregroundColor(selectedMerchantName.isEmpty ? FinPilotColors.textSecondary : FinPilotColors.textPrimary)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AUTOMATION")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(0.8)
                
                Spacer()
                
                if autoCreate {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(FinPilotColors.primary)
                            .frame(width: 6, height: 6)
                        Text("Auto-deduct ON")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FinPilotColors.primary.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Auto-create Toggle Row
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(autoCreate ? FinPilotColors.primary.opacity(0.14) : Color.gray.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(autoCreate ? FinPilotColors.primary : FinPilotColors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Auto-create Transaction")
                            .font(FinPilotTypography.subheadline)
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text(autoCreate ? "Automatically posts expense each billing cycle" : "Manual / Reminder only (no auto-deduction)")
                            .font(FinPilotTypography.caption)
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { autoCreate },
                        set: { val in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                autoCreate = val
                                if val && selectedExpenseCategoryId.isEmpty {
                                    applySmartExpenseCategorySuggestion()
                                }
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    ))
                    .labelsHidden()
                    .tint(FinPilotColors.primary)
                }
                .padding(16)
                
                // EXPENSE CATEGORY SELECTION (Visible ONLY when autoCreate is ON!)
                if autoCreate {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        // Section Subheader with Info
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("ASSIGN TO EXPENSE CATEGORY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(FinPilotColors.textSecondary)
                                    .tracking(0.8)
                                
                                Spacer()
                                
                                Button(action: { showCreateExpenseCategorySheet = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("New Category")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FinPilotColors.primary)
                                }
                            }
                            
                            Text("When auto-created, the transaction will be booked under this expense category.")
                                .font(.system(size: 12))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        
                        // Active Selected Expense Category Card / Picker Menu
                        if expenseCategories.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18))
                                
                                Text("No expense categories found. Tap 'New Category' to create one.")
                                    .font(FinPilotTypography.caption)
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        } else {
                            Menu {
                                ForEach(expenseCategories) { cat in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedExpenseCategoryId = cat.id
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }) {
                                        HStack {
                                            Text(cat.name)
                                            if cat.id == selectedExpenseCategoryId {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                Button(action: { showCreateExpenseCategorySheet = true }) {
                                    Label("Create New Expense Category...", systemImage: "plus")
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    let expColor = selectedExpenseCategory?.color != nil ? Color(hex: selectedExpenseCategory!.color!) : FinPilotColors.primary
                                    let expIcon = selectedExpenseCategory?.icon ?? "tag.fill"
                                    
                                    ZStack {
                                        Circle()
                                            .fill(expColor.opacity(0.16))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: expIcon)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(expColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(selectedExpenseCategory?.name ?? "Select Expense Category")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(FinPilotColors.textPrimary)
                                        
                                        Text("Target expense category for ledger & budgets")
                                            .font(.system(size: 11))
                                            .foregroundColor(FinPilotColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Text("Change")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(FinPilotColors.primary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(FinPilotColors.primary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(FinPilotColors.primary.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .padding(12)
                                .background(FinPilotColors.background)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(FinPilotColors.primary.opacity(0.25), lineWidth: 1.2)
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            // Horizontal quick category chip carousel
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(expenseCategories.prefix(6)) { cat in
                                        let isSel = cat.id == selectedExpenseCategoryId
                                        let cColor = cat.color != nil ? Color(hex: cat.color!) : FinPilotColors.primary
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedExpenseCategoryId = cat.id
                                            }
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.icon ?? "tag.fill")
                                                    .font(.system(size: 11, weight: .bold))
                                                Text(cat.name)
                                                    .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(isSel ? cColor : FinPilotColors.background)
                                            .foregroundColor(isSel ? .white : FinPilotColors.textPrimary)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            // Smart Suggestion Chip (if detected and not currently selected)
                            if let suggested = smartSuggestedExpenseCategory, suggested.id != selectedExpenseCategoryId {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedExpenseCategoryId = suggested.id
                                    }
                                    let gen = UIImpactFeedbackGenerator(style: .medium)
                                    gen.impactOccurred()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(Color.orange)
                                            .font(.system(size: 12, weight: .bold))
                                        Text("Suggested for \(selectedMerchantName):")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(FinPilotColors.textSecondary)
                                        Text(suggested.name)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(FinPilotColors.primary)
                                        Text("• Tap to apply")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color.orange)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                } else {
                    // When autoCreate is OFF, informational note
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(FinPilotColors.textSecondary)
                            .font(.system(size: 15))
                        
                        Text("Auto-creation is disabled. FinPilot will only track schedule & due dates without posting to your expense ledger.")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(FinPilotColors.background.opacity(0.6))
                    .cornerRadius(12)
                    .padding(16)
                }
            }
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
    private var isFormValid: Bool {
        let cleanAmt = amount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let num = Double(cleanAmt), num > 0 else { return false }
        guard !selectedMerchantName.isEmpty || selectedRecurringCategory != nil else { return false }
        if autoCreate && selectedExpenseCategoryId.isEmpty { return false }
        return !isLoading
    }
    
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
        .disabled(!isFormValid)
        .opacity(!isFormValid ? 0.55 : 1.0)
    }
    
    // MARK: - API Helpers & Logic
    private func applySmartExpenseCategorySuggestion() {
        if let suggested = smartSuggestedExpenseCategory {
            selectedExpenseCategoryId = suggested.id
        } else if selectedExpenseCategoryId.isEmpty, let first = expenseCategories.first {
            selectedExpenseCategoryId = first.id
        }
    }

    private func fetchCategories() async {
        do {
            let roots: [Category] = try await APIManager.shared.request(endpoint: "/categories")
            var allCats: [Category] = []
            func collect(_ list: [Category]) {
                for c in list {
                    allCats.append(c)
                    if let subs = c.subcategories {
                        collect(subs)
                    }
                }
            }
            collect(roots)
            
            let recurringCats = allCats.filter { $0.type.lowercased() == "recurring" }
            let expenseCats = allCats.filter { $0.type.lowercased() == "expense" }
            
            await MainActor.run {
                self.recurringCategories = recurringCats
                self.expenseCategories = expenseCats
                
                if self.selectedRecurringCategoryId.isEmpty, let first = recurringCats.first {
                    self.selectedRecurringCategoryId = first.id
                    self.selectedMerchantName = first.name
                }
                
                if self.selectedExpenseCategoryId.isEmpty {
                    self.applySmartExpenseCategorySuggestion()
                }
            }
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }

    private func saveTransaction() async {
        let cleanAmountStr = amount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let numAmount = Double(cleanAmountStr), numAmount > 0 else {
            await MainActor.run {
                errorMessage = "Please enter a valid amount greater than 0"
                showErrorAlert = true
            }
            return
        }
        
        let merchantName = !selectedMerchantName.isEmpty ? selectedMerchantName : (selectedRecurringCategory?.name ?? "Subscription")
        
        if autoCreate && selectedExpenseCategoryId.isEmpty {
            await MainActor.run {
                errorMessage = "Please select an expense category for auto-creation."
                showErrorAlert = true
            }
            return
        }
        
        var payload: [String: Any] = [
            "type": "expense",
            "amount": numAmount,
            "merchant": merchantName,
            "frequency": frequency.lowercased(),
            "next_due_date": nextDueDate.ISO8601Format().components(separatedBy: "T")[0],
            "auto_create": autoCreate
        ]
        
        // If auto_create is enabled, save under the selected expense category so auto-created transactions book to that category!
        if autoCreate && !selectedExpenseCategoryId.isEmpty {
            payload["category_id"] = selectedExpenseCategoryId
        } else if !selectedRecurringCategoryId.isEmpty {
            payload["category_id"] = selectedRecurringCategoryId
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            payload["notes"] = trimmedNotes
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
