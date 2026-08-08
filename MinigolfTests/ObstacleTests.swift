//
//  ObstacleTests.swift
//  MinigolfTests
//
//  The obstacles that move. Every one of them is a pure function of the clock —
//  deliberately, so a hole restarted mid-shot picks its scenery up exactly where
//  it was rather than having to rewind any state — which also means each can be
//  wound forward here and asked where it has got to.
//
//  What is worth checking is not the shape of the curves but their bounds: a
//  gate that sinks a millimetre too far leaves a lip the ball trips over, a belt
//  chevron that runs past the end of its bed appears to slide out through the
//  boards, and a speck of weather that escapes its box drifts off across the
//  skyline for the rest of the session. None of those show up as anything but a
//  puzzled player.
//

import Foundation
import RealityKit
import Testing
import simd
@testable import Minigolf

@MainActor
struct ObstacleAnimationTests {

    /// A minute at 60 fps: long enough for anything here to have gone round
    /// several times, and fine enough not to step over a crest.
    private static let clock: [Float] = (0...3600).map { Float($0) / 60 }

    // MARK: - Gates

    /// A gate drops into the floor and comes back. Sinking further than the drop
    /// it was given would leave a hole in the wall; not sinking that far would
    /// leave a lip standing in the gap the player is meant to putt through.
    @Test func aGateStaysBetweenShutAndFullySunk() {
        for time in Self.clock {
            let open = AnimatedObstacle.openness(time: time, period: 3.4, phase: 0.7)
            #expect(open >= 0 && open <= 1, "at \(time)s the gate is \(open) open")
        }
    }

    /// Both ends of the travel have to be reached, and dwelt on: the flat top
    /// and bottom of the curve are what give the player a window to putt through
    /// rather than a knife-edge to hit.
    @Test func aGateOpensFullyAndShutsFully() {
        let period: Float = 3.0
        var shut = 0, open = 0
        for time in stride(from: Float(0), through: period, by: 1.0 / 120) {
            let value = AnimatedObstacle.openness(time: time, period: period, phase: 0)
            if value < 0.001 { shut += 1 }
            if value > 0.999 { open += 1 }
        }
        // A frame or two either end would be a knife edge; a tenth of the cycle
        // at each is a window.
        #expect(shut > 12, "the gate is never properly shut")
        #expect(open > 12, "the gate never opens all the way")
    }

    /// A period of zero is what a hole gets if the field is left off. It has to
    /// read as a wall that never moves, not as a division by nothing.
    @Test func aGateWithNoPeriodStandsStill() {
        for time in Self.clock {
            #expect(AnimatedObstacle.openness(time: time, period: 0, phase: 0) == 0)
        }
    }

    // MARK: - Drifting weather

