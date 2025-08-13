//
//  ShowEmailAdressView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import Firebase
import FirebaseStorage
import PhotosUI
import UserNotifications


struct ShowEmailAdressView: View {
    
    @StateObject private var viewModel = userManagerViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var url: URL? = nil
    @StateObject private var settingsVm = SettingViewModel()
    
    var body: some View {
        VStack(spacing: 36) {
            Text("Email Address")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .padding(.top, 16)
            
            if let user = viewModel.user {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .padding(.bottom, 8)
                    Text(user.email ?? "No data")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Button(action: {
                        Task {
                            try? await settingsVm.updateEmail(email: user.email ?? "")
                        }
                    }) {
                        Label("Change my email address", systemImage: "pencil")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
                .frame(maxWidth: 350)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 12, y: 4)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
            Spacer()
        }
        .padding()
        .task {
            try? await viewModel.loadCurrentUser()
        }
    }
}


struct ShowEmailAdressView_Previews: PreviewProvider {
    static var previews: some View {
        ShowEmailAdressView()
    }
}

