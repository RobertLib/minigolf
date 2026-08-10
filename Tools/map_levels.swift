//
//  map_levels.swift
//  Minigolf tools
//
//  Draws every hole as a top-down ASCII map so the *shape* of the library can be
//  judged at a glance — which holes are plain rectangles, which worlds repeat
//  each other, where the playable area actually is. The level data is plain
//  Foundation + simd, so this compiles for macOS the same way the validator does:
//
//      swiftc -O -o /tmp/maps Tools/map_levels.swift \
//          Tools/LevelGeometry.swift \
//          Minigolf/Support/MathHelpers.swift \
//          Minigolf/Models/CourseType.swift \
//          Minigolf/Models/LevelDefinition.swift \
//          Minigolf/Models/LevelLibrary.swift \
//          Minigolf/Models/Levels/*.swift && /tmp/maps
//
//  Arguments: `/tmp/maps garden` draws one world, `/tmp/maps stats` prints only
//  the shape table.
//

import Foundation
import simd

let cell: Float = 0.05

// MARK: - Symbols

func floorSymbol(_ kind: FloorPatch.Kind) -> Character {
    switch kind {
    case .green: return "."
    case .sand: return ":"
    case .mud: return ","
    case .ice: return "*"
    case .water: return "~"
    case .lava: return "^"
    }
}

func obstacleSymbol(_ spec: ObstacleSpec) -> Character {
    switch spec {
    case .windmill: return "W"
    case .rotor: return "R"
    case .movingBlock: return "M"
    case .bumper: return "O"
    case .post: return "o"
    case .bump: return "n"
    case .ramp: return "/"
    case .block: return "B"
    case .tunnel: return "U"
    case .slope: return ">"
    case .conveyor: return "="
    case .teleporter: return "@"
    case .gate: return "G"
    case .pendulum: return "P"
    case .boostPad: return "!"
    case .loop: return "0"
    case .launchPad: return "J"
    case .cannon: return "C"
    case .turntable: return "Q"
    case .magnet: return "&"
    case .fan: return "F"
    case .critter: return "c"
    }
}

/// Where an obstacle marks the map. Zone-shaped ones fill their rectangle;
/// the rest just stamp their anchor points.
func marks(_ spec: ObstacleSpec) -> [SIMD2<Float>] {
    func fill(_ r: GroundRect) -> [SIMD2<Float>] {
        var out: [SIMD2<Float>] = []
        var z = r.minZ
        while z <= r.maxZ {
            var x = r.minX
            while x <= r.maxX {
                out.append(SIMD2(x, z))
                x += cell
            }
            z += cell
        }
        return out
    }
    func disc(_ c: SIMD2<Float>, _ radius: Float) -> [SIMD2<Float>] {
        fill(GroundRect(x0: c.x - radius, x1: c.x + radius,
                        z0: c.y - radius, z1: c.y + radius))
            .filter { simd_distance($0, c) <= radius }
    }
    func bar(_ c: SIMD2<Float>, _ half: SIMD2<Float>, _ yaw: Float) -> [SIMD2<Float>] {
        let across = SIMD2<Float>(cos(yaw), -sin(yaw))
        let along = SIMD2<Float>(sin(yaw), cos(yaw))
        var out: [SIMD2<Float>] = []
        var u = -half.x
        while u <= half.x {
            var v = -half.y
            while v <= half.y {
                out.append(c + across * u + along * v)
                v += cell
            }
            u += cell
        }
        return out
    }

    switch spec {
    case .windmill(let c, _, _): return disc(c, 0.12)
    case .rotor(let c, let l, _, _): return bar(c, SIMD2(l / 2, 0.02), 0)
    case .movingBlock(let c, let axis, let amp, _, let size, _):
        let unit = simd_length(axis) > 0 ? simd_normalize(axis) : SIMD2(1, 0)
        return bar(c, SIMD2(size.x / 2, size.y / 2), 0)
            + bar(c + unit * amp, SIMD2(size.x / 2, size.y / 2), 0)
            + bar(c - unit * amp, SIMD2(size.x / 2, size.y / 2), 0)
    case .bumper(let c, let r), .post(let c, let r): return disc(c, r)
    case .bump(let c, let w, _, let yaw): return bar(c, SIMD2(w / 2, 0.03), yaw)
    case .ramp(let c, let w, let l, _, let yaw): return bar(c, SIMD2(w / 2, l / 2), yaw)
    case .block(let c, let size, let yaw, _): return bar(c, SIMD2(size.x / 2, size.z / 2), yaw)
    case .tunnel(let c, let w, let l, let yaw): return bar(c, SIMD2(w / 2, l / 2), yaw)
    case .slope(let r, _, _, _), .conveyor(let r, _, _, _), .fan(let r, _, _, _, _, _):
        return fill(r)
    case .teleporter(let a, let b, let r, _): return disc(a, r) + disc(b, r)
    case .gate(let c, let size, let yaw, _, _, _): return bar(c, SIMD2(size.x / 2, size.y / 2), yaw)
    case .pendulum(let c, let span, _, _, let yaw, _): return bar(c, SIMD2(span / 2, 0.02), yaw)
    case .boostPad(let c, _, _, _): return disc(c, 0.08)
    case .loop(let c, let radius, let w, let yaw, _):
        return bar(c, SIMD2(w / 2, LoopShape.pitch(radius: radius) / 2 + radius), yaw)
    case .launchPad(let c, _, _, _, _): return disc(c, 0.08)
    case .cannon(let c, _, _, _): return disc(c, 0.09)
    case .turntable(let c, let r, _, _): return disc(c, r)
    case .magnet(let c, let r, _, _): return disc(c, r)
    case .critter(let kind, let c, let motion, _, _, _):
        switch motion {
        case .patrol(let axis, let amp), .hop(let axis, let amp, _):
            let unit = simd_length(axis) > 0 ? simd_normalize(axis) : SIMD2(1, 0)
            return disc(c, kind.radius) + disc(c + unit * amp, kind.radius)
                + disc(c - unit * amp, kind.radius)
        case .circle(let r): return disc(c, r + kind.radius).filter { simd_distance($0, c) >= r - kind.radius }
        case .burrow: return disc(c, kind.radius)
        }
    }
}