    /// Snow and ash loop through a box of air. The fold has to work in both
    /// directions — specks fall, so their travel goes negative — and a zero span
    /// has to pin the axis rather than divide by it, which is how a speck that
    /// only falls stays over the same spot.
    @Test func aSpeckOfWeatherNeverLeavesItsBox() {
        let span: Float = 4.5
        for time in Self.clock {
            for velocity in [Float(-3.2), -0.4, 0.9, 6.0] {
                let folded = AnimatedObstacle.looped(velocity * time, span)
                #expect(folded >= 0 && folded < span,
                        "\(velocity) m/s put a speck at \(folded) in a \(span) m box")
            }
        }
    }

    @Test func aZeroSpanPinsTheAxis() {
        for value in [Float(-9), -0.1, 0, 0.1, 9] {
            #expect(AnimatedObstacle.looped(value, 0) == 0)
        }
    }

    // MARK: - Belts

    /// The chevrons ride the length of their bed and start again. One that runs
    /// past the end would slide out through the boards at the end of the belt.
    @Test func beltChevronsStayOnTheirBed() {
        let length: Float = 1.2
        let strip = Entity()
        for _ in 0..<3 { strip.addChild(Entity()) }
        let belt = AnimatedObstacle(kind: .belt(length: length, speed: 0.9), entity: strip)

        for time in Self.clock {
            belt.update(time: time)
            for chevron in strip.children {
                #expect(chevron.position.z >= -length / 2 - 0.001
                        && chevron.position.z <= length / 2 + 0.001,
                        "at \(time)s a chevron is at \(chevron.position.z) on a \(length) m belt")
            }
        }
    }

    /// A belt with no length is the same authoring slip as a gate with no
    /// period: it must leave its chevrons alone rather than divide by nothing.
    @Test func aBeltWithNoLengthMovesNothing() {
        let strip = Entity()
        let chevron = Entity()
        chevron.position.z = 0.25
        strip.addChild(chevron)
        let belt = AnimatedObstacle(kind: .belt(length: 0, speed: 1.4), entity: strip)

        belt.update(time: 12.5)
        #expect(chevron.position.z == 0.25)
    }

    // MARK: - Sliding blocks and pendulums

    /// A block slides `amplitude` either side of where it was placed. Further
    /// than that and it puts itself through the boards it was measured against.
    @Test func aSlidingBlockKeepsToItsAmplitude() {
        let center = SIMD3<Float>(0.3, 0.04, -1.1)
        let amplitude: Float = 0.42
        let block = AnimatedObstacle(
            kind: .movingBlock(center: center, axis: SIMD3(1, 0, 0),
                               amplitude: amplitude, speed: 1.7),
            entity: Entity())

        var reach: Float = 0
        for time in Self.clock {
            block.update(time: time)
            let offset = block.entity.position - center
            reach = max(reach, simd_length(offset))
            #expect(simd_length(offset) <= amplitude + 0.001,
                    "at \(time)s the block is \(simd_length(offset)) m from its centre")
        }
        // And it really does use the whole of it, rather than trembling in place.
        #expect(reach > amplitude * 0.99)
    }

    /// A pendulum swings `arc` either side of straight down and no further, so
    /// the bar cannot come round over the top of its own pivot.
    @Test func aPendulumStaysInsideItsArc() {
        let arc: Float = 0.62
        let pivot = Entity()
        let pendulum = AnimatedObstacle(kind: .pendulum(arc: arc, speed: 2.1), entity: pivot)

        for time in Self.clock {
            pendulum.update(time: time)
            let angle = pivot.orientation.angle
            #expect(angle <= arc + 0.001, "at \(time)s the arm is \(angle) rad off centre")
        }
    }

    // MARK: - Pickups

    /// Bonus stars and portal rings turn and bob. The bob is what makes them
    /// read as a pickup rather than a fixture, and it has to stay within the
    /// clearance the collection test was tuned against.
    @Test func aPickupBobsAroundItsRestingHeight() {
        let baseY: Float = 0.09
        let bob: Float = 0.02
        let star = Entity()
        let spin = AnimatedObstacle(kind: .spin(speed: 1.2, baseY: baseY, bob: bob),
                                    entity: star)

        for time in Self.clock {
            spin.update(time: time)
            #expect(abs(star.position.y - baseY) <= bob + 0.001,
                    "at \(time)s the star is \(star.position.y - baseY) m off its height")
        }
    }

    // MARK: - Wind

    /// The gust the ball feels and the speed the blades turn at come off the
    /// same curve, which is the only reason a player can read the wind off the
    /// propeller. It swells from nothing to full and back.
    @Test func aGustSwellsFromNothingToFull() {
        let zone = WindZone(rect: zone(-1, 1, -1, 1), direction: SIMD2(1, 0),
                            strength: 2.4, period: 5.0, phase: 0, y: 0)
        var low: Float = 1, high: Float = 0
        for time in Self.clock {
            let gust = zone.gust(at: time)
            #expect(gust >= 0 && gust <= 1, "at \(time)s the gust is \(gust)")
            low = min(low, gust)
            high = max(high, gust)
        }
        #expect(low < 0.01, "the wind never drops away")
        #expect(high > 0.99, "the wind never blows properly")
    }

    /// A fan with no period blows steadily rather than dividing by nothing.
    @Test func aFanWithNoPeriodBlowsSteadily() {
        let zone = WindZone(rect: zone(-1, 1, -1, 1), direction: SIMD2(0, -1),
                            strength: 1.0, period: 0, phase: 0, y: 0)
        for time in Self.clock {
            #expect(zone.gust(at: time) == 1)
        }
    }
}

// MARK: - Loop geometry

/// The loop-the-loop is the one obstacle whose shape four different pieces of
/// code have to agree on — the model, the builder, the aim guide and the offline
/// validator — because the ball is walked around it by hand rather than left to
/// the solver. What follows is the contract between them.
@MainActor
struct LoopGeometryTests {

    private static let radius: Float = 0.22
    private static var pitch: Float { LoopShape.pitch(radius: radius) }

