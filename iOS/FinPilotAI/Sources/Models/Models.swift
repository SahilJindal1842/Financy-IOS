import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let name: String
    let monthlyIncome: Double?
    let currency: String?
    let primaryGoal: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: String,
        email: String? = nil,
        name: String,
        monthlyIncome: Double? = nil,
        currency: String? = nil,
        primaryGoal: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.monthlyIncome = monthlyIncome
        self.currency = currency
        self.primaryGoal = primaryGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name, currency
        case monthlyIncome = "monthly_income"
        case primaryGoal = "primary_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DashboardStats: Codable {
    let userName: String
    let currency: String
    let monthlyIncome: Double
    let totalIncome: Double
    let totalExpenses: Double
    let totalSpent: Double
    let balance: Double
    let savings: Double
    let budget: Double
    let transactionsCount: Int
    let recentTransactions: [Transaction]?
}

struct Account: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let type: String
    let balance: Double
    let currency: String
    let createdAt: Date?
    let updatedAt: Date?
}

struct Category: Codable, Identifiable {
    let id: String
    let userId: String?
    let parentId: String?
    let name: String
    let type: String // e.g. "income", "expense"
    let icon: String?
    let color: String?
    let createdAt: Date?
    let updatedAt: Date?
    let subcategories: [Category]?
}

struct Transaction: Codable, Identifiable {
    let id: String
    let accountId: String?
    let categoryId: String?
    let amount: Double
    let type: String // "income", "expense", "transfer"
    let date: Date
    let note: String?
    let merchant: String?
    let destinationAccountId: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct SavingsGoal: Codable, Identifiable {
    let id: String
    let userId: String?
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

struct RecurringTransaction: Codable, Identifiable {
    let id: String
    let userId: String?
    let amount: Double
    let type: String
    let frequency: String
    let nextDate: Date
    let merchant: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct BudgetSummaryResponse: Codable {
    let totalBudget: Double
    let totalSpent: Double
    let remainingBudget: Double
    let overallUsagePercentage: Double
    let budgets: [Budget]
}

struct Budget: Codable, Identifiable {
    let id: String
    let categoryId: String
    let categoryName: String?
    let amount: Double
    let spent: Double
    let remaining: Double
    let usagePercentage: Double
    let month: String
    let rolloverEnabled: Bool
}

struct Insight: Identifiable, Codable {
    var id: String { type + message }
    let type: String // e.g. "warning", "suggestion", "celebration", "info"
    let message: String
}

struct DailySpending: Codable, Identifiable {
    var id: String { date }
    let date: String
    let totalSpent: Double
}

struct TopSpendingCategory: Codable, Identifiable {
    var id: String { categoryId }
    let categoryId: String
    let categoryName: String
    let totalSpent: Double
}
