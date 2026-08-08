//
//  AimGuideTests.swift
//  MinigolfTests
//
//  The aiming line is the one piece of the shot the player is invited to trust
//  before taking it, and the only part of the physics that is pure geometry
//  rather than the solver — so it is the part that can be checked here rather
//  than by putting.
//
//  What it promises: it stops where the ball would stop, it banks off boards the
//  way the ball banks off them, it says so when the putt drops, and it stays
//  quiet about anything that will have moved by the time the ball arrives.
//

import Foundation
import Testing
import simd
@testable import Minigolf

@MainActor
struct AimGuideTraceTests {

    /// A plain walled lane, 0.9 m across, running from the tee at the origin to
    /// a cup 2.2 m down the -Z axis — the shape of Garden 1, with nothing on it.
    private static func lane(walls: Bool = true) -> LevelDefinition {
        LevelDefinition(
            course: .garden, number: 1, name: "test", par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [FloorPatch(rect: GroundRect(x0: -0.45, x1: 0.45, z0: -2.7, z1: 0.5))],
            wallLoops: walls ? [[
                SIMD2(-0.45, 0.5), SIMD2(0.45, 0.5),
                SIMD2(0.45, -2.7), SIMD2(-0.45, -2.7),
            ]] : []
        )
    }

    private static func trace(_ level: LevelDefinition,
                              from origin: SIMD2<Float> = SIMD2(0, 0),
                              direction: SIMD2<Float>,
                              length: Float,
                              holeRadius: Float = 0,
                              bounces: Int = 0) -> AimGuidePath {
        AimGuideTracer.trace(
            geometry: AimGuideGeometry.build(level: level),
            from: origin, direction: direction, length: length,
            ballY: 0, hole: level.hole, holeRadius: holeRadius,
            maxBounces: bounces)
    }

    /// Nothing in the way: the line is the shot, at full length and dead
    /// straight.
    @Test func anOpenLineRunsItsFullLength() {
        let path = Self.trace(Self.lane(walls: false),
                              direction: SIMD2(0, -1), length: 1.5)
        #expect(path.points.count == 2)
        #expect(abs(path.totalLength - 1.5) < 0.001)
        #expect(abs(path.points.last!.x) < 0.001)
        #expect(!path.endsInHole)
    }

    /// The line stops at the ball's surface, not at its centre: a putt aimed at
    /// the back board from 2 m short of it ends a ball radius plus half the
    /// board's thickness before the board's centre line, which is exactly where
    /// the real ball is stopped.
    @Test func aLineStopsWhereTheBallWouldTouch() {
        let path = Self.trace(Self.lane(), direction: SIMD2(0, -1), length: 5)
        let stop = path.points.last!.y   // SIMD2's .y is the Z axis here
        let board: Float = -2.7
        let clearance = GamePhysics.ballRadius + WallSegment(from: .zero, to: .zero).thickness / 2
        #expect(abs(stop - (board + clearance)) < 0.01,
                "stopped at \(stop), board at \(board)")
        // Short of the board, never through it.
        #expect(stop > board)
    }

    /// Straight into a wall and straight back. The bounce is what the guide is
    /// for — reading a bank off a fixed camera is the hardest thing it does.
    @Test func aSquareHitComesStraightBack() {
        let path = Self.trace(Self.lane(), direction: SIMD2(0, -1),
                              length: 5, bounces: 2)
        #expect(path.points.count >= 3)
        let incoming = path.points[1] - path.points[0]
        let outgoing = path.points[2] - path.points[1]
        // Reversed along Z, and still on the centre line.
        #expect(incoming.y < 0 && outgoing.y > 0)
        #expect(abs(outgoing.x) < 0.01)
    }

    /// A bank costs speed, so the line after one is shorter than the line the
    /// same draw would have drawn across open felt. A guide that kept its full
    /// length round a corner would promise a putt the ball cannot make.
    @Test func aBounceCostsLength() {
        let straight = Self.trace(Self.lane(walls: false),
                                  direction: SIMD2(0, -1), length: 5, bounces: 2)
        let banked = Self.trace(Self.lane(), direction: SIMD2(0, -1),
                                length: 5, bounces: 2)
        #expect(banked.totalLength < straight.totalLength)
    }

    /// With bounces switched off — the "short" setting — the line ends at the
    /// board rather than carrying on past it.
    @Test func theShortGuideNeverBanks() {
        let path = Self.trace(Self.lane(), direction: SIMD2(0, -1),
                              length: 5, bounces: 0)
        #expect(path.points.count == 2)
    }

    /// The gold line: aimed at the cup, the guide says so and ends there.
    @Test func aLineThatDropsSaysSo() {
        let level = Self.lane()
        let path = Self.trace(level, direction: SIMD2(0, -1), length: 3,
                              holeRadius: 0.052)
        #expect(path.endsInHole)
        #expect(simd_distance(path.points.last!, level.hole) < 0.06)
    }

    /// Aimed a hand's width wide of the cup it does not, even though the line
    /// runs well past it. This is the check that matters: a guide that lit up
    /// for near misses would be worse than none.
    @Test func aLineThatMissesDoesNot() {
        let level = Self.lane()
        let path = Self.trace(level, from: SIMD2(0.2, 0),
                              direction: SIMD2(0, -1), length: 3,
                              holeRadius: 0.052)
        #expect(!path.endsInHole)
    }

    /// A post is round, and the line has to leave it at the angle a ball would.
    @Test func aPostTurnsTheLineAside() {
        var level = Self.lane(walls: false)
        level.obstacles = [.post(center: SIMD2(0, -1), radius: 0.04)]
        let path = Self.trace(level, from: SIMD2(0.02, 0),
                              direction: SIMD2(0, -1), length: 2, bounces: 1)
        #expect(path.points.count >= 3)
        // Clipped on the right of centre, so it must come off to the right.
        #expect(path.points.last!.x > path.points[1].x)
    }

    /// Degenerate input is a real case — the draw starts at zero length every
    /// time the player puts a finger down.
    @Test func nothingToDrawIsDrawnAsNothing() {
        for length: Float in [0, 0.005] {
            let path = Self.trace(Self.lane(), direction: SIMD2(0, -1), length: length)
            #expect(path.points.count == 1)
            #expect(!path.endsInHole)
        }
        let noDirection = Self.trace(Self.lane(), direction: .zero, length: 1)
        #expect(noDirection.points.count == 1)
    }
}

