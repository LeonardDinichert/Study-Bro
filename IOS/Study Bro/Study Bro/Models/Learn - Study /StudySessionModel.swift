//
//  StudySessionModel.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import Foundation
import FirebaseFirestore

struct StudySession: Identifiable, Codable {
    var id: String?
    let session_start: Date
    let session_end: Date
    let studied_subject: String

    var duration: TimeInterval {
        session_end.timeIntervalSince(session_start)
    }

    init(id: String? = nil, session_start: Date, session_end: Date, studied_subject: String) {
        self.id = id
        self.session_start = session_start
        self.session_end = session_end
        self.studied_subject = studied_subject
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let startTS = data["session_start"] as? Timestamp,
              let endTS = data["session_end"] as? Timestamp,
              let subject = data["studied_subject"] as? String else { return nil }

        self.id = document.documentID
        self.session_start = startTS.dateValue()
        self.session_end = endTS.dateValue()
        self.studied_subject = subject
    }
}
