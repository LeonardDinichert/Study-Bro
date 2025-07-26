import Foundation
import SwiftUI
import FirebaseAuth

struct FriendStats: Identifiable {
    let user: DBUser
    let streak: Int
    let minutesToday: Int
    var id: String { user.userId }
    
    var daysSinceLastLogin: Int {
        guard let last = user.lastConnection else { return 0 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
    }
    
    var lastLoginText: String {
        guard let last = user.lastConnection else { return "No data" }
        if Calendar.current.isDateInToday(last) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: last))"
        }
        let days = daysSinceLastLogin
        return days == 1 ? "1 day ago" : "\(days) days ago"
    }
}

@MainActor
final class SocialViewModel: ObservableObject {
    @Published var currentUser: DBUser?
    @Published var friends: [FriendStats] = []
    @Published var userMinutesToday: Int = 0
    
    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            currentUser = try await UserManager.shared.getUser(userId: uid)
            let userSessions = try await UserManager.shared.fetchStudySessions(userId: uid)
            userMinutesToday = Int(Self.minutesToday(from: userSessions))
            let users = try await UserManager.shared.getAllUsers()
            var temp: [FriendStats] = []
            for friend in users where friend.userId != uid {
                let sessions = try await UserManager.shared.fetchStudySessions(userId: friend.userId)
                let st = Self.streak(from: sessions)
                let min = Int(Self.minutesToday(from: sessions))
                temp.append(FriendStats(user: friend, streak: st, minutesToday: min))
            }
            friends = temp
        } catch {
            print("Failed to load social data: \(error)")
        }
    }
    
    func nudge(friend: DBUser) {
        guard let token = friend.fcmToken else { return }
        sendNotificationRequest(title: "Time to study!", body: "Let's work together", token: token)
    }
    
    private func sendNotificationRequest(title: String, body: String, token: String) {
        guard let url = URL(string: "https://us-central1-jobb-8f5e7.cloudfunctions.net/sendPushNotification") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData: [String: Any] = ["token": token, "title": title, "body": body]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
    
    private static func minutesToday(from sessions: [StudySession]) -> Double {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.session_start) }
            .reduce(0) { $0 + $1.duration / 60 }
    }
    
    private static func streak(from sessions: [StudySession]) -> Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.session_start) }).sorted(by: >)
        guard let first = days.first else { return 0 }
        var count = 1
        var prev = first
        for day in days.dropFirst() {
            if cal.dateComponents([.day], from: day, to: prev).day == 1 {
                count += 1
                prev = day
            } else if day == prev {
                continue
            } else {
                break
            }
        }
        return count
    }
}
