//
//  validate_levels.swift
//  Minigolf tools
//
//  Offline geometry check for every hole in the library. The level data is
//  plain Foundation + simd, so it can be compiled for macOS and inspected
//  without launching the app:
//
//      swiftc -O -o /tmp/validate Tools/validate_levels.swift \
//          Tools/LevelGeometry.swift \
//          Minigolf/Support/MathHelpers.swift \
//          Minigolf/Models/CourseType.swift \
//          Minigolf/Models/LevelDefinition.swift \
//          Minigolf/Models/LevelLibrary.swift \
//          Minigolf/Models/Levels/*.swift && /tmp/validate
//
//  It reports anything that would make a hole unplayable: a cup inside a wall,
//  a green with an open edge the ball can roll off, floors that are not
//  connected to the tee, obstacles sitting on top of the hole and so on. It also
//  reports furniture stacked on furniture — a trap under a banked green, a skin
//  buried in a speed bump, a post planted in a lava vent — which plays and draws
//  as nonsense without ever making a hole impossible.
//  Finally it flood fills the playable surface cell by cell to prove the ball
//  can really roll from the tee to the cup and to the bonus star — pockets
//  sealed off by boards inside a single green show up there.
//

import Foundation
import simd


// MARK: - Small geometry helpers


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
    case .critter(_, let c, let motion, _, _, _): return critterPoints(c, motion)
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
    case .critter(let kind, let c, let motion, _, _, _):
        // A character has to keep both feet on the felt at every point of its
        // round, so the check runs along the path and out to its own width.
        return critterPoints(c, motion).flatMap { p in
            [p, p + SIMD2(kind.radius, 0), p - SIMD2(kind.radius, 0),
             p + SIMD2(0, kind.radius), p - SIMD2(0, kind.radius)]
        }
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
    case .critter(let kind, _, _, _, _, _): return "critter (\(kind))"
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

// MARK: - Stacked furniture

/// What a thing lays flat on the felt. Every one of these is drawn as a slab a
/// few millimetres thick sitting on the floor, and they are all pitched within a
/// millimetre or two of each other — so two of them over the same felt at the
/// same height fight for the same pixels, whatever else they do to the ball.
enum Lay {
    /// Sand, mud, ice: a damping change painted on a green.
    case skin
    /// Slope, belt, wind: a tinted rect that pushes the ball across it.
    case field
    /// Boost pad, turntable, portal ring: a small deck of its own.
    case pad
}

/// Everything a hole lays flat on its felt, with the height it lies at.
func laid(on level: LevelDefinition) -> [(lay: Lay, name: String, rect: GroundRect, y: Float)] {
    var out: [(Lay, String, GroundRect, Float)] = []
    for patch in level.floors where patch.kind.isOverlay {
        out.append((.skin, "\(patch.kind)", patch.rect, patch.y))
    }
    func square(_ c: SIMD2<Float>, _ reach: Float) -> GroundRect {
        GroundRect(x0: c.x - reach, x1: c.x + reach, z0: c.y - reach, z1: c.y + reach)
    }
    for spec in level.obstacles {
        let y = obstacleY(spec)
        switch spec {
        case .slope(let r, _, _, _), .conveyor(let r, _, _, _), .fan(let r, _, _, _, _, _):
            out.append((.field, obstacleName(spec), r, y))
        case .boostPad(let c, _, _, _):
            out.append((.pad, "boostPad", square(c, 0.095), y))
        case .turntable(let c, let radius, _, _):
            out.append((.pad, "turntable", square(c, radius), y))
        case .teleporter(let a, let b, let radius, _):
            out.append((.pad, "portal A", square(a, radius), y))
            out.append((.pad, "portal B", square(b, radius), y))
        default:
            break
        }
    }
    return out
}

