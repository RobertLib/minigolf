//
//  FinalRatingView.swift
//  Minigolf
//
//  Shown once the player has finished every world: the overall golfer rating
//  with a summary of each course.
//

import SwiftUI

struct FinalRatingView: View {
    let controller: GameController
    @State private var appeared = false

    private var totalPar: Int { LevelLibrary.totalPar }
    private var totalBest: Int { controller.progress.overallBestTotal }
    private var rating: GolferRating {
        GolferRating.rating(totalStrokes: totalBest, totalPar: totalPar)
    }

    var body: some View {
        ZStack {
            MenuBackground(colors: [
                Color(red: 0.55, green: 0.38, blue: 0.05),
                Color(red: 0.25, green: 0.14, blue: 0.02),
            ])

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer().frame(height: 30)

                    Image(systemName: rating.symbol)
                        .scaledFont(84, relativeTo: .largeTitle)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange],
                                           startPoint: .top, endPoint: .bottom))
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                        .popIn(appeared, from: 0.2,
                               animation: .spring(response: 0.6, dampingFraction: 0.55))
                        .accessibilityHidden(true)

                    Text("You finished all \(LevelLibrary.totalHoles) holes!")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(rating.title)
                        .scaledFont(40, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(rating.message)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    HStack(spacing: 12) {
                        HUDChip(text: String(localized: "Total \(totalBest)"), systemImage: "sum")
                        HUDChip(text: String(localized: "Par \(totalPar)"), systemImage: "flag.fill")
                        HUDChip(text: formattedDiff(totalBest - totalPar),
                                systemImage: "chart.line.uptrend.xyaxis")
                    }

                    HStack(spacing: 12) {
                        HUDChip(text: "\(controller.progress.starsEarned)/\(LevelLibrary.totalHoles * HoleStars.max)",
                                systemImage: "star.fill",
                                voiceOverLabel: Text("\(controller.progress.starsEarned) of \(LevelLibrary.totalHoles * HoleStars.max) stars"))
                        HUDChip(text: "\(controller.progress.totalBonusStars)/\(LevelLibrary.totalBonusStars)",
                                systemImage: "sparkles",
                                voiceOverLabel: Text("\(controller.progress.totalBonusStars) of \(LevelLibrary.totalBonusStars) bonus stars"))
                    }

                    VStack(spacing: 10) {
                        ForEach(CourseType.allCases) { course in
                            courseRow(course)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    VStack(spacing: 10) {
                        Button {
                            SoundManager.shared.play(.tap)
                            controller.goToCourseSelect()
                        } label: {
                            Label("Beat Your Score", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(PrimaryButtonStyle(colors: [
                            Color(red: 0.85, green: 0.6, blue: 0.1),
                            Color(red: 0.6, green: 0.4, blue: 0.05),
                        ]))

                        Button {
                            SoundManager.shared.play(.tap)
                            controller.goToMenu()
                        } label: {
                            Label("Main Menu", systemImage: "house.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.top, 12)

                    Spacer().frame(height: 30)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            appeared = true
            SoundManager.shared.play(.success)
        }
    }

    private func courseRow(_ course: CourseType) -> some View {
        let record = controller.progress.record(for: course)
        let par = LevelLibrary.coursePar(course)
        return HStack {
            Image(systemName: course.symbolName)
                .scaledFont(18, weight: .bold, relativeTo: .headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(course.theme.uiPrimary))

            VStack(alignment: .leading, spacing: 1) {
                Text(course.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                if let best = record.bestTotal {
                    Text("Best \(best) · Par \(par) · \(formattedDiff(best - par))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
    }
}
