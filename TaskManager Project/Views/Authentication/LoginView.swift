import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var showingForgotPassword = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 60)
                
                // Header Section
                headerSection
                
                // Form Section
                formSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(backgroundColor)
        .ignoresSafeArea()
    }
    
    // MARK: - Theme Colors
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.black
            : Color(.systemGroupedBackground)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6)
            : Color.white
    }
    
    private var primaryColor: Color {
        Color.accentColor
    }
    
    private var secondaryTextColor: Color {
        Color(.secondaryLabel)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Circle()
                .fill(primaryColor.gradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                )
                .shadow(
                    color: primaryColor.opacity(0.3),
                    radius: 10, x: 0, y: 5
                )
            
            VStack(spacing: 8) {
                Text("TaskMaster")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Stay organized and productive")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            // Auth Mode Toggle
            authModeToggle
            
            // Input Fields
            inputFields
            
            // Error Message
            if !viewModel.errorMessage.isEmpty {
                errorMessage
            }
            
            // Primary Button
            primaryActionButton
            
            // Divider
            dividerSection
            
            // Google Sign-In
            googleSignInButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.primary.opacity(0.05),
            radius: 20, x: 0, y: 8
        )
    }
    
    // MARK: - Auth Mode Toggle
    private var authModeToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isSignUpMode ? "Create Account" : "Welcome Back")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryTextColor)
                    
                    Button(isSignUpMode ? "Sign In" : "Sign Up") {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isSignUpMode.toggle()
                            // Clear any previous errors when switching modes
                            viewModel.errorMessage = ""
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryColor)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Input Fields
    private var inputFields: some View {
        VStack(spacing: 16) {
            CustomTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            CustomTextField(
                placeholder: "Password",
                text: $password,
                icon: "lock",
                isSecure: true
            )
            
            if !isSignUpMode {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        showingForgotPassword = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(primaryColor)
                }
            }
        }
    }
    
    // MARK: - Error Message
    private var errorMessage: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            Text(viewModel.errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Primary Action Button
    private var primaryActionButton: some View {
        Button(action: handlePrimaryAction) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isSignUpMode ? "person.badge.plus" : "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isSignUpMode ? "Create Account" : "Sign In")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                primaryColor.gradient,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .shadow(
                color: primaryColor.opacity(0.3),
                radius: 8, x: 0, y: 4
            )
        }
        .disabled(isFormInvalid)
        .opacity(isFormInvalid ? 0.6 : 1.0)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.2))
            
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 12)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.2))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Google Sign-In Button
    private var googleSignInButton: some View {
        Button(action: {
            Task { await viewModel.signInWithGoogle() }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                    .background(
                        colorScheme == .dark
                            ? Color(.systemGray5)
                            : Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            )
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Properties
    private var isFormInvalid: Bool {
        viewModel.isLoading || email.isEmpty || password.isEmpty
    }
    
    // MARK: - Actions
    private func handlePrimaryAction() {
        Task {
            if isSignUpMode {
                await viewModel.signUp(email: email, password: password)
            } else {
                await viewModel.signIn(email: email, password: password)
            }
        }
    }
}
