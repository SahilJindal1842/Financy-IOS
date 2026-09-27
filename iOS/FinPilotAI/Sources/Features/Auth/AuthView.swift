import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Area
                ZStack {
                    FinPilotColors.primary
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image("FinancyLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5)
                            .padding(.top, 40)
                        
                        Text("Financy")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your intelligent financial companion")
                            .font(FinPilotTypography.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                }
                .frame(height: 300)
                
                // Form Area
                VStack(spacing: 24) {
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(FinPilotColors.error)
                            .font(FinPilotTypography.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                    }
                    
                    switch viewModel.currentFlow {
                    case .login:
                        LoginView()
                    case .signupStep1:
                        SignupStep1View()
                    case .signupStep2:
                        SignupStep2View()
                    case .signupStep3:
                        SignupStep3View()
                    }
                }
                .padding(.horizontal, 24)
                .background(FinPilotColors.background)
                .cornerRadius(32, corners: [.topLeft, .topRight])
                .offset(y: -32) // overlap with header
            }
        }
        .background(FinPilotColors.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            viewModel.checkAuthStatus()
        }
        .animation(.easeInOut, value: viewModel.currentFlow)
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Authenticating...")
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var loginMethod = 0 // 0: Email, 1: Mobile
    @State private var email = ""
    @State private var mobile = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome Back")
                .font(FinPilotTypography.title2)
                .foregroundColor(FinPilotColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 32)
            
            Picker("Login Method", selection: $loginMethod) {
                Text("Email").tag(0)
                Text("Mobile").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack(spacing: 16) {
                if loginMethod == 0 {
                    InputField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
                } else {
                    InputField(icon: "phone.fill", placeholder: "Mobile Number", text: $mobile, keyboardType: .phonePad)
                }
                
                SecureInputField(icon: "lock.fill", placeholder: "Password", text: $password)
            }
            
            Button("Forgot Password?") {
                // Forgot password logic
            }
            .font(FinPilotTypography.subheadline)
            .foregroundColor(FinPilotColors.primary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            PrimaryButton(title: "Login", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.login(email: loginMethod == 0 ? email : nil,
                                          mobile: loginMethod == 1 ? mobile : nil,
                                          password: password)
                }
            }
            
            HStack {
                Text("Don't have an account?")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Button(action: {
                    viewModel.currentFlow = .signupStep1
                }) {
                    Text("Sign Up")
                        .font(FinPilotTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Signup Step 1 View
struct SignupStep1View: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Account")
                .font(FinPilotTypography.title2)
                .foregroundColor(FinPilotColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 32)
            
            VStack(spacing: 16) {
                InputField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                InputField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
                SecureInputField(icon: "lock.fill", placeholder: "Password", text: $password)
                SecureInputField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword)
            }
            
            PrimaryButton(title: "Next", isLoading: viewModel.isLoading) {
                if password == confirmPassword && !password.isEmpty {
                    Task {
                        await viewModel.signup(fullName: fullName, email: email, password: password)
                    }
                } else {
                    viewModel.error = "Passwords do not match."
                }
            }
            
            HStack {
                Text("Already have an account?")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Button(action: {
                    viewModel.currentFlow = .login
                }) {
                    Text("Login")
                        .font(FinPilotTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Signup Step 2 View (OTP)
struct SignupStep2View: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var otp = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Verify Email")
                .font(FinPilotTypography.title2)
                .foregroundColor(FinPilotColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 32)
            
            Text("Enter the 6-digit code sent to \(viewModel.signupEmail)")
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InputField(icon: "number.square.fill", placeholder: "6-digit OTP", text: $otp, keyboardType: .numberPad)
            
            PrimaryButton(title: "Verify", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.verifyOTP(code: otp)
                }
            }
            
            Button(action: {
                viewModel.currentFlow = .signupStep1
            }) {
                Text("Back to Sign Up")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.primary)
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Signup Step 3 View (Profile)
struct SignupStep3View: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var currency = "USD"
    @State private var monthlyIncome = ""
    @State private var primaryGoal = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Complete Profile")
                .font(FinPilotTypography.title2)
                .foregroundColor(FinPilotColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 32)
            
            VStack(spacing: 16) {
                InputField(icon: "dollarsign.circle.fill", placeholder: "Currency (e.g. USD, EUR)", text: $currency)
                InputField(icon: "banknote.fill", placeholder: "Monthly Income", text: $monthlyIncome, keyboardType: .decimalPad)
                InputField(icon: "target", placeholder: "Primary Goal (e.g. Save for a house)", text: $primaryGoal)
            }
            
            PrimaryButton(title: "Complete Setup", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.completeProfile(currency: currency, monthlyIncome: monthlyIncome, primaryGoal: primaryGoal)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Reusable Components
struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textPrimary)
        }
        .padding()
        .background(FinPilotColors.surface)
        .cornerRadius(12)
    }
}

struct SecureInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(width: 24)
            SecureField(placeholder, text: $text)
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textPrimary)
        }
        .padding()
        .background(FinPilotColors.surface)
        .cornerRadius(12)
    }
}

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(FinPilotTypography.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
        }
        .disabled(isLoading)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(FinPilotColors.primary.opacity(isLoading ? 0.7 : 1.0))
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: FinPilotColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.top, 16)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
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
