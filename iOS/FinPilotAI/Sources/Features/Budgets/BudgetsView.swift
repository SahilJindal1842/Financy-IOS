import SwiftUI

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetsViewModel()
    @State private var showingSetBudget = false
    @State private var selectedCategoryId: String? = nil
    @State private var setBudgetInitialMode: SetBudgetView.BudgetEditMode = .focus
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                if let summary = viewModel.summary {
                    ScrollView {
                        VStack(spacing: 20) {
                            monthNavigatorBar
                            
                            if viewModel.summary?.isSettled == true {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Settled Month (Locked)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(FinPilotColors.textPrimary)
                                        Text("This month has been settled. Budget allocations cannot be altered.")
                                            .font(.system(size: 11))
                                            .foregroundColor(FinPilotColors.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                            
                            donutChartSection(summary: summary)
                            categoryListSection(summary: summary)
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.fetchBudgets()
                    }
                } else {
                    VStack {
                        Text("No Budget Data")
                            .font(FinPilotTypography.headline)
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Budgets")
                        .font(FinPilotTypography.title3)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.summary?.isSettled == true {
                        Image(systemName: "lock.fill")
                            .foregroundColor(FinPilotColors.textSecondary)
                            .padding(4)
                    } else {
                        Button(action: {
                            selectedCategoryId = nil
                            setBudgetInitialMode = .focus
                            showingSetBudget = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(FinPilotColors.primary)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchBudgets()
            }
            .sheet(isPresented: $showingSetBudget) {
                SetBudgetView(
                    viewModel: viewModel,
                    initialCategoryId: selectedCategoryId,
                    initialMode: setBudgetInitialMode,
                    isMonthSettled: viewModel.summary?.isSettled == true
                )
                .id("\(selectedCategoryId ?? "none")-\(setBudgetInitialMode.rawValue)")
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSetBudget)) { notif in
                selectedCategoryId = nil
                if let modeStr = notif.object as? String, modeStr == "all" {
                    setBudgetInitialMode = .all
                } else {
                    setBudgetInitialMode = .focus
                }
                showingSetBudget = true
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Syncing Budgets...")
    }
    
    private var monthNavigatorBar: some View {
        HStack {
            Button(action: {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.selectedMonth) {
                    viewModel.selectedMonth = prev
                    Task {
                        await viewModel.fetchBudgets()
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FinPilotColors.primary)
                    .frame(width: 34, height: 34)
                    .background(FinPilotColors.surface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FinPilotColors.primary)
                Text(monthDisplayString(viewModel.selectedMonth))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(FinPilotColors.surface)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            Button(action: {
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: viewModel.selectedMonth) {
                    viewModel.selectedMonth = next
                    Task {
                        await viewModel.fetchBudgets()
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FinPilotColors.primary)
                    .frame(width: 34, height: 34)
                    .background(FinPilotColors.surface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func monthDisplayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: date)
    }
    
    @ViewBuilder
    private func donutChartSection(summary: BudgetSummaryResponse) -> some View {
        VStack(spacing: 16) {
            // Card Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(FinPilotColors.primary.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 16))
                            .foregroundColor(FinPilotColors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Budget Overview")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text(summary.totalBudget > 0 ? "Tracking real-time burn rate & allocation" : "No budget set for \(monthDisplayString(viewModel.selectedMonth))")
                            .font(.system(size: 12))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                
                Spacer()
                
                budgetStatusPill(for: summary)
            }
            .padding(.horizontal, 4)
            
            Divider()
                .background(FinPilotColors.divider.opacity(0.6))
            
            // Donut Chart Graphic
            ZStack {
                // Outer Subtle Concentric Outline
                Circle()
                    .stroke(FinPilotColors.divider.opacity(0.35), lineWidth: 1)
                    .frame(width: 224, height: 224)
                
                // Visible Background Track (Fixed so it is never invisible)
                Circle()
                    .stroke(
                        FinPilotColors.border.opacity(0.85),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 190, height: 190)
                
                if summary.totalBudget > 0 {
                    let usageFraction = max(0.0, min(abs(summary.overallUsagePercentage) / 100.0, 1.0))
                    // Progress Arc with Gradient
                    Circle()
                        .trim(from: 0.0, to: CGFloat(usageFraction))
                        .stroke(
                            LinearGradient(
                                colors: ringGradientColors(for: abs(summary.overallUsagePercentage)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                        )
                        .rotationEffect(Angle(degrees: -90.0))
                        .frame(width: 190, height: 190)
                        .shadow(color: statusColor(for: abs(summary.overallUsagePercentage)).opacity(0.28), radius: 6, x: 0, y: 3)
                        .animation(.easeInOut(duration: 0.4), value: summary.overallUsagePercentage)
                } else {
                    // Empty placeholder dashed indicator
                    Circle()
                        .stroke(
                            FinPilotColors.primary.opacity(0.25),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 6])
                        )
                        .frame(width: 190, height: 190)
                }
                
                // Inner Subtle Concentric Ring
                Circle()
                    .stroke(FinPilotColors.divider.opacity(0.25), lineWidth: 1)
                    .frame(width: 154, height: 154)
                
                // Center Metrics Content
                if summary.totalBudget > 0 {
                    VStack(spacing: 3) {
                        Text("TOTAL SPENT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(0.8)
                        
                        Text(String(format: "₹ %.0f", abs(summary.totalSpent)))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text(String(format: "of ₹ %.0f planned", summary.totalBudget))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                        
                        Text(String(format: "%.1f%% used", abs(summary.overallUsagePercentage)))
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(statusColor(for: abs(summary.overallUsagePercentage)))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(statusColor(for: abs(summary.overallUsagePercentage)).opacity(0.12))
                            .cornerRadius(4)
                            .padding(.top, 2)
                    }
                } else {
                    Button(action: {
                        selectedCategoryId = nil
                        setBudgetInitialMode = .all
                        showingSetBudget = true
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(FinPilotColors.primary.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(FinPilotColors.primary)
                            }
                            
                            Text("Set Budget")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(FinPilotColors.textPrimary)
                            
                            Text("Tap to allocate")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: 224, height: 224)
            .padding(.vertical, 10)
            
            // 2x2 Metrics Overview Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricTile(
                    icon: "wallet.pass.fill",
                    iconColor: summary.remainingBudget >= 0 ? FinPilotColors.primary : FinPilotColors.error,
                    title: "Remaining",
                    value: String(format: "₹ %.0f", summary.remainingBudget),
                    subtitle: summary.remainingBudget >= 0 ? "Under budget" : "Over budget"
                )
                
                metricTile(
                    icon: "target",
                    iconColor: Color(hex: "#0EA5E9"),
                    title: "Total Budget",
                    value: String(format: "₹ %.0f", summary.totalBudget),
                    subtitle: "Planned allocation"
                )
                
                metricTile(
                    icon: "calendar.badge.clock",
                    iconColor: Color(hex: "#8B5CF6"),
                    title: "Daily Safe Spend",
                    value: String(format: "₹ %.0f/d", dailySafeSpend(summary: summary)),
                    subtitle: "\(daysRemainingInMonth()) days left"
                )
                
                metricTile(
                    icon: "speedometer",
                    iconColor: statusColor(for: abs(summary.overallUsagePercentage)),
                    title: "Usage Pace",
                    value: String(format: "%.1f%%", abs(summary.overallUsagePercentage)),
                    subtitle: paceDescription(for: summary)
                )
            }
            .padding(.top, 4)
            
            // If totalBudget == 0, show CTA button
            if summary.totalBudget == 0 {
                Button(action: {
                    selectedCategoryId = nil
                    setBudgetInitialMode = .all
                    showingSetBudget = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Set Budget for \(monthDisplayString(viewModel.selectedMonth))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [FinPilotColors.primary, FinPilotColors.primaryDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(FinPilotColors.surface)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(FinPilotColors.border.opacity(0.7), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Metric Tile Component
    private func metricTile(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FinPilotColors.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(FinPilotColors.textSecondary.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(FinPilotColors.background)
        .cornerRadius(12)
    }
    
    // MARK: - Budget Status Pill
    @ViewBuilder
    private func budgetStatusPill(for summary: BudgetSummaryResponse) -> some View {
        let usage = abs(summary.overallUsagePercentage)
        if summary.totalBudget <= 0 {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 9))
                Text("NOT SET")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(FinPilotColors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FinPilotColors.primary.opacity(0.12))
            .cornerRadius(6)
        } else if usage > 100 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                Text("OVER BUDGET")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(FinPilotColors.error)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FinPilotColors.error.opacity(0.12))
            .cornerRadius(6)
        } else if usage >= 90 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 9))
                Text("CRITICAL")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(FinPilotColors.critical)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FinPilotColors.critical.opacity(0.12))
            .cornerRadius(6)
        } else if usage >= 70 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 9))
                Text("70%+ USED")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(FinPilotColors.warning)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FinPilotColors.warning.opacity(0.12))
            .cornerRadius(6)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 9))
                Text("ON TRACK")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(FinPilotColors.success)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FinPilotColors.success.opacity(0.12))
            .cornerRadius(6)
        }
    }
    
    // MARK: - Daily Safe Spend Calculation
    private func dailySafeSpend(summary: BudgetSummaryResponse) -> Double {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: viewModel.selectedMonth) ?? 1..<31
        let totalDays = range.count
        let currentDay = calendar.component(.day, from: Date())
        let isCurrentMonth = calendar.isDate(viewModel.selectedMonth, equalTo: Date(), toGranularity: .month)
        let daysLeft = isCurrentMonth ? max(1, totalDays - currentDay + 1) : totalDays
        
        let remaining = max(0, summary.remainingBudget)
        return remaining / Double(daysLeft)
    }
    
    private func daysRemainingInMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: viewModel.selectedMonth) ?? 1..<31
        let totalDays = range.count
        let currentDay = calendar.component(.day, from: Date())
        let isCurrentMonth = calendar.isDate(viewModel.selectedMonth, equalTo: Date(), toGranularity: .month)
        return isCurrentMonth ? max(1, totalDays - currentDay + 1) : totalDays
    }
    
    private func paceDescription(for summary: BudgetSummaryResponse) -> String {
        if summary.totalBudget <= 0 { return "No limits" }
        if summary.overallUsagePercentage > 100 { return "Exceeded limit" }
        if summary.overallUsagePercentage >= 90 { return "High velocity" }
        if summary.overallUsagePercentage >= 70 { return "Moderate spend" }
        return "Optimal burn"
    }
    
    private func ringGradientColors(for percentage: Double) -> [Color] {
        if percentage >= 100 {
            return [FinPilotColors.error, Color(hex: "#B91C1C")]
        } else if percentage >= 90 {
            return [FinPilotColors.critical, Color(hex: "#C2410C")]
        } else if percentage >= 70 {
            return [FinPilotColors.warning, Color(hex: "#D97706")]
        } else {
            return [FinPilotColors.primaryLight, FinPilotColors.primary]
        }
    }
    
    @ViewBuilder
    private func categoryListSection(summary: BudgetSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Category Allocations")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Spacer()
                
                Text("\(summary.budgets.count) \(summary.budgets.count == 1 ? "category" : "categories")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            .padding(.horizontal, 20)
            
            if summary.budgets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 28))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                    Text("No category budgets configured yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("Tap + in the top bar to set specific category limits")
                        .font(.system(size: 12))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(FinPilotColors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FinPilotColors.border.opacity(0.6), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(summary.budgets) { budget in
                        let category = viewModel.categories.first(where: { $0.id == budget.categoryId })
                        Button(action: {
                            selectedCategoryId = budget.categoryId
                            setBudgetInitialMode = .focus
                            showingSetBudget = true
                        }) {
                            BudgetCategoryRow(budget: budget, category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func statusColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<70:
            return FinPilotColors.success
        case 70..<90:
            return FinPilotColors.warning
        case 90...100:
            return FinPilotColors.critical
        default:
            return FinPilotColors.error
        }
    }
}

struct BudgetCategoryRow: View {
    let budget: Budget
    let category: Category?
    
    private var statusColor: Color {
        switch budget.usagePercentage {
        case 0..<70:
            return FinPilotColors.success
        case 70..<90:
            return FinPilotColors.warning
        case 90...100:
            return FinPilotColors.critical
        default:
            return FinPilotColors.error
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: category?.icon ?? "creditcard.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(category?.name ?? "General")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        
                        Text(String(format: "%.0f%%", abs(budget.usagePercentage)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.12))
                            .cornerRadius(4)
                    }
                    
                    Text("Budget: ₹ \(String(format: "%.0f", budget.amount))")
                        .font(.system(size: 12))
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "₹ %.0f", abs(budget.spent)))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.textPrimary)
                    
                    Text(budget.remaining >= 0 ? "Left ₹ \(String(format: "%.0f", budget.remaining))" : "Over by ₹ \(String(format: "%.0f", abs(budget.remaining)))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(budget.remaining >= 0 ? FinPilotColors.textSecondary : FinPilotColors.error)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FinPilotColors.textSecondary.opacity(0.4))
            }
            
            // Refined Multi-Layer Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FinPilotColors.border.opacity(0.7))
                        .frame(height: 7)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [statusColor.opacity(0.8), statusColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geometry.size.width * CGFloat(abs(budget.usagePercentage) / 100.0), geometry.size.width)), height: 7)
                }
            }
            .frame(height: 7)
        }
        .padding(14)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FinPilotColors.border.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct SetBudgetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BudgetsViewModel
    let initialCategoryId: String?
    let initialMode: BudgetEditMode
    let isMonthSettled: Bool
    
    enum BudgetEditMode: String, CaseIterable, Identifiable {
        case focus = "Focus Budget"
        case all = "All Categories"
        var id: String { rawValue }
    }
    
    enum BudgetAllocationScope: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case upcomingMonths = "Upcoming"
        case entireYear = "All Year"
        var id: String { rawValue }
    }
    
    @State private var mode: BudgetEditMode
    @State private var selectedCategoryId: String = ""
    @State private var budgetAmounts: [String: String] = [:]
    @State private var sliderValue: Double = 0
    @State private var isSaving = false
    @State private var allocationScope: BudgetAllocationScope = .upcomingMonths
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    init(viewModel: BudgetsViewModel, initialCategoryId: String? = nil, initialMode: BudgetEditMode = .focus, isMonthSettled: Bool = false) {
        self.viewModel = viewModel
        self.initialCategoryId = initialCategoryId
        self.initialMode = initialMode
        self.isMonthSettled = isMonthSettled
        self._mode = State(initialValue: initialMode)
    }
    
    var expenseCategories: [Category] {
        viewModel.categories.filter { $0.type.lowercased() == "expense" }
    }
    
    var activeCategory: Category? {
        expenseCategories.first(where: { $0.id == selectedCategoryId }) ?? expenseCategories.first
    }
    
    var activeCategoryBudget: Budget? {
        guard let cat = activeCategory else { return nil }
        return viewModel.summary?.budgets.first(where: { $0.categoryId == cat.id })
    }
    
    var activeCurrentSpent: Double {
        activeCategoryBudget?.spent ?? 0
    }
    
    var activeProposedAmount: Double {
        guard let cat = activeCategory else { return 0 }
        let raw = budgetAmounts[cat.id] ?? "0"
        return Double(raw.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    var activeCategoryColor: Color {
        if let hex = activeCategory?.color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return FinPilotColors.primary
    }
    
    var totalAllocatedBudget: Double {
        var total = 0.0
        for cat in expenseCategories {
            let str = budgetAmounts[cat.id] ?? "0"
            total += Double(str.replacingOccurrences(of: ",", with: "")) ?? 0
        }
        return total
    }
    
    var totalCurrentSpent: Double {
        viewModel.summary?.totalSpent ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FinPilotColors.background.ignoresSafeArea()
                
                if expenseCategories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 48))
                            .foregroundColor(FinPilotColors.textSecondary.opacity(0.5))
                        Text("No Expense Categories")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(FinPilotColors.textPrimary)
                        Text("Create expense categories in Profile before setting budgets.")
                            .font(.system(size: 14))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if isMonthSettled {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(FinPilotColors.error)
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Month Settled & Locked")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(FinPilotColors.error)
                                        Text("This month has already been settled. You cannot create or modify budgets for a settled month.")
                                            .font(.system(size: 11))
                                            .foregroundColor(FinPilotColors.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(FinPilotColors.error.opacity(0.12))
                                .cornerRadius(14)
                                .padding(.horizontal, 18)
                                .padding(.top, 4)
                            }
                            
                            // Mode Switcher Pills
                            HStack(spacing: 8) {
                                ForEach(BudgetEditMode.allCases) { m in
                                    let isSelected = mode == m
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            mode = m
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: m == .focus ? "slider.horizontal.3" : "list.bullet.rectangle.portrait.fill")
                                                .font(.system(size: 12, weight: .bold))
                                            Text(m.rawValue)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? FinPilotColors.primary : FinPilotColors.surface)
                                        .foregroundColor(isSelected ? .white : FinPilotColors.textSecondary)
                                        .cornerRadius(12)
                                        .shadow(color: isSelected ? FinPilotColors.primary.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                            
                            allocationScopeCard
                            
                            if mode == .focus {
                                focusModeView
                            } else {
                                allCategoriesView
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Set Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(FinPilotColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !expenseCategories.isEmpty {
                        Button("Reset All") {
                            for cat in expenseCategories {
                                budgetAmounts[cat.id] = ""
                            }
                            sliderValue = 0
                            let gen = UINotificationFeedbackGenerator()
                            gen.notificationOccurred(.warning)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FinPilotColors.error)
                    }
                }
            }
            .onAppear {
                mode = initialMode
                initializeBudgets()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSetBudget)) { notif in
                if let modeStr = notif.object as? String, modeStr == "all" {
                    withAnimation {
                        mode = .all
                    }
                } else if let modeStr = notif.object as? String, modeStr == "focus" {
                    withAnimation {
                        mode = .focus
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Focus Mode View
    @ViewBuilder
    private var focusModeView: some View {
        VStack(spacing: 18) {
            // Horizontal Category Selector Chips
            VStack(alignment: .leading, spacing: 10) {
                Text("SELECT CATEGORY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(1.0)
                    .padding(.horizontal, 22)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(expenseCategories, id: \.id) { cat in
                            let isSelected = cat.id == selectedCategoryId
                            let catColor = cat.color != nil ? Color(hex: cat.color!) : FinPilotColors.primary
                            let hasBudget = (Double(budgetAmounts[cat.id]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0) > 0
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategoryId = cat.id
                                    let currentVal = Double(budgetAmounts[cat.id]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
                                    sliderValue = min(currentVal, 50000)
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.icon ?? "creditcard.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSelected ? .white : catColor)
                                    
                                    Text(cat.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                                    
                                    if hasBudget {
                                        Circle()
                                            .fill(isSelected ? .white : catColor)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(isSelected ? catColor : FinPilotColors.surface)
                                .foregroundColor(isSelected ? .white : FinPilotColors.textPrimary)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isSelected ? catColor : Color.black.opacity(0.06), lineWidth: 1)
                                )
                                .shadow(color: isSelected ? catColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            
            if let cat = activeCategory {
                // Hero Budget Card
                VStack(spacing: 16) {
                    // Category icon & name header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(activeCategoryColor.opacity(0.18))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Circle()
                                        .stroke(activeCategoryColor.opacity(0.3), lineWidth: 1.5)
                                )
                            Image(systemName: cat.icon ?? "creditcard.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(activeCategoryColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(cat.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                            Text("Monthly Budget Limit")
                                .font(.system(size: 12))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Large Amount Display & Input
                    VStack(spacing: 6) {
                        Text("TARGET AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(0.8)
                        
                        HStack(alignment: .center, spacing: 6) {
                            Text("₹")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(activeCategoryColor)
                            
                            TextField("0", text: Binding(
                                get: { budgetAmounts[cat.id] ?? "" },
                                set: { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    budgetAmounts[cat.id] = filtered
                                    if let num = Double(filtered) {
                                        sliderValue = min(num, 50000)
                                    } else {
                                        sliderValue = 0
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 120, maxWidth: 220)
                            
                            if !((budgetAmounts[cat.id] ?? "").isEmpty) {
                                Button(action: {
                                    budgetAmounts[cat.id] = ""
                                    sliderValue = 0
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.6))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(FinPilotColors.background)
                        .cornerRadius(16)
                    }
                    
                    // Quick Increments Pills
                    HStack(spacing: 8) {
                        ForEach([500, 1000, 2000, 5000], id: \.self) { increment in
                            Button(action: {
                                let current = Double(budgetAmounts[cat.id] ?? "0") ?? 0
                                let nextVal = current + Double(increment)
                                budgetAmounts[cat.id] = String(Int(nextVal))
                                sliderValue = min(nextVal, 50000)
                                let gen = UIImpactFeedbackGenerator(style: .light)
                                gen.impactOccurred()
                            }) {
                                Text("+₹\(increment >= 1000 ? "\(increment/1000)k" : "\(increment)")")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(activeCategoryColor.opacity(0.12))
                                    .foregroundColor(activeCategoryColor)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Slide to adjust")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Spacer()
                            Text("Max ₹50,000")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        
                        Slider(value: $sliderValue, in: 0...50000, step: 500)
                        .tint(activeCategoryColor)
                        .onChange(of: sliderValue) { newVal in
                            budgetAmounts[cat.id] = String(Int(newVal))
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(FinPilotColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(activeCategoryColor.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 18)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
                
                // Real-time Spending Calibration Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(activeCategoryColor)
                        Text("SPENDING INSIGHT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(0.8)
                        Spacer()
                        Text("Current Month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Spent so far")
                                .font(.system(size: 11))
                                .foregroundColor(FinPilotColors.textSecondary)
                            Text(String(format: "₹ %.0f", activeCurrentSpent))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Proposed Buffer")
                                .font(.system(size: 11))
                                .foregroundColor(FinPilotColors.textSecondary)
                            let diff = activeProposedAmount - activeCurrentSpent
                            Text(String(format: "₹ %.0f", diff))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(diff >= 0 ? FinPilotColors.success : FinPilotColors.error)
                        }
                    }
                    
                    // Usage Simulation Progress Bar
                    if activeProposedAmount > 0 {
                        let pct = min((activeCurrentSpent / activeProposedAmount) * 100.0, 150.0)
                        let isOver = activeCurrentSpent > activeProposedAmount
                        
                        VStack(alignment: .leading, spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(FinPilotColors.background)
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(isOver ? FinPilotColors.error : (pct > 80 ? FinPilotColors.warning : activeCategoryColor))
                                        .frame(width: max(0, min(geo.size.width * CGFloat(pct / 100.0), geo.size.width)), height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            HStack {
                                Text(isOver ? "⚠️ Current spending already exceeds this budget!" : "Projected usage: \(String(format: "%.0f%%", pct))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(isOver ? FinPilotColors.error : FinPilotColors.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    
                    // Smart Presets
                    if activeCurrentSpent > 0 {
                        HStack(spacing: 8) {
                            Button(action: {
                                let rounded = ceil(activeCurrentSpent * 1.2 / 500) * 500
                                budgetAmounts[cat.id] = String(Int(rounded))
                                sliderValue = min(rounded, 50000)
                                let gen = UIImpactFeedbackGenerator(style: .medium)
                                gen.impactOccurred()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11))
                                    Text("Spend + 20% (₹\(Int(ceil(activeCurrentSpent * 1.2 / 500) * 500)))")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(activeCategoryColor.opacity(0.12))
                                .foregroundColor(activeCategoryColor)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(18)
                .background(FinPilotColors.surface)
                .cornerRadius(20)
                .padding(.horizontal, 18)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                
                // Save Button for Active Category
                Button(action: {
                    saveSingleCategoryBudget(categoryId: cat.id)
                }) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                            Text("Saving...")
                                .font(.system(size: 16, weight: .bold))
                        } else if isMonthSettled {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Month Settled (Locked)")
                                .font(.system(size: 16, weight: .bold))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Save \(cat.name) Budget")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        isMonthSettled ? AnyView(Color.gray) :
                        AnyView(LinearGradient(
                            colors: [activeCategoryColor, activeCategoryColor.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .cornerRadius(18)
                    .shadow(color: isMonthSettled ? .clear : activeCategoryColor.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .disabled(isSaving || isMonthSettled)
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - All Categories Mode View
    @ViewBuilder
    private var allCategoriesView: some View {
        VStack(spacing: 18) {
            // Consolidated Total Monthly Allocation Card
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TOTAL MONTHLY BUDGET")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(0.8)
                        Text(String(format: "₹ %.0f", totalAllocatedBudget))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("SPENT SO FAR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .tracking(0.8)
                        Text(String(format: "₹ %.0f", totalCurrentSpent))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                    }
                }
                
                if totalAllocatedBudget > 0 {
                    let totalPct = min((totalCurrentSpent / totalAllocatedBudget) * 100.0, 100.0)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(FinPilotColors.background)
                                .frame(height: 8)
                            Capsule()
                                .fill(totalCurrentSpent > totalAllocatedBudget ? FinPilotColors.error : FinPilotColors.primary)
                                .frame(width: max(0, min(geo.size.width * CGFloat(totalPct / 100.0), geo.size.width)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FinPilotColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FinPilotColors.primary.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 18)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            
            // Per Category List Cards
            VStack(spacing: 12) {
                ForEach(expenseCategories, id: \.id) { cat in
                    let catColor = cat.color != nil ? Color(hex: cat.color!) : FinPilotColors.primary
                    let catSpent = viewModel.summary?.budgets.first(where: { $0.categoryId == cat.id })?.spent ?? 0
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(catColor.opacity(0.16))
                                .frame(width: 44, height: 44)
                            Image(systemName: cat.icon ?? "creditcard.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(catColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(cat.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(FinPilotColors.textPrimary)
                            Text("Spent: ₹\(Int(catSpent))")
                                .font(.system(size: 12))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("₹")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(catColor)
                            
                            TextField("0", text: Binding(
                                get: { budgetAmounts[cat.id] ?? "" },
                                set: { budgetAmounts[cat.id] = $0.filter { "0123456789".contains($0) } }
                            ))
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(FinPilotColors.background)
                            .cornerRadius(10)
                        }
                    }
                    .padding(14)
                    .background(FinPilotColors.surface)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 18)
            
            // Bulk Save Action
            Button(action: saveBulkBudgets) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                        Text("Saving Budgets...")
                            .font(.system(size: 16, weight: .bold))
                    } else if isMonthSettled {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Month Settled (Locked)")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Save All Budgets")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    isMonthSettled ? AnyView(Color.gray) :
                    AnyView(LinearGradient(
                        colors: [FinPilotColors.primary, FinPilotColors.primary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                )
                .cornerRadius(18)
                .shadow(color: isMonthSettled ? .clear : FinPilotColors.primary.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .disabled(isSaving || isMonthSettled)
            .padding(.horizontal, 18)
            .padding(.top, 4)
        }
    }
    
    private func initializeBudgets() {
        for cat in expenseCategories {
            if let existingBudget = viewModel.summary?.budgets.first(where: { $0.categoryId == cat.id }) {
                budgetAmounts[cat.id] = String(Int(existingBudget.amount))
            } else {
                budgetAmounts[cat.id] = ""
            }
        }
        
        if let initId = initialCategoryId, expenseCategories.contains(where: { $0.id == initId }) {
            selectedCategoryId = initId
            let val = Double(budgetAmounts[initId]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            sliderValue = min(val, 50000)
        } else if let first = expenseCategories.first {
            selectedCategoryId = first.id
            let val = Double(budgetAmounts[first.id]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0
            sliderValue = min(val, 50000)
        }
    }
    
    private var allocationScopeCard: some View {
        let currentYear = Calendar.current.component(.year, from: viewModel.selectedMonth)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(FinPilotColors.primary)
                    .font(.system(size: 15, weight: .semibold))
                Text("BUDGET ALLOCATION SCOPE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(0.8)
                Spacer()
            }
            
            Picker("Scope", selection: $allocationScope) {
                ForEach(BudgetAllocationScope.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(FinPilotColors.textSecondary)
                Text(scopeDescription(year: currentYear))
                    .font(.system(size: 11))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .padding(14)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 18)
    }
    
    private func scopeDescription(year: Int) -> String {
        switch allocationScope {
        case .thisMonth:
            return "Applies only to \(monthTitleString(viewModel.selectedMonth))"
        case .upcomingMonths:
            return "Applies to \(monthTitleString(viewModel.selectedMonth)) and all upcoming months of \(String(year))"
        case .entireYear:
            return "Applies to all 12 months (Jan - Dec) of \(String(year))"
        }
    }
    
    private func monthTitleString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: date)
    }
    
    private func saveSingleCategoryBudget(categoryId: String) {
        if isMonthSettled {
            errorMessage = "This month has already been settled and locked."
            showErrorAlert = true
            return
        }
        isSaving = true
        let amtString = budgetAmounts[categoryId] ?? "0"
        let amt = Double(amtString.replacingOccurrences(of: ",", with: "")) ?? 0
        let yearNum = Calendar.current.component(.year, from: viewModel.selectedMonth)
        let isUpcoming = allocationScope == .upcomingMonths
        let isYear = allocationScope == .entireYear
        
        Task {
            await viewModel.setBudget(
                categoryId: categoryId,
                amount: amt,
                monthStr: viewModel.selectedMonthString,
                applyToYear: isYear,
                applyToUpcomingMonths: isUpcoming,
                year: yearNum
            )
            await MainActor.run {
                isSaving = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func saveBulkBudgets() {
        if isMonthSettled {
            errorMessage = "This month has already been settled and locked."
            showErrorAlert = true
            return
        }
        isSaving = true
        var bulkData: [[String: Any]] = []
        for cat in expenseCategories {
            let amtString = budgetAmounts[cat.id] ?? ""
            if let amt = Double(amtString.replacingOccurrences(of: ",", with: "")) {
                bulkData.append(["category_id": cat.id, "amount": amt])
            } else {
                bulkData.append(["category_id": cat.id, "amount": 0.0])
            }
        }
        let yearNum = Calendar.current.component(.year, from: viewModel.selectedMonth)
        let isUpcoming = allocationScope == .upcomingMonths
        let isYear = allocationScope == .entireYear
        
        Task {
            await viewModel.setBulkBudgets(
                budgets: bulkData,
                monthStr: viewModel.selectedMonthString,
                applyToYear: isYear,
                applyToUpcomingMonths: isUpcoming,
                year: yearNum
            )
            await MainActor.run {
                isSaving = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
