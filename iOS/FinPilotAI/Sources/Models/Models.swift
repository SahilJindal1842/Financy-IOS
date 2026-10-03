import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let name: String
    let role: String?
    let monthlyIncome: Double?
    let currency: String?
    let primaryGoal: String?
    let avatar: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: String,
        email: String? = nil,
        name: String,
        role: String? = nil,
        monthlyIncome: Double? = nil,
        currency: String? = nil,
        primaryGoal: String? = nil,
        avatar: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.monthlyIncome = monthlyIncome
        self.currency = currency
        self.primaryGoal = primaryGoal
        self.avatar = avatar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name, role, currency, avatar
        case monthlyIncome = "monthly_income"
        case primaryGoal = "primary_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AdminUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let mobileNumber: String?
    let role: String?
    let status: String?
    let avatar: String?
    let monthlyIncome: Double?
    let currency: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, role, status, avatar, currency
        case mobileNumber = "mobile_number"
        case monthlyIncome = "monthly_income"
        case createdAt = "created_at"
    }
}

struct UpcomingBill: Codable, Identifiable {
    let id: String
    let merchant: String
    let amount: Double
    let nextDueDate: Date
    let frequency: String
    let type: String
    let userName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, merchant, amount, frequency, type
        case nextDueDate = "next_due_date"
        case userName = "user_name"
    }
}

struct DashboardStats: Codable {
    let userName: String
    let avatar: String?
    let currency: String
    let monthlyIncome: Double
    let totalIncome: Double
    let totalExpenses: Double
    let balance: Double
    let savings: Double
    let budget: Double?
    let totalBudget: Double?
    let remainingBudget: Double?
    let budgetUsedPercentage: Double?
    let incomeGrowth: Double?
    let expenseGrowth: Double?
    let savingsGrowth: Double?
    let transactions: [Transaction]?
    let upcomingBills: [UpcomingBill]?
    let isAdmin: Bool?
    let isConsolidated: Bool?
    let totalUsers: Int?
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
    let userId: String
    let type: String
    let amount: Double
    let categoryId: String?
    let accountId: String
    let frequency: String
    let nextDueDate: Date
    let createdAt: Date
    
    // New enriched fields
    var merchant: String?
    var startDate: Date?
    var endDate: Date?
    var notes: String?
    var reminderDays: Int?
    var autoCreate: Bool?
    var status: String?
    var variableAmount: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case amount
        case categoryId = "category_id"
        case accountId = "account_id"
        case frequency
        case nextDueDate = "next_due_date"
        case createdAt = "created_at"
        
        case merchant
        case startDate = "start_date"
        case endDate = "end_date"
        case notes
        case reminderDays = "reminder_days"
        case autoCreate = "auto_create"
        case status
        case variableAmount = "variable_amount"
    }
    
    var nextDate: Date { nextDueDate }
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
