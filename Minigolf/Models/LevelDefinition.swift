//
//  LevelDefinition.swift
//  Minigolf
//
//  Data-driven description of a single minigolf hole. All coordinates are in
//  meters on the XZ plane; the tee sits near z = 0 and holes extend toward -Z.
//

import Foundation
import simd

/// One rectangular slab of the course floor.
struct FloorPatch {
    enum Kind {
        case green   // regular felt, normal friction
        case sand    // high damping trap
        case mud     // even slower: swamp, ash, slush
        case ice     // almost frictionless
        case water   // no collision, ball drops in -> penalty
        case lava    // no collision, molten -> penalty
    }

    var rect: GroundRect
    var kind: Kind = .green
    /// Height of the walkable top surface.
    var y: Float = 0
}

extension FloorPatch.Kind {
    /// Hazards are real gaps in the floor: falling in costs a stroke.
    var isHazard: Bool {
        self == .water || self == .lava
    }

    /// Surfaces painted as a thin skin on top of a green patch. They carry no
    /// collider — only a damping change while the ball rolls over them.
    var isOverlay: Bool {
        self == .sand || self == .mud || self == .ice
    }
}

/// A straight wall between two points on the XZ plane.
struct WallSegment {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    /// Base height (top surface of the floor the wall stands on).
    var baseY: Float = 0
    var height: Float = 0.085
    var thickness: Float = 0.055
}

/// The cast of characters that live on the holes — two per world. They are
/// scenery with teeth: solid enough that a putt banks off them, and never still,
/// so where one will be by the time the ball arrives is part of the shot.
enum CritterKind {
    case hedgehog, mole          // Green Garden
    case tumbleweed, meerkat     // Desert Oasis
    case frog, turtle            // Jungle Temple
    case snowman, penguin        // Frozen Fjord
    case drone, sentry           // Neon Nights
    case imp, magmaBlob          // Volcano Forge
    case windupBot, cuckoo       // Clockwork Works
    case crab, seagull           // Storm Coast
    case alien, rover            // Orbital Station
}

extension CritterKind {
    /// How far the character reaches out across the felt: the radius of the
    /// collider the ball meets, and the only bit of its geometry the level
    /// checker and the scene builder both have to agree on.
    var radius: Float {
        switch self {
        case .snowman, .tumbleweed, .turtle, .rover: return 0.08
        case .crab, .magmaBlob, .windupBot: return 0.07
        case .mole, .meerkat, .cuckoo: return 0.05
        case .hedgehog, .penguin, .frog, .drone, .sentry, .imp, .seagull, .alien: return 0.06
        }
    }
}

/// How a critter gets about. Whatever it does it stays on its own patch of
/// felt: the point is that the player can watch it for a moment and then time
/// the putt, not that it chases the ball around.
enum CritterMotion {
    /// Walks back and forth along `axis`, `amplitude` metres either side of its
    /// centre, turning round at each end.
    case patrol(axis: SIMD2<Float>, amplitude: Float)
    /// Walks a circle of `radius` around its centre.
    case circle(radius: Float)
    /// Sits, then leaps to the other end of `axis` and sits again. The ball can
    /// be threaded underneath one in mid-air.
    case hop(axis: SIMD2<Float>, amplitude: Float, height: Float)
    /// Pops up out of the felt and sinks back down on a `period`-second cycle,
    /// well clear of the ball while it is under.
    case burrow(period: Float)
}

