//
//  validate_levels.swift
//  Minigolf tools
//
//  Offline geometry check for every hole in the library. The level data is
//  plain Foundation + simd, so it can be compiled for macOS and inspected
//  without launching the app:
//
//      swiftc -O -o /tmp/validate Tools/validate_levels.swift \
//          Minigolf/Support/MathHelpers.swift \
//          Minigolf/Models/CourseType.swift \
//          Minigolf/Models/LevelDefinition.swift \
//          Minigolf/Models/LevelLibrary.swift \
//          Minigolf/Models/Levels/*.swift && /tmp/validate
//
//  It reports anything that would make a hole unplayable: a cup inside a wall,
//  a green with an open edge the ball can roll off, floors that are not
//  connected to the tee, obstacles sitting on top of the hole and so on.
//  Finally it flood fills the playable surface cell by cell to prove the ball
//  can really roll from the tee to the cup and to the bonus star — pockets
//  sealed off by boards inside a single green show up there.
//

import Foundation
import simd

let ballRadius: Float = 0.034

// MARK: - Small geometry helpers

struct Seg {
    var a: SIMD2<Float>
    var b: SIMD2<Float>
    var baseY: Float
    var height: Float
    var thickness: Float = 0.055

    func distance(to p: SIMD2<Float>) -> Float {
        let d = b - a
        let len2 = simd_length_squared(d)
        guard len2 > 1e-9 else { return simd_distance(p, a) }
        let t = simd_clamp(simd_dot(p - a, d) / len2, 0, 1)
        return simd_distance(p, a + d * t)
    }

    /// A wall only guards the surface it actually stands beside.
    func guards(y: Float) -> Bool {
        baseY <= y + 0.002 && baseY + height > y + 0.02
    }
}

func walls(of level: LevelDefinition) -> [Seg] {
    var out: [Seg] = []
    for loop in level.wallLoops {
        for i in 0..<loop.count {
            out.append(Seg(a: loop[i], b: loop[(i + 1) % loop.count], baseY: 0, height: 0.085))
        }
    }
    for w in level.extraWalls {
        out.append(Seg(a: w.from, b: w.to, baseY: w.baseY, height: w.height,
                       thickness: w.thickness))
    }
    return out
}

func touches(_ a: GroundRect, _ b: GroundRect, slack: Float = 0.02) -> Bool {
    a.minX - slack < b.maxX && b.minX - slack < a.maxX &&
    a.minZ - slack < b.maxZ && b.minZ - slack < a.maxZ
}

func strictlyOverlaps(_ a: GroundRect, _ b: GroundRect) -> Bool {
    a.minX + 0.001 < b.maxX && b.minX + 0.001 < a.maxX &&
    a.minZ + 0.001 < b.maxZ && b.minZ + 0.001 < a.maxZ
}

func contains(_ outer: GroundRect, _ inner: GroundRect) -> Bool {
    inner.minX >= outer.minX - 0.001 && inner.maxX <= outer.maxX + 0.001 &&
    inner.minZ >= outer.minZ - 0.001 && inner.maxZ <= outer.maxZ + 0.001
}

// MARK: - Obstacle introspection

/// Points an obstacle occupies that the ball must not find the cup underneath.
func blockingPoints(_ spec: ObstacleSpec) -> [SIMD2<Float>] {
    switch spec {
    case .windmill(let c, _, _): return [c]
    case .rotor(let c, _, _, _): return [c]
    case .movingBlock(let c, _, _, _, _, _): return [c]
    case .bumper(let c, _): return [c]
    case .post(let c, _): return [c]
    case .block(let c, _, _, _): return [c]
    case .gate(let c, _, _, _, _, _): return [c]
    case .pendulum(let c, _, _, _, _, _): return [c]
    case .tunnel(let c, _, _, _): return [c]
    case .cannon(let c, _, _, _): return [c]
    case .loop(let c, let radius, _, let yaw, _):
        // The whole run is off limits, both mouths included.
        let along = SIMD2(sin(yaw), cos(yaw))
        let half = LoopShape.pitch(radius: radius) / 2
        return [c, c + along * half, c - along * half]
    default: return []
    }
}