@MainActor
struct AimGuideGeometryTests {

    /// The rule the whole feature rests on: the guide only knows about things
    /// that will still be there when the ball arrives. A mill, a gate, a rotor
    /// or a wandering hedgehog is deliberately invisible to it, because a line
    /// that claimed to know where they will be in a second would be lying and
    /// every timing puzzle in the game would stop being one.
    @Test func movingObstaclesAreLeftOutOfTheLine() {
        var level = LevelDefinition(
            course: .garden, number: 1, name: "test", par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [FloorPatch(rect: GroundRect(x0: -0.45, x1: 0.45, z0: -2.7, z1: 0.5))]
        )
        level.obstacles = [
            .windmill(center: SIMD2(0, -1), yaw: 0, speed: 1),
            .rotor(center: SIMD2(0, -1.4), length: 0.6, speed: 1, baseY: 0),
            .movingBlock(center: SIMD2(0, -1.8), axis: SIMD2(1, 0), amplitude: 0.2,
                         speed: 1, size: SIMD2(0.2, 0.2), baseY: 0),
            critter(.hedgehog, at: SIMD2(0, -2),
                    .patrol(axis: SIMD2(1, 0), amplitude: 0.2), speed: 1),
        ]
        let geometry = AimGuideGeometry.build(level: level)
        #expect(geometry.boards.isEmpty)
        #expect(geometry.pillars.isEmpty)
    }

    /// Static blockers, on the other hand, are all there.
    @Test func staticBlockersAreAllThere() {
        var level = LevelDefinition(
            course: .garden, number: 1, name: "test", par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [FloorPatch(rect: GroundRect(x0: -0.45, x1: 0.45, z0: -2.7, z1: 0.5))]
        )
        level.obstacles = [
            .post(center: SIMD2(-0.2, -1), radius: 0.04),
            .bumper(center: SIMD2(0.2, -1.5), radius: 0.07),
            .block(center: SIMD2(0, -2), size: SIMD3(0.2, 0.1, 0.2), yaw: 0, baseY: 0),
        ]
        let geometry = AimGuideGeometry.build(level: level)
        #expect(geometry.pillars.count == 2)
        #expect(geometry.boards.count == 4)   // the block's four sides
        // A bumper kicks harder than a post, and the line has to know it.
        let bumper = geometry.pillars.first { $0.radius > 0.05 }
        let post = geometry.pillars.first { $0.radius < 0.05 }
        #expect(bumper?.restitution == GamePhysics.bumperBounce)
        #expect(post?.restitution == GamePhysics.wallBounce)
    }

