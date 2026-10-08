import SwiftUI

struct IncomeDrillDownView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let currentMonth: String
    let currency: String
    
    @State private var incomeTransactions: [Transaction] = []
    @State private var totalIncome: Double = 0.0
    @State private var monthlyTarget: Double = 0.0
    @State private var isLoading: Bool = true
    @State private var showingAddIncome: Bool = false
    @State private var selectedTimeFilter: Int = 0 // 0: This Month, 1: All Records
    
    var body: some View {
        ZStack {
            FinPilotColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Custom Navigation Bar
                customNavigationBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero Summary Card
                        incomeHeroCard
                        
                        // Mini Metrics Row
                        metricsRow
                        
                        // Filter Selector
                        filterSelector
                        
                        // Category Breakdown (if entries exist)
                        if !incomeTransactions.isEmpty {
                            categoryBreakdownSection
                        }
                        
                        // Income Field / Transactions List
                        incomeTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 90)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddIncome, onDismiss: {
            Task {
                await loadIncomeData()
                NotificationCenter.default.post(name: .transactionUpdated, object: nil)
            }
        }) {
            AddTransactionView(initialType: "Income", lockType: true)
                .environmentObject(authViewModel)
        }
        .task {
            await loadIncomeData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
            Task {
                await loadIncomeData()
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var customNavigationBar: some View {
        ZStack {
            // Centered Title
            Text("Income Details")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
                .lineLimit(1)
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Dashboard")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundColor(FinPilotColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(FinPilotColors.primary.opacity(0.12))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddIncome = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#059669"), Color(hex: "#10B981")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color(hex: "#10B981").opacity(0.35), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FinPilotColors.surface)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Hero Summary Card
    private var incomeHeroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
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
                .shadow(color: Color(hex: "#059669").opacity(0.35), radius: 14, x: 0, y: 7)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .font(.system(size: 14))
                        Text("TOTAL EARNINGS")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(0.8)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(currentMonth)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currency) \(formatAmount(totalIncome))")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    if monthlyTarget > 0 {
                        HStack(spacing: 6) {
                            Text("Monthly Target: \(currency) \(formatAmount(monthlyTarget))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                            
                            let pct = Int(min((totalIncome / monthlyTarget) * 100, 100))
                            Text("(\(pct)% achieved)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#A7F3D0"))
                        }
                    } else {
                        Text("All income logged for this month")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                if monthlyTarget > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 8)
                            
                            let progressWidth = min(geo.size.width * CGFloat(totalIncome / max(monthlyTarget, 1)), geo.size.width)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: progressWidth, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(22)
        }
    }
    
    // MARK: - Mini Metrics Row
    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Income Records",
                value: "\(filteredTransactions.count)",
                subtitle: "Transactions",
                icon: "tray.full.fill",
                color: Color(hex: "#059669")
            )
            
            let avg = filteredTransactions.isEmpty ? 0 : totalIncome / Double(filteredTransactions.count)
            metricCard(
                title: "Average Entry",
                value: "\(currency) \(formatAmount(avg))",
                subtitle: "Per Deposit",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "#0284C7")
            )
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(FinPilotColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Filter Selector
    private var filterSelector: some View {
        HStack(spacing: 8) {
            filterButton(title: "This Month (\(currentMonth))", index: 0)
            filterButton(title: "All History", index: 1)
        }
        .padding(4)
        .background(Color.black.opacity(0.04))
        .cornerRadius(14)
    }
    
    private func filterButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTimeFilter = index
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: selectedTimeFilter == index ? .bold : .medium, design: .rounded))
                .foregroundColor(selectedTimeFilter == index ? Color(hex: "#059669") : FinPilotColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTimeFilter == index ? Color.white : Color.clear)
                .cornerRadius(10)
                .shadow(color: selectedTimeFilter == index ? Color.black.opacity(0.05) : Color.clear, radius: 3, x: 0, y: 1)
        }
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Income Sources Breakdown")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
            
            let grouped = categoryBreakdownList
            VStack(spacing: 10) {
                ForEach(grouped, id: \.name) { cat in
                    VStack(spacing: 6) {
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#10B981").opacity(0.15))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: iconForCategory(cat.name))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#059669"))
                                }
                                Text(cat.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(FinPilotColors.textPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(currency) \(formatAmount(cat.amount))")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#059669"))
                                Text("\(Int(cat.percentage))%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(FinPilotColors.textSecondary)
                            }
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#059669"), Color(hex: "#10B981")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(g.size.width * CGFloat(cat.percentage / 100.0), 4), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(12)
                    .background(FinPilotColors.surface)
                    .cornerRadius(14)
                }
            }
        }
    }
    
    // MARK: - Income Transactions Section (ONLY INCOME FIELDS)
    private var incomeTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Income History (\(filteredTransactions.count))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Spacer()
                
                Text("Income Only")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#059669"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#10B981").opacity(0.15))
                    .cornerRadius(6)
            }
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color(hex: "#059669"))
                    Text("Loading income records...")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if filteredTransactions.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#10B981").opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#059669"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("No Income Recorded Yet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Add your salary, freelance payments, investments, or other cash inflows.")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Button(action: {
                        showingAddIncome = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Add Income Entry")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
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
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(FinPilotColors.surface)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredTransactions) { tx in
                        incomeRow(tx)
                    }
                }
            }
        }
    }
    
    private func incomeRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#10B981").opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#059669"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.merchant ?? tx.note ?? "Income Deposit")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(formatDate(tx.date))
                        .font(.system(size: 11))
                        .foregroundColor(FinPilotColors.textSecondary)
                    
                    if let note = tx.note, !note.isEmpty, note != tx.merchant {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 3, height: 3)
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+ \(currency) \(formatAmount(tx.amount))")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "#059669"))
                
                Text("Received")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#10B981"))
            }
        }
        .padding(14)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helpers & Data Computation
    private var filteredTransactions: [Transaction] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        let currentMonthKey = df.string(from: Date())
        
        return incomeTransactions.filter { tx in
            // Filter strictly to INCOME type only!
            guard tx.type.lowercased() == "income" else { return false }
            
            if selectedTimeFilter == 0 {
                let txMonthKey = df.string(from: tx.date)
                return txMonthKey == currentMonthKey
            }
            return true
        }
    }
    
    private struct CategorySummary {
        let name: String
        let amount: Double
        let percentage: Double
    }
    
    private var categoryBreakdownList: [CategorySummary] {
        let list = filteredTransactions
        guard !list.isEmpty else { return [] }
        
        var dict: [String: Double] = [:]
        for tx in list {
            let key = tx.merchant ?? tx.note ?? "General Income"
            dict[key, default: 0] += tx.amount
        }
        let total = dict.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return dict.map { (key, val) in
            CategorySummary(name: key, amount: val, percentage: (val / total) * 100)
        }.sorted { $0.amount > $1.amount }
    }
    
    private func iconForCategory(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("salary") { return "briefcase.fill" }
        if lower.contains("freelance") { return "laptopcomputer" }
        if lower.contains("invest") || lower.contains("dividend") { return "chart.line.uptrend.xyaxis" }
        if lower.contains("bonus") { return "gift.fill" }
        if lower.contains("rental") { return "house.fill" }
        return "dollarsign.circle.fill"
    }
    
    private func formatAmount(_ amt: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amt)) ?? "\(Int(amt))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadIncomeData() async {
        isLoading = true
        do {
            let allTxs: [Transaction] = try await APIManager.shared.request(endpoint: "/transactions?include_settled=true")
            // Filter only income transactions
            let incomeOnly = allTxs.filter { $0.type.lowercased() == "income" }
            self.incomeTransactions = incomeOnly
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            let curMonthKey = df.string(from: Date())
            let thisMonthSum = incomeOnly
                .filter { df.string(from: $0.date) == curMonthKey }
                .reduce(0.0) { $0 + $1.amount }
            
            self.totalIncome = thisMonthSum
            self.monthlyTarget = authViewModel.currentUser?.monthlyIncome ?? 0.0
        } catch {
            print("Failed to load income transactions: \(error)")
        }
        isLoading = false
    }
}
