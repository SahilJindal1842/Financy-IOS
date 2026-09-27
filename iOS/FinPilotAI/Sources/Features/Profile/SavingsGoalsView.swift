import SwiftUI

struct SavingsGoalsView: View {
    @State private var goals: [SavingsGoal] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if goals.isEmpty {
                    Text("No savings goals found.")
                        .foregroundColor(FinPilotColors.textSecondary)
                        .padding()
                } else {
                    ForEach(goals) { goal in
                        GoalCard(goal: goal)
                    }
                }
            }
            .padding()
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .navigationTitle("Savings Goals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchGoals()
        }
        .refreshable {
            await fetchGoals()
        }
        .loadingOverlay(isLoading: isLoading, message: "Syncing Goals...")
    }
    
    private func fetchGoals() async {
        isLoading = true
        do {
            let fetchedGoals: [SavingsGoal] = try await APIManager.shared.request(endpoint: "/savings-goals")
            goals = fetchedGoals
        } catch {
            print("Failed to load goals: \(error)")
        }
        isLoading = false
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
                Text("₹\(Int(goal.currentAmount))")
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
                Spacer()
                Text("Target: ₹\(Int(goal.targetAmount))")
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
