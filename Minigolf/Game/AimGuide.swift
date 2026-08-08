//
//  AimGuide.swift
//  Minigolf
//
//  Predicts where a putt will go, purely from the level's static geometry.
//  Only fixed blockers are considered — boards, blocks, posts, bumpers and
//  tunnel walls. Windmills, gates, rotors, pendulums and the critters wandering
//  the felt all move, and a guide that claimed to know where they will be would
//  be lying, so timing puzzles keep their teeth.
//

import Foundation
import simd

struct AimGuideGeometry {

    /// A board the ball bounces off, stored as a centre line plus half its
    /// thickness — the same way `SceneBuilder` places the collider.
    struct Board {
        var a: SIMD2<Float>
        var b: SIMD2<Float>
        var halfThickness: Float
        var baseY: Float
        var height: Float
    }

    struct Pillar {
        var center: SIMD2<Float>
        var radius: Float
        var baseY: Float
        var height: Float
        /// Bumpers kick the ball away far harder than a post does, so the line
        /// has to leave them with the same energy the real thing would.
        var restitution: Float = GamePhysics.wallBounce
    }

    var boards: [Board] = []
    var pillars: [Pillar] = []

    /// Collects every static blocker of a hole. Built once per scene.
    static func build(level: LevelDefinition) -> AimGuideGeometry {
        var geometry = AimGuideGeometry()
        let defaultWall = WallSegment(from: .zero, to: .zero)

        for loop in level.wallLoops where loop.count > 1 {
            for i in loop.indices {
                geometry.boards.append(Board(
                    a: loop[i], b: loop[(i + 1) % loop.count],
                    halfThickness: defaultWall.thickness / 2,
                    baseY: defaultWall.baseY, height: defaultWall.height))
            }
        }
        for segment in level.extraWalls {
            geometry.boards.append(Board(
                a: segment.from, b: segment.to,
                halfThickness: segment.thickness / 2,
                baseY: segment.baseY, height: segment.height))
        }

        for spec in level.obstacles {
            switch spec {
            case .bumper(let center, let radius):
                geometry.pillars.append(Pillar(center: center, radius: radius,
                                               baseY: 0, height: 0.12,
                                               restitution: GamePhysics.bumperBounce))
            case .post(let center, let radius):
                geometry.pillars.append(Pillar(center: center, radius: radius,
                                               baseY: 0, height: 0.12))
            case .block(let center, let size, let yaw, let baseY):
                geometry.boards.append(contentsOf: boxBoards(
                    center: center, sizeX: size.x, sizeZ: size.z, yaw: yaw,
                    baseY: baseY, height: size.y))
            case .tunnel(let center, let width, let length, let yaw):
                // Two side walls running along the tunnel's local Z axis.
                let alongZ = SIMD2(sin(yaw), cos(yaw))
                let alongX = SIMD2(cos(yaw), -sin(yaw))
                for side: Float in [-1, 1] {
                    let mid = center + alongX * (side * (width / 2 + 0.025))
                    geometry.boards.append(Board(
                        a: mid - alongZ * (length / 2), b: mid + alongZ * (length / 2),
                        halfThickness: 0.025, baseY: 0, height: 0.16))
                }
            case .loop(let center, let radius, let width, let yaw, let y):
                // The track itself is not in the way — the ball is carried
                // around it and set down again on the same line — but the two
                // boards that funnel the putt into the entrance very much are.
                let alongZ = SIMD2(sin(yaw), cos(yaw))
                let alongX = SIMD2(cos(yaw), -sin(yaw))
                let half = max(0.06, width / 2) + 0.028
                let length = LoopShape.pitch(radius: radius) + 0.32
                for side: Float in [-1, 1] {
                    let mid = center + alongX * (side * half)
                    geometry.boards.append(Board(
                        a: mid - alongZ * (length / 2), b: mid + alongZ * (length / 2),
                        halfThickness: 0.0275, baseY: y, height: 0.085))
                }
            case .windmill, .rotor, .movingBlock, .gate, .pendulum, .critter,
                 .bump, .ramp, .slope, .conveyor, .teleporter, .boostPad,
                 .launchPad, .cannon, .turntable, .magnet, .fan:
                continue
            }
        }
        return geometry
    }

