//
//  DetailNoteView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import Charts
import Foundation
import PDFKit
import FirebaseAuth
import FirebaseFirestore

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
    
    var body: some View {
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
                .background(.regularMaterial)
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
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                
                // Review Schedule Graph Section
                VStack(spacing: 12) {
                    Text("Review Schedule Graph")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                    
                    HStack(spacing: 2) {
                        Text("You remembered this note")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(wordForCount)")
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height: CGFloat = 180
                        let points = 5
                        let spacing = width / CGFloat(points - 1)
                        let labels = ["1st", "2nd", "3rd", "4th", "5th"]
                        
                        return ZStack {
                            // Draw base line
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: height/2))
                                path.addLine(to: CGPoint(x: width, y: height/2))
                            }
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                            
                            // Draw labels
                            ForEach(0..<labels.count, id: \.self) { idx in
                                Text(labels[idx])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .labelStyle(.titleAndIcon)
                                    .position(x: CGFloat(idx) * spacing, y: height/2 + 28)
                            }
                        }
                        .frame(height: height)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    .animation(.bouncy, value: [note.reminder_1, note.reminder_2, note.reminder_3, note.reminder_4, note.reminder_5])
                }
                .padding()
                .background(.regularMaterial)
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
                .background(.regularMaterial)
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
                        .tint(.accentColor)
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
                ).onDisappear {
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
            
        }
        .onAppear(perform: {
            // Compute how many reminders are true, in order
            let reminders = [note.reminder_1, note.reminder_2, note.reminder_3, note.reminder_4, note.reminder_5]
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

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground
        
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