// MARK: - Drawing

func drawWalls(_ level: LevelDefinition, into grid: inout [[Character]],
               nx: Int, nz: Int, area: GroundRect) {
    var segments: [(SIMD2<Float>, SIMD2<Float>)] = []
    for loop in level.wallLoops {
        for i in loop.indices {
            segments.append((loop[i], loop[(i + 1) % loop.count]))
        }
    }
    for w in level.extraWalls { segments.append((w.from, w.to)) }

    for (a, b) in segments {
        let length = simd_distance(a, b)
        let steps = max(1, Int((length / (cell * 0.5)).rounded(.up)))
        let horizontal = abs(b.x - a.x) >= abs(b.y - a.y)
        for i in 0...steps {
            let p = a + (b - a) * (Float(i) / Float(steps))
            let ix = Int(((p.x - area.minX) / cell).rounded())
            let iz = Int(((p.y - area.minZ) / cell).rounded())
            guard ix >= 0, ix < nx, iz >= 0, iz < nz else { continue }
            let existing = grid[iz][ix]
            let glyph: Character = horizontal ? "-" : "|"
            grid[iz][ix] = (existing == "-" || existing == "|") && existing != glyph ? "+" : glyph
        }
    }
}

func render(_ level: LevelDefinition) -> String {
    let area = level.bounds.expanded(by: 0.1)
    let nx = max(1, Int((area.size.x / cell).rounded(.up)) + 1)
    let nz = max(1, Int((area.size.y / cell).rounded(.up)) + 1)

    var grid = [[Character]](repeating: [Character](repeating: " ", count: nx), count: nz)

    func stamp(_ p: SIMD2<Float>, _ ch: Character) {
        let ix = Int(((p.x - area.minX) / cell).rounded())
        let iz = Int(((p.y - area.minZ) / cell).rounded())
        guard ix >= 0, ix < nx, iz >= 0, iz < nz else { return }
        grid[iz][ix] = ch
    }

    // Floors, low ones first so overlays and upper terraces win.
    for patch in level.floors.sorted(by: { $0.y < $1.y }) {
        let base = floorSymbol(patch.kind)
        var z = patch.rect.minZ
        while z <= patch.rect.maxZ {
            var x = patch.rect.minX
            while x <= patch.rect.maxX {
                // Raised greens get a digit for their level so terraces read.
                let ch: Character
                if patch.kind == .green && patch.y > 0.001 {
                    let step = min(9, max(1, Int((patch.y / 0.07).rounded())))
                    ch = Character(String(step))
                } else {
                    ch = base
                }
                stamp(SIMD2(x, z), ch)
                x += cell
            }
            z += cell
        }
    }

    drawWalls(level, into: &grid, nx: nx, nz: nz, area: area)

    for spec in level.obstacles {
        let ch = obstacleSymbol(spec)
        for p in marks(spec) { stamp(p, ch) }
    }

    if let star = level.bonusStar { stamp(star, "$") }
    stamp(level.tee, "T")
    stamp(level.hole, "H")

    // -Z is "away", so print the far end first.
    return grid.map { String($0).replacingOccurrences(of: "\\s+$", with: "",
                                                      options: .regularExpression) }
        .joined(separator: "\n")
}

