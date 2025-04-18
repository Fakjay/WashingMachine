import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var selectedSkillLevel = SkillLevel.intermediate
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)), Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // App logo and title
                VStack(spacing: 15) {
                    Image(systemName: "tennis.racket")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("WashingMachine")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Padel Tennis App")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 50)
                
                // Auth form
                VStack(spacing: 25) {
                    if showingSignUp {
                        // Sign up form
                        VStack(spacing: 15) {
                            TextField("Name", text: $name)
                                .textContentType(.name)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                            
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                            
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                            
                            // Skill level picker
                            VStack(alignment: .leading) {
                                Text("Skill Level")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Skill Level", selection: $selectedSkillLevel) {
                                    ForEach(SkillLevel.allCases) { level in
                                        Text(level.rawValue).tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                        
                        Button(action: signUp) {
                            HStack {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                        .disabled(authService.isLoading)
                        
                        Button(action: { showingSignUp = false }) {
                            Text("Already have an account? Sign In")
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, 10)
                        
                    } else {
                        // Sign in form
                        VStack(spacing: 15) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                            
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: signIn) {
                            HStack {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                        .disabled(authService.isLoading)
                        
                        HStack {
                            Button(action: { showingForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            
                            Spacer()
                            
                            Button(action: { showingSignUp = true }) {
                                Text("Sign Up")
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                        .padding(.top, 10)
                        
                        // Social sign in options
                        VStack(spacing: 15) {
                            Divider()
                                .background(Color.white)
                                .padding(.vertical, 15)
                            
                            Button(action: signInWithApple) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 24))
                                    
                                    Text("Sign in with Apple")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                            }
                            
                            Button(action: signInWithGoogle) {
                                HStack {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 24))
                                    
                                    Text("Sign in with Google")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding(.top, 50)
            
            // Error message
            if let error = authService.error {
                VStack {
                    Spacer()
                    
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom))
                }
                .zIndex(1)
                .animation(.easeInOut)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(email: $resetEmail, isPresented: $showingForgotPassword)
                .environmentObject(authService)
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        authService.signIn(email: email, password: password)
    }
    
    private func signUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else { return }
        authService.signUp(name: name, email: email, password: password, skillLevel: selectedSkillLevel)
    }
    
    private func signInWithApple() {
        authService.signInWithApple()
    }
    
    private func signInWithGoogle() {
        authService.signInWithGoogle()
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject private var authService: AuthService
    @Binding var email: String
    @Binding var isPresented: Bool
    @State private var emailSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 70))
                    .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                    .padding(.bottom, 20)
                
                Text("Reset Your Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if emailSent {
                    Text("Email sent! Check your inbox for a password reset link.")
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disableAutocorrection(true)
                    
                    Button(action: resetPassword) {
                        HStack {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                            
                            if authService.isLoading {
                                ProgressView()
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(authService.isLoading || email.isEmpty)
                }
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
            .alert(item: Binding<AuthError?>(
                get: { authService.error != nil ? AuthError(message: authService.error!) : nil },
                set: { _ in authService.error = nil }
            )) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        authService.resetPassword(email: email)
        emailSent = true
    }
}

struct AuthError: Identifiable {
    let id = UUID()
    let message: String
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthService())
    }
} 