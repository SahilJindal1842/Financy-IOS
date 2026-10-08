import Foundation
import StoreKit

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    
    // MARK: - Published Properties
    @Published var state: EntitlementState = .trialActive
    @Published var daysRemaining: Int = 7
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastChecked: Date?
    @Published var currentUserId: String?
    
    private init() {
        restoreFromCache(userId: nil)
    }
    
    // MARK: - User-Scoped Cache
    private func cacheKeyPrefix(for userId: String?) -> String {
        if let uid = userId ?? currentUserId, !uid.isEmpty {
            return "financy_\(uid)_"
        }
        return "financy_guest_"
    }
    
    func restoreFromCache(userId: String?) {
        self.currentUserId = userId
        let prefix = cacheKeyPrefix(for: userId)
        
        if let cachedStateStr = UserDefaults.standard.string(forKey: "\(prefix)entitlement_state"),
           let cachedState = EntitlementState(rawValue: cachedStateStr) {
            self.state = cachedState
        } else {
            self.state = .trialActive
        }
        
        self.isPremium = UserDefaults.standard.bool(forKey: "\(prefix)is_premium")
        let cachedDays = UserDefaults.standard.integer(forKey: "\(prefix)days_remaining")
        self.daysRemaining = cachedDays > 0 ? cachedDays : 7
        
        if isPremium {
            self.state = .premiumActive
        }
    }
    
    private func saveToCache(userId: String, state: EntitlementState, isPremium: Bool, daysRemaining: Int) {
        let prefix = cacheKeyPrefix(for: userId)
        UserDefaults.standard.set(state.rawValue, forKey: "\(prefix)entitlement_state")
        UserDefaults.standard.set(isPremium, forKey: "\(prefix)is_premium")
        UserDefaults.standard.set(daysRemaining, forKey: "\(prefix)days_remaining")
    }
    
    // MARK: - Entitlement Check
    func checkEntitlement(userId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        if let uid = userId, uid != currentUserId {
            restoreFromCache(userId: uid)
        }
        
        // Development command line overrides
        if CommandLine.arguments.contains("--trial-expired") {
            self.state = .trialExpired
            self.daysRemaining = 0
            self.isPremium = false
            self.isLoading = false
            return
        }
        
        if CommandLine.arguments.contains("--premium-active") {
            self.state = .premiumActive
            self.isPremium = true
            self.daysRemaining = 0
            self.isLoading = false
            return
        }
        
        do {
            let res: EntitlementResponse = try await APIManager.shared.request(endpoint: "/entitlements")
            
            self.currentUserId = res.userId
            self.state = res.entitlement
            self.isPremium = res.isPremium
            self.daysRemaining = res.trial?.daysRemaining ?? (res.entitlement == .trialActive ? 7 : 0)
            self.lastChecked = Date()
            
            saveToCache(userId: res.userId, state: self.state, isPremium: self.isPremium, daysRemaining: self.daysRemaining)
            self.isLoading = false
        } catch {
            print("⚠️ Error checking server entitlement: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            
            // Offline Safety: Check user-scoped cache so previous premium is not downgraded
            let prefix = cacheKeyPrefix(for: userId)
            if UserDefaults.standard.bool(forKey: "\(prefix)is_premium") {
                print("🔒 Offline resilience: Preserving user's previously verified PREMIUM_ACTIVE status.")
                self.state = .premiumActive
                self.isPremium = true
            }
        }
    }
    
    func applyVerifiedEntitlement(_ res: EntitlementResponse?) {
        guard let res = res else { return }
        self.currentUserId = res.userId
        self.state = res.entitlement
        self.isPremium = res.isPremium
        self.daysRemaining = res.trial?.daysRemaining ?? 0
        self.lastChecked = Date()
        saveToCache(userId: res.userId, state: self.state, isPremium: self.isPremium, daysRemaining: self.daysRemaining)
    }
    
    func applyAppleVerifiedFallback(transaction: StoreKit.Transaction) {
        print("🛡️ Applying local Apple-verified fallback for lifetime purchase.")
        self.state = .premiumActive
        self.isPremium = true
        self.daysRemaining = 0
        if let uid = currentUserId {
            saveToCache(userId: uid, state: .premiumActive, isPremium: true, daysRemaining: 0)
        }
    }
    
    // MARK: - Development Testing Helpers
    func devExpireTrial() async -> Bool {
        do {
            let res: PurchaseVerificationResponse = try await APIManager.shared.request(
                endpoint: "/entitlements/dev/expire-trial",
                method: "POST"
            )
            if let ent = res.entitlement {
                applyVerifiedEntitlement(ent)
                return true
            }
            return false
        } catch {
            print("❌ devExpireTrial error: \(error)")
            self.state = .trialExpired
            self.daysRemaining = 0
            self.isPremium = false
            if let uid = currentUserId {
                saveToCache(userId: uid, state: .trialExpired, isPremium: false, daysRemaining: 0)
            }
            return true
        }
    }
    
    func devResetTrial() async -> Bool {
        do {
            let res: PurchaseVerificationResponse = try await APIManager.shared.request(
                endpoint: "/entitlements/dev/reset-trial",
                method: "POST"
            )
            if let ent = res.entitlement {
                applyVerifiedEntitlement(ent)
                return true
            }
            return false
        } catch {
            print("❌ devResetTrial error: \(error)")
            self.state = .trialActive
            self.daysRemaining = 7
            self.isPremium = false
            if let uid = currentUserId {
                saveToCache(userId: uid, state: .trialActive, isPremium: false, daysRemaining: 7)
            }
            return true
        }
    }
    
    func clearCacheOnLogout() {
        self.currentUserId = nil
        self.state = .trialActive
        self.daysRemaining = 7
        self.isPremium = false
    }
}
