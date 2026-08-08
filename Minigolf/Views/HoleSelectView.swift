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
                        .scaledFont(18, weight: .bold, relativeTo: .headline)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .accessibilityLabel(Text("Back to course select"))
                Spacer()
            }
            .padding(.horizontal)

            Label(course.displayName, systemImage: course.symbolName)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                HUDChip(text: "\(starsEarned)/\(levels.count * HoleStars.max)",
                        systemImage: "star.fill",
                        voiceOverLabel: Text("\(starsEarned) of \(levels.count * HoleStars.max) stars"))
                HUDChip(text: "\(record.bonusStars.count)/\(LevelLibrary.bonusStarCount(course))",
                        systemImage: "sparkles",
                        voiceOverLabel: Text("\(record.bonusStars.count) of \(LevelLibrary.bonusStarCount(course)) bonus stars"))
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
                        .scaledFont(22, weight: .heavy, design: .rounded, relativeTo: .title2)
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    if hasBonusStar {
                        Image(systemName: bonusCollected ? "sparkles" : "sparkle")
                            .scaledFont(12, weight: .bold, relativeTo: .caption)
                            .foregroundStyle(bonusCollected ? .yellow : .white.opacity(0.35))
                    }
                }

                Text(level.name)
                    .scaledFont(11, weight: .semibold, design: .rounded, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 28, alignment: .top)

                HStack(spacing: 2) {
                    ForEach(0..<HoleStars.max, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .scaledFont(10, relativeTo: .caption2)
                            .foregroundStyle(i < stars ? .yellow : .white.opacity(0.3))
                    }
                    Spacer(minLength: 0)
                    Text(best.map { "\($0)" } ?? "–")
                        .scaledFont(12, weight: .heavy, design: .rounded, relativeTo: .caption)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.9))
                    Text("/\(level.par)")
                        .scaledFont(10, weight: .semibold, design: .rounded, relativeTo: .caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(10)
            .frame(minHeight: 96)
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
                                .scaledFont(20, weight: .bold, relativeTo: .title3)
                                .foregroundStyle(.white.opacity(0.85))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        // Read as one tile. Swiped through piece by piece it is a number, a
        // name, three anonymous stars and two more numbers, none of which say
        // what they are.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Hole \(level.number), \(level.name)"))
        .accessibilityValue(Text(spokenValue))
    }

    private var spokenValue: String {
        guard unlocked else { return String(localized: "Locked") }
        var parts = [
            best.map { String(localized: "best \($0), par \(level.par)") }
                ?? String(localized: "not played yet, par \(level.par)"),
            String(localized: "\(stars) out of \(HoleStars.max) stars"),
        ]
        if hasBonusStar {
            parts.append(bonusCollected
                         ? String(localized: "bonus star collected")
                         : String(localized: "bonus star still hidden"))
        }
        return parts.joined(separator: ", ")
    }
}
