import re

with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "r") as f:
    content = f.read()

# Add @Query and SwiftData import
content = content.replace("import SwiftUI\n\nstruct MockTransaction", "import SwiftUI\nimport SwiftData\n\nstruct MockTransaction")

# In TransactionsView, replace groupedTransactions with SwiftData
old_view = """struct TransactionsView: View {
    @State private var selectedFilter = 0 // 0 = All, 1 = Expenses, 2 = Income
    let filters = ["All", "Expenses", "Income"]
    
    let groupedTransactions: [MockTransactionGroup] = [
        MockTransactionGroup(dateStr: "Today", transactions: [
            MockTransaction(icon: "cup.and.saucer.fill", iconColor: .orange, title: "Starbucks", subtitle: "Food & Beverage • 09:30 AM", amount: "-₹ 350", isIncome: false),
            MockTransaction(icon: "car.fill", iconColor: .blue, title: "Uber", subtitle: "Transport • 11:15 AM", amount: "-₹ 450", isIncome: false)
        ]),
        MockTransactionGroup(dateStr: "16 Sep 2025", transactions: [
            MockTransaction(icon: "cart.fill", iconColor: .green, title: "Whole Foods", subtitle: "Groceries • 02:45 PM", amount: "-₹ 2,400", isIncome: false),
            MockTransaction(icon: "arrow.down.left.circle.fill", iconColor: FinPilotColors.success, title: "Salary", subtitle: "Income • 09:00 AM", amount: "+₹ 85,000", isIncome: true)
        ])
    ]"""

new_view = """struct TransactionsView: View {
    @State private var selectedFilter = 0 // 0 = All, 1 = Expenses, 2 = Income
    let filters = ["All", "Expenses", "Income"]
    
    @Query(sort: \\Transaction.date, order: .reverse) private var transactions: [Transaction]
"""

content = content.replace(old_view, new_view)

# Update filteredGroups
old_filter = """    private var filteredGroups: [MockTransactionGroup] {
        groupedTransactions.compactMap { group in
            let filtered = group.transactions.filter { tx in
                if selectedFilter == 1 { return !tx.isIncome }
                if selectedFilter == 2 { return tx.isIncome }
                return true
            }
            if filtered.isEmpty { return nil }
            return MockTransactionGroup(dateStr: group.dateStr, transactions: filtered)
        }
    }"""

new_filter = """    private var filteredGroups: [MockTransactionGroup] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.doesRelativeDateFormatting = true
        
        let tf = DateFormatter()
        tf.timeStyle = .short
        
        // Filter first
        let filteredTxs = transactions.filter { tx in
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
                    icon: iconForCategory(tx.category),
                    iconColor: colorForCategory(tx.category),
                    title: tx.merchant,
                    subtitle: "\(tx.category) • \(tf.string(from: tx.date))",
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
    }"""

content = content.replace(old_filter, new_filter)

with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "w") as f:
    f.write(content)

