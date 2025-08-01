import Foundation
import FirebaseFirestore

struct TaskItem: Codable, Identifiable {
    var id: String?
  
    var title: String
    var dueDate: Date
    var completed: Bool
    var createdAt: Date

    init(id: String? = nil, title: String, dueDate: Date, completed: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.completed = completed
        self.createdAt = createdAt
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let title = data["title"] as? String,
              let dueTS = data["dueDate"] as? Timestamp,
              let completed = data["completed"] as? Bool,
              let createdTS = data["createdAt"] as? Timestamp else { return nil }

        self.id = document.documentID
        self.title = title
        self.dueDate = dueTS.dateValue()
        self.completed = completed
        self.createdAt = createdTS.dateValue()
    }

    var dictionary: [String: Any] {
        [
            "title": title,
            "dueDate": Timestamp(date: dueDate),
            "completed": completed,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
