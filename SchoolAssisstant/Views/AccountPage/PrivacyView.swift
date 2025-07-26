//
//  PrivacyView.swift
//  Jobb
//
//  Created by Léonard Dinichert on 10.04.2025.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        deleteAccountButton()
    }
}

#Preview {
    PrivacyView()
}

struct deleteAccountButton: View {
    
    @State private var UserWantsToDeleteAccount = false
    
    @AppStorage("showSignInView") private var showSignInView: Bool = false
    
    @StateObject private var viewModel = userManagerViewModel()
    
    var body: some View {
        VStack {
            
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
        }
        .task {
            try? await viewModel.loadCurrentUser()
        }
    }
}
