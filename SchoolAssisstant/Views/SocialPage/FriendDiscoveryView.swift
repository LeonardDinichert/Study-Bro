import SwiftUI

struct FriendDiscoveryView: View {
    @StateObject private var viewModel = FriendDiscoveryViewModel()

    var body: some View {
        List {
            ForEach(viewModel.filteredUsers, id: \.id) { user in
                HStack {
                    Text(user.username ?? "no username")
                    Spacer()
                    Button("Add") {
                        viewModel.sendRequest(to: user)
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
    FriendDiscoveryView()
}
