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
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                    }
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                    }
                }
            }
        }
        .onAppear {
            Task {
                try await viewModel.loadCurrentUser()

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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter
    }()
    
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastSevenDays = (0..<7).map { calendar.date(byAdding: .day, value: -($0), to: today)! }.reversed()
        let chartData = lastSevenDays.map { day in
            statsModel.dailyTotals.first(where: { calendar.isDate($0.day, inSameDayAs: day) })?.minutes ?? 0.0
        }
        let hasData = chartData.contains(where: { $0 > 0 })
        let maxY = max(chartData.max() ?? 0, 60)
        
        VStack(alignment: .leading, spacing: 24) {
            
            Text("Hi \(user.username ?? "No user"), let's work !")
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            VStack(spacing: 16) {
                
                Group {
                    if statsModel.streak == 0 {
                        Text("No streak yet")
                    } else if statsModel.hasSessionToday {
                        Text("Current streak: \(statsModel.streak) days")
                    } else {
                        Text("Nice work! You have a \(statsModel.streak) day streak. Work today too to keep it going!")
                    }
                }
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
            
            
            if statsModel.streak != 0 {
                Text("Amount of time you have worked each day :")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 8) {
                Chart {
                    ForEach(Array(lastSevenDays.enumerated()), id: \.offset) { index, day in
                        BarMark(
                            x: .value("Day", dateFormatter.string(from: day)),
                            y: .value("Minutes", chartData[index])
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .chartXScale(domain: lastSevenDays.map { dateFormatter.string(from: $0) })
                .chartYScale(domain: 0...maxY)
                .chartXAxisLabel("Day")
                .chartYAxisLabel("Minutes")
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
            
            if !hasData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your study data will appear here.")
                        .foregroundStyle(.orange)
                        .font(.title3.weight(.bold))
                    Text("To display your study graph, log at least one study session per day for 7 days within a 7-day span.")
                        .foregroundStyle(.secondary)
                    Text("• Open the app daily and complete a study session to record your time.")
                        .foregroundStyle(.secondary)
                    Text("• Once 7 days have data out of your last 7 days, your graph will appear here.")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .padding(.horizontal, 16)
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
         Spacer()
        }
        .onAppear {
            Task {
                await statsModel.load()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    HomeTabSubView(user: DBUser(userId: "preview", username: "PreviewUser"))
}
