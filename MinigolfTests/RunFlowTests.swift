//
//  RunFlowTests.swift
//  MinigolfTests
//
//  The life budget. A tour is four lives across twelve holes, and every way of
//  spending one runs through `GameController`: the stroke limit reached, a
//  penalty that tips the count over it, a restart asked for from the pause menu.
//  None of it is arithmetic anybody can see going wrong — a life quietly not
//  charged makes a world endless, one charged twice ends a run the player had
//  not lost, and both read as "the game is a bit off" rather than as a bug.
//
//  These drive the real controller rather than a copy of its rules, because the
//  rules only exist as the order those methods happen in. Writing to disk is
//  what usually stops a test doing that; here it does not, because a test run
//  reads as a demo — see `DemoProgress` — so every `save()` in the process is a
//  no-op and the machine's own save is never touched. `aTestRunNeverReachesDisk`
//  below is what keeps that true.
//

import Testing
@testable import Minigolf

/// Takes strokes until the hole's limit is reached, then lets the ball settle —
/// which is the moment the limit is enforced.
@MainActor
private func failTheHole(_ game: GameController) {
    while game.strokes < game.currentLevel.strokeLimit {
        game.registerStroke()
    }
    game.ballRested()
}

@MainActor
private func isGameOver(_ game: GameController) -> Bool {
    if case .gameOver = game.overlay { return true }
    return false
}

@MainActor
struct TourLivesTests {

    @Test func aTestRunNeverReachesDisk() {
        // The premise every other test in this file rests on. If this ever fails,
        // the suite is writing over whatever save is on the machine running it.
        #expect(DemoProgress.isActive)
    }

    @Test func aTourOpensOnTheFirstHoleWithEveryLifeInHand() {
        let game = GameController()
        game.startCourse(.garden)

        #expect(game.lives == GameController.livesPerCourse)
        #expect(game.holeNumber == 1)
        #expect(game.strokes == 0)
        #expect(!game.isSingleHole)
        #expect(!isGameOver(game))
    }

    @Test func runningOutOfStrokesCostsOneLifeAndStartsTheHoleOver() {
        let game = GameController()
        game.startCourse(.garden)
        failTheHole(game)

        #expect(game.lives == GameController.livesPerCourse - 1)
        // The same hole, from the beginning — not the next one, and not a fresh
        // stroke count on a hole that is already half played.
        #expect(game.holeNumber == 1)
        #expect(game.strokes == 0)
        #expect(!isGameOver(game))
    }

    @Test func onlyTheLastLifeEndsTheRun() {
        let game = GameController()
        game.startCourse(.garden)

        for spent in 1..<GameController.livesPerCourse {
            failTheHole(game)
            #expect(game.lives == GameController.livesPerCourse - spent)
            #expect(!isGameOver(game), "the run ended with \(game.lives) lives still in hand")
        }

        failTheHole(game)
        #expect(game.lives == 0)
        #expect(isGameOver(game))
    }

    /// A penalty is a stroke, so it counts against the limit like any other. The
    /// hole a player loses to the water rather than to their putting is the one
    /// this covers.
    @Test func aPenaltyCountsTowardTheStrokeLimit() {
        let game = GameController()
        game.startCourse(.garden)
        let limit = game.currentLevel.strokeLimit
        let penaltiesBefore = game.stats.penalties

        for _ in 0..<(limit - 1) { game.registerStroke() }
        #expect(game.strokes == limit - 1)

        game.registerPenalty(kind: .water)
        #expect(game.strokes == limit)
        #expect(game.stats.penalties == penaltiesBefore + 1)

        game.ballRested()
        #expect(game.lives == GameController.livesPerCourse - 1)
    }

    @Test(arguments: [OutOfBoundsKind.water, .lava, .outOfBounds])
    func everyKindOfPenaltyCostsAStroke(kind: OutOfBoundsKind) {
        let game = GameController()
        game.startCourse(.garden)
        game.registerPenalty(kind: kind)
        #expect(game.strokes == 1)
    }
}

@MainActor
struct SingleHoleRetryTests {

    /// Practice is where a player goes to work a hole out, so it cannot be
    /// allowed to run them out of anything.
    @Test func practiceNeverCostsALife() {
        let game = GameController()
        game.startPractice(course: .garden, hole: 1)

        for _ in 0..<(GameController.livesPerCourse + 2) {
            failTheHole(game)
        }

        #expect(game.lives == GameController.livesPerCourse)
        #expect(game.holeNumber == 1)
        #expect(game.strokes == 0)
        #expect(!isGameOver(game))
    }

    @Test func theDailyHoleNeverCostsALife() {
        let game = GameController()
        game.startDailyChallenge()
        let hole = game.holeNumber

        for _ in 0..<(GameController.livesPerCourse + 2) {
            failTheHole(game)
        }

        #expect(game.lives == GameController.livesPerCourse)
        #expect(game.holeNumber == hole)
        #expect(!isGameOver(game))
    }
}

@MainActor
struct PauseRestartTests {

    @Test func restartingFromPauseCostsALifeInATour() {
        let game = GameController()
        game.startCourse(.garden)
        #expect(game.canRestartHole)

        game.registerStroke()
        game.restartHoleFromPause()

        #expect(game.lives == GameController.livesPerCourse - 1)
        #expect(game.strokes == 0)
        #expect(game.holeNumber == 1)
    }

    /// The one that matters: a restart may never be the thing that ends the run.
    /// Spending the last life from the pause menu would hand the player a game
    /// over they never played into.
    @Test func theLastLifeCannotBeSpentOnARestart() {
        let game = GameController()
        game.startCourse(.garden)

        while game.lives > 1 { game.restartHoleFromPause() }
        #expect(game.lives == 1)
        #expect(!game.canRestartHole)

        game.restartHoleFromPause()
        #expect(game.lives == 1)
        #expect(!isGameOver(game))
    }

    @Test func singleHoleModesRestartAsOftenAsTheyLike() {
        let game = GameController()
        game.startPractice(course: .garden, hole: 3)

        for _ in 0..<10 {
            #expect(game.canRestartHole)
            game.restartHoleFromPause()
        }

        #expect(game.lives == GameController.livesPerCourse)
        #expect(game.holeNumber == 3)
    }
}