/// Every point of an obstacle that has to sit over playable floor.
func footprint(_ spec: ObstacleSpec) -> [SIMD2<Float>] {
    switch spec {
    case .windmill(let c, _, _): return [c]
    case .rotor(let c, let l, _, _):
        return [c, c + SIMD2(l / 2, 0), c - SIMD2(l / 2, 0)]
    case .movingBlock(let c, let axis, let amp, _, _, _):
        let unit = simd_length(axis) > 0 ? simd_normalize(axis) : SIMD2(1, 0)
        return [c, c + unit * amp, c - unit * amp]
    case .bumper(let c, _), .post(let c, _): return [c]
    case .bump(let c, let w, _, let yaw):
        let dir = SIMD2(cos(yaw), -sin(yaw))
        return [c, c + dir * (w / 2 - 0.02), c - dir * (w / 2 - 0.02)]
    case .ramp(let c, _, _, _, _): return [c]
    case .block(let c, _, _, _): return [c]
    case .tunnel(let c, _, _, _): return [c]
    case .slope(let r, _, _, _), .conveyor(let r, _, _, _):
        return [SIMD2(r.minX + 0.01, r.minZ + 0.01), SIMD2(r.maxX - 0.01, r.minZ + 0.01),
                SIMD2(r.minX + 0.01, r.maxZ - 0.01), SIMD2(r.maxX - 0.01, r.maxZ - 0.01)]
    case .teleporter(let a, let b, _, _): return [a, b]
    case .gate(let c, let size, _, _, _, _):
        return [c, c + SIMD2(size.x / 2 - 0.01, 0), c - SIMD2(size.x / 2 - 0.01, 0)]
    case .pendulum(let c, _, _, _, _, _): return [c]
    case .boostPad(let c, _, _, _): return [c]
    case .loop(let c, let radius, _, let yaw, _):
        // Both mouths plus the ends of the channel the track stands in.
        let along = SIMD2(sin(yaw), cos(yaw))
        let reach = LoopShape.pitch(radius: radius) / 2 + 0.16
        return [c, c + along * reach, c - along * reach]
    case .launchPad(let c, _, _, _, _): return [c]
    case .cannon(let c, let dir, _, _):
        // The barrel may hang over the edge, but the ball has to land on felt.
        let unit = simd_length(dir) > 0 ? simd_normalize(dir) : SIMD2(0, -1)
        return [c, c + unit * 0.26]
    case .turntable(let c, let radius, _, _):
        return [c, c + SIMD2(radius - 0.01, 0), c - SIMD2(radius - 0.01, 0),
                c + SIMD2(0, radius - 0.01), c - SIMD2(0, radius - 0.01)]
    case .magnet(let c, _, _, _): return [c]
    case .fan(let r, _, _, _, _, _):
        return [SIMD2(r.minX + 0.01, r.minZ + 0.01), SIMD2(r.maxX - 0.01, r.minZ + 0.01),
                SIMD2(r.minX + 0.01, r.maxZ - 0.01), SIMD2(r.maxX - 0.01, r.maxZ - 0.01)]
    }
}

/// Where a kicker drops the ball again on level ground: a plain ballistic arc
/// at the fixed speed and lift the pad hands out.
func jumpLanding(_ c: SIMD2<Float>, _ direction: SIMD2<Float>,
                 speed: Float, lift: Float) -> SIMD2<Float> {
    let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(0, -1)
    return c + unit * (2 * speed * lift / 9.81)
}

func obstacleY(_ spec: ObstacleSpec) -> Float {
    switch spec {
    case .rotor(_, _, _, let y), .movingBlock(_, _, _, _, _, let y),
         .block(_, _, _, let y), .slope(_, _, _, let y), .conveyor(_, _, _, let y),
         .teleporter(_, _, _, let y), .gate(_, _, _, _, _, let y),
         .pendulum(_, _, _, _, _, let y), .boostPad(_, _, _, let y),
         .loop(_, _, _, _, let y), .launchPad(_, _, _, _, let y),
         .cannon(_, _, _, let y), .turntable(_, _, _, let y),
         .magnet(_, _, _, let y), .fan(_, _, _, _, _, let y):
        return y
    default:
        return 0
    }
}

