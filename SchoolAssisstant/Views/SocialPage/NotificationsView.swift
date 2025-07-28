import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        List {
            if viewModel.incomingRequests.isEmpty {
                Text("No pending requests")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.incomingRequests, id: \.id) { user in
                    HStack {
                        Text(user.username ?? "no username")
                        Spacer()
                        Button("Accept") {
                            Task { try await viewModel.acceptFriendRequest(from: user) }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Decline") {
                            Task { try await viewModel.declineFriendRequest(from: user) }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .task { await viewModel.loadPendingRequests() }
    }
}

#Preview {
    NotificationsView()
}
