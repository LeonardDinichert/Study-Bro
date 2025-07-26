//
//  AuthenticationView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//


import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import FirebaseAuth

struct AuthenticationView: View {
    
    @StateObject private var vm = SignInWithGoogleModel()
    @AppStorage("showSignInView") private var showSignInView: Bool = true

    
    var body: some View {
        NavigationStack {
            ZStack {
                
                VStack(spacing: 40) {
                    Spacer(minLength: 80)
                    
                    // Welcoming Header
                    VStack(spacing: 12) {
                        Text("Welcome")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Create an account or log in to start exploring amazing opportunities.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
//                        Button {
//                            showSignInView = false
//                        } label: {
//                            Text("I am a demo user, access the app without the personalised account feature")
//                        }

                    }
                    
                    // Navigation Buttons as Cards
                    VStack(spacing: 20) {
                        NavigationLink {
                            SignUpView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            Text("Create an Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                        
                        NavigationLink {
                            LogInView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}