func obstacleName(_ spec: ObstacleSpec) -> String {
    switch spec {
    case .windmill: return "windmill"
    case .rotor: return "rotor"
    case .movingBlock: return "movingBlock"
    case .bumper: return "bumper"
    case .post: return "post"
    case .bump: return "bump"
    case .ramp: return "ramp"
    case .block: return "block"
    case .tunnel: return "tunnel"
    case .slope: return "slope"
    case .conveyor: return "conveyor"
    case .teleporter: return "teleporter"
    case .gate: return "gate"
    case .pendulum: return "pendulum"
    case .boostPad: return "boostPad"
    case .loop: return "loop"
    case .launchPad: return "launchPad"
    case .cannon: return "cannon"
    case .turntable: return "turntable"
    case .magnet: return "magnet"
    case .fan: return "fan"
    }
}

// MARK: - Checks

var problems = 0
var warnings = 0

func fail(_ level: LevelDefinition, _ message: String) {
    print("  ✗ \(level.course.rawValue) \(level.number) (\(level.name)): \(message)")
    problems += 1
}

func warn(_ level: LevelDefinition, _ message: String) {
    print("  ! \(level.course.rawValue) \(level.number) (\(level.name)): \(message)")
    warnings += 1
}

func greens(_ level: LevelDefinition) -> [FloorPatch] {
    level.floors.filter { $0.kind == .green }
}

/// Playable surface: greens plus the overlay skins painted on top of them.
func surfaces(_ level: LevelDefinition) -> [FloorPatch] {
    level.floors.filter { !$0.kind.isHazard }
}

func patchIndex(containing p: SIMD2<Float>, y: Float, in level: LevelDefinition) -> Int? {
    greens(level).indices.first { i in
        let patch = greens(level)[i]
        return abs(patch.y - y) < 0.001 && patch.rect.contains(p)
    }
}

