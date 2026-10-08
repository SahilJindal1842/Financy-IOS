import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let mobileNumber: String?
    let name: String
    let role: String?
    let monthlyIncome: Double?
    let savingsTarget: Double?
    let currency: String?
    let primaryGoal: String?
    let avatar: String?
    let notificationsEnabled: Bool?
    let biometricsEnabled: Bool?
    let lastSettledMonth: String?
    let settledMonths: [String]?
    let createdAt: Date?
    let updatedAt: Date?
    let subscriptionStatus: String?
    let isSubscribed: Bool?
    let trialEndsAt: Date?
    let trialDaysRemaining: Int?
    let isTrialExpired: Bool?
    
    init(
        id: String,
        email: String? = nil,
        mobileNumber: String? = nil,
        name: String,
        role: String? = nil,
        monthlyIncome: Double? = nil,
        savingsTarget: Double? = nil,
        currency: String? = nil,
        primaryGoal: String? = nil,
        avatar: String? = nil,
        notificationsEnabled: Bool? = true,
        biometricsEnabled: Bool? = false,
        lastSettledMonth: String? = nil,
        settledMonths: [String]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        subscriptionStatus: String? = nil,
        isSubscribed: Bool? = nil,
        trialEndsAt: Date? = nil,
        trialDaysRemaining: Int? = nil,
        isTrialExpired: Bool? = nil
    ) {
        self.id = id
        self.email = email
        self.mobileNumber = mobileNumber
        self.name = name
        self.role = role
        self.monthlyIncome = monthlyIncome
        self.savingsTarget = savingsTarget
        self.currency = currency
        self.primaryGoal = primaryGoal
        self.avatar = avatar
        self.notificationsEnabled = notificationsEnabled
        self.biometricsEnabled = biometricsEnabled
        self.lastSettledMonth = lastSettledMonth
        self.settledMonths = settledMonths
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.subscriptionStatus = subscriptionStatus
        self.isSubscribed = isSubscribed
        self.trialEndsAt = trialEndsAt
        self.trialDaysRemaining = trialDaysRemaining
        self.isTrialExpired = isTrialExpired
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name, role, currency, avatar
        case mobileNumber = "mobile_number"
        case monthlyIncome = "monthly_income"
        case savingsTarget = "savings_target"
        case primaryGoal = "primary_goal"
        case notificationsEnabled = "notifications_enabled"
        case biometricsEnabled = "biometrics_enabled"
        case lastSettledMonth = "last_settled_month"
        case settledMonths = "settled_months"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case subscriptionStatus = "subscription_status"
        case isSubscribed = "is_subscribed"
        case trialEndsAt = "trial_ends_at"
        case trialDaysRemaining = "trial_days_remaining"
        case isTrialExpired = "is_trial_expired"
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
        case nextDueDateCamel = "nextDueDate"
        case userName = "user_name"
    }

    init(id: String, merchant: String, amount: Double, nextDueDate: Date, frequency: String, type: String, userName: String? = nil) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.nextDueDate = nextDueDate
        self.frequency = frequency
        self.type = type
        self.userName = userName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.merchant = try container.decodeIfPresent(String.self, forKey: .merchant) ?? "Bill"
        
        if let amtDouble = try? container.decode(Double.self, forKey: .amount) {
            self.amount = amtDouble
        } else if let amtStr = try? container.decode(String.self, forKey: .amount), let amtParsed = Double(amtStr) {
            self.amount = amtParsed
        } else {
            self.amount = 0.0
        }
        
        if let d = try? container.decode(Date.self, forKey: .nextDueDate) {
            self.nextDueDate = d
        } else if let d = try? container.decode(Date.self, forKey: .nextDueDateCamel) {
            self.nextDueDate = d
        } else {
            self.nextDueDate = Date()
        }
        
        self.frequency = try container.decodeIfPresent(String.self, forKey: .frequency) ?? "monthly"
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "expense"
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(merchant, forKey: .merchant)
        try container.encode(amount, forKey: .amount)
        try container.encode(nextDueDate, forKey: .nextDueDate)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(userName, forKey: .userName)
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
    let availableMoney: Double?
    let savings: Double
    let budget: Double?
    let totalBudget: Double?
    let remainingBudget: Double?
    let budgetUsedPercentage: Double?
    let incomeGrowth: Double?
    let expenseGrowth: Double?
    let savingsGrowth: Double?
    let isSettled: Bool?
    let isEndOfMonth: Bool?
    let endOfMonthDate: String?
    let settlementMonth: String?
    let leftoverSavings: Double?
    let totalAccumulatedSavings: Double?
    let transactions: [Transaction]?
    let upcomingBills: [UpcomingBill]?
    let isAdmin: Bool?
    let isConsolidated: Bool?
    let totalUsers: Int?
}

