import SwiftUI

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetsViewModel()
    @State private var showingSetBudget = false
    @State private var selectedCategoryId: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                if let summary = viewModel.summary {
                    ScrollView {
                        VStack(spacing: 24) {
                            donutChartSection(summary: summary)
                            categoryListSection(summary: summary)
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.fetchBudgets()
                    }
                } else {
                    VStack {
                        Text("No Budget Data")
                            .font(FinPilotTypography.headline)
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Budgets")
                        .font(FinPilotTypography.title3)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedCategoryId = nil
                        showingSetBudget = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(FinPilotColors.primary)
                    }
                }
            }
            .task {
                await viewModel.fetchBudgets()
            }
            .sheet(isPresented: $showingSetBudget) {
                SetBudgetView(viewModel: viewModel, initialCategoryId: selectedCategoryId)
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing Budgets...")
    }
    
    @ViewBuilder
    private func donutChartSection(summary: BudgetSummaryResponse) -> some View {
        VStack {
            ZStack {
                // Background Track
                Circle()
                    .stroke(lineWidth: 24)
                    .foregroundColor(FinPilotColors.surface)
                
                // Progress
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(summary.overallUsagePercentage / 100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round))
                    .foregroundColor(statusColor(for: summary.overallUsagePercentage))
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.easeInOut, value: summary.overallUsagePercentage)
                
                // Inner Text
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text(String(format: "₹ %.0f", summary.totalSpent))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text(String(format: "of ₹ %.0f", summary.totalBudget))
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.vertical, 20)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Remaining")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text(String(format: "₹ %.0f", summary.remainingBudget))
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                
                VStack {
                    Text("Usage")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text(String(format: "%.1f%%", summary.overallUsagePercentage))
                        .font(FinPilotTypography.headline)
                        .foregroundColor(statusColor(for: summary.overallUsagePercentage))
                }
            }
        }
        .padding()
        .background(FinPilotColors.surface)
        .cornerRadius(24)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private func categoryListSection(summary: BudgetSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Category-wise Spending")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(summary.budgets) { budget in
                    let category = viewModel.categories.first(where: { $0.id == budget.categoryId })
                    Button(action: {
                        selectedCategoryId = budget.categoryId
                        showingSetBudget = true
                    }) {
                        BudgetCategoryRow(budget: budget, category: category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func statusColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<70:
            return FinPilotColors.success
        case 70..<90:
            return FinPilotColors.warning
        case 90...100:
            return FinPilotColors.critical
        default:
            return FinPilotColors.error
        }
    }
}

struct BudgetCategoryRow: View {
    let budget: Budget
    let category: Category?
    
    private var statusColor: Color {
        switch budget.usagePercentage {
        case 0..<70:
            return FinPilotColors.success
        case 70..<90:
            return FinPilotColors.warning
        case 90...100:
            return FinPilotColors.critical
        default:
            return FinPilotColors.error
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: category?.icon ?? "creditcard.fill")
                    .foregroundColor(statusColor)
                    .frame(width: 40, height: 40)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category?.name ?? "Unknown")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("\(String(format: "%.1f", budget.usagePercentage))% used")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "₹ %.0f", budget.spent))
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text(String(format: "Left ₹ %.0f", budget.remaining))
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
            }
            
            // Custom Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FinPilotColors.background)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(statusColor)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(budget.usagePercentage / 100.0), geometry.size.width)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct SetBudgetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BudgetsViewModel
    @State var initialCategoryId: String?
    
    @State private var budgetAmounts: [String: String] = [:]
    
    var expenseCategories: [Category] {
        viewModel.categories.filter { $0.type.lowercased() == "expense" }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Categories")) {
                    ForEach(expenseCategories, id: \.id) { cat in
                        HStack {
                            Image(systemName: cat.icon ?? "creditcard.fill")
                                .foregroundColor(FinPilotColors.primary)
                                .frame(width: 24, height: 24)
                            Text(cat.name)
                            Spacer()
                            Text("₹")
                                .foregroundColor(FinPilotColors.textSecondary)
                            TextField("0", text: Binding(
                                get: { budgetAmounts[cat.id] ?? "" },
                                set: { budgetAmounts[cat.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        }
                    }
                }
                
                Section {
                    Button("Save Budget") {
                        var bulkData: [[String: Any]] = []
                        for cat in expenseCategories {
                            let amtString = budgetAmounts[cat.id] ?? ""
                            if let amt = Double(amtString.replacingOccurrences(of: ",", with: "")) {
                                bulkData.append(["category_id": cat.id, "amount": amt])
                            } else {
                                bulkData.append(["category_id": cat.id, "amount": 0.0])
                            }
                        }
                        
                        Task {
                            await viewModel.setBulkBudgets(budgets: bulkData)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(FinPilotColors.primary)
                }
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                for cat in expenseCategories {
                    if let existingBudget = viewModel.summary?.budgets.first(where: { $0.categoryId == cat.id }) {
                        budgetAmounts[cat.id] = String(Int(existingBudget.amount))
                    } else {
                        budgetAmounts[cat.id] = ""
                    }
                }
            }
        }
    }
}
