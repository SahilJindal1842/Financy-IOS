import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var avatar: String? = nil
    @Published var monthlyIncome: Double = 0.0
    @Published var totalIncome: Double = 0.0
    @Published var totalExpenses: Double = 0.0
    @Published var balance: Double = 0.0
    @Published var availableMoney: Double = 0.0
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
    
    // Settlement & Savings Module
    @Published var isSettled: Bool = false
    @Published var isEndOfMonth: Bool = false
    @Published var endOfMonthDate: String = ""
    @Published var settlementMonth: String = ""
    @Published var leftoverSavings: Double = 0.0
    @Published var totalAccumulatedSavings: Double = 0.0
    @Published var isSettling: Bool = false
    @Published var settlementSuccessMessage: String? = nil
    
    // Month-wise filtering
    @Published var selectedMonth: String = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return df.string(from: Date())
    }()
    
    @Published var displayMonthName: String = {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: Date())
    }()
    
    struct MonthOption: Identifiable, Hashable {
        let id: String
        let key: String
        let label: String
    }
    
    var availableMonths: [MonthOption] {
        let calendar = Calendar.current
        let now = Date()
        var options: [MonthOption] = []
        
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"
        
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMMM yyyy"
        
        for offset in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -offset, to: now) {
                let key = keyFormatter.string(from: date)
                let label = labelFormatter.string(from: date)
                options.append(MonthOption(id: key, key: key, label: label))
            }
        }
        return options
    }
    
    func selectMonth(_ monthKey: String, displayName: String, userRole: String? = nil) async {
        self.selectedMonth = monthKey
        self.displayMonthName = displayName
        await loadDashboardData(userRole: userRole, month: monthKey)
    }

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
    
    func loadDashboardData(targetUserId: String? = nil, userRole: String? = nil, month: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        if let month = month {
            self.selectedMonth = month
            let dfIn = DateFormatter()
            dfIn.dateFormat = "yyyy-MM"
            if let d = dfIn.date(from: month) {
                let dfOut = DateFormatter()
                dfOut.dateFormat = "MMMM yyyy"
                self.displayMonthName = dfOut.string(from: d)
            }
        }
        
        let role = userRole?.uppercased()
        let adminMode = (role == "ADMIN") || self.isAdmin
        
        do {
            let endpoint: String
            if adminMode {
                let uid = targetUserId ?? selectedUserId
                if uid == "all" || uid.isEmpty {
                    endpoint = "/admin/dashboard?month=\(selectedMonth)"
                } else {
                    endpoint = "/admin/dashboard?user_id=\(uid)&month=\(selectedMonth)"
                }
            } else {
                endpoint = "/users/dashboard?month=\(selectedMonth)"
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
            let avail = stats.availableMoney ?? stats.balance
            self.availableMoney = avail
            self.balance = avail
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
            
            self.isSettled = stats.isSettled ?? false
            self.isEndOfMonth = stats.isEndOfMonth ?? false
            self.endOfMonthDate = stats.endOfMonthDate ?? ""
            self.settlementMonth = stats.settlementMonth ?? ""
            self.leftoverSavings = stats.leftoverSavings ?? 0.0
            self.totalAccumulatedSavings = stats.totalAccumulatedSavings ?? 0.0
            
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
    
    func settleCurrentMonth(notes: String? = nil, userRole: String? = nil) async -> Bool {
        isSettling = true
        errorMessage = nil
        do {
            var bodyObj: [String: Any] = [:]
            if !settlementMonth.isEmpty {
                bodyObj["month"] = settlementMonth
            }
            if let n = notes, !n.isEmpty {
                bodyObj["notes"] = n
            }
            if selectedUserId != "all" && !selectedUserId.isEmpty {
                bodyObj["user_id"] = selectedUserId
            }
            let data = try JSONSerialization.data(withJSONObject: bodyObj)
            let res: SettlementResultResponse = try await APIManager.shared.request(endpoint: "/settlement/settle", method: "POST", body: data)
            self.settlementSuccessMessage = res.message
            
            await loadDashboardData(targetUserId: selectedUserId, userRole: userRole)
            NotificationCenter.default.post(name: .transactionUpdated, object: nil)
            isSettling = false
            return true
        } catch {
            print("Failed to settle month: \(error)")
            self.errorMessage = error.localizedDescription
            isSettling = false
            return false
        }
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
        availableMoney = 0.0
        savings = 0.0
        budget = 0.0
        remainingBudget = 0.0
        budgetUsedPercentage = 0.0
        incomeGrowth = 0.0
        expenseGrowth = 0.0
        savingsGrowth = 0.0
        isSettled = false
        isEndOfMonth = false
        endOfMonthDate = ""
        settlementMonth = ""
        leftoverSavings = 0.0
        totalAccumulatedSavings = 0.0
        isSettling = false
        settlementSuccessMessage = nil
        currency = "INR"
        transactions = []
        upcomingBills = []
        isLoading = false
        errorMessage = nil
    }
}
