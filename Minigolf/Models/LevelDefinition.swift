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
