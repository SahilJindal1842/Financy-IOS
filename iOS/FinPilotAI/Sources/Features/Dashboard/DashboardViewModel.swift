import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var monthlyIncome: Double = 0.0
    @Published var totalIncome: Double = 0.0
    @Published var totalExpenses: Double = 0.0
    @Published var totalSpent: Double = 0.0
    @Published var totalBalance: Double = 0.0
    @Published var savings: Double = 0.0
    @Published var budget: Double = 0.0
    @Published var currency: String = "INR"
    @Published var transactionsCount: Int = 0
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        do {
            let stats: DashboardStats = try await APIManager.shared.request(endpoint: "/users/dashboard")
            self.userName = stats.userName
            self.currency = stats.currency
            self.monthlyIncome = stats.monthlyIncome
            self.totalIncome = stats.totalIncome
            self.totalExpenses = stats.totalExpenses
            self.totalSpent = stats.totalSpent
            self.totalBalance = stats.balance
            self.savings = stats.savings
            self.budget = stats.budget
            self.transactionsCount = stats.transactionsCount
            self.transactions = stats.recentTransactions ?? []
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
            do {
                let txs: [Transaction] = try await APIManager.shared.request(endpoint: "/transactions")
                self.transactions = txs
                self.totalSpent = txs.filter { $0.amount < 0 || $0.type.lowercased() == "expense" }.reduce(0) { $0 + abs($1.amount) }
            } catch {
                print("Failed to fallback load transactions: \(error)")
            }
        }
        isLoading = false
    }
    
    func reset() {
        userName = ""
        monthlyIncome = 0.0
        totalIncome = 0.0
        totalExpenses = 0.0
        totalSpent = 0.0
        totalBalance = 0.0
        savings = 0.0
        budget = 0.0
        currency = "INR"
        transactionsCount = 0
        transactions = []
        isLoading = false
        errorMessage = nil
    }
}