struct MonthlySavingsRecord: Codable, Identifiable {
    let id: String
    let userId: String?
    let userName: String?
    let userEmail: String?
    let month: String
    let savedAmount: Double
    let totalBudget: Double
    let totalExpenses: Double
    let totalIncome: Double
    let settledAt: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, month, settledAt, notes
        case userId, userName, userEmail
        case snakeUserId = "user_id"
        case snakeUserName = "user_name"
        case snakeUserEmail = "user_email"
        case savedAmount, totalBudget, totalExpenses, totalIncome
        case snakeSavedAmount = "saved_amount"
        case snakeTotalBudget = "total_budget"
        case snakeTotalExpenses = "total_expenses"
        case snakeTotalIncome = "total_income"
        case snakeSettledAt = "settled_at"
    }
    
    init(
        id: String,
        userId: String? = nil,
        userName: String? = nil,
        userEmail: String? = nil,
        month: String,
        savedAmount: Double,
        totalBudget: Double,
        totalExpenses: Double,
        totalIncome: Double,
        settledAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.month = month
        self.savedAmount = savedAmount
        self.totalBudget = totalBudget
        self.totalExpenses = totalExpenses
        self.totalIncome = totalIncome
        self.settledAt = settledAt
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserId))
        userName = (try? container.decodeIfPresent(String.self, forKey: .userName)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserName))
        userEmail = (try? container.decodeIfPresent(String.self, forKey: .userEmail)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserEmail))
        month = (try? container.decode(String.self, forKey: .month)) ?? ""
        settledAt = (try? container.decodeIfPresent(String.self, forKey: .settledAt)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeSettledAt))
        notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        
        func decodeDouble(_ key: CodingKeys, _ alt: CodingKeys) -> Double {
            if let d = try? container.decode(Double.self, forKey: key) { return d }
            if let d = try? container.decode(Double.self, forKey: alt) { return d }
            if let s = try? container.decode(String.self, forKey: key), let d = Double(s) { return d }
            if let s = try? container.decode(String.self, forKey: alt), let d = Double(s) { return d }
            return 0.0
        }
        
        savedAmount = decodeDouble(.savedAmount, .snakeSavedAmount)
        totalBudget = decodeDouble(.totalBudget, .snakeTotalBudget)
        totalExpenses = decodeDouble(.totalExpenses, .snakeTotalExpenses)
        totalIncome = decodeDouble(.totalIncome, .snakeTotalIncome)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userEmail, forKey: .userEmail)
        try container.encode(month, forKey: .month)
        try container.encode(savedAmount, forKey: .savedAmount)
        try container.encode(totalBudget, forKey: .totalBudget)
        try container.encode(totalExpenses, forKey: .totalExpenses)
        try container.encode(totalIncome, forKey: .totalIncome)
        try container.encodeIfPresent(settledAt, forKey: .settledAt)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

struct SavingsHistoryResponse: Codable {
    let totalAccumulatedSavings: Double
    let history: [MonthlySavingsRecord]
    
    enum CodingKeys: String, CodingKey {
        case totalAccumulatedSavings, history
        case snakeTotal = "total_accumulated_savings"
    }
    
    init(totalAccumulatedSavings: Double, history: [MonthlySavingsRecord]) {
        self.totalAccumulatedSavings = totalAccumulatedSavings
        self.history = history
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hist = (try? container.decode([MonthlySavingsRecord].self, forKey: .history)) ?? []
        self.history = hist
        
        if let d = try? container.decode(Double.self, forKey: .totalAccumulatedSavings) {
            totalAccumulatedSavings = d
        } else if let d = try? container.decode(Double.self, forKey: .snakeTotal) {
            totalAccumulatedSavings = d
        } else if let s = try? container.decode(String.self, forKey: .totalAccumulatedSavings), let d = Double(s) {
            totalAccumulatedSavings = d
        } else if let s = try? container.decode(String.self, forKey: .snakeTotal), let d = Double(s) {
            totalAccumulatedSavings = d
        } else {
            totalAccumulatedSavings = hist.reduce(0.0) { $0 + $1.savedAmount }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalAccumulatedSavings, forKey: .totalAccumulatedSavings)
        try container.encode(history, forKey: .history)
    }
}

struct SettlementStatusResponse: Codable {
    let month: String
    let endOfMonthDate: String
    let isEndOfMonth: Bool
    let isSettled: Bool
    let totalBudget: Double
    let totalExpenses: Double
    let totalIncome: Double
    let leftoverSavings: Double
    let totalAccumulatedSavings: Double
}

