import re

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "r") as f:
    content = f.read()

# Fix Email Field
old_email = """                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(FinPilotTypography.body)"""

new_email = """                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(FinPilotTypography.body)
                            .foregroundColor(FinPilotColors.textPrimary)"""

content = content.replace(old_email, new_email)

# Fix Password Field
old_pass = """                        SecureField("Password", text: $password)
                            .font(FinPilotTypography.body)"""

new_pass = """                        SecureField("Password", text: $password)
                            .font(FinPilotTypography.body)
                            .foregroundColor(FinPilotColors.textPrimary)"""

content = content.replace(old_pass, new_pass)

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)

