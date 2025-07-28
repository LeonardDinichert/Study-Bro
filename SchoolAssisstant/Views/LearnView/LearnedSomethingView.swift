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
    @State private var selectedCategory: String = "All"
    
    @StateObject private var viewModel = NotesViewModel()
    
    private var filteredNotes: [LearningNote] {
        if selectedCategory == "All" {
            return viewModel.notes
        } else {
            return viewModel.notes.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Header card
                    VStack(spacing: 8) {
                        
                        HStack {
                            Text("Your notes : ")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag("All")
                            Text("Math").tag("Math")
                            Text("French").tag("French")
                            Text("English").tag("English")
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading) {
                            ForEach(filteredNotes) { note in
                                
                                NavigationLink {
                                    DetailNoteView(note: note)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        // Intensity Icon
                                        let iconColor: Color = {
                                            switch note.importance.lowercased() {
                                            case "high": return .red
                                            case "medium": return .orange
                                            default: return .green
                                            }
                                        }()
                                        Image(systemName: "flame.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(iconColor)
                                            .shadow(color: iconColor.opacity(0.3), radius: 6, x: 0, y: 2)
                                            .padding(.top, 3)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(note.category)
                                                .font(.headline)
                                                .foregroundStyle(.black)
                                            
//                                            Text(note.text)
//                                                .foregroundStyle(.black)
                                            
                                            Text("Importance :\(note.importance.capitalized)")
                                                .font(.caption)
                                                .foregroundColor(iconColor)
                                            
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                                    )
                                    .padding(.vertical, 4)
                                    .animation(.smooth, value: viewModel.notes.count)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            Task { await viewModel.delete(note: note) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
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
            .task {
                await viewModel.loadNotes()
            }
        }
    }
}

#Preview {
    LearnedSomethingView()
}
