import Foundation
import FirebaseAuth
import UserNotifications

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var title: String = ""
    @Published var dueDate: Date = Date()

    func loadTasks() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            tasks = try await TaskManager.shared.fetchTasks(userId: userId)
        } catch {
            print("Error loading tasks: \(error)")
        }
    }

    func addTask() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let task = TaskItem(title: title,
                            dueDate: dueDate,
                            completed: false,
                            createdAt: Date())
        do {
            try await TaskManager.shared.addTask(task, userId: userId)
            NotificationManager.scheduleNotification(title: "Task Due",
                                                     body: title,
                                                     at: dueDate)
            await loadTasks()
        } catch {
            print("Failed to add task: \(error)")
        }
    }

    func delete(task: TaskItem) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let id = task.id else { return }
        do {
            try await TaskManager.shared.deleteTask(id, userId: userId)
            await loadTasks()
        } catch {
            print("Failed to delete task: \(error)")
        }
    }

    func toggleCompleted(_ task: TaskItem) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        var updated = task
        updated.completed.toggle()
        do {
            try await TaskManager.shared.updateTask(updated, userId: userId)
            await loadTasks()
        } catch {
            print("Failed to update task: \(error)")
        }
    }
}
