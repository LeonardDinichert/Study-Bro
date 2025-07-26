//
//  LearnedSomethingView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 27.04.2025.
//

import SwiftUI

struct LearnedSomethingView: View {
    @State private var userWantsToRevise = false
    @State private var userWantsAddInfo = false
    
    @StateObject private var viewModel = NotesViewModel()

    var body: some View {
        ZStack {
            // Full-screen background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Header card
                VStack(spacing: 8) {
                    Text("Did you learn something new?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    ForEach(viewModel.dueNotes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.category)
                                .font(.headline)
                            Text(note.text)
                            Text(note.importance)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(note: note) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: { userWantsAddInfo = true }) {
                            Label("I learned something new", systemImage: "lightbulb.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: { userWantsToRevise = true }) {
                            Label("I want to revise", systemImage: "book.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 4)
                )
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Modals
        .fullScreenCover(isPresented: $userWantsAddInfo) {
            AddNoteView(isPresented: $userWantsAddInfo)
        }
        .fullScreenCover(isPresented: $userWantsToRevise) {
            UserWantsToReviseView().onDisappear { userWantsToRevise = false }
        }
        .task { await viewModel.loadNotes() }
    }
}

#Preview {
    LearnedSomethingView()
}
