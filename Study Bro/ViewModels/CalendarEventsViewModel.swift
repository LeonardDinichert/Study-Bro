import Foundation
import FirebaseAuth

@MainActor
final class CalendarEventsViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var notes: [LearningNote] = []

    func load() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            tasks = try await TaskManager.shared.fetchTasks(userId: userId)
            notes = try await NotesManager.shared.fetchNotes(userId: userId)
        } catch {
            print("Failed to load events: \(error)")
        }
    }

    private var calendar: Calendar { .current }

    func tasks(on date: Date) -> [TaskItem] {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    func notes(on date: Date) -> [LearningNote] {
        notes.filter { note in
            [note.firstReminderDate, note.secondReminderDate, note.thirdReminderDate,
             note.forthReminderDate, note.fifthReminderDate]
                .compactMap { $0 }
                .contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }

    func hasEvents(on date: Date) -> Bool {
        !tasks(on: date).isEmpty || !notes(on: date).isEmpty
    }
}
