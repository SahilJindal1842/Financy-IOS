import SwiftUI

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var insights: [Insight] = []
    @Published var dailySpending: [DailySpending] = []
    @Published var topCategories: [TopSpendingCategory] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        
        async let fetchInsights: [Insight]? = try? APIManager.shared.request(endpoint: "/insights")
        async let fetchDaily: [DailySpending]? = try? APIManager.shared.request(endpoint: "/reports/daily-spending")
        async let fetchTop: [TopSpendingCategory]? = try? APIManager.shared.request(endpoint: "/reports/top-spending")
        
        let (fetchedInsights, fetchedDaily, fetchedTop) = await (fetchInsights, fetchDaily, fetchTop)
        
        if let insights = fetchedInsights {
            self.insights = insights
        } else {
            // Fallback for insights
            self.insights = [
                Insight(type: "warning", message: "Shopping has used 92% of its budget"),
                Insight(type: "suggestion", message: "You could save $50 by cutting back on subscriptions."),
                Insight(type: "celebration", message: "You stayed under your groceries budget this week!")
            ]
        }
        
        if let daily = fetchedDaily {
            self.dailySpending = daily
        } else {
            // Fallback for daily
            self.dailySpending = [
                DailySpending(date: "2023-10-01", totalSpent: 45.0),
                DailySpending(date: "2023-10-02", totalSpent: 12.0),
                DailySpending(date: "2023-10-03", totalSpent: 80.0),
                DailySpending(date: "2023-10-04", totalSpent: 15.0),
                DailySpending(date: "2023-10-05", totalSpent: 5.0)
            ]
        }
        
        if let top = fetchedTop {
            self.topCategories = top
        } else {
            // Fallback for top categories
            self.topCategories = [
                TopSpendingCategory(categoryId: "1", categoryName: "Food", totalSpent: 120.0),
                TopSpendingCategory(categoryId: "2", categoryName: "Transport", totalSpent: 45.0),
                TopSpendingCategory(categoryId: "3", categoryName: "Shopping", totalSpent: 200.0)
            ]
        }
        
        isLoading = false
    }
}
