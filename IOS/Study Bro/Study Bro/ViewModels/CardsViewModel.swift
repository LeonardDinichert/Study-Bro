import Foundation
import FirebaseAuth
import Combine

@MainActor
final class CardsViewModel: ObservableObject {
    @Published var sets: [StudySet] = []
    @Published var currentSet: StudySet?
    @Published var currentIndex: Int = 0
    @Published var isAutoplay: Bool = false

    private var timer: Timer?

    func loadSets() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            sets = try await StudySetManager.shared.fetchSets(userId: uid)
            if currentSet == nil {
                currentSet = sets.first
            }
        } catch {
            print("Failed to load sets: \(error)")
        }
    }

    func nextCard() {
        guard let set = currentSet else { return }
        currentIndex = (currentIndex + 1) % set.items.count
    }

    func previousCard() {
        guard let set = currentSet else { return }
        currentIndex = (currentIndex - 1 + set.items.count) % set.items.count
    }

    func shuffle() {
        guard var set = currentSet else { return }
        set.items.shuffle()
        currentSet = set
        currentIndex = 0
    }

    func toggleStar() async {
        guard var set = currentSet else { return }
        var item = set.items[currentIndex]
        item.starred.toggle()
        set.items[currentIndex] = item
        currentSet = set
        await saveCurrentSet()
    }

    func saveCurrentSet() async {
        guard let set = currentSet, let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await StudySetManager.shared.updateSet(set, userId: uid)
        } catch { print("Failed to save set: \(error)") }
    }

    func startAutoplay() {
        stopAutoplay()
        guard isAutoplay else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            if let self = self {
                Task { @MainActor in
                    self.nextCard()
                }
            }
        }
    }

    func stopAutoplay() {
        timer?.invalidate()
        timer = nil
    }
}

