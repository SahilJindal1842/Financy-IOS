with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "r") as f:
    content = f.read()

content = content.replace(".animation(.easeInOut, value: viewModel.transactions)", "")

with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "w") as f:
    f.write(content)
