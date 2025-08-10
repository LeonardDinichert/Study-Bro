import SwiftUI

struct FriendDiscoveryView: View {
    @StateObject private var viewModel = FriendDiscoveryViewModel()
    let userId: String

    var body: some View {
        List {
            ForEach(viewModel.filteredUsers, id: \.id) { user in
                HStack {
                    if let urlString = user.profileImagePathUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing, 8)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .padding(.trailing, 8)
                    }
                    Text(user.username ?? "no username")
                    Spacer()
                    Button("Add") {
                        viewModel.sendRequest(to: user, userId: userId)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Find Friends")
        .searchable(text: $viewModel.searchText)
        .task { await viewModel.loadUsers() }
    }
}

#Preview {
    FriendDiscoveryView(userId: "")
}
