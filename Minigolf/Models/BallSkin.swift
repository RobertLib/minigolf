//
//  BallSkin.swift
//  Minigolf
//
//  Cosmetic golf balls. Every skin is procedural — a colour plus a few material
//  numbers — and unlocks from progress the player was going to make anyway.
//

import Foundation
import SwiftUI
import UIKit

enum BallSkin: String, CaseIterable, Identifiable, Codable {
    case classic
    case tangerine
    case bubblegum
    case emerald
    case ace
    case chrome
    case glacier
    case neon
    case magma
    case sunburst
    case brass
    case tempest
    case nebula
    case legend

    var id: String { rawValue }

    static var `default`: BallSkin { .classic }

    static func named(_ raw: String) -> BallSkin {
        BallSkin(rawValue: raw) ?? .classic
    }

    var displayName: String {
        switch self {
        case .classic: return String(localized: "Classic")
        case .tangerine: return String(localized: "Tangerine")
        case .bubblegum: return String(localized: "Bubblegum")
        case .emerald: return String(localized: "Emerald")
        case .ace: return String(localized: "Golden Ace")
        case .chrome: return String(localized: "Chrome")
        case .glacier: return String(localized: "Glacier")
        case .neon: return String(localized: "Neon Pulse")
        case .magma: return String(localized: "Magma")
        case .sunburst: return String(localized: "Sunburst")
        case .brass: return String(localized: "Brass")
        case .tempest: return String(localized: "Tempest")
        case .nebula: return String(localized: "Nebula")
        case .legend: return String(localized: "Legend")
        }
    }

    // MARK: - Look

    var baseColor: UIColor {
        switch self {
        case .classic: return UIColor(white: 0.96, alpha: 1)
        case .tangerine: return UIColor(red: 0.98, green: 0.52, blue: 0.14, alpha: 1)
        case .bubblegum: return UIColor(red: 0.98, green: 0.42, blue: 0.68, alpha: 1)
        case .emerald: return UIColor(red: 0.16, green: 0.74, blue: 0.44, alpha: 1)
        case .ace: return UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1)
        case .chrome: return UIColor(red: 0.80, green: 0.83, blue: 0.88, alpha: 1)
        case .glacier: return UIColor(red: 0.62, green: 0.87, blue: 0.96, alpha: 1)
        case .neon: return UIColor(red: 0.20, green: 0.95, blue: 0.90, alpha: 1)
        case .magma: return UIColor(red: 0.92, green: 0.26, blue: 0.10, alpha: 1)
        case .sunburst: return UIColor(red: 1.00, green: 0.72, blue: 0.18, alpha: 1)
        case .brass: return UIColor(red: 0.85, green: 0.63, blue: 0.24, alpha: 1)
        case .tempest: return UIColor(red: 0.46, green: 0.62, blue: 0.72, alpha: 1)
        case .nebula: return UIColor(red: 0.42, green: 0.24, blue: 0.72, alpha: 1)
        case .legend: return UIColor(red: 0.72, green: 0.48, blue: 0.98, alpha: 1)
        }
    }

    var metallic: Float {
        switch self {
        case .chrome, .ace: return 1.0
        case .brass: return 0.95
        case .legend: return 0.7
        case .tempest: return 0.45
        case .magma: return 0.3
        default: return 0.0
        }
    }

    var roughness: Float {
        switch self {
        case .chrome: return 0.06
        case .ace: return 0.15
        case .brass: return 0.22
        case .tempest: return 0.24
        case .nebula: return 0.2
        case .legend: return 0.18
        case .glacier: return 0.12
        default: return 0.3
        }
    }

    /// Skins that glow in the dark worlds carry their own emissive tint.
    var glow: UIColor? {
        switch self {
        case .neon: return UIColor(red: 0.10, green: 0.95, blue: 0.85, alpha: 1)
        case .magma: return UIColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 1)
        case .legend: return UIColor(red: 0.55, green: 0.35, blue: 1.00, alpha: 1)
        case .sunburst: return UIColor(red: 1.00, green: 0.65, blue: 0.10, alpha: 1)
        case .nebula: return UIColor(red: 0.35, green: 0.85, blue: 1.00, alpha: 1)
        default: return nil
        }
    }

    var glowIntensity: Float {
        switch self {
        case .neon: return 1.6
        case .magma: return 1.3
        case .legend: return 1.0
        case .sunburst: return 0.7
        case .nebula: return 1.5
        default: return 0
        }
    }

    /// Colour of the roll trail; the classic ball leaves a neutral white streak.
    var trailColor: UIColor {
        switch self {
        case .classic: return UIColor(white: 1.0, alpha: 1)
        case .chrome: return UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
        default: return baseColor
        }
    }

    /// SwiftUI colour for the picker swatch.
    var uiColor: Color { Color(baseColor) }

    // MARK: - Unlocking

    /// Human-readable unlock condition, shown on locked swatches.
    var requirement: String {
        switch self {
        case .classic: return String(localized: "Always yours")
        case .tangerine: return String(localized: "Finish 10 holes")
        case .bubblegum: return String(localized: "Collect 5 bonus stars")
        case .emerald: return String(localized: "Earn 30 stars")
        case .ace: return String(localized: "Score a hole-in-one")
        case .chrome: return String(localized: "Finish 2 worlds")
        case .glacier: return String(localized: "Finish the Frozen Fjord")
        case .neon: return String(localized: "Finish the Neon Nights")
        case .magma: return String(localized: "Finish the Volcano Forge")
        case .sunburst: return String(localized: "Reach a 7-day daily streak")
        case .brass: return String(localized: "Finish the Clockwork Works")
        case .tempest: return String(localized: "Finish the Storm Coast")
        case .nebula: return String(localized: "Finish the Orbital Station")
        case .legend: return String(localized: "Finish all \(LevelLibrary.totalHoles) holes")
        }
    }

    func isUnlocked(stats: PlayerStats, progress: GameProgress) -> Bool {
        switch self {
        case .classic: return true
        case .tangerine: return stats.holesCompleted >= 10
        case .bubblegum: return progress.totalBonusStars >= 5
        case .emerald: return progress.starsEarned >= 30
        case .ace: return stats.holeInOnes >= 1
        case .chrome: return progress.completedCourseCount >= 2
        case .glacier: return progress.record(for: .ice).completed
        case .neon: return progress.record(for: .neon).completed
        case .magma: return progress.record(for: .volcano).completed
        case .sunburst: return stats.bestDailyStreak >= 7
        case .brass: return progress.record(for: .clockwork).completed
        case .tempest: return progress.record(for: .storm).completed
        case .nebula: return progress.record(for: .cosmos).completed
        case .legend: return progress.holesFinished >= LevelLibrary.totalHoles
        }
    }

    static func unlocked(stats: PlayerStats, progress: GameProgress) -> [BallSkin] {
        allCases.filter { $0.isUnlocked(stats: stats, progress: progress) }
    }
}