/// Interactive/physical obstacles placed on the course.
enum ObstacleSpec {
    /// Classic mill with rotating blades over a narrow gate. `yaw` in radians.
    case windmill(center: SIMD2<Float>, yaw: Float, speed: Float)
    /// Bar rotating around the vertical axis, sweeping just above the floor.
    case rotor(center: SIMD2<Float>, length: Float, speed: Float, baseY: Float)
    /// Kinematic block sliding back and forth along `axis`.
    case movingBlock(center: SIMD2<Float>, axis: SIMD2<Float>, amplitude: Float,
                     speed: Float, size: SIMD2<Float>, baseY: Float)
    /// Round bouncy pillar.
    case bumper(center: SIMD2<Float>, radius: Float)
    /// Small static post.
    case post(center: SIMD2<Float>, radius: Float)
    /// Smooth speed bump across the lane; `height` is the crest above the felt.
    case bump(center: SIMD2<Float>, width: Float, height: Float, yaw: Float)
    /// Inclined slab connecting two floor heights, rising toward -Z when yaw = 0.
    case ramp(center: SIMD2<Float>, width: Float, length: Float, rise: Float, yaw: Float)
    /// Static box, useful as deflector or island wall. `yaw` in radians.
    case block(center: SIMD2<Float>, size: SIMD3<Float>, yaw: Float, baseY: Float)
    /// Decorative tunnel arch over the lane (two side walls + roof).
    case tunnel(center: SIMD2<Float>, width: Float, length: Float, yaw: Float)
    /// Banked green: pushes the rolling ball sideways with a gentle, constant
    /// acceleration (m/s²). Drawn as a tinted wedge with drift arrows.
    case slope(rect: GroundRect, direction: SIMD2<Float>, strength: Float, y: Float)
    /// Belt that carries the ball along `direction` — same physics as a slope
    /// but much stronger and drawn with moving chevrons.
    case conveyor(rect: GroundRect, direction: SIMD2<Float>, strength: Float, y: Float)
    /// Portal pair: rolling into either ring throws the ball out of the other
    /// one with its speed intact.
    case teleporter(a: SIMD2<Float>, b: SIMD2<Float>, radius: Float, y: Float)
    /// Wall that sinks into the floor and rises again on a timer — a gap that
    /// has to be timed. `period` is one full cycle in seconds.
    case gate(center: SIMD2<Float>, size: SIMD2<Float>, yaw: Float,
              period: Float, phase: Float, baseY: Float)
    /// Bar hanging from above, swinging across the lane like a vine.
    /// `yaw` = 0 sweeps along X; `arc` is the half-angle in radians.
    case pendulum(center: SIMD2<Float>, span: Float, arc: Float, speed: Float,
                  yaw: Float, baseY: Float)
    /// Pad that kicks the ball along `direction` when it rolls across; `boost`
    /// is the added speed in m/s.
    case boostPad(center: SIMD2<Float>, direction: SIMD2<Float>, boost: Float, y: Float)
    /// Loop-the-loop standing over the lane. The track is stretched along the
    /// lane, so it has a real entrance and a real exit: the ball rolls in at the
    /// near mouth, is carried around the inside of the ring and comes back down
    /// to the felt `loopPitch` further on. It trades speed for height the whole
    /// way — too slow and it rolls back out of the entrance, not quite fast
    /// enough and it drops off near the top. `yaw` = 0 runs the track along Z;
    /// `center` is the middle of the run, half a pitch from either mouth.
    case loop(center: SIMD2<Float>, radius: Float, width: Float, yaw: Float, y: Float)
    /// Kicker that throws the ball over a gap. It always leaves at exactly
    /// `speed` forward and `lift` upward, so the jump lands in the same place
    /// every time (range ≈ 2 · speed · lift / g). A ball crawling in below half
    /// `speed` just rolls over the wedge.
    case launchPad(center: SIMD2<Float>, direction: SIMD2<Float>, speed: Float,
                   lift: Float, y: Float)
    /// Barrel that swallows the ball, holds it while it charges, then fires it
    /// along `direction` — whichever way the ball happened to roll in.
    case cannon(center: SIMD2<Float>, direction: SIMD2<Float>, speed: Float, y: Float)
    /// Disc set into the felt, turning at `speed` rad/s. Friction drags the ball
    /// around with it and slings it off the rim.
    case turntable(center: SIMD2<Float>, radius: Float, speed: Float, y: Float)
    /// Pulls the ball in (positive `strength`, in m/s²) or pushes it away
    /// (negative) everywhere inside `radius`, fading out toward the edge.
    case magnet(center: SIMD2<Float>, radius: Float, strength: Float, y: Float)
    /// Wind that swells and dies away on a `period`-second cycle. The same force
    /// zone as a belt, except the blades tell the player when it is blowing.
    case fan(rect: GroundRect, direction: SIMD2<Float>, strength: Float,
             period: Float, phase: Float, y: Float)
    /// One of the world's characters, going about its business on the felt. It
    /// is a solid kinematic body like a sliding block — a moving one shunts a
    /// ball at rest, and a ball that runs into one banks off and knocks it over
    /// sideways. `speed` is in radians per second of its cycle.
    case critter(kind: CritterKind, center: SIMD2<Float>, motion: CritterMotion,
                 speed: Float, phase: Float, baseY: Float)
}

