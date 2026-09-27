import SwiftUI

struct MockTransaction: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let isIncome: Bool
}

struct MockTransactionGroup: Identifiable {
    let id = UUID()
    let dateStr: String
    let transactions: [MockTransaction]
}

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var selectedFilter = 0 // 0 = All, 1 = Expenses, 2 = Income
    let filters = ["All", "Expenses", "Income"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Segmented Picker
                HStack {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Button(action: {
                            selectedFilter = index
                        }) {
                            Text(filters[index])
                                .font(FinPilotTypography.subheadline)
                                .foregroundColor(selectedFilter == index ? .white : FinPilotColors.textSecondary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedFilter == index ? FinPilotColors.primary : Color.clear)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(4)
                .background(FinPilotColors.surface)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(FinPilotColors.error)
                            .padding()
                    } else if viewModel.transactions.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Text("No transactions yet. Tap + to add one!")
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(filteredGroups) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(group.dateStr)
                                        .font(FinPilotTypography.headline)
                                        .foregroundColor(FinPilotColors.textPrimary)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(group.transactions) { tx in
                                            TransactionsTabRow(tx: tx)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 24)
                        
                    }
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transactions")
                        .font(FinPilotTypography.title3)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
            }
            .task {
                await viewModel.fetchTransactions()
            }
            .refreshable {
                await viewModel.fetchTransactions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                Task {
                    await viewModel.fetchTransactions()
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing...")
    }
    
    private var filteredGroups: [MockTransactionGroup] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.doesRelativeDateFormatting = true
        
        let tf = DateFormatter()
        tf.timeStyle = .short
        
        // Filter first
        let filteredTxs = viewModel.transactions.filter { tx in
            if selectedFilter == 1 { return tx.amount < 0 } // Expenses
            if selectedFilter == 2 { return tx.amount >= 0 } // Income
            return true
        }
        
        // Group by date string
        let grouped = Dictionary(grouping: filteredTxs) { tx -> String in
            return df.string(from: tx.date)
        }
        
        // Sort keys (descending dates roughly, we'll just use the first tx date)
        let sortedKeys = grouped.keys.sorted { k1, k2 in
            let tx1 = grouped[k1]?.first?.date ?? Date()
            let tx2 = grouped[k2]?.first?.date ?? Date()
            return tx1 > tx2
        }
        
        return sortedKeys.map { key in
            let txs = grouped[key] ?? []
            let mockTxs = txs.map { tx in
                MockTransaction(
                    icon: iconForCategory(tx.categoryId ?? ""),
                    iconColor: colorForCategory(tx.categoryId ?? ""),
                    title: tx.merchant ?? "Unknown",
                    subtitle: "\(tx.categoryId ?? "Unknown") • \(tf.string(from: tx.date))",
                    amount: "\(tx.amount < 0 ? "-" : "+")₹ \(abs(tx.amount).formatted(.number.precision(.fractionLength(0))))",
                    isIncome: tx.amount >= 0
                )
            }
            return MockTransactionGroup(dateStr: key, transactions: mockTxs)
        }
    }
    
    private func iconForCategory(_ cat: String) -> String {
        switch cat {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Bills": return "doc.text.fill"
        case "Health": return "heart.fill"
        default: return "creditcard.fill"
        }
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "Food": return .orange
        case "Transport": return .blue
        case "Shopping": return .pink
        case "Bills": return .purple
        case "Health": return .red
        default: return .gray
        }
    }
}

