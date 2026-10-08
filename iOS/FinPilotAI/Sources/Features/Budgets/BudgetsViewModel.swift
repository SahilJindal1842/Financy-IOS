import SwiftUI

@MainActor
final class BudgetsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var summary: BudgetSummaryResponse?
    @Published var categories: [Category] = []
    @Published var errorMessage: String? = nil
    @Published var selectedMonth: Date = Date()
    
    var selectedMonthString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return df.string(from: selectedMonth)
    }
    
    func fetchBudgets(monthStr: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let targetMonth = monthStr ?? selectedMonthString
        async let summaryTask: BudgetSummaryResponse = try APIManager.shared.request(endpoint: "/budgets/summary?month=\(targetMonth)")
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
    
    func setBudget(categoryId: String, amount: Double, monthStr: String? = nil, applyToYear: Bool = false, applyToUpcomingMonths: Bool = false, year: Int? = nil) async {
        isLoading = true
        var params: [String: Any] = [
            "category_id": categoryId,
            "amount": amount,
            "month": monthStr ?? selectedMonthString
        ]
        if applyToUpcomingMonths {
            params["apply_to_upcoming_months"] = true
        } else if applyToYear {
            params["apply_to_year"] = true
        }
        if let y = year {
            params["year"] = y
        }
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
    
    func setBulkBudgets(budgets: [[String: Any]], monthStr: String? = nil, applyToYear: Bool = false, applyToUpcomingMonths: Bool = false, year: Int? = nil) async {
        isLoading = true
        var params: [String: Any] = [
            "budgets": budgets,
            "month": monthStr ?? selectedMonthString
        ]
        if applyToUpcomingMonths {
            params["apply_to_upcoming_months"] = true
        } else if applyToYear {
            params["apply_to_year"] = true
        }
        if let y = year {
            params["year"] = y
        }
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
