//
//  GameProgress.swift
//  Minigolf
//
//  Persistent player progress stored in UserDefaults.
//

import Foundation

#if DEBUG
/// Progress that must never reach disk.
///
/// `-unlockall` fills progress and stats in with plausible numbers so the menu
/// screens can be photographed. Those numbers must never reach disk: the first
/// tap on a ball in the clubhouse, or the first hole finished, would otherwise
/// write the fake save over the real one and there is no way back from that.
/// Both stores check this before writing, so nothing has to remember to.
///
/// A test run counts for the same reason. The tests drive the real controller
/// through lost lives, penalties and finished holes, and the machine running
/// them is somebody's Mac with their own save on it — so the run is read as a
/// demo too, and every `save()` in the process becomes a no-op. Read off the
/// environment XCTest sets in the host process rather than a scheme setting, so
/// there is nothing to keep in step.
enum DemoProgress {
    static let isActive = ProcessInfo.processInfo.arguments.contains("-unlockall")
        || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || NSClassFromString("XCTestCase") != nil
}
#endif

struct CourseRecord: Codable {
    var completed = false
    var bestTotal: Int?
    var stars = 0
    var bestHoleScores: [Int]?
    /// Best strokes ever taken on a hole, whether in a tour or in practice.
    var holeBest: [Int: Int] = [:]
    /// Hole numbers whose bonus star has been picked up.
    var bonusStars: Set<Int> = []

    mutating func register(total: Int, coursePar: Int, holeScores: [Int]) {
        completed = true
        if bestTotal == nil || total < bestTotal! {
            bestTotal = total
            bestHoleScores = holeScores
        }
        stars = max(stars, CourseStars.stars(total: total, coursePar: coursePar))
    }

    /// Records a finished hole. Returns true when it beat the previous best.
    @discardableResult
    mutating func registerHole(_ number: Int, strokes: Int) -> Bool {
        let previous = holeBest[number]
        guard previous == nil || strokes < previous! else { return false }
        holeBest[number] = strokes
        return previous != nil
    }

    /// The furthest hole the player has finished (0 when the course is untouched).
    var holesPlayed: Int {
        holeBest.keys.max() ?? 0
    }
}

struct GameProgress: Codable {
    var records: [String: CourseRecord] = [:]

    // v2: per-hole records and bonus stars, keyed by course. A new world needs no
    // version bump — the map just gains a key, and a missing one reads as unplayed.
    private static let storageKey = "minigolf.progress.v2"

    static func load() -> GameProgress {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let progress = try? JSONDecoder().decode(GameProgress.self, from: data)
        else {
            return GameProgress()
        }
        return progress
    }

    func save() {
        #if DEBUG
        guard !DemoProgress.isActive else { return }
        #endif
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func record(for course: CourseType) -> CourseRecord {
        records[course.rawValue] ?? CourseRecord()
    }

    mutating func update(for course: CourseType, mutate: (inout CourseRecord) -> Void) {
        var rec = record(for: course)
        mutate(&rec)
        records[course.rawValue] = rec
        save()
    }

    /// A world opens once the previous one has been cleared. A course that has
    /// already been finished always stays open.
    func isUnlocked(_ course: CourseType) -> Bool {
        guard let previous = course.previous else { return true }
        return record(for: previous).completed || record(for: course).completed
    }

    /// Practice unlocks hole by hole: the first one plus everything the player
    /// has already reached in a tour.
    func isHoleUnlocked(course: CourseType, hole: Int) -> Bool {
        guard isUnlocked(course) else { return false }
        if hole <= 1 { return true }
        let rec = record(for: course)
        return rec.completed || rec.holeBest[hole - 1] != nil || rec.holeBest[hole] != nil
    }

    func holeStars(course: CourseType, hole: Int) -> Int {
        guard let best = record(for: course).holeBest[hole] else { return 0 }
        return HoleStars.stars(strokes: best, par: LevelLibrary.level(course: course, number: hole).par)
    }

    func bonusStarCount(for course: CourseType) -> Int {
        record(for: course).bonusStars.count
    }

    var allCompleted: Bool {
        CourseType.allCases.allSatisfy { record(for: $0).completed }
    }

    var completedCourseCount: Int {
        CourseType.allCases.count { record(for: $0).completed }
    }

    /// Sum of the best totals across all courses (only meaningful when allCompleted).
    var overallBestTotal: Int {
        CourseType.allCases.compactMap { record(for: $0).bestTotal }.reduce(0, +)
    }

    var totalBonusStars: Int {
        CourseType.allCases.reduce(0) { $0 + bonusStarCount(for: $1) }
    }

    /// Holes finished at least once across every world.
    var holesFinished: Int {
        CourseType.allCases.reduce(0) { $0 + record(for: $1).holeBest.count }
    }

    var starsEarned: Int {
        CourseType.allCases.reduce(0) { total, course in
            total + (1...LevelLibrary.holeCount(course)).reduce(0) {
                $0 + holeStars(course: course, hole: $1)
            }
        }
    }
}