/// Complete definition of one hole.
struct LevelDefinition: Identifiable {
    var course: CourseType
    var number: Int              // 1...holeCount
    /// Flavour name shown in the intro banner and on the hole picker.
    var name: String
    var par: Int
    var tee: SIMD2<Float>
    var hole: SIMD2<Float>
    var holeY: Float = 0
    var floors: [FloorPatch]
    /// Closed outlines: walls are built between consecutive points (loop closes automatically).
    var wallLoops: [[SIMD2<Float>]] = []
    var extraWalls: [WallSegment] = []
    var obstacles: [ObstacleSpec] = []
    /// Optional bonus star, usually tucked away off the direct line of play.
    var bonusStar: SIMD2<Float>?
    var bonusStarY: Float = 0
    /// Extra camera pull-back for larger holes.
    var cameraZoom: Float = 1.0

    var id: String { "\(course.rawValue)-\(number)" }
    var strokeLimit: Int { par + 3 }

    /// Bounding rect of all floors (used for decoration placement and bounds checks).
    var bounds: GroundRect {
        guard var rect = floors.first?.rect else {
            return GroundRect(x0: -1, x1: 1, z0: -1, z1: 1)
        }
        for patch in floors.dropFirst() {
            rect = rect.union(patch.rect)
        }
        return rect
    }

    var minFloorY: Float {
        floors.map(\.y).min() ?? 0
    }
}

// MARK: - Authoring helpers

func floorRect(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float,
               kind: FloorPatch.Kind = .green, y: Float = 0) -> FloorPatch {
    FloorPatch(rect: GroundRect(x0: x0, x1: x1, z0: z0, z1: z1), kind: kind, y: y)
}

/// Bare rectangle for zone-shaped obstacles (slopes, belts).
func zone(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) -> GroundRect {
    GroundRect(x0: x0, x1: x1, z0: z0, z1: z1)
}

/// A character on its rounds. Only the kind, the spot and the path are worth
/// spelling out in a hole — the rest of the dial settings have sane defaults,
/// which enum cases cannot carry.
func critter(_ kind: CritterKind, at center: SIMD2<Float>, _ motion: CritterMotion,
             speed: Float = 1.0, phase: Float = 0, baseY: Float = 0) -> ObstacleSpec {
    .critter(kind: kind, center: center, motion: motion, speed: speed,
             phase: phase, baseY: baseY)
}

/// Straight line for a patrol, in the two directions holes are laid out on.
let acrossLane = SIMD2<Float>(1, 0)
let alongLane = SIMD2<Float>(0, 1)

// MARK: - Loop geometry

/// The shape of a loop-the-loop, shared by the model, the builder, the aim
/// guide and the offline validator so all four agree on where the track runs.
///
/// A plain circle is closed: it touches the felt at a single point, which is
/// both its entrance and its exit, and it reads as a hoop parked on the lane.
/// A real loop is stretched — the track drifts forward the whole way round, so
/// it leaves the felt at one mouth and touches down again a pitch further on,
/// crossing over itself low down exactly the way a toy loop does.
enum LoopShape {
    /// Distance between the two mouths, measured along the lane. Enough for the
    /// entrance and the exit to be four ball widths apart, and little enough
    /// that the ring still looks like a ring rather than a barrel.
    static func pitch(radius: Float) -> Float { radius * 1.5 }

    /// Point on the track at `theta` — 0 at the entrance, 2π at the exit — in
    /// the vertical plane of the run: x is measured along the lane from the
    /// middle of the loop, y over the felt. `radius` is the curve being traced:
    /// the ring for its own geometry, one ball radius less for the ball's path.
    static func point(theta: Float, radius: Float, pitch: Float) -> SIMD2<Float> {
        SIMD2(pitch * (theta / (2 * .pi) - 0.5) + radius * sin(theta),
              radius * (1 - cos(theta)))
    }

