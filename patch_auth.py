import re

content = """import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Image/Gradient area
            ZStack {
                FinPilotColors.primary
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Text("FinPilot AI")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your intelligent financial companion")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
            }
            .frame(height: 300)
            
            // Login Form
            VStack(spacing: 24) {
                Text(isSignup ? "Create Account" : "Welcome Back")
                    .font(FinPilotTypography.title2)
                    .foregroundColor(FinPilotColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 32)
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(FinPilotColors.error)
                        .font(FinPilotTypography.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(spacing: 16) {
                    // Email Field
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(FinPilotColors.textSecondary)
                            .frame(width: 24)
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(FinPilotTypography.body)
                    }
                    .padding()
                    .background(FinPilotColors.surface)
                    .cornerRadius(12)
                    
                    // Password Field
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(FinPilotColors.textSecondary)
                            .frame(width: 24)
                        SecureField("Password", text: $password)
                            .font(FinPilotTypography.body)
                    }
                    .padding()
                    .background(FinPilotColors.surface)
                    .cornerRadius(12)
                }
                
                if !isSignup {
                    Button("Forgot Password?") {
                        // Forgot password logic
                    }
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Button(action: {
                    Task {
                        await viewModel.login()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignup ? "Sign Up" : "Login")
                            .font(FinPilotTypography.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FinPilotColors.primary)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.top, 16)
                
                Spacer()
                
                HStack {
                    Text(isSignup ? "Already have an account?" : "Don't have an account?")
                        .font(FinPilotTypography.subheadline)
                        .foregroundColor(FinPilotColors.textSecondary)
                    
                    Button(action: {
                        withAnimation {
                            isSignup.toggle()
                        }
                    }) {
                        Text(isSignup ? "Login" : "Sign Up")
                            .font(FinPilotTypography.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(FinPilotColors.primary)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .background(FinPilotColors.background)
            .cornerRadius(32, corners: [.topLeft, .topRight])
            .offset(y: -32) // overlap with header
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .onAppear {
            viewModel.checkAuthStatus()
        }
    }
}

// Helper to round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
"""

with open("iOS/FinPilotAI/Sources/Features/Auth/AuthView.swift", "w") as f:
    f.write(content)
