//
//  GameProgressTests.swift
//  MinigolfTests
//
//  Unlocking and records. Getting these wrong either walls a player out of a
//  world they earned or hands them one they did not, and neither shows up until
//  somebody has played far enough to reach it.
//
//  Nothing here goes near `update(for:)` — that saves to `UserDefaults`, and a
//  test has no business writing to the device the app runs on.
//

import Testing
@testable import Minigolf

@MainActor
struct CourseUnlockTests {

    private func progress(completed: [CourseType]) -> GameProgress {
        var progress = GameProgress()
        for course in completed {
            var record = CourseRecord()
            record.completed = true
            progress.records[course.rawValue] = record
        }
        return progress
    }

    @Test func theFirstWorldIsAlwaysOpen() {
        let fresh = GameProgress()
        let first = CourseType.allCases[0]
        #expect(first.previous == nil)
        #expect(fresh.isUnlocked(first))
    }

    @Test func aFreshSaveOpensNothingElse() {
        let fresh = GameProgress()
        for course in CourseType.allCases.dropFirst() {
            #expect(!fresh.isUnlocked(course))
        }
    }

    @Test func finishingAWorldOpensTheNextOneAndNoMore() {
        let all = CourseType.allCases
        let progress = progress(completed: [all[0]])
        #expect(progress.isUnlocked(all[1]))
        for course in all.dropFirst(2) {
            #expect(!progress.isUnlocked(course))
        }
    }

    /// The chain has no gaps: clearing each world in turn opens exactly the
    /// next, all the way to the end.
    @Test func theChainReachesEveryWorld() {
        var cleared: [CourseType] = []
        for course in CourseType.allCases {
            #expect(progress(completed: cleared).isUnlocked(course))
            cleared.append(course)
        }
        #expect(progress(completed: cleared).allCompleted)
        #expect(progress(completed: cleared).completedCourseCount == CourseType.allCases.count)
    }
}

@MainActor
struct HoleUnlockTests {

    @Test func theFirstHoleOfAnOpenWorldIsPlayable() {
        let progress = GameProgress()
        #expect(progress.isHoleUnlocked(course: CourseType.allCases[0], hole: 1))
    }

    @Test func aLockedWorldLocksItsHolesToo() {
        let progress = GameProgress()
        let locked = CourseType.allCases[1]
        #expect(!progress.isHoleUnlocked(course: locked, hole: 1))
    }

    @Test func reachingAHoleOpensIt() {
        var progress = GameProgress()
        let course = CourseType.allCases[0]
        var record = CourseRecord()
        record.holeBest[3] = 4
        progress.records[course.rawValue] = record

        #expect(progress.isHoleUnlocked(course: course, hole: 3))  // played it
        #expect(progress.isHoleUnlocked(course: course, hole: 4))  // next one up
        #expect(!progress.isHoleUnlocked(course: course, hole: 5))
    }

    @Test func clearingAWorldOpensAllOfIt() {
        var progress = GameProgress()
        let course = CourseType.allCases[0]
        var record = CourseRecord()
        record.completed = true
        progress.records[course.rawValue] = record

        for hole in 1...LevelLibrary.holeCount(course) {
            #expect(progress.isHoleUnlocked(course: course, hole: hole))
        }
    }
}

@MainActor
struct CourseRecordTests {

    /// The first time round there is no previous best to beat, so the result
    /// card must not claim a record — it just sets one.
    @Test func theFirstRoundOnAHoleIsNotANewBest() {
        var record = CourseRecord()
        #expect(record.registerHole(1, strokes: 4) == false)
        #expect(record.holeBest[1] == 4)
    }

    @Test func onlyAnImprovementCounts() {
        var record = CourseRecord()
        record.registerHole(1, strokes: 4)
        #expect(record.registerHole(1, strokes: 3) == true)
        #expect(record.holeBest[1] == 3)
        #expect(record.registerHole(1, strokes: 5) == false)
        #expect(record.holeBest[1] == 3)   // a worse round never overwrites
        #expect(record.registerHole(1, strokes: 3) == false)  // equalling is not beating
    }

