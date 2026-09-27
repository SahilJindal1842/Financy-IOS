with open("iOS/FinPilotAI/Sources/App/FinPilotAIApp.swift", "r") as f:
    content = f.read()

content = content.replace("            AppCoordinatorView()\n        }", "            AppCoordinatorView()\n                .preferredColorScheme(.light)\n        }")

with open("iOS/FinPilotAI/Sources/App/FinPilotAIApp.swift", "w") as f:
    f.write(content)
