with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "r") as f:
    content = f.read()

old_call = """                Button(action: {
                    Task {
                        await viewModel.login()
                    }
                }) {"""

new_call = """                Button(action: {
                    Task {
                        if isSignup {
                            // Mock signup for now
                            await viewModel.login(email: email, password: password)
                        } else {
                            await viewModel.login(email: email, password: password)
                        }
                    }
                }) {"""

content = content.replace(old_call, new_call)

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)