struct SettlementResultResponse: Codable {
    let success: Bool
    let message: String
    let savedAmount: Double
    let totalBudget: Double
    let totalExpenses: Double
    let totalIncome: Double
    let month: String
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
    let isSystem: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    let subcategories: [Category]?
}

struct Transaction: Codable, Identifiable {
    let id: String
    let userId: String?
    let userName: String?
    let userEmail: String?
    let accountId: String?
    let categoryId: String?
    let amount: Double
    let type: String // "income", "expense", "transfer"
    let date: Date
    let note: String?
    let merchant: String?
    let destinationAccountId: String?
    let isSettled: Bool?
    let settledMonth: String?
    let settledForReports: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, amount, type, date, note, merchant
        case userId, userName, userEmail
        case snakeUserId = "user_id"
        case snakeUserName = "user_name"
        case snakeUserEmail = "user_email"
        case accountId = "accountId"
        case snakeAccountId = "account_id"
        case categoryId = "categoryId"
        case snakeCategoryId = "category_id"
        case destinationAccountId = "destinationAccountId"
        case snakeDestinationAccountId = "destination_account_id"
        case isSettled = "isSettled"
        case snakeIsSettled = "is_settled"
        case settledMonth = "settledMonth"
        case snakeSettledMonth = "settled_month"
        case settledForReports = "settledForReports"
        case snakeSettledForReports = "settled_for_reports"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String,
        userId: String? = nil,
        userName: String? = nil,
        userEmail: String? = nil,
        accountId: String? = nil,
        categoryId: String? = nil,
        amount: Double,
        type: String,
        date: Date,
        note: String? = nil,
        merchant: String? = nil,
        destinationAccountId: String? = nil,
        isSettled: Bool? = nil,
        settledMonth: String? = nil,
        settledForReports: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.merchant = merchant
        self.destinationAccountId = destinationAccountId
        self.isSettled = isSettled
        self.settledMonth = settledMonth
        self.settledForReports = settledForReports
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserId))
        self.userName = (try? container.decodeIfPresent(String.self, forKey: .userName)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserName))
        self.userEmail = (try? container.decodeIfPresent(String.self, forKey: .userEmail)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserEmail))
        self.accountId = (try? container.decodeIfPresent(String.self, forKey: .accountId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeAccountId))
        self.categoryId = (try? container.decodeIfPresent(String.self, forKey: .categoryId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeCategoryId))
        
        if let amt = try? container.decode(Double.self, forKey: .amount) {
            self.amount = amt
        } else if let amtStr = try? container.decode(String.self, forKey: .amount), let amtVal = Double(amtStr) {
            self.amount = amtVal
        } else {
            self.amount = 0.0
        }
        
        self.type = (try? container.decode(String.self, forKey: .type)) ?? "expense"
        self.date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        self.note = try? container.decodeIfPresent(String.self, forKey: .note)
        self.merchant = try? container.decodeIfPresent(String.self, forKey: .merchant)
        self.destinationAccountId = (try? container.decodeIfPresent(String.self, forKey: .destinationAccountId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeDestinationAccountId))
        self.isSettled = (try? container.decodeIfPresent(Bool.self, forKey: .isSettled)) ?? (try? container.decodeIfPresent(Bool.self, forKey: .snakeIsSettled))
        self.settledMonth = (try? container.decodeIfPresent(String.self, forKey: .settledMonth)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeSettledMonth))
        self.settledForReports = (try? container.decodeIfPresent(Bool.self, forKey: .settledForReports)) ?? (try? container.decodeIfPresent(Bool.self, forKey: .snakeSettledForReports))
        self.createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userEmail, forKey: .userEmail)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        try container.encode(type, forKey: .type)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(merchant, forKey: .merchant)
        try container.encodeIfPresent(destinationAccountId, forKey: .destinationAccountId)
        try container.encodeIfPresent(isSettled, forKey: .isSettled)
        try container.encodeIfPresent(settledMonth, forKey: .settledMonth)
        try container.encodeIfPresent(settledForReports, forKey: .settledForReports)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Monthly Expense Reports Models
