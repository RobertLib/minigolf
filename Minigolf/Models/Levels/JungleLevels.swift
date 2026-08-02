//
//  JungleLevels.swift
//  Minigolf
//
//  Jungle Temple — the world that introduces mud, swinging vines, flowing
//  rivers and the ancient portals that stitch the course together.
//

import Foundation
import simd

enum JungleCourse {

    static let holes: [LevelDefinition] = [
        // 1 — an easy walk up to the temple.
        LevelDefinition(
            course: .jungle, number: 1, name: String(localized: "Temple Steps"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.4),
            floors: [floorRect(-0.45, 0.45, -2.8, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -2.8, 0.5)],
            obstacles: [.post(center: SIMD2(-0.15, -1.4), radius: 0.04)],
            bonusStar: SIMD2(0.32, -2.6)
        ),
        // 2 — mud on both flanks: only the middle strip is quick.
        LevelDefinition(
            course: .jungle, number: 2, name: String(localized: "Muddy Banks"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [
                floorRect(-0.55, 0.55, -3.3, 0.5),
                floorRect(-0.55, -0.15, -2.2, -1.2, kind: .mud),
                floorRect(0.15, 0.55, -1.7, -0.9, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.3, 0.5)],
            obstacles: [
                .post(center: SIMD2(-0.18, -2.5), radius: 0.04),
                .post(center: SIMD2(0.2, -2.6), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.4, -1.7)
        ),
        // 3 — a vine sweeps the lane.
        LevelDefinition(
            course: .jungle, number: 3, name: String(localized: "Swinging Vines"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.95),
            floors: [floorRect(-0.5, 0.5, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            obstacles: [
                .pendulum(center: SIMD2(0, -1.8), span: 0.34, arc: 0.5, speed: 2.0,
                          yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(0.36, -3.2)
        ),
        // 4 — a wall with no way round it, and a portal in front.
        LevelDefinition(
            course: .jungle, number: 4, name: String(localized: "Ancient Portal"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.2),
            floors: [floorRect(-0.5, 0.5, -3.6, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.6, 0.5)],
            extraWalls: [wall(-0.5, -1.8, 0.5, -1.8)],
            obstacles: [
                .teleporter(a: SIMD2(0, -1.35), b: SIMD2(0, -2.35), radius: 0.11, y: 0),
                .post(center: SIMD2(0.22, -2.8), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.36, -1.55),
            cameraZoom: 1.15
        ),
        // 5 — the current sweeps everything downstream.
        LevelDefinition(
            course: .jungle, number: 5, name: String(localized: "Jungle River"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.2, -3.05),
            floors: [floorRect(-0.6, 0.6, -3.6, 0.5)],
            wallLoops: [rectLoop(-0.6, 0.6, -3.6, 0.5)],
            obstacles: [
                .conveyor(rect: zone(-0.6, 0.6, -2.1, -1.5), direction: SIMD2(1, 0),
                          strength: 1.2, y: 0),
                .post(center: SIMD2(0.2, -2.7), radius: 0.04),
            ],
            bonusStar: SIMD2(0.45, -2.7),
            cameraZoom: 1.2
        ),
        // 6 — mud first, then thread the ruined arch.
        LevelDefinition(
            course: .jungle, number: 6, name: String(localized: "Ruined Arch"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.4),
            floors: [
                floorRect(-0.5, 0.5, -3.8, 0.5),
                floorRect(-0.5, -0.1, -1.5, -1.0, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.8, 0.5)],
            obstacles: [
                .tunnel(center: SIMD2(0, -2.2), width: 0.28, length: 0.9, yaw: 0),
                .block(center: SIMD2(-0.33, -2.2), size: SIMD3(0.34, 0.16, 0.9),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.33, -2.2), size: SIMD3(0.34, 0.16, 0.9),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(0.36, -3.6),
            cameraZoom: 1.2
        ),
        // 7 — cross the water, then beat the guardian vine.
        LevelDefinition(
            course: .jungle, number: 7, name: String(localized: "Vine Bridge"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.55),
            floors: [
                floorRect(-0.6, 0.6, -1.3, 0.5),
                floorRect(-0.6, -0.16, -2.4, -1.3, kind: .water),
                floorRect(-0.16, 0.16, -2.4, -1.3),
                floorRect(0.16, 0.6, -2.4, -1.3, kind: .water),
                floorRect(-0.6, 0.6, -3.8, -2.4),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -3.8, 0.5)],
            obstacles: [
                .pendulum(center: SIMD2(0, -3.0), span: 0.34, arc: 0.5, speed: 1.7,
                          yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.45, -2.7),
            cameraZoom: 1.3
        ),
        // 8 — two portals behind an unbroken wall: one to the cup, one to the
        //     hidden treasure pocket.
        LevelDefinition(
            course: .jungle, number: 8, name: String(localized: "Twin Portals"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.42, -3.25),
            floors: [floorRect(-0.7, 0.7, -3.6, 0.5)],
            wallLoops: [rectLoop(-0.7, 0.7, -3.6, 0.5)],
            extraWalls: [wall(-0.7, -2.2, 0.7, -2.2)],
            obstacles: [
                .teleporter(a: SIMD2(-0.38, -1.72), b: SIMD2(-0.42, -2.55), radius: 0.1, y: 0),
                .teleporter(a: SIMD2(0.38, -1.72), b: SIMD2(0.45, -2.55), radius: 0.1, y: 0),
                .block(center: SIMD2(0.06, -3.18), size: SIMD3(0.09, 0.1, 0.85),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(0.45, -3.35),
            cameraZoom: 1.3
        ),
        // 9 — climb to the terrace where the water runs sideways.
        LevelDefinition(
            course: .jungle, number: 9, name: String(localized: "Cascade"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.28, -3.75), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -1.8, 0.5),
                floorRect(-0.5, 0.5, -4.0, -2.5, y: 0.13),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -1.8),
                wall(0.5, -1.8, 0.5, -4.0, height: 0.26),
                wall(0.5, -4.0, -0.5, -4.0, height: 0.26),
                wall(-0.5, -4.0, -0.5, -1.8, height: 0.26),
                wall(-0.5, -1.8, -0.5, 0.5),
            ],
            obstacles: [
                .ramp(center: SIMD2(0, -2.15), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                .conveyor(rect: zone(-0.5, 0.5, -3.3, -2.9), direction: SIMD2(1, 0),
                          strength: 1.6, y: 0.13),
            ],
            bonusStar: SIMD2(0.36, -3.9), bonusStarY: 0.13,
            cameraZoom: 1.3
        ),
        // 10 — rotor, vine and a mud bank guarding the cup.
        LevelDefinition(
            course: .jungle, number: 10, name: String(localized: "Temple Guardian"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.35, -3.95),
            floors: [
                floorRect(-0.8, 0.8, -4.2, 0.5),
                floorRect(-0.8, 0.2, -3.6, -3.2, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.8, 0.8, -4.2, 0.5)],
            obstacles: [
                .rotor(center: SIMD2(0, -1.6), length: 0.9, speed: 1.4, baseY: 0),
                .pendulum(center: SIMD2(0, -2.9), span: 0.4, arc: 0.5, speed: 1.8,
                          yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.6, -3.4),
            cameraZoom: 1.4
        ),
        // 11 — the river cannot be crossed; the portal can.
        LevelDefinition(
            course: .jungle, number: 11, name: String(localized: "Portal Rapids"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.35, -3.5),
            floors: [
                floorRect(-0.7, 0.7, -1.2, 0.5),
                floorRect(-0.7, 0.7, -2.0, -1.2, kind: .water),
                floorRect(-0.7, 0.7, -3.8, -2.0),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -3.8, 0.5)],
            obstacles: [
                .teleporter(a: SIMD2(0, -0.8), b: SIMD2(0, -2.35), radius: 0.11, y: 0),
                .conveyor(rect: zone(-0.7, 0.7, -3.0, -2.6), direction: SIMD2(1, 0),
                          strength: 1.6, y: 0),
            ],
            bonusStar: SIMD2(0.55, -3.6),
            cameraZoom: 1.3
        ),
        // 12 — the lost city: court, guardian vine and the raised sanctum.
        LevelDefinition(
            course: .jungle, number: 12, name: String(localized: "Lost City"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.6), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -1.6, 0.5),
                floorRect(-1.2, 1.2, -3.2, -1.6),
                floorRect(-1.2, -0.5, -2.6, -2.0, kind: .mud),
                floorRect(-0.45, 0.45, -4.9, -3.7, y: 0.13),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -1.6),
                wall(0.5, -1.6, 1.2, -1.6),
                wall(1.2, -1.6, 1.2, -3.2),
                wall(1.2, -3.2, 0.45, -3.2),
                wall(0.45, -3.2, 0.45, -4.9, height: 0.26),
                wall(0.45, -4.9, -0.45, -4.9, height: 0.26),
                wall(-0.45, -4.9, -0.45, -3.2, height: 0.26),
                wall(-0.45, -3.2, -1.2, -3.2),
                wall(-1.2, -3.2, -1.2, -1.6),
                wall(-1.2, -1.6, -0.5, -1.6),
                wall(-0.5, -1.6, -0.5, 0.5),
            ],
            obstacles: [
                .pendulum(center: SIMD2(0, -2.35), span: 0.8, arc: 0.6, speed: 1.7,
                          yaw: 0, baseY: 0),
                .ramp(center: SIMD2(0, -3.45), width: 0.9, length: 0.5, rise: 0.13, yaw: 0),
                .movingBlock(center: SIMD2(0, -4.3), axis: SIMD2(1, 0), amplitude: 0.16,
                             speed: 1.6, size: SIMD2(0.28, 0.12), baseY: 0.13),
            ],
            bonusStar: SIMD2(-1.05, -2.3),
            cameraZoom: 1.55
        ),
    ]
}
