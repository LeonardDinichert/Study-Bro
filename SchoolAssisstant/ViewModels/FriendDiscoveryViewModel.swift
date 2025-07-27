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

    func sendRequest(to user: DBUser) {
        guard let currentUser = UserManager.shared.currentUser else { return }
        let theirDoc = UserManager.shared.userDocument(userId: user.userId)
        theirDoc.updateData([
            "pendingFriends": FieldValue.arrayUnion([currentUser.userId])
        ])
    }
}
