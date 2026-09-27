with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "r") as f:
    content = f.read()

# Replace the top VStack with a ScrollView containing a VStack
old_body = """    var body: some View {
        VStack(spacing: 0) {"""

new_body = """    var body: some View {
        ScrollView {
            VStack(spacing: 0) {"""

content = content.replace(old_body, new_body)

# Add the closing brace for ScrollView before the modifiers
old_end = """        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .onAppear {"""

new_end = """            }
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {"""

content = content.replace(old_end, new_end)

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)

