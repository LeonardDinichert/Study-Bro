// WorkSessionsGraphDetailView.swift
// Shows a condensed chart of all days the user ever worked (all study sessions)

import SwiftUI
import Charts

extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// Ensure we're using the StudySession model from StudySessionModel.swift
// (If needed: import StudySessionModel)

struct WorkSessionsGraphDetailView: View {
    
    @Environment(\.dismiss) private var dismiss

    // For testing/previews only
    init(userId: String, previewSessions: [StudySession]? = nil) {
        self.userId = userId
        if let previewSessions {
            self._sessions = State(initialValue: previewSessions)
            self._isLoading = State(initialValue: false)
        }
    }
    
    let userId: String
    
    @State private var sessions: [StudySession] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private let calendar = Calendar.current
    private let minBarHeight: CGFloat = 2
    
    // Helper function to print all sessions for diagnostics
    private func debugPrintSessions(_ sessions: [StudySession]) {
        // Removed debug print statements
    }
    
    private func groupSessionsByDay(_ sessions: [StudySession]) -> [(day: Date, totalMinutes: Double)] {
        // Stricter filtering: Exclude sessions with zero, negative, or near-zero duration (< 1 minute)
        // and ensure session_start is valid. This avoids skewing daily totals with invalid or too-short sessions.
        // Note: durations under 1 minute are essentially no-ops for the chart and are ignored for meaningful graph data.
        let validSessions = sessions.filter {
            let duration = $0.session_end.timeIntervalSince($0.session_start)
            let validStart = calendar.isDate($0.session_start, equalTo: $0.session_start, toGranularity: .day)
            // Exclude zero/negative/near-zero durations (< 60 seconds)
            let isDurationValid = duration >= 60 && duration.isFinite // only sessions >=1 minute count for the graph
            return validStart && isDurationValid
        }
        
        let grouped = Dictionary(grouping: validSessions) { calendar.startOfDay(for: $0.session_start) }
        
        let mapped = grouped.map { (day: Date, sessions: [StudySession]) -> (day: Date, totalMinutes: Double) in
            let total = sessions.reduce(0) { $0 + $1.duration/60 }
            // totalMinutes might be NaN or negative if data is bad, clamp to zero
            let totalMinutes = total.isFinite && total >= 0 ? total : 0
            return (day: day, totalMinutes: totalMinutes)
        }
        let sorted = mapped.sorted { a, b in a.day < b.day }
        return sorted
    }
    
    var body: some View {
        let dailyTotalsRaw = groupSessionsByDay(sessions)
        // Filter out invalid daily totals before rendering chart
        let dailyTotals = dailyTotalsRaw.filter { entry in
            let valid = entry.totalMinutes.isFinite && entry.totalMinutes >= 0
            return valid
        }
        // Only entries with totalMinutes >= 1 should be shown on the chart,
        // as durations less than 1 minute are effectively invisible on a 'Minutes' scale.
        let chartData = dailyTotals.filter { $0.totalMinutes >= 1 }
        
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
                        Text("No valid work sessions found.")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("Start a study session to see your progress, or check that your session times are correct!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if dailyTotals.isEmpty {
                    // Show empty state if all data was filtered out as invalid
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.secondary)
                        Text("No valid work sessions found.")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("Start a study session to see your progress, or check that your session times are correct!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Study Sessions Over Time")
                            .font(.headline)
                        
                        let chartDomain: ClosedRange<Date>? = {
                            guard let first = chartData.first?.day, let last = chartData.last?.day else { return nil }
                            return first...last
                        }()
                        
                        Chart(chartData, id: \.day) { entry in
                            BarMark(
                                x: .value("Day", entry.day),
                                y: .value("Minutes", max(minBarHeight, entry.totalMinutes))
                            )
                            .foregroundStyle(.orange)
                        }
                        .chartYAxisLabel { Text("Minutes") }
                        .ifLet(chartDomain) { view, domain in
                            view.chartXScale(domain: domain)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 400)
                        
                        Text("Each bar represents the total minutes you worked on that day. Scroll for more days.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding()
                }
            }
            .navigationTitle("All Study Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            loadSessions()
            assert(chartData.allSatisfy { $0.totalMinutes >= 1 }, "All charted entries must be >= 1 minute.")
        }
        
    }
    
    private func loadSessions() {
        assert(!userId.isEmpty, "userId should not be empty")
        
        isLoading = true
        errorMessage = nil
        
        let startTime = Date()
        Task {
            do {
                let fetched = try await UserManager.shared.fetchStudySessions(userId: userId)

                await MainActor.run {
                    assert(Thread.isMainThread, "UI state updates must be on the main thread")

                    self.sessions = fetched
                    self.isLoading = false

                    if fetched.isEmpty {
                        // No sessions found
                    }
                }
            } catch {
                await MainActor.run {
                    assert(Thread.isMainThread, "UI state updates must be on the main thread")

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
    return WorkSessionsGraphDetailView(userId: "preview", previewSessions: sampleSessions)
}
#endif

