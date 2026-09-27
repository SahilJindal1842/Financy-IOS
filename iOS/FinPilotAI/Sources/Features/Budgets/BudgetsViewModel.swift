import SwiftUI

@MainActor
final class BudgetsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var summary: BudgetSummaryResponse?
    @Published var categories: [Category] = []
    @Published var errorMessage: String? = nil
    
    func fetchBudgets() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        async let summaryTask: BudgetSummaryResponse = try APIManager.shared.request(endpoint: "/budgets/summary")
        async let categoriesTask: [Category] = try APIManager.shared.request(endpoint: "/categories")
        
        do {
            summary = try await summaryTask
            let roots = try await categoriesTask
            var flatCategories: [Category] = []
            func flatten(cats: [Category]) {
                for cat in cats {
                    flatCategories.append(cat)
                    if let subs = cat.subcategories {
                        flatten(cats: subs)
                    }
                }
            }
            flatten(cats: roots)
            categories = flatCategories
        } catch {
            print("Failed to load budgets or categories: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func setBudget(categoryId: String, amount: Double) async {
        isLoading = true
        let params: [String: Any] = [
            "category_id": categoryId,
            "amount": amount
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: params)
            struct GenericResponse: Decodable {}
            let _ : GenericResponse? = try? await APIManager.shared.request(endpoint: "/budgets/set", method: "POST", body: data)
            await fetchBudgets()
        } catch {
            print("Failed to set budget: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func setBulkBudgets(budgets: [[String: Any]]) async {
        isLoading = true
        let params: [String: Any] = [
            "budgets": budgets
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: params)
            struct GenericResponse: Decodable {}
            let _ : GenericResponse? = try? await APIManager.shared.request(endpoint: "/budgets/set-bulk", method: "POST", body: data)
            await fetchBudgets()
        } catch {
            print("Failed to set bulk budgets: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
