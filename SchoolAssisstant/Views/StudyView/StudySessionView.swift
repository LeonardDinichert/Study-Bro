//
//  StudySessionView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 27.04.2025.
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
                    VStack {

                        Text("What will you study \(user.firstName ?? "no name") ? ")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        CustomTextField(text: $userWillStudy, placeholder: "Eg. Math")
                            .focused($focusedField, equals: .studysubject)
                            .cardStyle()
                            .padding(.horizontal)
                        
                        
                        Button {
                            openMeditationView = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                                    .frame(height: 100)
                                    .padding(.horizontal)
                                    .foregroundStyle(.orange).opacity(0.2)
                                VStack {
                                    
                                    Text("Prepare yourself better for working ?")
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.top)
                                    
                                    Text("By resting a few minutes before working, you will be able to concentrate better")
                                        .foregroundStyle(.black)
                                        .font(.footnote)
                                        .padding(.bottom)
                                }
                                .padding()
                            }
                            .padding()
                        }
                        
                        Spacer()
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
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
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    
                } else {
                    // MARK: - Loading / Not Logged In
                    VStack(spacing: 16) {
                        Text("Loading...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        ProgressView()
                            .font(.title)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $openMeditationView, content: {
            MeditationPreWorkView(openMeditationView: $openMeditationView)
        })
        .fullScreenCover(isPresented: $startSession, content: {
            PomodoroTimerView(startSession: $startSession, userWillStudy: $userWillStudy, userId: $userId)
        })
        
        .task {
            Task {
                try await viewModel.loadCurrentUser()
            }
        }
    }
}

#Preview {
    StudySessionView()
}
