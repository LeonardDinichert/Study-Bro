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
            Rectangle()
                .fill(.ultraThinMaterial)
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
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .foregroundColor(.accentColor)
                        }

                        Button(action: { userWantsToRevise = true }) {
                            Label("I want to revise", systemImage: "book.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.thinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .blur(radius: 0.3)
                )
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .task { await viewModel.loadNotes() }
    }
}

#Preview {
    LearnedSomethingView()
}