    /// Derivative of `point`: the direction of travel, its length the arc the
    /// ball covers per radian.
    static func tangent(theta: Float, radius: Float, pitch: Float) -> SIMD2<Float> {
        SIMD2(pitch / (2 * .pi) + radius * cos(theta), radius * sin(theta))
    }
}

/// Corner points of a rectangle outline (counter-clockwise, closed by the builder).
func rectLoop(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) -> [SIMD2<Float>] {
    [
        SIMD2(x0, z0), SIMD2(x1, z0),
        SIMD2(x1, z1), SIMD2(x0, z1),
    ]
}

func wall(_ x0: Float, _ z0: Float, _ x1: Float, _ z1: Float,
          baseY: Float = 0, height: Float = 0.085) -> WallSegment {
    WallSegment(from: SIMD2(x0, z0), to: SIMD2(x1, z1), baseY: baseY, height: height)
}

/// Boards along an open run of points. `wallLoops` closes and always stands on
/// the ground; this does neither, so it is what a raised green and a half-open
/// outline are kerbed with.
func wallPath(_ points: [SIMD2<Float>], baseY: Float = 0,
              height: Float = 0.085) -> [WallSegment] {
    zip(points, points.dropFirst()).map {
        WallSegment(from: $0.0, to: $0.1, baseY: baseY, height: height)
    }
}

/// Boards all the way round a closed outline standing on a raised green. The
/// board is tall enough to retain the green it stands beside *and* to guard the
/// floor at its own foot, which is how one kerb serves both heights.
func wallRing(_ points: [SIMD2<Float>], baseY: Float = 0,
              height: Float = 0.085) -> [WallSegment] {
    guard points.count > 1 else { return [] }
    return wallPath(points + [points[0]], baseY: baseY, height: height)
}


// MARK: - Rounded greens

/// How a corner of `radius` is stepped, as fractions of that radius: the run
/// along each axis from the corner point of the square towards the arc.
///
/// An axis-aligned floor cannot hold a curve, and a kerb cutting straight
/// across a step leaves the felt behind it unguarded — so how sharply a corner
/// may be rounded is a function of how many boards cut it. The checker allows a
/// 10 cm unguarded run, which works out at **0.17 m of radius per step**: one
/// board gives a chamfer, two a soft corner, three a corner that reads as
/// round. Going past that leaves a lip of felt outside the kerb.
private func cornerSteps(_ steps: Int) -> [(cos: Float, sin: Float)] {
    (0...max(1, steps)).map { k in
        let angle = Float.pi / 2 * Float(k) / Float(max(1, steps))
        return (cos(angle), sin(angle))
    }
}

/// The largest radius `steps` boards can round a corner with before the felt
/// starts showing outside the kerb: one board gives a chamfer, two a soft
/// corner, three a corner that reads as round from the tee.
func maxCornerRadius(steps: Int) -> Float { 0.15 * Float(max(1, steps)) }

/// Outline of a rectangle rounded at one or both ends — the kerb line of a
/// target green. Holes run away from the tee toward −Z, so `far` rounds the two
/// corners at `z0` and `near` the two at `z1`.
///
/// The run of points starts and ends on the near edge, so `wallPath` boards
/// everything **but** that edge: the kerb of a green a lane runs straight into.
/// Passing the same points to `wallLoops` closes it instead, for a green that
/// stands on its own.
func roundedLoop(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float,
                 far: Float, near: Float = 0, steps: Int = 2) -> [SIMD2<Float>] {
    let arc = cornerSteps(steps)
    var out: [SIMD2<Float>] = []

    if near > 0.001 {
        let c = SIMD2(x0 + near, z1 - near)
        out += arc.map { c + SIMD2(-near * $0.sin, near * $0.cos) }
    } else {
        out.append(SIMD2(x0, z1))
    }

    if far > 0.001 {
        let c = SIMD2(x0 + far, z0 + far)
        out += arc.map { c + SIMD2(-far * $0.cos, -far * $0.sin) }
        let d = SIMD2(x1 - far, z0 + far)
        out += arc.map { d + SIMD2(far * $0.sin, -far * $0.cos) }
    } else {
        out += [SIMD2(x0, z0), SIMD2(x1, z0)]
    }

    if near > 0.001 {
        let c = SIMD2(x1 - near, z1 - near)
        out += arc.map { c + SIMD2(near * $0.cos, near * $0.sin) }
    } else {
        out.append(SIMD2(x1, z1))
    }

    return out
}

