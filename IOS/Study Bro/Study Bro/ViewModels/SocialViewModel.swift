import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine


class FriendsViewModel: ObservableObject {
    @Published var friends: [DBUser] = []
    @Published var incomingRequests: [DBUser] = []
    @Published var friendsStreaks: [String: Int] = [:]
    
    @MainActor
    func load() async throws {
        guard let currentId = Auth.auth().currentUser?.uid else { return }
        do {
            let allUsers = try await UserManager.shared.getAllUsers()
            let me = allUsers.first(where: { $0.userId == currentId })
            let friendIds = me?.friends ?? []
            if friendIds.isEmpty {
                self.friends = []
                try await loadPendingRequests()
                return
            }
            let loadedFriends = allUsers.filter { friendIds.contains($0.userId) }
            self.friends = loadedFriends
            
            self.friendsStreaks = [:]
            for friend in loadedFriends {
                Task {
                    let streak = (try? await UserManager.shared.calculateStreak(userId: friend.userId)) ?? 0
                    await MainActor.run { [weak self] in
                        self?.friendsStreaks[friend.userId] = streak
                    }
                }
            }
            
            try await loadPendingRequests()
        } catch {
            print("Failed to load friends: \(error)")
            self.friends = []
            try await loadPendingRequests()
        }
    }
    
    @MainActor
    func loadPendingRequests() async throws {
        guard let currentId = Auth.auth().currentUser?.uid else { return }

        
        let snapshot = try await Firestore.firestore().collection("users")
            .whereField("sentFriendRequests", arrayContains: currentId)
            .getDocuments()
        print(snapshot)
        let users: [DBUser] = snapshot.documents.compactMap { document in
            try? document.data(as: DBUser.self)
        }
        
        self.incomingRequests = users

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

        try await load()
        try await loadPendingRequests()
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

        try await loadPendingRequests()
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

