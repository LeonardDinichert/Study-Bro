//
//  LearnedSomethingView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct LearnedSomethingView: View {
    let deepLinkNoteID: String?
    let reminderNumber: Int

    @StateObject private var viewModel = NotesViewModel()
    @StateObject private var noteShareVM = NoteSharingViewModel()
    @State private var didHandleDeepLink = false
    
    @State private var userWantsToRevise = false
    @State private var userWantsAddInfo = false
    @State private var selectedCategory: String = "All"
    @State private var userCategories: [String] = ["All"]
    
    @State private var selectedNote: LearningNote? = nil
    
    @State private var showQuickQuizPopup = false
    @State private var quizWrongAnswer: String? = nil
    @State private var quizAnsweredCorrectly = false
    @State private var quizDismissAfterWrong = false
    @State private var quizAnswerText: String = ""
    
    @State private var showIncomingShares = false
    
    @State private var lastAcceptedNoteId: String? = nil
    @State private var showSetImportanceSheet: Bool = false



    
    @Environment(\.scenePhase) private var scenePhase
    
    init(deepLinkNoteID: String? = nil, reminderNumber: Int = 0) {
        self.deepLinkNoteID = deepLinkNoteID
        self.reminderNumber = reminderNumber
    }
    
    private var filteredNotes: [LearningNote] {
        if selectedCategory == "All" {
            return viewModel.notes
        } else {
            return viewModel.notes.filter { $0.category == selectedCategory }
        }
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
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]
    
//    private var flashcardDeck: Deck? {
//        let cards = filteredNotes.map { note in
//            Card(
//                id: note.id ?? UUID().uuidString,
//                front: note.category,          // or a question/title if you have one
//                back: note.text,               // the answer
//                imageURL: nil,
//                audioLangCode: nil,
//                tags: [note.category],
//                isStarred: false
//            )
//        }
//        return cards.isEmpty ? nil : Deck(
//            id: "deck-\(selectedCategory)",
//            title: "Review • \(selectedCategory)",
//            cards: cards
//        )
//    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Header card with vibrant gradient background
                    VStack(spacing: 12) {
                        HStack {
                            Text("Your notes : ")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(userCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.automatic)
                        .accessibilityLabel("Select category")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(colors: [.accentColor, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                    )
                    .padding(.horizontal, 20)
                    .animation(.smooth, value: selectedCategory)
                    
                    // Notes grid or empty state
                    if filteredNotes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "note.text.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            Text("No notes found.")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.secondary)
                            Text("Add some notes to get started learning!")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .animation(.smooth, value: filteredNotes.isEmpty)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(filteredNotes) { note in
                                    NoteCardView(note: note)
                                        .onTapGesture {
                                            selectedNote = note
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await viewModel.delete(note: note) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityAddTraits(.isButton)
                                        .animation(.smooth, value: viewModel.notes.count)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 80) // spacing for floating button
                        }
                        .animation(.smooth, value: filteredNotes)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.smooth, value: userWantsAddInfo || userWantsToRevise)
                
                // Floating Add Note button bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { userWantsAddInfo = true }) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: Color.accentColor.opacity(0.6), radius: 10, x: 0, y: 4)
                                .accessibilityLabel("Add a new note")
                        }
                        .padding(.bottom, 32)
                        .padding(.trailing, 24)
                        .contentShape(Circle())
                        .animation(.smooth, value: userWantsAddInfo)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showIncomingShares = true
                    } label: {
                        Image(systemName: "envelope.open")
                    }
                    .accessibilityLabel("Incoming Shared Notes")
                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    if let deck = flashcardDeck {
//                        NavigationLink {
//                            FlashcardStackView(deck: deck)
//                        } label: {
//                            Image(systemName: "rectangle.on.rectangle")
//                        }
//                    } else {
//                        Image(systemName: "rectangle.on.rectangle").foregroundStyle(.secondary)
//                            .accessibilityLabel("Flashcards")
//                    }
//                }
            }
            // DetailNoteView sheet for selected note
            .sheet(item: $selectedNote) { note in
                DetailNoteView(note: note)
                    .background(.regularMaterial)
            }
            .sheet(isPresented: $showQuickQuizPopup) {
                QuickQuizPopup(note: selectedNote, isPresented: $showQuickQuizPopup, wrongAnswer: $quizWrongAnswer, answeredCorrectly: $quizAnsweredCorrectly, dismissAfterWrong: $quizDismissAfterWrong, answerText: $quizAnswerText, onWrongAnswer: { note in
                    // Schedule notification for next day
                    if let note = note, let noteId = note.id, let userId = Auth.auth().currentUser?.uid {
                        let content = UNMutableNotificationContent()
                        content.title = "Study Bro"
                        content.body = note.text
                        content.sound = .default
                        let date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
                        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                        let req = UNNotificationRequest(identifier: "retry-\(noteId)-\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(req)
                    }
                })
            }
            .sheet(isPresented: $showIncomingShares) {
                IncomingSharedNotesView(viewModel: noteShareVM, lastAcceptedNoteId: $lastAcceptedNoteId, showIncomingShares: $showIncomingShares, showSetImportanceSheet: $showSetImportanceSheet)
            }
            
            .sheet(isPresented: $showSetImportanceSheet) {
                if let noteId = lastAcceptedNoteId, let shareRequest = noteShareVM.incomingRequests.first(where: { $0.noteId == noteId }) {
                    SetSharedNoteImportanceView(shareRequest: shareRequest) {
                        showSetImportanceSheet = false
                        lastAcceptedNoteId = nil
                    }
                }
            }
        }
        .onAppear {
            Task { await loadUserCategories() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await loadUserCategories() }
            }
        }
        // Modals
        .fullScreenCover(isPresented: $userWantsAddInfo) {
            AddNoteView(isPresented: $userWantsAddInfo)
                .background(.regularMaterial)
        }
        .fullScreenCover(isPresented: $userWantsToRevise) {
            UserWantsToReviseView().onDisappear { userWantsToRevise = false }
                .background(.regularMaterial)
        }
        .task {
            await viewModel.loadNotes()
            await loadUserCategories()
            await noteShareVM.loadIncoming()
            if let id = deepLinkNoteID, !didHandleDeepLink, let note = viewModel.notes.first(where: { $0.id == id }) {
                selectedNote = note
                didHandleDeepLink = true
                showQuickQuizPopup = true
                
                // Deep link reminder update:
                // Mark the appropriate reminder_x field as true in Firestore for this note
                if let userId = Auth.auth().currentUser?.uid, let noteId = note.id, (1...5).contains(reminderNumber) {
                    let noteRef = Firestore.firestore().collection("users").document(userId).collection("learning_notes").document(noteId)
                    let field = "reminder_\(reminderNumber)"
                    Task {
                        do {
                            try await noteRef.setData([field: true], merge: true)
                        } catch {
                            print("Failed to update \(field): \(error)")
                        }
                    }
                }
            }
        }
    }
}

