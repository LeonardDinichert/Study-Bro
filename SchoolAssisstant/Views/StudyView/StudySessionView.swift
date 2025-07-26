//
//  StudySessionView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 27.04.2025.
//

import SwiftUI

struct StudySessionView: View {
    
    @StateObject private var viewModel = userManagerViewModel()
    
    @State var userWillStudy: String = ""
    @State var openMeditationView: Bool = false
    @State var startSession: Bool = false
    @State var userId: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = viewModel.user {
                    VStack {

                        Text("What will you study \(user.firstName ?? "no name") ? ")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        TextField("Eg. Math", text: $userWillStudy)
                            .padding(.leading, 30)
                            .frame(height: 40)
                            .cardStyle()
                            .padding()
                        
                        
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
                        
                        Button {
                            
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
            PomodoroTimerView(startSession: $startSession, userWillStudy: $userWillStudy, userId: userId)
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
