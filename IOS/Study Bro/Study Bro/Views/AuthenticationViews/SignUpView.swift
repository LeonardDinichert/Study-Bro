//
//  Created by Léonard Dinichert on 09.06.23.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore
import AuthenticationServices

struct SignUpView: View {
        
    @StateObject private var googleVm = SignInWithGoogleModel()
    @ObservedObject var viewModel = SignUpEmailViewModel()
    @StateObject private var appleVM = AppleSignInViewModel()
    
    @State private var signInGoogleFinished: Bool = false
    @State private var signUpSuccessful: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcoming Header
                    VStack(spacing: 12) {
                        Text("Welcome to StuddyBuddy")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        Text("Sign up using your email to get started")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 40)
                    
                    // Email Input Card
                    CustomTextField(text: $viewModel.email, placeholder: "Email", isSecure: false, keyboardType: .emailAddress, returnKeyType: .next)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Password Input Card
                    CustomTextField(text: $viewModel.password, placeholder: "Password", isSecure: true, keyboardType: .default, returnKeyType: .done)
                        .cardStyle()
                        .padding(.horizontal)
                    
                    // Error Message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Primary Sign Up Button
                    Button {
                        Task {
                            viewModel.errorMessage = ""
                            await signUpWithEmail()
                            if viewModel.errorMessage == "" {
                                signUpSuccessful = true
                            }
                        }
                    } label: {
                        Text("Sign up")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
                    
                    // OR Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Sign Up with Google
                    
                    Button {
                        Task {
                            await signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image("google")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("Sign up with Google")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .cardStyle()
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Sign Up with Apple
                    Button {
                        Task { await signUpWithApple() }
                    } label: {
                        SignInWithAppleButtonViewRepresentable(type: .signUp, style: .black)
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    .onChange(of: appleVM.didSignInWithApple) { _, newValue in
                        if newValue { signUpSuccessful = true }
                    }
                    
                    
                    // Already Have an Account?
                    NavigationLink(destination: LogInView().navigationBarBackButtonHidden()) {
                        HStack {
                            Text("Already have an account?")
                            Text("Log in")
                                .bold()
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        .font(.system(size: 16))
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationDestination(isPresented: $signUpSuccessful) {
            UserInfosCreation()
                .navigationBarBackButtonHidden()
        }
    }
    
    // MARK: - Helper functions

    func signUpWithEmail() async {
        do {
            try await viewModel.signUp()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
    
    func signInWithGoogle() async {
        do {
            try await googleVm.signUpGoogle()
            signUpSuccessful = true
        } catch {
            print("Error signing in with Google: \(error)")
        }
    }
    
    func signUpWithApple() async {
        
        appleVM.signUpWithApple()
        signUpSuccessful = true
        
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

