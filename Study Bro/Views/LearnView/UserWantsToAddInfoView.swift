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
            VStack {
                Form {
                    Section(header: Text("Category")
                        .font(.callout)
                        .foregroundStyle(.secondary)) {
                            
                            Picker("Category", selection: $category) {
                                Text("All").tag("All")
                                Text("Math").tag("Math")
                                Text("French").tag("French")
                                Text("English").tag("English")
                            }
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                        )
                    
                    Section(header: Text("What did you learn?")
                        .font(.callout)
                        .foregroundStyle(.secondary)) {
                            TextField("Describe it here", text: $learned)
                                .textInputAutocapitalization(.sentences)
                                .submitLabel(.done)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                        )
                    
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
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
                )
                .padding([.horizontal, .top], 18)
                .animation(.smooth, value: category + learned + String(describing: importance))
                
                Spacer(minLength: 16)
                
                VStack(spacing: 12) {
                    Button {
                        Task { await save() }
                    } label: {
                        Label("Save Note", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .secondary.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .padding([.horizontal, .bottom], 24)
            }
            .background(.ultraThinMaterial)
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
        let offsets: [(value: Int, component: Calendar.Component)] = [
            (1, .day),
            (4, .day),
            (8, .day),
            (1, .month),
            (4, .month)
        ]

        let reminderDates = offsets.compactMap { offset in
            Calendar.current.date(byAdding: offset.component, value: offset.value, to: now)
        }

        let note = LearningNote(
            category: category,
            text: learned,
            importance: importance.rawValue,
            reviewCount: 0,
            nextReview: reminderDates.first ?? now,
            createdAt: now,
            firstReminderDate: reminderDates.count > 0 ? reminderDates[0] : nil,
            secondReminderDate: reminderDates.count > 1 ? reminderDates[1] : nil,
            thirdReminderDate: reminderDates.count > 2 ? reminderDates[2] : nil,
            forthReminderDate: reminderDates.count > 3 ? reminderDates[3] : nil,
            fifthReminderDate: reminderDates.count > 4 ? reminderDates[4] : nil
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
        let reminderDates: [Date?] = [
            note.firstReminderDate,
            note.secondReminderDate,
            note.thirdReminderDate,
            note.forthReminderDate,
            note.fifthReminderDate
        ]

        for (index, fireDate) in reminderDates.enumerated() {
            guard let fireDate = fireDate else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Time to revise :"
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
