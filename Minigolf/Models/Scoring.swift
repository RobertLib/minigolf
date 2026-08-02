//
//  Scoring.swift
//  Minigolf
//

import Foundation
import SwiftUI

/// Classic golf naming for a finished hole.
enum HoleRating {
    case holeInOne
    case eagle
    case birdie
    case par
    case bogey
    case doubleBogey
    case over(Int)

    static func rating(strokes: Int, par: Int) -> HoleRating {
        if strokes == 1 { return .holeInOne }
        switch strokes - par {
        case ...(-2): return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .over(strokes - par)
        }
    }

    var title: String {
        switch self {
        case .holeInOne: return String(localized: "HOLE-IN-ONE!")
        case .eagle: return String(localized: "EAGLE!")
        case .birdie: return String(localized: "BIRDIE!")
        case .par: return String(localized: "PAR")
        case .bogey: return String(localized: "BOGEY")
        case .doubleBogey: return String(localized: "DOUBLE BOGEY")
        case .over(let n): return String(localized: "+\(n) OVER PAR")
        }
    }

    var subtitle: String {
        switch self {
        case .holeInOne: return String(localized: "Absolutely incredible!")
        case .eagle: return String(localized: "Outstanding shot!")
        case .birdie: return String(localized: "One under par — great job!")
        case .par: return String(localized: "Right on target.")
        case .bogey: return String(localized: "Almost there.")
        case .doubleBogey: return String(localized: "That was a tough one.")
        case .over: return String(localized: "Better luck on the next hole.")
        }
    }

    var emoji: String {
        switch self {
        case .holeInOne: return "🌟"
        case .eagle: return "🦅"
        case .birdie: return "🐦"
        case .par: return "🎯"
        case .bogey: return "🙂"
        case .doubleBogey: return "😅"
        case .over: return "💪"
        }
    }

    var tint: Color {
        switch self {
        case .holeInOne: return .yellow
        case .eagle: return .orange
        case .birdie: return .green
        case .par: return .blue
        case .bogey: return .gray
        case .doubleBogey, .over: return .secondary
        }
    }
}

/// Star rating for a completed course (twelve holes per world).
enum CourseStars {
    static func stars(total: Int, coursePar: Int) -> Int {
        let diff = total - coursePar
        if diff <= -5 { return 3 }
        if diff <= 0 { return 2 }
        return 1
    }
}

/// Star rating for a single hole, used by the hole picker and practice mode.
enum HoleStars {
    static let max = 3

    static func stars(strokes: Int, par: Int) -> Int {
        if strokes <= par - 1 { return 3 }
        if strokes == par { return 2 }
        return 1
    }
}

/// Overall golfer rating shown once every course is finished.
struct GolferRating {
    var title: String
    var message: String
    var symbol: String
    var tier: Int   // 0 (best) ... 5

    // Thresholds are scaled for the full nine-world tour: roughly a quarter of
    // a stroke per hole between one tier and the next.
    static func rating(totalStrokes: Int, totalPar: Int) -> GolferRating {
        let diff = totalStrokes - totalPar
        switch diff {
        case ...(-45):
            return GolferRating(
                title: String(localized: "Golf Legend"),
                message: String(localized: "The greens whisper your name. A flawless performance!"),
                symbol: "crown.fill", tier: 0)
        case ...(-22):
            return GolferRating(
                title: String(localized: "Master of the Greens"),
                message: String(localized: "Precision, patience, perfection. Almost legendary!"),
                symbol: "trophy.fill", tier: 1)
        case ...0:
            return GolferRating(
                title: String(localized: "Pro Golfer"),
                message: String(localized: "Playing at or under par across every course. Impressive!"),
                symbol: "medal.fill", tier: 2)
        case ...22:
            return GolferRating(
                title: String(localized: "Skilled Player"),
                message: String(localized: "A steady swing and a sharp eye. Keep it up!"),
                symbol: "star.fill", tier: 3)
        case ...45:
            return GolferRating(
                title: String(localized: "Promising Talent"),
                message: String(localized: "You have the touch — now polish it to a shine."),
                symbol: "star.leadinghalf.filled", tier: 4)
        default:
            return GolferRating(
                title: String(localized: "Weekend Golfer"),
                message: String(localized: "Every legend started somewhere. Another round?"),
                symbol: "figure.golf", tier: 5)
        }
    }
}

/// Formats a score difference like golf players do.
func formattedDiff(_ diff: Int) -> String {
    if diff == 0 { return "E" }
    return diff > 0 ? "+\(diff)" : "\(diff)"
}
