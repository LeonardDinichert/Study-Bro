import Foundation
import FirebaseFirestore

final class NotesManager {
    static let shared = NotesManager()
    private init() {}

    private var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    private func notesCollection(userId: String) -> CollectionReference {
        userCollection.document(userId).collection("learning_notes")
    }

    func addNote(_ note: LearningNote, userId: String) async throws {
        try await notesCollection(userId: userId).addDocument(data: note.dictionary)
    }

    func fetchNotes(userId: String) async throws -> [LearningNote] {
        let snapshot = try await notesCollection(userId: userId).getDocuments()
        return snapshot.documents.compactMap { document in
            LearningNote(document: document)
        }
    }

    func deleteNote(_ noteId: String, userId: String) async throws {
        try await notesCollection(userId: userId).document(noteId).delete()
    }

    func updateReview(noteId: String, userId: String, reviewCount: Int, nextReview: Date) async throws {
        try await notesCollection(userId: userId).document(noteId).updateData([
            "reviewCount": reviewCount,
            "nextReview": nextReview
        ])
    }
}