    /// A wall loop closes: four points make four boards, not three.
    @Test func aWallLoopIsClosed() {
        var level = LevelDefinition(
            course: .garden, number: 1, name: "test", par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [FloorPatch(rect: GroundRect(x0: -1, x1: 1, z0: -1, z1: 1))]
        )
        level.wallLoops = [[SIMD2(-1, 1), SIMD2(1, 1), SIMD2(1, -1), SIMD2(-1, -1)]]
        #expect(AimGuideGeometry.build(level: level).boards.count == 4)
    }

    /// A blocker only counts on the ball's own level, so the boards around a
    /// raised green do not stop a line drawn down on the felt below.
    @Test func aBlockerOnAnotherLevelIsIgnored() {
        var level = LevelDefinition(
            course: .garden, number: 1, name: "test", par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [FloorPatch(rect: GroundRect(x0: -1, x1: 1, z0: -3, z1: 1))]
        )
        level.extraWalls = [WallSegment(from: SIMD2(-1, -1), to: SIMD2(1, -1), baseY: 0.6)]
        let geometry = AimGuideGeometry.build(level: level)

        let onTheFelt = AimGuideTracer.trace(
            geometry: geometry, from: SIMD2(0, 0), direction: SIMD2(0, -1),
            length: 2, ballY: 0, hole: level.hole, holeRadius: 0, maxBounces: 0)
        let upTop = AimGuideTracer.trace(
            geometry: geometry, from: SIMD2(0, 0), direction: SIMD2(0, -1),
            length: 2, ballY: 0.6, hole: level.hole, holeRadius: 0, maxBounces: 0)

        #expect(abs(onTheFelt.totalLength - 2) < 0.001)
        #expect(upTop.totalLength < 1.2)
    }
}

@MainActor
struct AimGuideAgainstTheRealLevelsTests {

    /// Every hole in the game, traced from its own tee at full draw with the
    /// bounce budget the "full" setting allows. Nothing here asserts a good
    /// line — only that the tracer terminates and returns finite numbers on all
    /// 108 holes, including the ones with loops, cannons and turntables on them.
    @Test func everyHoleTracesToAFiniteLine() {
        for course in CourseType.allCases {
            for number in 1...LevelLibrary.holeCount(course) {
                let level = LevelLibrary.level(course: course, number: number)
                let toHole = level.hole - level.tee
                let path = AimGuideTracer.trace(
                    geometry: AimGuideGeometry.build(level: level),
                    from: level.tee,
                    direction: simd_length(toHole) > 0 ? simd_normalize(toHole) : SIMD2(0, -1),
                    length: AimGuideLevel.full.length(power: 1),
                    ballY: 0,
                    hole: level.hole, holeRadius: 0.052,
                    maxBounces: AimGuideLevel.full.maxBounces)

                #expect(path.points.count >= 2, "\(level.id) drew nothing")
                #expect(path.points.count <= AimGuideLevel.full.maxBounces + 2,
                        "\(level.id) drew more legs than it has bounces")
                for point in path.points {
                    #expect(point.x.isFinite && point.y.isFinite, "\(level.id) went non-finite")
                }
                #expect(path.totalLength <= AimGuideLevel.full.length(power: 1) + 0.001,
                        "\(level.id) drew a longer line than the putt would roll")
            }
        }
    }

    /// The line never claims more roll than the draw pays for, at any strength.
    @Test func theLineIsNeverLongerThanTheDraw() {
        let level = LevelLibrary.level(course: .garden, number: 1)
        let geometry = AimGuideGeometry.build(level: level)
        for step in 0...10 {
            let power = Float(step) / 10
            let asked = AimGuideLevel.full.length(power: power)
            let path = AimGuideTracer.trace(
                geometry: geometry, from: level.tee, direction: SIMD2(1, 0),
                length: asked, ballY: 0, hole: level.hole, holeRadius: 0,
                maxBounces: 2)
            #expect(path.totalLength <= asked + 0.001)
        }
    }

    /// Longer draw, longer line — the one thing a player reads off it directly.
    @Test func aHarderDrawDrawsAFurtherLine() {
        for level in [AimGuideLevel.short, .full] {
            var previous: Float = -1
            for step in 0...10 {
                let length = level.length(power: Float(step) / 10)
                #expect(length >= previous)
                previous = length
            }
        }
        // Off is off, at every strength.
        #expect(AimGuideLevel.off.length(power: 1) == 0)
        // Short is capped; full is not.
        #expect(AimGuideLevel.short.length(power: 1) < AimGuideLevel.full.length(power: 1))
    }
}
