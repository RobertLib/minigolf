//
//  CourseSelectView.swift
//  Minigolf
//

import SwiftUI

struct CourseSelectView: View {
    let controller: GameController

    var body: some View {
        ZStack {
            MenuBackground(colors: [
                Color(red: 0.10, green: 0.35, blue: 0.28),
                Color(red: 0.05, green: 0.18, blue: 0.16),
            ])

            VStack(spacing: 0) {
                HStack {
                    Button {
                        SoundManager.shared.play(.tap)
                        controller.goToMenu()
                    } label: {
                        Image(systemName: "chevron.left")
                            .scaledFont(18, weight: .bold, relativeTo: .headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    .accessibilityLabel(Text("Back to menu"))
                    Spacer()
                    ProgressChips(progress: controller.progress)
                }
                .padding(.horizontal)

                Text("Choose Your Course")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.top, 2)
                    .accessibilityAddTraits(.isHeader)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(CourseType.allCases) { course in
                            CourseCard(
                                course: course,
                                record: controller.progress.record(for: course),
                                unlocked: controller.progress.isUnlocked(course),
                                play: {
                                    SoundManager.shared.play(.tap)
                                    controller.startCourse(course)
                                },
                                browse: {
                                    SoundManager.shared.play(.tap)
                                    controller.goToHoleSelect(course)
                                }
                            )
                        }

                        if controller.progress.allCompleted {
                            Button {
                                SoundManager.shared.play(.tap)
                                controller.showFinalRating()
                            } label: {
                                Label("View Your Golf Rating", systemImage: "trophy.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.top, 6)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Collection totals shown next to the back button.
struct ProgressChips: View {
    let progress: GameProgress

    var body: some View {
        HStack(spacing: 8) {
            HUDChip(text: "\(progress.starsEarned)/\(LevelLibrary.totalHoles * HoleStars.max)",
                    systemImage: "star.fill",
                    voiceOverLabel: Text("\(progress.starsEarned) of \(LevelLibrary.totalHoles * HoleStars.max) stars"))
            HUDChip(text: "\(progress.totalBonusStars)/\(LevelLibrary.totalBonusStars)",
                    systemImage: "sparkles",
                    voiceOverLabel: Text("\(progress.totalBonusStars) of \(LevelLibrary.totalBonusStars) bonus stars"))
        }
    }
}

private struct CourseCard: View {
    let course: CourseType
    let record: CourseRecord
    let unlocked: Bool
    let play: () -> Void
    let browse: () -> Void

    private var coursePar: Int { LevelLibrary.coursePar(course) }
    private var holes: Int { LevelLibrary.holeCount(course) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: course.symbolName)
                    .scaledFont(28, weight: .bold, relativeTo: .title)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.white.opacity(0.2)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(course.displayName)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(course.tagline)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)

                if record.completed {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < record.stars ? "star.fill" : "star")
                                .scaledFont(13, relativeTo: .footnote)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(record.stars) out of 3 stars"))
                }
            }

            HStack(spacing: 8) {
                HUDChip(text: course.difficultyLabel, systemImage: "chart.bar.fill")
                HUDChip(text: String(localized: "\(holes) holes · Par \(coursePar)"),
                        systemImage: "flag.fill")
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                if let best = record.bestTotal {
                    HUDChip(text: String(localized: "Best \(best) (\(formattedDiff(best - coursePar)))"),
                            systemImage: "rosette")
                } else if record.holesPlayed > 0 {
                    HUDChip(text: String(localized: "Reached hole \(record.holesPlayed)"),
                            systemImage: "figure.golf")
                }
                if !record.bonusStars.isEmpty {
                    HUDChip(text: "\(record.bonusStars.count)/\(LevelLibrary.bonusStarCount(course))",
                            systemImage: "sparkles")
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button(action: play) {
                    Label("Play", systemImage: "play.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.white.opacity(0.28)))
                }
                // Which world the button belongs to is carried by the card it
                // sits on, which a listener stepping straight onto the button
                // never sees.
                .accessibilityLabel(Text("Play \(course.displayName)"))
                Button(action: browse) {
                    Label("Holes", systemImage: "square.grid.3x3.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(.white.opacity(0.16)))
                }
                .accessibilityLabel(Text("Holes in \(course.displayName)"))
            }
            .buttonStyle(.plain)
            .disabled(!unlocked)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [course.theme.uiPrimary,
                                              course.theme.uiPrimary.opacity(0.65)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        )
        .overlay {
            if !unlocked {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.black.opacity(0.6))
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .scaledFont(26, weight: .bold, relativeTo: .title2)
                                .accessibilityHidden(true)
                            Text("Finish the previous course to unlock")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                    )
            }
        }
    }
}
