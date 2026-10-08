import SwiftUI

struct MockTransaction: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let isIncome: Bool
    var isSettled: Bool = false
    var userName: String? = nil
    var userEmail: String? = nil
    var note: String? = nil
    var rawDate: Date? = nil
    var categoryName: String? = nil
    var type: String? = nil
}

struct MockTransactionGroup: Identifiable {
    let id: String
    let dateStr: String
    let transactions: [MockTransaction]
}

enum DateFilterMode: String, CaseIterable, Identifiable {
    case all = "All Dates"
    case today = "Today"
    case yesterday = "Yesterday"
    case thisMonth = "This Month"
    case custom = "Pick Date"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .today: return "sun.max.fill"
        case .yesterday: return "arrow.uturn.backward"
        case .thisMonth: return "calendar.badge.clock"
        case .custom: return "calendar.badge.plus"
        }
    }
}

struct SwipeToDeleteRow: View {
    let tx: MockTransaction
    @ObservedObject var viewModel: TransactionsViewModel
    var onSelect: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            TransactionsTabRow(tx: tx)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteTransaction(id: tx.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(FinPilotColors.error)
        }
    }
}

struct TransactionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var selectedFilter = 0 // 0 = All, 1 = Expenses, 2 = Income
    @State private var selectedDateFilter: DateFilterMode = .all
    @State private var customSelectedDate: Date = Date()
    @State private var showingDatePickerSheet = false
    @State private var showingAddTransaction = false
    @State private var selectedDetailTx: MockTransaction? = nil
    let filters = ["All", "Expenses", "Income"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                if authViewModel.currentUser?.role?.uppercased() == "ADMIN" {
                    adminUserSelectorView
                }
                
                // Type Filter (Segmented control)
                HStack {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Button(action: {
                            selectedFilter = index
                        }) {
                            Text(filters[index])
                                .font(FinPilotTypography.subheadline)
                                .foregroundColor(selectedFilter == index ? .white : FinPilotColors.textSecondary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedFilter == index ? FinPilotColors.primary : Color.clear)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(4)
                .background(FinPilotColors.surface)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                // Date Filter Chips (Date-wise filtration)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DateFilterMode.allCases) { mode in
                            Button(action: {
                                if mode == .custom {
                                    showingDatePickerSheet = true
                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDateFilter = mode
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(mode == .custom && selectedDateFilter == .custom ? formattedCustomDatePill : mode.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(selectedDateFilter == mode ? .white : FinPilotColors.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedDateFilter == mode
                                        ? FinPilotColors.primary
                                        : FinPilotColors.surface
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedDateFilter == mode ? Color.clear : FinPilotColors.border.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Active Date Banner & Day Totals
                if selectedDateFilter != .all {
                    activeDateFilterBanner
                }
                
                if let errorMessage = viewModel.errorMessage {
                    ScrollView {
                        Text(errorMessage)
                            .foregroundColor(FinPilotColors.error)
                            .padding()
                    }
                } else if filteredGroups.isEmpty && !viewModel.isLoading {
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(systemName: selectedDateFilter == .all ? "tray" : "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                            
                            Text(selectedDateFilter == .all ? "No transactions yet. Tap + to add one!" : "No transactions on \(activeFilterTitle)")
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            if selectedDateFilter != .all {
                                Button(action: {
                                    withAnimation {
                                        selectedDateFilter = .all
                                    }
                                }) {
                                    Text("Show All Dates")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(FinPilotColors.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(FinPilotColors.primary.opacity(0.1))
                                        .cornerRadius(20)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                } else {
                    List {
                        ForEach(filteredGroups) { group in
                            Section(header: Text(group.dateStr)
                                .font(FinPilotTypography.headline)
                                .foregroundColor(FinPilotColors.textPrimary)
                                .textCase(nil)
                                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20))
                                .listRowBackground(Color.clear)
                            ) {
                                ForEach(group.transactions) { tx in
                                    SwipeToDeleteRow(tx: tx, viewModel: viewModel) {
                                        selectedDetailTx = tx
                                    }
                                }
                            }
                        }
                        
                        // Buffer space so bottom transaction is never occluded by the action button
                        Section {
                            Color.clear.frame(height: 72)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transactions")
                        .font(FinPilotTypography.title3)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(FinPilotColors.primary)
                    }
                }
            }
            .task {
                await viewModel.fetchTransactions(isAdmin: authViewModel.currentUser?.role?.uppercased() == "ADMIN")
            }
            .refreshable {
                await viewModel.fetchTransactions(isAdmin: authViewModel.currentUser?.role?.uppercased() == "ADMIN")
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(item: $selectedDetailTx) { tx in
                TransactionDetailSheet(tx: tx, viewModel: viewModel)
            }
            .sheet(isPresented: $showingDatePickerSheet) {
                datePickerSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                Task {
                    await viewModel.fetchTransactions(isAdmin: authViewModel.currentUser?.role?.uppercased() == "ADMIN")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowAddTx"))) { _ in
                showingAddTransaction = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .filterTransactions)) { notif in
                if let idx = notif.object as? Int {
                    withAnimation {
                        selectedFilter = idx
                    }
                }
            }
            .onAppear {
                if CommandLine.arguments.contains("--date-yesterday") {
                    selectedDateFilter = .yesterday
                } else if CommandLine.arguments.contains("--date-picker") {
                    showingDatePickerSheet = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(
            Button(action: {
                showingAddTransaction = true
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(FinPilotColors.primary)
                    .clipShape(Circle())
                    .shadow(color: FinPilotColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24),
            alignment: .bottomTrailing
        )
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing...")
    }
    
    // MARK: - Admin User Selector View
    private var adminUserSelectorView: some View {
        HStack(spacing: 10) {
            Menu {
                Button(action: {
                    viewModel.selectedAdminUserId = "all"
                    viewModel.selectedAdminUserName = "All Users"
                    Task {
                        await viewModel.fetchTransactions(targetUserId: "all", isAdmin: true)
                    }
                }) {
                    HStack {
                        Text("🌐 All Users (Consolidated)")
                        if viewModel.selectedAdminUserId == "all" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                ForEach(viewModel.adminUsers) { user in
                    Button(action: {
                        viewModel.selectedAdminUserId = user.id
                        viewModel.selectedAdminUserName = user.name
                        Task {
                            await viewModel.fetchTransactions(targetUserId: user.id, isAdmin: true)
                        }
                    }) {
                        HStack {
                            Text("\(user.name) (\(user.email ?? ""))")
                            if viewModel.selectedAdminUserId == user.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.selectedAdminUserId == "all" ? "globe.americas.fill" : "person.crop.circle.fill")
                        .foregroundColor(FinPilotColors.primary)
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Filter Transactions by User (Admin)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Text(viewModel.selectedAdminUserId == "all" ? "All Users" : viewModel.selectedAdminUserName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(FinPilotColors.surface)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(FinPilotColors.primary.opacity(0.3), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
    
    // MARK: - Active Date Filter Banner
    private var activeDateFilterBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FinPilotColors.primary)
                    Text(activeFilterTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                
                HStack(spacing: 8) {
                    Text("Spent: -₹ \(formatAmount(daySummary.expense))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#EF4444"))
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                    
                    Text("Income: +₹ \(formatAmount(daySummary.income))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#059669"))
                }
            }
            
            Spacer()
            
            if selectedDateFilter == .today || selectedDateFilter == .yesterday || selectedDateFilter == .custom {
                HStack(spacing: 6) {
                    Button(action: { stepDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(FinPilotColors.background)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { stepDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(FinPilotColors.background)
                            .clipShape(Circle())
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    selectedDateFilter = .all
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(FinPilotColors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FinPilotColors.border.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Date Picker Modal Sheet
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Select Date",
                    selection: $customSelectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(FinPilotColors.primary)
                .padding()
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                Button(action: {
                    selectedDateFilter = .custom
                    showingDatePickerSheet = false
                }) {
                    Text("Apply Date Filter")
                        .font(FinPilotTypography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(FinPilotColors.primary)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                
                Button(action: {
                    selectedDateFilter = .all
                    showingDatePickerSheet = false
                }) {
                    Text("Clear Filter (Show All)")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDatePickerSheet = false
                    }
                    .foregroundColor(FinPilotColors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Date Filtering & Helpers
    private func stepDate(by days: Int) {
        let calendar = Calendar.current
        let current: Date
        switch selectedDateFilter {
        case .today: current = Date()
        case .yesterday: current = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .custom: current = customSelectedDate
        default: current = Date()
        }
        if let next = calendar.date(byAdding: .day, value: days, to: current) {
            customSelectedDate = next
            selectedDateFilter = .custom
        }
    }
    
    private var dateFilteredTransactions: [Transaction] {
        let calendar = Calendar.current
        return viewModel.transactions.filter { tx in
            // Type filter
            if selectedFilter == 1 && tx.amount >= 0 { return false } // Expenses only
            if selectedFilter == 2 && tx.amount < 0 { return false } // Income only
            
            // Date filter
            switch selectedDateFilter {
            case .all:
                return true
            case .today:
                return calendar.isDateInToday(tx.date)
            case .yesterday:
                return calendar.isDateInYesterday(tx.date)
            case .thisMonth:
                return calendar.isDate(tx.date, equalTo: Date(), toGranularity: .month)
            case .custom:
                return calendar.isDate(tx.date, inSameDayAs: customSelectedDate)
            }
        }
    }
    
    private var daySummary: (expense: Double, income: Double, count: Int) {
        var exp: Double = 0
        var inc: Double = 0
        for tx in dateFilteredTransactions {
            if tx.amount < 0 {
                exp += abs(tx.amount)
            } else {
                inc += tx.amount
            }
        }
        return (exp, inc, dateFilteredTransactions.count)
    }
    
    private var activeFilterTitle: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        
        switch selectedDateFilter {
        case .all:
            return "All Dates"
        case .today:
            return "Today (\(df.string(from: Date())))"
        case .yesterday:
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return "Yesterday (\(df.string(from: yesterday)))"
        case .thisMonth:
            let mf = DateFormatter()
            mf.dateFormat = "MMMM yyyy"
            return "This Month (\(mf.string(from: Date())))"
        case .custom:
            return df.string(from: customSelectedDate)
        }
    }
    
    private var formattedCustomDatePill: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: customSelectedDate)
    }
    
    private func formatAmount(_ amt: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amt)) ?? "\(Int(amt))"
    }
    
    private var filteredGroups: [MockTransactionGroup] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.doesRelativeDateFormatting = true
        
        let tf = DateFormatter()
        tf.timeStyle = .short
        
        let txs = dateFilteredTransactions
        
        // Group by date string
        let grouped = Dictionary(grouping: txs) { tx -> String in
            return df.string(from: tx.date)
        }
        
        // Sort keys descending
        let sortedKeys = grouped.keys.sorted { k1, k2 in
            let d1 = grouped[k1]?.first?.date ?? Date.distantPast
            let d2 = grouped[k2]?.first?.date ?? Date.distantPast
            return d1 > d2
        }
        
        return sortedKeys.map { key in
            let dayTxs = (grouped[key] ?? []).sorted(by: { $0.date > $1.date })
            let mockTxs = dayTxs.map { tx in
                MockTransaction(
                    id: tx.id,
                    icon: iconForCategory(tx.categoryId ?? ""),
                    iconColor: colorForCategory(tx.categoryId ?? ""),
                    title: tx.merchant ?? tx.note ?? "Transaction",
                    subtitle: "\(tx.categoryId ?? "General") • \(tf.string(from: tx.date))",
                    amount: "\(tx.amount < 0 ? "-" : "+")₹ \(abs(tx.amount).formatted(.number.precision(.fractionLength(0))))",
                    isIncome: tx.amount >= 0,
                    isSettled: tx.isSettled ?? false,
                    userName: tx.userName,
                    userEmail: tx.userEmail,
                    note: tx.note,
                    rawDate: tx.date,
                    categoryName: tx.categoryId,
                    type: tx.type
                )
            }
            return MockTransactionGroup(id: UUID().uuidString, dateStr: key, transactions: mockTxs)
        }
    }
    
    private func iconForCategory(_ cat: String) -> String {
        switch cat.lowercased() {
        case "food", "dining", "restaurant", "cafe": return "fork.knife"
        case "groceries", "grocery", "supermarket": return "cart.fill"
        case "transport", "travel", "fuel", "commute", "cab", "uber": return "car.fill"
        case "shopping", "ecommerce", "clothes", "clothing": return "bag.fill"
        case "bills", "utilities", "electricity", "water", "recharge": return "doc.text.fill"
        case "health", "medical", "pharmacy", "doctor": return "heart.fill"
        case "salary", "income", "wage", "freelance": return "banknote.fill"
        case "entertainment", "movies", "games", "netflix": return "film.fill"
        case "investment", "stocks", "mutual funds", "crypto": return "chart.line.uptrend.xyaxis"
        case "education", "books", "course": return "book.fill"
        case "housing", "rent", "home": return "house.fill"
        case "personal", "lifestyle": return "person.fill"
        default: return "creditcard.fill"
        }
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat.lowercased() {
        case "food", "dining", "restaurant", "cafe": return .orange
        case "groceries", "grocery", "supermarket": return Color(hex: "#10B981")
        case "transport", "travel", "fuel", "commute", "cab", "uber": return .blue
        case "shopping", "ecommerce", "clothes", "clothing": return .purple
        case "bills", "utilities", "electricity", "water", "recharge": return .indigo
        case "health", "medical", "pharmacy", "doctor": return .red
        case "salary", "income", "wage", "freelance": return Color(hex: "#059669")
        case "entertainment", "movies", "games", "netflix": return .pink
        case "investment", "stocks", "mutual funds", "crypto": return .teal
        case "education", "books", "course": return .yellow
        case "housing", "rent", "home": return .brown
        case "personal", "lifestyle": return .blue
        default: return FinPilotColors.primary
        }
    }
}

struct TransactionsTabRow: View {
    let tx: MockTransaction
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(tx.iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: tx.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tx.iconColor)
            }
            
            // Middle Details Column
            VStack(alignment: .leading, spacing: 3) {
                // Title Line (Full width, no badge crowding)
                Text(tx.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FinPilotColors.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                // Subtitle Line (Category, Time)
                Text(tx.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .lineLimit(1)
                
                // Badges Row (User tag & Settled tag) displayed cleanly below
                if (tx.userName != nil && !tx.userName!.isEmpty) || tx.isSettled {
                    HStack(spacing: 6) {
                        if let uName = tx.userName, !uName.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 8))
                                Text(uName)
                                    .font(.system(size: 9.5, weight: .semibold))
                            }
                            .foregroundColor(FinPilotColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FinPilotColors.primary.opacity(0.1))
                            .cornerRadius(4)
                            .fixedSize(horizontal: true, vertical: true)
                        }
                        
                        if tx.isSettled {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                Text("Settled")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#059669"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#059669").opacity(0.12))
                            .cornerRadius(4)
                            .fixedSize(horizontal: true, vertical: true)
                        }
                    }
                    .padding(.top, 1)
                }
            }
            
            Spacer(minLength: 8)
            
            // Amount Display (Right Aligned, Never Squeezed)
            Text(tx.amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(tx.isIncome ? FinPilotColors.success : FinPilotColors.textPrimary)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FinPilotColors.surface)
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
        )
    }
}

struct TransactionDetailSheet: View {
    let tx: MockTransaction
    @ObservedObject var viewModel: TransactionsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Circle + Title + Amount
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(tx.iconColor.opacity(0.12))
                                .frame(width: 68, height: 68)
                            
                            Image(systemName: tx.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(tx.iconColor)
                        }
                        .padding(.top, 12)
                        
                        Text(tx.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Text(tx.amount)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(tx.isIncome ? FinPilotColors.success : FinPilotColors.textPrimary)
                        
                        if tx.isSettled {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Settled in Monthly Report")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#059669"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#059669").opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Transaction Info Table Card
                    VStack(spacing: 0) {
                        detailRow(title: "Category", value: tx.categoryName ?? "General", icon: "folder.fill")
                        Divider().padding(.horizontal, 16)
                        
                        if let d = tx.rawDate {
                            detailRow(title: "Date & Time", value: formattedDetailDate(d), icon: "calendar")
                            Divider().padding(.horizontal, 16)
                        }
                        
                        detailRow(title: "Type", value: (tx.type ?? (tx.isIncome ? "Income" : "Expense")).capitalized, icon: "arrow.left.arrow.right")
                        
                        if let u = tx.userName, !u.isEmpty {
                            Divider().padding(.horizontal, 16)
                            detailRow(title: "Created By", value: "\(u)\(tx.userEmail != nil && !tx.userEmail!.isEmpty ? " (\(tx.userEmail!))" : "")", icon: "person.fill")
                        }
                        
                        if let n = tx.note, !n.isEmpty, n != tx.title {
                            Divider().padding(.horizontal, 16)
                            detailRow(title: "Notes", value: n, icon: "note.text")
                        }
                    }
                    .background(FinPilotColors.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(FinPilotColors.border.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Delete Button
                    Button(action: {
                        showingDeleteConfirm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Delete Transaction")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(FinPilotColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(FinPilotColors.error.opacity(0.1))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FinPilotColors.primary)
                }
            }
            .alert(isPresented: $showingDeleteConfirm) {
                Alert(
                    title: Text("Delete Transaction"),
                    message: Text("Are you sure you want to permanently delete this transaction?"),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            await viewModel.deleteTransaction(id: tx.id)
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FinPilotColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(FinPilotColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func formattedDetailDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TransactionsViewModel()
    
    @State private var transactionType: String = "Expense"
    let transactionTypes = ["Income", "Expense", "Transfer"]
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var date: Date
    @State private var note: String = ""
    @State private var showCalendarPicker = CommandLine.arguments.contains("--calendar-open")
    @State private var showingBudgetAlert = false
    @State private var budgetAlertMessage = ""
    
    // Transfer specific
    @State private var fromAccount: String = "Checking"
    @State private var toAccount: String = "Savings"
    let mockAccounts = ["Checking", "Savings", "Credit Card", "Investment"]
    
    var lockType: Bool = false
    
    init(initialType: String = "Expense", lockType: Bool = false) {
        _transactionType = State(initialValue: initialType)
        _selectedCategory = State(initialValue: initialType.lowercased() == "income" ? "Salary" : "Food")
        self.lockType = lockType
        var initDate = Date()
        if CommandLine.arguments.contains("--date-prev-month") {
            if let prev = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
                initDate = prev
            }
        }
        _date = State(initialValue: initDate)
    }

    
    private var selectedMonthKey: String {

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return df.string(from: date)
    }
    
    private var isDateInSettledMonth: Bool {
        // Only lock if the specific month is actually settled
        if viewModel.settledMonths.contains(selectedMonthKey) {
            return true
        }
        if let userSettled = authViewModel.currentUser?.settledMonths, userSettled.contains(selectedMonthKey) {
            return true
        }
        return false
    }
    
    
    // We will merge fetched categories with the user's custom one if they type it.

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Picker for Type or locked badge
                if !lockType {
                    Picker("Type", selection: $transactionType) {
                        ForEach(transactionTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: transactionType.lowercased() == "income" ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(transactionType.lowercased() == "income" ? Color(hex: "#059669") : Color(hex: "#EF4444"))
                        Text("New \(transactionType) Entry")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Transaction Date asked FIRST
                            transactionDateSection
                                .id("transactionDateSection")
                            
                            // 2. Amount Input
                            amountInputSection
                            
                            // 3. Category or Transfer Details
                            if transactionType == "Transfer" {
                                transferAccountsSection
                            } else {
                                categorySection
                            }
                            
                            // 4. Notes & Tags
                            notesSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // Space for sticky button
                    }
                    .onAppear {
                        if CommandLine.arguments.contains("--scroll-details") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation {
                                    scrollProxy.scrollTo("transactionDateSection", anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add \(transactionType)")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
            }
            .overlay(
                saveButton
                , alignment: .bottom
            )
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Saving...")
        .task {
            await viewModel.fetchCategories()
            await viewModel.fetchSettledMonths()
        }
        .onAppear {
            if CommandLine.arguments.contains("--date-prev-month") {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
                    date = prev
                }
            }
        }

        .alert(isPresented: $showingBudgetAlert) {
            Alert(
                title: Text("Budget Exceeded"),
                message: Text(budgetAlertMessage),
                primaryButton: .destructive(Text("Proceed")) {
                    saveTransaction(ignoreBudget: true)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Enter Amount")
                .font(FinPilotTypography.subheadline)
                .foregroundColor(FinPilotColors.textSecondary)
            
            HStack(spacing: 4) {
                Text("₹")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                TextField("0", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .fixedSize()
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Category")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            let displayCategories = viewModel.categories.filter { $0.type.lowercased() == transactionType.lowercased() }
            
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 20) {
                ForEach(displayCategories, id: \.id) { category in
                    CategoryIcon(
                        title: category.name,
                        icon: category.icon ?? "tag.fill",
                        color: colorForHexString(category.color),
                        isSelected: selectedCategory == category.name
                    )
                    .onTapGesture {
                        selectedCategory = category.name
                    }
                }
                

            }
        }
    }

    private func colorForHexString(_ hex: String?) -> Color {
        guard let hex = hex else { return .blue }
        switch hex.lowercased() {
        case "#ff5733": return .orange
        case "#33ff57": return .green
        case "#3357ff": return .blue
        case "#ff33a1": return .pink
        case "#a133ff": return .purple
        case "#ffc300": return .yellow
        default: return .blue
        }
    }
    
    private var transferAccountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transfer Details")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("From")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Spacer()
                    Picker("From Account", selection: $fromAccount) {
                        ForEach(mockAccounts, id: \.self) { acc in
                            Text(acc).tag(acc)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(12)
                
                HStack {
                    Text("To")
                        .font(FinPilotTypography.body)
                        .foregroundColor(FinPilotColors.textSecondary)
                    Spacer()
                    Picker("To Account", selection: $toAccount) {
                        ForEach(mockAccounts, id: \.self) { acc in
                            Text(acc).tag(acc)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(16)
                .background(FinPilotColors.surface)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 1. Transaction Date (Asked First)
    private var transactionDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(FinPilotColors.primary)
                Text("Transaction Date")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showCalendarPicker.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(date, style: .date)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: showCalendarPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(FinPilotColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FinPilotColors.primary.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            
            // Quick Date Preset Chips
            HStack(spacing: 8) {
                datePresetChip(label: "Today", daysOffset: 0)
                datePresetChip(label: "Yesterday", daysOffset: -1)
                datePresetChip(label: "2 Days Ago", daysOffset: -2)
            }
            
            // Expandable Graphical Calendar
            if showCalendarPicker {
                VStack {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(FinPilotColors.primary)
                }
                .padding(8)
                .background(Color.gray.opacity(0.04))
                .cornerRadius(12)
            }
            
            // Settled Month Lock Warning
            if isDateInSettledMonth {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Month Settled & Locked")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                        Text("Month \(selectedMonthKey) was already settled. Adding new expenses or income to a closed month is disabled.")
                            .font(.system(size: 11))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 4. Notes & Tags Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundColor(FinPilotColors.primary)
                Text("Notes & Tags")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                Spacer()
                Text("\(note.count)/150")
                    .font(.system(size: 11))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Add context, merchant, or bill description...")
                        .font(.system(size: 14))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $note)
                    .font(.system(size: 14))
                    .frame(minHeight: 65)
                    .scrollContentBackground(.hidden)
            }
            
            // Quick Suggestion Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Personal", "Business", "Tax Deductible", "Dining Out", "Groceries", "Online Order", "Paid with Cash", "Shared Split"], id: \.self) { tag in
                        Button(action: {
                            if note.isEmpty {
                                note = tag
                            } else if !note.contains(tag) {
                                note += " • \(tag)"
                            }
                        }) {
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(FinPilotColors.primary.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
    
    private func datePresetChip(label: String, daysOffset: Int) -> some View {
        let target = Calendar.current.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()
        let isSelected = Calendar.current.isDate(date, inSameDayAs: target)
        
        return Button(action: {
            date = target
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AnyView(FinPilotColors.primary) : AnyView(Color.gray.opacity(0.12)))
                .cornerRadius(12)
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveTransaction(ignoreBudget: false)
        }) {
            ZStack {
                if isDateInSettledMonth {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text("Month \(selectedMonthKey) is Locked")
                            .font(FinPilotTypography.headline)
                    }
                    .foregroundColor(.white)
                } else {
                    Text("Save \(transactionType)")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .padding(.vertical, 18)
            .background(
                isDateInSettledMonth
                    ? Color.gray
                    : FinPilotColors.primary.opacity(viewModel.isLoading ? 0.7 : 1.0)
            )
            .cornerRadius(16)
            .shadow(color: FinPilotColors.primary.opacity(isDateInSettledMonth ? 0 : 0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading || isDateInSettledMonth)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [FinPilotColors.background.opacity(0), FinPilotColors.background]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func saveTransaction(ignoreBudget: Bool) {
        guard !isDateInSettledMonth else { return }
        if let amountDouble = Double(amount.replacingOccurrences(of: ",", with: "")) {
            Task {
                if transactionType == "Expense" && !ignoreBudget {
                    if let alertMsg = await viewModel.checkBudgetExceeded(categoryId: selectedCategory, amount: amountDouble) {
                        budgetAlertMessage = alertMsg
                        showingBudgetAlert = true
                        return
                    }
                }
                
                let finalAmount = transactionType == "Expense" ? -amountDouble : amountDouble
                let typeString = transactionType.lowercased()
                let cat = transactionType == "Transfer" ? "Transfer" : selectedCategory
                
                let destAcc = transactionType == "Transfer" ? toAccount : nil
                let srcAcc = transactionType == "Transfer" ? fromAccount : "default"
                
                await viewModel.addTransaction(
                    amount: finalAmount,
                    merchant: cat,
                    category: cat,
                    date: date,
                    note: note.isEmpty ? nil : note,
                    type: typeString,
                    accountId: srcAcc,
                    destinationAccountId: destAcc
                )
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CategoryIcon: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? FinPilotColors.textPrimary : FinPilotColors.textSecondary)
        }
    }
}
