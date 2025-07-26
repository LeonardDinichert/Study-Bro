//
//  UserWantsToAddInfoView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 26.05.2025.
//

import SwiftUI
import FirebaseAuth
import UserNotifications


struct AddNoteView: View {
    @State private var category = ""
    @State private var learned = ""
    enum Importance: String, CaseIterable, Identifiable {
        case low = "Low", medium = "Medium", high = "High"
        var id: String { rawValue }
    }
    @State private var importance: Importance = .low
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")
                            .font(.callout)
                            .foregroundStyle(.secondary)) {
                    TextField("Enter a category", text: $category)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                }

                Section(header: Text("What did you learn?")
                            .font(.callout)
                            .foregroundStyle(.secondary)) {
                    TextField("Describe it here", text: $learned)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }

                Section(header: Text("Importance")
                            .font(.callout)
                            .foregroundStyle(.secondary)) {
                    Picker(selection: $importance) {
                        ForEach(Importance.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    } label: {
                        Label("Importance", systemImage: "flag.fill")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)  // subtle depth :contentReference[oaicite:9]{index=9}
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Button {
                    Task { await save() }
                } label: {
                    Label("Save Note", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .cancel) {
                    isPresented = false
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationTitle("Add New Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    func save() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isPresented = false
            return
        }

        let now = Date()
        let note = LearningNote(
            category: category,
            text: learned,
            importance: importance.rawValue,
            reviewCount: 0,
            nextReview: Calendar.current.date(byAdding: .day, value: 1, to: now)!,
            createdAt: now
        )

        do {
            try await NotesManager.shared.addNote(note, userId: userId)
            scheduleNotifications(for: note)
            isPresented = false
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    /// Schedules “Do you remember?” with the note text at a series of spaced intervals.
    private func scheduleNotifications(for note: LearningNote) {
        let center = UNUserNotificationCenter.current()
        let offsets: [(value: Int, component: Calendar.Component)] = [
            (1, .day),
            (4, .day),
            (8, .day),
            (1, .month),
            (4, .month)
        ]

        for (index, offset) in offsets.enumerated() {
            guard
                let fireDate = Calendar.current.date(
                    byAdding: offset.component,
                    value: offset.value,
                    to: note.createdAt
                )
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Do you remember?"
            content.body = note.text
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let request = UNNotificationRequest(
                identifier: "note-\(note.createdAt.timeIntervalSince1970)-\(index)",
                content: content,
                trigger: trigger
            )
            
            print("Change the note.text to an autoformulated question made by ai")

            center.add(request) { error in
                if let err = error {
                    print("🔔 Notification error: \(err)")
                }
            }
        }
    }

}

#Preview {
    AddNoteView(isPresented: .constant(true))
}
