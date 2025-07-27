import SwiftUI
import Charts
import FirebaseAuth

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    
    private static var hasLoadedThisSession = false
    
    func load() async {
        guard !Self.hasLoadedThisSession else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            sessions = try await UserManager.shared.fetchStudySessions(userId: userId)
            Self.hasLoadedThisSession = true
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    var dailyTotals: [(day: Date, minutes: Double)] {
        let cal = Calendar.current
        var totals: [Date: Double] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.session_start)
            totals[day, default: 0] += s.duration / 60
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.day < $1.day }
    }
    
    var streak: Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.session_start) }).sorted(by: >)
        guard let first = days.first else { return 0 }
        var count = 1
        var prev = first
        for day in days.dropFirst() {
            if cal.dateComponents([.day], from: day, to: prev).day == 1 {
                count += 1
                prev = day
            } else if day == prev {
                continue
            } else {
                break
            }
        }
        return count
    }
}

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Study Minutes by Day")
                    .font(.headline)
                Text("Current streak: \(viewModel.streak) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
