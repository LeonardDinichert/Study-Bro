import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialViewModel()
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.userMinutesToday > 0 {
                        Text("You've studied \(viewModel.userMinutesToday) min today")
                            .font(.headline)
                    }
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.friends) { friend in
                            FriendCard(friend: friend) {
                                viewModel.nudge(friend: friend.user)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .task { await viewModel.load() }
    }
}

struct FriendCard: View {
    let friend: FriendStats
    var nudgeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(friend.user.username ?? "Unknown")
                .font(.headline)
            Text(friend.lastLoginText)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Streak: \(friend.streak) d")
                .font(.caption)
            Text("Today: \(friend.minutesToday) min")
                .font(.caption)
            if friend.daysSinceLastLogin >= 2 {
                Button("Nudge", action: nudgeAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .cardStyle()
    }
}

#Preview {
    SocialView()
}
