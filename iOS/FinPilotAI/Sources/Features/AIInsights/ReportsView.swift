import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if true {
                        insightsSection
                        dailySpendingChart
                        topCategoriesChart
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
            .background(FinPilotColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reports & Insights")
                        .font(FinPilotTypography.title3)
                        .foregroundColor(FinPilotColors.textPrimary)
                }
            }
            .task {
                await viewModel.fetchAllData()
            }
            .refreshable {
                await viewModel.fetchAllData()
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Analyzing Data...")
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            ForEach(viewModel.insights) { insight in
                insightCard(for: insight)
            }
        }
    }
    
    private func insightCard(for insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconForInsight(insight.type))
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(colorForInsight(insight.type))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(titleForInsight(insight.type))
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text(insight.message)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func iconForInsight(_ type: String) -> String {
        switch type.lowercased() {
        case "warning": return "exclamationmark.triangle.fill"
        case "celebration": return "party.popper.fill"
        case "suggestion": return "lightbulb.fill"
        default: return "sparkles"
        }
    }
    
    private func colorForInsight(_ type: String) -> Color {
        switch type.lowercased() {
        case "warning": return .red
        case "celebration": return .green
        case "suggestion": return .orange
        default: return FinPilotColors.primary
        }
    }
    
    private func titleForInsight(_ type: String) -> String {
        switch type.lowercased() {
        case "warning": return "Alert"
        case "celebration": return "Great Job!"
        case "suggestion": return "Suggestion"
        default: return "Insight"
        }
    }
    
    private var dailySpendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Spending")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            if viewModel.dailySpending.isEmpty {
                Text("No data available.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
            } else {
                Chart {
                    ForEach(viewModel.dailySpending) { data in
                        BarMark(
                            x: .value("Date", data.date),
                            y: .value("Spent", data.totalSpent)
                        )
                        .foregroundStyle(FinPilotColors.primary)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var topCategoriesChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Categories")
                .font(FinPilotTypography.title3)
                .foregroundColor(FinPilotColors.textPrimary)
            
            if viewModel.topCategories.isEmpty {
                Text("No data available.")
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textSecondary)
            } else {
                Chart(viewModel.topCategories) { category in
                    SectorMark(
                        angle: .value("Spent", category.totalSpent),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Category", category.categoryName))
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            }
        }
    }
}
