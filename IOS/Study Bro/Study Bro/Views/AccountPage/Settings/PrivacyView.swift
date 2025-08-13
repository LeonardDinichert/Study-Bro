//
//  PrivacyView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Privacy")
                    .font(.largeTitle.bold())
                    .padding(.top)
                Text("Manage your privacy settings and account information.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            DeleteAccountSection()
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PrivacyView()
}

struct DeleteAccountSection: View {
    @State private var UserWantsToDeleteAccount = false
    @AppStorage("showSignInView") private var showSignInView: Bool = false
    @StateObject private var viewModel = userManagerViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .padding(.top)
            Text("Danger Zone")
                .font(.title2.bold())
                .foregroundColor(.red)
            Text("Deleting your account is irreversible. All your data will be permanently removed.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Delete my account", role: .destructive) {
                UserWantsToDeleteAccount = true
                print("Asks for deleting account")
            }
            .alert("Are you sure you want to delete your account? You cannot undo it", isPresented: $UserWantsToDeleteAccount) {
                Button("Yes", role: .destructive) {
                    Task {
                        do {
                            if let user = viewModel.user {
                                viewModel.deleteProfileImage()
                                try await UserManager.shared.deleteUsersData(userId: user.userId)
                                print("données aussi effacées")
                                try await AuthService.shared.deleteAccount(userId: user.userId)
                                showSignInView = true
                                print("Votre compte à bien été supprimé")
                            }
                        } catch {
                            print("There was an error :\(error)")
                        }
                    }
                }
                Button("No", role: .cancel) { }
            }
            .padding(.bottom)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
        .task {
            try? await viewModel.loadCurrentUser()
        }
    }
}
