with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "r") as f:
    content = f.read()

content = content.replace('Text("FinPilot AI")', 'Text("Financy")')

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)
