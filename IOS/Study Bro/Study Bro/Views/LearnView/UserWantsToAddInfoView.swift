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
                    Section(header: Text("Category")
                        .font(.callout)
                        .foregroundStyle(.secondary)) {
                            
                            Picker("Category", selection: $category) {
                                ForEach(userCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                        )
                    
                    Section(header: Text("What did you learn?")
                        .font(.callout)
                        .foregroundStyle(.secondary)) {
                            TextEditor(text: $learned)
                                .frame(minHeight: 80, maxHeight: 160, alignment: .topLeading)
                                .scrollContentBackground(.hidden)
                                .autocorrectionDisabled(false)
                                .textInputAutocapitalization(.sentences)
                                .padding(.vertical, 6)
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
        .onAppear {
            Task { await loadUserCategories() }
        }
        .navigationTitle("Add New Info")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
            }
        } catch {
            print("Error loading user categories: \(error)")
        }
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
            isPresented = false
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

#Preview {
    AddNoteView(isPresented: .constant(true))
}
