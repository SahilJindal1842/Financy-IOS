import re

with open("iOS/FinPilotAI/Sources/Features/AIInsights/AIInsightsView.swift", "r") as f:
    content = f.read()

content = content.replace("import SwiftUI\nimport Charts\n\nstruct MockChartData", "import SwiftUI\nimport SwiftData\nimport Charts\n\nstruct MockChartData")

old_view = """struct AIInsightsView: View {
    let chartData: [MockChartData] = [
        MockChartData(day: "Mon", amount: 120),
        MockChartData(day: "Tue", amount: 80),
        MockChartData(day: "Wed", amount: 250),
        MockChartData(day: "Thu", amount: 150),
        MockChartData(day: "Fri", amount: 300),
        MockChartData(day: "Sat", amount: 400),
        MockChartData(day: "Sun", amount: 200)
    ]
    
    let topCategories: [MockCategoryInsight] = [
        MockCategoryInsight(name: "Food & Beverage", icon: "cup.and.saucer.fill", color: .orange, percentage: 35.5, amount: "₹ 12,000"),
        MockCategoryInsight(name: "Shopping", icon: "bag.fill", color: .pink, percentage: 22.0, amount: "₹ 7,500")
    ]"""

new_view = """struct AIInsightsView: View {
    @Query(sort: \\Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    private var expenses: [Transaction] {
        transactions.filter { $0.amount < 0 }
    }
    
    private var chartData: [MockChartData] {
        let df = DateFormatter()
        df.dateFormat = "EEE" // e.g. Mon, Tue
        
        let grouped = Dictionary(grouping: expenses, by: { df.string(from: $0.date) })
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        return days.map { day in
            let total = grouped[day]?.reduce(0) { $0 + abs($1.amount) } ?? 0
            return MockChartData(day: day, amount: total)
        }
    }
    
    private var topCategories: [MockCategoryInsight] {
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        guard totalExpenses > 0 else { return [] }
        
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (cat, txs) in
            let catTotal = txs.reduce(0) { $0 + abs($1.amount) }
            return MockCategoryInsight(
                name: cat,
                icon: iconForCategory(cat),
                color: colorForCategory(cat),
                percentage: (catTotal / totalExpenses) * 100,
                amount: "₹ \(catTotal.formatted(.number.precision(.fractionLength(0))))"
            )
        }.sorted { $0.percentage > $1.percentage }.prefix(3).map { $0 }
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

with open("iOS/FinPilotAI/Sources/Features/AIInsights/AIInsightsView.swift", "w") as f:
    f.write(content)

