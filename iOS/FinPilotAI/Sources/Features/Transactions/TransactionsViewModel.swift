import Foundation
import SwiftUI

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var errorMessage: String? = nil
    
    init() {
        NotificationCenter.default.addObserver(forName: .userLoggedOut, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.transactions = []
                self?.categories = []
            }
        }
    }
    
    func fetchTransactions() async {
        isLoading = true
        errorMessage = nil
        do {
            transactions = try await APIManager.shared.request(endpoint: "/transactions")
        } catch {
            print("Failed to load transactions: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchCategories() async {
        do {
            let roots: [Category] = try await APIManager.shared.request(endpoint: "/categories")
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
            print("Failed to load categories: \(error)")
        }
    }
    
    func addTransaction(amount: Double, merchant: String, category: String, date: Date, note: String?, type: String, accountId: String = "default", destinationAccountId: String? = nil) async {
        isLoading = true
        
        let newTx = Transaction(
            id: UUID().uuidString,
            accountId: accountId,
            categoryId: category,
            amount: amount,
            type: type,
            date: date,
            note: note,
            merchant: merchant,
            destinationAccountId: destinationAccountId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(newTx)
            let _ : Transaction = try await APIManager.shared.request(endpoint: "/transactions", method: "POST", body: data)
            await fetchTransactions()
            NotificationCenter.default.post(name: .transactionUpdated, object: nil)
        } catch {
            print("Failed to add transaction: \(error)")
            errorMessage = error.localizedDescription
            await fetchTransactions()
            NotificationCenter.default.post(name: .transactionUpdated, object: nil)
        }
        
        isLoading = false
    }
    
    func checkBudgetExceeded(categoryId: String, amount: Double) async -> String? {
        // Fetch budget summary to check limits
        do {
            let summary: BudgetSummaryResponse = try await APIManager.shared.request(endpoint: "/budgets/summary")
            if let budget = summary.budgets.first(where: { $0.categoryName == categoryId || $0.categoryId == categoryId }) {
                if (budget.spent + amount) > budget.amount {
                    return "Adding this ₹\(amount.formatted()) expense will exceed your \(budget.categoryName ?? budget.categoryId) budget of ₹\(budget.amount.formatted()). Are you sure you want to proceed?"
                }
            }
        } catch {
            print("Failed to check budget: \(error)")
        }
        return nil
    }
}