struct TransactionsTabRow: View {
    let tx: MockTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tx.icon)
                .font(.title3)
                .foregroundColor(tx.iconColor)
                .frame(width: 48, height: 48)
                .background(tx.iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title)
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
                Text(tx.subtitle)
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
            
            Text(tx.amount)
                .font(FinPilotTypography.headline)
                .foregroundColor(tx.isIncome ? FinPilotColors.success : FinPilotColors.textPrimary)
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TransactionsViewModel()
    
    @State private var transactionType: String = "Expense"
    let transactionTypes = ["Income", "Expense", "Transfer"]
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var showingBudgetAlert = false
    @State private var budgetAlertMessage = ""
    
    // Transfer specific
    @State private var fromAccount: String = "Checking"
    @State private var toAccount: String = "Savings"
    let mockAccounts = ["Checking", "Savings", "Credit Card", "Investment"]
    
    @State private var showingNewCategoryAlert = false
    @State private var newCategoryName = ""
    
    // We will merge fetched categories with the user's custom one if they type it.

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Picker for Type
                Picker("Type", selection: $transactionType) {
                    ForEach(transactionTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        amountInputSection
                        if transactionType == "Transfer" {
                            transferAccountsSection
                        } else {
                            categorySection
                        }
                        detailsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 100) // Space for sticky button
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add \(transactionType)")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
            }
            .overlay(
                saveButton
                , alignment: .bottom
            )
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Saving...")
        .task {
            await viewModel.fetchCategories()
        }
        .alert("New Category", isPresented: $showingNewCategoryAlert) {
            TextField("Category Name", text: $newCategoryName)
            Button("Add") {
                if !newCategoryName.isEmpty {
                    selectedCategory = newCategoryName
                }
            }
            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
        }
        .alert(isPresented: $showingBudgetAlert) {
            Alert(
                title: Text("Budget Exceeded"),
                message: Text(budgetAlertMessage),
                primaryButton: .destructive(Text("Proceed")) {
                    saveTransaction(ignoreBudget: true)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Enter Amount")
                .font(FinPilotTypography.subheadline)
                .foregroundColor(FinPilotColors.textSecondary)
            
            HStack(spacing: 4) {
                Text("₹")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                TextField("0", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .fixedSize()
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Category")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            let displayCategories = viewModel.categories.filter { $0.type.lowercased() == transactionType.lowercased() }
            
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 20) {
                ForEach(displayCategories, id: \.id) { category in
                    CategoryIcon(
                        title: category.name,
                        icon: category.icon ?? "tag.fill",
                        color: colorForHexString(category.color),
                        isSelected: selectedCategory == category.name
                    )
                    .onTapGesture {
                        selectedCategory = category.name
                    }
                }
                
                if !newCategoryName.isEmpty && !displayCategories.contains(where: { $0.name == newCategoryName }) {
                    CategoryIcon(
                        title: newCategoryName,
                        icon: "star.fill",
                        color: .blue,
                        isSelected: selectedCategory == newCategoryName
                    )
                    .onTapGesture {
                        selectedCategory = newCategoryName
                    }
                }
                
                CategoryIcon(
                    title: "Add New",
                    icon: "plus",
                    color: .gray,
                    isSelected: false
                )
                .onTapGesture {
                    showingNewCategoryAlert = true
                }
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
    
    private var transferAccountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transfer Details")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("From")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Spacer()
                    Picker("From Account", selection: $fromAccount) {
                        ForEach(mockAccounts, id: \.self) { acc in
                            Text(acc).tag(acc)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(12)
                
                HStack {
                    Text("To")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Spacer()
                    Picker("To Account", selection: $toAccount) {
                        ForEach(mockAccounts, id: \.self) { acc in
                            Text(acc).tag(acc)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(12)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(FinPilotColors.textSecondary)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .font(FinPilotTypography.body)
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(12)
            
            HStack {
                Image(systemName: "pencil")
                    .foregroundColor(FinPilotColors.textSecondary)
                TextField("Note", text: $note)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(12)
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveTransaction(ignoreBudget: false)
        }) {
            ZStack {
                Text("Save \(transactionType)")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .padding(.vertical, 18)
            .background(FinPilotColors.primary.opacity(viewModel.isLoading ? 0.7 : 1.0))
            .cornerRadius(16)
            .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [FinPilotColors.background.opacity(0), FinPilotColors.background]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func saveTransaction(ignoreBudget: Bool) {
        if let amountDouble = Double(amount.replacingOccurrences(of: ",", with: "")) {
            Task {
                if transactionType == "Expense" && !ignoreBudget {
                    if let alertMsg = await viewModel.checkBudgetExceeded(categoryId: selectedCategory, amount: amountDouble) {
                        budgetAlertMessage = alertMsg
                        showingBudgetAlert = true
                        return
                    }
                }
                
                let finalAmount = transactionType == "Expense" ? -amountDouble : amountDouble
                let typeString = transactionType.lowercased()
                let cat = transactionType == "Transfer" ? "Transfer" : selectedCategory
                
                let destAcc = transactionType == "Transfer" ? toAccount : nil
                let srcAcc = transactionType == "Transfer" ? fromAccount : "default"
                
                await viewModel.addTransaction(
                    amount: finalAmount,
                    merchant: cat,
                    category: cat,
                    date: date,
                    note: note.isEmpty ? nil : note,
                    type: typeString,
                    accountId: srcAcc,
                    destinationAccountId: destAcc
                )
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CategoryIcon: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? FinPilotColors.textPrimary : FinPilotColors.textSecondary)
        }
    }
}
