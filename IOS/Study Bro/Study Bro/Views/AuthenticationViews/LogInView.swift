//
//  EmailSignInPageView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore
import AuthenticationServices

struct LogInView: View {
    
    @StateObject private var viewModel = SignUpEmailViewModel()
    @StateObject private var googleVm = SignInWithGoogleModel()
    @StateObject private var appleVM = AppleSignInViewModel()
    
    @AppStorage("showSignInView") private var showSignInView: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Welcoming Header
                    VStack(spacing: 8) {
                        Text("Welcome Back to Study Bro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        Text("Log in to access your account.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 40)
                    
                    // Email Field Card
                    CustomTextField(text: $viewModel.email, placeholder: "Email", keyboardType: .emailAddress, returnKeyType: .next)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Password Field Card
                    CustomTextField(text: $viewModel.password, placeholder: "Password", isSecure: true, returnKeyType: .done)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Primary Login Button
                    Button(action: {
                        Task {
                            viewModel.errorMessage = ""
                            await signInWithEmail()
                            if viewModel.errorMessage == "" {
                                showSignInView = false
                            }
                        }
                    }) {
                        Text("Log in")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
                    
                    // Social Sign-In Buttons
                    Button(action: {
                        Task { await signInWithGoogle() }
                    }) {
                        HStack(spacing: 12) {
                            Image("google")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("Log in with Google")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                        .cardStyle()
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    SignInWithAppleButtonViewRepresentable(type: .signIn, style: .black, onTap: {
                        Task { await signUpWithApple() }
                    })
                    .frame(height: 50)
                    .padding(.horizontal)
                    // Only close the sign-in view when Firebase user is authenticated
                    .onChange(of: appleVM.didSignInWithApple) { _, newValue in
                        if newValue {
                            // Double-check Firebase authentication before closing
                            if Auth.auth().currentUser != nil {
                                showSignInView = false
                            }
                        }
                    }
                    
                    // Navigation Links for Sign Up and Reset Password
                    NavigationLink(destination: SignUpView().navigationBarBackButtonHidden()) {
                        HStack {
                            Text("Don't have an account yet?")
                            Text("Sign up")
                                .bold()
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        .font(.subheadline)
                        .padding()
                    }
                    
//                    NavigationLink(destination: ResetPasswordView().navigationBarBackButtonHidden()) {
//                        Text("Forgot your password?")
//                            .bold()
//                            .underline()
//                            .foregroundColor(Color("JobbGreen"))
//                            .font(.subheadline)
//                            .padding()
//                    }
                    
                    Spacer()
                }
                .padding()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    func signInWithEmail() async {
        do {
            try await viewModel.signIn()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
    
    func signInWithGoogle() async {
        do {
            try await googleVm.signInGoogle()
            self.showSignInView = false
            
        } catch {
            print("Error signing in with Google: \(error)")
        }
    }
    
    func signUpWithApple() async {
        await appleVM.signUpWithApple()
        // Removed showSignInView = false here to only close after confirmed authentication
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}
