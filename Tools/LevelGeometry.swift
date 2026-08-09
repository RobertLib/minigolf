//
//  LevelGeometry.swift
//  Minigolf tools
//
//  The geometry the offline tools share: what the ball can touch, and how far it
//  has to roll to get anywhere. `validate_levels` uses it to prove a hole is
//  playable and `map_levels` to measure how long it plays, and both only agree
//  about a hole because they read it off the same code.
//
//  Compiled into each tool alongside the level data — see the build lines in
//  those files.
//

import Foundation
import simd

/// Radius of the ball, in metres. Everything solid is grown by it, so a cell
/// the ball's centre can sit in is a cell the ball fits in.
let ballRadius: Float = 0.034

// MARK: - Walls

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

// MARK: - Obstacle introspection

/// Everywhere a critter's rounds take it: the cup, the tee and the floor all
/// have to be judged against the whole path, not just where it starts.
func critterPoints(_ center: SIMD2<Float>, _ motion: CritterMotion) -> [SIMD2<Float>] {
    switch motion {
    case .patrol(let axis, let amplitude), .hop(let axis, let amplitude, _):
        let unit = simd_length(axis) > 0 ? simd_normalize(axis) : SIMD2(1, 0)
        return [center, center + unit * amplitude, center - unit * amplitude]
    case .circle(let radius):
        return [center, center + SIMD2(radius, 0), center - SIMD2(radius, 0),
                center + SIMD2(0, radius), center - SIMD2(0, radius)]
    case .burrow:
        return [center]
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
         .magnet(_, _, _, let y), .fan(_, _, _, _, _, let y),
         .critter(_, _, _, _, _, let y):
        return y
    default:
        return 0
    }
}

// MARK: - Static blockers

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


// MARK: - How far a hole plays

