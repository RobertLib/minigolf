//
//  GameController.swift
//  Minigolf
//
//  Central game state machine: menus, course runs, lives, scoring.
//

import Foundation
import SwiftUI
import Observation

struct HoleResult {
    var holeNumber: Int
    var name: String
    var strokes: Int
    var par: Int
    var rating: HoleRating
    var stars: Int
    var isNewBest: Bool
    var bonusStar: Bool
    var isLastHole: Bool
}

struct CourseSummary {
    var course: CourseType
    var holeScores: [Int]
    var pars: [Int]
    var total: Int
    var coursePar: Int
    var stars: Int
    var isNewBest: Bool
    var bonusStars: Int
    var allCoursesCompleted: Bool
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var symbol: String
}

@Observable
final class GameController {

    enum Phase: Equatable {
        case menu
        case courseSelect
        case holeSelect
        case clubhouse
        case playing
        case finalRating
    }

    enum PlayOverlay {
        case none
        case paused
        case holeComplete(HoleResult)
        case courseSuccess(CourseSummary)
        case gameOver
    }

    /// A tour plays a whole world on a life budget; practice is a single hole,
    /// replayable as often as the player likes; daily is today's shared hole.
    enum RunMode {
        case tour
        case practice
        case daily
    }

    static let livesPerCourse = 4

    // MARK: - Published state

    private(set) var phase: Phase = .menu
    private(set) var overlay: PlayOverlay = .none
    private(set) var progress = GameProgress.load()
    private(set) var stats = PlayerStats.load()

    // Current run
    private(set) var course: CourseType = .garden
    private(set) var mode: RunMode = .tour
    private(set) var holeNumber = 1
    private(set) var strokes = 0
    private(set) var lives = GameController.livesPerCourse
    private(set) var holeScores: [Int] = []
    /// Bonus star picked up on the hole being played right now.
    private(set) var bonusStarInHand = false
    /// Changes whenever the 3D scene must be rebuilt from scratch.
    private(set) var sceneToken = UUID()

    /// The world whose hole list is on screen in `.holeSelect`.
    private(set) var browsingCourse: CourseType = .garden

    // Live HUD state fed by the scene coordinator
    private(set) var aimPower: Float = 0
    private(set) var isAiming = false
    var ballInMotion = false
    var introRunning = false

    var toast: Toast?
    private var toastDismissTask: Task<Void, Never>?

    /// Achievement currently being celebrated, plus the ones queued behind it.
    private(set) var achievementBanner: Achievement?
    private var achievementQueue: [Achievement] = []
    private var achievementTask: Task<Void, Never>?

    /// Day key of the daily challenge being played right now.
    private(set) var dailyDay = GameDay.key()
    /// Penalties taken in the current tour, for the clean-round achievement.
    private var runPenalties = 0
    /// Holes finished at or under par back to back, across the whole session.
    private var parStreak = 0
    /// Skins announced by a toast already, so the same unlock is only shouted
    /// about once per launch even if several holes finish afterwards.
    private var announcedSkins: Set<String> = []

    var currentLevel: LevelDefinition {
        LevelLibrary.level(course: course, number: holeNumber)
    }

    var holeCount: Int {
        LevelLibrary.holeCount(course)
    }

    /// The music loop belonging to whatever is on screen. Playing a world starts
    /// at its hole list, so the theme has already introduced itself by the time
    /// the first shot is taken.
    var musicTrack: MusicTrack {
        switch phase {
        case .playing: return MusicTrack(course: course)
        case .holeSelect: return MusicTrack(course: browsingCourse)
        case .menu, .courseSelect, .clubhouse, .finalRating: return .menu
        }
    }

    var isPractice: Bool { mode == .practice }
    var isDaily: Bool { mode == .daily }
    /// Single-hole modes: no lives, no course total, retry as often as you like.
    var isSingleHole: Bool { mode != .tour }

    var selectedSkin: BallSkin { BallSkin.named(stats.selectedSkin) }

    /// Skins unlocked but not yet looked at in the clubhouse.
    var unseenSkinCount: Int {
        BallSkin.unlocked(stats: stats, progress: progress)
            .count { !stats.seenSkins.contains($0.rawValue) }
    }

