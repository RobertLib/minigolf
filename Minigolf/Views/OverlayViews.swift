//
//  OverlayViews.swift
//  Minigolf
//
//  In-game overlays: hole complete, course success, game over and pause.
//

import SwiftUI

// MARK: - Hole complete

struct HoleCompleteOverlay: View {
    let controller: GameController
    let result: HoleResult
    @State private var appeared = false

    var body: some View {
        OverlayCard {
            Text(result.rating.emoji)
                .font(.system(size: 58))
                .scaleEffect(appeared ? 1 : 0.3)
                .animation(.spring(response: 0.45, dampingFraction: 0.55), value: appeared)

            Text(result.rating.title)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(result.rating.tint)
                .multilineTextAlignment(.center)

            Text(result.rating.subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            StarsView(count: result.stars, max: HoleStars.max, size: 26)

            HStack(spacing: 10) {
                HUDChip(text: String(localized: "Strokes \(result.strokes)"),
                        systemImage: "figure.golf")
                HUDChip(text: String(localized: "Par \(result.par)"), systemImage: "flag.fill")
            }

            if result.bonusStar {
                Label("Bonus star collected!", systemImage: "sparkles")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            if result.isNewBest {
                Label("New best on this hole!", systemImage: "rosette")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            if controller.isDaily {
                let streak = controller.stats.liveDailyStreak()
                Label("Daily streak: \(streak)", systemImage: "flame.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 10) {
                Button {
                    controller.advanceAfterHole(result)
                } label: {
                    Text(nextLabel)
                }
                .buttonStyle(PrimaryButtonStyle())

                if controller.isSingleHole {
                    Button {
                        controller.replayHole()
                    } label: {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if controller.isPractice {
                        Button {
                            controller.quitRun()
                        } label: {
                            Label("Hole List", systemImage: "square.grid.3x3.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
        }
        .onAppear { appeared = true }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private var nextLabel: LocalizedStringKey {
        if controller.isDaily { return "Back to Menu" }
        if controller.isPractice {
            return result.holeNumber < controller.holeCount ? "Next Hole" : "Hole List"
        }
        return result.isLastHole ? "Finish Course" : "Next Hole"
    }
}

// MARK: - Course success

struct CourseSuccessOverlay: View {
    let controller: GameController
    let summary: CourseSummary

    var body: some View {
        OverlayCard {
            Text("🏆")
                .font(.system(size: 54))

            Text("Course Complete!")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)

            Text(summary.course.displayName)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            StarsView(count: summary.stars)

            HStack(spacing: 10) {
                HUDChip(text: String(localized: "Total \(summary.total)"), systemImage: "sum")
                HUDChip(text: String(localized: "Par \(summary.coursePar)"), systemImage: "flag.fill")
                HUDChip(text: formattedDiff(summary.total - summary.coursePar),
                        systemImage: "chart.line.uptrend.xyaxis")
            }

            HStack(spacing: 10) {
                if summary.isNewBest {
                    Label("New personal best!", systemImage: "rosette")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.yellow)
                }
                Label("\(summary.bonusStars)/\(LevelLibrary.bonusStarCount(summary.course))",
                      systemImage: "sparkles")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }

            ScorecardView(summary: summary)

            VStack(spacing: 10) {
                Button {
                    controller.continueAfterSuccess(summary)
                } label: {
                    Text(summary.allCoursesCompleted && summary.course == CourseType.allCases.last
                         ? "See Your Rating" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    controller.retryCourse()
                } label: {
                    Label("Play Again", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

/// Scorecard grid, wrapped into rows of six so twelve holes still fit on an
/// iPhone in portrait.
private struct ScorecardView: View {
    let summary: CourseSummary

    private let perRow = 6

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(stride(from: 0, to: summary.holeScores.count, by: perRow)), id: \.self) { start in
                HStack(spacing: 4) {
                    ForEach(start..<min(start + perRow, summary.holeScores.count), id: \.self) { i in
                        VStack(spacing: 2) {
                            Text("\(i + 1)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("\(summary.holeScores[i])")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(color(score: summary.holeScores[i], par: par(at: i)))
                                )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func par(at index: Int) -> Int {
        index < summary.pars.count ? summary.pars[index] : 3
    }

    private func color(score: Int, par: Int) -> Color {
        if score < par { return .green }
        if score == par { return .blue }
        if score == par + 1 { return .orange }
        return .red.opacity(0.85)
    }
}

// MARK: - Game over

struct GameOverOverlay: View {
    let controller: GameController

    var body: some View {
        OverlayCard {
            Text("😢")
                .font(.system(size: 54))

            Text("Game Over")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.red)

            Text("You ran out of lives on hole \(controller.holeNumber). Practice makes perfect — give it another shot!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    controller.retryCourse()
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    controller.practiceCurrentHole()
                } label: {
                    Label("Practice This Hole", systemImage: "target")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    SoundManager.shared.play(.tap)
                    controller.goToCourseSelect()
                } label: {
                    Label("Course Select", systemImage: "list.bullet")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

// MARK: - Pause

struct PauseOverlay: View {
    let controller: GameController
    @State private var soundOn = SoundManager.shared.soundEnabled
    @State private var musicOn = SoundManager.shared.musicEnabled
    @State private var hapticsOn = Haptics.shared.enabled

    var body: some View {
        OverlayCard {
            Text("Paused")
                .font(.system(size: 30, weight: .heavy, design: .rounded))

            Text(controller.currentLevel.name)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                toggleButton(icon: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                             active: soundOn) {
                    soundOn.toggle()
                    SoundManager.shared.soundEnabled = soundOn
                }
                toggleButton(icon: musicOn ? "music.note" : "music.note.list",
                             active: musicOn) {
                    musicOn.toggle()
                    SoundManager.shared.musicEnabled = musicOn
                }
                toggleButton(icon: "iphone.radiowaves.left.and.right",
                             active: hapticsOn) {
                    hapticsOn.toggle()
                    Haptics.shared.enabled = hapticsOn
                }
            }

            VStack(spacing: 10) {
                Button {
                    controller.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    controller.restartHoleFromPause()
                } label: {
                    Label(controller.isSingleHole ? "Restart Hole" : "Restart Hole (−1 ❤️)",
                          systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!controller.canRestartHole)
                .opacity(controller.canRestartHole ? 1 : 0.5)

                Button {
                    controller.quitRun()
                } label: {
                    Label(quitLabel, systemImage: "xmark")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private var quitLabel: LocalizedStringKey {
        if controller.isDaily { return "Back to Menu" }
        if controller.isPractice { return "Back to Holes" }
        return "Quit Course"
    }

    private func toggleButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(active ? .white : .white.opacity(0.4))
                .frame(width: 52, height: 52)
                .background(Circle().fill(active ? .green.opacity(0.7) : .white.opacity(0.12)))
        }
    }
}
