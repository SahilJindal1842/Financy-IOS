import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @State private var showingAddExpense = false
    @State private var showPaywall = false
    @State private var showingSettlementModal = false
    @State private var showingSettlementConfirmation = false
    @State private var currentMonth: String = "September 2026"
    @State private var navigateToIncome: Bool = false
    @State private var navigateToExpense: Bool = false
    @State private var showingDueBillsAlert = false
    @State private var dueBillsAlertTitle = "Recurring Payment Alert"
    @State private var dueBillsAlertMessage = ""
    @State private var hasAlertedDueBillsOnOpen = false
    
    var body: some View {

        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    scrollContent
                }
                .refreshable {
                    await viewModel.loadDashboardData(userRole: authViewModel.currentUser?.role)
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
            .sheet(isPresented: $showPaywall) {
                LifetimePremiumPaywallView(isMandatory: false)
            }
            .task {
                if authViewModel.currentUser == nil {
                    await authViewModel.fetchProfile()
                }
                await entitlementManager.checkEntitlement(userId: authViewModel.currentUser?.id)
                await viewModel.loadDashboardData(userRole: authViewModel.currentUser?.role)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                currentMonth = formatter.string(from: Date())
                
                checkDueRecurringBills()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                Task {
                    await viewModel.loadDashboardData(userRole: authViewModel.currentUser?.role)
                    checkDueRecurringBills()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
                viewModel.reset()
                hasAlertedDueBillsOnOpen = false
            }
            .onChange(of: authViewModel.currentUser?.id) { _ in
                Task {
                    await viewModel.loadDashboardData(userRole: authViewModel.currentUser?.role)
                    checkDueRecurringBills()
                }
            }
            .alert(isPresented: $showingDueBillsAlert) {
                Alert(
                    title: Text(dueBillsAlertTitle),
                    message: Text(dueBillsAlertMessage),
                    primaryButton: .default(Text("View Recurring Bills")) {
                        selectedTab = 2
                    },
                    secondaryButton: .cancel(Text("Got It"))
                )
            }
            .sheet(isPresented: $showingAddExpense) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingSettlementModal) {
                monthSettlementSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowMonthSettlement"))) { _ in
                showingSettlementModal = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowAddTx"))) { _ in
                showingAddExpense = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowIncomeDrillDown"))) { _ in
                navigateToIncome = true
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowExpenseDrillDown"))) { _ in
                navigateToExpense = true
            }
        }
    }

    
    private var scrollContent: some View {
        VStack(spacing: 20) {
            if viewModel.isAdmin || authViewModel.currentUser?.role?.uppercased() == "ADMIN" {
                adminControlSection
            } else if !entitlementManager.isPremium && !authViewModel.isSubscribed {
                trialStatusBanner
            }
            
            headerView
            monthlyOverviewCard
            budgetOverviewCard
            monthSettlementCard
            statsGrid
            upcomingBillsSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .padding(.bottom, 100)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good Morning,")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    HStack {
                        Text(viewModel.userName.isEmpty ? (authViewModel.currentUser?.name ?? "User") : viewModel.userName)
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
                Menu {
                    ForEach(viewModel.availableMonths) { opt in
                        Button(action: {
                            Task {
                                await viewModel.selectMonth(opt.key, displayName: opt.label, userRole: authViewModel.currentUser?.role)
                            }
                        }) {
                            HStack {
                                Text(opt.label)
                                if viewModel.selectedMonth == opt.key {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FinPilotColors.primary)
                        Text(viewModel.displayMonthName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(FinPilotColors.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FinPilotColors.border.opacity(0.6), lineWidth: 1)
                    )
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Currency & Number Formatting Helpers
    private var currencySymbol: String {
        viewModel.currency == "INR" ? "₹" : viewModel.currency
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
    
    // MARK: - Monthly Overview Card
    private var monthlyOverviewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#065F46"),
                            Color(hex: "#059669"),
                            Color(hex: "#10B981")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "#059669").opacity(0.32), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("MONTHLY OVERVIEW")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    if viewModel.isSettled {
                        Text("SETTLED • SAVED")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    } else {
                        Text(viewModel.displayMonthName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // Rows: Income & Spent
                VStack(spacing: 8) {
                    HStack {
                        Text("Income")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("\(currencySymbol)\(formatCurrency(viewModel.totalIncome))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Spent")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("\(currencySymbol)\(formatCurrency(viewModel.totalExpenses))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.25))
                
                // Highlight: Available Money
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.isSettled ? "Saved Amount" : "Available")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Income − Spent")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    Text("\(currencySymbol)\(formatCurrency(viewModel.isSettled ? viewModel.leftoverSavings : viewModel.availableMoney))")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(18)
        }
    }
    
    // MARK: - Budget Card
    private var budgetOverviewCard: some View {
        Button(action: {
            selectedTab = 3 // Navigate to Budgets tab
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.primary)
                        Text("BUDGET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.primary)
                            .tracking(0.8)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(FinPilotColors.primary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Spending Plan")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                    }
                }
                
                // Rows: Total Budget & Budget Used
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Budget")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Spacer()
                        Text("\(currencySymbol)\(formatCurrency(viewModel.budget))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                    
                    HStack {
                        Text("Budget Used")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Spacer()
                        Text("\(currencySymbol)\(formatCurrency(viewModel.totalExpenses))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.budget > 0 && viewModel.totalExpenses > viewModel.budget ? FinPilotColors.error : FinPilotColors.textPrimary)
                    }
                }
                
                Divider()
                    .background(FinPilotColors.border.opacity(0.8))
                
                // Highlight: Budget Remaining
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budget Remaining")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Spending Limit Left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(currencySymbol)\(formatCurrency(viewModel.remainingBudget))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(
                            viewModel.remainingBudget > 0
                                ? FinPilotColors.primary
                                : (viewModel.budget > 0 ? FinPilotColors.error : FinPilotColors.textSecondary)
                        )
                }
                
                // Visual progress bar or setup note
                if viewModel.budget > 0 {
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(FinPilotColors.background)
                                    .frame(height: 7)
                                
                                let pct = CGFloat(min(viewModel.budgetUsedPercentage / 100.0, 1.0))
                                Capsule()
                                    .fill(
                                        viewModel.totalExpenses > viewModel.budget
                                            ? FinPilotColors.error
                                            : (viewModel.budgetUsedPercentage > 80 ? FinPilotColors.warning : FinPilotColors.primary)
                                    )
                                    .frame(width: max(geo.size.width * pct, 0), height: 7)
                            }
                        }
                        .frame(height: 7)
                        
                        HStack {
                            Text("\(Int(viewModel.budgetUsedPercentage))% used")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(viewModel.totalExpenses > viewModel.budget ? FinPilotColors.error : FinPilotColors.textSecondary)
                            Spacer()
                            Text("Spending limit • Not bank balance")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.8))
                        }
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.primary)
                        Text("No budget set for \(viewModel.displayMonthName). Tap to allocate.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            .padding(18)
            .background(FinPilotColors.surface)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(FinPilotColors.border.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statsGrid: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                NavigationLink(
                    destination: IncomeDrillDownView(currentMonth: viewModel.displayMonthName, currency: viewModel.currency),
                    isActive: $navigateToIncome
                ) {
                    StatCard(
                        icon: "arrow.down.left",
                        iconColor: Color(hex: "#059669"),
                        iconBg: Color(hex: "#10B981").opacity(0.15),
                        title: "Income",
                        amount: "\(viewModel.currency) \(Int(viewModel.totalIncome))",
                        growth: "↑ \(Int(viewModel.incomeGrowth))%",
                        growthColor: Color(hex: "#059669"),
                        showChevron: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(
                    destination: ExpenseDrillDownView(currentMonth: viewModel.displayMonthName, currency: viewModel.currency),
                    isActive: $navigateToExpense
                ) {
                    StatCard(
                        icon: "arrow.up.right",
                        iconColor: Color(hex: "#EF4444"),
                        iconBg: Color(hex: "#EF4444").opacity(0.15),
                        title: "Expenses",
                        amount: "\(viewModel.currency) \(Int(viewModel.totalExpenses))",
                        growth: "↑ \(Int(viewModel.expenseGrowth))%",
                        growthColor: Color(hex: "#EF4444"),
                        showChevron: true
                    )
                }
                .buttonStyle(PlainButtonStyle())

            }
            
            HStack(spacing: 14) {
                NavigationLink(destination: SavingsModuleView()) {
                    StatCard(
                        icon: "target",
                        iconColor: Color(hex: "#059669"),
                        iconBg: Color(hex: "#10B981").opacity(0.15),
                        title: "Savings",
                        amount: "\(viewModel.currency) \(Int(viewModel.savings))",
                        growth: "↑ \(Int(viewModel.savingsGrowth))%",
                        growthColor: Color(hex: "#059669"),
                        showChevron: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                let netCash = viewModel.totalIncome - viewModel.totalExpenses
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: netCash >= 0 ? Color(hex: "#059669") : Color(hex: "#EF4444"),
                    iconBg: (netCash >= 0 ? Color(hex: "#10B981") : Color(hex: "#EF4444")).opacity(0.15),
                    title: "Cash Flow",
                    amount: "\(netCash >= 0 ? "+" : "-") \(viewModel.currency) \(Int(abs(netCash)))",
                    growth: netCash >= 0 ? "Surplus" : "Deficit",
                    growthColor: netCash >= 0 ? Color(hex: "#059669") : Color(hex: "#EF4444"),
                    showChevron: true,
                    action: {
                        selectedTab = 3 // Navigate to Budgets tab
                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                    }
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
    
    // MARK: - Month-End Settlement Card & Modal
    private var monthSettlementCard: some View {
        VStack(spacing: 0) {
            if viewModel.isSettled {
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#10B981").opacity(0.18))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#059669"))
                            }
                            
                            Text("\(currentMonth) Settled")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                                .lineLimit(1)
                                .fixedSize()
                            
                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#10B981").opacity(0.15))
                                .foregroundColor(Color(hex: "#059669"))
                                .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        NavigationLink(destination: MonthlyExpenseReportsView()) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.doc.horizontal.fill")
                                    .font(.system(size: 12))
                                Text("Reports")
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .foregroundColor(FinPilotColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(FinPilotColors.primary.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: SavingsModuleView()) {
                            HStack(spacing: 6) {
                                Text("Savings")
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                    .fixedSize()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#059669"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#10B981").opacity(0.14))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider()
                        .background(Color(hex: "#10B981").opacity(0.2))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#059669"))
                        Text("Unspent earnings transferred to Savings. Records preserved for reports.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Spacer()
                    }
                }
                .padding(14)
                .background(FinPilotColors.surface)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#10B981").opacity(0.3), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
            }
 else {
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#0284C7"))
                            Text("MONTH-END SETTLEMENT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#0284C7"))
                                .tracking(0.8)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0284C7").opacity(0.1))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Text("End of Month: \(formattedSettlementDate(viewModel.endOfMonthDate))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }

                    
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Unspent Income to Save")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(viewModel.currency)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                Text("\(Int(viewModel.leftoverSavings))")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#059669"))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettlementModal = true
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Settle Month")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#059669"), Color(hex: "#10B981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#10B981").opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                    }
                    
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Text("Press to close month: transfers unspent income surplus to Savings. Records & budgets preserved.")
                            .font(.system(size: 11))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Spacer()
                    }
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#059669").opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            }
        }
    }
    
    private var monthSettlementSheet: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Illustration / Badge
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#10B981").opacity(0.14))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(Color(hex: "#059669"))
                            }
                            
                            Text("Settle & Close Month")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(FinPilotColors.textPrimary)
                            
                            Text(currentMonth)
                                .font(FinPilotTypography.subheadline)
                                .foregroundColor(FinPilotColors.primary)
                                .bold()
                        }
                        .padding(.top, 10)
                        
                        // Surplus Transfer Card
                        VStack(spacing: 12) {
                            Text("SURPLUS TO SAVINGS MODULE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#059669"))
                                .tracking(0.8)
                            
                            Text("₹ \(Int(viewModel.leftoverSavings))")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#059669"))
                            
                            Text("Unspent cash from your monthly income will be transferred into your Savings Module.")
                                .font(.system(size: 12))
                                .foregroundColor(FinPilotColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#10B981").opacity(0.1))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#10B981").opacity(0.3), lineWidth: 1.2)
                        )
                        
                        // Breakdown Grid
                        VStack(spacing: 12) {
                            HStack {
                                Text("Monthly Breakdown")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                breakdownTile(title: "Total Income", amount: viewModel.totalIncome, color: .green)
                                breakdownTile(title: "Total Spent", amount: viewModel.totalExpenses, color: .red)
                                breakdownTile(title: "Net Surplus", amount: viewModel.leftoverSavings, color: .blue)
                            }
                        }
                        .padding(16)
                        .background(FinPilotColors.surface)
                        .cornerRadius(18)
                        
                        // Notice box
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT HAPPENS NEXT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(FinPilotColors.textSecondary)
                                .tracking(0.8)
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                Text("Unspent earnings (₹\(Int(viewModel.leftoverSavings))) are saved to Monthly Savings.")
                                    .font(.system(size: 12))
                                    .foregroundColor(FinPilotColors.textPrimary)
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                Text("Category budgets and transactions remain preserved as records for your reports.")
                                    .font(.system(size: 12))
                                    .foregroundColor(FinPilotColors.textPrimary)
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(FinPilotColors.primary)
                                    .font(.system(size: 14))
                                Text("Your recurring expense listing will NOT be removed and stays completely intact.")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(FinPilotColors.primary)
                            }
                        }
                        .padding(16)
                        .background(FinPilotColors.surface)
                        .cornerRadius(18)
                        
                        // Settle Button
                        Button(action: {
                            showingSettlementConfirmation = true
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }) {
                            HStack(spacing: 8) {
                                if viewModel.isSettling {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Settling Month...")
                                        .font(.system(size: 16, weight: .bold))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Confirm Settle & Transfer Surplus")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#059669"), Color(hex: "#10B981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "#10B981").opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isSettling)
                        .padding(.top, 6)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Month-End Settlement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingSettlementModal = false }
                        .foregroundColor(FinPilotColors.textSecondary)
                }
            }
            .alert(isPresented: $showingSettlementConfirmation) {
                Alert(
                    title: Text("Confirm Month Settlement"),
                    message: Text("Are you sure you want to finalize settlement for \(currentMonth)?\n\n• Unspent earnings of ₹\(Int(viewModel.leftoverSavings)) will be deposited into your Savings Module.\n• Category budgets will be preserved as planning records.\n• All transactions will remain preserved for your Monthly Expense Reports.\n• The settled month will be locked."),
                    primaryButton: .default(Text("Yes, Settle Month")) {
                        Task {
                            let success = await viewModel.settleCurrentMonth(userRole: authViewModel.currentUser?.role)
                            if success {
                                let gen = UINotificationFeedbackGenerator()
                                gen.notificationOccurred(.success)
                                showingSettlementModal = false
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
        }
    }
    
    private func breakdownTile(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(FinPilotColors.textSecondary)
            Text("₹\(Int(amount))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Admin Control Section
    private var adminControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text("ADMIN DASHBOARD")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.0)
                
                Spacer()
                
                Text(viewModel.isConsolidated ? "CONSOLIDATED" : "FILTERED")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            HStack(spacing: 10) {
                Menu {
                    Button(action: {
                        Task {
                            await viewModel.selectUser(id: "all", name: "All Users (Consolidated)", userRole: authViewModel.currentUser?.role)
                        }
                    }) {
                        HStack {
                            Text("🌐 All Users (Consolidated)")
                            if viewModel.selectedUserId == "all" || viewModel.selectedUserId.isEmpty {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(viewModel.adminUsers) { user in
                        Button(action: {
                            Task {
                                await viewModel.selectUser(id: user.id, name: user.name, userRole: authViewModel.currentUser?.role)
                            }
                        }) {
                            HStack {
                                Text("\(user.name) (\(user.email))")
                                if viewModel.selectedUserId == user.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.selectedUserId == "all" ? "globe.americas.fill" : "person.crop.circle.fill")
                            .foregroundColor(FinPilotColors.primary)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.selectedUserId == "all" ? "Viewing Scope" : "Viewing User")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Text(viewModel.selectedUserId == "all" ? "All Users (\(viewModel.totalUsersCount) accounts)" : viewModel.selectedUserName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(FinPilotColors.surface)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    Task {
                        await viewModel.loadDashboardData(userRole: authViewModel.currentUser?.role)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E293B"), Color(hex: "#0F172A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Trial Status Banner
    private var trialStatusBanner: some View {
        Button(action: {
            showPaywall = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(entitlementManager.state == .trialExpired ? Color.red.opacity(0.15) : FinPilotColors.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: entitlementManager.state == .trialExpired ? "exclamationmark.shield.fill" : "gift.fill")
                        .font(.system(size: 18))
                        .foregroundColor(entitlementManager.state == .trialExpired ? .red : FinPilotColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entitlementManager.state == .trialExpired ? "Free Trial Expired" : "\(entitlementManager.daysRemaining) Days Free Trial Left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        
                        if entitlementManager.state != .trialExpired {
                            Text("7 DAYS")
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(FinPilotColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                    }
                    
                    Text(entitlementManager.state == .trialExpired ? "Tap to unlock Lifetime Pro" : "Lifetime access • Pay once, own forever")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(entitlementManager.state == .trialExpired ? "Unlock" : (purchaseManager.lifetimeProduct?.displayPrice ?? "$9.99"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(entitlementManager.state == .trialExpired ? Color.red : FinPilotColors.primary)
                    .cornerRadius(8)
            }
            .padding(12)
            .background(FinPilotColors.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(entitlementManager.state == .trialExpired ? Color.red.opacity(0.3) : FinPilotColors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func formattedSettlementDate(_ rawDate: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        if let d = inputFormatter.date(from: rawDate) {
            let out = DateFormatter()
            out.dateFormat = "MMM d, yyyy"
            return out.string(from: d)
        }
        return rawDate.isEmpty ? "Oct 31, 2026" : rawDate
    }
    
    private func checkDueRecurringBills() {
        guard !CommandLine.arguments.contains("--no-alert") else { return }
        guard !hasAlertedDueBillsOnOpen else { return }
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        var dueAlertItems: [String] = []
        for bill in viewModel.upcomingBills {
            guard bill.type.lowercased() == "expense" else { continue }
            let startOfDue = calendar.startOfDay(for: bill.nextDueDate)
            let diffDays = calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 999
            
            if diffDays == 0 {
                dueAlertItems.append("• \(bill.merchant): \(viewModel.currency) \(Int(bill.amount)) (Due Today!)")
            } else if diffDays == 1 {
                dueAlertItems.append("• \(bill.merchant): \(viewModel.currency) \(Int(bill.amount)) (Due Tomorrow)")
            } else if diffDays == 2 {
                dueAlertItems.append("• \(bill.merchant): \(viewModel.currency) \(Int(bill.amount)) (Due in 2 days)")
            } else if diffDays < 0 {
                dueAlertItems.append("• \(bill.merchant): \(viewModel.currency) \(Int(bill.amount)) (Overdue by \(abs(diffDays)) day\(abs(diffDays) > 1 ? "s" : ""))")
            }
        }
        
        if !dueAlertItems.isEmpty {
            hasAlertedDueBillsOnOpen = true
            dueBillsAlertTitle = "Recurring Payment Alert"
            dueBillsAlertMessage = "Upcoming recurring expense(s) due soon:\n\n" + dueAlertItems.joined(separator: "\n") + "\n\nPlease ensure your account has sufficient balance."
            showingDueBillsAlert = true
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
    var showChevron: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let act = action {
                Button(action: act) {
                    cardBody
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardBody
            }
        }
    }
    
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconBg)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Spacer(minLength: 2)
                
                if showChevron || action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.45))
                }
            }
            
            Text(amount)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let g = growth {
                Text(g)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(growthColor)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FinPilotColors.surface)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
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
                if let uName = bill.userName, !uName.isEmpty {
                    Text("👤 \(uName)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(FinPilotColors.primary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(FinPilotColors.primary.opacity(0.1))
                        .cornerRadius(4)
                }

                Text(bill.merchant)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("\(currency) \(Int(bill.amount)) • \(formatDate(bill.nextDueDate))")
                    .font(.system(size: 13))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
            
            let days = daysUntilDue(bill.nextDueDate)
            if days == 0 {
                Text("Due Today")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#EF4444").opacity(0.12))
                    .cornerRadius(8)
            } else if days == 1 {
                Text("Due Tomorrow")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F59E0B").opacity(0.15))
                    .cornerRadius(8)
            } else if days == 2 {
                Text("In 2 Days")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#D97706"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
            } else if days < 0 {
                Text("Overdue")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#DC2626"))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func daysUntilDue(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 999
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
