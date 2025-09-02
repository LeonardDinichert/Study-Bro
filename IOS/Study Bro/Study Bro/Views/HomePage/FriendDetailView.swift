import SwiftUI

struct FriendDetailView: View {
    let friend: DBUser

    @State private var trophies: [String] = []
    @State private var streak: Int? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image
                if let urlString = friend.profileImagePathUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(width: 100, height: 100)
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .glassEffect()
                        case .failure(_):
                            Image(systemName: "person.crop.circle").resizable()
                                .frame(width: 100, height: 100)
                        @unknown default:
                            Image(systemName: "person.crop.circle").resizable()
                                .frame(width: 100, height: 100)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                // Username
                Text(friend.username ?? "No username")
                    .font(.title2).fontWeight(.semibold)
                // First & Last Name
                Text("\(friend.firstName ?? "") \(friend.lastName ?? "")")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Divider()
                // Streak
                if let streak = streak {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("Streak: \(streak) days")
                            .font(.title3.weight(.semibold))
                    }
                } else {
                    ProgressView().frame(width: 24, height: 24)
                }
                Divider()
                // Trophies
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trophies:")
                        .font(.headline)
                    if trophies.isEmpty {
                        Text("No trophies yet").foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(trophies, id: \.self) { trophy in
                                    VStack {
                                        if trophy == "10_day_streak" {
                                            Image("10DaysStreakTrophie")
                                                .resizable().frame(width: 60, height: 60)
                                        } else if trophy == "15_day_streak" {
                                            Image("15DaysStreakTrophie")
                                                .resizable().frame(width: 60, height: 60)
                                        } else if trophy == "30_day_streak" {
                                            Image("30DaysStreakTrophie")
                                                .resizable().frame(width: 60, height: 60)
                                        }
                                        Text(trophy.replacingOccurrences(of: "_", with: " "))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding()
        }
        .navigationTitle(friend.username ?? "Friend")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadFriendTrophies()
                await loadFriendStreak()
            }
        }
    }

    // MARK: - Data Loading
    func loadFriendTrophies() async {
        do {
            let user = try await UserManager.shared.getUser(userId: friend.userId)
            await MainActor.run {
                self.trophies = user.trophies ?? []
            }
        } catch {
            // Handle error
        }
    }
    func loadFriendStreak() async {
        do {
            let s = try await UserManager.shared.calculateStreak(userId: friend.userId)
            await MainActor.run {
                self.streak = s
            }
        } catch {
            // Handle error
        }
    }
}

#Preview {
    FriendDetailView(friend: DBUser(userId: "preview", username: "PreviewUser", firstName: "John", lastName: "Doe", profileImagePathUrl: nil, trophies: ["10_day_streak"], lastConnection: Date()))
}