/// Things laid on top of one another, and things standing on nothing.
///
/// A trap and a banked green over the same felt is the case worth spelling out:
/// the two tints are drawn into each other, and what they ask of the ball pulls
/// opposite ways — the arrows say it is being carried while the sand says it is
/// being held, and what really happens is that the bank creeps the ball out of
/// the trap and parks it against the boards. A bank that stops where the sand
/// starts says the same thing about the hole and plays the way it looks.
func checkStacking(_ level: LevelDefinition) {
    let flat = laid(on: level)

    for i in flat.indices {
        for j in flat.indices where j > i {
            let (a, b) = (flat[i], flat[j])
            guard abs(a.y - b.y) < 0.001, strictlyOverlaps(a.rect, b.rect) else { continue }
            let x = min(a.rect.maxX, b.rect.maxX) - max(a.rect.minX, b.rect.minX)
            let z = min(a.rect.maxZ, b.rect.maxZ) - max(a.rect.minZ, b.rect.minZ)
            let shared = String(format: "%.2f", x * z)
            // A pad is small and sits proud of the felt, so it reads as being
            // *on* whatever it is on; the rest are flat tints of equal standing.
            if a.lay == .pad || b.lay == .pad {
                warn(level, "\(a.name) \(fmt(a.rect)) and \(b.name) \(fmt(b.rect)) " +
                            "share \(shared) m² of felt at y = \(a.y)")
            } else {
                fail(level, "\(a.name) \(fmt(a.rect)) and \(b.name) \(fmt(b.rect)) are both " +
                            "laid over \(shared) m² of the same felt at y = \(a.y)")
            }
        }
    }

    // A skin is a flat rect and a bump is a mound: where they meet, the skin is
    // buried in the mound and shows as a rectangle bitten off at the foot.
    for spec in level.obstacles {
        guard case .bump(let c, let width, let height, let yaw) = spec else { continue }
        let mound = bumpFootprint(center: c, width: width, height: height, yaw: yaw)
        for patch in level.floors where patch.kind.isOverlay && abs(patch.y) < 0.001 {
            let steps = 12
            var inside = 0
            for iz in 0...steps {
                for ix in 0...steps {
                    let p = SIMD2(patch.rect.minX + patch.rect.size.x * Float(ix) / Float(steps),
                                  patch.rect.minZ + patch.rect.size.y * Float(iz) / Float(steps))
                    if boxContains(p, center: mound.center, half: mound.half, yaw: mound.yaw) {
                        inside += 1
                    }
                }
            }
            if inside > 0 {
                let share = Float(inside) / Float((steps + 1) * (steps + 1))
                fail(level, "\(patch.kind) patch \(fmt(patch.rect)) runs " +
                            "\(String(format: "%.0f", share * 100))% into the mound of the " +
                            "bump at \(fmt(c))")
            }
        }
    }

    // A board along the edge of a trap is its kerb; a board through the middle
    // of one cuts it in two and leaves half of it somewhere else.
    for w in walls(of: level) {
        for patch in level.floors where patch.kind.isOverlay && abs(patch.y - w.baseY) < 0.001 {
            let steps = max(4, Int((simd_distance(w.a, w.b) / 0.02).rounded(.up)))
            var deepest: Float = 0
            for i in 0...steps {
                let p = w.a + (w.b - w.a) * (Float(i) / Float(steps))
                guard patch.rect.contains(p) else { continue }
                let r = patch.rect
                deepest = max(deepest, min(min(p.x - r.minX, r.maxX - p.x),
                                           min(p.y - r.minZ, r.maxZ - p.y)))
            }
            if deepest > 0.06 {
                fail(level, "board (\(fmt(w.a))–\(fmt(w.b))) cuts " +
                            "\(String(format: "%.2f", deepest)) m into the \(patch.kind) patch " +
                            "\(fmt(patch.rect))")
            }
        }
    }

    // Something planted in a hazard has no floor under it, and the ball is
    // already on its way down by the time it could touch the thing.
    for spec in level.obstacles {
        var foot: SIMD2<Float>?
        switch spec {
        case .post(let c, _), .bumper(let c, _), .windmill(let c, _, _),
             .block(let c, _, _, 0), .tunnel(let c, _, _, _):
            foot = c
        default:
            break
        }
        guard let c = foot else { continue }
        let standing = greens(level).contains { abs($0.y) < 0.001 && $0.rect.contains(c) }
        let sinking = level.floors.contains {
            $0.kind.isHazard && abs($0.y) < 0.001 && $0.rect.contains(c)
        }
        if sinking && !standing {
            fail(level, "\(obstacleName(spec)) at \(fmt(c)) stands in a hazard with no floor under it")
        }
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
            guard rampIsClear(center: c, width: width, length: length, rise: rise,
                              yaw: yaw, through: solids) else {
                fail(level, "ramp \(fmt(c)) is walled off — nothing can climb it")
                continue
            }
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
                checkStacking(level)
                checkEnclosure(level)
                checkReachability(level)
                checkBallPaths(level)
            }
        }

        print("\n\(problems) problem(s), \(warnings) warning(s)")
        exit(problems == 0 ? 0 : 1)
    }
}
