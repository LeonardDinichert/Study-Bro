//
//  HomeTab.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//

import SwiftUI
import Charts

struct HomeTab: View {

    @StateObject private var viewModel = userManagerViewModel()
    @StateObject private var notesViewModel = NotesViewModel()
    @StateObject private var statsModel = StatsViewModel()
    @Binding var selectedTab: Tab
    @AppStorage("showSignInView") private var showSignInView: Bool = true


    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    if let user = viewModel.user {
                        VStack(alignment: .leading, spacing: 24) {

                            Text(statsModel.streak > 0 ? "\(statsModel.streak) day streak! Keep it up!" : "Start building your streak!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            Text(statsModel.streak > 0 ? "" : "You can begin building your work streak by finishing a minium of one study session.")
                                .padding(.horizontal)

                            
                            let totalDays = statsModel.dailyTotals.count
                            let daysWithData = statsModel.dailyTotals.filter { $0.minutes > 0 }.count

                            if totalDays >= 10 && daysWithData >= 7 {
                                Chart(statsModel.dailyTotals, id: \.day) { entry in
                                    LineMark(
                                        x: .value("Day", entry.day, unit: .day),
                                        y: .value("Minutes", entry.minutes)
                                    )
                                    PointMark(
                                        x: .value("Day", entry.day, unit: .day),
                                        y: .value("Minutes", entry.minutes)
                                    )
                                }
                                .chartXAxisLabel("Day")
                                .chartYAxisLabel("Minutes")
                                .chartLegend(position: .bottom) {
                                    Text("Minutes studied per day")
                                }
                                .frame(height: 200)
                                .padding(.horizontal)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("To display your study graph, log at least one study session per day for 7 days within a 10-day span.")
                                    Text("• Open the app daily and complete a study session to record your time.")
                                    Text("• Once 7 days have data out of your last 10 days, your graph will appear here.")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            }
                            
                            Text("Your friends : ")
                                .padding(.horizontal)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            FriendsView(userId: user.userId)
                        }
                        .navigationTitle("Hi \(user.username ?? "No user"), let's work !")
                        .navigationBarTitleDisplayMode(.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 16) {
                            Text("Loading...")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            ProgressView()
                                .font(.title)
                            
                            Text("If you are not logged in, you can log in below:")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 40)
                            
                            Button {
                                showSignInView = true
                            } label: {
                                Text("Sign in / Create an account")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
//                Button {
//                    selectedTab = .studySession
//                } label: {
//                    Text("Start a study session")
//                }
//                .buttonStyle(.borderedProminent)
//                .padding()
            }
        }
        .onAppear {
            Task {
                try await viewModel.loadCurrentUser()
                await notesViewModel.loadNotes()
                await statsModel.load()
                await viewModel.loadLeaderboard()
                scheduleReminder()
            }
        }
    }

    private func scheduleReminder() {
        NotificationManager.cancelAll()
        let cal = Calendar.current
        let now = Date()
        if let last = viewModel.user?.lastConnection, cal.isDateInToday(last) {
            return
        }
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = 20
        components.minute = 0
        let target = cal.date(from: components) ?? now
        NotificationManager.scheduleNotification(title: "Time to study!", body: "You haven't logged in today", at: target)
    }
}

#Preview {
    HomeTab(selectedTab: .constant(.home))
}

