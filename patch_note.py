with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "r") as f:
    content = f.read()

old_note = """                TextField("Note", text: $note)
                    .font(FinPilotTypography.body)"""

new_note = """                TextField("Note", text: $note)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)"""

content = content.replace(old_note, new_note)

with open("iOS/FinPilotAI/Sources/Features/Transactions/TransactionsView.swift", "w") as f:
    f.write(content)

