import SwiftUI
import PhotosUI

struct EditProfileView: View {
    var user: DBUser
    @State private var username: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @StateObject private var viewModel = userManagerViewModel()
    
    init(user: DBUser) {
        self.user = user
        _viewModel = StateObject(wrappedValue: userManagerViewModel())
      }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let data = selectedImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let urlStr = user.profileImagePathUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                    }
                }
                .onChange(of: selectedItem) { newItem, oldItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }

                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                Toggle("Dark Mode", isOn: $viewModel.useDarkMode)
                    .padding(.vertical)

                Button("Save") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .onAppear {
                username = user.username ?? ""
            }
        }
    }

    func save() async {
        if let data = selectedImageData {
            try? await viewModel.saveProfileImage(data: data, userId: user.userId)
        }
        if username != user.username {
            try? await UserManager.shared.updateUsername(userId: user.userId, username: username)
        }
    }
}
