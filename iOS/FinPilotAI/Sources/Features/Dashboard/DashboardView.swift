import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                if true {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerView
                            monthlyBudgetCard
                            balanceAndSavingsCards
                            quickActions
                            todaysExpenses
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        await viewModel.loadDashboardData()
                    }
                }
            }
            .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing Dashboard...")
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                Task {
                    await viewModel.loadDashboardData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
                viewModel.reset()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userName.isEmpty ? "Good Morning" : "Good Morning, \(viewModel.userName)")
                    .font(FinPilotTypography.title2)
                    .foregroundColor(FinPilotColors.textPrimary)
                Text("Here's your financial overview")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            Spacer()
            NavigationLink(destination: NotificationsView()) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(FinPilotColors.primary)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var monthlyBudgetCard: some View {
        let budgetTotal = viewModel.budget > 0 ? viewModel.budget : viewModel.monthlyIncome
        let spent = viewModel.totalSpent
        let left = max(0, budgetTotal - spent)
        let progress = budgetTotal > 0 ? min(1.0, spent / budgetTotal) : 0.0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Monthly Budget")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
            }
            
            Text("₹ \(budgetTotal.formatted(.number.precision(.fractionLength(0))))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("₹ \(spent.formatted(.number.precision(.fractionLength(0)))) spent")
                    Spacer()
                    Text("₹ \(left.formatted(.number.precision(.fractionLength(0)))) left")
                }
                .font(FinPilotTypography.caption)
                .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(24)
        .background(FinPilotColors.budgetCardGradient)
        .cornerRadius(24)
        .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var balanceAndSavingsCards: some View {
        HStack(spacing: 16) {
            // Balance Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(FinPilotColors.primary)
                        .font(.subheadline)
                    Text("Balance")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                Text("₹ \(viewModel.totalBalance.formatted(.number.precision(.fractionLength(0))))")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FinPilotColors.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

            // Savings Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(FinPilotColors.success)
                        .font(.subheadline)
                    Text("Savings")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                Text("₹ \(viewModel.savings.formatted(.number.precision(.fractionLength(0))))")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FinPilotColors.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: 20) {
            Button(action: { showingAddExpense = true }) {
                QuickActionIcon(icon: "plus", title: "Add Expense", color: .blue)
            }
            Button(action: { selectedTab = 3 }) {
                QuickActionIcon(icon: "chart.pie.fill", title: "View Insights", color: .purple)
            }
            Button(action: { selectedTab = 2 }) {
                QuickActionIcon(icon: "target", title: "Set Budget", color: .orange)
            }
            Button(action: { selectedTab = 4 }) {
                QuickActionIcon(icon: "star.fill", title: "Goals", color: .pink)
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showingAddExpense) {
            AddTransactionView()
        }
    }
    
    private var todaysExpenses: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Expenses")
                    .font(FinPilotTypography.title3)
                    .foregroundColor(FinPilotColors.textPrimary)
                Spacer()
                Text("See All")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.primary)
            }
            
            VStack(spacing: 12) {
                if false {
                    // removed inline loading since we use global overlay
                }
                
                if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                        Text("No expenses yet")
                            .font(FinPilotTypography.headline)
                            .foregroundColor(FinPilotColors.textSecondary)
                        Text("Tap 'Add Expense' above to log your first transaction.")
                            .font(FinPilotTypography.caption)
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(FinPilotColors.surface)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
                } else {
                    ForEach(viewModel.transactions.prefix(5)) { tx in
                        DashboardTransactionRow(
                            icon: iconForCategory(tx.categoryId ?? ""),
                            iconColor: colorForCategory(tx.categoryId ?? ""),
                            title: tx.merchant ?? (tx.categoryId ?? "Expense"),
                            subtitle: "\(tx.categoryId ?? "General") • \(dateFormatter.string(from: tx.date))",
                            amount: "\(tx.amount < 0 ? "-" : "+")₹ \(abs(tx.amount).formatted(.number.precision(.fractionLength(0))))"
                        )
                    }
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
    
    private func iconForCategory(_ cat: String) -> String {
        switch cat {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Bills": return "doc.text.fill"
        case "Health": return "heart.fill"
        default: return "creditcard.fill"
        }
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "Food": return .orange
        case "Transport": return .blue
        case "Shopping": return .pink
        case "Bills": return .purple
        case "Health": return .red
        default: return .gray
        }
    }
}

struct QuickActionIcon: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(FinPilotColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardTransactionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
                Text(subtitle)
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(FinPilotTypography.headline)
                .foregroundColor(FinPilotColors.textPrimary)
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(0))
    }
}
