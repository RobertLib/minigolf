//
//  DailyChallenge.swift
//  Minigolf
//
//  One hole a day, the same one for everybody, drawn from every world —
//  including the ones the player has not unlocked yet, so the daily doubles as
//  a taster of what is still ahead.
//

import Foundation

enum DailyChallenge {

    struct Pick: Equatable {
        var course: CourseType
        var hole: Int
    }

    /// Today's hole. Derived from the calendar day alone, so it is stable across
    /// launches and identical on every device.
    static func pick(for day: String = GameDay.key()) -> Pick {
        var candidate = draw(seed: seed(for: day))
        // Never hand out the same hole two days running.
        if let previous = previousDay(day), candidate == draw(seed: seed(for: previous)) {
            candidate = draw(seed: seed(for: day) &* 31 &+ 7)
        }
        return candidate
    }

    static func level(for day: String = GameDay.key()) -> LevelDefinition {
        let pick = pick(for: day)
        return LevelLibrary.level(course: pick.course, number: pick.hole)
    }

    private static func draw(seed: UInt64) -> Pick {
        var rng = SplitMix64(seed: seed)
        let courses = CourseType.allCases
        let course = courses[Int(rng.next() % UInt64(courses.count))]
        let holes = LevelLibrary.holeCount(course)
        let hole = Int(rng.next() % UInt64(holes)) + 1
        return Pick(course: course, hole: hole)
    }

    /// FNV-1a over the day key: cheap, stable, and well spread for short strings.
    private static func seed(for day: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in day.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    private static func previousDay(_ day: String) -> String? {
        guard let date = GameDay.date(from: day),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)
        else { return nil }
        return GameDay.key(yesterday)
    }
}

/// How well today's round went, shown on the menu card once it is done.
enum DailyMedal {
    case gold
    case silver
    case bronze

    static func medal(strokes: Int, par: Int) -> DailyMedal {
        if strokes < par { return .gold }
        if strokes == par { return .silver }
        return .bronze
    }

    var symbol: String {
        switch self {
        case .gold: return "medal.fill"
        case .silver: return "medal"
        case .bronze: return "checkmark.seal.fill"
        }
    }

    var label: String {
        switch self {
        case .gold: return String(localized: "Under par")
        case .silver: return String(localized: "Par")
        case .bronze: return String(localized: "Done")
        }
    }
}
