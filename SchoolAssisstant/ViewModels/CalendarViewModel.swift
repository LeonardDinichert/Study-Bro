import Foundation
import FirebaseAuth

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var notes: [LearningNote] = []

    func load() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            tasks = try await TaskManager.shared.fetchTasks(userId: userId)
            notes = try await NotesManager.shared.fetchNotes(userId: userId)
        } catch {
            print("Failed to load calendar data: \(error)")
        }
    }

    func tasks(on date: Date, calendar: Calendar) -> [TaskItem] {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    func notes(on date: Date, calendar: Calendar) -> [LearningNote] {
        notes.filter { note in
            note.reminderDates.contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }

    func hasEvent(on date: Date, calendar: Calendar) -> Bool {
        !tasks(on: date, calendar: calendar).isEmpty || !notes(on: date, calendar: calendar).isEmpty
    }
}
