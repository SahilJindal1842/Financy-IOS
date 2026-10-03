import SwiftUI
import PhotosUI

// MARK: - Main Auth View
struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var activeTab: Int = 0 // 0: Login, 1: Sign Up
    
    var body: some View {
        ZStack {
            FinPilotColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if viewModel.currentFlow == .login || viewModel.currentFlow == .signupStep1 {
                        // Header
                        headerView
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                        
                        // Tab Selector [ Login | Sign Up ]
                        tabSelector
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        
                        // Error message
                        if let error = viewModel.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(FinPilotColors.error)
                                Text(error)
                                    .font(FinPilotTypography.caption)
                                    .foregroundColor(FinPilotColors.error)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FinPilotColors.error.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        }
                        
                        // Active Screen
                        if activeTab == 0 {
                            ModernLoginView(onSwitchToSignUp: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeTab = 1
                                    viewModel.currentFlow = .signupStep1
                                }
                            })
                            .padding(.horizontal, 24)
                        } else {
                            ModernSignupView(onSwitchToLogin: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeTab = 0
                                    viewModel.currentFlow = .login
                                }
                            })
                            .padding(.horizontal, 24)
                        }
                    } else if viewModel.currentFlow == .signupStep2 {
                        SignupStep2View()
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    } else if viewModel.currentFlow == .signupStep3 {
                        SignupStep3View()
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            if viewModel.currentFlow == .login {
                activeTab = 0
            } else if viewModel.currentFlow == .signupStep1 {
                activeTab = 1
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Please wait...")
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Image("FinancyLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: FinPilotColors.primary.opacity(0.18), radius: 10, x: 0, y: 5)
            
            Text("Financy")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.textPrimary)
            
            Text("Your Personal Finance Companion")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(FinPilotColors.textSecondary)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Login", isSelected: activeTab == 0) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    activeTab = 0
                    viewModel.currentFlow = .login
                }
            }
            
            tabButton(title: "Sign Up", isSelected: activeTab == 1) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    activeTab = 1
                    viewModel.currentFlow = .signupStep1
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? FinPilotColors.primary : FinPilotColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(12)
                .shadow(color: isSelected ? Color.black.opacity(0.06) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Modern Login View
struct ModernLoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    let onSwitchToSignUp: () -> Void
    
    @State private var loginMethod: Int = 0 // 0: Email, 1: Mobile
    @State private var email = ""
    @State private var mobile = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberMe = true
    @State private var showingSocialDialog = false
    @State private var socialProvider = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Method Switcher [ Email | Mobile ]
            methodPicker
            
            // Input Fields
            VStack(spacing: 14) {
                if loginMethod == 0 {
                    ModernTextField(
                        icon: "envelope.fill",
                        placeholder: "Email Address",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                } else {
                    ModernTextField(
                        icon: "phone.fill",
                        placeholder: "Mobile Number",
                        text: $mobile,
                        keyboardType: .phonePad,
                        prefix: "+91 "
                    )
                }
                
                ModernSecureField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    showPassword: $showPassword
                )
            }
            
            // Remember Me & Forgot Password
            HStack {
                Button(action: { rememberMe.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                            .foregroundColor(rememberMe ? FinPilotColors.primary : FinPilotColors.textSecondary)
                            .font(.system(size: 16))
                        Text("Remember me")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(FinPilotColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showForgotPassword = true }) {
                    Text("Forgot Password?")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.horizontal, 4)
            
            // Login Button
            PrimaryGradientButton(title: "Login", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.login(
                        email: loginMethod == 0 ? email.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                        mobile: loginMethod == 1 ? mobile.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                        password: password
                    )
                }
            }
            .disabled((loginMethod == 0 ? email.isEmpty : mobile.isEmpty) || password.isEmpty)
            .opacity(((loginMethod == 0 ? email.isEmpty : mobile.isEmpty) || password.isEmpty) ? 0.6 : 1.0)
            
            // Or continue with Divider
            orDivider
            
            // Social Auth Buttons (Google, Facebook, Apple)
            SocialLoginRow(onSelectProvider: { provider in
                socialProvider = provider
                showingSocialDialog = true
            })
            
            // Bottom Switch to Sign Up
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Button(action: onSwitchToSignUp) {
                    Text("Sign Up")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.top, 8)
        }
        .actionSheet(isPresented: $showingSocialDialog) {
            ActionSheet(
                title: Text("Sign in with \(socialProvider)"),
                message: Text("Authorize Financy to sign in using your \(socialProvider) account."),
                buttons: [
                    .default(Text("Continue with \(socialProvider)")) {
                        Task {
                            let dummyEmail = "\(socialProvider.lowercased())_user@financy.app"
                            let dummyName = "\(socialProvider) User"
                            await viewModel.socialLogin(provider: socialProvider.lowercased(), email: dummyEmail, name: dummyName)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showForgotPassword) {
            Alert(
                title: Text("Reset Password"),
                message: Text("Password reset instructions have been dispatched to your registered address."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var methodPicker: some View {
        HStack(spacing: 12) {
            methodButton(title: "Email", icon: "envelope.fill", isSelected: loginMethod == 0) {
                loginMethod = 0
            }
            methodButton(title: "Mobile", icon: "phone.fill", isSelected: loginMethod == 1) {
                loginMethod = 1
            }
        }
    }
    
    private func methodButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? FinPilotColors.primary.opacity(0.12) : Color.white)
            .foregroundColor(isSelected ? FinPilotColors.primary : FinPilotColors.textSecondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? FinPilotColors.primary : Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Modern Signup View
struct ModernSignupView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    let onSwitchToLogin: () -> Void
    
    @State private var signupMethod: Int = 0 // 0: Email, 1: Mobile
    @State private var fullName = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreeToTerms = true
    @State private var showingSocialDialog = false
    @State private var socialProvider = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Method Switcher [ Email | Mobile ]
            methodPicker
            
            // Input Fields
            VStack(spacing: 14) {
                ModernTextField(
                    icon: "person.fill",
                    placeholder: "Full Name",
                    text: $fullName
                )
                
                if signupMethod == 0 {
                    ModernTextField(
                        icon: "envelope.fill",
                        placeholder: "Email Address",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                } else {
                    ModernTextField(
                        icon: "phone.fill",
                        placeholder: "Mobile Number",
                        text: $mobile,
                        keyboardType: .phonePad,
                        prefix: "+91 "
                    )
                }
                
                ModernSecureField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    showPassword: $showPassword
                )
                
                ModernSecureField(
                    icon: "lock.shield.fill",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    showPassword: $showPassword
                )
            }
            
            // Terms Agreement
            HStack(alignment: .top, spacing: 10) {
                Button(action: { agreeToTerms.toggle() }) {
                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreeToTerms ? FinPilotColors.primary : FinPilotColors.textSecondary)
                        .font(.system(size: 16))
                        .padding(.top, 2)
                }
                
                Text("I agree to Financy's Terms of Service & Privacy Policy")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(FinPilotColors.textSecondary)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Sign Up Button
            PrimaryGradientButton(title: "Create Account", isLoading: viewModel.isLoading) {
                guard password == confirmPassword else {
                    viewModel.error = "Passwords do not match."
                    return
                }
                guard agreeToTerms else {
                    viewModel.error = "Please agree to the Terms of Service."
                    return
                }
                
                Task {
                    await viewModel.signup(
                        fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                        email: signupMethod == 0 ? email.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                        mobile: signupMethod == 1 ? mobile.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                        password: password
                    )
                }
            }
            .disabled(fullName.isEmpty || (signupMethod == 0 ? email.isEmpty : mobile.isEmpty) || password.isEmpty || confirmPassword.isEmpty)
            .opacity((fullName.isEmpty || (signupMethod == 0 ? email.isEmpty : mobile.isEmpty) || password.isEmpty) ? 0.6 : 1.0)
            
            // Or continue with Divider
            orDivider
            
            // Social Auth Buttons
            SocialLoginRow(onSelectProvider: { provider in
                socialProvider = provider
                showingSocialDialog = true
            })
            
            // Bottom Switch to Login
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Button(action: onSwitchToLogin) {
                    Text("Login")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(FinPilotColors.primary)
                }
            }
            .padding(.top, 8)
        }
        .actionSheet(isPresented: $showingSocialDialog) {
            ActionSheet(
                title: Text("Sign up with \(socialProvider)"),
                message: Text("Create your Financy account instantly using your \(socialProvider) profile."),
                buttons: [
                    .default(Text("Continue with \(socialProvider)")) {
                        Task {
                            let dummyEmail = "\(socialProvider.lowercased())_user@financy.app"
                            let dummyName = fullName.isEmpty ? "\(socialProvider) User" : fullName
                            await viewModel.socialLogin(provider: socialProvider.lowercased(), email: dummyEmail, name: dummyName)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var methodPicker: some View {
        HStack(spacing: 12) {
            methodButton(title: "Sign up with Email", icon: "envelope.fill", isSelected: signupMethod == 0) {
                signupMethod = 0
            }
            methodButton(title: "Sign up with Mobile", icon: "phone.fill", isSelected: signupMethod == 1) {
                signupMethod = 1
            }
        }
    }
    
    private func methodButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? FinPilotColors.primary.opacity(0.12) : Color.white)
            .foregroundColor(isSelected ? FinPilotColors.primary : FinPilotColors.textSecondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? FinPilotColors.primary : Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Social Login Components
struct SocialLoginRow: View {
    let onSelectProvider: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Google
            SocialButton(
                title: "Google",
                icon: AnyView(GoogleLogoView()),
                action: { onSelectProvider("Google") }
            )
            
            // Facebook
            SocialButton(
                title: "Facebook",
                icon: AnyView(FacebookLogoView()),
                action: { onSelectProvider("Facebook") }
            )
            
            // Apple
            SocialButton(
                title: "Apple",
                icon: AnyView(Image(systemName: "applelogo").font(.system(size: 18)).foregroundColor(.black)),
                action: { onSelectProvider("Apple") }
            )
        }
    }
}

struct SocialButton: View {
    let title: String
    let icon: AnyView
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}

struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            Text("G")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#4285F4"))
        }
        .frame(width: 20, height: 20)
    }
}

struct FacebookLogoView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#1877F2"))
                .frame(width: 20, height: 20)
            Text("f")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .offset(y: -1)
        }
    }
}

// MARK: - Reusable Modern Form Components
struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var prefix: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(width: 22)
            
            if let prefix = prefix {
                Text(prefix)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)
                    .fontWeight(.semibold)
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .font(FinPilotTypography.body)
                .foregroundColor(FinPilotColors.textPrimary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.gray.opacity(0.5))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct ModernSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(FinPilotColors.textSecondary)
                .frame(width: 22)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)
            } else {
                SecureField(placeholder, text: $text)
                    .font(FinPilotTypography.body)
                    .foregroundColor(FinPilotColors.textPrimary)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(FinPilotColors.textSecondary)
                    .font(.system(size: 15))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct PrimaryGradientButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [FinPilotColors.primaryLight, FinPilotColors.primary]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: FinPilotColors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

private var orDivider: some View {
    HStack(spacing: 12) {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
        Text("Or continue with")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(FinPilotColors.textSecondary)
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
    }
    .padding(.vertical, 4)
}

// MARK: - Signup Step 2 View (OTP)
struct SignupStep2View: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var otp = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(FinPilotColors.primary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 32))
                    .foregroundColor(FinPilotColors.primary)
            }
            
            VStack(spacing: 8) {
                Text("Verify Your Account")
                    .font(FinPilotTypography.title2)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                let target = !viewModel.signupEmail.isEmpty ? viewModel.signupEmail : viewModel.signupMobile
                Text("Enter the 6-digit code sent to \(target)")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // OTP Input
            ModernTextField(
                icon: "number.square.fill",
                placeholder: "6-digit OTP",
                text: $otp,
                keyboardType: .numberPad
            )
            
            PrimaryGradientButton(title: "Verify & Continue", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.verifyOTP(code: otp.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            .disabled(otp.count < 4)
            .opacity(otp.count < 4 ? 0.6 : 1.0)
            
            Button(action: {
                viewModel.currentFlow = .signupStep1
            }) {
                Text("Back to Sign Up")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(FinPilotColors.primary)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Signup Step 3 View (Profile Setup)
struct SignupStep3View: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var currency = "INR"
    @State private var monthlyIncome = ""
    @State private var primaryGoal = "Savings & Investments"
    @State private var avatar: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Personalize Financy")
                    .font(FinPilotTypography.title2)
                    .foregroundColor(FinPilotColors.textPrimary)
                
                Text("Help us tailor your financial companion to your goals")
                    .font(FinPilotTypography.subheadline)
                    .foregroundColor(FinPilotColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            AvatarPickerView(avatarBase64: $avatar)
            
            VStack(spacing: 14) {
                ModernTextField(
                    icon: "indianrupeesign.circle.fill",
                    placeholder: "Currency (e.g. INR, USD)",
                    text: $currency
                )
                
                ModernTextField(
                    icon: "banknote.fill",
                    placeholder: "Monthly Income (e.g. 50000)",
                    text: $monthlyIncome,
                    keyboardType: .decimalPad
                )
                
                ModernTextField(
                    icon: "target",
                    placeholder: "Primary Goal (e.g. Buy a home)",
                    text: $primaryGoal
                )
            }
            
            PrimaryGradientButton(title: "Complete Setup", isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.completeProfile(
                        currency: currency,
                        monthlyIncome: monthlyIncome,
                        primaryGoal: primaryGoal,
                        avatar: avatar
                    )
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Gorgeous Splash View (Screen 1 in Prototype)
struct SplashView: View {
    @Binding var hasSeenSplash: Bool
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var isAnimating = false
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Emerald Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "#052e16"),
                    Color(hex: "#065f46"),
                    Color(hex: "#047857"),
                    Color(hex: "#0F9D58")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle Ambient Glow Circles
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 380, height: 380)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color(hex: "#34D399").opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 15)
            }
            
            VStack(spacing: 0) {
                // Top Branding Badge
                HStack(spacing: 8) {
                    Image("FinancyLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Financy")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .padding(.top, 40)
                
                Spacer()
                
                // Hero Typography
                VStack(spacing: 12) {
                    Text("Take Control of\nYour Finances")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Text("Track. Budget. Save. Grow.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 3D Wallet Illustration Visual
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .frame(width: 260, height: 260)
                    
                    Image("WalletIllustration")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                        .offset(y: floatOffset)
                }
                .padding(.vertical, 16)
                
                Spacer()
                
                // Bottom CTAs
                VStack(spacing: 16) {
                    // "Get Started" Button (White pill with green text)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenSplash = true
                            viewModel.currentFlow = .signupStep1
                        }
                    }) {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#065f46"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    }
                    
                    // "Already have an account? Login" Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenSplash = true
                            viewModel.currentFlow = .login
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                            
                            Text("Login")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true)
            ) {
                floatOffset = -8
            }
        }
    }
}
