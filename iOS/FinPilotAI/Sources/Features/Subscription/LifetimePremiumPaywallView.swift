import SwiftUI
import StoreKit

struct LifetimePremiumPaywallView: View {
    var isMandatory: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        ZStack {
            // Background
            FinPilotColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar (Fixed at top, perfectly in safe area)
                HStack {
                    if !isMandatory {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                        }
                    } else {
                        // Lock icon showing trial expiration
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("TRIAL EXPIRED")
                                .font(.system(size: 11, weight: .black))
                                .tracking(1.0)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Log out button always available
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                    
                    // Crown & Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFD700").opacity(0.28), Color(hex: "#FFA500").opacity(0.18)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 82, height: 82)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "#FF9900"))
                        }
                        
                        Text("Financy Premium")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        
                        Text("Your 7-day free trial has ended")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("Unlock Financy for lifetime access")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    // Lifetime Pricing Card (Fetched from StoreKit 2)
                    VStack(spacing: 14) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("LIFETIME PASS")
                                        .font(.system(size: 10, weight: .black))
                                        .tracking(1.2)
                                        .foregroundColor(FinPilotColors.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(FinPilotColors.primary.opacity(0.12))
                                        .cornerRadius(6)
                                    
                                    Text("BEST VALUE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12))
                                        .cornerRadius(4)
                                }
                                
                                Text("Pay Once, Own Forever")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                
                                Text("One-time purchase • Lifetime access")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                if let product = purchaseManager.lifetimeProduct {
                                    Text(product.displayPrice)
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(FinPilotColors.primary)
                                } else {
                                    Text("$9.99")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(FinPilotColors.primary)
                                }
                                
                                Text("ONE-TIME")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [FinPilotColors.primary, FinPilotColors.primaryLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: FinPilotColors.primary.opacity(0.15), radius: 12, x: 0, y: 5)
                    .padding(.horizontal, 24)
                    
                    // Value Proposition Feature List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PREMIUM FEATURES INCLUDED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(1.0)
                            .padding(.horizontal, 28)
                        
                        VStack(spacing: 12) {
                            FeatureBenefitRow(icon: "checkmark.seal.fill", color: .green, title: "Unlimited Transactions & Budgets", desc: "Never hit artificial limits on your financial tracking")
                            FeatureBenefitRow(icon: "sparkles", color: .purple, title: "AI-Powered Financial Insights", desc: "Actionable analysis to cut expenses and build wealth")
                            FeatureBenefitRow(icon: "calendar.badge.clock", color: .blue, title: "Automated Recurring Bills & Alerts", desc: "Stay ahead of every renewal and subscription")
                            FeatureBenefitRow(icon: "chart.bar.xaxis", color: .orange, title: "Month Settlement & Savings Reports", desc: "Track reserve transfers and historic month closures")
                            FeatureBenefitRow(icon: "lock.icloud.fill", color: .indigo, title: "Encrypted Cloud Backup & Multi-device", desc: "Private, enterprise-grade data security forever")
                        }
                        .padding(18)
                        .background(FinPilotColors.surface)
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                    }
                    
                    // Purchase & Restore Action Buttons
                    VStack(spacing: 14) {
                        Button(action: handlePurchase) {
                            HStack(spacing: 8) {
                                if purchaseManager.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "lock.open.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Unlock Lifetime Premium")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [FinPilotColors.primaryLight, FinPilotColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(color: FinPilotColors.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)
                        
                        // Restore Purchases
                        Button(action: handleRestore) {
                            HStack(spacing: 6) {
                                if purchaseManager.isRestoring {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 13))
                                }
                                Text("Restore Purchase")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(FinPilotColors.primary)
                        }
                        .disabled(purchaseManager.isPurchasing || purchaseManager.isRestoring)
                        .padding(.top, 4)
                        
                        // Legal & Support Links
                        HStack(spacing: 16) {
                            Button("Terms of Use") {
                                showTerms = true
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                            
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                            
                            Button("Privacy Policy") {
                                showPrivacy = true
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
        .task {
            // Load StoreKit products when paywall appears
            await purchaseManager.loadProducts()
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("🎉 Lifetime Access Unlocked!"),
                message: Text("Thank you for purchasing Financy Lifetime Premium. All features are permanently available to you."),
                dismissButton: .default(Text("Continue")) {
                    dismiss()
                }
            )
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Purchase Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showTerms) {
            LegalDocumentView(title: "Terms of Use", content: "Financy Lifetime Premium is a one-time, non-consumable in-app purchase providing perpetual access to the Financy financial management software on all compatible iOS devices associated with your Apple ID. No recurring subscription fees will ever be charged. For assistance, contact support@financy.app.")
        }
        .sheet(isPresented: $showPrivacy) {
            LegalDocumentView(title: "Privacy Policy", content: "Financy respects your financial privacy. Your personal financial records, budgets, accounts, and transactions are securely encrypted and never sold to third parties or advertisers. For more information, please visit https://financy.app/privacy.")
        }
    }
    
    // MARK: - Actions
    private func handlePurchase() {
        Task {
            let success = await purchaseManager.purchaseLifetime()
            if success {
                showSuccessAlert = true
            } else if let err = purchaseManager.errorMessage {
                alertMessage = err
                showErrorAlert = true
            }
        }
    }
    
    private func handleRestore() {
        Task {
            let success = await purchaseManager.restorePurchases()
            if success {
                showSuccessAlert = true
            } else if let err = purchaseManager.errorMessage {
                alertMessage = err
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Benefit Row Component
private struct FeatureBenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Legal Document Viewer
private struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textPrimary)
                        .padding(20)
                    Spacer()
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
}
