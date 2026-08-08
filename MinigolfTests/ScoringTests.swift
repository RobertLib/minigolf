//
//  ScoringTests.swift
//  MinigolfTests
//
//  The golf arithmetic. Every threshold here is a number a player will argue
//  with, and none of them are checked by the level validator.
//

import Testing
@testable import Minigolf

@MainActor
struct HoleRatingTests {

    @Test func oneStrokeIsAlwaysAnAce() {
        // Even on a par 2, where one under par would otherwise read as birdie.
        #expect(HoleRating.rating(strokes: 1, par: 2) == .holeInOne)
        #expect(HoleRating.rating(strokes: 1, par: 5) == .holeInOne)
    }

    @Test func namesFollowTheDifferenceFromPar() {
        #expect(HoleRating.rating(strokes: 2, par: 4) == .eagle)
        #expect(HoleRating.rating(strokes: 3, par: 4) == .birdie)
        #expect(HoleRating.rating(strokes: 4, par: 4) == .par)
        #expect(HoleRating.rating(strokes: 5, par: 4) == .bogey)
        #expect(HoleRating.rating(strokes: 6, par: 4) == .doubleBogey)
        #expect(HoleRating.rating(strokes: 7, par: 4) == .over(3))
    }

    @Test func threeOrMoreUnderParIsStillAnEagle() {
        #expect(HoleRating.rating(strokes: 2, par: 5) == .eagle)
    }

    /// Nothing reachable in the game may fall through to a blank card: the
    /// stroke limit is par + 3, so that is the worst score a hole can produce.
    @Test(arguments: [2, 3, 4, 5])
    func everyReachableScoreHasATitle(par: Int) {
        for strokes in 1...(par + 3) {
            #expect(!HoleRating.rating(strokes: strokes, par: par).title.isEmpty)
            #expect(!HoleRating.rating(strokes: strokes, par: par).emoji.isEmpty)
        }
    }
}

@MainActor
struct StarTests {

    @Test func holeStarsNeedUnderParForThree() {
        #expect(HoleStars.stars(strokes: 2, par: 3) == 3)
        #expect(HoleStars.stars(strokes: 1, par: 3) == 3)
        #expect(HoleStars.stars(strokes: 3, par: 3) == 2)
        #expect(HoleStars.stars(strokes: 4, par: 3) == 1)
        #expect(HoleStars.stars(strokes: 9, par: 3) == 1)
    }

    /// A finished hole is always worth something — the picker draws an empty
    /// row only for holes that have never been played.
    @Test func aFinishedHoleNeverScoresZeroStars() {
        for par in 2...5 {
            for strokes in 1...(par + 3) {
                #expect(HoleStars.stars(strokes: strokes, par: par) >= 1)
                #expect(HoleStars.stars(strokes: strokes, par: par) <= HoleStars.max)
            }
        }
    }

    @Test func courseStarsWantFiveUnderForThree() {
        #expect(CourseStars.stars(total: 30, coursePar: 35) == 3)
        #expect(CourseStars.stars(total: 31, coursePar: 35) == 2)
        #expect(CourseStars.stars(total: 35, coursePar: 35) == 2)
        #expect(CourseStars.stars(total: 36, coursePar: 35) == 1)
    }
}

@MainActor
struct GolferRatingTests {

    /// Tiers run 0 (best) to 5 and must not skip or overlap as the score walks
    /// past each threshold.
    @Test func tiersDescendMonotonicallyWithScore() {
        let par = LevelLibrary.totalPar
        var previous = -1
        for diff in stride(from: -60, through: 60, by: 1) {
            let tier = GolferRating.rating(totalStrokes: par + diff, totalPar: par).tier
            #expect(tier >= previous)
            previous = tier
        }
        #expect(previous == 5)
    }

    @Test func theThresholdsSitWhereTheyClaimTo() {
        let par = LevelLibrary.totalPar
        #expect(GolferRating.rating(totalStrokes: par - 45, totalPar: par).tier == 0)
        #expect(GolferRating.rating(totalStrokes: par - 44, totalPar: par).tier == 1)
        #expect(GolferRating.rating(totalStrokes: par, totalPar: par).tier == 2)
        #expect(GolferRating.rating(totalStrokes: par + 1, totalPar: par).tier == 3)
        #expect(GolferRating.rating(totalStrokes: par + 46, totalPar: par).tier == 5)
    }
}

@MainActor
struct FormattedDiffTests {

    @Test func evenParIsE() {
        #expect(formattedDiff(0) == "E")
    }

    @Test func overParCarriesItsSign() {
        #expect(formattedDiff(3) == "+3")
        #expect(formattedDiff(-3) == "-3")
    }
}
