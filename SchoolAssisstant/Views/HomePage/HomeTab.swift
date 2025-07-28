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
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ScrollView {
                        if let user = viewModel.user {
                            HomeTabSubView(user: user)
                        } else {
                            VStack(spacing: 16) {
                                Text("Loading...")
                                    .font(.title.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                ProgressView()
                                    .controlSize(.large)
                                
                                Text("If you are not logged in, you can log in below:")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 32)
                                
                                Button {
                                    showSignInView = true
                                } label: {
                                    Text("Sign in / Create an account")
                                        .font(.title3.weight(.semibold))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .cornerRadius(8)
                                .padding(.horizontal, 16)
                            }
                            .padding()
                        }
                    }
                }
                
                
            }

            .navigationBarTitleDisplayMode(.large)
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
        let target: Date = cal.date(from: components) ?? now
        NotificationManager.scheduleNotification(title: "Time to study!", body: "You haven't logged in today", at: target)
    }
}


struct HomeTabSubView: View {
    
    @StateObject private var statsModel = StatsViewModel()

    let user: DBUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            Text("Hi \(user.username ?? "No user"), let's work !")
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            VStack(spacing: 16) {
                Text(statsModel.streak > 0 ? "\(statsModel.streak) day streak! Keep it up!" : "Start building your streak!")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(statsModel.streak > 0 ? .orange : .primary)
                
                if statsModel.streak == 0 {
                    Text("You can begin building your work streak by finishing a minium of one study session.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 16)
            .accentColor(.orange)
            .animation(.spring(), value: statsModel.streak)
            
            let totalDays = statsModel.dailyTotals.count
            let daysWithData = statsModel.dailyTotals.filter { $0.minutes > 0 }.count
            
            if totalDays >= 10 && daysWithData >= 7 {
                VStack(spacing: 8) {
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
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 200)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.12),
                                    Color.orange.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 16)
                .animation(.spring(), value: statsModel.streak)
            } else {
                VStack(spacing: 8) {
                    Chart(statsModel.dailyTotals.prefix(0), id: \.day) { _ in
                        // No data
                    }
                    .chartXAxisLabel("Day")
                    .chartYAxisLabel("Minutes")
                    .frame(height: 200)
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your study data will appear here.")
                            .foregroundStyle(.orange)
                            .font(.title3.weight(.bold))
                        Text("To display your study graph, log at least one study session per day for 7 days within a 10-day span.")
                            .foregroundStyle(.secondary)
                        Text("• Open the app daily and complete a study session to record your time.")
                            .foregroundStyle(.secondary)
                        Text("• Once 7 days have data out of your last 10 days, your graph will appear here.")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.12),
                                    Color.orange.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 16)
                .animation(.spring(), value: statsModel.streak)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("Your friends :")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    NavigationLink(destination: FriendDiscoveryView(userId: user.userId)) {
                        Image(systemName: "person.badge.plus")
                            .imageScale(.medium)
                            .padding(6)
                            .contentShape(Rectangle())
                    Spacer()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a new friend")
                    .padding(.horizontal)
                }
                .padding(.horizontal, 16)
                
                FriendsView(userId: user.userId)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 16)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    HomeTabSubView(user: DBUser(userId: "preview", username: "PreviewUser"))
}
