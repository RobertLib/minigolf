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
            }

            overlayContent

            // Above the result card: an unlock announced the moment a hole ends
            // would otherwise be hidden behind it.
            if let toast = controller.toast {
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(toast.id)
            }

            if let achievement = controller.achievementBanner {
                AchievementBanner(achievement: achievement)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(achievement.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: controller.toast)
        .animation(.spring(response: 0.45, dampingFraction: 0.75),
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

    var body: some View {
        VStack {
            topBar
            Spacer()
            bottomArea
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var topBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                HUDChip(text: "\(controller.holeNumber)/\(controller.holeCount)",
                        systemImage: controller.course.symbolName)
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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(.black.opacity(0.35)))
                }
            }
            HStack(spacing: 8) {
                HUDChip(
                    text: String(localized: "Stroke \(controller.strokes)/\(controller.currentLevel.strokeLimit)"),
                    systemImage: "figure.golf")
                if !controller.isSingleHole {
                    HUDChip(text: String(localized: "Total \(formattedDiff(controller.runningDiff))"),
                            systemImage: "sum")
                }
                if controller.currentLevel.bonusStar != nil {
                    Image(systemName: controller.bonusStarInHand ? "sparkles" : "sparkle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(controller.bonusStarInHand ? .yellow : .white.opacity(0.55))
                        .padding(7)
                        .background(Circle().fill(.black.opacity(0.35)))
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
                .font(.system(size: 13, weight: .heavy, design: .rounded))
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.yellow.gradient))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trophy unlocked")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
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
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
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
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
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