struct SettledMonthSummary: Codable, Identifiable {
    var id: String {
        if let uid = userId, !uid.isEmpty {
            return "\(uid)_\(month)"
        }
        return month
    }
    let userId: String?
    let userName: String?
    let userEmail: String?
    let month: String
    let totalExpenses: Double
    let totalIncome: Double
    let totalBudget: Double
    let savedAmount: Double
    let settledAt: String?
    let transactionCount: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case userId, userName, userEmail, month, totalExpenses, totalIncome, totalBudget, savedAmount, settledAt, transactionCount, notes
        case snakeUserId = "user_id"
        case snakeUserName = "user_name"
        case snakeUserEmail = "user_email"
        case snakeTotalExpenses = "total_expenses"
        case snakeTotalIncome = "total_income"
        case snakeTotalBudget = "total_budget"
        case snakeSavedAmount = "saved_amount"
        case snakeSettledAt = "settled_at"
        case snakeTransactionCount = "transaction_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserId))
        userName = (try? container.decodeIfPresent(String.self, forKey: .userName)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserName))
        userEmail = (try? container.decodeIfPresent(String.self, forKey: .userEmail)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserEmail))
        month = (try? container.decode(String.self, forKey: .month)) ?? ""
        settledAt = (try? container.decodeIfPresent(String.self, forKey: .settledAt)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeSettledAt))
        notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        transactionCount = (try? container.decodeIfPresent(Int.self, forKey: .transactionCount)) ?? (try? container.decodeIfPresent(Int.self, forKey: .snakeTransactionCount)) ?? 0
        
        func decodeDouble(_ key: CodingKeys, _ alt: CodingKeys) -> Double {
            if let d = try? container.decode(Double.self, forKey: key) { return d }
            if let d = try? container.decode(Double.self, forKey: alt) { return d }
            if let s = try? container.decode(String.self, forKey: key), let d = Double(s) { return d }
            if let s = try? container.decode(String.self, forKey: alt), let d = Double(s) { return d }
            return 0.0
        }
        
        totalExpenses = decodeDouble(.totalExpenses, .snakeTotalExpenses)
        totalIncome = decodeDouble(.totalIncome, .snakeTotalIncome)
        totalBudget = decodeDouble(.totalBudget, .snakeTotalBudget)
        savedAmount = decodeDouble(.savedAmount, .snakeSavedAmount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userEmail, forKey: .userEmail)
        try container.encode(month, forKey: .month)
        try container.encode(totalExpenses, forKey: .totalExpenses)
        try container.encode(totalIncome, forKey: .totalIncome)
        try container.encode(totalBudget, forKey: .totalBudget)
        try container.encode(savedAmount, forKey: .savedAmount)
        try container.encodeIfPresent(settledAt, forKey: .settledAt)
        try container.encode(transactionCount, forKey: .transactionCount)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

struct MonthlyExpenseReportsListResponse: Codable {
    let settledMonths: [SettledMonthSummary]
    let totalHistoricalSavings: Double
    let totalHistoricalExpenses: Double
}

struct ReportCategoryBreakdown: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let amount: Double
    let percentage: Double
}

struct ReportTransactionItem: Codable, Identifiable {
    let id: String
    let amount: Double
    let type: String
    let date: Date
    let note: String?
    let merchant: String?
    let categoryName: String?
    let categoryIcon: String?
    let categoryColor: String?
    let settledForReports: Bool?
    let settledMonth: String?
}

struct MonthlyExpenseReportDetail: Codable {
    let month: String
    let userId: String?
    let userName: String?
    let userEmail: String?
    let isSettled: Bool
    let settlementRecord: MonthlySavingsRecord?
    let totalExpenses: Double
    let totalIncome: Double
    let totalBudget: Double
    let savedAmount: Double
    let settledAt: String?
    let categoryBreakdown: [ReportCategoryBreakdown]
    let transactions: [ReportTransactionItem]
    
