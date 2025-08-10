//
//  CHooseStudyBranches.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 29.07.2025.
//

import SwiftUI
import FirebaseFirestore

struct CHooseStudyBranches: View {
    @State private var selectedSubjects: Set<String> = []
    @State private var userId: String? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private let subjects = [
        // Languages
        "German", "French", "Italian", "Romansh",
        "English", "Latin", "Greek",
        "Spanish", "Russian", "Third national language",
        // Mathematics
        "Mathematics", "Applied Mathematics",
        // Natural Sciences
        "Biology", "Chemistry", "Physics", "Natural Sciences", "Computer Science",
        // Social Sciences & Humanities
        "Geography", "History", "Civics", "Economics and Law",
        "Philosophy", "Psychology", "Education",
        // Arts & Design
        "Visual Arts", "Music", "Design and Technology", "Technical Design",
        "Textile Design",
        // Practical & Elective
        "Home Economics", "Project Work",
        "Media Studies", "ICT",
        // Sport & Health
        "Physical Education", "Health",
        // Religion & Ethics
        "Religious Studies", "Ethics"
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                Text("Choose Your Subjects")
                    .font(.largeTitle).bold()
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(minimum: 160), spacing: 16)
                        ], spacing: 16) {
                            ForEach(subjects, id: \.self) { subject in
                                Button(action: {
                                    handleToggle(for: subject)
                                }) {
                                    HStack {
                                        Image(systemName: selectedSubjects.contains(subject) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(AppTheme.primaryColor)
                                            .font(.title2)
                                        Text(subject)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    .padding()
                                    .glassEffect()
                                }
                                .buttonStyle(.plain)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                }
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal)
        }
        .onAppear {
            loadUserIdAndSelections()
        }
    }
    
    private func loadUserIdAndSelections() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let id = try await UserManager.shared.loadCurrentUserId()
                await MainActor.run {
                    self.userId = id
                    self.isLoading = false
                }
                if let id = userId {
                    let doc = try await UserManager.shared.userDocument(userId: id).getDocument()
                    if let arr = doc.data()?["is_studying"] as? [String] {
                        await MainActor.run {
                            self.selectedSubjects = Set(arr)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleToggle(for subject: String) {
        guard let userId else { return }
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
        if selectedSubjects.contains(subject) {
            selectedSubjects.remove(subject)
            ref.updateData([
                "is_studying": FieldValue.arrayRemove([subject])
            ])
        } else {
            selectedSubjects.insert(subject)
            ref.updateData([
                "is_studying": FieldValue.arrayUnion([subject])
            ])
        }
    }
}

#Preview {
    CHooseStudyBranches()
}
