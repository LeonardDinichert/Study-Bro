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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    if let user = viewModel.user {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Hello \(user.username ?? "No user"), let's work !")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            Text(statsModel.streak > 0 ? "\(statsModel.streak) day streak! Keep it up!" : "Start building your streak!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)

//                            if !statsModel.dailyTotals.isEmpty {
//                                Chart {
//                                    ForEach(statsModel.dailyTotals, id: \.day) { entry in
//                                        BarMark(
//                                            x: .value("Day", entry.day, unit: .day),
//                                            y: .value("Minutes", entry.minutes)
//                                        )
//                                        .foregroundStyle(AppTheme.primaryColor)
//                                    }
//                                }
//                                .chartXAxisLabel("Day")
//                                .chartYAxisLabel("Minutes")
//                                .frame(height: 200)
//                                .padding(.horizontal)
//                            }
                            
                            SocialView()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
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
                .backgroundExtensionEffect()
                Button {
                    selectedTab = .studySession
                } label: {
                    Text("Start a study session")
                }
                .buttonStyle(.borderedProminent)
                .padding()
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

