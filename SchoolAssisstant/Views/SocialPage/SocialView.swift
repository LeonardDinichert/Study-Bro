import SwiftUI
import UserNotifications

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var lastNotifiedRequests: Set<String> = [] // userIds of last notified
    let userId: String
    var body: some View {
        VStack {

            if !viewModel.incomingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Friend Requests")
                        .font(.headline)
                    ForEach(viewModel.incomingRequests, id: \.id) { user in
                        HStack {
                            Text(user.username ?? "no username")
                            Spacer()
                            Button("Accept") {
                                Task {
                                    try await viewModel.acceptFriendRequest(from: user)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Decline") {
                                Task {
                                    try await viewModel.declineFriendRequest(from: user)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

//            if viewModel.friends.isEmpty {
//                NavigationLink("Find Friends") {
//                    FriendDiscoveryView(userId: userId)
//                }
//            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                ForEach(viewModel.friends, id: \.id) { friend in
                    VStack {
                        Text(friend.username ?? "no username")
                    }
                    .padding()
                    .background(Color(.systemBlue).opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .task {
            Task {
                try await viewModel.load()
                try await viewModel.loadPendingRequests()
                
                // Check for new incoming friend requests and show local notifications for new ones
                let currentSet = Set(viewModel.incomingRequests.map { $0.id })
                let newRequests = currentSet.subtracting(lastNotifiedRequests)
                for userId in newRequests {
                    if let user = viewModel.incomingRequests.first(where: { $0.id == userId }) {
                        let content = UNMutableNotificationContent()
                        content.title = "New Friend Request"
                        content.body = "You received a friend request from \(user.username ?? "no username")"
                        content.sound = .default
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        try await UNUserNotificationCenter.current().add(request)
                    }
                }
                lastNotifiedRequests = currentSet
            }
        }
    }
}
