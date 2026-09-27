with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "r") as f:
    content = f.read()

content = content.replace('http://localhost:3000', 'http://192.168.1.9:3000')

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthViewModel.swift", "w") as f:
    f.write(content)
