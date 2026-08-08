//
//  GameView.swift
//  Minigolf
//
//  The playable screen: RealityKit view, gestures, HUD and overlays.
//

import SwiftUI
import RealityKit

/// Container that persists across holes; the inner RealityView is rebuilt
/// per hole via .id(sceneToken).
struct GameContainerView: View {
    let controller: GameController

    var body: some View {
        ZStack {
            GameSceneView(controller: controller, level: controller.currentLevel)
                .id(controller.sceneToken)
                .ignoresSafeArea()

            HUDView(controller: controller)

            if controller.introRunning {
                IntroBanner(level: controller.currentLevel)
                    .transition(.opacity)
                    .accessibilityAddTraits(.isHeader)
            }

            overlayContent

            // Above the result card: an unlock announced the moment a hole ends
            // would otherwise be hidden behind it.
            if let toast = controller.toast {
                ToastView(toast: toast)
                    .motionTransition(.move(edge: .top).combined(with: .opacity))
                    .id(toast.id)
            }

            if let achievement = controller.achievementBanner {
                AchievementBanner(achievement: achievement)
                    .motionTransition(.move(edge: .bottom).combined(with: .opacity))
                    .id(achievement.id)
            }
        }
        // Penalties, unlocks and trophies show themselves for a couple of
        // seconds and then leave, which is well inside the time it takes to
        // swipe over and find them. They are spoken as they appear instead.
        .onChange(of: controller.toast?.id) { _, _ in
            announce(controller.toast?.text)
        }
        .onChange(of: controller.achievementBanner?.id) { _, _ in
            announce(controller.achievementBanner.map {
                String(localized: "Trophy unlocked: \($0.title)")
            })
        }
        .motionAnimation(.spring(response: 0.4, dampingFraction: 0.8), value: controller.toast)
        .motionAnimation(.spring(response: 0.45, dampingFraction: 0.75),
                         value: controller.achievementBanner?.id)
        .animation(.easeInOut(duration: 0.3), value: controller.introRunning)
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch controller.overlay {
        case .none:
            if !controller.tutorialSeen, !controller.introRunning {
                TutorialOverlay(controller: controller)
            }
        case .paused:
            OverlayBackdrop()
            PauseOverlay(controller: controller)
        case .holeComplete(let result):
            OverlayBackdrop()
            HoleCompleteOverlay(controller: controller, result: result)
        case .courseSuccess(let summary):
            OverlayBackdrop()
            CourseSuccessOverlay(controller: controller, summary: summary)
        case .gameOver:
            OverlayBackdrop()
            GameOverOverlay(controller: controller)
        }
    }
}

/// One RealityKit scene = one hole attempt.
private struct GameSceneView: View {
    let controller: GameController
    @State private var coordinator: GameSceneCoordinator

    init(controller: GameController, level: LevelDefinition) {
        self.controller = controller
        _coordinator = State(initialValue: GameSceneCoordinator(level: level,
                                                                controller: controller))
    }

    var body: some View {
        GeometryReader { proxy in
            RealityView { content in
                // Built before the scene is touched: a static collision mesh can
                // only be generated off the main actor, and awaiting one with the
                // content already in hand would hold it across the suspension.
                let floorShapes = await SceneBuilder.floorShapes(of: coordinator.level)
                coordinator.build(content: &content, floorShapes: floorShapes)
                coordinator.viewSizeChanged(size: proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                coordinator.viewSizeChanged(size: newSize)
            }
            .onChange(of: controller.isPaused) { _, paused in
                coordinator.pauseStateChanged(paused: paused)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        coordinator.aimChanged(translation: value.translation)
                    }
                    .onEnded { _ in
                        coordinator.aimEnded()
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        coordinator.pinchChanged(magnification: Float(value.magnification))
                    }
                    .onEnded { _ in
                        coordinator.pinchEnded()
                    }
            )
        }
    }
}

// MARK: - HUD

