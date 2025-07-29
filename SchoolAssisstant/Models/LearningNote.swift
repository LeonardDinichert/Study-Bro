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
    var reminder_1: Bool
    var reminder_2: Bool
    var reminder_3: Bool
    var reminder_4: Bool
    var reminder_5: Bool
    var firstReminderDate: Date?
    var secondReminderDate: Date?
    var thirdReminderDate: Date?
    var fourthReminderDate: Date?
    var fifthReminderDate: Date?

    init(id: String? = nil, category: String, text: String, importance: String, reviewCount: Int, nextReview: Date, createdAt: Date) {
        self.id = id
        self.category = category
        self.text = text
        self.importance = importance
        self.reviewCount = reviewCount
        self.nextReview = nextReview
        self.createdAt = createdAt
        self.reminder_1 = false
        self.reminder_2 = false
        self.reminder_3 = false
        self.reminder_4 = false
        self.reminder_5 = false
        self.firstReminderDate = Calendar.current.date(byAdding: .day, value: 1, to: createdAt)
        self.secondReminderDate = Calendar.current.date(byAdding: .day, value: 4, to: createdAt)
        self.thirdReminderDate = Calendar.current.date(byAdding: .day, value: 8, to: createdAt)
        self.fourthReminderDate = Calendar.current.date(byAdding: .month, value: 1, to: createdAt)
        self.fifthReminderDate = Calendar.current.date(byAdding: .month, value: 4, to: createdAt)
    }

    init(id: String? = nil, category: String, text: String, importance: String, reviewCount: Int, nextReview: Date, createdAt: Date, reminder_1: Bool = false, reminder_2: Bool = false, reminder_3: Bool = false, reminder_4: Bool = false, reminder_5: Bool = false) {
        self.id = id
        self.category = category
        self.text = text
        self.importance = importance
        self.reviewCount = reviewCount
        self.nextReview = nextReview
        self.createdAt = createdAt
        self.reminder_1 = reminder_1
        self.reminder_2 = reminder_2
        self.reminder_3 = reminder_3
        self.reminder_4 = reminder_4
        self.reminder_5 = reminder_5
        self.firstReminderDate = Calendar.current.date(byAdding: .day, value: 1, to: createdAt)
        self.secondReminderDate = Calendar.current.date(byAdding: .day, value: 4, to: createdAt)
        self.thirdReminderDate = Calendar.current.date(byAdding: .day, value: 8, to: createdAt)
        self.fourthReminderDate = Calendar.current.date(byAdding: .month, value: 1, to: createdAt)
        self.fifthReminderDate = Calendar.current.date(byAdding: .month, value: 4, to: createdAt)
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

        self.reminder_1 = data["reminder_1"] as? Bool ?? false
        self.reminder_2 = data["reminder_2"] as? Bool ?? false
        self.reminder_3 = data["reminder_3"] as? Bool ?? false
        self.reminder_4 = data["reminder_4"] as? Bool ?? false
        self.reminder_5 = data["reminder_5"] as? Bool ?? false
        self.firstReminderDate = (data["firstReminderDate"] as? Timestamp)?.dateValue()
        self.secondReminderDate = (data["secondReminderDate"] as? Timestamp)?.dateValue()
        self.thirdReminderDate = (data["thirdReminderDate"] as? Timestamp)?.dateValue()
        self.fourthReminderDate = (data["fourthReminderDate"] as? Timestamp)?.dateValue()
        self.fifthReminderDate = (data["fifthReminderDate"] as? Timestamp)?.dateValue()
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "category": category,
            "text": text,
            "importance": importance,
            "reviewCount": reviewCount,
            "nextReview": Timestamp(date: nextReview),
            "createdAt": Timestamp(date: createdAt),
            "reminder_1": reminder_1,
            "reminder_2": reminder_2,
            "reminder_3": reminder_3,
            "reminder_4": reminder_4,
            "reminder_5": reminder_5
        ]

        if let firstReminderDate { dict["firstReminderDate"] = Timestamp(date: firstReminderDate) }
        if let secondReminderDate { dict["secondReminderDate"] = Timestamp(date: secondReminderDate) }
        if let thirdReminderDate { dict["thirdReminderDate"] = Timestamp(date: thirdReminderDate) }
        if let fourthReminderDate { dict["fourthReminderDate"] = Timestamp(date: fourthReminderDate) }
        if let fifthReminderDate { dict["fifthReminderDate"] = Timestamp(date: fifthReminderDate) }

        return dict
    }

    var reminderDates: [Date] {
        [firstReminderDate, secondReminderDate, thirdReminderDate, fourthReminderDate, fifthReminderDate]
            .compactMap { $0 }
    }
}
