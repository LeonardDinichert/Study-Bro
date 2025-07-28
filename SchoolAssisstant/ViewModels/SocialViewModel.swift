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
            guard let friendIds = me?.dictionary["friends"] as? [String] else {
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
            guard let pendingIds = me?.dictionary["pendingFriends"] as? [String] else {
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
        // Implementation of notification sending
    }
}