    /// The four sides of a yaw-rotated box, as boards with no extra thickness
    /// (the corners are already the outer face).
    private static func boxBoards(center: SIMD2<Float>, sizeX: Float, sizeZ: Float,
                                  yaw: Float, baseY: Float, height: Float) -> [Board] {
        let axisX = SIMD2(cos(yaw), -sin(yaw)) * (sizeX / 2)
        let axisZ = SIMD2(sin(yaw), cos(yaw)) * (sizeZ / 2)
        let corners = [
            center - axisX - axisZ, center + axisX - axisZ,
            center + axisX + axisZ, center - axisX + axisZ,
        ]
        return corners.indices.map { i in
            Board(a: corners[i], b: corners[(i + 1) % corners.count],
                  halfThickness: 0, baseY: baseY, height: height)
        }
    }
}

/// A predicted putt: the corner points of the path plus whether it drops.
struct AimGuidePath {
    var points: [SIMD2<Float>] = []
    var endsInHole = false

    var totalLength: Float {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).reduce(0) { $0 + simd_distance($1.0, $1.1) }
    }

    /// Walks the polyline and returns the point `distance` along it.
    func point(at distance: Float) -> SIMD2<Float>? {
        guard var previous = points.first else { return nil }
        var walked: Float = 0
        for next in points.dropFirst() {
            let leg = simd_distance(previous, next)
            if walked + leg >= distance, leg > 0.0001 {
                let t = (distance - walked) / leg
                return simd_mix(previous, next, SIMD2(repeating: t))
            }
            walked += leg
            previous = next
        }
        return points.last
    }
}

enum AimGuideTracer {

    /// Casts a putt through the static geometry, reflecting off boards with the
    /// same restitution the coordinator applies to a real bounce, so the line
    /// flattens against the boards exactly like the ball does.
    static func trace(geometry: AimGuideGeometry,
                      from origin: SIMD2<Float>,
                      direction: SIMD2<Float>,
                      length: Float,
                      ballY: Float,
                      hole: SIMD2<Float>,
                      holeRadius: Float,
                      maxBounces: Int) -> AimGuidePath {

        var path = AimGuidePath(points: [origin])
        guard simd_length(direction) > 0.0001, length > 0.01 else { return path }

        let boards = geometry.boards.filter { reaches(baseY: $0.baseY, height: $0.height, ballY: ballY) }
        let pillars = geometry.pillars.filter { reaches(baseY: $0.baseY, height: $0.height, ballY: ballY) }

        var point = origin
        var heading = simd_normalize(direction)
        var remaining = length

        for bounce in 0...maxBounces {
            let nearest = firstHit(from: point, direction: heading, limit: remaining,
                                   boards: boards, pillars: pillars)
            let legLength = nearest?.distance ?? remaining
            let legEnd = point + heading * legLength

            // A leg that brushes the cup ends there — the strongest bit of
            // feedback the guide can give.
            if let drop = holeCrossing(from: point, to: legEnd, hole: hole, radius: holeRadius) {
                path.points.append(drop)
                path.endsInHole = true
                return path
            }

            path.points.append(legEnd)
            guard let hit = nearest, bounce < maxBounces else { return path }

            remaining = (remaining - legLength) * 0.8   // a bounce costs speed
            guard remaining > 0.06 else { return path }

            heading = reflect(heading, normal: hit.normal, restitution: hit.restitution)
            point = legEnd
        }
        return path
    }

    /// A blocker only matters when it stands on the ball's own level.
    private static func reaches(baseY: Float, height: Float, ballY: Float) -> Bool {
        height > 0.02 && abs(ballY - baseY) < 0.25
    }

    private struct Hit {
        var distance: Float
        var normal: SIMD2<Float>
        var restitution: Float
    }

