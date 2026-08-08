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

    /// How many days of the chain a pick is resolved against. Yesterday's hole
    /// may itself have been a re-draw, so knowing it means resolving it, which
    /// means knowing the day before — the rule is only exact if the chain is
    /// walked back to the beginning of time.
    ///
    /// It is walked back four days instead. Each further day only matters if
    /// every day between collided, which is a 1-in-108 event compounded, so the
    /// first day this could still get wrong is somewhere past the year 5000.
    /// Four days is four draws and four date computations, once per menu.
    private static let chainDepth = 4

    /// Today's hole. Derived from the calendar day alone, so it is stable across
    /// launches and identical on every device.
    static func pick(for day: String = GameDay.key()) -> Pick {
        resolve(day, depth: chainDepth)
    }

    /// The hole for `day`, guaranteed different from the one `depth` days of
    /// chain say came before it.
    private static func resolve(_ day: String, depth: Int) -> Pick {
        let candidate = draw(seed: seed(for: day))
        guard depth > 0, let previous = previousDay(day) else { return candidate }

        // Yesterday as it will really be played, not as it was first drawn —
        // comparing against the raw draw is what used to let a re-drawn day be
        // handed straight back the next morning.
        let before = resolve(previous, depth: depth - 1)
        guard candidate == before else { return candidate }

        // Never hand out the same hole two days running. A re-draw can collide
        // again, so it keeps going; with 108 holes it practically never does.
        var salt: UInt64 = 0
        var replacement = candidate
        repeat {
            salt &+= 1
            replacement = draw(seed: seed(for: day) &+ salt &* 0x9E37_79B9_7F4A_7C15)
        } while replacement == before
        return replacement
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
