// DetailedStreakGraphView.swift
// A detailed streak graph view with explanations and a list of all user sessions

import SwiftUI
import Charts

struct DetailedStreakGraphView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    
    @State private var sessions: [StudySession] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private let calendar = Calendar.current
    private let minBarHeight: CGFloat = 2
    
    private func groupSessionsByDay(_ sessions: [StudySession]) -> [(day: Date, totalMinutes: Double)] {
        let validSessions = sessions.filter { $0.duration.isFinite && $0.duration > 0 }
        let grouped = Dictionary(grouping: validSessions) { calendar.startOfDay(for: $0.session_start) }
        return grouped.map { (day, sessions) in
            (day: day, totalMinutes: sessions.reduce(0) { $0 + $1.duration/60 })
        }.sorted { $0.day < $1.day }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading work sessions...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.secondary)
                        Text("No work sessions found.")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("Start a study session to see your progress!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    let dailyTotalsRaw = groupSessionsByDay(sessions)
                    let dailyTotals = dailyTotalsRaw.filter { $0.totalMinutes.isFinite && $0.totalMinutes > 0 }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("📈 Study Streak & Session History")
                                .font(.title2).bold()
                                .padding(.top, 12)
                            Text("This graph shows every day you've worked. Each bar represents your total study time for that day, even if you did multiple sessions. Below, you can see a list of all the days you've studied and exactly how much time you spent.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            // Condensed graph
                            ScrollView(.horizontal) {
                                Chart(dailyTotals, id: \.day) { entry in
                                    BarMark(
                                        x: .value("Day", entry.day, unit: .day),
                                        y: .value("Minutes", max(minBarHeight, entry.totalMinutes))
                                    )
                                    .foregroundStyle(.orange)
                                }
                                .chartXScale(domain: dailyTotals.map { $0.day })
                                .chartYAxisLabel("Minutes")
                                .frame(height: 180)
                                .frame(minWidth: CGFloat(dailyTotals.count) * 14 + 60)
                            }
                            .padding(.horizontal, 8)
                            
                            Divider()
                            
                            Text("📅 Daily Study Log")
                                .font(.headline)
                            ForEach(dailyTotals.reversed(), id: \.day) { entry in
                                HStack {
                                    Text(dateString(entry.day))
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    Text(durationString(entry.totalMinutes))
                                        .font(.body)
                                }
                                .padding(.vertical, 4)
                                .glassEffect()
                            }
                            .padding(.horizontal, 4)
                            
                            Spacer(minLength: 24)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Streak & History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            loadSessions()
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    private func durationString(_ minutes: Double) -> String {
        if minutes < 1 { return "<1 min" }
        if minutes < 60 { return String(format: "%.0f min", minutes) }
        let hrs = Int(minutes) / 60
        let min = Int(minutes) % 60
        return min == 0 ? "\(hrs) hr" : "\(hrs) hr \(min) min"
    }
    private func loadSessions() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetched = try await UserManager.shared.fetchStudySessions(userId: userId)
                let validSessions = fetched.filter { $0.session_end.timeIntervalSince($0.session_start) > 0 }
                await MainActor.run {
                    self.sessions = validSessions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load sessions: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    // Provide some sample data for preview
    let sampleSessions: [StudySession] = (0..<30).map {
        let day = Calendar.current.date(byAdding: .day, value: -$0, to: Date())!
        return StudySession(session_start: day, session_end: day.addingTimeInterval(Double.random(in: 60*30...60*90)), studied_subject: "Math")
    }
    return DetailedStreakGraphView(userId: "preview")
}
#endif

