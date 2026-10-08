import SwiftUI

final class MonthlyExpenseReportsViewModel: ObservableObject {
    @Published var settledMonths: [SettledMonthSummary] = []
    @Published var selectedMonth: String = ""
    @Published var selectedItemId: String = ""
    @Published var reportDetail: MonthlyExpenseReportDetail?
    @Published var isLoadingList = false
    @Published var isLoadingDetail = false
    @Published var errorMessage: String?
    
    // Admin filtering
    @Published var adminUsers: [AdminUser] = []
    @Published var selectedAdminUserId: String = "all"
    @Published var selectedAdminUserName: String = "All Users"
    
    func fetchSettledMonths(preselectedMonth: String? = nil, isAdmin: Bool = false) async {
        await MainActor.run {
            isLoadingList = true
            errorMessage = nil
        }
        
        if isAdmin && adminUsers.isEmpty {
            do {
                let users: [AdminUser] = try await APIManager.shared.request(endpoint: "/admin/users")
                await MainActor.run {
                    self.adminUsers = users
                }
            } catch {
                print("Failed to fetch admin users in reports: \(error)")
            }
        }
        
        do {
            let userQuery = (isAdmin && selectedAdminUserId != "all" && !selectedAdminUserId.isEmpty)
                ? "?user_id=\(selectedAdminUserId)"
                : ""
            let res: MonthlyExpenseReportsListResponse = try await APIManager.shared.request(endpoint: "/reports/monthly-expense\(userQuery)")
            await MainActor.run {
                self.settledMonths = res.settledMonths
                if let preselected = preselectedMonth, let matched = res.settledMonths.first(where: { $0.month == preselected }) {
                    self.selectedMonth = matched.month
                    self.selectedItemId = matched.id
                } else if !res.settledMonths.isEmpty {
                    let first = res.settledMonths[0]
                    self.selectedMonth = first.month
                    self.selectedItemId = first.id
                } else {
                    self.selectedMonth = ""
                    self.selectedItemId = ""
                    self.reportDetail = nil
                }
                self.isLoadingList = false
            }
            
            if !self.selectedMonth.isEmpty {
                let targetUser = self.settledMonths.first(where: { $0.id == self.selectedItemId })?.userId
                await fetchReportDetail(month: self.selectedMonth, userId: targetUser)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load settled months: \(error.localizedDescription)"
                self.isLoadingList = false
            }
        }
    }
    
    func fetchReportDetail(month: String, userId: String? = nil) async {
        await MainActor.run {
            isLoadingDetail = true
        }
        
        do {
            var ep = "/reports/monthly-expense?month=\(month)"
            if let uid = userId, !uid.isEmpty {
                ep += "&user_id=\(uid)"
            } else if selectedAdminUserId != "all" && !selectedAdminUserId.isEmpty {
                ep += "&user_id=\(selectedAdminUserId)"
            }
            let detail: MonthlyExpenseReportDetail = try await APIManager.shared.request(endpoint: ep)
            await MainActor.run {
                self.reportDetail = detail
                self.isLoadingDetail = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load report for \(month): \(error.localizedDescription)"
                self.isLoadingDetail = false
            }
        }
    }
}

