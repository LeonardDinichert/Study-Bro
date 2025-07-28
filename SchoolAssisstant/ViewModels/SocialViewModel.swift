import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class FriendsViewModel: ObservableObject {
    @Published var friends: [DBUser] = []
    @Published var incomingRequests: [DBUser] = []

    @MainActor
    func load() async {
        guard let currentId = Auth.auth().currentUser?.uid else { return }
        do {
            let allUsers = try await UserManager.shared.getAllUsers()
            let me = allUsers.first(where: { $0.userId == currentId })
            let friendIds = me?.friends ?? []
            if friendIds.isEmpty {
                self.friends = []
                await loadPendingRequests()
                return
            }
            let loadedFriends = allUsers.filter { friendIds.contains($0.userId) }
            self.friends = loadedFriends
            await loadPendingRequests()
        } catch {
            print("Failed to load friends: \(error)")
            self.friends = []
            await loadPendingRequests()
        }
    }

    @MainActor
    func loadPendingRequests() async {
        guard let currentId = Auth.auth().currentUser?.uid else { return }
        do {
            let allUsers = try await UserManager.shared.getAllUsers()
            let me = allUsers.first(where: { $0.userId == currentId })
            let pendingIds = me?.pendingFriends ?? []
            if pendingIds.isEmpty {
                self.incomingRequests = []
                return
            }
            let requests = allUsers.filter { pendingIds.contains($0.userId) }
            self.incomingRequests = requests
        } catch {
            print("Failed to load pending requests: \(error)")
            self.incomingRequests = []
        }
    }

    @MainActor
    func acceptFriendRequest(from user: DBUser) async throws {
        guard let currentId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let myDoc = UserManager.shared.userDocument(userId: currentId)
        let theirDoc = UserManager.shared.userDocument(userId: user.userId)

        let batch = db.batch()
        batch.updateData([
            "pendingFriends": FieldValue.arrayRemove([user.userId]),
            "friends": FieldValue.arrayUnion([user.userId])
        ], forDocument: myDoc)
        batch.updateData([
            "sentFriendRequests": FieldValue.arrayRemove([currentId]),
            "friends": FieldValue.arrayUnion([currentId])
        ], forDocument: theirDoc)

        try await batch.commit()

        await load()
        await loadPendingRequests()
    }

    @MainActor
    func declineFriendRequest(from user: DBUser) async throws {
        guard let currentId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let myDoc = UserManager.shared.userDocument(userId: currentId)
        let theirDoc = UserManager.shared.userDocument(userId: user.userId)

        let batch = db.batch()
        batch.updateData([
            "pendingFriends": FieldValue.arrayRemove([user.userId])
        ], forDocument: myDoc)
        batch.updateData([
            "sentFriendRequests": FieldValue.arrayRemove([currentId])
        ], forDocument: theirDoc)

        try await batch.commit()

        await loadPendingRequests()
    }

    @MainActor
    func addFriend(user: DBUser) {
        guard let currentUser = UserManager.shared.currentUser else { return }
        let theirDoc = UserManager.shared.userDocument(userId: user.userId)
        theirDoc.updateData([
            "pendingFriends": FieldValue.arrayUnion([currentUser.userId])
        ])
        sendNotificationRequest(title: "New Friend Request", body: "You have a new friend request from \(currentUser.username ?? "someone")!", token: user.fcmToken ?? "no token")
    }

    func sendNotificationRequest(title: String, body: String, token: String) {
        guard let url = URL(string: "https://us-central1-jobb-8f5e7.cloudfunctions.net/sendPushNotification") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let bodyData: [String: Any] = [
            "token": token,
            "title": title,
            "body": body
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification request: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("Notification request sent successfully")
                } else {
                    print("Server error: \(httpResponse.statusCode)")
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("Error message: \(errorMessage)")
                    }
                }
            }
        }
        task.resume()
    }
}
