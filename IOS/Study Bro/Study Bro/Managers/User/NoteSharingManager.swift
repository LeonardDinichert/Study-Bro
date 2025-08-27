import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

/// Model for a note share request
struct NoteShareRequest: Identifiable, Codable {
    var id: String { requestId }
    let requestId: String
    let senderId: String
    let senderName: String
    let recipientId: String
    let noteId: String
    let noteTitle: String
    let message: String?
    let sentAt: Date
    var accepted: Bool?
}

/// Manager for all note sharing actions
class NoteSharingManager: ObservableObject {
    static let shared = NoteSharingManager()
    private let db = Firestore.firestore()
    
    private func requestsCollection(senderId: String) -> CollectionReference {
        db.collection("users").document(senderId).collection("sent_note_requests")
    }
    private func incomingCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("received_note_requests")
    }

    /// Sends a note share request to a friend
    func sendNoteShare(to recipient: DBUser, noteId: String, noteTitle: String, message: String?) async throws {
        guard let sender = try? await UserManager.shared.getUser(userId: Auth.auth().currentUser?.uid ?? "") else { return }
        let requestId = UUID().uuidString
        let now = Date()
        let share = NoteShareRequest(requestId: requestId, senderId: sender.userId, senderName: sender.username ?? "Unknown", recipientId: recipient.userId, noteId: noteId, noteTitle: noteTitle, message: message, sentAt: now, accepted: nil)
        let shareData = try Firestore.Encoder().encode(share)
        // Write to both sender and recipient for easy querying
        try await requestsCollection(senderId: sender.userId).document(requestId).setData(shareData)
        try await incomingCollection(userId: recipient.userId).document(requestId).setData(shareData)
    }
    /// Fetches all incoming note requests for a user
    func fetchIncomingRequests(for userId: String) async throws -> [NoteShareRequest] {
        let snap = try await incomingCollection(userId: userId).order(by: "sentAt", descending: true).getDocuments()
        return snap.documents.compactMap { doc in
            try? doc.data(as: NoteShareRequest.self)
        }
    }
    /// Marks a request as accepted (updates both sender and recipient doc)
    func acceptNoteShare(request: NoteShareRequest) async throws {
        try await updateShareRequestStatus(request: request, accepted: true)
    }
    /// Marks a request as ignored (updates both sender and recipient doc)
    func ignoreNoteShare(request: NoteShareRequest) async throws {
        try await updateShareRequestStatus(request: request, accepted: false)
    }
    private func updateShareRequestStatus(request: NoteShareRequest, accepted: Bool) async throws {
        let update: [String: Any] = ["accepted": accepted]
        try await requestsCollection(senderId: request.senderId).document(request.requestId).updateData(update)
        try await incomingCollection(userId: request.recipientId).document(request.requestId).updateData(update)
    }
}

