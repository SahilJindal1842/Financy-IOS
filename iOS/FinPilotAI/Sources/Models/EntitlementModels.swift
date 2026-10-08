import Foundation

enum EntitlementState: String, Codable {
    case trialActive = "TRIAL_ACTIVE"
    case trialExpired = "TRIAL_EXPIRED"
    case premiumActive = "PREMIUM_ACTIVE"
}

struct TrialInfo: Codable {
    let startDate: String?
    let endDate: String?
    let daysRemaining: Int
    let isExpired: Bool
    let status: String
}

struct PurchaseInfo: Codable {
    let productId: String
    let transactionId: String
    let originalTransactionId: String?
    let purchaseDate: String?
    let environment: String?
    let status: String?
}

struct EntitlementResponse: Codable {
    let entitlement: EntitlementState
    let userId: String
    let isPremium: Bool
    let trial: TrialInfo?
    let purchase: PurchaseInfo?
    let serverTime: String?
}

struct PurchaseVerificationPayload: Codable {
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let purchaseDate: String
    let environment: String
    let jwsRepresentation: String?
}

struct PurchaseVerificationResponse: Codable {
    let success: Bool
    let message: String
    let entitlement: EntitlementResponse?
}
