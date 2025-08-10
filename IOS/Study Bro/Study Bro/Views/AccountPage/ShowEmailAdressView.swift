//
//  ShowEmailAdressView.swift
//
//
//  Created by Léonard Dinichert on 10.04.25
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
        VStack {
            Text("Email adress :")
                .font(.title3)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            
            if let user = viewModel.user {
                Text(user.email ?? "No data")
                
                Button(action: {
                    Task {
                        try await settingsVm.updateEmail(email: user.email ?? "")
                    }
                }) {
                    Text("Change my email adress")
                }
                .buttonStyle(.borderedProminent)
            }
        }
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

