//
//  HoleSelectView.swift
//  Minigolf
//
//  Per-world hole picker. Doubles as the practice range: any hole the player
//  has already reached can be replayed on its own, with no lives at stake.
//

import SwiftUI

struct HoleSelectView: View {
    let controller: GameController

    private var course: CourseType { controller.browsingCourse }
    private var levels: [LevelDefinition] { LevelLibrary.levels(for: course) }
    private var record: CourseRecord { controller.progress.record(for: course) }

    private var starsEarned: Int {
        levels.reduce(0) { $0 + controller.progress.holeStars(course: course, hole: $1.number) }
    }

    var body: some View {
        ZStack {
            MenuBackground(colors: [
                course.theme.uiPrimary.opacity(0.85),
                course.theme.uiPrimary.opacity(0.35),
            ])

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 12)],
                              spacing: 12) {
                        ForEach(levels) { level in
                            HoleTile(
                                level: level,
                                best: record.holeBest[level.number],
                                stars: controller.progress.holeStars(course: course,
                                                                    hole: level.number),
                                hasBonusStar: level.bonusStar != nil,
                                bonusCollected: record.bonusStars.contains(level.number),
                                unlocked: controller.progress.isHoleUnlocked(course: course,
                                                                            hole: level.number)
                            ) {
                                SoundManager.shared.play(.tap)
                                controller.startPractice(course: course, hole: level.number)
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    Button {
                        SoundManager.shared.play(.tap)
                        controller.startCourse(course)
                    } label: {
                        Label("Play Full Course", systemImage: "flag.checkered")
                    }
                    .buttonStyle(PrimaryButtonStyle(colors: [
                        course.theme.uiPrimary,
                        course.theme.uiPrimary.opacity(0.7),
                    ]))
                    .padding(.top, 20)

                    Text("Practice a single hole as often as you like — no lives, no pressure.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    SoundManager.shared.play(.tap)
                    controller.goToCourseSelect()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                Spacer()
            }
            .padding(.horizontal)

            Label(course.displayName, systemImage: course.symbolName)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                HUDChip(text: "\(starsEarned)/\(levels.count * HoleStars.max)",
                        systemImage: "star.fill")
                HUDChip(text: "\(record.bonusStars.count)/\(LevelLibrary.bonusStarCount(course))",
                        systemImage: "sparkles")
                HUDChip(text: String(localized: "Par \(LevelLibrary.coursePar(course))"),
                        systemImage: "flag.fill")
            }
            .padding(.bottom, 12)
        }
    }
}

private struct HoleTile: View {
    let level: LevelDefinition
    let best: Int?
    let stars: Int
    let hasBonusStar: Bool
    let bonusCollected: Bool
    let unlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(level.number)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    if hasBonusStar {
                        Image(systemName: bonusCollected ? "sparkles" : "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(bonusCollected ? .yellow : .white.opacity(0.35))
                    }
                }

                Text(level.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 28, alignment: .top)

                HStack(spacing: 2) {
                    ForEach(0..<HoleStars.max, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(i < stars ? .yellow : .white.opacity(0.3))
                    }
                    Spacer(minLength: 0)
                    Text(best.map { "\($0)" } ?? "–")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.9))
                    Text("/\(level.par)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(10)
            .frame(height: 96)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(stars > 0 ? 0.22 : 0.13))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .overlay {
                if !unlocked {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.55))
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}
