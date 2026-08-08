//
//  RewardTests.swift
//  MinigolfTests
//
//  Trophies and balls. Both are long-horizon goals, so a target set out of
//  reach — or an unlock that fires on day one — is not something playing the
//  game will reveal for weeks.
//

import Testing
@testable import Minigolf

@MainActor
struct AchievementTests {

    /// The clubhouse keys its "already announced" set off these, and a
    /// duplicate would silently swallow one of the pair.
    @Test func identifiersAreUnique() {
        let ids = Achievements.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyTrophyIsDescribedAndReachable() {
        for achievement in Achievements.all {
            #expect(!achievement.title.isEmpty)
            #expect(!achievement.detail.isEmpty)
            #expect(!achievement.symbol.isEmpty)
            #expect(achievement.goal > 0)
        }
    }

    @Test func nothingIsEarnedOnAFreshSave() {
        let stats = PlayerStats()
        let progress = GameProgress()
        #expect(Achievements.earnedCount(stats: stats, progress: progress) == 0)
        for achievement in Achievements.all {
            #expect(!achievement.isEarned(stats: stats, progress: progress))
            #expect(achievement.fraction(stats: stats, progress: progress) == 0)
        }
    }

    /// The collection trophies are measured against the same totals the level
    /// files produce, so a tenth world would have to move both together.
    @Test func collectionGoalsMatchWhatTheGameContains() {
        func goal(_ id: String) -> Int? { Achievements.all.first { $0.id == id }?.goal }
        #expect(goal("allHoles") == LevelLibrary.totalHoles)
        #expect(goal("bonusAll") == LevelLibrary.totalBonusStars)
        #expect(goal("starsAll") == LevelLibrary.totalHoles * HoleStars.max)
        #expect(goal("worldTour") == CourseType.allCases.count)
    }

    @Test func progressIsCappedAtTheGoal() {
        var stats = PlayerStats()
        stats.holesCompleted = 10_000
        let progress = GameProgress()
        for achievement in Achievements.all {
            let current = achievement.progress(stats: stats, progress: progress)
            #expect(current <= achievement.goal)
            #expect(achievement.fraction(stats: stats, progress: progress) <= 1)
        }
    }

    @Test func newlyEarnedOnlyReportsWhatHasNotBeenSeen() {
        var stats = PlayerStats()
        var progress = GameProgress()
        stats.holesCompleted = 1

        let first = Achievements.newlyEarned(stats: stats, progress: progress)
        #expect(first.contains { $0.id == "firstHole" })

        for achievement in first { stats.unlockedAchievements.insert(achievement.id) }
        #expect(Achievements.newlyEarned(stats: stats, progress: progress).isEmpty)

        // Something new crossing its line still comes through.
        stats.holeInOnes = 1
        progress.records[CourseType.allCases[0].rawValue] = CourseRecord()
        #expect(Achievements.newlyEarned(stats: stats, progress: progress)
                    .contains { $0.id == "ace" })
    }
}

@MainActor
struct BallSkinTests {

    @Test func theClassicBallIsAlwaysAvailable() {
        #expect(BallSkin.classic.isUnlocked(stats: PlayerStats(), progress: GameProgress()))
        #expect(BallSkin.unlocked(stats: PlayerStats(), progress: GameProgress()) == [.classic])
    }

    @Test func everySkinIsDescribed() {
        for skin in BallSkin.allCases {
            #expect(!skin.displayName.isEmpty)
            #expect(!skin.requirement.isEmpty)
        }
    }

    /// The selected skin is stored as a raw string, so a save written by an
    /// older build — or a corrupted one — has to land somewhere valid.
    @Test func anUnknownNameFallsBackToTheClassic() {
        #expect(BallSkin.named("nonesuch") == .classic)
        #expect(BallSkin.named("") == .classic)
        for skin in BallSkin.allCases {
            #expect(BallSkin.named(skin.rawValue) == skin)
        }
    }

    @Test func aFinishedGameUnlocksEveryBall() {
        var stats = PlayerStats()
        var progress = GameProgress()
        stats.holesCompleted = LevelLibrary.totalHoles
        stats.holeInOnes = 1
        stats.bestDailyStreak = 7
        for course in CourseType.allCases {
            var record = CourseRecord()
            record.completed = true
            for level in LevelLibrary.levels(for: course) {
                record.holeBest[level.number] = level.par
                if level.bonusStar != nil { record.bonusStars.insert(level.number) }
            }
            progress.records[course.rawValue] = record
        }
        #expect(BallSkin.unlocked(stats: stats, progress: progress).count
                == BallSkin.allCases.count)
    }

    /// Each world-specific ball answers to its own world and not to a
    /// neighbour's — an easy thing to fumble in a nine-case switch.
    @Test(arguments: [(BallSkin.glacier, CourseType.ice),
                      (.neon, .neon),
                      (.magma, .volcano),
                      (.brass, .clockwork),
                      (.tempest, .storm),
                      (.nebula, .cosmos)])
    func worldBallsTrackTheirOwnWorld(skin: BallSkin, course: CourseType) {
        var progress = GameProgress()
        var record = CourseRecord()
        record.completed = true
        progress.records[course.rawValue] = record
        let stats = PlayerStats()

        #expect(skin.isUnlocked(stats: stats, progress: progress))
        #expect(!skin.isUnlocked(stats: stats, progress: GameProgress()))
    }
}
