import SwiftUI

struct RecurringTransactionsView: View {
    @State private var transactions: [RecurringTransaction] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if transactions.isEmpty {
                    Text("No recurring transactions found.")
                        .foregroundColor(FinPilotColors.textSecondary)
                        .padding()
                } else {
                    ForEach(transactions) { tx in
                        RecurringTransactionCard(transaction: tx)
                    }
                }
            }
            .padding()
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .navigationTitle("Recurring Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchRecurring()
        }
        .refreshable {
            await fetchRecurring()
        }
        .loadingOverlay(isLoading: isLoading, message: "Syncing Data...")
    }
    
    private func fetchRecurring() async {
        isLoading = true
        do {
            let fetched: [RecurringTransaction] = try await APIManager.shared.request(endpoint: "/recurring")
            transactions = fetched
        } catch {
            print("Failed to load recurring transactions: \(error)")
        }
        isLoading = false
    }
}

struct RecurringTransactionCard: View {
    let transaction: RecurringTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.type.lowercased() == "income" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title)
                .foregroundColor(transaction.type.lowercased() == "income" ? FinPilotColors.success : FinPilotColors.error)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Unknown")
                    .font(FinPilotTypography.headline)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("Next: \(transaction.nextDate.formatted(date: .abbreviated, time: .omitted)) • \(transaction.frequency.capitalized)")
                    .font(FinPilotTypography.caption)
                    .foregroundColor(FinPilotColors.textSecondary)
            }
            
            Spacer()
            
            Text("₹\(Int(transaction.amount))")
                .font(FinPilotTypography.headline)
                .foregroundColor(FinPilotColors.textPrimary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
