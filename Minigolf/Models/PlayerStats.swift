//
//  PlayerStats.swift
//  Minigolf
//
//  Lifetime player statistics, the play-day streak, unlocked cosmetics and
//  daily-challenge history. Kept in its own UserDefaults key so the existing
//  course progress stays untouched.
//

import Foundation

/// Calendar day identity, stable across time zones for streak arithmetic.
enum GameDay {

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Local calendar day as `yyyy-MM-dd`.
    static func key(_ date: Date = Date()) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    /// Whole days from `from` to `to`, negative when `to` is earlier.
    static func days(from: String, to: String) -> Int? {
        guard let a = date(from: from), let b = date(from: to) else { return nil }
        return Calendar.current.dateComponents([.day], from: a, to: b).day
    }

    /// Seconds until the next local midnight — the daily challenge reset.
    static func secondsUntilTomorrow(from date: Date = Date()) -> TimeInterval {
        let calendar = Calendar.current
        guard let midnight = calendar.nextDate(after: date,
                                               matching: DateComponents(hour: 0, minute: 0, second: 0),
                                               matchingPolicy: .nextTime)
        else { return 0 }
        return midnight.timeIntervalSince(date)
    }
}

struct PlayerStats: Codable {

    // MARK: Lifetime counters

    var holesCompleted = 0
    var totalStrokes = 0
    var holeInOnes = 0
    var birdiesOrBetter = 0
    var penalties = 0
    var coursesFinished = 0
    /// Longest run of holes finished at or under par, across every session.
    var bestParStreak = 0
    /// Best number of shots saved against par over a full course.
    var bestCourseUnderPar = 0
    var cleanCourses = 0

    // MARK: Play-day streak

    var lastPlayDay: String?
    var dayStreak = 0
    var bestDayStreak = 0
    var daysPlayed = 0

    // MARK: Daily challenge

    /// Best score per day key, so a day already played still shows its result.
    var dailyBest: [String: Int] = [:]
    var dailyStreak = 0
    var bestDailyStreak = 0
    var lastDailyDay: String?
    var dailiesCompleted = 0

    // MARK: Cosmetics & achievements

    var selectedSkin: String = BallSkin.classic.rawValue
    var unlockedAchievements: Set<String> = []
    /// Skins the player has already been told about, so the "New!" badge and
    /// the unlock toast each fire exactly once.
    var seenSkins: Set<String> = [BallSkin.classic.rawValue]

    // MARK: - Persistence

    private static let storageKey = "minigolf.stats.v1"

    static func load() -> PlayerStats {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stats = try? JSONDecoder().decode(PlayerStats.self, from: data)
        else {
            return PlayerStats()
        }
        return stats
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - Streaks

    /// Call when a hole is finished. Extends the streak on consecutive days,
    /// restarts it after a gap, and does nothing twice on the same day.
    mutating func registerPlayDay(_ today: String = GameDay.key()) {
        guard lastPlayDay != today else { return }
        if let last = lastPlayDay, let gap = GameDay.days(from: last, to: today), gap == 1 {
            dayStreak += 1
        } else {
            dayStreak = 1
        }
        lastPlayDay = today
        daysPlayed += 1
        bestDayStreak = max(bestDayStreak, dayStreak)
    }

    /// Records a finished daily challenge. Only the first completion of a day
    /// moves the streak; later replays can still improve the score.
    mutating func registerDaily(day: String, strokes: Int) {
        let firstToday = dailyBest[day] == nil
        dailyBest[day] = min(dailyBest[day] ?? strokes, strokes)
        guard firstToday else { return }
        if let last = lastDailyDay, let gap = GameDay.days(from: last, to: day), gap == 1 {
            dailyStreak += 1
        } else {
            dailyStreak = 1
        }
        lastDailyDay = day
        dailiesCompleted += 1
        bestDailyStreak = max(bestDailyStreak, dailyStreak)
        // Keep the history small; only the recent weeks are ever shown.
        if dailyBest.count > 60 {
            for key in dailyBest.keys.sorted().prefix(dailyBest.count - 60) {
                dailyBest.removeValue(forKey: key)
            }
        }
    }

    /// The daily streak lapses if yesterday was missed, so the menu never shows
    /// a stale number the player can no longer continue.
    func liveDailyStreak(today: String = GameDay.key()) -> Int {
        guard let last = lastDailyDay, let gap = GameDay.days(from: last, to: today) else { return 0 }
        return gap <= 1 ? dailyStreak : 0
    }

    func dailyDone(today: String = GameDay.key()) -> Bool {
        dailyBest[today] != nil
    }
}