    /// True when the hole being played hides a star the player has not got yet.
    var hasUncollectedBonusStar: Bool {
        currentLevel.bonusStar != nil && !bonusStarInHand
            && !progress.record(for: course).bonusStars.contains(holeNumber)
    }

    /// Running score difference vs par for completed holes of this run.
    var runningDiff: Int {
        let pars = LevelLibrary.levels(for: course).map(\.par)
        var diff = 0
        for (i, score) in holeScores.enumerated() where i < pars.count {
            diff += score - pars[i]
        }
        return diff
    }

    /// Mirrored in memory rather than read straight off `UserDefaults` on every
    /// access: the HUD keys its "drag to aim" hint off this, and a bare defaults
    /// read is invisible to `@Observable`, so dismissing the tutorial would not
    /// redraw anything that depends on it.
    private var tutorialSeenFlag = UserDefaults.standard.bool(forKey: "minigolf.tutorialSeen")

    var tutorialSeen: Bool {
        get { tutorialSeenFlag }
        set {
            tutorialSeenFlag = newValue
            UserDefaults.standard.set(newValue, forKey: "minigolf.tutorialSeen")
        }
    }

    #if DEBUG
    init() {
        // Debug launch support: `-autostart <course> <hole>` jumps straight
        // into a hole; used by automated smoke tests.
        let args = ProcessInfo.processInfo.arguments

        // `-unlockall` fills in plausible progress for menu screenshots. It is
        // never written back to disk.
        if args.contains("-unlockall") {
            for course in CourseType.allCases {
                var record = CourseRecord()
                let holes = LevelLibrary.holeCount(course)
                for hole in 1...holes {
                    record.holeBest[hole] = LevelLibrary.level(course: course, number: hole).par
                        + (hole % 3 == 0 ? 1 : -1)
                }
                record.bonusStars = Set(1...max(1, holes / 2))
                record.completed = true
                record.bestTotal = LevelLibrary.coursePar(course) - 2
                record.stars = 2
                progress.records[course.rawValue] = record
            }

            // The clubhouse reads its career tiles, its trophy count and every
            // ball unlock out of `stats`, so the course records alone would
            // leave it showing "0 holes played" next to "108/108 cleared".
            // These numbers follow from the records above: two thirds of the
            // holes sit a shot under par, and every course best is par − 2.
            stats.holesCompleted = 168
            stats.totalStrokes = 592
            stats.holeInOnes = 6
            stats.birdiesOrBetter = 72
            stats.penalties = 21
            stats.coursesFinished = CourseType.allCases.count
            stats.bestParStreak = 11
            stats.bestCourseUnderPar = 2
            stats.cleanCourses = 3
            stats.dayStreak = 6
            stats.bestDayStreak = 9
            stats.daysPlayed = 24
            // Yesterday, not today — the streak still reads as live, but the
            // daily challenge stays unplayed so `-daily` opens on a playable
            // hole instead of on today's result.
            stats.lastDailyDay = GameDay.key(Date().addingTimeInterval(-86400))
            stats.dailyStreak = 6
            stats.bestDailyStreak = 9
            stats.dailiesCompleted = 14
            stats.seenSkins = Set(BallSkin.allCases.map(\.rawValue))
        }

        if args.contains("-finalrating") {
            phase = .finalRating
        } else if args.contains("-clubhouse") {
            phase = .clubhouse
        } else if args.contains("-daily") {
            tutorialSeen = true
            startDailyChallenge()
        } else if args.contains("-courseselect") {
            phase = .courseSelect
        } else if let index = args.firstIndex(of: "-holeselect"), args.count > index + 1,
                  let course = CourseType(rawValue: args[index + 1]) {
            browsingCourse = course
            phase = .holeSelect
        } else if let index = args.firstIndex(of: "-autostart"), args.count > index + 2,
           let course = CourseType(rawValue: args[index + 1]),
           let hole = Int(args[index + 2]),
           (1...LevelLibrary.holeCount(course)).contains(hole) {
            self.course = course
            browsingCourse = course
            lives = Self.livesPerCourse
            holeScores = Array(repeating: 3, count: hole - 1)
            phase = .playing
            holeNumber = hole
            tutorialSeen = true
        }
    }
    #endif

    // MARK: - Navigation

    func goToMenu() {
        overlay = .none
        phase = .menu
        prewarmMenuTextures()
    }

