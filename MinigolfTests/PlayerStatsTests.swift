//
//  PlayerStatsTests.swift
//  MinigolfTests
//
//  Streak arithmetic. It only ever runs one day at a time on a real device, so
//  a gap, a replay or a lapsed run is not something normal play will surface —
//  the counters just quietly say the wrong number.
//

import Foundation
import Testing
@testable import Minigolf

@MainActor
struct PlayDayStreakTests {

    @Test func consecutiveDaysExtendTheStreak() {
        var stats = PlayerStats()
        stats.registerPlayDay("2026-08-06")
        stats.registerPlayDay("2026-08-07")
        stats.registerPlayDay("2026-08-08")
        #expect(stats.dayStreak == 3)
        #expect(stats.daysPlayed == 3)
        #expect(stats.bestDayStreak == 3)
    }

    @Test func aSecondHoleOnTheSameDayChangesNothing() {
        var stats = PlayerStats()
        stats.registerPlayDay("2026-08-08")
        stats.registerPlayDay("2026-08-08")
        stats.registerPlayDay("2026-08-08")
        #expect(stats.dayStreak == 1)
        #expect(stats.daysPlayed == 1)
    }

    @Test func aMissedDayRestartsTheStreakButKeepsTheBest() {
        var stats = PlayerStats()
        stats.registerPlayDay("2026-08-01")
        stats.registerPlayDay("2026-08-02")
        stats.registerPlayDay("2026-08-03")
        stats.registerPlayDay("2026-08-08")   // five days off
        #expect(stats.dayStreak == 1)
        #expect(stats.bestDayStreak == 3)
        #expect(stats.daysPlayed == 4)
    }

    @Test func theStreakSurvivesAMonthBoundary() {
        var stats = PlayerStats()
        stats.registerPlayDay("2026-07-31")
        stats.registerPlayDay("2026-08-01")
        #expect(stats.dayStreak == 2)
    }
}

@MainActor
struct DailyChallengeStatsTests {

    @Test func firstCompletionStartsTheStreakAndCounts() {
        var stats = PlayerStats()
        stats.registerDaily(day: "2026-08-08", strokes: 3)
        #expect(stats.dailyStreak == 1)
        #expect(stats.dailiesCompleted == 1)
        #expect(stats.dailyBest["2026-08-08"] == 3)
        #expect(stats.dailyDone(today: "2026-08-08"))
    }

    @Test func replayingTheSameDayOnlyImprovesTheScore() {
        var stats = PlayerStats()
        stats.registerDaily(day: "2026-08-08", strokes: 5)
        stats.registerDaily(day: "2026-08-08", strokes: 3)
        stats.registerDaily(day: "2026-08-08", strokes: 7)
        #expect(stats.dailyBest["2026-08-08"] == 3)
        // The streak and the lifetime count move once per day, not once per run.
        #expect(stats.dailyStreak == 1)
        #expect(stats.dailiesCompleted == 1)
    }

    @Test func consecutiveDaysBuildTheDailyStreak() {
        var stats = PlayerStats()
        for day in ["2026-08-05", "2026-08-06", "2026-08-07", "2026-08-08"] {
            stats.registerDaily(day: day, strokes: 3)
        }
        #expect(stats.dailyStreak == 4)
        #expect(stats.bestDailyStreak == 4)
        #expect(stats.dailiesCompleted == 4)
    }

    @Test func aGapResetsTheDailyStreak() {
        var stats = PlayerStats()
        stats.registerDaily(day: "2026-08-01", strokes: 3)
        stats.registerDaily(day: "2026-08-02", strokes: 3)
        stats.registerDaily(day: "2026-08-08", strokes: 3)
        #expect(stats.dailyStreak == 1)
        #expect(stats.bestDailyStreak == 2)
    }

    /// The menu must never advertise a run the player can no longer continue.
    @Test func aStreakLapsesOnceYesterdayIsMissed() {
        var stats = PlayerStats()
        stats.registerDaily(day: "2026-08-06", strokes: 3)
        stats.registerDaily(day: "2026-08-07", strokes: 3)

        #expect(stats.liveDailyStreak(today: "2026-08-07") == 2)  // played today
        #expect(stats.liveDailyStreak(today: "2026-08-08") == 2)  // still catchable
        #expect(stats.liveDailyStreak(today: "2026-08-09") == 0)  // gone
    }

    @Test func anUntouchedDailyHasNoStreakAtAll() {
        let stats = PlayerStats()
        #expect(stats.liveDailyStreak(today: "2026-08-08") == 0)
        #expect(!stats.dailyDone(today: "2026-08-08"))
    }

    /// The history is trimmed so a daily player does not carry years of keys
    /// around in `UserDefaults` — but the trim has to drop the oldest, and it
    /// has to leave today's result alone.
    @Test func historyIsTrimmedOldestFirst() {
        var stats = PlayerStats()
        var day = DateComponents(year: 2026, month: 1, day: 1)
        let calendar = Calendar.current
        var keys: [String] = []
        for _ in 0..<80 {
            let date = calendar.date(from: day)!
            let key = GameDay.key(date)
            keys.append(key)
            stats.registerDaily(day: key, strokes: 3)
            day.day! += 1
        }
        #expect(stats.dailyBest.count == 60)
        #expect(stats.dailyBest[keys.last!] != nil)
        #expect(stats.dailyBest[keys.first!] == nil)
        #expect(stats.dailiesCompleted == 80)
    }
}

@MainActor
struct GameDayTests {

    @Test func keysRoundTripThroughDates() {
        let key = "2026-08-08"
        let date = GameDay.date(from: key)
        #expect(date != nil)
        #expect(GameDay.key(date!) == key)
    }

    @Test func dayArithmeticIsSignedAndCrossesMonths() {
        #expect(GameDay.days(from: "2026-08-07", to: "2026-08-08") == 1)
        #expect(GameDay.days(from: "2026-08-08", to: "2026-08-07") == -1)
        #expect(GameDay.days(from: "2026-07-31", to: "2026-08-01") == 1)
        #expect(GameDay.days(from: "2026-02-28", to: "2026-03-01") == 1)  // 2026 is not a leap year
    }

    @Test func aMalformedKeyYieldsNothingRatherThanZero() {
        #expect(GameDay.days(from: "not-a-day", to: "2026-08-08") == nil)
        #expect(GameDay.date(from: "08/08/2026") == nil)
    }

    @Test func midnightIsAlwaysAheadAndWithinADay() {
        let remaining = GameDay.secondsUntilTomorrow()
        #expect(remaining > 0)
        #expect(remaining <= 24 * 60 * 60)
    }
}
