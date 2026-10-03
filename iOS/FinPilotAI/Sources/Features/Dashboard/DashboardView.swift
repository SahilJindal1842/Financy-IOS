import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddExpense = false
    @State private var currentMonth: String = "September 2026"
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerView
                        totalBalanceCard
                        statsGrid
                        upcomingBillsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .padding(.bottom, 100) // For tab bar and FAB
                }
                .refreshable {
                    await viewModel.loadDashboardData()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(FinPilotColors.primary)
                                .clipShape(Circle())
                                .shadow(color: FinPilotColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing Dashboard...")
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                currentMonth = formatter.string(from: Date())
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                Task {
                    await viewModel.loadDashboardData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
                viewModel.reset()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddTransactionView()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good Morning,")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    HStack {
                        Text("\(viewModel.userName) 👋")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
                Spacer()
                
                HStack(spacing: 16) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                    
                    NavigationLink(destination: EditProfileView()) {
                        Group {
                            if let avatar = viewModel.avatar, !avatar.isEmpty, avatar.starts(with: "/") {
                                let fullUrlStr = NetworkConfig.baseURLString.replacingOccurrences(of: "/api", with: "") + avatar
                                AsyncImage(url: URL(string: fullUrlStr)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            HStack {
                Button(action: { /* Pick month */ }) {
                    HStack(spacing: 4) {
                        Text(currentMonth)
                            .font(FinPilotTypography.subheadline)
                            .foregroundColor(FinPilotColors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var totalBalanceCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [FinPilotColors.primaryLight, FinPilotColors.primaryDark]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Balance")
                        .font(FinPilotTypography.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(viewModel.currency) \(Int(viewModel.remainingBudget))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("of \(viewModel.currency) \(Int(viewModel.budget)) budget")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.budgetUsedPercentage) / 100)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.budgetUsedPercentage))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("budget used")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 140)
    }
    
    private var statsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "arrow.down.left",
                    iconColor: .green,
                    iconBg: Color.green.opacity(0.15),
                    title: "Income",
                    amount: "\(viewModel.currency) \(Int(viewModel.totalIncome))",
                    growth: "↑ \(Int(viewModel.incomeGrowth))%",
                    growthColor: .green
                )
                
                StatCard(
                    icon: "arrow.up.right",
                    iconColor: .red,
                    iconBg: Color.red.opacity(0.15),
                    title: "Expenses",
                    amount: "\(viewModel.currency) \(Int(viewModel.totalExpenses))",
                    growth: "↑ \(Int(viewModel.expenseGrowth))%",
                    growthColor: .red
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "target",
                    iconColor: .blue,
                    iconBg: Color.blue.opacity(0.15),
                    title: "Savings",
                    amount: "\(viewModel.currency) \(Int(viewModel.savings))",
                    growth: "↑ \(Int(viewModel.savingsGrowth))%",
                    growthColor: .blue
                )
                
                StatCard(
                    icon: "chart.pie.fill",
                    iconColor: .purple,
                    iconBg: Color.purple.opacity(0.15),
                    title: "Remaining Budget",
                    amount: "\(viewModel.currency) \(Int(viewModel.remainingBudget))",
                    growth: nil,
                    growthColor: .clear
                )
            }
        }
    }
    
    private var upcomingBillsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Upcoming Recurring Payments")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = 2 // Navigate to Recurring tab
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(FinPilotColors.primary)
            }
            
            if viewModel.upcomingBills.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingBills) { bill in
                        UpcomingBillRow(bill: bill, currency: viewModel.currency)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    let amount: String
    let growth: String?
    let growthColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconBg)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                Spacer()
            }
            
            Text(amount)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
            
            if let g = growth {
                Text(g)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(growthColor)
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct UpcomingBillRow: View {
    let bill: UpcomingBill
    let currency: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconFor(bill.merchant))
                .font(.system(size: 20))
                .foregroundColor(colorFor(bill.merchant))
                .frame(width: 48, height: 48)
                .background(colorFor(bill.merchant).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.merchant)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("\(currency) \(Int(bill.amount)) • \(formatDate(bill.nextDueDate))")
                    .font(.system(size: 13))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func iconFor(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("rent") || n.contains("home") { return "house.fill" }
        if n.contains("netflix") || n.contains("tv") { return "play.tv.fill" }
        if n.contains("internet") || n.contains("wifi") { return "wifi" }
        return "doc.text.fill"
    }
    
    private func colorFor(_ name: String) -> Color {
        let n = name.lowercased()
        if n.contains("rent") || n.contains("home") { return .red }
        if n.contains("netflix") || n.contains("tv") { return .red }
        if n.contains("internet") || n.contains("wifi") { return .blue }
        return .purple
    }
}
