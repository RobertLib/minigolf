//
//  DailyChallengeTests.swift
//  MinigolfTests
//
//  The daily hole is picked from the date and nothing else, which is what lets
//  every device agree without a server. That promise is only ever exercised one
//  day at a time in play, so it is checked across years here.
//

import Foundation
import Testing
@testable import Minigolf

@MainActor
struct DailyChallengeTests {

    /// Two years of day keys, so the properties below are checked against a
    /// spread of hashes rather than whatever today happens to be.
    private static let days: [String] = span(from: 2026, days: 730)

    private static func span(from year: Int, days count: Int) -> [String] {
        let calendar = Calendar.current
        var components = DateComponents(year: year, month: 1, day: 1)
        var keys: [String] = []
        for _ in 0..<count {
            keys.append(GameDay.key(calendar.date(from: components)!))
            components.day! += 1
        }
        return keys
    }

    @Test func theSameDayAlwaysGivesTheSameHole() {
        for day in Self.days {
            #expect(DailyChallenge.pick(for: day) == DailyChallenge.pick(for: day))
        }
    }

    @Test func everyPickIsAHoleThatExists() {
        for day in Self.days {
            let pick = DailyChallenge.pick(for: day)
            #expect((1...LevelLibrary.holeCount(pick.course)).contains(pick.hole))
        }
    }

    /// The one rule the picker bends its own hash for: yesterday's hole is
    /// never handed out again today.
    @Test func neverRepeatsTwoDaysRunning() {
        for (previous, today) in zip(Self.days, Self.days.dropFirst()) {
            #expect(DailyChallenge.pick(for: previous) != DailyChallenge.pick(for: today))
        }
    }

    /// Two years is not enough to catch this one. The rule used to be checked
    /// against yesterday's *first* draw rather than the hole yesterday actually
    /// handed out, so a day that had itself been re-drawn could be repeated the
    /// next morning — which first happens on 2036-09-20, a decade past the
    /// window above. Fifteen years, so the next such pair is caught too.
    @Test func neverRepeatsAcrossTheDecades() {
        let days = Self.span(from: 2026, days: 15 * 365)
        for (previous, today) in zip(days, days.dropFirst()) {
            let before = DailyChallenge.pick(for: previous)
            let now = DailyChallenge.pick(for: today)
            #expect(before != now, "\(previous) and \(today) both give \(now)")
        }
    }

    /// The re-draw is part of the picker, not an accident of it: a day that
    /// collides still has to answer the same way every time it is asked.
    @Test func aReDrawnDayIsJustAsStable() {
        for day in Self.span(from: 2036, days: 400) {
            #expect(DailyChallenge.pick(for: day) == DailyChallenge.pick(for: day))
        }
    }

    /// A taster of the whole game, not a tour of the first world — over two
    /// years every world should come up.
    @Test func drawsFromEveryWorld() {
        let courses = Set(Self.days.map { DailyChallenge.pick(for: $0).course })
        #expect(courses.count == CourseType.allCases.count)
    }

    @Test func theLevelMatchesThePick() {
        for day in Self.days.prefix(60) {
            let pick = DailyChallenge.pick(for: day)
            let level = DailyChallenge.level(for: day)
            #expect(level.course == pick.course)
            #expect(level.number == pick.hole)
        }
    }
}

@MainActor
struct DailyMedalTests {

    @Test func medalsFollowTheScore() {
        #expect(DailyMedal.medal(strokes: 2, par: 3) == .gold)
        #expect(DailyMedal.medal(strokes: 3, par: 3) == .silver)
        #expect(DailyMedal.medal(strokes: 4, par: 3) == .bronze)
    }

    @Test func everyMedalSaysSomething() {
        for medal in [DailyMedal.gold, .silver, .bronze] {
            #expect(!medal.label.isEmpty)
            #expect(!medal.symbol.isEmpty)
        }
    }
}
