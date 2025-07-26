import Foundation

import FirebaseFirestore

struct LearningNote: Codable, Identifiable {
    var id: String?

  let category: String
    let text: String
    let importance: String
    var reviewCount: Int
    var nextReview: Date
    let createdAt: Date
    init(id: String? = nil, category: String, text: String, importance: String, reviewCount: Int, nextReview: Date, createdAt: Date) {
        self.id = id
        self.category = category
        self.text = text
        self.importance = importance
        self.reviewCount = reviewCount
        self.nextReview = nextReview
        self.createdAt = createdAt
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let category = data["category"] as? String,
              let text = data["text"] as? String,
              let importance = data["importance"] as? String,
              let reviewCount = data["reviewCount"] as? Int,
              let nextReviewTS = data["nextReview"] as? Timestamp,
              let createdTS = data["createdAt"] as? Timestamp else { return nil }

        self.id = document.documentID
        self.category = category
        self.text = text
        self.importance = importance
        self.reviewCount = reviewCount
        self.nextReview = nextReviewTS.dateValue()
        self.createdAt = createdTS.dateValue()
    }

    var dictionary: [String: Any] {
        [
            "category": category,
            "text": text,
            "importance": importance,
            "reviewCount": reviewCount,
            "nextReview": Timestamp(date: nextReview),
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