/// The shortest roll from the tee to the cup, in metres, measured through the
/// felt the ball can really use: round every board, post and block, up every
/// ramp and through every portal, kicker and barrel.
///
/// This — not the size of the plot — is what par is a function of. A labyrinth
/// covers two square metres and takes four putts to cross, while an open pan
/// twice its area goes in one, so travel is the only honest way to line two
/// holes of different shapes up against each other.
///
/// Returns nil if the cup cannot be reached; the level checker reports that
/// case in its own words.
func travelDistance(of level: LevelDefinition, cell: Float = 0.03) -> Float? {
    let pads = level.floors.filter { !$0.kind.isHazard }
    guard !pads.isEmpty else { return nil }

    var layers: [Float] = []
    for patch in pads where !layers.contains(where: { abs($0 - patch.y) < 0.001 }) {
        layers.append(patch.y)
    }

    let area = level.bounds
    let nx = max(1, Int((area.size.x / cell).rounded(.up)) + 1)
    let nz = max(1, Int((area.size.y / cell).rounded(.up)) + 1)
    let perLayer = nx * nz
    let gridCount = perLayer * layers.count

    func point(_ ix: Int, _ iz: Int) -> SIMD2<Float> {
        SIMD2(area.minX + Float(ix) * cell, area.minZ + Float(iz) * cell)
    }

    // Cells the ball's centre fits in.
    let solids = blockers(of: level)
    var open = [Bool](repeating: false, count: gridCount)
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

    // Everything that carries the ball somewhere instead of letting it roll gets
    // a pair of nodes off the grid: every mouth cell joins its node for nothing,
    // and the two nodes are joined by whatever the trip costs.
    var extra: [[(Int, Float)]] = []

    /// A mouth cell joins its node for what it costs to roll to the middle of
    /// the mouth — nought would let the path jump the width of the mouth for
    /// free, which on a ramp hole is most of a putt.
    func cellPoint(_ index: Int) -> SIMD2<Float> {
        let rest = index % perLayer
        return point(rest % nx, rest / nx)
    }
    func link(_ from: [Int], at fromCentre: SIMD2<Float>,
              _ to: [Int], at toCentre: SIMD2<Float>,
              cost: Float, into edges: inout [[(Int, Float)]]) {
        guard !from.isEmpty, !to.isEmpty else { return }
        let a = gridCount + extra.count
        let b = a + 1
        extra.append([])
        extra.append([])
        for cellIndex in from {
            let reach = simd_distance(cellPoint(cellIndex), fromCentre)
            edges[cellIndex].append((a, reach))
            extra[a - gridCount].append((cellIndex, reach))
        }
        for cellIndex in to {
            let reach = simd_distance(cellPoint(cellIndex), toCentre)
            edges[cellIndex].append((b, reach))
            extra[b - gridCount].append((cellIndex, reach))
        }
        extra[a - gridCount].append((b, cost))
        extra[b - gridCount].append((a, cost))
    }

    var edges = [[(Int, Float)]](repeating: [], count: gridCount)
    for spec in level.obstacles {
        switch spec {
        case .ramp(let c, let width, let length, let rise, let yaw):
            let along = SIMD2<Float>(sin(yaw), cos(yaw))
            let foot = c + along * (length / 2 + 0.04)
            let top = c - along * (length / 2 + 0.04)
            link(cells(near: foot, y: 0, radius: width / 2), at: foot,
                 cells(near: top, y: rise, radius: width / 2), at: top,
                 cost: length, into: &edges)
        case .teleporter(let a, let b, let radius, let y):
            link(cells(near: a, y: y, radius: radius), at: a,
                 cells(near: b, y: y, radius: radius), at: b,
                 cost: 0, into: &edges)
        case .launchPad(let c, let dir, let speed, let lift, let y):
            let landing = jumpLanding(c, dir, speed: speed, lift: lift)
            link(cells(near: c, y: y, radius: 0.07), at: c,
                 layers.flatMap { cells(near: landing, y: $0, radius: 0.16) }, at: landing,
                 cost: simd_distance(landing, c), into: &edges)
        case .cannon(let c, let dir, _, let y):
            let unit = simd_length(dir) > 0 ? simd_normalize(dir) : SIMD2<Float>(0, -1)
            link(cells(near: c, y: y, radius: 0.09), at: c,
                 cells(near: c + unit * 0.26, y: y, radius: 0.07), at: c + unit * 0.26,
                 cost: 0.26, into: &edges)
        default:
            break
        }
    }

    // Dijkstra over the grid plus those nodes.
    let total = gridCount + extra.count
    var dist = [Float](repeating: .infinity, count: total)
    var heap: [(Float, Int)] = []

    func push(_ d: Float, _ node: Int) {
        heap.append((d, node))
        var i = heap.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard heap[parent].0 > heap[i].0 else { break }
            heap.swapAt(parent, i)
            i = parent
        }
    }
    func pop() -> (Float, Int)? {
        guard let first = heap.first else { return nil }
        heap[0] = heap[heap.count - 1]
        heap.removeLast()
        var i = 0
        while true {
            let l = 2 * i + 1, r = l + 1
            var best = i
            if l < heap.count, heap[l].0 < heap[best].0 { best = l }
            if r < heap.count, heap[r].0 < heap[best].0 { best = r }
            if best == i { break }
            heap.swapAt(best, i)
            i = best
        }
        return first
    }

    var starts: [Int] = []
    var probe: Float = cell
    while starts.isEmpty, probe <= 0.25 {
        starts = cells(near: level.tee, y: 0, radius: probe)
        probe += cell
    }
    guard !starts.isEmpty else { return nil }
    for s in starts { dist[s] = 0; push(0, s) }

    let straight = cell
    let diagonal = cell * Float(2).squareRoot()
    let targets = Set(cells(near: level.hole, y: level.holeY, radius: 0.05))
    guard !targets.isEmpty else { return nil }

    while let (d, node) = pop() {
        guard d <= dist[node] + 1e-6 else { continue }
        if targets.contains(node) { return d }

        if node >= gridCount {
            for (next, cost) in extra[node - gridCount] where d + cost < dist[next] {
                dist[next] = d + cost
                push(dist[next], next)
            }
            continue
        }

        for (next, cost) in edges[node] where d + cost < dist[next] {
            dist[next] = d + cost
            push(dist[next], next)
        }

        let layer = node / perLayer
        let rest = node % perLayer
        let iz = rest / nx, ix = rest % nx
        for dz in -1...1 {
            for dx in -1...1 where dx != 0 || dz != 0 {
                let jx = ix + dx, jz = iz + dz
                guard jx >= 0, jx < nx, jz >= 0, jz < nz else { continue }
                let next = layer * perLayer + jz * nx + jx
                guard open[next] else { continue }
                // A diagonal step may not cut a corner between two solids.
                if dx != 0, dz != 0 {
                    guard open[layer * perLayer + iz * nx + jx],
                          open[layer * perLayer + jz * nx + ix] else { continue }
                }
                let step = (dx != 0 && dz != 0) ? diagonal : straight
                if d + step < dist[next] {
                    dist[next] = d + step
                    push(dist[next], next)
                }
            }
        }
    }
    return nil
}