private struct NoteCardView: View {
    let note: LearningNote
    @State private var flameScale: CGFloat = 1.0
    @Environment(\.colorScheme) private var colorScheme
    
    private var iconColor: Color {
        switch note.importance.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category at top
            Text(note.category)
                .font(.headline.weight(.semibold))
                .foregroundColor(iconColor)
                .accessibilityLabel("Category \(note.category)")
            
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "flame.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
                    .shadow(color: iconColor.opacity(0.5), radius: 6, x: 0, y: 2)
                    .scaleEffect(flameScale)
                    .animation(
                        note.importance.lowercased() == "high"
                        ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                        value: flameScale
                    )
                    .onAppear {
                        if note.importance.lowercased() == "high" {
                            flameScale = 1.15
                        }
                    }
                    .accessibilityHidden(true)
                
                Text(note.importance.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .clipShape(Capsule())
                    .accessibilityLabel("Importance \(note.importance.capitalized)")
                
                Spacer()
            }
            
            Text(note.text)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Note preview: \(note.text)")
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.primary.opacity(0.25), radius: 10, x: 0, y: 5)
        )
        .accessibilityAddTraits(.isButton)
    }
}

struct QuickQuizPopup: View {
    let note: LearningNote?
    @Binding var isPresented: Bool
    @Binding var wrongAnswer: String?
    @Binding var answeredCorrectly: Bool
    @Binding var dismissAfterWrong: Bool
    @Binding var answerText: String
    var onWrongAnswer: (LearningNote?) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            if let note = note {
                Text("Quick Quiz")
                    .font(.title2).bold()
                Text("What did you learn?")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                TextField("Type your answer here", text: $answerText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocapitalization(.sentences)
                if wrongAnswer != nil {
                    Text("❌ Wrong. Correct answer:")
                        .foregroundColor(.red)
                    Text(note.text)
                        .font(.body)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Dismiss") {
                        dismissAfterWrong = false
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                } else if answeredCorrectly {
                    Text("✅ Correct!")
                        .foregroundColor(.green)
                    Button("Continue") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Submit") {
                        if answerText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == note.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                            answeredCorrectly = true
                        } else {
                            wrongAnswer = answerText
                            dismissAfterWrong = true
                            onWrongAnswer(note)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(answerText.isEmpty)
                }
            } else {
                Text("No note loaded.")
                Button("Dismiss") { isPresented = false }
            }
        }
        .padding()
        .onChange(of: dismissAfterWrong) { _, newValue in
            if newValue == false {
                answerText = ""
                wrongAnswer = nil
                answeredCorrectly = false
            }
        }
    }
}

#Preview {
    LearnedSomethingView(deepLinkNoteID: nil, reminderNumber: 0)
}

