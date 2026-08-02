//
//  MainMenuView.swift
//  Minigolf
//

import SwiftUI

struct MainMenuView: View {
    let controller: GameController
    @State private var showSettings = false
    @State private var swing = false

    var body: some View {
        ZStack {
            MenuBackground(colors: [
                Color(red: 0.16, green: 0.52, blue: 0.30),
                Color(red: 0.07, green: 0.32, blue: 0.20),
            ])

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("⛳️")
                        .font(.system(size: 78))
                        .rotationEffect(.degrees(swing ? 6 : -6))
                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                                   value: swing)
                        .onAppear { swing = true }

                    Text("MINIGOLF")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color(red: 0.85, green: 0.98, blue: 0.8)],
                                           startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 3)

                    Text("\(CourseType.allCases.count) worlds. \(LevelLibrary.totalHoles) holes. One champion.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)

                    if controller.progress.holesFinished > 0 {
                        HStack(spacing: 8) {
                            HUDChip(text: String(localized: "\(controller.progress.holesFinished)/\(LevelLibrary.totalHoles) holes"),
                                    systemImage: "flag.fill")
                            HUDChip(text: "\(controller.progress.starsEarned)/\(LevelLibrary.totalHoles * HoleStars.max)",
                                    systemImage: "star.fill")
                            HUDChip(text: "\(controller.progress.totalBonusStars)/\(LevelLibrary.totalBonusStars)",
                                    systemImage: "sparkles")
                        }
                        .padding(.top, 12)
                    }

                    DailyChallengeCard(controller: controller)
                        .padding(.top, 18)

                    VStack(spacing: 12) {
                        Button {
                            SoundManager.shared.play(.tap)
                            controller.goToCourseSelect()
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            SoundManager.shared.play(.tap)
                            controller.goToClubhouse()
                        } label: {
                            Label("Clubhouse", systemImage: "figure.golf")
                                .overlay(alignment: .topTrailing) {
                                    if controller.unseenSkinCount > 0 {
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 9, height: 9)
                                            .offset(x: 10, y: -4)
                                    }
                                }
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        if controller.progress.allCompleted {
                            Button {
                                SoundManager.shared.play(.tap)
                                controller.showFinalRating()
                            } label: {
                                Label("My Golf Rating", systemImage: "trophy.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        Button {
                            SoundManager.shared.play(.tap)
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.top, 20)

                    Text(verbatim: "v\(AppInfo.version)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 18)
                }
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Daily challenge

/// The one card that gives a reason to open the app on a Tuesday: today's hole,
/// how it went, and how long the streak has run.
private struct DailyChallengeCard: View {
    let controller: GameController

    private var day: String { GameDay.key() }
    private var level: LevelDefinition { DailyChallenge.level(for: day) }
    private var todaysScore: Int? { controller.stats.dailyBest[day] }
    private var streak: Int { controller.stats.liveDailyStreak(today: day) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 15, weight: .bold))
                Text("Daily Challenge")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                Spacer(minLength: 0)
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.orange)
                }
            }
            .foregroundStyle(.white)

            HStack(spacing: 10) {
                Image(systemName: level.course.symbolName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white.opacity(0.18)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(level.course.displayName) · Hole \(level.number) · Par \(level.par)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 0)

                if let score = todaysScore {
                    let medal = DailyMedal.medal(strokes: score, par: level.par)
                    VStack(spacing: 2) {
                        Image(systemName: medal.symbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.yellow)
                        Text("\(score)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }
            }

            Button {
                SoundManager.shared.play(.tap)
                controller.startDailyChallenge()
            } label: {
                Label(todaysScore == nil ? "Play Today's Hole" : "Beat Your Score",
                      systemImage: todaysScore == nil ? "play.fill" : "arrow.counterclockwise")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(.white.opacity(todaysScore == nil ? 0.32 : 0.18)))
            }
            .buttonStyle(.plain)

            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(resetText(now: context.date))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [level.course.theme.uiPrimary,
                                              level.course.theme.uiPrimary.opacity(0.55)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func resetText(now: Date) -> String {
        let remaining = Int(GameDay.secondsUntilTomorrow(from: now))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return hours > 0
            ? String(localized: "New hole in \(hours)h \(minutes)m")
            : String(localized: "New hole in \(minutes)m")
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soundOn = SoundManager.shared.soundEnabled
    @State private var musicOn = SoundManager.shared.musicEnabled
    @State private var hapticsOn = Haptics.shared.enabled
    @State private var aimGuide = GameSettings.shared.aimGuide
    @State private var ballTrail = GameSettings.shared.ballTrail

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // A segmented picker drops its own label inside a List, so
                    // the row carries the heading itself.
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Aim Guide", systemImage: "scope")
                        Picker("Aim Guide", selection: $aimGuide) {
                            ForEach(AimGuideLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: aimGuide) { _, value in
                            GameSettings.shared.aimGuide = value
                        }
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $ballTrail) {
                        Label("Ball Trail", systemImage: "wind")
                    }
                    .onChange(of: ballTrail) { _, value in
                        GameSettings.shared.ballTrail = value
                    }
                } header: {
                    Text("Gameplay")
                } footer: {
                    Text(aimGuide.detail)
                }

                Section("Audio") {
                    Toggle(isOn: $soundOn) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }
                    .onChange(of: soundOn) { _, value in
                        SoundManager.shared.soundEnabled = value
                    }
                    Toggle(isOn: $musicOn) {
                        Label("Music", systemImage: "music.note")
                    }
                    .onChange(of: musicOn) { _, value in
                        SoundManager.shared.musicEnabled = value
                    }
                }
                Section("Feedback") {
                    Toggle(isOn: $hapticsOn) {
                        Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticsOn) { _, value in
                        Haptics.shared.enabled = value
                    }
                }
                Section {
                    LabeledContent("Version", value: AppInfo.version)
                } footer: {
                    Text("Drag anywhere on the course to aim, release to shoot. Finish every hole within the stroke limit!")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
