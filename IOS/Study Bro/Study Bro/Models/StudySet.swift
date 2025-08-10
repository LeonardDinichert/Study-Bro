import Foundation
import FirebaseFirestore

struct StudyCardItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var term: String
    var definition: String
    var starred: Bool

    init(id: String = UUID().uuidString, term: String, definition: String, starred: Bool = false) {
        self.id = id
        self.term = term
        self.definition = definition
        self.starred = starred
    }

    init?(dictionary: [String: Any]) {
        guard let term = dictionary["term"] as? String,
              let definition = dictionary["definition"] as? String else { return nil }
        self.id = dictionary["id"] as? String ?? UUID().uuidString
        self.term = term
        self.definition = definition
        self.starred = dictionary["starred"] as? Bool ?? false
    }

    var dictionary: [String: Any] {
        [
            "id": id,
            "term": term,
            "definition": definition,
            "starred": starred
        ]
    }
}

struct StudySet: Codable, Identifiable {
    var id: String?
    var title: String
    var owner: String
    var isPublic: Bool
    var items: [StudyCardItem]

    init(id: String? = nil, title: String, owner: String, isPublic: Bool = false, items: [StudyCardItem]) {
        self.id = id
        self.title = title
        self.owner = owner
        self.isPublic = isPublic
        self.items = items
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let title = data["title"] as? String,
              let owner = data["owner"] as? String,
              let itemsData = data["items"] as? [[String: Any]] else { return nil }
        self.id = document.documentID
        self.title = title
        self.owner = owner
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.items = itemsData.compactMap { StudyCardItem(dictionary: $0) }
    }

    var dictionary: [String: Any] {
        [
            "title": title,
            "owner": owner,
            "isPublic": isPublic,
            "items": items.map { $0.dictionary }
        ]
    }
}
