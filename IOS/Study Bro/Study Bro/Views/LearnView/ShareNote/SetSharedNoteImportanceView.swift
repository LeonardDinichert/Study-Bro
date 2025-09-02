import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation

struct SetSharedNoteImportanceView: View {
    let shareRequest: NoteShareRequest
    let onComplete: () -> Void

    @State private var selectedImportance: Importance = .low
    @State private var firstReviewDate: Date = Date().addingTimeInterval(60*60*24) // Default: 1 day from now
    @State private var isSaving = false
    @State private var error: String? = nil

    enum Importance: String, CaseIterable, Identifiable {
        case low = "Low", medium = "Medium", high = "High"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Importance")) {
                    Picker("Importance", selection: $selectedImportance) {
                        ForEach(Importance.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Set First Review Date")) {
                    DatePicker("First Review", selection: $firstReviewDate, displayedComponents: .date)
                }
                if let error = error {
                    Text(error).foregroundColor(.red)
                }
                Button("Save & Continue") {
                    Task { await save() }
                }
                .disabled(isSaving)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Set Note Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete() }
                }
            }
        }
    }

    private func save() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = "User not found"
            return
        }
        isSaving = true
        error = nil

        do {
            let senderNoteRef = Firestore.firestore()
                .collection("users")
                .document(shareRequest.senderId)
                .collection("learning_notes")
                .document(shareRequest.noteId)

            let snapshot = try await senderNoteRef.getDocument()
            guard let senderNoteData = snapshot.data() else {
                error = "Original note not found"
                isSaving = false
                return
            }

            // Compute review intervals based on importance
            let offsets: [TimeInterval]
            switch selectedImportance {
            case .high:
                offsets = [0.0, 6.0*24.0*60.0*60.0, 29.0*24.0*60.0*60.0, 89.0*24.0*60.0*60.0, 179.0*24.0*60.0*60.0] // 0d, 6d, 29d, 89d, 179d
            case .medium:
                offsets = [0.0, 6.0*24.0*60.0*60.0, 29.0*24.0*60.0*60.0] // 0d, 6d, 29d
            case .low:
                offsets = [0.0, 6.0*24.0*60.0*60.0] // 0d, 6d
            }

            let reminderDates = offsets.map { Calendar.current.date(byAdding: .second, value: Int($0), to: firstReviewDate) ?? firstReviewDate }

            var newNoteData = senderNoteData
            // Override fields with selected values
            newNoteData["importance"] = selectedImportance.rawValue
            newNoteData["nextReview"] = Timestamp(date: firstReviewDate)
            newNoteData["reviewCount"] = 0
            newNoteData["reminder_1"] = false
            newNoteData["reminder_2"] = false
            newNoteData["reminder_3"] = false
            newNoteData["reminder_4"] = false
            newNoteData["reminder_5"] = false

            if reminderDates.indices.contains(0) { newNoteData["firstReminderDate"] = Timestamp(date: reminderDates[0]) }
            if reminderDates.indices.contains(1) { newNoteData["secondReminderDate"] = Timestamp(date: reminderDates[1]) }
            if reminderDates.indices.contains(2) { newNoteData["thirdReminderDate"] = Timestamp(date: reminderDates[2]) }
            if reminderDates.indices.contains(3) { newNoteData["forthReminderDate"] = Timestamp(date: reminderDates[3]) }
            if reminderDates.indices.contains(4) { newNoteData["fifthReminderDate"] = Timestamp(date: reminderDates[4]) }

            let recipientNoteRef = Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("learning_notes")
                .document(UUID().uuidString)

            try await recipientNoteRef.setData(newNoteData)

            isSaving = false
            onComplete()
        } catch {
            self.error = error.localizedDescription
            self.isSaving = false
        }
    }
}