    /// The track starts on the felt and comes back down to it, a pitch further
    /// along. A closed circle — both mouths in the same place — is the shape
    /// this deliberately is not: it would read as a hoop parked on the lane and
    /// give the ball nowhere to come out.
    @Test func theTrackLeavesTheFeltAndReturnsToIt() {
        let entrance = LoopShape.point(theta: 0, radius: Self.radius, pitch: Self.pitch)
        let exit = LoopShape.point(theta: 2 * .pi, radius: Self.radius, pitch: Self.pitch)

        #expect(abs(entrance.y) < 0.0001, "the entrance is off the ground")
        #expect(abs(exit.y) < 0.0001, "the exit is off the ground")
        #expect(abs((exit.x - entrance.x) - Self.pitch) < 0.0001,
                "the exit lands \(exit.x - entrance.x) m along, not a pitch of \(Self.pitch) m")
    }

    /// How far apart the two mouths stand, in absolute terms rather than in
    /// terms of the pitch itself. Everything else here holds the shape against
    /// its own definition, which stays true of a pitch of nought — and a pitch
    /// of nought is a closed hoop: one point on the felt that is both the way in
    /// and the way out, with the ball meeting itself coming back.
    @Test func theTwoMouthsStandWellApart() {
        for radius in [Float(0.16), 0.22, 0.3] {
            let pitch = LoopShape.pitch(radius: radius)
            #expect(pitch > 4 * GamePhysics.ballRadius,
                    "a \(radius) m loop puts its mouths only \(pitch) m apart")
            #expect(pitch < 4 * radius,
                    "a \(radius) m loop is stretched into a barrel at \(pitch) m")
        }
    }

    /// The top of the loop is the full diameter above the felt, and that is the
    /// height the ball has to have bought with its speed on the way up.
    @Test func theCrownStandsADiameterOverTheFelt() {
        let crown = LoopShape.point(theta: .pi, radius: Self.radius, pitch: Self.pitch)
        #expect(abs(crown.y - 2 * Self.radius) < 0.0001)

        for step in 0...360 {
            let theta = Float(step) * .pi / 180
            let point = LoopShape.point(theta: theta, radius: Self.radius, pitch: Self.pitch)
            #expect(point.y >= -0.0001 && point.y <= 2 * Self.radius + 0.0001,
                    "at \(theta) rad the track is \(point.y) m up")
        }
    }

    /// The ball is moved along the track by `speed × tangent`, so a tangent that
    /// went to zero anywhere would stall it there for good.
    @Test func theTrackNeverStalls() {
        for step in 0...360 {
            let theta = Float(step) * .pi / 180
            let tangent = LoopShape.tangent(theta: theta, radius: Self.radius, pitch: Self.pitch)
            #expect(simd_length(tangent) > 0.001,
                    "the track has no direction at \(theta) rad")
        }
    }

    /// `tangent` is the derivative of `point`, and the coordinator relies on
    /// that: it trades speed for the height the next step will cost, then steps.
    @Test func theTangentIsTheDerivativeOfThePath() {
        let h: Float = 0.0005
        for step in 1...359 {
            let theta = Float(step) * .pi / 180
            let ahead = LoopShape.point(theta: theta + h, radius: Self.radius, pitch: Self.pitch)
            let behind = LoopShape.point(theta: theta - h, radius: Self.radius, pitch: Self.pitch)
            let measured = (ahead - behind) / (2 * h)
            let stated = LoopShape.tangent(theta: theta, radius: Self.radius, pitch: Self.pitch)
            #expect(simd_length(measured - stated) < 0.001,
                    "at \(theta) rad the path runs \(measured) but says \(stated)")
        }
    }

    /// The ball's own path is the track less its radius, lifted so it still
    /// touches down on the felt rather than sinking through it at the mouths.
    @Test func theBallRidesInsideTheTrack() {
        let loop = LoopTrack(center: SIMD2(0, -1.5), radius: Self.radius,
                             axis: SIMD2(0, 1), halfWidth: 0.1, y: 0)
        #expect(loop.trackRadius < loop.radius)
        #expect(abs(loop.ballPoint(theta: 0).y - GamePhysics.ballRadius) < 0.0001,
                "the ball does not start resting on the felt")
        #expect(loop.ballPoint(theta: .pi).y < 2 * loop.radius,
                "the ball rides outside the ring at the crown")
    }

    /// Which mouth the ball rolls into depends on which way it was going, and
    /// the two are a pitch apart either side of the middle of the run.
    @Test func eitherEndCanBeEntered() {
        let loop = LoopTrack(center: SIMD2(0.4, -2), radius: Self.radius,
                             axis: SIMD2(0, 1), halfWidth: 0.1, y: 0)
        let forward = loop.mouth(sign: 1)
        let backward = loop.mouth(sign: -1)

        #expect(abs(simd_distance(forward, backward) - loop.pitch) < 0.0001)
        #expect(simd_distance((forward + backward) / 2, loop.center) < 0.0001,
                "the mouths are not evenly placed about the middle of the run")
    }
}
