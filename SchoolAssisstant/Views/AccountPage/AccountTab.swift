//
//  AccountTab.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//

import SwiftUI

struct AccountTab: View {
    
    @StateObject private var viewModel = userManagerViewModel()
    @State private var url: URL? = nil
    @AppStorage("showSignInView") private var showSignInView: Bool = true

    var body: some View {

        NavigationStack {
            if let user = viewModel.user {
                AccountViewSub(user: user)
                
            } else {
                // MARK: - Loading / Not Logged In
                VStack(spacing: 16) {
                    Text("Loading...")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    ProgressView()
                        .font(.title)
                    
                    Text("If you are not logged in, you can log in below:")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 40)
                    
                    Button {
                        showSignInView = true
                    } label: {
                        Text("Sign in / Create an account")
                            .fontWeight(.semibold)
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .onAppear() {
            Task {
                print("yes")
                try await viewModel.loadCurrentUser()
            }
        }
    }
}

#Preview {
    AccountViewSub(user: DBUser(userId: "dummy", email: "test", age: 23, username: "testkug", firstName: "monsiuer", lastName: "mister", profileImagePathUrl: "jh", biography: "tres gentiwe", fcmToken: "khk", lastConnection: Date()))
}

struct logOutButton: View {
    
    @State private var UserWantsToLogOut = false
    
    @AppStorage("showSignInView") private var showSignInView: Bool = true
    
    var body: some View {
        Button("Me déconnecter", role: .destructive) {
            UserWantsToLogOut = true
            print("Ask for logging out")
        }
        .alert("Etes-vous sur de vouloir vous déconnecter?", isPresented: $UserWantsToLogOut) {
            Button("Oui", role: .destructive) {
                Task {
                    do {
                        try AuthService.shared.signOut()
                        showSignInView = true
                    } catch {
                        print(error)
                    }
                }
            }
            
            Button("Non", role: .cancel) { }
        }
    }
}

struct AccountViewSub: View {
    
    let user: DBUser
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            // MARK: - Page Title
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // MARK: - Profile Card
            
            NavigationLink {
                SettingsView(userId: user.userId, user: user)
            } label: {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Profile Image
                        if let urlString = user.profileImagePathUrl,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 70, height: 70)
                        } else {
                            // Fallback circle
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 70)
                        }
                        
                        // Username & subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.username ?? "Error fetching your username")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("More about my profile")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
                        
                    }
                    .padding()
                }
                //.cardStyle()
                .padding(.horizontal)
                .padding(.top, 10)
            }
            
            // MARK: - Divider / Section Break
            Divider()
                .padding()

            
            HStack {
                VStack (alignment: .leading) {
                    
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        HStack {

                            Text("Security and privacy")
                                .font(.headline)
                                .foregroundStyle(.black)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.black)

                        }
                    }
                    .padding(.bottom)

                    NavigationLink {
                        LegalView()
                    } label: {
                        HStack {
                            Text("Legal")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.bottom)

                }
                
                Spacer()
            }
            .padding()
            
            Divider()
                .padding()
            
            HStack {
                logOutButton()
                    .foregroundColor(.black)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            
        } // end ScrollView
        .backgroundExtensionEffect()
    }
    
}
