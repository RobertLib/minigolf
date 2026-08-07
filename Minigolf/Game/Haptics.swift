//
//  Haptics.swift
//  Minigolf
//

import Foundation
import UIKit

final class Haptics {

    static let shared = Haptics()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    /// The settings toggle, mirrored in memory. Tested on every impact, and a
    /// ball working its way along the boards asks for several of those a second,
    /// which is no place for a `UserDefaults` lookup. Main thread only — so are
    /// the generators, which is the whole reason this cost cannot be posted
    /// elsewhere the way sound can.
    private var on: Bool

    var enabled: Bool {
        get { on }
        set {
            on = newValue
            UserDefaults.standard.set(newValue, forKey: "minigolf.haptics")
        }
    }

    private init() {
        on = UserDefaults.standard.object(forKey: "minigolf.haptics") as? Bool ?? true
    }

    /// Powers up the Taptic Engine ahead of a putt.
    ///
    /// This buys latency, not frame time: an idle engine still delivers the tap,
    /// just late enough that it reads as unrelated to the bounce that caused it.
    /// The engine idles back down by itself a moment after the last impact, so
    /// this is called when a stroke is being lined up rather than held open for
    /// the whole session.
    func prepare() {
        guard on else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    func light() {
        guard on else { return }
        lightImpact.impactOccurred()
    }

    func impact(intensity: CGFloat) {
        guard on else { return }
        mediumImpact.impactOccurred(intensity: min(max(intensity, 0.1), 1))
    }

    func success() {
        guard on else { return }
        notification.notificationOccurred(.success)
    }

    func error() {
        guard on else { return }
        notification.notificationOccurred(.error)
    }
}