func checkPlacement(_ level: LevelDefinition) {
    let ws = walls(of: level)

    // Tee and cup have to sit on a green at the right height, clear of boards.
    if patchIndex(containing: level.tee, y: 0, in: level) == nil {
        fail(level, "tee \(fmt(level.tee)) is not on a green patch at y = 0")
    }
    if patchIndex(containing: level.hole, y: level.holeY, in: level) == nil {
        fail(level, "cup \(fmt(level.hole)) is not on a green patch at y = \(level.holeY)")
    }
    for w in ws where w.guards(y: level.holeY) && w.distance(to: level.hole) < 0.075 {
        fail(level, "cup \(fmt(level.hole)) is inside a wall (\(fmt(w.a))–\(fmt(w.b)))")
        break
    }
    for w in ws where w.guards(y: 0) && w.distance(to: level.tee) < 0.07 {
        warn(level, "tee is only \(String(format: "%.3f", w.distance(to: level.tee))) m from a wall")
        break
    }
    if simd_distance(level.tee, level.hole) < 0.6 {
        warn(level, "tee and cup are only \(String(format: "%.2f", simd_distance(level.tee, level.hole))) m apart")
    }

    // Overlays are skins: they must lie on a green of the same height.
    for patch in level.floors where patch.kind.isOverlay {
        let host = greens(level).contains {
            abs($0.y - patch.y) < 0.001 && contains($0.rect, patch.rect)
        }
        if !host {
            fail(level, "\(patch.kind) patch \(fmt(patch.rect)) is not fully on a green at y = \(patch.y)")
        }
    }

    // Hazards are real gaps: no green may bridge them, or the ball never falls in.
    for hazard in level.floors where hazard.kind.isHazard {
        for green in greens(level) where abs(green.y - hazard.y) < 0.001 {
            if strictlyOverlaps(green.rect, hazard.rect) {
                fail(level, "\(hazard.kind) \(fmt(hazard.rect)) is covered by green \(fmt(green.rect))")
            }
        }
    }

    // Obstacles: over floor, and never on top of the cup or the tee.
    for spec in level.obstacles {
        let y = obstacleY(spec)
        // A ramp deliberately spans the gap between two floors, so only its
        // two ends are checked (below).
        var isRamp = false
        if case .ramp = spec { isRamp = true }
        for p in footprint(spec) where !isRamp {
            let onFloor = level.floors.contains {
                abs($0.y - y) < 0.001 && $0.rect.contains(p, margin: 0.03)
            }
            if !onFloor {
                fail(level, "\(obstacleName(spec)) point \(fmt(p)) is off the floor at y = \(y)")
            }
        }
        for p in blockingPoints(spec) {
            if abs(y - level.holeY) < 0.001, simd_distance(p, level.hole) < 0.14 {
                fail(level, "\(obstacleName(spec)) at \(fmt(p)) sits on the cup")
            }
            if abs(y) < 0.001, simd_distance(p, level.tee) < 0.14 {
                fail(level, "\(obstacleName(spec)) at \(fmt(p)) sits on the tee")
            }
        }
        if case .ramp(let c, _, let length, let rise, _) = spec {
            let low = greens(level).contains {
                abs($0.y) < 0.001 && touches($0.rect, GroundRect(
                    x0: c.x - 0.05, x1: c.x + 0.05,
                    z0: c.y + length / 2 - 0.02, z1: c.y + length / 2 + 0.02))
            }
            let high = greens(level).contains {
                abs($0.y - rise) < 0.001 && touches($0.rect, GroundRect(
                    x0: c.x - 0.05, x1: c.x + 0.05,
                    z0: c.y - length / 2 - 0.02, z1: c.y - length / 2 + 0.02))
            }
            if !low { fail(level, "ramp at \(fmt(c)) has no green at its foot (y = 0)") }
            if !high { fail(level, "ramp at \(fmt(c)) has no green at its top (y = \(rise))") }
        }
        if case .launchPad(let c, let dir, let speed, let lift, _) = spec {
            let landing = jumpLanding(c, dir, speed: speed, lift: lift)
            let lands = surfaces(level).contains { $0.rect.contains(landing, margin: 0.05) }
            if !lands {
                fail(level, "launchPad at \(fmt(c)) throws the ball to \(fmt(landing)), " +
                            "where there is nothing to land on")
            }
        }
        if case .teleporter(let a, let b, _, let y) = spec {
            for (label, p) in [("A", a), ("B", b)] {
                if patchIndex(containing: p, y: y, in: level) == nil {
                    fail(level, "portal \(label) \(fmt(p)) is not on a green at y = \(y)")
                }
                for w in ws where w.guards(y: y) && w.distance(to: p) < 0.12 {
                    warn(level, "portal \(label) \(fmt(p)) is very close to a wall")
                    break
                }
            }
        }
    }

    // Bonus star: reachable spot on a real surface, not buried in the boards.
    if let star = level.bonusStar {
        let onSurface = surfaces(level).contains {
            abs($0.y - level.bonusStarY) < 0.001 && $0.rect.contains(star)
        }
        if !onSurface {
            fail(level, "bonus star \(fmt(star)) is not on a surface at y = \(level.bonusStarY)")
        }
        for w in ws where w.guards(y: level.bonusStarY) && w.distance(to: star) < ballRadius + 0.028 {
            fail(level, "bonus star \(fmt(star)) is unreachable behind a wall")
            break
        }
        if simd_distance(star, level.hole) < 0.16 {
            warn(level, "bonus star is right on top of the cup")
        }
        for spec in level.obstacles where abs(obstacleY(spec) - level.bonusStarY) < 0.001 {
            if blockingPoints(spec).contains(where: { simd_distance($0, star) < 0.11 }) {
                fail(level, "bonus star \(fmt(star)) is inside a \(obstacleName(spec))")
            }
        }
    }

    if level.par < 2 { fail(level, "par \(level.par) is too low") }
    let reach = simd_distance(level.tee, level.hole)
    if reach > Float(level.par) * 1.7 {
        warn(level, "cup is \(String(format: "%.1f", reach)) m away for par \(level.par)")
    }
}

