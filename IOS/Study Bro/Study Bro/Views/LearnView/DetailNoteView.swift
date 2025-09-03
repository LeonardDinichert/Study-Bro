//
//  DetailNoteView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

// Warm palette applied for a more inviting look!

import SwiftUI
import Charts
import Foundation
import PDFKit
import FirebaseAuth
import FirebaseFirestore

let warmGradient = LinearGradient(colors: [.orange, .yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)

struct DetailNoteView: View {
    
    let note: LearningNote
    
    @State private var wordForCount: String = ""
    @State private var showDocumentViewer = false
    @State private var showJointScan = false
    @State private var promptAutoTest: Bool = false
    
    @State private var showSessionRequired = false

    
    // Pomodoro Timer State
    @State private var showPomodoro = false
    @State private var pomodoroUserId: String = ""
    
    @State private var showSendSheet = false
    @StateObject private var friendsVM = FriendsViewModel()
    
    private var reminders: [Bool] { [note.reminder_1, note.reminder_2, note.reminder_3, note.reminder_4, note.reminder_5] }
    private var activeIndices: [Int] { reminders.enumerated().compactMap { $0.element ? $0.offset : nil } }
    private var count: Int { activeIndices.count }
    private var encouragement: String {
        switch count {
        case 0:
            return "Let's get started! Your memory journey begins now. 🏁"
        case 1:
            return "Great start! Keep it up and you'll remember even more! 💡"
        case 2:
            return "You're on a roll! Two reviews done – awesome work! 🚀"
        case 3:
            return "Halfway there! Your dedication shows. 🌱"
        case 4:
            return "Amazing! One more and you'll master it! 🌟"
        case 5:
            return "Congratulations! You've completed all reviews! 🎉"
        default:
            return "Keep going!"
        }
    }
    
    
    
    var body: some View {
        ZStack {

            ScrollView {
                
                VStack(spacing: 32) {
                    
                   // graph ne s'update pas
                    
                    // Category Section
                    VStack(alignment: .leading, spacing: 8) {
      
                            Text(note.category)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(.trailing)
       
                    }
                    .padding()
                    .background(Color.orange.opacity(0.17))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    
                    // Reminder Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What you have to remember :")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(note.text)
                            .foregroundStyle(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        if let documentURL = note.documentURL, !documentURL.isEmpty {
                            let trimmedDocumentURL = documentURL.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let remoteURL = URL(string: trimmedDocumentURL), (remoteURL.scheme == "http" || remoteURL.scheme == "https") {
                                let ext = remoteURL.pathExtension.lowercased()
                                if ext == "pdf" {
                                    Button("Open Attached Document") {
                                        showDocumentViewer = true
                                    }
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                    .sheet(isPresented: $showDocumentViewer) {
                                        PDFKitView(url: remoteURL)
                                    }
                                } else if ["jpg","jpeg","png"].contains(ext) {
                                    AsyncImage(url: remoteURL) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 300)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity, maxHeight: 300)
                                                .cornerRadius(12)
                                        case .failure:
                                            VStack {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.largeTitle)
                                                    .foregroundColor(.red)
                                                Text("Failed to load image")
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(height: 300)
                                        @unknown default:
                                            Text("No joint documents")
                                        }
                                    }
                                } else {
                                    Text("[DEBUG] Unsupported file extension: \(remoteURL.lastPathComponent)")
                                }
                            } else {
                                // Assume it's a local file reference
                                let fileManager = FileManager.default
                                let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                                if let docs = docs {
                                    let fileURL = docs.appendingPathComponent(trimmedDocumentURL)
                                    let ext = fileURL.pathExtension.lowercased()
                                    if fileManager.fileExists(atPath: fileURL.path) {
                                        if ext == "pdf" {
                                            Button("Open Attached Document") {
                                                showDocumentViewer = true
                                            }
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(12)
                                            .sheet(isPresented: $showDocumentViewer) {
                                                PDFKitView(url: fileURL)
                                            }
                                        } else if ["jpg","jpeg","png"].contains(ext) {
                                            AsyncImage(url: fileURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(height: 300)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: .infinity, maxHeight: 300)
                                                        .cornerRadius(12)
                                                case .failure:
                                                    VStack {
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .font(.largeTitle)
                                                            .foregroundColor(.red)
                                                        Text("Failed to load image")
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .frame(height: 300)
                                                @unknown default:
                                                    Text("No joint documents")
                                                }
                                            }
                                        } else {
                                            Text("[DEBUG] Unsupported file extension: \(fileURL.lastPathComponent)")
                                        }
                                    } else {
                                        Text("[DEBUG] File does not exist at path: \(fileURL.path)")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.17))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    
                    Button {
                        showSendSheet = true
                    } label: {
                        Label("Share with Friends", systemImage: "person.2.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.25))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                            .shadow(color: Color.orange.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .padding(.vertical, 4)
                    
                    // Review Schedule Graph Section
                    
                    VStack(spacing: 16) {
                        Text("Review Progress")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.top, 4)

                        Text(encouragement)
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.spring, value: count)

                        // Colored Progress Circles
                        HStack(spacing: 24) {
                            let stageColors: [Color] = [Color.orange, Color.red, Color.pink, Color.yellow, Color.brown]
                            let labels = ["1st", "2nd", "3rd", "4th", "5th"]
                            ForEach(0..<5, id: \.self) { idx in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(idx < count ? stageColors[idx] : Color.secondary.opacity(0.18))
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary.opacity(0.15), lineWidth: 2)
                                            )
                                            .shadow(color: idx < count ? stageColors[idx].opacity(0.28) : .clear, radius: 4)
                                            .animation(.bouncy, value: count)
                                        if idx < count {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 18, weight: .bold))
                                                .transition(.scale)
                                                .animation(.spring, value: count)
                                        }
                                    }
                                    Text(labels[idx])
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(idx < count ? stageColors[idx] : .secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.17))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    .contentMargins(1)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The forgetting curve illustrates how memory retention declines over time when there are no attempts to review information. The horizontal axis represents days since the initial learning or any subsequent review, and the vertical axis shows the percentage of information retained. Spacing these reviews farther apart over time optimizes long-term retention by slowing the rate of forgetting with each repetition.")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.17))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    
                    // Pomodoro study session button
                    Button {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        let db = Firestore.firestore()
                        db.collection("users")
                            .document(uid).collection("learning_notes")
                            .document(note.id ?? "noID").collection("sessions_on_note")
                            .whereField("has_been_revised", isEqualTo: false)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    print("[DEBUG] Firestore query error: \(error.localizedDescription)")
                                    // fallback to show pomodoro if error
                                    pomodoroUserId = uid
                                    showPomodoro = true
                                } else if let snapshot = snapshot, !snapshot.isEmpty {
                                    pomodoroUserId = uid
                                    showSessionRequired = true
                                } else {
                                    pomodoroUserId = uid
                                    showPomodoro = true
                                }
                            }
                    } label: {
                        Label("Study this set", systemImage: "timer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect()
                            .tint(.orange)
                    }
                    .padding([.horizontal, .top])
                    
                    Spacer()
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    
                }
                .padding()
                .fullScreenCover(isPresented: $showPomodoro) {
                    PomodoroTimerView(
                        startSession: $showPomodoro,
                        userWillStudy: .constant(note.text),
                        userId: $pomodoroUserId, noteId: .constant(note.id ?? "none")
                    )
                    .onDisappear {
                        promptAutoTest = true
                        
                    }
                }
                .fullScreenCover(isPresented: $promptAutoTest) {
                    DelayedAutoTestView(noteId: note.id ?? "none")
                }
                .fullScreenCover(isPresented: $showSessionRequired) {
                    QuizView()
                        .onDisappear {
                            showPomodoro = true
                        }
                }
                .sheet(isPresented: $showSendSheet) {
                    SendNoteToFriendView(friendsVM: friendsVM, noteId: note.id ?? "none", noteTitle: note.text.prefix(20) + (note.text.count > 20 ? "..." : ""))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSendSheet = true
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                }
            }
            
            .onAppear(perform: {
                // Compute how many reminders are true, in order
                let count = reminders.prefix { $0 }.count
                var wordForCount1: String
                switch count {
                case 1: wordForCount1 = "once"
                case 2: wordForCount1 = "twice"
                case 3: wordForCount1 = "three times"
                case 4: wordForCount1 = "four times"
                case 5: wordForCount1 = "five times"
                default: wordForCount1 = "never"
                }
                wordForCount = wordForCount1
            })
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.14)
        
        print("[DEBUG] PDFKitView loading from URL: \(url)")
        if let document = PDFDocument(url: url) {
            print("[DEBUG] PDF document loaded successfully")
            pdfView.document = document
        } else {
            print("[DEBUG] Failed to load PDF document")
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Nothing to update
    }
}

struct JointScanPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "viewfinder.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            Text("Joint Scan")
                .font(.title)
                .fontWeight(.bold)
            Text("This is a placeholder for the joint scan of this learning note. Replace with actual scan functionality.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    DetailNoteView(note: LearningNote(
        category: "Sample Category",
        text: "This is a sample note for preview.",
        importance: "High",
        reviewCount: 2,
        nextReview: Date(),
        createdAt: Date(),
        reminder_1: true,
        reminder_2: false,
        reminder_3: false,
        reminder_4: false,
        reminder_5: false,
        documentURL: nil
    ))
}
