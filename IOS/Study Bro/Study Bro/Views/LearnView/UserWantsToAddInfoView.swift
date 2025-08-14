//
//  UserWantsToAddInfoView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import FirebaseAuth
import UserNotifications

struct AddNoteView: View {
    @State private var category = ""
    @State private var learned = ""
    @State private var userCategories: [String] = ["All"]

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
                    Section(header: Text("Category").font(.callout).foregroundStyle(.secondary)) {
                        Picker("Category", selection: $category) {
                            ForEach(userCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))

                    Section(header: Text("What did you learn?").font(.callout).foregroundStyle(.secondary)) {
                        TextEditor(text: $learned)
                            .frame(minHeight: 80, maxHeight: 160, alignment: .topLeading)
                            .scrollContentBackground(.hidden)
                            .autocorrectionDisabled(false)
                            .textInputAutocapitalization(.sentences)
                            .padding(.vertical, 6)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))

                    Section(header: Text("Importance").font(.callout).foregroundStyle(.secondary)) {
                        Picker(selection: $importance) {
                            ForEach(Importance.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        } label: {
                            Label("Importance", systemImage: "flag.fill")
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
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
            .navigationTitle("Add New Info")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task { await loadUserCategories() }
        }
    }

    // MARK: - Data
    private func loadUserCategories() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let user = try await UserManager.shared.getUser(userId: userId)
            await MainActor.run {
                if let studying = user.isStudying, !studying.isEmpty {
                    self.userCategories = ["All"] + studying
                } else {
                    self.userCategories = ["All"]
                }
                if self.category.isEmpty { self.category = self.userCategories.first ?? "" }
            }
        } catch {
            print("Error loading user categories: \(error)")
        }
    }

    // MARK: - Notifications
    private func getNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func ensureNotificationAuth() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await getNotificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            do { return try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
            catch { return false }
        }
    }

    private func scheduleLocalNotification(body: String, at date: Date, id: String) {
        let content = UNMutableNotificationContent()
        content.title = "Study Bro"
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func scheduleImmediate(body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = "Study Bro"
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Save
    func save() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isPresented = false
            return
        }

        let now = Date()
        let offsets: [(value: Int, component: Calendar.Component)] = [
            (1, .day),          // +1 day
            (4, .day),          // +4 days
            (1, .weekOfYear),   // +1 week
            (1, .month),        // +1 month
            (4, .month)         // +4 months
        ]
        let reminderDates = offsets.compactMap { Calendar.current.date(byAdding: $0.component, value: $0.value, to: now) }

        let note = LearningNote(
            category: category,
            text: learned,
            importance: importance.rawValue,
            reviewCount: 0,
            nextReview: reminderDates.first ?? now,
            createdAt: now,
        )

        do {
            try await NotesManager.shared.addNote(note, userId: userId)

            if await ensureNotificationAuth(),
               !learned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let baseId = "learningnote-\(userId)-\(now.timeIntervalSince1970)"
                scheduleImmediate(body: learned, id: "\(baseId)-now")
                for (idx, date) in reminderDates.enumerated() {
                    scheduleLocalNotification(body: learned, at: date, id: "\(baseId)-\(idx+1)")
                }
            }

            isPresented = false
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

#Preview {
    AddNoteView(isPresented: .constant(true))
}