/// Walks every green edge and complains about stretches the ball can roll off:
/// no neighbouring floor patch and no wall beside it.
func checkEnclosure(_ level: LevelDefinition) {
    let ws = walls(of: level)
    let all = level.floors

    for (patchIndex, patch) in level.floors.enumerated()
    where !patch.kind.isHazard && !patch.kind.isOverlay {
        let r = patch.rect
        let corners: [(SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)] = [
            (SIMD2(r.minX, r.minZ), SIMD2(r.maxX, r.minZ), SIMD2(0, -1)),
            (SIMD2(r.maxX, r.minZ), SIMD2(r.maxX, r.maxZ), SIMD2(1, 0)),
            (SIMD2(r.maxX, r.maxZ), SIMD2(r.minX, r.maxZ), SIMD2(0, 1)),
            (SIMD2(r.minX, r.maxZ), SIMD2(r.minX, r.minZ), SIMD2(-1, 0)),
        ]

        for (a, b, normal) in corners {
            let length = simd_distance(a, b)
            let steps = max(2, Int((length / 0.02).rounded(.up)))
            var openRun: Float = 0
            var worstRun: Float = 0
            var worstAt = a

            for i in 0...steps {
                let t = Float(i) / Float(steps)
                let p = a + (b - a) * t
                let outside = p + normal * 0.012
                let neighbour = all.indices.contains { k in
                    k != patchIndex && abs(all[k].y - patch.y) < 0.001 &&
                    !all[k].kind.isOverlay && all[k].rect.contains(outside)
                }
                let boarded = ws.contains { $0.guards(y: patch.y) && $0.distance(to: p) <= 0.05 }
                // A ramp bridges a gap the same way a floor patch does.
                let ramped = level.obstacles.contains { spec in
                    guard case .ramp(let c, let width, let rampLength, _, _) = spec else { return false }
                    let rect = GroundRect(x0: c.x - width / 2, x1: c.x + width / 2,
                                          z0: c.y - rampLength / 2, z1: c.y + rampLength / 2)
                    return rect.contains(outside, margin: 0.02)
                }
                // An edge that drops straight into a hazard is a design choice,
                // not a leak: falling in just costs a stroke.
                let overHazard = all.contains {
                    $0.kind.isHazard && $0.y <= patch.y + 0.001 && $0.rect.contains(outside)
                }
                if neighbour || boarded || ramped || overHazard {
                    openRun = 0
                } else {
                    openRun += length / Float(steps)
                    if openRun > worstRun { worstRun = openRun; worstAt = p }
                }
            }
            if worstRun > 0.1 {
                fail(level, "green \(fmt(r)) y=\(patch.y) has a \(String(format: "%.2f", worstRun)) m open edge near \(fmt(worstAt))")
            }
        }
    }
}

/// Flood fills the green patches from the tee and checks the cup can be reached.
func checkReachability(_ level: LevelDefinition) {
    let patches = greens(level)
    guard !patches.isEmpty else { return }

    var links: [Set<Int>] = Array(repeating: [], count: patches.count)
    func link(_ i: Int, _ j: Int) {
        links[i].insert(j)
        links[j].insert(i)
    }

    for i in patches.indices {
        for j in patches.indices where j > i {
            guard abs(patches[i].y - patches[j].y) < 0.001 else { continue }
            if touches(patches[i].rect, patches[j].rect, slack: 0.005) { link(i, j) }
        }
    }
    for spec in level.obstacles {
        switch spec {
        case .ramp(let c, let width, let length, let rise, _):
            let rect = GroundRect(x0: c.x - width / 2, x1: c.x + width / 2,
                                  z0: c.y - length / 2, z1: c.y + length / 2)
            let low = patches.indices.filter {
                abs(patches[$0].y) < 0.001 && touches(patches[$0].rect, rect, slack: 0.03)
            }
            let high = patches.indices.filter {
                abs(patches[$0].y - rise) < 0.001 && touches(patches[$0].rect, rect, slack: 0.03)
            }
            for l in low { for h in high { link(l, h) } }
        case .teleporter(let a, let b, _, let y):
            if let i = patchIndex(containing: a, y: y, in: level),
               let j = patchIndex(containing: b, y: y, in: level) {
                link(i, j)
            }
        case .launchPad(let c, let dir, let speed, let lift, let y):
            // A jump reaches whatever green is under the landing point, at
            // whichever height that green happens to sit.
            let landing = jumpLanding(c, dir, speed: speed, lift: lift)
            if let i = patchIndex(containing: c, y: y, in: level) {
                for j in patches.indices where patches[j].rect.contains(landing, margin: 0.1) {
                    link(i, j)
                }
            }
        case .cannon(let c, let dir, _, let y):
            let unit = simd_length(dir) > 0 ? simd_normalize(dir) : SIMD2(0, -1)
            if let i = patchIndex(containing: c, y: y, in: level),
               let j = patchIndex(containing: c + unit * 0.26, y: y, in: level) {
                link(i, j)
            }
        default:
            break
        }
    }

    guard let start = patchIndex(containing: level.tee, y: 0, in: level) else { return }
    var seen: Set<Int> = [start]
    var queue = [start]
    while let node = queue.popLast() {
        for next in links[node] where !seen.contains(next) {
            seen.insert(next)
            queue.append(next)
        }
    }

    if let target = patchIndex(containing: level.hole, y: level.holeY, in: level),
       !seen.contains(target) {
        fail(level, "the cup's green is not connected to the tee")
    }
    for i in patches.indices where !seen.contains(i) {
        warn(level, "green \(fmt(patches[i].rect)) y=\(patches[i].y) cannot be reached from the tee")
    }
    if let star = level.bonusStar,
       let host = patchIndex(containing: star, y: level.bonusStarY, in: level),
       !seen.contains(host) {
        fail(level, "bonus star \(fmt(star)) is on an unreachable green")
    }
}

