import re

with open("iOS/FinPilotAI/Sources/Features/Budgets/BudgetsView.swift", "r") as f:
    content = f.read()

# Add @Query and SwiftData import
content = content.replace("import SwiftUI\n\nstruct MockBudgetCategory", "import SwiftUI\nimport SwiftData\n\nstruct MockBudgetCategory")

old_view = """struct BudgetsView: View {
    @State private var selectedPeriod = 0 // 0 = Monthly, 1 = Weekly
    let periods = ["Monthly", "Weekly"]
    
    let categories = [
        MockBudgetCategory(name: "Food & Dining", icon: "cup.and.saucer.fill", color: .orange, spent: 12000, total: 15000),
        MockBudgetCategory(name: "Transport", icon: "car.fill", color: .blue, spent: 4500, total: 8000),
        MockBudgetCategory(name: "Shopping", icon: "bag.fill", color: .pink, spent: 6000, total: 7000)
    ]"""

new_view = """struct BudgetsView: View {
    @State private var selectedPeriod = 0 // 0 = Monthly, 1 = Weekly
    let periods = ["Monthly", "Weekly"]
    
    @Query(sort: \\Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    private var categories: [MockBudgetCategory] {
        let expenses = transactions.filter { $0.amount < 0 }
        
        // Filter by period (mock implementation: just scale totals for weekly)
        let isWeekly = selectedPeriod == 1
        
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (cat, txs) in
            let spent = txs.reduce(0) { $0 + abs($1.amount) }
            let baseTotal: Double = cat == "Food" ? 15000 : (cat == "Transport" ? 8000 : 7000)
            let total = isWeekly ? baseTotal / 4.0 : baseTotal
            
            return MockBudgetCategory(
                name: cat,
                icon: iconForCategory(cat),
                color: colorForCategory(cat),
                spent: spent,
                total: total
            )
        }.sorted { $0.spent > $1.spent }
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
    }"""

content = content.replace(old_view, new_view)

# Also fix the donutChartSection to calculate from actual categories
old_donut = """    private var donutChartSection: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(FinPilotColors.surface, lineWidth: 20)
                
                // Simplified mock donut chart
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(FinPilotColors.primary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("Total Budget")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("₹ 30,000")
                        .font(FinPilotTypography.title2)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("₹ 11,580 left")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
            }
            .frame(height: 200)
            .padding(20)
        }
    }"""

new_donut = """    private var donutChartSection: some View {
        let totalBudget = categories.reduce(0) { $0 + $1.total }
        let totalSpent = categories.reduce(0) { $0 + $1.spent }
        let progress = totalBudget > 0 ? min(1.0, totalSpent / totalBudget) : 0
        let left = max(0, totalBudget - totalSpent)
        
        return VStack {
            ZStack {
                Circle()
                    .stroke(FinPilotColors.surface, lineWidth: 20)
                
                // Simplified mock donut chart
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(FinPilotColors.primary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("Total Budget")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("₹ \(totalBudget.formatted(.number.precision(.fractionLength(0))))")
                        .font(FinPilotTypography.title2)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("₹ \(left.formatted(.number.precision(.fractionLength(0)))) left")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
            }
            .frame(height: 200)
            .padding(20)
        }
    }"""

content = content.replace(old_donut, new_donut)

with open("iOS/FinPilotAI/Sources/Features/Budgets/BudgetsView.swift", "w") as f:
    f.write(content)

