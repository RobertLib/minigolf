//
//  ClubhouseView.swift
//  Minigolf
//
//  The player's own corner of the game: pick a ball, read your career numbers,
//  and see how far along the long-haul goals are.
//

import SwiftUI

struct ClubhouseView: View {
    let controller: GameController

    var body: some View {
        ZStack {
            MenuBackground(colors: [
                Color(red: 0.13, green: 0.30, blue: 0.42),
                Color(red: 0.06, green: 0.15, blue: 0.24),
            ])

            VStack(spacing: 0) {
                HStack {
                    Button {
                        SoundManager.shared.play(.tap)
                        controller.goToMenu()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    Spacer()
                    HUDChip(text: String(localized: "\(Achievements.earnedCount(stats: controller.stats, progress: controller.progress))/\(Achievements.all.count) trophies"),
                            systemImage: "trophy.fill")
                }
                .padding(.horizontal)

                Text("Clubhouse")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.top, 2)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        BallLockerSection(controller: controller)
                        CareerSection(stats: controller.stats, progress: controller.progress)
                        TrophySection(stats: controller.stats, progress: controller.progress)
                    }
                    .padding(20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Ball locker

private struct BallLockerSection: View {
    let controller: GameController

    private let columns = [GridItem(.adaptive(minimum: 82), spacing: 12)]

    var body: some View {
        SectionCard(title: String(localized: "Your Ball"), symbol: "circle.circle.fill") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BallSkin.allCases) { skin in
                    let unlocked = skin.isUnlocked(stats: controller.stats,
                                                   progress: controller.progress)
                    BallSwatch(skin: skin,
                               unlocked: unlocked,
                               selected: controller.selectedSkin == skin) {
                        controller.selectSkin(skin)
                    }
                }
            }
            Text(hint)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    private var hint: String {
        let locked = BallSkin.allCases.first {
            !$0.isUnlocked(stats: controller.stats, progress: controller.progress)
        }
        guard let locked else { return String(localized: "Every ball is yours. Show off.") }
        return String(localized: "Next up — \(locked.displayName): \(locked.requirement)")
    }
}

private struct BallSwatch: View {
    let skin: BallSkin
    let unlocked: Bool
    let selected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [.white.opacity(0.85), skin.uiColor],
                                           center: UnitPoint(x: 0.34, y: 0.28),
                                           startRadius: 1, endRadius: 42)
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    if !unlocked {
                        Circle()
                            .fill(.black.opacity(0.62))
                            .frame(width: 52, height: 52)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(selected ? .white : .white.opacity(0.25),
                                      lineWidth: selected ? 3 : 1)
                        .frame(width: 52, height: 52)
                )

                Text(unlocked ? skin.displayName : skin.requirement)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(unlocked ? 0.9 : 0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 26, alignment: .top)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}

// MARK: - Career numbers

private struct CareerSection: View {
    let stats: PlayerStats
    let progress: GameProgress

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 10)]

    var body: some View {
        SectionCard(title: String(localized: "Career"), symbol: "chart.bar.fill") {
            LazyVGrid(columns: columns, spacing: 10) {
                StatTile(value: "\(stats.holesCompleted)",
                         label: String(localized: "Holes played"), symbol: "figure.golf")
                StatTile(value: "\(stats.holeInOnes)",
                         label: String(localized: "Hole-in-ones"), symbol: "target")
                StatTile(value: "\(stats.birdiesOrBetter)",
                         label: String(localized: "Under par"), symbol: "bird.fill")
                StatTile(value: "\(stats.bestParStreak)",
                         label: String(localized: "Best par run"), symbol: "bolt.fill")
                StatTile(value: "\(stats.dayStreak)",
                         label: String(localized: "Day streak"), symbol: "flame.fill")
                StatTile(value: "\(stats.dailiesCompleted)",
                         label: String(localized: "Dailies done"), symbol: "calendar")
                StatTile(value: "\(progress.holesFinished)/\(LevelLibrary.totalHoles)",
                         label: String(localized: "Holes cleared"), symbol: "flag.fill")
                StatTile(value: "\(progress.starsEarned)/\(LevelLibrary.totalHoles * HoleStars.max)",
                         label: String(localized: "Stars"), symbol: "star.fill")
            }
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.yellow.opacity(0.9))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.white.opacity(0.1)))
    }
}

// MARK: - Trophies

private struct TrophySection: View {
    let stats: PlayerStats
    let progress: GameProgress

    var body: some View {
        SectionCard(title: String(localized: "Trophies"), symbol: "trophy.fill") {
            VStack(spacing: 8) {
                ForEach(sorted) { achievement in
                    TrophyRow(achievement: achievement, stats: stats, progress: progress)
                }
            }
        }
    }

    /// Earned ones sink to the bottom, so what is still in reach stays on top.
    private var sorted: [Achievement] {
        Achievements.all.sorted { lhs, rhs in
            let lhsDone = lhs.isEarned(stats: stats, progress: progress)
            let rhsDone = rhs.isEarned(stats: stats, progress: progress)
            if lhsDone != rhsDone { return !lhsDone }
            return lhs.fraction(stats: stats, progress: progress)
                > rhs.fraction(stats: stats, progress: progress)
        }
    }
}

private struct TrophyRow: View {
    let achievement: Achievement
    let stats: PlayerStats
    let progress: GameProgress

    private var earned: Bool { achievement.isEarned(stats: stats, progress: progress) }
    private var current: Int { achievement.progress(stats: stats, progress: progress) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(earned ? .black.opacity(0.75) : .white.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(Circle().fill(earned
                                          ? AnyShapeStyle(.yellow.gradient)
                                          : AnyShapeStyle(.white.opacity(0.12))))

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(achievement.detail)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)

                if !earned {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.14))
                            Capsule()
                                .fill(.yellow.opacity(0.85))
                                .frame(width: max(3, proxy.size.width
                                                  * achievement.fraction(stats: stats, progress: progress)))
                        }
                    }
                    .frame(height: 5)
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Text(earned ? "✓" : "\(current)/\(achievement.goal)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(earned ? .yellow : .white.opacity(0.6))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.white.opacity(earned ? 0.12 : 0.06)))
    }
}

// MARK: - Shared card

private struct SectionCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.09))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
    }
}
