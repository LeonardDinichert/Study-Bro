import SwiftUI

/// Dashboard showcasing Duolingo-style gamification elements.
struct GamificationView: View {
    @StateObject private var manager = GamificationManager.shared
    @State private var newFriendName: String = ""
    @State private var streakScale: CGFloat = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let message = manager.weeklyResult {
                        Text(message)
                            .font(.subheadline)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.2)))
                    }
                    streakSection
                    friendsSection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear {
                Task {
                    await manager.updateStreak()
                }
                manager.sortLeaderboard()
                manager.scheduleDailyReminder()
            }
        }
    }

    private var streakSection: some View {
        HStack {
            Image(systemName: "flame.fill").foregroundColor(.orange)
            Text("Streak: \(manager.streak)")
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1)))
        .scaleEffect(streakScale)
        .onChange(of: manager.streak) { oldValue, newValue in
            withAnimation(.spring()) { streakScale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) { streakScale = 1 }
            }
        }
    }

//    private var xpSection: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text("XP: \(manager.totalXP)")
//                    .font(.headline)
//                Spacer()
//                Text("Level \(manager.level)")
//                    .font(.subheadline)
//            }
//            ProgressView(value: Double(manager.dailyXP), total: Double(manager.dailyGoal))
//                .tint(.blue)
//            Text("Daily goal: \(manager.dailyXP)/\(manager.dailyGoal)")
//                .font(.caption)
//                .foregroundStyle(.secondary)
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.1)))
//    }



//    private var leaderboardSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Leaderboard")
//                .font(.headline)
//            ForEach(manager.leaderboard) { player in
//                HStack {
//                    Text(player.name)
//                    Spacer()
//                    Text("\(player.xp) XP")
//                }
//                .font(player.name == "You" ? .headline : .body)
//                .foregroundColor(player.name == "You" ? .blue : .primary)
//            }
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.1)))
//    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Friends")
                    .font(.headline)
                Spacer()
                TextField("Add friend", text: $newFriendName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 120)
                Button("Add") {
                    guard !newFriendName.isEmpty else { return }
                    manager.addFriend(name: newFriendName)
                    newFriendName = ""
                }
            }
            ForEach(manager.friends) { friend in
                HStack {
                    Text(friend.name)
                    Spacer()
                    Text("🔥\(friend.streak)  \(friend.xp) XP")
                }
            }
            if manager.friends.isEmpty {
                Text("Connect with friends to see their progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1)))
    }
}

#Preview {
    GamificationView()
}
