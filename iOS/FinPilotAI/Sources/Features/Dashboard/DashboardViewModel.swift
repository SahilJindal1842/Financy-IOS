import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var avatar: String? = nil
    @Published var monthlyIncome: Double = 0.0
    @Published var totalIncome: Double = 0.0
    @Published var totalExpenses: Double = 0.0
    @Published var balance: Double = 0.0
    @Published var savings: Double = 0.0
    @Published var budget: Double = 0.0
    @Published var remainingBudget: Double = 0.0
    @Published var budgetUsedPercentage: Double = 0.0
    @Published var incomeGrowth: Double = 0.0
    @Published var expenseGrowth: Double = 0.0
    @Published var savingsGrowth: Double = 0.0
    @Published var currency: String = "INR"
    @Published var transactions: [Transaction] = []
    @Published var upcomingBills: [UpcomingBill] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Admin features
    @Published var isAdmin: Bool = false
    @Published var isConsolidated: Bool = false
    @Published var adminUsers: [AdminUser] = []
    @Published var selectedUserId: String = "all"
    @Published var selectedUserName: String = "All Users"
    @Published var totalUsersCount: Int = 0
    
    func fetchAdminUsers() async {
        do {
            let users: [AdminUser] = try await APIManager.shared.request(endpoint: "/admin/users")
            self.adminUsers = users
            self.totalUsersCount = users.count
        } catch {
            print("Failed to fetch admin users: \(error)")
        }
    }
    
    func loadDashboardData(targetUserId: String? = nil, userRole: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        let role = userRole?.uppercased()
        let adminMode = (role == "ADMIN") || self.isAdmin
        
        do {
            let endpoint: String
            if adminMode {
                let uid = targetUserId ?? selectedUserId
                if uid == "all" || uid.isEmpty {
                    endpoint = "/admin/dashboard"
                } else {
                    endpoint = "/admin/dashboard?user_id=\(uid)"
                }
            } else {
                endpoint = "/users/dashboard"
            }
            
            let stats: DashboardStats = try await APIManager.shared.request(endpoint: endpoint)
            self.isAdmin = stats.isAdmin ?? adminMode
            self.isConsolidated = stats.isConsolidated ?? false
            self.totalUsersCount = stats.totalUsers ?? self.totalUsersCount
            self.userName = stats.userName
            self.avatar = stats.avatar
            self.currency = stats.currency
            self.monthlyIncome = stats.monthlyIncome
            self.totalIncome = stats.totalIncome
            self.totalExpenses = stats.totalExpenses
            self.balance = stats.balance
            self.savings = stats.savings
            
            let budgetVal = stats.totalBudget ?? stats.budget ?? 0.0
            self.budget = budgetVal
            self.remainingBudget = stats.remainingBudget ?? budgetVal
            self.budgetUsedPercentage = stats.budgetUsedPercentage ?? 0
            self.incomeGrowth = stats.incomeGrowth ?? 0
            self.expenseGrowth = stats.expenseGrowth ?? 0
            self.savingsGrowth = stats.savingsGrowth ?? 0
            self.transactions = stats.transactions ?? []
            self.upcomingBills = stats.upcomingBills ?? []
            
            if adminMode && adminUsers.isEmpty {
                await fetchAdminUsers()
            }
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
            do {
                let txs: [Transaction] = try await APIManager.shared.request(endpoint: "/transactions")
                self.transactions = txs
            } catch {
                print("Failed to fallback load transactions: \(error)")
            }
        }
        isLoading = false
    }
    
    func selectUser(id: String, name: String, userRole: String?) async {
        self.selectedUserId = id
        self.selectedUserName = name
        await loadDashboardData(targetUserId: id, userRole: userRole)
    }
    
    func reset() {
        userName = ""
        avatar = nil
        monthlyIncome = 0.0
        totalIncome = 0.0
        totalExpenses = 0.0
        balance = 0.0
        savings = 0.0
        budget = 0.0
        remainingBudget = 0.0
        budgetUsedPercentage = 0.0
        incomeGrowth = 0.0
        expenseGrowth = 0.0
        savingsGrowth = 0.0
        currency = "INR"
        transactions = []
        upcomingBills = []
        isLoading = false
        errorMessage = nil
    }
}