struct MonthlyExpenseReportsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MonthlyExpenseReportsViewModel()
    var initialMonth: String? = nil
    
    var body: some View {
        ZStack {
            FinPilotColors.background.ignoresSafeArea()
            
            if viewModel.isLoadingList && viewModel.settledMonths.isEmpty {
                ProgressView("Loading Expense Reports...")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
            } else if viewModel.settledMonths.isEmpty {
                VStack(spacing: 16) {
                    if authViewModel.currentUser?.role?.uppercased() == "ADMIN" {
                        adminUserSelectorView
                            .padding(.top, 16)
                    }
                    emptySettledState
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if authViewModel.currentUser?.role?.uppercased() == "ADMIN" {
                            adminUserSelectorView
                        }
                        
                        // Month Selector Carousel
                        monthSelectorView
                        
                        if viewModel.isLoadingDetail {
                            ProgressView()
                                .padding(.top, 40)
                        } else if let report = viewModel.reportDetail {
                            // High level metrics
                            overviewCards(report: report)
                            
                            // Category breakdown
                            if !report.categoryBreakdown.isEmpty {
                                categoryBreakdownSection(breakdown: report.categoryBreakdown)
                            }
                            
                            // Preserved Transactions
                            preservedTransactionsSection(transactions: report.transactions)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Expense Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchSettledMonths(
                preselectedMonth: initialMonth,
                isAdmin: authViewModel.currentUser?.role?.uppercased() == "ADMIN"
            )
        }
    }
    
    // MARK: - Admin User Selector View
    private var adminUserSelectorView: some View {
        HStack(spacing: 10) {
            Menu {
                Button(action: {
                    viewModel.selectedAdminUserId = "all"
                    viewModel.selectedAdminUserName = "All Users"
                    Task {
                        await viewModel.fetchSettledMonths(isAdmin: true)
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
                            await viewModel.fetchSettledMonths(isAdmin: true)
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
                        Text("Filter Reports by User (Admin)")
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
    }
    
    // MARK: - Subviews
    
    private var monthSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.settledMonths) { item in
                    let isSelected = (viewModel.selectedItemId == item.id) || (viewModel.selectedItemId.isEmpty && viewModel.selectedMonth == item.month)
                    Button(action: {
                        viewModel.selectedMonth = item.month
                        viewModel.selectedItemId = item.id
                        Task {
                            await viewModel.fetchReportDetail(month: item.month, userId: item.userId)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 11))
                                Text(formatMonth(item.month))
                                    .font(.system(size: 13, weight: .bold))
                            }
                            if authViewModel.currentUser?.role?.uppercased() == "ADMIN", let name = item.userName, !name.isEmpty {
                                Text("👤 \(name)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                    .opacity(isSelected ? 0.95 : 0.75)
                            }
                        }
                        .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isSelected
                                ? AnyView(FinPilotColors.primary)
                                : AnyView(FinPilotColors.surface)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.18), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func overviewCards(report: MonthlyExpenseReportDetail) -> some View {
        VStack(spacing: 14) {
            // Main Banner
            VStack(alignment: .leading, spacing: 10) {
                if authViewModel.currentUser?.role?.uppercased() == "ADMIN", let name = report.userName, !name.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FinPilotColors.primary)
                        Text(name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        if let email = report.userEmail, !email.isEmpty {
                            Text("• \(email)")
                                .font(.system(size: 11))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FinPilotColors.primary.opacity(0.08))
                    .cornerRadius(8)
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("SETTLED MONTH")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                            .tracking(0.6)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    if let dateStr = report.settledAt {
                        Text("Settled on \(formatDate(dateStr))")
                            .font(.system(size: 11))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                
                Text(formatMonth(report.month))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                // 4-metric overview grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.left.circle.fill")
                                .foregroundColor(Color(hex: "#059669"))
                                .font(.system(size: 13))
                            Text("Total Income")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        Text("₹\(Int(report.totalIncome))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#059669"))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#059669").opacity(0.08))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 13))
                            Text("Total Spent")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        Text("₹\(Int(report.totalExpenses))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(FinPilotColors.primary)
                                .font(.system(size: 13))
                            Text("Saved to Reserves")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        Text("₹\(Int(report.savedAmount))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FinPilotColors.primary.opacity(0.08))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 13))
                            Text("Budget Allocated")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        Text("₹\(Int(report.totalBudget))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding(18)
            .background(FinPilotColors.surface)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    private func categoryBreakdownSection(breakdown: [ReportCategoryBreakdown]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category Breakdown")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(FinPilotColors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(breakdown) { cat in
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: cat.icon.isEmpty ? "tag.fill" : cat.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: cat.color))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: cat.color).opacity(0.12))
                                .clipShape(Circle())
                            
                            Text(cat.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FinPilotColors.textPrimary)
                            
                            Spacer()
                            
                            Text("₹\(Int(cat.amount))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                            
                            Text("(\(Int(cat.percentage))%)")
                                .font(.system(size: 12))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(Color(hex: cat.color))
                                    .frame(width: max(4, geo.size.width * CGFloat(cat.percentage / 100)), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(FinPilotColors.surface)
            .cornerRadius(16)
        }
    }
    
    private func preservedTransactionsSection(transactions: [ReportTransactionItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Settled Transactions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
                Spacer()
                Text("\(transactions.count) record(s) preserved")
                    .font(.system(size: 12))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            if transactions.isEmpty {
                Text("No transaction records found for this settled month.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(FinPilotColors.surface)
                    .cornerRadius(16)
            } else {
                VStack(spacing: 10) {
                    ForEach(transactions) { tx in
                        HStack(spacing: 12) {
                            Image(systemName: tx.categoryIcon ?? "tag.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: tx.categoryColor ?? "#6366F1"))
                                .frame(width: 40, height: 40)
                                .background(Color(hex: tx.categoryColor ?? "#6366F1").opacity(0.12))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tx.merchant ?? "Expense")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(FinPilotColors.textPrimary)
                                
                                HStack(spacing: 6) {
                                    Text(tx.categoryName ?? "General")
                                        .font(.system(size: 12))
                                        .foregroundColor(FinPilotColors.textSecondary)
                                    Text("•")
                                        .foregroundColor(FinPilotColors.textSecondary)
                                    Text(tx.date, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(FinPilotColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₹\(Int(abs(tx.amount)))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(tx.type == "income" ? .green : .red)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                    Text("Archived")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                            }
                        }
                        .padding(12)
                        .background(FinPilotColors.surface)
                        .cornerRadius(14)
                    }
                }
            }
        }
    }
    
    private var emptySettledState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
            
            Text("No Settled Months Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(FinPilotColors.textPrimary)
            
            Text("When you settle a month from the Dashboard at month-end, all transactions and category stats for that month are safely preserved here for historical reports.")
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 60)
    }
    
    private func formatMonth(_ monthStr: String) -> String {
        let parts = monthStr.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else {
            return monthStr
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        if let d = Calendar.current.date(from: comps) {
            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            return df.string(from: d)
        }
        return monthStr
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = df.date(from: dateStr) {
            let out = DateFormatter()
            out.dateStyle = .medium
            return out.string(from: d)
        }
        return dateStr.prefix(10).description
    }
}
