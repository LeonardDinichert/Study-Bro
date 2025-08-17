//
//  DelayedAutoTestView.swift
//  Study Bro
//
//  Created by Léonard Dinichert on 15.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DelayedAutoTestView: View {
    // Return the created Q&A to the caller
    var onSave: ([QAPair]) -> Void = { _ in }
    
    let noteId: String
    
    @State private var pairs: [QAPair] = [QAPair(question: "", answer: "")]
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: UUID?
    @State private var sessionDocId: String? = nil
    
    private var validPairs: [QAPair] {
        pairs
            .map { QAPair(id: $0.id, question: $0.question.trimmingCharacters(in: .whitespacesAndNewlines),
                          answer: $0.answer.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.question.isEmpty && !$0.answer.isEmpty }
    }
    
    var body: some View {
        
        NavigationStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add or create your study questions 📝")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.bottom, 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Text("Jot down what you learned and their answers. The more you write, the better you'll remember!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .padding(.vertical, 10)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            )
            
            Section(footer: Text("Write a maximum of questions about what you worked on and the answers to it.").foregroundStyle(.secondary).font(.footnote).padding()) {
                ForEach($pairs) { $pair in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Question", text: $pair.question, axis: .vertical)
                            .lineLimit(1...4)
                            .focused($focusedField, equals: pair.id)
                            .textFieldStyle(.roundedBorder)
                        TextField("Answer", text: $pair.answer, axis: .vertical)
                            .lineLimit(1...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .shadow(color: Color.orange.opacity(0.09), radius: 3, x: 0, y: 2)
                    .padding(.vertical, 4)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
                .padding(.horizontal)

                
                Button(action: add) {
                    Label("Add a question", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.orange.gradient)
                                .shadow(color: Color.orange.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 10)
            
            if !validPairs.isEmpty {
                Section {
                    Text("\(validPairs.count) pairs ready")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.body)
                    .padding(.bottom, 2)
            }
            
            Button(action: {
                errorMessage = nil
                // Find pairs where exactly one field is empty
                let invalidPairs = pairs.filter {
                    ($0.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != $0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if !invalidPairs.isEmpty {
                    errorMessage = "Please fill both the question and answer for each pair."
                    return
                }
                guard let userId = Auth.auth().currentUser?.uid else {
                    print("Error: No user logged in")
                    return
                }
                let data: [String: Any] = [
                    "pairs": validPairs.map { ["question": $0.question, "answer": $0.answer] },
                    "has_been_revised": false
                ]
                let db = Firestore.firestore()
                let sessionsCollection = db.collection("users")
                    .document(userId)
                    .collection("learning_notes")
                    .document(noteId)
                    .collection("sessions_on_note")
                if let docId = sessionDocId {
                    sessionsCollection.document(docId).updateData(data) { error in
                        if let error = error {
                            print("Error updating session: \(error.localizedDescription)")
                        } else {
                            onSave(validPairs)
                            dismiss()
                        }
                    }
                } else {
                    var ref: DocumentReference? = nil
                    ref = sessionsCollection.addDocument(data: data) { error in
                        if let error = error {
                            print("Error saving session: \(error.localizedDescription)")
                        } else {
                            sessionDocId = ref?.documentID
                            onSave(validPairs)
                            dismiss()
                        }
                    }
                }
            }) {
                Text("Save")
                    .bold()
                    .foregroundStyle(validPairs.isEmpty ? .gray : .black)
            }
            .disabled(validPairs.isEmpty)
            
            Button(action: {
                dismiss()
            }) {
                Text("Quit without saving or adding new values")
            }
            
            
        }
    }
    
    private func add() {
        let new = QAPair(question: "", answer: "")
        pairs.append(new)
        focusedField = new.id
    }
    
    private func delete(at offsets: IndexSet) {
        pairs.remove(atOffsets: offsets)
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        pairs.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    DelayedAutoTestView(noteId: "preview-note")
}