// MARK: - Shape statistics

struct Shape {
    var patches: Int
    var width: Float
    var depth: Float
    var floorArea: Float
    var boundsArea: Float
    var heights: Int
    var turns: Int
    /// Shortest roll from the tee to the cup — the honest measure of how much
    /// hole there is, and the one par has to follow.
    var travel: Float

    /// 1.0 means the playable felt fills its bounding box exactly — a plain
    /// rectangle. Anything below ~0.8 has a real outline.
    var fill: Float { boundsArea > 0 ? floorArea / boundsArea : 0 }
}

func shape(_ level: LevelDefinition) -> Shape {
    // Playable felt only: an overlay is a skin on felt that is already counted,
    // and a hazard is a hole in the hole — counting either would call a ring of
    // green round a pond a solid rectangle.
    let pads = level.floors.filter { !$0.kind.isOverlay && !$0.kind.isHazard }
    // Union area on a coarse grid: patches may overlap. Each hit is worth one
    // whole cell, so the grid has to be cells and not the fence posts between
    // them: sampling the corners would be a row and a column too many, and every
    // one of them charged for a full cell the box does not have. That is a few
    // per cent on a small hole — enough to have reported a bare rectangle as
    // fill 1.03, more felt than the box it is measured against. So the count is
    // ceil, without the +1, and the sample sits at the middle of its own cell.
    let area = level.bounds
    let nx = max(1, Int((area.size.x / cell).rounded(.up)))
    let nz = max(1, Int((area.size.y / cell).rounded(.up)))
    var covered = 0
    var heights = Set<Int>()
    for patch in pads where patch.kind == .green { heights.insert(Int(patch.y * 1000)) }
    for iz in 0..<nz {
        for ix in 0..<nx {
            let p = SIMD2(area.minX + (Float(ix) + 0.5) * cell,
                          area.minZ + (Float(iz) + 0.5) * cell)
            if pads.contains(where: { $0.rect.contains(p) }) { covered += 1 }
        }
    }
    // Turns: how many times the straight line tee -> cup leaves the felt.
    var turns = 0
    let steps = 60
    var wasOff = false
    for i in 0...steps {
        let p = level.tee + (level.hole - level.tee) * (Float(i) / Float(steps))
        let on = level.floors.contains { $0.kind == .green && $0.rect.contains(p) }
        if !on && !wasOff { turns += 1 }
        wasOff = !on
    }
    return Shape(patches: pads.count, width: area.size.x, depth: area.size.y,
                 floorArea: Float(covered) * cell * cell,
                 boundsArea: area.size.x * area.size.y,
                 heights: heights.count, turns: turns,
                 travel: travelDistance(of: level) ?? 0)
}

// MARK: - Run

let wanted = CommandLine.arguments.dropFirst().filter { $0 != "stats" }

func table() {
    print(String(format: "%-11@ %3@ %5@ %6@ %6@ %5@ %5@ %5@ %4@ %5@",
                 "world" as NSString, "no" as NSString, "par" as NSString,
                 "travel" as NSString, "m/par" as NSString, "wide" as NSString,
                 "area" as NSString, "fill" as NSString, "lv" as NSString,
                 "obst" as NSString))
    for course in CourseType.allCases {
        if !wanted.isEmpty && !wanted.contains(course.rawValue) { continue }
        for level in LevelLibrary.levels(for: course) {
            let s = shape(level)
            print(String(format: "%-11@ %3d %5d %6.2f %6.2f %5.2f %5.2f %5.2f %4d %5d   %@",
                         course.rawValue as NSString, level.number, level.par,
                         s.travel, s.travel / Float(level.par),
                         s.width, s.floorArea, s.fill, s.heights,
                         level.obstacles.count, level.name as NSString))
        }
    }
}

@main
struct Maps {
    static func main() {
        if CommandLine.arguments.contains("stats") {
            table()
            return
        }
        for course in CourseType.allCases {
            if !wanted.isEmpty && !wanted.contains(course.rawValue) { continue }
            for level in LevelLibrary.levels(for: course) {
                let s = shape(level)
                print("\n=== \(course.rawValue) \(level.number) — \(level.name) — par \(level.par) " +
                      "— \(String(format: "%.2f×%.2f m, fill %.2f, %d level(s)", s.width, s.depth, s.fill, s.heights))")
                print(render(level))
            }
        }
        print("")
        table()
    }
}
