//
//  QuizView.swift
//  Study Bro
//
//  Created by Léonard Dinichert on 15.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuizViewModel()
    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    @State private var answeredCorrectly: Set<Int> = []
    @State private var showQuitAlert = false
    @State private var showCompletionMessage = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            GlassEffectContainer {
                VStack {
                    if viewModel.loading {
                        ProgressView("Loading questions...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else if viewModel.pairs.isEmpty {
                        Text("No questions available.")
                            .foregroundColor(.gray)
                    } else {
                        let pair = viewModel.pairs[currentIndex]
                        VStack(spacing: 16) {
                            Text(pair.question)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            // Styled TextField container
                            VStack {
                                TextField("Your answer", text: Binding(
                                    get: { selectedAnswer ?? "" },
                                    set: { selectedAnswer = $0 }
                                ))
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                                    .glassEffect(.regular.tint(.white.opacity(0.15)), in: .rect(cornerRadius: 14))
                            )
                            .padding(.horizontal)
                            
                            if showResult {
                                let isCorrect = selectedAnswer?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == pair.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                
                                if isCorrect {
                                    Text("Correct!")
                                        .bold()
                                        .foregroundColor(.green)
                                        .padding(8)
                                        .glassEffect(.regular.tint(.green).interactive(), in: .rect(cornerRadius: 12))
                                        .accessibilityLabel("Correct answer")
                                } else {
                                    Text("Incorrect. Correct: \(pair.answer)")
                                        .bold()
                                        .foregroundColor(.red)
                                        .padding(8)
                                        .glassEffect(.regular.tint(.red).interactive(), in: .rect(cornerRadius: 12))
                                        .accessibilityLabel("Incorrect answer. Correct answer is \(pair.answer)")
                                }
                            }
                            
                            VStack(spacing: 12) {
                                Button("Check") {
                                    showResult = true
                                    let isCorrect = selectedAnswer?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == pair.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                    if isCorrect && !answeredCorrectly.contains(currentIndex) {
                                        answeredCorrectly.insert(currentIndex)
                                    }
                                }
                                .buttonStyle(.glassProminent)
                                .foregroundColor(.primary)
                                .disabled(selectedAnswer?.isEmpty ?? true)
                                .accessibilityHint("Check your answer")
                                
                                Button("Next") {
                                    let total = viewModel.pairs.count
                                    var next = currentIndex
                                    var found = false
                                    for _ in 0..<total {
                                        next = (next + 1) % total
                                        if !answeredCorrectly.contains(next) {
                                            found = true
                                            break
                                        }
                                    }
                                    if found {
                                        currentIndex = next
                                        selectedAnswer = nil
                                        showResult = false
                                    } else if answeredCorrectly.count == total { // All correct
                                        showCompletionMessage = true
                                    }
                                }
                                .buttonStyle(.glassProminent)
                                .foregroundColor(.primary)
                                .disabled(!showResult)
                                .accessibilityHint("Go to next unanswered question")
                            }
                            .padding(.top, 12)
                            
                            if answeredCorrectly.count == viewModel.pairs.count && viewModel.pairs.count > 0 {
                                if showCompletionMessage {
                                    Text("You've completed all questions!")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                        .padding(.bottom, 10)
                                        .multilineTextAlignment(.center)
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.spring(), value: showCompletionMessage)
                                        .accessibilityAddTraits(.isSummaryElement)
                                } else {
                                    // Trigger the message and dismissal only once when all answered correctly
                                    Text("You've completed all questions!")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                        .padding(.bottom, 10)
                                        .multilineTextAlignment(.center)
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.spring(), value: showCompletionMessage)
                                        .onAppear {
                                            Task {
                                                await viewModel.markSessionAsRevised()
                                                showCompletionMessage = true
                                                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                                                dismiss()
                                            }
                                        }
                                        .accessibilityAddTraits(.isSummaryElement)
                                }
                            }
                        }
                        .padding()
                        .glassEffect(.regular.tint(.accentColor).interactive(), in: .rect(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.15), radius: 18, y: 6)
                        .padding(.horizontal, 24)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Quit") {
                            
                            showQuitAlert = true
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(.red)
                        .foregroundStyle(.regularMaterial)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)
                        .accessibilityHint("Quit the quiz")
                        .alert("Quit Quiz?", isPresented: $showQuitAlert) {
                            Button("Quit", role: .destructive) {
                                Task {
                                    dismiss()
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }
                    .padding(.top, 10)
                    
                    if !viewModel.pairs.isEmpty {
                        Text("Question \(currentIndex+1) of \(viewModel.pairs.count)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.top, 8)
                            .accessibilityLabel("Question \(currentIndex + 1) of \(viewModel.pairs.count)")
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: {
            Task {
                await viewModel.loadAllPairs()
                // Reset tracking on reload
                answeredCorrectly = []
                selectedAnswer = nil
                showResult = false
                showCompletionMessage = false
                currentIndex = 0
            }
        })
    }
}

#Preview {
    QuizView()
}

