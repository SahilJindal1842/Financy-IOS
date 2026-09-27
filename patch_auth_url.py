with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "r") as f:
    content = f.read()

content = content.replace('private let baseURL = "http://localhost:3000/api/auth"', 'private let baseURL = "http://192.168.1.9:3000/api/auth"')

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "w") as f:
    f.write(content)
