with open("iOS/FinPilotAI/Sources/Models/Models.swift", "r") as f:
    content = f.read()

content = content.replace("struct Transaction: Identifiable, Codable {", "struct Transaction: Identifiable, Codable, Equatable {")

with open("iOS/FinPilotAI/Sources/Models/Models.swift", "w") as f:
    f.write(content)