// MARK: - Fine-grained path check

/// Something solid the rolling ball has to go around, seen from above. Moving
/// parts (gates, sliding blocks, rotors, pendulums) are left out on purpose:
/// they always open up again.
struct Blocker {
    enum Shape {
        case segment(a: SIMD2<Float>, b: SIMD2<Float>, halfThickness: Float)
        case circle(center: SIMD2<Float>, radius: Float)
        case box(center: SIMD2<Float>, half: SIMD2<Float>, yaw: Float)
    }

    var shape: Shape
    var baseY: Float
    var height: Float

    func guards(y: Float) -> Bool {
        baseY <= y + 0.002 && baseY + height > y + 0.02
    }

    /// True when a ball centred on `p` would overlap this obstacle.
    func blocks(_ p: SIMD2<Float>) -> Bool {
        let slack: Float = 0.001
        switch shape {
        case .segment(let a, let b, let half):
            let seg = Seg(a: a, b: b, baseY: 0, height: 0)
            return seg.distance(to: p) < half + ballRadius - slack
        case .circle(let c, let r):
            return simd_distance(p, c) < r + ballRadius - slack
        case .box(let c, let half, let yaw):
            let d = p - c
            let local = SIMD2(d.x * cos(yaw) - d.y * sin(yaw),
                              d.x * sin(yaw) + d.y * cos(yaw))
            return abs(local.x) < half.x + ballRadius - slack &&
                   abs(local.y) < half.y + ballRadius - slack
        }
    }
}

func blockers(of level: LevelDefinition) -> [Blocker] {
    var out: [Blocker] = []
    for w in walls(of: level) {
        out.append(Blocker(shape: .segment(a: w.a, b: w.b, halfThickness: w.thickness / 2),
                           baseY: w.baseY, height: w.height))
    }
    for spec in level.obstacles {
        switch spec {
        case .bumper(let c, let r), .post(let c, let r):
            out.append(Blocker(shape: .circle(center: c, radius: r), baseY: 0, height: 0.09))
        case .block(let c, let size, let yaw, let baseY):
            out.append(Blocker(shape: .box(center: c, half: SIMD2(size.x / 2, size.z / 2),
                                           yaw: yaw),
                               baseY: baseY, height: size.y))
        case .tunnel(let c, let width, let length, let yaw):
            // Two side walls along the local Z axis; the roof clears the ball.
            let along = SIMD2(sin(yaw), cos(yaw))
            let across = SIMD2(cos(yaw), -sin(yaw))
            for side: Float in [-1, 1] {
                let mid = c + across * (side * (width / 2 + 0.025))
                out.append(Blocker(
                    shape: .segment(a: mid - along * (length / 2), b: mid + along * (length / 2),
                                    halfThickness: 0.025),
                    baseY: 0, height: 0.16))
            }
        case .loop(let c, let radius, let width, let yaw, let y):
            // The ring is overhead; only the boards funnelling into it block.
            let along = SIMD2(sin(yaw), cos(yaw))
            let across = SIMD2(cos(yaw), -sin(yaw))
            let half = max(0.06, width / 2) + 0.028
            let length = 2 * radius + 0.12
            for side: Float in [-1, 1] {
                let mid = c + across * (side * half)
                out.append(Blocker(
                    shape: .segment(a: mid - along * (length / 2), b: mid + along * (length / 2),
                                    halfThickness: 0.0275),
                    baseY: y, height: 0.085))
            }
        default:
            break
        }
    }
    return out
}

