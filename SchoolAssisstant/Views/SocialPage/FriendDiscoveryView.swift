import SwiftUI

struct FriendDiscoveryView: View {
    @StateObject private var viewModel = FriendDiscoveryViewModel()
    let userId: String

    var body: some View {
        List {
            ForEach(viewModel.filteredUsers, id: \.id) { user in
                HStack {
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
        .navigationTitle("Friend Discovery")
        .searchable(text: $viewModel.searchText)
        .task { await viewModel.loadUsers() }
    }
}

#Preview {
    FriendDiscoveryView(userId: "")
}
