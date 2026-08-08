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
                        .scaledFont(78, relativeTo: .largeTitle)
                        .rotationEffect(.degrees(swing ? 6 : -6))
                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                                   value: swing)
                        .onAppear { swing = true }
                        .accessibilityHidden(true)

                    Text("MINIGOLF")
                        .scaledFont(52, weight: .heavy, design: .rounded, relativeTo: .largeTitle)
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color(red: 0.85, green: 0.98, blue: 0.8)],
                                           startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
                        .accessibilityAddTraits(.isHeader)

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
                                    systemImage: "star.fill",
                                    voiceOverLabel: Text("\(controller.progress.starsEarned) of \(LevelLibrary.totalHoles * HoleStars.max) stars"))
                            HUDChip(text: "\(controller.progress.totalBonusStars)/\(LevelLibrary.totalBonusStars)",
                                    systemImage: "sparkles",
                                    voiceOverLabel: Text("\(controller.progress.totalBonusStars) of \(LevelLibrary.totalBonusStars) bonus stars"))
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
                        // The red dot is the only thing saying a ball is
                        // waiting, and a dot reads as nothing at all.
                        .accessibilityLabel(controller.unseenSkinCount > 0
                                            ? Text("Clubhouse, \(controller.unseenSkinCount) new balls")
                                            : Text("Clubhouse"))

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
                    .scaledFont(15, weight: .bold, relativeTo: .subheadline)
                    .accessibilityHidden(true)
                Text("Daily Challenge")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.orange)
                        .accessibilityLabel(Text("\(streak) day streak"))
                }
            }
            .foregroundStyle(.white)

            HStack(spacing: 10) {
                Image(systemName: level.course.symbolName)
                    .scaledFont(20, weight: .bold, relativeTo: .title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white.opacity(0.18)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(level.course.displayName) · Hole \(level.number) · Par \(level.par)")
                        .scaledFont(11, design: .rounded, relativeTo: .caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 0)

                if let score = todaysScore {
                    let medal = DailyMedal.medal(strokes: score, par: level.par)
                    VStack(spacing: 2) {
                        Image(systemName: medal.symbol)
                            .scaledFont(18, weight: .bold, relativeTo: .headline)
                            .foregroundStyle(.yellow)
                        Text("\(score)")
                            .scaledFont(15, weight: .heavy, design: .rounded,
                                        relativeTo: .subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                    // The medal is drawn as a symbol and its meaning is
                    // entirely in which symbol it is.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Today's score \(score), \(medal.label)"))
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
                    .scaledFont(11, design: .rounded, relativeTo: .caption2)
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

                Section {
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
                    // Not decoration: part of the soundtrack is CC-BY, and the
                    // credit is a condition of the licence rather than a
                    // courtesy. It has to name the works as well as the people,
                    // and be somewhere a player can actually reach — which is
                    // why it is a screen here and not a line in the store
                    // listing.
                    NavigationLink {
                        MusicCreditsView()
                    } label: {
                        Label("Music Credits", systemImage: "text.badge.star")
                    }
                } header: {
                    Text("Audio")
                } footer: {
                    // No licence version in the sentence: the tracks are under
                    // several, and each row states its own.
                    Text("Music by \(MusicCredit.authorList), used under Creative Commons licences.")
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
