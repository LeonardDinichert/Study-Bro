import SwiftUI
import Charts
import FirebaseAuth

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    private static var hasLoadedThisSession = false

    func load() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            sessions = try await UserManager.shared.fetchStudySessions(userId: userId)
            Self.hasLoadedThisSession = true
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }

    private var calendar: Calendar { .current }

    // daily totals in minutes
    var dailyTotals: [(day: Date, minutes: Double)] {
        var totals: [Date: Double] = [:]
        for s in sessions {
            let day = calendar.startOfDay(for: s.session_start)
            totals[day, default: 0] += s.duration / 60
        }
        return totals
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }

    // sorted unique session days
    private var sessionDays: [Date] {
        Set(sessions.map { calendar.startOfDay(for: $0.session_start) })
            .sorted()
    }

    // current streak length
    var streak: Int {
        guard let last = sessionDays.last else { return 0 }
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard calendar.isDate(last, inSameDayAs: today)
                || calendar.isDate(last, inSameDayAs: yesterday)
        else { return 0 }

        var count = 1
        var prev = last
        for day in sessionDays.dropLast().reversed() {
            let diff = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
            if diff == 1 {
                count += 1
                prev = day
            } else if diff == 0 {
                continue
            } else {
                break
            }
        }
        if calendar.isDate(last, inSameDayAs: yesterday) {
            if count >= 10, let userId = Auth.auth().currentUser?.uid {
                Task { await self.checkStreakTrophies(streak: count, userId: userId) }
            }
            return count
        } else {
            if count >= 10, let userId = Auth.auth().currentUser?.uid {
                Task { await self.checkStreakTrophies(streak: count, userId: userId) }
            }
            return count
        }
    }

    // whether user has a session today
    var hasSessionToday: Bool {
        guard let last = sessionDays.last else { return false }
        let today = calendar.startOfDay(for: .now)
        return calendar.isDate(last, inSameDayAs: today)
    }

    private func checkStreakTrophies(streak: Int, userId: String) async {
        do {
            let user = try await UserManager.shared.getUser(userId: userId)
            let trophies = user.trophies ?? []
            let thresholds: [(Int, String)] = [
                (10, "10_day_streak"),
                (15, "15_day_streak"),
                (30, "30_day_streak")
            ]
            for (requiredStreak, trophyName) in thresholds {
                if streak >= requiredStreak && !trophies.contains(trophyName) {
                    try? await UserManager.shared.addTrophy(userId: userId, trophy: trophyName)
                }
            }
        } catch {
            print("Error checking/adding trophies: \(error)")
        }
    }
}

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Study Minutes by Day")
                    .font(.headline)

                // streak message
                Group {
                    if viewModel.streak == 0 {
                        Text("No streak yet")
                    } else if viewModel.hasSessionToday {
                        Text("Current streak: \(viewModel.streak) days")
                    } else {
                        Text("Nice work! You have a \(viewModel.streak)-day streak—come back today to keep it going!")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                // bar chart or placeholder
                if viewModel.dailyTotals.isEmpty {
                    Text("No sessions yet")
                        .foregroundColor(.secondary)
                } else {
                    Chart {
                        ForEach(viewModel.dailyTotals, id: \.day) { entry in
                            BarMark(
                                x: .value("Day", entry.day, unit: .day),
                                y: .value("Minutes", entry.minutes)
                            )
                            .foregroundStyle(AppTheme.primaryColor)
                        }
                    }
                    .chartXAxisLabel("Day")
                    .chartYAxisLabel("Minutes")
                    .frame(height: 200)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Stats")
        }
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    StatsView()
}