    func goToCourseSelect() {
        overlay = .none
        phase = .courseSelect
        // Every world with a live Play button, since any of them can be started
        // from this screen without passing through hole select first.
        prewarmTextures(for: CourseType.allCases.filter { progress.isUnlocked($0) })
    }

    func goToHoleSelect(_ course: CourseType) {
        overlay = .none
        browsingCourse = course
        phase = .holeSelect
        prewarmTextures(for: [course])
    }

    /// The daily hole is launched straight from the menu, so its world is the one
    /// worth having ready while the menu is up. Also called when the app opens on
    /// the menu, which no navigation method sees.
    func prewarmMenuTextures() {
        prewarmTextures(for: [DailyChallenge.pick().course])
    }

    /// Draws a world's textures ahead of time, off the main thread. Menus are the
    /// place for this: the work is the same either way, but here a long frame
    /// costs nothing, whereas inside a hole it is a visible hitch.
    ///
    /// The shared meshes go the same way, for the same reason. Unlike the
    /// textures they cannot be built off the main thread — `MeshResource` is
    /// main-actor only — so they are built here, on a menu, rather than moved
    /// off the thread that cannot escape them.
    private func prewarmTextures(for courses: [CourseType]) {
        Prim.prewarm()
        Scenery.prewarmSky()
        Task {
            for course in courses {
                await TextureFactory.prewarm(course: course)
            }
        }
    }

    func showFinalRating() {
        overlay = .none
        phase = .finalRating
    }

    func goToClubhouse() {
        overlay = .none
        phase = .clubhouse
        markSkinsSeen()
    }

    /// Opening the clubhouse clears the "new ball" badge.
    private func markSkinsSeen() {
        let unlocked = BallSkin.unlocked(stats: stats, progress: progress).map(\.rawValue)
        guard !Set(unlocked).isSubset(of: stats.seenSkins) else { return }
        stats.seenSkins.formUnion(unlocked)
        stats.save()
    }

    func selectSkin(_ skin: BallSkin) {
        guard skin.isUnlocked(stats: stats, progress: progress) else { return }
        SoundManager.shared.play(.tap)
        stats.selectedSkin = skin.rawValue
        stats.save()
    }

    // MARK: - Course run lifecycle

    func startCourse(_ course: CourseType) {
        self.course = course
        browsingCourse = course
        mode = .tour
        lives = Self.livesPerCourse
        holeScores = []
        runPenalties = 0
        overlay = .none
        phase = .playing
        startHole(1)
    }

    /// Today's shared hole. Playable straight from the menu, from any world,
    /// whether or not that world has been unlocked yet.
    func startDailyChallenge() {
        let day = GameDay.key()
        let pick = DailyChallenge.pick(for: day)
        dailyDay = day
        course = pick.course
        browsingCourse = pick.course
        mode = .daily
        lives = Self.livesPerCourse
        holeScores = []
        overlay = .none
        phase = .playing
        startHole(pick.hole)
    }

    /// Replays a single hole with no lives on the line and no course total.
    func startPractice(course: CourseType, hole: Int) {
        self.course = course
        browsingCourse = course
        mode = .practice
        lives = Self.livesPerCourse
        holeScores = []
        overlay = .none
        phase = .playing
        startHole(hole)
    }

    private func startHole(_ number: Int) {
        holeNumber = number
        strokes = 0
        setAim(power: 0, aiming: false)
        ballInMotion = false
        bonusStarInHand = false
        overlay = .none
        sceneToken = UUID()
    }

    // MARK: - Events from the scene

    /// Aim state arrives once per touch event of a drag, which is faster than the
    /// screen refreshes. `@Observable` notifies on assignment whether or not the
    /// value actually changed, and every notification costs a HUD rebuild on the
    /// same thread that renders the scene — so writes that change nothing are
    /// dropped here rather than at each of the half-dozen call sites.
    func setAim(power: Float, aiming: Bool) {
        if aimPower != power { aimPower = power }
        if isAiming != aiming { isAiming = aiming }
    }

    func registerStroke() {
        strokes += 1
        ballInMotion = true
    }

