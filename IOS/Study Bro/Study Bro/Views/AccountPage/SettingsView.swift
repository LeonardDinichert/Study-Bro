//
//  UserAccountDetail.swift
//
//
//  Created by Léonard Dinichert on 10.04.25.
//

import SwiftUI
import Combine


struct SettingsView: View {
    
    let userId: String
    let user: DBUser
    
    @StateObject private var viewModel = userManagerViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // MARK: - Personal Info Cards
                    VStack(spacing: 16) {
                        NavigationLink {
                            ShowEmailAdressView()
                        } label: {
                            settingsRow(title: "Email")
                        }
                        
                        NavigationLink {
                            ShowPasswordView()
                        } label: {
                            settingsRow(title: "Password")
                        }
                        
                        NavigationLink {
                            EditProfileView(user: user)
                        } label: {
                            settingsRow(title: "Edit Profile")
                        }

                        NavigationLink {
                            LegalView()
                        } label: {
                            settingsRow(title: "Legal")
                        }

                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding()
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("My account")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            try? await viewModel.loadCurrentUser()
        }
    }
    
    // MARK: - Helper for Settings Row
    @ViewBuilder
    private func settingsRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .cardStyle()
    }
}

@MainActor
final class SettingViewModel: ObservableObject {
    
    @Published var authProviders: [authProviderOption] = []
    @AppStorage("showSignInView") private var showSignInView: Bool = true
    
    
    func loadAuthProviders() {
        if let providers = try? AuthService.shared.getProviders() {
            authProviders = providers
        }
    }
    
    func logOut() throws {
        try AuthService.shared.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await AuthService.shared.resetPassword(email: email)
    }
    
    func updateEmail(email: String) async throws {
        try await AuthService.shared.updateEmail(email: email)
    }
    
    func updatePassword(password: String) async throws {
        try await AuthService.shared.updatePassword(password: password)
    }
    
}
