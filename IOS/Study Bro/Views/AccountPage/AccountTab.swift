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
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        // MARK: - Page Title
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
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
                                            .fontWeight(.semibold)
                                        
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
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(.thinMaterial)
                                    .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Divider / Section Break
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        
                        HStack {
                            VStack (alignment: .leading) {
                                
                                Text("Settings")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.bottom)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                NavigationLink {
                                    PrivacyView()
                                } label: {
                                    HStack {
                                        Text("Security and privacy")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                                }
                                .padding(.bottom, 6)

                                NavigationLink {
                                    SubscribeView()
                                } label: {
                                    HStack {
                                        Text("Subscribe")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                                }
                                .padding(.bottom, 6)
                                NavigationLink {
                                    LegalView()
                                } label: {
                                    HStack {
                                        Text("Legal")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                                }
                                .padding(.bottom, 6)
                                
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.thinMaterial)
                                .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        VStack(alignment: .leading) {
                            Text("Customization")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            NavigationLink {
                                CHooseStudyBranches()
                            } label: {
                                HStack {
                                    Text("Studying branches")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .padding(.bottom, 6)
                            
                            NavigationLink {
                                FocusSettingsView()
                            } label: {
                                HStack {
                                    Text("Focus")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .padding(.bottom, 6)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.thinMaterial)
                                .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        
                        HStack {
                            logOutButton()
                                .foregroundColor(.primary)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                    } // end ScrollView
                    
                } else {
                    // MARK: - Loading / Not Logged In
                    VStack(spacing: 16) {
                        Text("Loading...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        ProgressView()
                            .font(.title)
                        
                        Text("If you are not logged in, you can log in below:")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        Button {
                            showSignInView = true
                        } label: {
                            Text("Sign in / Create an account")
                                .fontWeight(.semibold)
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.accentColor)
                                )
                        }
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.thinMaterial)
                            .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                    )
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
                .padding(.horizontal, 20)
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
                                .fontWeight(.semibold)
                            
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
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.thinMaterial)
                        .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                )
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
            }
            
            // MARK: - Divider / Section Break
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            
            HStack {
                VStack (alignment: .leading) {
                    
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        HStack {

                            Text("Security and privacy")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.primary)

                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.bottom, 6)

                    NavigationLink {
                        LegalView()
                    } label: {
                        HStack {
                            Text("Legal")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.bottom, 6)

                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            VStack(alignment: .leading) {
                Text("Customization")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink {
                    // TODO: Replace with your customization view
                    Text("Customization options coming soon")
                } label: {
                    HStack {
                        Text("App Appearance")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                .padding(.bottom, 6)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            
            HStack {
                logOutButton()
                    .foregroundColor(.primary)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
        } // end ScrollView
    }
    
}

struct PomodoroTimerViewWrapper: View {
    @State private var startSession = false
    @State private var userWillStudy = ""
    @State private var userId = ""
    var body: some View {
        PomodoroTimerView(startSession: $startSession, userWillStudy: $userWillStudy, userId: $userId)
    }
}
