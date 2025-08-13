import Foundation
import FirebaseAuth
import Combine

@MainActor
final class CalendarEventsViewModel: ObservableObject {
    @Published var notes: [LearningNote] = []

    func load() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            notes = try await NotesManager.shared.fetchNotes(userId: userId)
        } catch {
            print("Failed to load events: \(error)")
        }
    }

    private var calendar: Calendar { .current }

    func notes(on date: Date) -> [LearningNote] {
        notes.filter { note in
            [note.firstReminderDate, note.secondReminderDate, note.thirdReminderDate,
             note.forthReminderDate, note.fifthReminderDate]
                .compactMap { $0 }
                .contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }

    func hasEvents(on date: Date) -> Bool {
        !notes(on: date).isEmpty
    }
}
