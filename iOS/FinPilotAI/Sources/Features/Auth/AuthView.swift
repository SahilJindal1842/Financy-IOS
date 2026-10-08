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
    @State private var email = "demo@financy.app"
    @State private var mobile = ""
    @State private var password = "Password@123"
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
                viewModel.startSocialAuth(provider: provider)
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
            .padding(.top, 6)
            
            // Demo Quick Login
            Button(action: {
                email = "demo@financy.app"
                password = "Password@123"
                loginMethod = 0
                Task {
                    await viewModel.login(email: "demo@financy.app", password: "Password@123")
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                    Text("Demo Quick Login (₹20k Income / ₹10k Budget)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FinPilotColors.primary)
                .cornerRadius(12)
            }
            .padding(.top, 4)
            
            // Admin Quick Login
            Button(action: {
                email = "admin@financy.app"
                password = "Admin@123"
                loginMethod = 0
                Task {
                    await viewModel.login(email: "admin@financy.app", password: "Admin@123")
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 13))
                    Text("Admin Quick Login (admin@financy.app)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(FinPilotColors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FinPilotColors.primary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top, 2)
        }
        .sheet(isPresented: $showingSocialDialog) {
            SocialAuthModalView(
                provider: socialProvider,
                isSignUp: false,
                onAuthenticate: { email, name in
                    showingSocialDialog = false
                    Task {
                        await viewModel.socialLogin(provider: socialProvider.lowercased(), email: email, name: name)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowSocialSheet"))) { notif in
            if let p = notif.object as? String {
                socialProvider = p
                showingSocialDialog = true
            }
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
                viewModel.startSocialAuth(provider: provider)
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
        .sheet(isPresented: $showingSocialDialog) {
            SocialAuthModalView(
                provider: socialProvider,
                isSignUp: true,
                onAuthenticate: { email, name in
                    showingSocialDialog = false
                    Task {
                        await viewModel.socialLogin(provider: socialProvider.lowercased(), email: email, name: name)
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FinPilotShowSocialSheet"))) { notif in
            if let p = notif.object as? String {
                socialProvider = p
                showingSocialDialog = true
            }
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
        Image("GoogleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
}

struct FacebookLogoView: View {
    var body: some View {
        Image("FacebookLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
}

// MARK: - Social Authentication Modal
struct SocialAuthModalView: View {
    @Environment(\.presentationMode) var presentationMode
    let provider: String
    let isSignUp: Bool
    let onAuthenticate: (String, String) -> Void
    
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var validationError: String? = nil
    @State private var isAuthenticating: Bool = false
    
    var effectiveProvider: String {
        let p = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        return p.isEmpty ? "Google" : p
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Brand Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(providerColor.opacity(0.12))
                                .frame(width: 72, height: 72)
                            
                            if effectiveProvider.lowercased() == "google" {
                                GoogleLogoView()
                                    .scaleEffect(1.6)
                            } else {
                                FacebookLogoView()
                                    .scaleEffect(1.6)
                            }
                        }
                        
                        Text(isSignUp ? "Sign Up with \(effectiveProvider)" : "Sign In with \(effectiveProvider)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.textPrimary)
                        
                        Text("Connect your official \(effectiveProvider) account with Financy via Firebase Authentication.")
                            .font(.system(size: 14))
                            .foregroundColor(FinPilotColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                    
                    // Input Form
                    VStack(alignment: .leading, spacing: 16) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(FinPilotColors.textSecondary)
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                    TextField("Enter your name", text: $fullName)
                                }
                                .padding(14)
                                .background(Color(hex: "#F9FAFB"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(effectiveProvider) Account Email")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FinPilotColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("e.g. name@\(effectiveProvider.lowercased() == "google" ? "gmail.com" : "example.com")", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(14)
                            .background(Color(hex: "#F9FAFB"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                        
                        if let error = validationError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Button
                    VStack(spacing: 12) {
                        Button(action: handleAuth) {
                            HStack(spacing: 8) {
                                if isAuthenticating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Continue with \(effectiveProvider)")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(providerColor)
                            .cornerRadius(14)
                            .shadow(color: providerColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isAuthenticating)
                        
                        // Firebase Security Badge
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#059669"))
                            Text("Secured via Firebase Identity & Auth Services")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FinPilotColors.textSecondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var providerColor: Color {
        effectiveProvider.lowercased() == "google" ? Color(hex: "#4285F4") : Color(hex: "#1877F2")
    }
    
    private func handleAuth() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            validationError = "Please enter a valid \(effectiveProvider) email address."
            return
        }
        
        validationError = nil
        isAuthenticating = true
        
        let finalName = trimmedName.isEmpty ? "\(effectiveProvider) User" : trimmedName
        onAuthenticate(trimmedEmail, finalName)
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
            
            // Dev Mode OTP Banner (for instant testing or before SMTP is set)
            if let devCode = viewModel.devOTP, !devCode.isEmpty {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(FinPilotColors.primary)
                        Text("Code: \(devCode)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(FinPilotColors.primary)
                        Spacer()
                        Button(action: {
                            self.otp = devCode
                        }) {
                            Text("Autofill")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(FinPilotColors.primary)
                                .cornerRadius(8)
                        }
                    }
                    Text("Also dispatched to your email (check inbox/spam).")
                        .font(.system(size: 11))
                        .foregroundColor(FinPilotColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(FinPilotColors.primary.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FinPilotColors.primary.opacity(0.2), lineWidth: 1)
                )
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
            
            // Resend Code Action
            HStack(spacing: 4) {
                Text("Didn't receive the email?")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(FinPilotColors.textSecondary)
                
                Button("Resend Code") {
                    Task {
                        await viewModel.resendOTP()
                    }
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(FinPilotColors.primary)
            }
            
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

// MARK: - Motion App Logo Component
struct MotionAppLogoView: View {
    @State private var isPulsing = false
    @State private var rotateRings = false
    @State private var waveScale: CGFloat = 1.0
    @State private var waveOpacity: Double = 0.7
    @State private var floatY: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Outermost pulsing wave ring
            Circle()
                .stroke(Color(hex: "#34D399").opacity(waveOpacity), lineWidth: 2)
                .frame(width: 250, height: 250)
                .scaleEffect(waveScale)
            
            // Secondary glowing backdrop ring with radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#10B981").opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 130
                    )
                )
                .frame(width: 270, height: 270)
                .scaleEffect(isPulsing ? 1.12 : 0.94)
            
            // Rotating dashed orbital ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.7),
                            Color(hex: "#34D399").opacity(0.2),
                            Color.white.opacity(0.85),
                            Color(hex: "#10B981").opacity(0.1)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                )
                .frame(width: 195, height: 195)
                .rotationEffect(.degrees(rotateRings ? 360 : 0))
            
            // Central App Logo Card with floating motion & glow
            ZStack {
                // Soft glowing glass plate backdrop
                RoundedRectangle(cornerRadius: 38)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 146, height: 146)
                    .blur(radius: 8)
                
                // Actual Brand Logo Image
                Image("FinancyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 34))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.7), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: "#052e16").opacity(0.4), radius: 25, x: 0, y: 15)
                    .shadow(color: Color(hex: "#34D399").opacity(0.5), radius: 35, x: 0, y: 0)
            }
            .scaleEffect(isPulsing ? 1.05 : 0.97)
            .offset(y: floatY)
        }
        .frame(height: 280)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatY = -10
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotateRings = true
            }
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                waveScale = 1.34
                waveOpacity = 0.0
            }
        }
    }
}

// MARK: - Gorgeous Splash View with Motion Logo in Middle
struct SplashView: View {
    @Binding var hasSeenSplash: Bool
    @EnvironmentObject var viewModel: AuthViewModel
    
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
            
            // Ambient Glow Orbs
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
                Spacer()
                
                // Motion App Logo in the Middle
                MotionAppLogoView()
                
                // Hero Typography
                VStack(spacing: 8) {
                    Text("Financy")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.5)
                    
                    Text("Track. Budget. Save. Grow.")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#34D399"))
                        .tracking(0.3)
                    
                    Text("AI-Powered Personal Finance & Wealth")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom CTAs
                VStack(spacing: 16) {
                    // "Get Started" Button
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
    }
}
