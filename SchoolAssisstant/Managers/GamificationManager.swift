import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Models
struct Lesson: Identifiable, Codable {
    let id: Int
    let title: String
    var isUnlocked: Bool
    var isCompleted: Bool
}

struct Player: Identifiable, Codable {
    var id = UUID()
    let name: String
    var xp: Int
}

struct Friend: Identifiable, Codable {
    var id = UUID()
    var name: String
    var streak: Int
    var xp: Int
}

enum Achievement: String, CaseIterable, Codable {
    case firstLesson = "First Lesson Complete"
    case streak7 = "7-Day Streak"
    case xp100 = "100 XP Earned"
}

// MARK: - Gamification Manager
/// Central manager handling streaks, XP, hearts, gems and other game data.
/// Data is stored locally using UserDefaults. In a real app, this would sync
/// with a backend service.
final class GamificationManager: ObservableObject {
    static let shared = GamificationManager()
    private init() {
        loadProgress()
        loadLessons()
        loadAchievements()
        generateSampleLeaderboard()
        generateSampleFriends()
        refillHeartsIfNeeded()
        resetDailyXPIfNeeded()
        resetLeaderboardIfNeeded()
        startHeartTimer()
    }

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // Published message about weekly results when leaderboard resets
    @Published var weeklyResult: String?

    private var weekStartKey = "leaderboardWeekStart"

    /// Load persisted progress values from UserDefaults
    private func loadProgress() {
        streak = defaults.integer(forKey: streakKey)
        totalXP = defaults.integer(forKey: xpKey)
        dailyXP = defaults.integer(forKey: dailyXPKey)
        gems = defaults.integer(forKey: gemsKey)
        hearts = defaults.integer(forKey: heartsKey)
    }

    // MARK: - Streak
    @Published private(set) var streak: Int = 0
    private var lastActiveKey = "lastActiveDate"
    private var streakKey = "streakCount"

    /// Call when the user launches the app or completes a lesson.
    func updateStreak() {
        let now = Date()
        let last = defaults.object(forKey: lastActiveKey) as? Date ?? now
        let cal = Calendar.current
        if cal.isDateInYesterday(last) {
            streak += 1
        } else if !cal.isDateInToday(last) {
            streak = 1
        }
        defaults.set(now, forKey: lastActiveKey)
        defaults.set(streak, forKey: streakKey)
        bonusGemsForStreak()
        checkAchievements()
        resetLeaderboardIfNeeded()
        // TODO: update streak on server
    }

    // MARK: - XP
    @Published private(set) var totalXP: Int = 0
    @Published private(set) var dailyXP: Int = 0
    let dailyGoal = 30
    private var xpKey = "totalXP"
    private var dailyXPKey = "dailyXP"
    private var dailyXPDateKey = "dailyXPDate"
    var level: Int { max(totalXP / 50, 1) }

    func awardXP(_ amount: Int) {
        resetDailyXPIfNeeded()
        totalXP += amount
        dailyXP += amount
        defaults.set(totalXP, forKey: xpKey)
        defaults.set(dailyXP, forKey: dailyXPKey)
        defaults.set(Date(), forKey: dailyXPDateKey)
        earnGems(forXP: amount)
        updateLeaderboardForCurrentUser()
        checkAchievements()
        resetLeaderboardIfNeeded()
    }

    private func resetDailyXPIfNeeded() {
        if let date = defaults.object(forKey: dailyXPDateKey) as? Date {
            if !Calendar.current.isDateInToday(date) {
                dailyXP = 0
                defaults.set(0, forKey: dailyXPKey)
            }
        }
    }

    // MARK: - Hearts
    @Published private(set) var hearts: Int = 5
    let maxHearts = 5
    private var heartsKey = "hearts"
    private var lastRefillKey = "lastHeartRefill"

    func loseHeart() {
        refillHeartsIfNeeded()
        if hearts > 0 { hearts -= 1 }
        defaults.set(hearts, forKey: heartsKey)
    }

    func refillHeartsIfNeeded() {
        let last = defaults.object(forKey: lastRefillKey) as? Date ?? Date()
        let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
        if hearts < maxHearts && hours >= 1 {
            hearts = min(maxHearts, hearts + hours)
            defaults.set(Date(), forKey: lastRefillKey)
            defaults.set(hearts, forKey: heartsKey)
        }
    }

    func manualRefillHeart() -> Bool {
        if spendGems(cost: 10) {
            hearts = min(maxHearts, hearts + 1)
            defaults.set(hearts, forKey: heartsKey)
            return true
        }
        return false
    }

    private func startHeartTimer() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refillHeartsIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Gems
    @Published private(set) var gems: Int = 0
    private var gemsKey = "gems"

    private func earnGems(forXP amount: Int) {
        let earned = amount / 10
        gems += earned
        defaults.set(gems, forKey: gemsKey)
        // TODO: sync gems with server
    }

    func bonusGemsForStreak() {
        if streak % 7 == 0 { gems += 5 }
        defaults.set(gems, forKey: gemsKey)
    }

