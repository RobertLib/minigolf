//
//  GameSettings.swift
//  Minigolf
//
//  Player-facing gameplay preferences that are not audio or haptics.
//

import Foundation

/// How much help the aiming line gives. Off keeps the original feel; full is
/// the friendliest and the default, because reading a bank shot off a fixed
/// camera is the single hardest part of the game for a new player.
enum AimGuideLevel: String, CaseIterable, Identifiable, Codable {
    case off
    case short
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return String(localized: "Off")
        case .short: return String(localized: "Short")
        case .full: return String(localized: "Full")
        }
    }

    var detail: String {
        switch self {
        case .off: return String(localized: "Just the direction arrow.")
        case .short: return String(localized: "A short line, no bank shots.")
        case .full: return String(localized: "Full line with two bounces.")
        }
    }

    var maxBounces: Int {
        switch self {
        case .off: return 0
        case .short: return 0
        case .full: return 2
        }
    }

    /// Guide length in metres for a given draw strength.
    ///
    /// Measured against the real thing with `-calibrate` on plain felt: a putt
    /// rolls ≈0.28 m at 20 %, 0.76 m at 40 %, 1.16 m at 60 % and ≈2.4 m at full
    /// draw, which `2.3·power^1.2` tracks closely. Sand, mud and ice move the
    /// real number a long way either side, so the line is a good guess rather
    /// than a promise — but it is the right length on the surface the player
    /// spends most of their time on.
    func length(power: Float) -> Float {
        let roll = 2.3 * pow(max(power, 0), 1.2)
        switch self {
        case .off: return 0
        case .short: return min(roll, 1.1)
        case .full: return roll
        }
    }
}

final class GameSettings {

    static let shared = GameSettings()

    private init() {}

    var aimGuide: AimGuideLevel {
        get {
            let raw = UserDefaults.standard.string(forKey: "minigolf.aimGuide")
            return raw.flatMap(AimGuideLevel.init(rawValue:)) ?? .full
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "minigolf.aimGuide") }
    }

    var ballTrail: Bool {
        get { UserDefaults.standard.object(forKey: "minigolf.ballTrail") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "minigolf.ballTrail") }
    }
}
