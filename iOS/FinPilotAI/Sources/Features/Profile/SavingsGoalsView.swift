import SwiftUI

struct SavingsModuleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Admin user-wise filtering
    @State private var adminUsers: [AdminUser] = []
    @State private var selectedAdminUserId: String = "all"
    @State private var selectedAdminUserName: String = "All Users"
    
    @State private var totalAccumulatedSavings: Double = 0.0
    @State private var history: [MonthlySavingsRecord] = []
    @State private var goals: [SavingsGoal] = []
    @State private var isLoading = false
    @State private var selectedTab = "History" // "History" or "Goals"
    @State private var showingNewGoalSheet = false
    @State private var newGoalName = ""
    @State private var newGoalTarget = ""
    
    var body: some View {
        ZStack {
            FinPilotColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if authViewModel.currentUser?.role?.uppercased() == "ADMIN" {
                        adminUserSelectorView
                    }
                    
                    heroSavingsCard
                    
                    // Segmented Filter
                    HStack(spacing: 8) {
                        tabButton(title: "Monthly Savings", tag: "History", icon: "calendar.badge.clock")
                        tabButton(title: "Savings Goals", tag: "Goals", icon: "target")
                    }
                    .padding(.horizontal, 20)
                    
                    if selectedTab == "History" {
                        monthlyHistorySection
                    } else {
                        savingsGoalsSection
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Savings Module")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab == "Goals" {
                    Button(action: { showingNewGoalSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(FinPilotColors.primary)
                    }
                }
            }
        }
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
        .loadingOverlay(isLoading: isLoading, message: "Syncing Savings...")
        .sheet(isPresented: $showingNewGoalSheet) {
            newGoalModal
        }
    }
    
    // MARK: - Admin User Selector View
    private var adminUserSelectorView: some View {
        HStack(spacing: 10) {
            Menu {
                Button(action: {
                    selectedAdminUserId = "all"
                    selectedAdminUserName = "All Users"
                    Task { await loadData() }
                }) {
                    HStack {
                        Text("🌐 All Users (Consolidated)")
                        if selectedAdminUserId == "all" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                ForEach(adminUsers) { user in
                    Button(action: {
                        selectedAdminUserId = user.id
                        selectedAdminUserName = user.name
                        Task { await loadData() }
                    }) {
                        HStack {
                            Text("\(user.name) (\(user.email))")
                            if selectedAdminUserId == user.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: selectedAdminUserId == "all" ? "globe.americas.fill" : "person.crop.circle.fill")
                        .foregroundColor(FinPilotColors.primary)
                        .font(.system(size: 15))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Filter by User (Admin)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(FinPilotColors.textSecondary)
                        Text(selectedAdminUserId == "all" ? "All Users" : selectedAdminUserName)
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
    }

    // MARK: - Hero Card
    private var heroSavingsCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#059669"), Color(hex: "#10B981"), Color(hex: "#34D399")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "#10B981").opacity(0.35), radius: 12, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        Text("SAVINGS MODULE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.0)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.role?.uppercased() == "ADMIN" && selectedAdminUserId != "all" 
                        ? "Total Savings for \(selectedAdminUserName)" 
                        : "Total Accumulated Savings")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(.white.opacity(0.85))
                    
                    Text("₹ \(formatSavingsAmount(totalAccumulatedSavings))")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("From monthly surpluses & settlements")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text("\(history.count) months settled")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(22)
        }
        .padding(.horizontal, 20)
    }
    
    private func tabButton(title: String, tag: String, icon: String) -> some View {
        let isSelected = selectedTab == tag
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
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
    
    // MARK: - Monthly History Section
    private var monthlyHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MONTHLY SURPLUS LOG")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(0.8)
                Spacer()
                Text("Auto-transferred at month end")
                    .font(.system(size: 11))
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            .padding(.horizontal, 22)
            
            if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 44))
                        .foregroundColor(FinPilotColors.textSecondary.opacity(0.4))
                    Text("No Settled Months Yet")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("When you press 'Settle Month' on the Dashboard at the end of the month date, all unspent earnings (Income − Expenses) will appear here as your monthly savings!")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(FinPilotColors.surface)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(history) { record in
                        MonthlySavingsCard(record: record)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Savings Goals Section
    private var savingsGoalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ACTIVE SAVINGS GOALS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .tracking(0.8)
                Spacer()
                Button(action: { showingNewGoalSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Goal")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.horizontal, 22)
            
            if goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(FinPilotColors.primary.opacity(0.6))
                    Text("No Savings Goals Configured")
                        .font(FinPilotTypography.headline)
                        .foregroundColor(FinPilotColors.textPrimary)
                    Text("Create a savings goal (e.g. Vacation, Car, Emergency Fund) to direct your monthly surplus.")
                        .font(FinPilotTypography.caption)
                        .foregroundColor(FinPilotColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(FinPilotColors.surface)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(goals) { goal in
                        GoalCard(goal: goal)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - New Goal Modal
    private var newGoalModal: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal Name (e.g. New Laptop, Vacation)", text: $newGoalName)
                    TextField("Target Amount (₹)", text: $newGoalTarget)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingNewGoalSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await createGoal()
                        }
                    }
                    .disabled(newGoalName.isEmpty || newGoalTarget.isEmpty)
                }
            }
        }
    }
    
    private func createGoal() async {
        guard let target = Double(newGoalTarget) else { return }
        do {
            var payload: [String: Any] = [
                "name": newGoalName,
                "target_amount": target,
                "current_amount": 0.0
            ]
            let isAdmin = authViewModel.currentUser?.role?.uppercased() == "ADMIN"
            if isAdmin && selectedAdminUserId != "all" && !selectedAdminUserId.isEmpty {
                payload["user_id"] = selectedAdminUserId
            }
            let data = try JSONSerialization.data(withJSONObject: payload)
            struct Res: Codable {}
            let _: Res = try await APIManager.shared.request(endpoint: "/savings-goals", method: "POST", body: data)
            showingNewGoalSheet = false
            newGoalName = ""
            newGoalTarget = ""
            await loadData()
        } catch {
            print("Failed to create goal: \(error)")
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        let isAdmin = authViewModel.currentUser?.role?.uppercased() == "ADMIN"
        if isAdmin && adminUsers.isEmpty {
            do {
                let fetchedUsers: [AdminUser] = try await APIManager.shared.request(endpoint: "/admin/users")
                self.adminUsers = fetchedUsers
            } catch {
                print("Failed to load admin users: \(error)")
            }
        }
        
        let userQuery = (isAdmin && selectedAdminUserId != "all" && !selectedAdminUserId.isEmpty) 
            ? "?user_id=\(selectedAdminUserId)" 
            : ""
        
        do {
            let histRes: SavingsHistoryResponse = try await APIManager.shared.request(endpoint: "/settlement/history\(userQuery)")
            self.history = histRes.history
            if histRes.totalAccumulatedSavings > 0 {
                self.totalAccumulatedSavings = histRes.totalAccumulatedSavings
            } else {
                self.totalAccumulatedSavings = histRes.history.reduce(0.0) { $0 + $1.savedAmount }
            }
        } catch {
            print("Failed to load savings history: \(error)")
        }
        
        do {
            let fetchedGoals: [SavingsGoal] = try await APIManager.shared.request(endpoint: "/savings-goals\(userQuery)")
            self.goals = fetchedGoals
        } catch {
            print("Failed to load savings goals: \(error)")
        }
        
        // Fallback: If totalAccumulatedSavings is still 0 but history has records, compute sum
        if self.totalAccumulatedSavings == 0 && !self.history.isEmpty {
            self.totalAccumulatedSavings = self.history.reduce(0.0) { $0 + $1.savedAmount }
        }
        
        isLoading = false
    }
}

func formatSavingsAmount(_ amt: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amt)) ?? "\(Int(amt))"
}

