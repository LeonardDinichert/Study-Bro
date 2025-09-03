//
//  StudySessionView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct StudySessionView: View {
    
    @StateObject private var viewModel = userManagerViewModel()
    
    @State var userWillStudy: String = ""
    @State var openMeditationView: Bool = false
    @State var startSession: Bool = false
    @State var userId: String = ""
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case studysubject
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = viewModel.user {
                    StudySessionSubview(
                        userWillStudy: $userWillStudy,
                        openMeditationView: $openMeditationView,
                        startSession: $startSession,
                        userId: $userId,
                        errorMessage: $errorMessage,
                        user: user
                    )
                } else {
                    VStack(spacing: 16) {
                        Text("Loading...")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.secondary)
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .padding(24)
                    .frame(maxWidth: 300)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .padding(.vertical, 40)
                    .padding(.horizontal)

                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $openMeditationView) {
                MeditationPreWorkView(openMeditationView: $openMeditationView)
            }
            .fullScreenCover(isPresented: $startSession) {
                PomodoroTimerView(startSession: $startSession, userWillStudy: $userWillStudy, userId: $userId, noteId: .constant(""))
            }
            .task {
                Task {
                    try await viewModel.loadCurrentUser()
                    userWillStudy = ""
                }
            }
        }
    }
}

#Preview {
    StudySessionSubview(
        userWillStudy: .constant("Math"),
        openMeditationView: .constant(false),
        startSession: .constant(false),
        userId: .constant("preview-id"),
        errorMessage: .constant(nil),
        user: DBUser(userId: "preview-id", email: "preview@example.com", firstName: "Preview", lastName: "User")
    )
}

struct StudySessionSubview: View {
    
    @Binding var userWillStudy: String
    @Binding var openMeditationView: Bool
    @Binding var startSession: Bool
    @Binding var userId: String
    @Binding var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case studysubject
    }
    
    let user: DBUser
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .center, spacing: 16) {
                Text("What will you study \(user.firstName ?? "no name")?")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.vertical)
                
                Text("Study Subject")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.vertical)
                
                CustomTextField(text: $userWillStudy, placeholder: "Eg. Math")
                    .focused($focusedField, equals: .studysubject)
                    .padding(.horizontal)
                    .cornerRadius(18)
                    .glassEffect()
                    .frame(height: 50)
                
                Button {
                    openMeditationView = true
                } label: {
            
                        Text("Prepare yourself to work ?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 10)
                        
                }
                .buttonStyle(.glassProminent)
                .padding(.vertical)
                
                Text("By resting a few minutes before working, you will be able to concentrate better")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
               
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                        .animation(.easeInOut, value: errorMessage)
                        .padding(.vertical)
                }
                    
                
                Button {
                    if userWillStudy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errorMessage = "Please enter what you will study before starting the timer."
                        return
                    }
                    errorMessage = nil
                    userId = user.userId
                    startSession = true
                } label: {
                    Text("Begin the pomodoro timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 10)

                }
                .padding(.vertical)
                .buttonStyle(.glassProminent)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
        .padding(1)

    }
}