    enum CodingKeys: String, CodingKey {
        case month, userId, userName, userEmail, isSettled, settlementRecord, totalExpenses, totalIncome, totalBudget, savedAmount, settledAt, categoryBreakdown, transactions
        case snakeUserId = "user_id"
        case snakeUserName = "user_name"
        case snakeUserEmail = "user_email"
        case snakeIsSettled = "is_settled"
        case snakeSettlementRecord = "settlement_record"
        case snakeTotalExpenses = "total_expenses"
        case snakeTotalIncome = "total_income"
        case snakeTotalBudget = "total_budget"
        case snakeSavedAmount = "saved_amount"
        case snakeSettledAt = "settled_at"
        case snakeCategoryBreakdown = "category_breakdown"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        month = (try? container.decode(String.self, forKey: .month)) ?? ""
        userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserId))
        userName = (try? container.decodeIfPresent(String.self, forKey: .userName)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserName))
        userEmail = (try? container.decodeIfPresent(String.self, forKey: .userEmail)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserEmail))
        isSettled = (try? container.decode(Bool.self, forKey: .isSettled)) ?? (try? container.decode(Bool.self, forKey: .snakeIsSettled)) ?? false
        settlementRecord = (try? container.decodeIfPresent(MonthlySavingsRecord.self, forKey: .settlementRecord)) ?? (try? container.decodeIfPresent(MonthlySavingsRecord.self, forKey: .snakeSettlementRecord))
        
        func decodeDouble(_ k1: CodingKeys, _ k2: CodingKeys) -> Double {
            if let d = try? container.decode(Double.self, forKey: k1) { return d }
            if let d = try? container.decode(Double.self, forKey: k2) { return d }
            if let s = try? container.decode(String.self, forKey: k1), let d = Double(s) { return d }
            if let s = try? container.decode(String.self, forKey: k2), let d = Double(s) { return d }
            return 0.0
        }
        totalExpenses = decodeDouble(.totalExpenses, .snakeTotalExpenses)
        totalIncome = decodeDouble(.totalIncome, .snakeTotalIncome)
        totalBudget = decodeDouble(.totalBudget, .snakeTotalBudget)
        savedAmount = decodeDouble(.savedAmount, .snakeSavedAmount)
        settledAt = (try? container.decodeIfPresent(String.self, forKey: .settledAt)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeSettledAt))
        categoryBreakdown = (try? container.decode([ReportCategoryBreakdown].self, forKey: .categoryBreakdown)) ?? (try? container.decode([ReportCategoryBreakdown].self, forKey: .snakeCategoryBreakdown)) ?? []
        transactions = (try? container.decode([ReportTransactionItem].self, forKey: .transactions)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(month, forKey: .month)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userEmail, forKey: .userEmail)
        try container.encode(isSettled, forKey: .isSettled)
        try container.encodeIfPresent(settlementRecord, forKey: .settlementRecord)
        try container.encode(totalExpenses, forKey: .totalExpenses)
        try container.encode(totalIncome, forKey: .totalIncome)
        try container.encode(totalBudget, forKey: .totalBudget)
        try container.encode(savedAmount, forKey: .savedAmount)
        try container.encodeIfPresent(settledAt, forKey: .settledAt)
        try container.encode(categoryBreakdown, forKey: .categoryBreakdown)
        try container.encode(transactions, forKey: .transactions)
    }
}

struct SavingsGoal: Codable, Identifiable {
    let id: String
    let userId: String?
    let userName: String?
    let userEmail: String?
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt
        case userId, userName, userEmail, targetAmount, currentAmount, deadline
        case snakeUserId = "user_id"
        case snakeUserName = "user_name"
        case snakeUserEmail = "user_email"
        case snakeTargetAmount = "target_amount"
        case snakeCurrentAmount = "current_amount"
        case snakeDeadline = "target_date"
        case snakeCreatedAt = "created_at"
        case snakeUpdatedAt = "updated_at"
    }
    
    init(
        id: String,
        userId: String? = nil,
        userName: String? = nil,
        userEmail: String? = nil,
        name: String,
        targetAmount: Double,
        currentAmount: Double,
        deadline: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Goal"
        userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserId))
        userName = (try? container.decodeIfPresent(String.self, forKey: .userName)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserName))
        userEmail = (try? container.decodeIfPresent(String.self, forKey: .userEmail)) ?? (try? container.decodeIfPresent(String.self, forKey: .snakeUserEmail))
        
        func decodeDouble(_ key: CodingKeys, _ alt: CodingKeys) -> Double {
            if let d = try? container.decode(Double.self, forKey: key) { return d }
            if let d = try? container.decode(Double.self, forKey: alt) { return d }
            if let s = try? container.decode(String.self, forKey: key), let d = Double(s) { return d }
            if let s = try? container.decode(String.self, forKey: alt), let d = Double(s) { return d }
            return 0.0
        }
        
        targetAmount = decodeDouble(.targetAmount, .snakeTargetAmount)
        currentAmount = decodeDouble(.currentAmount, .snakeCurrentAmount)
        
        deadline = (try? container.decodeIfPresent(Date.self, forKey: .deadline)) ?? (try? container.decodeIfPresent(Date.self, forKey: .snakeDeadline))
        createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? (try? container.decodeIfPresent(Date.self, forKey: .snakeCreatedAt))
        updatedAt = (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? (try? container.decodeIfPresent(Date.self, forKey: .snakeUpdatedAt))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userEmail, forKey: .userEmail)
        try container.encode(name, forKey: .name)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(currentAmount, forKey: .currentAmount)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
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
    var userName: String?
    var userEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userEmail = "user_email"
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
    let isSettled: Bool?
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
