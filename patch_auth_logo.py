with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "r") as f:
    content = f.read()

# Replace leaf.fill with the custom logo
old_icon = """                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.top, 40)"""

new_icon = """                    Image("FinancyLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5)
                        .padding(.top, 40)"""

content = content.replace(old_icon, new_icon)

# Force light mode on AuthView to fix placeholder colors against white background
old_end = """        .background(FinPilotColors.background.ignoresSafeArea())
        .onTapGesture {"""

new_end = """        .background(FinPilotColors.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onTapGesture {"""

content = content.replace(old_end, new_end)

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)