    private static func firstHit(from origin: SIMD2<Float>, direction: SIMD2<Float>,
                                 limit: Float,
                                 boards: [AimGuideGeometry.Board],
                                 pillars: [AimGuideGeometry.Pillar]) -> Hit? {
        var best: Hit?
        for board in boards {
            guard let hit = intersect(origin: origin, direction: direction, board: board),
                  hit.distance <= limit, hit.distance < (best?.distance ?? .greatestFiniteMagnitude)
            else { continue }
            best = hit
        }
        for pillar in pillars {
            guard let hit = intersect(origin: origin, direction: direction, pillar: pillar),
                  hit.distance <= limit, hit.distance < (best?.distance ?? .greatestFiniteMagnitude)
            else { continue }
            best = hit
        }
        return best
    }

    /// Ray against a board, inflated by the ball's radius so the line stops
    /// where the ball's surface would touch rather than where its centre would.
    private static func intersect(origin: SIMD2<Float>, direction: SIMD2<Float>,
                                  board: AimGuideGeometry.Board) -> Hit? {
        let edge = board.b - board.a
        let edgeLength = simd_length(edge)
        guard edgeLength > 0.0001 else { return nil }
        let along = edge / edgeLength

        var normal = SIMD2(-along.y, along.x)
        if simd_dot(normal, origin - board.a) < 0 { normal = -normal }
        guard simd_dot(direction, normal) < -0.0001 else { return nil }

        // Push the face out toward the ball and round the ends off, so a putt
        // aimed at a corner is stopped instead of slipping past it.
        let offset = board.halfThickness + GamePhysics.ballRadius
        let a = board.a + normal * offset - along * offset
        let b = board.b + normal * offset + along * offset

        let s = b - a
        let denominator = cross(direction, s)
        guard abs(denominator) > 1e-7 else { return nil }
        let toStart = a - origin
        let t = cross(toStart, s) / denominator
        let u = cross(toStart, direction) / denominator
        guard t > 0.0005, u >= 0, u <= 1 else { return nil }
        return Hit(distance: t, normal: normal, restitution: GamePhysics.wallBounce)
    }

    private static func intersect(origin: SIMD2<Float>, direction: SIMD2<Float>,
                                  pillar: AimGuideGeometry.Pillar) -> Hit? {
        let radius = pillar.radius + GamePhysics.ballRadius
        let toCenter = origin - pillar.center
        let b = simd_dot(toCenter, direction)
        let c = simd_dot(toCenter, toCenter) - radius * radius
        let discriminant = b * b - c
        guard discriminant > 0 else { return nil }
        let t = -b - sqrt(discriminant)
        guard t > 0.0005 else { return nil }
        let contact = origin + direction * t
        let normal = contact - pillar.center
        guard simd_length(normal) > 0.0001 else { return nil }
        return Hit(distance: t, normal: simd_normalize(normal),
                   restitution: pillar.restitution)
    }

    /// Mirrors the tangential component and damps the normal one by the same
    /// restitution the coordinator applies to a real bounce off that blocker.
    private static func reflect(_ direction: SIMD2<Float>, normal: SIMD2<Float>,
                                restitution: Float) -> SIMD2<Float> {
        let normalPart = normal * simd_dot(direction, normal)
        let bounced = (direction - normalPart) - normalPart * restitution
        guard simd_length(bounced) > 0.0001 else { return normal }
        return simd_normalize(bounced)
    }

    /// Where a straight leg first comes within `radius` of the cup, if it does.
    private static func holeCrossing(from: SIMD2<Float>, to: SIMD2<Float>,
                                     hole: SIMD2<Float>, radius: Float) -> SIMD2<Float>? {
        let leg = to - from
        let legLength = simd_length(leg)
        guard legLength > 0.0001 else { return nil }
        let along = leg / legLength
        let projected = simd_clamp(simd_dot(hole - from, along), 0, legLength)
        let closest = from + along * projected
        guard simd_distance(closest, hole) < radius else { return nil }
        return closest
    }

    private static func cross(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        a.x * b.y - a.y * b.x
    }
}
