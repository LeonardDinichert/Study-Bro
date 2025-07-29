import Foundation
import FirebaseAuth

@MainActor
final class TrophiesViewModel: ObservableObject {
    @Published var trophies: [String] = []

    func load() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let user = try await UserManager.shared.getUser(userId: userId)
            trophies = user.trophies ?? []
        } catch {
            print("Failed to load trophies: \(error)")
        }
    }
}