struct MonthlySavingsCard: View {
    let record: MonthlySavingsRecord
    
    var formattedMonthName: String {
        let parts = record.month.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else {
            return record.month
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        if let date = Calendar.current.date(from: comps) {
            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            return df.string(from: date)
        }
        return record.month
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // User header pill for Admin identification
            if let name = record.userName, !name.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FinPilotColors.primary)
                    Text(name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FinPilotColors.textPrimary)
                    if let email = record.userEmail, !email.isEmpty {
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

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedMonthName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FinPilotColors.textPrimary)
                    
                    Text("Settled & Transferred")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinPilotColors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("+₹\(formatSavingsAmount(record.savedAmount))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#059669"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "#059669").opacity(0.12))
                .cornerRadius(10)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget")
                        .font(.system(size: 11))
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("₹\(formatSavingsAmount(record.totalBudget))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Spent")
                        .font(.system(size: 11))
                        .foregroundColor(FinPilotColors.textSecondary)
                    Text("₹\(formatSavingsAmount(record.totalExpenses))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FinPilotColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Saved to Reserves")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#059669"))
                    Text("₹\(formatSavingsAmount(record.savedAmount))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#059669"))
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

struct SavingsGoalsView: View {
    @State private var goals: [SavingsGoal] = []
    @State private var isLoading = false
    
    var body: some View {
        SavingsModuleView()
    }
}

struct GoalCard: View {
    let goal: SavingsGoal
    
    var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let name = goal.userName, !name.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 11))
                    Text(name)
                        .font(.system(size: 11, weight: .bold))
                    if let email = goal.userEmail, !email.isEmpty {
                        Text("• \(email)")
                            .font(.system(size: 10))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                    Spacer()
                }
                .foregroundColor(FinPilotColors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FinPilotColors.primary.opacity(0.08))
                .cornerRadius(6)
            }
            
            HStack {
                Text(goal.name)
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.primary)
                    .bold()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 8)
                        .foregroundColor(FinPilotColors.surface)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("₹\(formatSavingsAmount(goal.currentAmount))")
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
                Spacer()
                Text("Target: ₹\(formatSavingsAmount(goal.targetAmount))")
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .padding(16)
        .background(FinPilotColors.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