/// Boards round a green shaped with `roundedLoop`, leaving its near edge open —
/// that is where the lane joins it. `openFar` leaves the far edge open too, for
/// a green with a shaft going on out of it; the stubs either side of a mouth
/// belong to the caller, since only the hole knows how wide the mouth is.
func roundedKerb(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float,
                 far: Float, near: Float = 0, steps: Int = 2, openFar: Bool = false,
                 baseY: Float = 0, height: Float = 0.085) -> [WallSegment] {
    let boards = wallPath(roundedLoop(x0, x1, z0, z1, far: far, near: near, steps: steps),
                          baseY: baseY, height: height)
    guard openFar else { return boards }
    // The far edge is the one board that runs straight along z0.
    return boards.filter {
        !(abs($0.from.y - z0) < 0.001 && abs($0.to.y - z0) < 0.001)
    }
}

/// The felt inside a `roundedLoop`, laid in courses like stone: one wide band
/// across the middle and a narrower one for every step of the rounding, so the
/// corners the kerb cuts are left to the paving rather than paved in felt.
/// Give it the same arguments as the loop; the two only agree while that holds.
func roundedFloor(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float,
                  far: Float, near: Float = 0, steps: Int = 2,
                  kind: FloorPatch.Kind = .green, y: Float = 0) -> [FloorPatch] {
    let arc = cornerSteps(steps)
    var out = [FloorPatch(rect: GroundRect(x0: x0, x1: x1, z0: z0 + far, z1: z1 - near),
                          kind: kind, y: y)]
    for k in arc.indices.dropLast() {
        // Each course stops at the narrow end of the step it spans, so the
        // board cutting across that step always has felt behind it.
        if far > 0.001 {
            let inset = far * (1 - arc[k + 1].cos)
            out.append(FloorPatch(
                rect: GroundRect(x0: x0 + inset, x1: x1 - inset,
                                 z0: z0 + far * (1 - arc[k + 1].sin),
                                 z1: z0 + far * (1 - arc[k].sin)), kind: kind, y: y))
        }
        if near > 0.001 {
            let inset = near * (1 - arc[k + 1].cos)
            out.append(FloorPatch(
                rect: GroundRect(x0: x0 + inset, x1: x1 - inset,
                                 z0: z1 - near * (1 - arc[k].sin),
                                 z1: z1 - near * (1 - arc[k + 1].sin)), kind: kind, y: y))
        }
    }
    return out
}

/// Points along a circular arc on the XZ plane. Angles are in radians and are
/// measured the same way the rest of the level data reads them: 0 points at +X,
/// 90° at +Z. Handy for rounded bowls and banked turns, which a hand-written
/// list of corners never gets smooth enough.
func arcPoints(center: SIMD2<Float>, radius: Float, from: Float, to: Float,
               segments: Int = 8) -> [SIMD2<Float>] {
    let steps = max(1, segments)
    return (0...steps).map { i in
        let angle = from + (to - from) * Float(i) / Float(steps)
        return center + SIMD2(cos(angle) * radius, sin(angle) * radius)
    }
}

/// Curved board: an arc chopped into straight boards. The ball banks off it the
/// same way it banks off any other wall, so a bowl or a horseshoe needs no new
/// runtime support at all.
func arcWall(center: SIMD2<Float>, radius: Float, from: Float, to: Float,
             segments: Int = 8, baseY: Float = 0, height: Float = 0.085) -> [WallSegment] {
    let points = arcPoints(center: center, radius: radius, from: from, to: to,
                           segments: segments)
    return zip(points, points.dropFirst()).map {
        WallSegment(from: $0.0, to: $0.1, baseY: baseY, height: height)
    }
}

/// Degrees as radians — arc angles read better that way in the level files.
func deg(_ value: Float) -> Float { value * .pi / 180 }
