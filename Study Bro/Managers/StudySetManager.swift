import Foundation
import FirebaseFirestore

final class StudySetManager {
    static let shared = StudySetManager()
    private init() {}

    // MARK: - Collection references
    private var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    private func setsCollection(userId: String) -> CollectionReference {
        userCollection.document(userId).collection("study_sets")
    }

    // MARK: - CRUD
    func createSet(_ set: StudySet, userId: String) async throws -> String {
        let ref = try await setsCollection(userId: userId).addDocument(data: set.dictionary)
        return ref.documentID
    }

    func updateSet(_ set: StudySet, userId: String) async throws {
        guard let id = set.id else { return }
        try await setsCollection(userId: userId).document(id).setData(set.dictionary, merge: true)
    }

    func deleteSet(_ id: String, userId: String) async throws {
        try await setsCollection(userId: userId).document(id).delete()
    }

    func fetchSets(userId: String) async throws -> [StudySet] {
        let snapshot = try await setsCollection(userId: userId).getDocuments()
        return snapshot.documents.compactMap { StudySet(document: $0) }
    }

    func fetchPublicSets() async throws -> [StudySet] {
        let snapshot = try await Firestore.firestore()
            .collectionGroup("study_sets")
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { StudySet(document: $0) }
    }
}
