import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    // Configurable product identifiers
    static let lifetimeProductID = "com.financy.lifetime"
    static let alternativeProductIDs = ["com.finpilotai.lifetime"]
    
    @Published var lifetimeProduct: Product?
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false
    @Published var errorMessage: String?
    
    private var updatesTask: Task<Void, Never>?
    
    private init() {
        // Start listening to background transaction updates (StoreKit 2)
        updatesTask = listenForTransactions()
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        do {
            let productIDs = [Self.lifetimeProductID] + Self.alternativeProductIDs
            let products = try await Product.products(for: productIDs)
            
            // Prefer com.financy.lifetime, fallback to first available
            if let matched = products.first(where: { $0.id == Self.lifetimeProductID }) {
                self.lifetimeProduct = matched
            } else {
                self.lifetimeProduct = products.first
            }
            
            if let prod = self.lifetimeProduct {
                print("🛒 StoreKit 2 loaded product: \(prod.id), price: \(prod.displayPrice)")
            } else {
                print("⚠️ StoreKit 2: No product found matching \(Self.lifetimeProductID)")
            }
        } catch {
            print("❌ StoreKit 2 loadProducts error: \(error.localizedDescription)")
            self.errorMessage = "Failed to load StoreKit products: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Purchase Flow
    func purchaseLifetime() async -> Bool {
        guard let product = lifetimeProduct else {
            // Try reloading once
            await loadProducts()
            if let reloadedProduct = lifetimeProduct {
                return await purchase(product: reloadedProduct)
            }
            
            #if DEBUG
            print("🧪 [StoreKit Dev Mode] Simulating StoreKit 2 transaction verification for development...")
            isPurchasing = true
            let simulatedTxId = "dev_sim_\(UUID().uuidString.prefix(8))"
            let payload = PurchaseVerificationPayload(
                productId: Self.lifetimeProductID,
                transactionId: simulatedTxId,
                originalTransactionId: simulatedTxId,
                purchaseDate: ISO8601DateFormatter().string(from: Date()),
                environment: "Xcode",
                jwsRepresentation: "dev_mock_jws_\(simulatedTxId)"
            )
            do {
                let data = try JSONEncoder().encode(payload)
                let response: PurchaseVerificationResponse = try await APIManager.shared.request(
                    endpoint: "/purchases/verify",
                    method: "POST",
                    body: data
                )
                if response.success {
                    print("✅ [StoreKit Dev Mode] Backend verified purchase: \(response.message)")
                    EntitlementManager.shared.applyVerifiedEntitlement(response.entitlement)
                    isPurchasing = false
                    return true
                } else {
                    self.errorMessage = response.message
                    isPurchasing = false
                    return false
                }
            } catch {
                print("❌ [StoreKit Dev Mode] Error verifying with backend: \(error)")
                self.errorMessage = error.localizedDescription
                isPurchasing = false
                return false
            }
            #else
            self.errorMessage = "Product unavailable in App Store. Please try again later."
            return false
            #endif
        }
        return await purchase(product: product)
    }
    
    func purchase(product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                let jws = verification.jwsRepresentation
                
                // Verify with backend before unlocking
                let verifiedOnServer = await verifyPurchaseOnBackend(transaction: transaction, jws: jws)
                
                if verifiedOnServer {
                    // Always finish the transaction after successful backend registration
                    await transaction.finish()
                    isPurchasing = false
                    return true
                } else {
                    isPurchasing = false
                    self.errorMessage = "Purchase could not be verified on the server. Please try restoring."
                    return false
                }
                
            case .userCancelled:
                isPurchasing = false
                print("ℹ️ User cancelled purchase.")
                return false
                
            case .pending:
                isPurchasing = false
                self.errorMessage = "Purchase is pending approval (Ask to Buy or Parental Control)."
                return false
                
            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            isPurchasing = false
            self.errorMessage = error.localizedDescription
            print("❌ Purchase failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        isRestoring = true
        errorMessage = nil
        
        do {
            // Force App Store sync
            try await AppStore.sync()
            
            var restoredAny = false
            
            for await result in StoreKit.Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == Self.lifetimeProductID ||
                        Self.alternativeProductIDs.contains(transaction.productID) {
                        
                        let serverSuccess = await verifyPurchaseOnBackend(transaction: transaction, jws: result.jwsRepresentation)
                        if serverSuccess {
                            await transaction.finish()
                            restoredAny = true
                        }
                    }
                }
            }
            
            isRestoring = false
            
            if restoredAny {
                // Refresh local entitlement manager
                await EntitlementManager.shared.checkEntitlement()
                return true
            } else {
                // Re-check entitlement from backend just in case
                await EntitlementManager.shared.checkEntitlement()
                if EntitlementManager.shared.isPremium {
                    return true
                }
                self.errorMessage = "No prior Lifetime purchases were found for your Apple ID."
                return false
            }
        } catch {
            isRestoring = false
            self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Server-Side Verification
    private func verifyPurchaseOnBackend(transaction: StoreKit.Transaction, jws: String? = nil) async -> Bool {
        let payload = PurchaseVerificationPayload(
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            purchaseDate: ISO8601DateFormatter().string(from: transaction.purchaseDate),
            environment: transaction.environment.rawValue,
            jwsRepresentation: jws
        )
        
        do {
            let data = try JSONEncoder().encode(payload)
            let response: PurchaseVerificationResponse = try await APIManager.shared.request(
                endpoint: "/purchases/verify",
                method: "POST",
                body: data
            )
            
            if response.success {
                print("✅ Server verified purchase for product: \(transaction.productID)")
                EntitlementManager.shared.applyVerifiedEntitlement(response.entitlement)
                return true
            } else {
                print("⚠️ Server rejected purchase verification: \(response.message)")
                return false
            }
        } catch {
            print("❌ Error verifying purchase on server: \(error)")
            // Offline resilience: if transaction is verified by Apple, mark user locally as premium
            // so network hiccups don't lock the user out, and retry sync when online.
            EntitlementManager.shared.applyAppleVerifiedFallback(transaction: transaction)
            return true
        }
    }
    
    // MARK: - Verification Helper
    nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Background Transaction Updates Listener
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    let jws = result.jwsRepresentation
                    
                    // Verify on server
                    let success = await self.verifyPurchaseOnBackend(transaction: transaction, jws: jws)
                    if success {
                        await transaction.finish()
                    }
                } catch {
                    print("⚠️ Transaction update unverified: \(error.localizedDescription)")
                }
            }
        }
    }
}
