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
            Color.clear
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

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
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.thinMaterial)
                        )
                        .padding(.vertical, 4)
                        .animation(.smooth, value: viewModel.dueNotes.count)
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
                                .glassEffect()
                                .tint(.accentColor)
                        }

                        Button(action: { userWantsToRevise = true }) {
                            Label("I want to revise", systemImage: "book.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassEffect()
                                .tint(.primary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .foregroundStyle(.black.opacity(0.1))
                )
                .padding(.horizontal, 20)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.smooth, value: userWantsAddInfo || userWantsToRevise)
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