    func spendGems(cost: Int) -> Bool {
        guard gems >= cost else { return false }
        gems -= cost
        defaults.set(gems, forKey: gemsKey)
        // TODO: deduct gems on server and verify purchase
        return true
    }

    // MARK: - Achievements
    @Published private(set) var earnedAchievements: [Achievement] = []
    private var achievementsKey = "achievements"

    private func loadAchievements() {
        if let data = defaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            earnedAchievements = decoded
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(earnedAchievements) {
            defaults.set(data, forKey: achievementsKey)
        }
    }

    func checkAchievements() {
        var new: [Achievement] = []
        if totalXP >= 100 { new.append(.xp100) }
        if streak >= 7 { new.append(.streak7) }
        if lessons.first(where: { $0.id == 1 })?.isCompleted == true { new.append(.firstLesson) }
        for achievement in new where !earnedAchievements.contains(achievement) {
            earnedAchievements.append(achievement)
            // Could award bonus XP or gems here
            gems += 2
            // TODO: report achievement to server
        }
        saveAchievements()
    }

    // MARK: - Lessons
    @Published private(set) var lessons: [Lesson] = []
    private var lessonsKey = "lessons"

    private func loadLessons() {
        if let data = defaults.data(forKey: lessonsKey),
           let decoded = try? JSONDecoder().decode([Lesson].self, from: data) {
            lessons = decoded
        } else {
            lessons = [
                Lesson(id: 1, title: "Lesson 1", isUnlocked: true, isCompleted: false),
                Lesson(id: 2, title: "Lesson 2", isUnlocked: false, isCompleted: false),
                Lesson(id: 3, title: "Lesson 3", isUnlocked: false, isCompleted: false)
            ]
        }
    }

    func completeLesson(_ lesson: Lesson) {
        guard let idx = lessons.firstIndex(where: { $0.id == lesson.id }) else { return }
        lessons[idx].isCompleted = true
        if idx + 1 < lessons.count {
            lessons[idx + 1].isUnlocked = true
        }
        saveLessons()
        awardXP(10)
        bonusGemsForStreak()
        // TODO: update lesson progress on server
    }

    private func saveLessons() {
        if let data = try? JSONEncoder().encode(lessons) {
            defaults.set(data, forKey: lessonsKey)
        }
    }

    // MARK: - Leaderboard
    @Published var leaderboard: [Player] = []

    private func generateSampleLeaderboard() {
        leaderboard = [
            Player(name: "You", xp: totalXP),
            Player(name: "Alex", xp: Int.random(in: 50...300)),
            Player(name: "Sam", xp: Int.random(in: 50...300)),
            Player(name: "Jamie", xp: Int.random(in: 50...300))
        ]
        sortLeaderboard()
    }

    func sortLeaderboard() {
        leaderboard.sort { $0.xp > $1.xp }
    }

    private func updateLeaderboardForCurrentUser() {
        if let idx = leaderboard.firstIndex(where: { $0.name == "You" }) {
            leaderboard[idx].xp = totalXP
            sortLeaderboard()
        }
    }

    private func resetLeaderboardIfNeeded() {
        let last = defaults.object(forKey: weekStartKey) as? Date ?? Date()
        let cal = Calendar.current
        let currentWeek = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date())
        let lastWeek = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: last)
        if currentWeek != lastWeek {
            let rank = leaderboard.firstIndex(where: { $0.name == "You" }) ?? 0
            weeklyResult = "You finished \(ordinal(rank + 1)) last week!"
            defaults.set(Date(), forKey: weekStartKey)
            generateSampleLeaderboard()
        }
    }

    private func ordinal(_ number: Int) -> String {
        let suffix: String
        let ones = number % 10
        let tens = (number / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(number)\(suffix)"
    }

    // MARK: - Friends
    @Published var friends: [Friend] = []

    private func generateSampleFriends() {
        friends = [
            Friend(name: "Alex", streak: Int.random(in: 1...5), xp: Int.random(in: 0...200)),
            Friend(name: "Sam", streak: Int.random(in: 1...5), xp: Int.random(in: 0...200)),
            Friend(name: "Jamie", streak: Int.random(in: 1...5), xp: Int.random(in: 0...200))
        ]
    }

    func addFriend(name: String) {
        let newFriend = Friend(name: name, streak: 0, xp: 0)
        friends.append(newFriend)
        // TODO: send friend request to server
    }

    // MARK: - Notifications
    /// Schedules a daily local reminder at 8pm with a random message.
    func scheduleDailyReminder() {
        let messages = [
            "Duo misses you! Time for your lesson 🦉",
            "Keep your streak up! Practice today 💪",
            "Don't let your progress fade – study now!"
        ]
        let content = UNMutableNotificationContent()
        content.title = "Study Reminder"
        content.body = messages.randomElement() ?? "Time to practice!"
        content.sound = .default

        var date = DateComponents()
        date.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}