struct HUDView: View {
    let controller: GameController
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack {
            topBar
            Spacer()
            bottomArea
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        // The HUD sits on top of the hole rather than beside it, so it is the
        // one surface where the largest accessibility sizes would cover the
        // thing being played. It grows with the reader up to a point and stops.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var topBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // At the accessibility sizes the top row runs out of width, and
                // the hole total is the one number on it that never changes —
                // dropping it beats letting the counter truncate to "6/…".
                HUDChip(text: typeSize.isAccessibilitySize
                              ? "\(controller.holeNumber)"
                              : "\(controller.holeNumber)/\(controller.holeCount)",
                        systemImage: controller.course.symbolName,
                        voiceOverLabel: Text("\(controller.course.displayName), hole \(controller.holeNumber) of \(controller.holeCount)"))
                HUDChip(text: String(localized: "Par \(controller.currentLevel.par)"),
                        systemImage: "flag.fill")
                Spacer()
                if controller.isDaily {
                    HUDChip(text: String(localized: "Daily"), systemImage: "calendar")
                } else if controller.isPractice {
                    HUDChip(text: String(localized: "Practice"), systemImage: "target")
                } else {
                    LivesView(lives: controller.lives)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(.black.opacity(0.35)))
                }
                Button {
                    controller.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .scaledFont(15, weight: .bold, relativeTo: .subheadline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(.black.opacity(0.35)))
                }
                .accessibilityLabel(Text("Pause"))
            }
            HStack(spacing: 8) {
                HUDChip(
                    text: String(localized: "Stroke \(controller.strokes)/\(controller.currentLevel.strokeLimit)"),
                    systemImage: "figure.golf")
                if !controller.isSingleHole {
                    HUDChip(text: String(localized: "Total \(formattedDiff(controller.runningDiff))"),
                            systemImage: "sum",
                            voiceOverLabel: Text("Total \(controller.runningDiff) against par"))
                }
                if controller.currentLevel.bonusStar != nil {
                    Image(systemName: controller.bonusStarInHand ? "sparkles" : "sparkle")
                        .scaledFont(13, weight: .bold, relativeTo: .caption)
                        .foregroundStyle(controller.bonusStarInHand ? .yellow : .white.opacity(0.55))
                        .padding(7)
                        .background(Circle().fill(.black.opacity(0.35)))
                        .accessibilityLabel(controller.bonusStarInHand
                                            ? Text("Bonus star collected")
                                            : Text("Bonus star not collected yet"))
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var bottomArea: some View {
        VStack(spacing: 10) {
            if controller.isAiming {
                PowerBar(controller: controller)
                    .transition(.opacity)
            } else if !controller.ballInMotion, !controller.introRunning,
                      controller.strokes == 0, controller.holeNumber == 1,
                      controller.tutorialSeen {
                Text("Drag back to aim · release to shoot")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(.black.opacity(0.35)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: controller.isAiming)
        .padding(.bottom, 6)
    }
}

/// Reads `aimPower` inside its own body rather than taking it as a parameter, so
/// the strength readout follows the drag without pulling the rest of the HUD —
/// chips, localized lookups, the running total — through a rebuild on every
/// touch event. `HUDView` only ever reads `isAiming`, which flips twice a shot.
private struct PowerBar: View {
    let controller: GameController

    var body: some View {
        VStack(spacing: 5) {
            Text("\(Int((controller.aimPower * 100).rounded()))%")
                .scaledFont(13, weight: .heavy, design: .rounded, relativeTo: .caption)
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.4))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .orange, .red],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(12, proxy.size.width * CGFloat(controller.aimPower)))
                    // Quarter marks, so the same strength can be dialled in twice.
                    HStack(spacing: 0) {
                        ForEach(1..<4, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(.white.opacity(0.35))
                                .frame(width: 1)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 230, height: 14)
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Shot power"))
        .accessibilityValue(Text("\(Int((controller.aimPower * 100).rounded())) percent"))
    }
}

// MARK: - Achievement banner

private struct AchievementBanner: View {
    let achievement: Achievement

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: achievement.symbol)
                    .scaledFont(20, weight: .bold, relativeTo: .title3)
                    .foregroundStyle(.black.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.yellow.gradient))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trophy unlocked")
                        .scaledFont(11, weight: .bold, design: .rounded, relativeTo: .caption2)
                        .foregroundStyle(.yellow)
                    Text(achievement.title)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.yellow.opacity(0.5), lineWidth: 1)
            )
            .padding(.bottom, 44)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Banners & toasts

private struct IntroBanner: View {
    let level: LevelDefinition

    var body: some View {
        VStack {
            VStack(spacing: 4) {
                Text(level.course.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Hole \(level.number)")
                    .scaledFont(34, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                    .foregroundStyle(.white)
                Text(level.name)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Par \(level.par)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.black.opacity(0.45))
            )
            .padding(.top, 90)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

private struct ToastView: View {
    let toast: Toast

    var body: some View {
        VStack {
            Label(toast.text, systemImage: toast.symbol)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Capsule().fill(.black.opacity(0.6)))
                .padding(.top, 120)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Tutorial

private struct TutorialOverlay: View {
    let controller: GameController
    @State private var visible = true

    var body: some View {
        if visible {
            VStack {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "hand.draw.fill")
                        .scaledFont(44, relativeTo: .largeTitle)
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                    Text("How to Play")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Touch anywhere and drag away from your target — like pulling back a slingshot. The further you drag, the harder the shot. Release to putt!")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    Button {
                        SoundManager.shared.play(.tap)
                        controller.tutorialSeen = true
                        visible = false
                    } label: {
                        Text("Got It!")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.black.opacity(0.65))
                )
                .padding(30)
                Spacer().frame(height: 40)
            }
        }
    }
}