/// Flood fills the playable surface on a fine grid — walls and static obstacles
/// included — and checks that the ball can actually roll from the tee to the
/// cup and to the bonus star. This catches pockets sealed off *inside* a single
/// floor patch, which the patch-level check above cannot see.
func checkBallPaths(_ level: LevelDefinition) {
    let cell: Float = 0.02
    let solids = blockers(of: level)
    let pads = level.floors.filter { !$0.kind.isHazard }
    guard !pads.isEmpty else { return }

    var layers = [Float]()
    for patch in pads where !layers.contains(where: { abs($0 - patch.y) < 0.001 }) {
        layers.append(patch.y)
    }

    let area = level.bounds
    let nx = max(1, Int(((area.maxX - area.minX) / cell).rounded(.up)) + 1)
    let nz = max(1, Int(((area.maxZ - area.minZ) / cell).rounded(.up)) + 1)
    let perLayer = nx * nz

    func point(_ ix: Int, _ iz: Int) -> SIMD2<Float> {
        SIMD2(area.minX + Float(ix) * cell, area.minZ + Float(iz) * cell)
    }

    // Open cells: the ball's centre fits there without clipping anything.
    var open = [Bool](repeating: false, count: perLayer * layers.count)
    for (l, y) in layers.enumerated() {
        let floorsHere = pads.filter { abs($0.y - y) < 0.001 }
        let solidsHere = solids.filter { $0.guards(y: y) }
        for iz in 0..<nz {
            for ix in 0..<nx {
                let p = point(ix, iz)
                guard floorsHere.contains(where: { $0.rect.contains(p) }) else { continue }
                guard !solidsHere.contains(where: { $0.blocks(p) }) else { continue }
                open[l * perLayer + iz * nx + ix] = true
            }
        }
    }

    var parent = Array(0..<open.count)
    func find(_ i: Int) -> Int {
        var root = i
        while parent[root] != root { root = parent[root] }
        var node = i
        while parent[node] != node { let next = parent[node]; parent[node] = root; node = next }
        return root
    }
    func union(_ i: Int, _ j: Int) {
        let (a, b) = (find(i), find(j))
        if a != b { parent[a] = b }
    }

    for l in layers.indices {
        for iz in 0..<nz {
            for ix in 0..<nx {
                let i = l * perLayer + iz * nx + ix
                guard open[i] else { continue }
                if ix + 1 < nx, open[i + 1] { union(i, i + 1) }
                if iz + 1 < nz, open[i + nx] { union(i, i + nx) }
            }
        }
    }

    /// Open cells whose centre lies within `radius` of `p` on the given layer.
    func cells(near p: SIMD2<Float>, y: Float, radius: Float) -> [Int] {
        guard let l = layers.firstIndex(where: { abs($0 - y) < 0.001 }) else { return [] }
        let span = Int((radius / cell).rounded(.up))
        let cx = Int(((p.x - area.minX) / cell).rounded())
        let cz = Int(((p.y - area.minZ) / cell).rounded())
        var out: [Int] = []
        for iz in max(0, cz - span)...min(nz - 1, cz + span) {
            for ix in max(0, cx - span)...min(nx - 1, cx + span) {
                let i = l * perLayer + iz * nx + ix
                if open[i], simd_distance(point(ix, iz), p) <= radius { out.append(i) }
            }
        }
        return out
    }

    // Ramps and portals stitch the layers together.
    for spec in level.obstacles {
        switch spec {
        case .ramp(let c, let width, let length, let rise, let yaw):
            let along = SIMD2(sin(yaw), cos(yaw))
            let foot = cells(near: c + along * (length / 2 + 0.04), y: 0, radius: width / 2)
            let top = cells(near: c - along * (length / 2 + 0.04), y: rise, radius: width / 2)
            if let anchor = foot.first {
                for i in foot.dropFirst() { union(anchor, i) }
                for i in top { union(anchor, i) }
            }
        case .teleporter(let a, let b, let radius, let y):
            let mouthA = cells(near: a, y: y, radius: radius)
            let mouthB = cells(near: b, y: y, radius: radius)
            if let anchor = mouthA.first {
                for i in mouthA.dropFirst() + mouthB { union(anchor, i) }
            }
        case .launchPad(let c, let dir, let speed, let lift, let y):
            let landing = jumpLanding(c, dir, speed: speed, lift: lift)
            let takeoff = cells(near: c, y: y, radius: 0.07)
            let target = layers.flatMap { cells(near: landing, y: $0, radius: 0.16) }
            if let anchor = takeoff.first {
                for i in takeoff.dropFirst() + target { union(anchor, i) }
            }
        case .cannon(let c, let dir, _, let y):
            let unit = simd_length(dir) > 0 ? simd_normalize(dir) : SIMD2(0, -1)
            let mouth = cells(near: c, y: y, radius: 0.09)
            let exit = cells(near: c + unit * 0.26, y: y, radius: 0.07)
            if let anchor = mouth.first {
                for i in mouth.dropFirst() + exit { union(anchor, i) }
            }
        default:
            break
        }
    }

    // Where the ball starts.
    var start: Int?
    var probe: Float = cell
    while start == nil, probe <= 0.25 {
        start = cells(near: level.tee, y: 0, radius: probe).first
        probe += cell
    }
    guard let origin = start else {
        fail(level, "the ball does not fit anywhere near the tee \(fmt(level.tee))")
        return
    }
    let reachable = find(origin)

    func check(_ target: SIMD2<Float>, y: Float, radius: Float, what: String) {
        let spots = cells(near: target, y: y, radius: radius)
        if spots.isEmpty {
            fail(level, "\(what) \(fmt(target)) has no room for the ball around it")
        } else if !spots.contains(where: { find($0) == reachable }) {
            fail(level, "\(what) \(fmt(target)) is walled off from the tee")
        }
    }

    // Capture radius of the cup and pickup radius of the star (see the scene
    // coordinator): the ball's centre has to get at least that close.
    check(level.hole, y: level.holeY, radius: 0.05, what: "cup")
    if let star = level.bonusStar {
        check(star, y: level.bonusStarY, radius: 0.078, what: "bonus star")
    }
}

