//
//  Achievements.swift
//  Minigolf
//
//  Long-horizon goals that give a reason to come back once every hole has
//  been walked once. Each one is a counter with a target, so the trophy room
//  can show partial progress instead of a locked box.
//

import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let goal: Int
    /// Where the player currently stands, capped at `goal` by `progress(…)`.
    let measure: (PlayerStats, GameProgress) -> Int

    func progress(stats: PlayerStats, progress: GameProgress) -> Int {
        min(goal, measure(stats, progress))
    }

    func isEarned(stats: PlayerStats, progress: GameProgress) -> Bool {
        measure(stats, progress) >= goal
    }

    func fraction(stats: PlayerStats, progress: GameProgress) -> Double {
        goal > 0 ? Double(self.progress(stats: stats, progress: progress)) / Double(goal) : 0
    }
}

enum Achievements {

    /// Ordered roughly by how soon a new player will meet them. Built once —
    /// the trophy room reads this list several times per redraw.
    static let all: [Achievement] = {
        [
            Achievement(
                id: "firstHole",
                title: String(localized: "Tee Off"),
                detail: String(localized: "Finish your first hole."),
                symbol: "flag.fill", goal: 1,
                measure: { stats, _ in stats.holesCompleted }),
            Achievement(
                id: "holes25",
                title: String(localized: "Warmed Up"),
                detail: String(localized: "Finish 25 holes."),
                symbol: "figure.golf", goal: 25,
                measure: { stats, _ in stats.holesCompleted }),
            Achievement(
                id: "holes150",
                title: String(localized: "Course Regular"),
                detail: String(localized: "Finish 150 holes."),
                symbol: "repeat", goal: 150,
                measure: { stats, _ in stats.holesCompleted }),
            Achievement(
                id: "ace",
                title: String(localized: "Ace!"),
                detail: String(localized: "Sink a hole-in-one."),
                symbol: "target", goal: 1,
                measure: { stats, _ in stats.holeInOnes }),
            Achievement(
                id: "ace10",
                title: String(localized: "Sharpshooter"),
                detail: String(localized: "Sink 10 hole-in-ones."),
                symbol: "scope", goal: 10,
                measure: { stats, _ in stats.holeInOnes }),
            Achievement(
                id: "birdies25",
                title: String(localized: "Birdwatcher"),
                detail: String(localized: "Finish 25 holes under par."),
                symbol: "bird.fill", goal: 25,
                measure: { stats, _ in stats.birdiesOrBetter }),
            Achievement(
                id: "parStreak8",
                title: String(localized: "In the Zone"),
                detail: String(localized: "Play 8 holes in a row at or under par."),
                symbol: "bolt.fill", goal: 8,
                measure: { stats, _ in stats.bestParStreak }),
            Achievement(
                id: "cleanRound",
                title: String(localized: "Clean Round"),
                detail: String(localized: "Finish a world without a single penalty."),
                symbol: "sparkle", goal: 1,
                measure: { stats, _ in stats.cleanCourses }),
            Achievement(
                id: "underPar",
                title: String(localized: "Under Par"),
                detail: String(localized: "Finish a world 5 shots under par."),
                symbol: "arrow.down.circle.fill", goal: 5,
                measure: { stats, _ in stats.bestCourseUnderPar }),
            Achievement(
                id: "stars50",
                title: String(localized: "Star Collector"),
                detail: String(localized: "Earn 50 stars."),
                symbol: "star.fill", goal: 50,
                measure: { _, progress in progress.starsEarned }),
            Achievement(
                id: "starsAll",
                title: String(localized: "Perfectionist"),
                detail: String(localized: "Earn every star in the game."),
                symbol: "crown.fill", goal: LevelLibrary.totalHoles * HoleStars.max,
                measure: { _, progress in progress.starsEarned }),
            Achievement(
                id: "bonus12",
                title: String(localized: "Treasure Hunter"),
                detail: String(localized: "Collect 12 bonus stars."),
                symbol: "sparkles", goal: 12,
                measure: { _, progress in progress.totalBonusStars }),
            Achievement(
                id: "bonusAll",
                title: String(localized: "Nothing Left Behind"),
                detail: String(localized: "Collect every bonus star."),
                symbol: "shippingbox.fill", goal: LevelLibrary.totalBonusStars,
                measure: { _, progress in progress.totalBonusStars }),
            Achievement(
                id: "allHoles",
                title: String(localized: "Every Green"),
                detail: String(localized: "Finish all \(LevelLibrary.totalHoles) holes at least once."),
                symbol: "map.fill", goal: LevelLibrary.totalHoles,
                measure: { _, progress in progress.holesFinished }),
            Achievement(
                id: "worldTour",
                title: String(localized: "World Tour"),
                detail: String(localized: "Finish all \(CourseType.allCases.count) worlds."),
                symbol: "globe.europe.africa.fill", goal: CourseType.allCases.count,
                measure: { _, progress in progress.completedCourseCount }),
            Achievement(
                id: "daily1",
                title: String(localized: "Daily Habit"),
                detail: String(localized: "Finish your first daily challenge."),
                symbol: "calendar", goal: 1,
                measure: { stats, _ in stats.dailiesCompleted }),
            Achievement(
                id: "daily7",
                title: String(localized: "Seven-Day Swing"),
                detail: String(localized: "Keep a 7-day daily streak."),
                symbol: "calendar.badge.checkmark", goal: 7,
                measure: { stats, _ in stats.bestDailyStreak }),
            Achievement(
                id: "daily30",
                title: String(localized: "Month of Golf"),
                detail: String(localized: "Keep a 30-day daily streak."),
                symbol: "flame.fill", goal: 30,
                measure: { stats, _ in stats.bestDailyStreak }),
        ]
    }()

    static func earnedCount(stats: PlayerStats, progress: GameProgress) -> Int {
        all.count { $0.isEarned(stats: stats, progress: progress) }
    }

    /// Achievements that have just crossed their goal and were not recorded yet.
    /// The caller is expected to mark them as unlocked in `stats`.
    static func newlyEarned(stats: PlayerStats, progress: GameProgress) -> [Achievement] {
        all.filter {
            !stats.unlockedAchievements.contains($0.id) && $0.isEarned(stats: stats, progress: progress)
        }
    }
}