    @Test func holesPlayedTracksTheFurthestReached() {
        var record = CourseRecord()
        #expect(record.holesPlayed == 0)
        record.registerHole(1, strokes: 3)
        record.registerHole(5, strokes: 3)
        record.registerHole(2, strokes: 3)
        #expect(record.holesPlayed == 5)
    }

    @Test func courseTotalsKeepTheBestRoundAndTheBestStars() {
        var record = CourseRecord()
        record.register(total: 40, coursePar: 35, holeScores: [4, 4])
        #expect(record.completed)
        #expect(record.bestTotal == 40)
        #expect(record.stars == 1)

        record.register(total: 30, coursePar: 35, holeScores: [3, 3])
        #expect(record.bestTotal == 30)
        #expect(record.bestHoleScores == [3, 3])
        #expect(record.stars == 3)

        // A worse round afterwards leaves both alone.
        record.register(total: 50, coursePar: 35, holeScores: [5, 5])
        #expect(record.bestTotal == 30)
        #expect(record.bestHoleScores == [3, 3])
        #expect(record.stars == 3)
    }
}

@MainActor
struct ProgressTotalsTests {

    @Test func anUntouchedSaveCountsNothing() {
        let progress = GameProgress()
        #expect(progress.holesFinished == 0)
        #expect(progress.starsEarned == 0)
        #expect(progress.totalBonusStars == 0)
        #expect(!progress.allCompleted)
    }

    /// The "Perfectionist" trophy asks for every star in the game, so the
    /// ceiling the totals can reach has to be the ceiling it is measured against.
    @Test func aPerfectSaveReachesExactlyTheAdvertisedMaximum() {
        var progress = GameProgress()
        for course in CourseType.allCases {
            var record = CourseRecord()
            record.completed = true
            for level in LevelLibrary.levels(for: course) {
                // Three stars asks for under par, and a par 2 only goes under
                // par with an ace.
                record.holeBest[level.number] = level.par - 1
                if level.bonusStar != nil { record.bonusStars.insert(level.number) }
            }
            progress.records[course.rawValue] = record
        }
        #expect(progress.holesFinished == LevelLibrary.totalHoles)
        #expect(progress.starsEarned == LevelLibrary.totalHoles * HoleStars.max)
        #expect(progress.totalBonusStars == LevelLibrary.totalBonusStars)
        #expect(progress.allCompleted)
    }

    @Test func starsAreOnlyCountedForHolesActuallyFinished() {
        var progress = GameProgress()
        let course = CourseType.allCases[0]
        var record = CourseRecord()
        record.holeBest[1] = LevelLibrary.level(course: course, number: 1).par
        progress.records[course.rawValue] = record
        #expect(progress.holesFinished == 1)
        #expect(progress.starsEarned == 2)   // par is worth two, and nothing else scores
    }
}

@MainActor
struct LevelLibraryTests {

    @Test func everyWorldIsWiredToItsOwnHoles() {
        for course in CourseType.allCases {
            let levels = LevelLibrary.levels(for: course)
            #expect(!levels.isEmpty)
            for (index, level) in levels.enumerated() {
                #expect(level.course == course)
                #expect(level.number == index + 1)
            }
        }
    }

    @Test func totalsAddUpFromTheWorlds() {
        #expect(LevelLibrary.totalHoles
                == CourseType.allCases.reduce(0) { $0 + LevelLibrary.holeCount($1) })
        #expect(LevelLibrary.totalPar
                == CourseType.allCases.reduce(0) { $0 + LevelLibrary.coursePar($1) })
    }

    /// The lookup clamps rather than traps, and the HUD leans on that while a
    /// scene is being swapped out.
    @Test func outOfRangeLookupsClampToTheEnds() {
        let course = CourseType.allCases[0]
        let count = LevelLibrary.holeCount(course)
        #expect(LevelLibrary.level(course: course, number: 0).number == 1)
        #expect(LevelLibrary.level(course: course, number: -5).number == 1)
        #expect(LevelLibrary.level(course: course, number: count + 99).number == count)
    }

    @Test func theStrokeLimitLeavesRoomOverPar() {
        for course in CourseType.allCases {
            for level in LevelLibrary.levels(for: course) {
                #expect(level.strokeLimit == level.par + 3)
            }
        }
    }
}
