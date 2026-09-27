with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "r") as f:
    content = f.read()

# Add animation and empty state
old_list = """                List(viewModel.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }"""

new_list = """                if viewModel.transactions.isEmpty && !viewModel.isLoading {
                    VStack {
                        Spacer()
                        Text("No transactions yet.")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap + to add one!")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }
                    .animation(.easeInOut, value: viewModel.transactions)
                }"""

content = content.replace(old_list, new_list)

with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "w") as f:
    f.write(content)