    /// Water / lava / out-of-bounds penalty. Called by the coordinator before
    /// respawning the ball.
    func registerPenalty(kind: OutOfBoundsKind) {
        strokes += 1
        runPenalties += 1
        stats.penalties += 1
        switch kind {
        case .water:
            showToast(String(localized: "Splash! +1 stroke"), symbol: "drop.fill")
        case .lava:
            showToast(String(localized: "Burned up! +1 stroke"), symbol: "flame.fill")
        case .outOfBounds:
            showToast(String(localized: "Out of bounds! +1 stroke"), symbol: "arrow.uturn.backward")
        }
        Haptics.shared.error()
    }

    /// The ball rolled through this hole's bonus star. It only counts toward the
    /// collection once the hole is actually finished.
    func collectBonusStar() {
        guard !bonusStarInHand else { return }
        bonusStarInHand = true
        showToast(String(localized: "Bonus star collected!"), symbol: "star.fill")
    }

    /// Ball came to rest after a shot; enforce the stroke limit.
    func ballRested() {
        ballInMotion = false
        guard case .none = overlay else { return }
        if strokes >= currentLevel.strokeLimit {
            failAttempt()
        }
    }

    func ballHoled() {
        ballInMotion = false
        // The drop is announced on a delay, by which time the player may have
        // paused and walked out of the run entirely. Pausing is fine — the
        // result card simply replaces the pause menu — but a run that has been
        // left must not be scored.
        guard phase == .playing else { return }
        let level = currentLevel
        let hole = holeNumber
        let taken = strokes
        let gotStar = bonusStarInHand

        var isNewBest = false
        progress.update(for: course) { record in
            isNewBest = record.registerHole(hole, strokes: taken)
            if gotStar { record.bonusStars.insert(hole) }
        }
        recordHoleStats(strokes: taken, par: level.par)

        let result = HoleResult(
            holeNumber: hole,
            name: level.name,
            strokes: taken,
            par: level.par,
            rating: HoleRating.rating(strokes: taken, par: level.par),
            stars: HoleStars.stars(strokes: taken, par: level.par),
            isNewBest: isNewBest,
            bonusStar: gotStar,
            isLastHole: mode == .tour && hole == holeCount
        )
        if mode == .tour {
            holeScores.append(taken)
        }
        Haptics.shared.success()
        overlay = .holeComplete(result)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-autoadvance") {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                self?.advanceAfterHole(result)
            }
        }
        #endif
    }

    // MARK: - Stats & achievements

    /// Folds a finished hole into the lifetime record, keeps the play-day and
    /// daily streaks alive, and hands anything newly earned to the banner queue.
    private func recordHoleStats(strokes: Int, par: Int) {
        stats.holesCompleted += 1
        stats.totalStrokes += strokes
        if strokes == 1 { stats.holeInOnes += 1 }
        if strokes < par { stats.birdiesOrBetter += 1 }
        if strokes <= par {
            parStreak += 1
            stats.bestParStreak = max(stats.bestParStreak, parStreak)
        } else {
            parStreak = 0
        }
        stats.registerPlayDay()
        if mode == .daily {
            stats.registerDaily(day: dailyDay, strokes: strokes)
        }
        stats.save()
        checkUnlocks()
    }

    private func checkUnlocks() {
        let earned = Achievements.newlyEarned(stats: stats, progress: progress)
        if !earned.isEmpty {
            for achievement in earned { stats.unlockedAchievements.insert(achievement.id) }
            stats.save()
            achievementQueue.append(contentsOf: earned)
            showNextAchievement()
        }

        let freshSkins = BallSkin.unlocked(stats: stats, progress: progress).filter {
            !stats.seenSkins.contains($0.rawValue) && !announcedSkins.contains($0.rawValue)
        }
        if let skin = freshSkins.first {
            for unlocked in freshSkins { announcedSkins.insert(unlocked.rawValue) }
            showToast(String(localized: "New ball unlocked: \(skin.displayName)"),
                      symbol: "circle.circle.fill")
        }
    }

    private func showNextAchievement() {
        guard achievementBanner == nil, !achievementQueue.isEmpty else { return }
        achievementBanner = achievementQueue.removeFirst()
        SoundManager.shared.play(.star, volume: 0.7)
        Haptics.shared.success()
        achievementTask?.cancel()
        achievementTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            self?.achievementBanner = nil
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.showNextAchievement()
        }
    }

    private func failAttempt() {
        Haptics.shared.error()
        // Practice and the daily never cost anything: the hole just starts over.
        if mode != .tour {
            showToast(String(localized: "Stroke limit reached! Try this hole again."),
                      symbol: "arrow.counterclockwise")
            SoundManager.shared.play(.fail)
            startHole(holeNumber)
            return
        }
        lives -= 1
        if lives > 0 {
            showToast(String(localized: "Stroke limit reached! Try this hole again."),
                      symbol: "heart.slash.fill")
            SoundManager.shared.play(.fail)
            startHole(holeNumber)
        } else {
            SoundManager.shared.play(.gameOver)
            overlay = .gameOver
        }
    }

    /// Restart the current hole from the pause menu (costs one life in a tour).
    func restartHoleFromPause() {
        if mode == .tour {
            guard lives > 1 else { return }
            lives -= 1
        }
        SoundManager.shared.play(.tap)
        startHole(holeNumber)
    }

    var canRestartHole: Bool {
        mode != .tour || lives > 1
    }

    func advanceAfterHole(_ result: HoleResult) {
        if mode == .daily {
            SoundManager.shared.play(.tap)
            goToMenu()
            return
        }
        if mode == .practice {
            SoundManager.shared.play(.tap)
            if holeNumber < holeCount {
                startHole(holeNumber + 1)
            } else {
                goToHoleSelect(course)
            }
            return
        }
        if result.isLastHole {
            finishCourse()
        } else {
            SoundManager.shared.play(.tap)
            startHole(holeNumber + 1)
        }
    }

    /// Single-hole modes: play the same hole again straight from the result card.
    func replayHole() {
        SoundManager.shared.play(.tap)
        startHole(holeNumber)
    }

    private func finishCourse() {
        let levels = LevelLibrary.levels(for: course)
        let pars = levels.map(\.par)
        let total = holeScores.reduce(0, +)
        let coursePar = pars.reduce(0, +)
        let previousBest = progress.record(for: course).bestTotal
        let scores = holeScores
        let finishedCourse = course

        progress.update(for: finishedCourse) { record in
            record.register(total: total, coursePar: coursePar, holeScores: scores)
        }

        stats.coursesFinished += 1
        if runPenalties == 0 { stats.cleanCourses += 1 }
        stats.bestCourseUnderPar = max(stats.bestCourseUnderPar, coursePar - total)
        stats.save()
        checkUnlocks()

        let summary = CourseSummary(
            course: finishedCourse,
            holeScores: scores,
            pars: pars,
            total: total,
            coursePar: coursePar,
            stars: CourseStars.stars(total: total, coursePar: coursePar),
            isNewBest: previousBest == nil || total < previousBest!,
            bonusStars: progress.bonusStarCount(for: finishedCourse),
            allCoursesCompleted: progress.allCompleted
        )
        SoundManager.shared.play(.success)
        Haptics.shared.success()
        overlay = .courseSuccess(summary)
    }

    func continueAfterSuccess(_ summary: CourseSummary) {
        if summary.allCoursesCompleted && summary.course == CourseType.allCases.last {
            showFinalRating()
        } else {
            goToCourseSelect()
        }
    }

    func retryCourse() {
        SoundManager.shared.play(.tap)
        startCourse(course)
    }

    /// Game over: drop into practice on the hole that ended the run.
    func practiceCurrentHole() {
        SoundManager.shared.play(.tap)
        startPractice(course: course, hole: holeNumber)
    }

    // MARK: - Pause

    var isPaused: Bool {
        if case .paused = overlay { return true }
        return false
    }

    func pause() {
        guard case .none = overlay, phase == .playing else { return }
        SoundManager.shared.play(.tap)
        overlay = .paused
    }

    func resume() {
        guard isPaused else { return }
        SoundManager.shared.play(.tap)
        overlay = .none
    }

    func quitRun() {
        SoundManager.shared.play(.tap)
        switch mode {
        case .practice: goToHoleSelect(course)
        case .daily: goToMenu()
        case .tour: goToCourseSelect()
        }
    }

    // MARK: - Toasts

    func showToast(_ text: String, symbol: String) {
        toastDismissTask?.cancel()
        toast = Toast(text: text, symbol: symbol)
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled {
                self?.toast = nil
            }
        }
    }
}

enum OutOfBoundsKind {
    case water
    case lava
    case outOfBounds
}
