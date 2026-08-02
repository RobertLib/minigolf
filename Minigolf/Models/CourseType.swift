//
//  CourseType.swift
//  Minigolf
//
//  The worlds of the game and the order they unlock in. Kept free of UIKit so
//  the level data can also be compiled by `Tools/validate_levels.swift`.
//

import Foundation

/// The nine course worlds, listed in unlock order.
enum CourseType: String, CaseIterable, Codable, Identifiable {
    case garden
    case desert
    case jungle
    case ice
    case neon
    case volcano
    case clockwork
    case storm
    case cosmos

    var id: String { rawValue }

    /// Position in the unlock chain (0 = first).
    var order: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var displayName: String {
        switch self {
        case .garden: return String(localized: "Green Garden")
        case .desert: return String(localized: "Desert Oasis")
        case .jungle: return String(localized: "Jungle Temple")
        case .ice: return String(localized: "Frozen Fjord")
        case .neon: return String(localized: "Neon Nights")
        case .volcano: return String(localized: "Volcano Forge")
        case .clockwork: return String(localized: "Clockwork Works")
        case .storm: return String(localized: "Storm Coast")
        case .cosmos: return String(localized: "Orbital Station")
        }
    }

    var tagline: String {
        switch self {
        case .garden: return String(localized: "A sunny classic among the trees")
        case .desert: return String(localized: "Hot sand and tricky dunes")
        case .jungle: return String(localized: "Swinging vines and ancient portals")
        case .ice: return String(localized: "Slick ice and drifting floes")
        case .neon: return String(localized: "Glowing challenge after dark")
        case .volcano: return String(localized: "Lava, geysers and iron gates")
        case .clockwork: return String(localized: "Brass gears, turntables and cannons")
        case .storm: return String(localized: "Gale winds and long jumps over the surf")
        case .cosmos: return String(localized: "Loops, tractor beams and the void")
        }
    }

    var symbolName: String {
        switch self {
        case .garden: return "leaf.fill"
        case .desert: return "sun.max.fill"
        case .jungle: return "tree.fill"
        case .ice: return "snowflake"
        case .neon: return "sparkles"
        case .volcano: return "flame.fill"
        case .clockwork: return "gearshape.fill"
        case .storm: return "wind"
        case .cosmos: return "moon.stars.fill"
        }
    }

    /// Short difficulty label shown on the course cards.
    var difficultyLabel: String {
        switch self {
        case .garden: return String(localized: "Beginner")
        case .desert: return String(localized: "Easy")
        case .jungle: return String(localized: "Medium")
        case .ice: return String(localized: "Hard")
        case .neon: return String(localized: "Very hard")
        case .volcano: return String(localized: "Expert")
        case .clockwork: return String(localized: "Master")
        case .storm: return String(localized: "Brutal")
        case .cosmos: return String(localized: "Legendary")
        }
    }

    /// The course that unlocks after finishing this one.
    var next: CourseType? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    /// The course that has to be cleared before this one opens.
    var previous: CourseType? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return nil }
        return all[index - 1]
    }
}
