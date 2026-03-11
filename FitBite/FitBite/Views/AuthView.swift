import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) var authVM
    @State private var isRegistering = false
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("FitBite")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text(isRegistering ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(.gray.opacity(0.08))
                            .cornerRadius(12)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        if isRegistering {
                            TextField("Username", text: $username)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.gray.opacity(0.08))
                                .cornerRadius(12)
                                .textContentType(.username)
                                .autocapitalization(.none)
                        }

                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(.gray.opacity(0.08))
                            .cornerRadius(12)
                            .textContentType(isRegistering ? .newPassword : .password)

                        if isRegistering {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.gray.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Error
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Submit Button
                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isRegistering ? "Create Account" : "Log In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(authVM.isLoading || !isValid)
                    .opacity(isValid ? 1 : 0.6)
                    .padding(.horizontal)

                    // Toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRegistering.toggle()
                            authVM.errorMessage = nil
                        }
                    } label: {
                        Text(isRegistering ? "Already have an account? **Log In**" : "Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        if isRegistering {
            return !email.isEmpty && !username.isEmpty
                && password.count >= 6 && password == confirmPassword
        }
        return !email.isEmpty && !password.isEmpty
    }

    private func submit() async {
        if isRegistering {
            await authVM.register(email: email, username: username, password: password)
        } else {
            await authVM.login(email: email, password: password)
        }
    }
}
