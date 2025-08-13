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
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.15), Color.secondary.opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Profile Image Card
                    ZStack(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Group {
                                if let data = selectedImageData, let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.spring(), value: selectedImageData)
                                } else if let urlStr = user.profileImagePathUrl, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 140, height: 140)
                                    .shadow(radius: 8, y: 4)
                            )
                            .padding(.top, 24)
                        }
                        .onChange(of: selectedItem) { newItem, oldItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        // Edit (pencil) icon overlay
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "pencil").foregroundColor(.white))
                            .offset(x: 10, y: 10)
                            .shadow(radius: 4)
                    }
                    
                    // Card for text field and toggles
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.title3).bold()
                                .foregroundColor(.secondary)
                            TextField("Enter username", text: $username)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
                    .shadow(radius: 6, y: 2)
                    
                    // Save button
                    Button(action: { Task { await save() } }) {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Capsule().fill(Color.accentColor))
                            .foregroundColor(.white)
                            .shadow(radius: 3, y: 2)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .navigationTitle("Edit Profile")
                .onAppear {
                    username = user.username ?? ""
                }
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
