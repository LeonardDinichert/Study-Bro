import Foundation
import FirebaseAuth

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [LearningNote] = []
    @Published var dueNotes: [LearningNote] = []

    func loadNotes() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            notes = try await NotesManager.shared.fetchNotes(userId: userId)
            dueNotes = notes.filter { $0.nextReview <= Date() }
        } catch {
            print("Error loading notes: \(error)")
        }
    }

    func delete(note: LearningNote) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let id = note.id else { return }
        do {
            try await NotesManager.shared.deleteNote(id, userId: userId)
            await loadNotes()
        } catch {
            print("Failed to delete note: \(error)")
        }
    }

    func markReviewed(note: LearningNote) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let id = note.id else { return }

        let newCount = note.reviewCount + 1
        let intervals = [1, 3, 7, 14, 30]
        var days = intervals.last!
        if newCount <= intervals.count {
            days = intervals[newCount - 1]
        } else {
            let extra = newCount - intervals.count
            days = intervals.last! * Int(pow(2.0, Double(extra)))
        }
        let next = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        do {
            try await NotesManager.shared.updateReview(noteId: id, userId: userId, reviewCount: newCount, nextReview: next)
            await loadNotes()
        } catch {
            print("Failed to update note: \(error)")
        }
    }
}
