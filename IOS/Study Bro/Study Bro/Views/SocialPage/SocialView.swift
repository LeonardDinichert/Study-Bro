import SwiftUI
import UserNotifications

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var lastNotifiedRequests: Set<String> = [] // userIds of last notified
    let userId: String
    var body: some View {
            
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                    ForEach(viewModel.friends, id: \.id) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                            VStack(spacing: 6) {
                                if let urlString = friend.profileImagePathUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 56, height: 56)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 56, height: 56)
                                                .clipShape(Circle())
                                        case .failure(_):
                                            Image(systemName: "person.crop.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 56, height: 56)
                                        @unknown default:
                                            Image(systemName: "person.crop.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 56, height: 56)
                                        }
                                    }
                                    
                                }
                                else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 56, height: 56)
                                }
                                
                                Text(friend.username ?? "no username")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                if let streak = viewModel.friendsStreaks[friend.id] {
                                    Text("🔥 \(streak)")
                                        .foregroundColor(AppTheme.primaryColor)
                                        .font(.footnote)
                                } else {
                                    Text("...")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .glassEffect()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View details for \(friend.username ?? "friend")")
                    }
                }
                .padding()
            }
        
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

#Preview {
    FriendsView(userId: "previewUser")
}
