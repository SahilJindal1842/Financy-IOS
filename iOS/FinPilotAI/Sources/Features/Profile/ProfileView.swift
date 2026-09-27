import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Green Background
                    ZStack(alignment: .bottom) {
                        // Dark Green Extended Header
                        FinPilotColors.primaryDark
                            .frame(height: 250)
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                            
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(FinPilotTypography.title2)
                                .foregroundColor(.white)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(FinPilotTypography.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 60)
                        
                        // Overlapping Financial Health Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Financial Health")
                                    .font(FinPilotTypography.subheadline)
                                    .foregroundColor(FinPilotColors.textSecondary)
                                Text("Good")
                                    .font(FinPilotTypography.headline)
                                    .foregroundColor(FinPilotColors.success)
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(FinPilotColors.success)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        .offset(y: 40) // Overlap the header
                    }
                    .padding(.bottom, 60) // Space for the overlapping card
                    
                    // Settings List
                    VStack(spacing: 16) {
                        NavigationLink(destination: SavingsGoalsView()) {
                            SettingsRow(icon: "target", title: "Savings Goals", color: .teal)
                        }
                        NavigationLink(destination: RecurringTransactionsView()) {
                            SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Recurring Transactions", color: .indigo)
                        }
                        SettingsRow(icon: "person.fill", title: "Account", color: .blue)
                        NavigationLink(destination: NotificationsView()) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                        }
                        SettingsRow(icon: "arrow.down.doc.fill", title: "Export Data", color: .purple)
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                        SettingsRow(icon: "info.circle.fill", title: "About", color: .gray)
                        
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.title3)
                                    .foregroundColor(FinPilotColors.error)
                                    .frame(width: 40, height: 40)
                                    .background(FinPilotColors.error.opacity(0.15))
                                    .clipShape(Circle())
                                
                                Text("Log Out")
                                    .font(FinPilotTypography.headline)
                                    .foregroundColor(FinPilotColors.error)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(FinPilotTypography.headline)
                .foregroundColor(FinPilotColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(FinPilotColors.textSecondary)
                .font(.caption)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
