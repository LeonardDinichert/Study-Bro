import Foundation
import FirebaseFirestore

final class TaskManager {
    static let shared = TaskManager()
    private init() {}

    private var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    private func tasksCollection(userId: String) -> CollectionReference {
        userCollection.document(userId).collection("tasks")
    }

    func addTask(_ task: TaskItem, userId: String) async throws {
        try await tasksCollection(userId: userId).addDocument(data: task.dictionary)
    }

    func fetchTasks(userId: String) async throws -> [TaskItem] {
        let snapshot = try await tasksCollection(userId: userId).getDocuments()

        return snapshot.documents.compactMap { document in
            TaskItem(document: document)
        }
    }

    func updateTask(_ task: TaskItem, userId: String) async throws {
        guard let id = task.id else { return }

        try await tasksCollection(userId: userId).document(id).setData(task.dictionary, merge: true)
    }

    func deleteTask(_ id: String, userId: String) async throws {
        try await tasksCollection(userId: userId).document(id).delete()
    }
}
