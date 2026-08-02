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

    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "minigolf.haptics") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "minigolf.haptics") }
    }

    private init() {}

    func light() {
        guard enabled else { return }
        lightImpact.impactOccurred()
    }

    func impact(intensity: CGFloat) {
        guard enabled else { return }
        mediumImpact.impactOccurred(intensity: min(max(intensity, 0.1), 1))
    }

    func success() {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    func error() {
        guard enabled else { return }
        notification.notificationOccurred(.error)
    }
}
