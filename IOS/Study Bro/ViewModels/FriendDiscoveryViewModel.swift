import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class FriendDiscoveryViewModel: ObservableObject {
    @Published var users: [DBUser] = []
    @Published var searchText: String = ""

    var filteredUsers: [DBUser] {
        guard !searchText.isEmpty else { return users }
        return users.filter { ($0.username ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    func loadUsers() async {
        do {
            let fetched = try await UserManager.shared.getAllUsers()
            if let current = Auth.auth().currentUser?.uid {
                users = fetched.filter { $0.userId != current }
            } else {
                users = fetched
            }
        } catch {
            print("Failed to load users: \(error)")
            users = []
        }
    }

    func sendRequest(
        to user: DBUser, userId: String,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {


        let db = Firestore.firestore()
        let theirDoc = UserManager.shared.userDocument(userId: user.userId)
        let myDoc    = UserManager.shared.userDocument(userId: userId)

        // 2. Batch both updates together
        let batch = db.batch()
        batch.updateData([
            "pendingFriends": FieldValue.arrayUnion([userId])
        ], forDocument: theirDoc)
        batch.updateData([
            "sentFriendRequests": FieldValue.arrayUnion([user.userId])
        ], forDocument: myDoc)

        // 3. Commit
        batch.commit { error in
            if let error = error {
                print("❌ Failed to send friend request:", error.localizedDescription)
                completion(.failure(error))
            } else {
                print("✅ Friend request sent!")
                completion(.success(()))
            }
        }
    }
}
