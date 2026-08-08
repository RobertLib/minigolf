//
//  Motion.swift
//  Minigolf
//
//  Reduce Motion, read once and answered the same way on both sides of the app.
//

import SwiftUI
import UIKit

/// Whether the player has asked the system for less movement.
///
/// SwiftUI has `\.accessibilityReduceMotion`, which is the right way to read
/// this inside a view and the only one that redraws it when the switch is
/// thrown. The scene coordinator is not a view and has no environment to read,
/// so it asks UIKit directly — once, as the hole is built, which is the only
/// moment it could act on the answer anyway.
enum Motion {

    static var reduced: Bool { UIAccessibility.isReduceMotionEnabled }

    /// What a spring or a slide becomes for a player who has asked for less
    /// movement: a cross-fade. Not nothing — a card that swaps in with no
    /// transition at all is harder to follow than one that fades, and the point
    /// of the setting is to remove the sweep, not the continuity.
    static let gentle = Animation.easeInOut(duration: 0.2)
}

// MARK: - SwiftUI

private struct MotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.gentle : animation, value: value)
    }
}

private struct MotionTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let moving: AnyTransition

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : moving)
    }
}

private struct MotionIdle<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        // A loop that never ends is the one kind of movement Reduce Motion is
        // least ambiguous about: there is no change to follow, so there is
        // nothing to soften it into. It simply stops, on its resting frame.
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

private struct PopIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let appeared: Bool
    let from: CGFloat
    let animation: Animation

    func body(content: Content) -> some View {
        // Same arrival either way, by a different route: the rating badge grows
        // into place, or — for a player who would rather it did not — fades in
        // at the size it is going to be.
        content
            .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : from))
            .opacity(!reduceMotion || appeared ? 1 : 0)
            .animation(reduceMotion ? Motion.gentle : animation, value: appeared)
    }
}

extension View {

    /// An element that arrives by growing into place from `from`, and by fading
    /// into place instead under Reduce Motion.
    func popIn(_ appeared: Bool, from: CGFloat, animation: Animation) -> some View {
        modifier(PopIn(appeared: appeared, from: from, animation: animation))
    }

    /// `animation(_:value:)`, softened to a cross-fade under Reduce Motion.
    func motionAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }

    /// `transition(_:)`, replaced by a plain fade under Reduce Motion.
    func motionTransition(_ moving: AnyTransition) -> some View {
        modifier(MotionTransition(moving: moving))
    }

    /// `animation(_:value:)` for an idling loop — a breathing glow, a drifting
    /// shimmer — which under Reduce Motion is dropped rather than shortened.
    func idleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionIdle(animation: animation, value: value))
    }
}