// MARK: - Formatting

func fmt(_ p: SIMD2<Float>) -> String {
    "(\(String(format: "%.2f", p.x)), \(String(format: "%.2f", p.y)))"
}

func fmt(_ r: GroundRect) -> String {
    "[\(String(format: "%.2f", r.minX))…\(String(format: "%.2f", r.maxX)) × " +
    "\(String(format: "%.2f", r.minZ))…\(String(format: "%.2f", r.maxZ))]"
}

// MARK: - Run

@main
struct Validate {
    static func main() {
        print("Minigolf level check — \(LevelLibrary.totalHoles) holes, " +
              "par \(LevelLibrary.totalPar), \(LevelLibrary.totalBonusStars) bonus stars\n")

        for course in CourseType.allCases {
            let holes = LevelLibrary.levels(for: course)
            print("\(course.rawValue): \(holes.count) holes, par \(LevelLibrary.coursePar(course)), " +
                  "stars \(LevelLibrary.bonusStarCount(course))")

            for (index, level) in holes.enumerated() {
                if level.number != index + 1 {
                    fail(level, "hole number \(level.number) does not match its position \(index + 1)")
                }
                if level.course != course {
                    fail(level, "hole is filed under the wrong course")
                }
                checkPlacement(level)
                checkEnclosure(level)
                checkReachability(level)
                checkBallPaths(level)
            }
        }

        print("\n\(problems) problem(s), \(warnings) warning(s)")
        exit(problems == 0 ? 0 : 1)
    }
}
