//
//  QuizViewModel.swift
//  Study Bro
//
//  Created by Léonard Dinichert on 15.08.2025.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine


@MainActor
final class QuizViewModel: ObservableObject {    
    
    @Published var pairs: [QAPair] = []
    @Published var loading = true
    @Published var error: String? = nil
    
    func loadAllPairs() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.loading = false
            self.error = "Not logged in."
            return
        }
        let db = Firestore.firestore()
        let notesColl = db.collection("users").document(uid).collection("learning_notes")
        do {
            let notes = try await notesColl.getDocuments().documents
            var allPairs: [QAPair] = []
            for note in notes {
                let sessions = try await notesColl.document(note.documentID)
                    .collection("sessions_on_note")
                    .whereField("has_been_revised", isEqualTo: false)
                    .getDocuments().documents
                for sess in sessions {
                    if let arr = sess.data()["pairs"] as? [[String: Any]] {
                        allPairs.append(contentsOf: arr.compactMap { QAPair(dict: $0) })
                    }
                }
            }
            self.pairs = allPairs
            self.loading = false
        } catch {
            self.loading = false
            self.error = error.localizedDescription
        }
    }
    
    /// Marks all sessions_on_note for the current user as revised by setting `has_been_revised` to true.
    /// This updates all sessions in the path users/<uid>/learning_notes/*/sessions_on_note/*.
    @MainActor
    func markSessionAsRevised() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Not logged in.")
            return
        }
        let db = Firestore.firestore()
        let notesColl = db.collection("users").document(uid).collection("learning_notes")
        do {
            let notes = try await notesColl.getDocuments().documents
            for note in notes {
                let sessionsColl = notesColl.document(note.documentID).collection("sessions_on_note")
                let sessions = try await sessionsColl.getDocuments().documents
                for sessionDoc in sessions {
                    do {
                        try await sessionsColl.document(sessionDoc.documentID).setData(["has_been_revised": true], merge: true)
                    } catch {
                        print("Error updating session \(sessionDoc.documentID): \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("Error marking sessions as revised: \(error.localizedDescription)")
        }
    }
}



struct QAPair: Identifiable, Hashable {
    let id: UUID
    var question: String
    var answer: String
    
    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
    
    init?(dict: [String: Any]) {
        guard let question = dict["question"] as? String, let answer = dict["answer"] as? String else { return nil }
        self.id = UUID()
        self.question = question
        self.answer = answer
    }
}
