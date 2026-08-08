//
//  ClockworkLevels.swift
//  Minigolf
//
//  Clockwork Works — a brass workshop where the course itself is machinery:
//  turning tables, timed gates, pistons and the first cannons of the tour.
//

import Foundation
import simd

enum ClockworkCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one turning table, nothing else.
        LevelDefinition(
            course: .clockwork, number: 1, name: String(localized: "First Cog"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.45),
            floors: [floorRect(-0.5, 0.5, -2.9, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -2.9, 0.5)],
            obstacles: [
                .turntable(center: SIMD2(0, -1.35), radius: 0.26, speed: 1.2, y: 0),
                // A wind-up tin man marching across the run-out.
                critter(.windupBot, at: SIMD2(0, -2.05),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 1.1),
            ],
            bonusStar: SIMD2(0.34, -2.68)
        ),
        // 2 — a curved brass bank carries the ball around the corner.
        LevelDefinition(
            course: .clockwork, number: 2, name: String(localized: "Brass Alley"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.3, -2.75),
            floors: [
                floorRect(-0.45, 0.45, -2.3, 0.5),
                floorRect(-0.45, 1.7, -3.2, -2.3),
            ],
            wallLoops: [[
                SIMD2(0.45, 0.5), SIMD2(0.45, -2.3), SIMD2(1.7, -2.3),
                SIMD2(1.7, -3.2), SIMD2(-0.45, -3.2), SIMD2(-0.45, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(0.10, -2.65), radius: 0.55,
                                from: deg(180), to: deg(270), segments: 6),
            obstacles: [
                .movingBlock(center: SIMD2(0.75, -2.75), axis: SIMD2(0, 1), amplitude: 0.2,
                             speed: 1.3, size: SIMD2(0.12, 0.36), baseY: 0),
            ],
            bonusStar: SIMD2(-0.28, -2.55),
            cameraZoom: 1.2
        ),
        // 3 — piston first, then a gate that has to be read.
        LevelDefinition(
            course: .clockwork, number: 3, name: String(localized: "The Piston"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.95),
            floors: [floorRect(-0.5, 0.5, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            obstacles: [
                .movingBlock(center: SIMD2(0, -1.5), axis: SIMD2(1, 0), amplitude: 0.3,
                             speed: 1.5, size: SIMD2(0.34, 0.12), baseY: 0),
                .gate(center: SIMD2(0, -2.4), size: SIMD2(0.5, 0.09), yaw: 0,
                      period: 2.4, phase: 0.6, baseY: 0),
                // A cuckoo popping out of a hatch beside the cup, on its own
                // beat — nothing else on this hole keeps that time.
                critter(.cuckoo, at: SIMD2(-0.3, -3.2), .burrow(period: 3.4)),
            ],
            bonusStar: SIMD2(0.34, -3.2)
        ),
        // 4 — a table wide enough that there is no way round it.
        LevelDefinition(
            course: .clockwork, number: 4, name: String(localized: "Big Wheel"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.05),
            floors: [floorRect(-0.8, 0.8, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.8, 0.8, -3.4, 0.5)],
            obstacles: [
                .turntable(center: SIMD2(0, -1.9), radius: 0.62, speed: 1.2, y: 0),
                .post(center: SIMD2(-0.6, -2.7), radius: 0.045),
                .post(center: SIMD2(0.6, -2.7), radius: 0.045),
            ],
            bonusStar: SIMD2(-0.62, -3.25),
            cameraZoom: 1.2
        ),
        // 5 — the barrel takes the corner for you, whichever way you rolled in.
        LevelDefinition(
            course: .clockwork, number: 5, name: String(localized: "Powder Keg"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.55, -2.65),
            floors: [
                floorRect(-0.45, 0.45, -2.2, 0.5),
                floorRect(-0.45, 1.9, -3.1, -2.2),
            ],
            wallLoops: [[
                SIMD2(0.45, 0.5), SIMD2(0.45, -2.2), SIMD2(1.9, -2.2),
                SIMD2(1.9, -3.1), SIMD2(-0.45, -3.1), SIMD2(-0.45, 0.5),
            ]],
            obstacles: [
                .cannon(center: SIMD2(0, -2.65), direction: SIMD2(1, 0), speed: 3.0, y: 0),
            ],
            bonusStar: SIMD2(-0.28, -2.85),
            cameraZoom: 1.25
        ),
        // 6 — two tables geared against each other.
        LevelDefinition(
            course: .clockwork, number: 6, name: String(localized: "Gear Train"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.62),
            floors: [floorRect(-0.75, 0.75, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.75, 0.75, -4.0, 0.5)],
            obstacles: [
                .turntable(center: SIMD2(-0.36, -1.5), radius: 0.35, speed: 1.8, y: 0),
                .turntable(center: SIMD2(0.36, -2.5), radius: 0.35, speed: -1.8, y: 0),
                .post(center: SIMD2(-0.3, -3.2), radius: 0.04),
                .post(center: SIMD2(0.3, -3.2), radius: 0.04),
                critter(.cuckoo, at: SIMD2(0.3, -1.95), .burrow(period: 3.0), phase: 0.8),
            ],
            bonusStar: SIMD2(0.6, -3.85),
            cameraZoom: 1.25
        ),
        // 7 — belt between two gates beating out of phase.
        LevelDefinition(
            course: .clockwork, number: 7, name: String(localized: "The Escapement"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.85),
            floors: [floorRect(-0.55, 0.55, -4.3, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -4.3, 0.5)],
            obstacles: [
                .gate(center: SIMD2(0, -1.3), size: SIMD2(0.62, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                .conveyor(rect: zone(-0.55, 0.55, -2.7, -1.7), direction: SIMD2(0, -1),
                          strength: 1.5, y: 0),
                .gate(center: SIMD2(0, -3.1), size: SIMD2(0.62, 0.09), yaw: 0,
                      period: 2.2, phase: .pi, baseY: 0),
            ],
            bonusStar: SIMD2(-0.38, -4.1),
            cameraZoom: 1.3
        ),
        // 8 — narrow plank over the oil, table waiting on the far side.
        LevelDefinition(
            course: .clockwork, number: 8, name: String(localized: "Oil Bath"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.33, -3.3),
            floors: [
                floorRect(-0.55, 0.55, -1.4, 0.5),
                floorRect(-0.55, -0.18, -2.4, -1.4, kind: .water),
                floorRect(-0.18, 0.18, -2.4, -1.4),
                floorRect(0.18, 0.55, -2.4, -1.4, kind: .water),
                floorRect(-0.55, 0.55, -3.6, -2.4),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.6, 0.5)],
            obstacles: [.turntable(center: SIMD2(0.12, -2.95), radius: 0.38, speed: 1.6, y: 0)],
            bonusStar: SIMD2(0.42, -3.35),
            cameraZoom: 1.15
        ),
        // 9 — up the ramp into the tower, with a piston on the landing.
        LevelDefinition(
            course: .clockwork, number: 9, name: String(localized: "Clock Tower"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6), holeY: 0.13,
            floors: [
                floorRect(-0.45, 0.45, -1.9, 0.5),
                floorRect(-0.45, 0.45, -3.9, -2.6, y: 0.13),
            ],
            extraWalls: [
                wall(0.45, 0.5, -0.45, 0.5),
                wall(-0.45, 0.5, -0.45, -1.9),
                wall(-0.45, -1.9, -0.45, -3.9, height: 0.26),
                wall(-0.45, -3.9, 0.45, -3.9, height: 0.26),
                wall(0.45, -3.9, 0.45, -1.9, height: 0.26),
                wall(0.45, -1.9, 0.45, 0.5),
            ],
            obstacles: [
                .gate(center: SIMD2(0, -1.1), size: SIMD2(0.56, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                // Marching the approach between the gate and the ramp.
                critter(.windupBot, at: SIMD2(0, -1.6),
                        .patrol(axis: acrossLane, amplitude: 0.2), speed: 1.3),
                .ramp(center: SIMD2(0, -2.25), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                .movingBlock(center: SIMD2(0, -3.15), axis: SIMD2(1, 0), amplitude: 0.24,
                             speed: 1.7, size: SIMD2(0.3, 0.12), baseY: 0.13),
            ],
            bonusStar: SIMD2(0.31, -3.75), bonusStarY: 0.13,
            cameraZoom: 1.25
        ),
        // 10 — the belts wind the ball around the drum the long way.
        LevelDefinition(
            course: .clockwork, number: 10, name: String(localized: "The Mainspring"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.82, -1.6),
            floors: [floorRect(-1.1, 1.1, -3.4, 0.5)],
            wallLoops: [rectLoop(-1.1, 1.1, -3.4, 0.5)],
            obstacles: [
                .block(center: SIMD2(0, -1.6), size: SIMD3(1.1, 0.16, 1.4), yaw: 0, baseY: 0),
                .conveyor(rect: zone(0.58, 1.08, -2.3, -0.9), direction: SIMD2(0, -1),
                          strength: 1.5, y: 0),
                .conveyor(rect: zone(-1.08, 1.08, -2.9, -2.4), direction: SIMD2(-1, 0),
                          strength: 1.5, y: 0),
            ],
            bonusStar: SIMD2(0.85, -3.15),
            cameraZoom: 1.4
        ),
        // 11 — two bulkheads, two barrels, one way through each.
        LevelDefinition(
            course: .clockwork, number: 11, name: String(localized: "Double Barrel"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.65, -3.35),
            floors: [floorRect(-1.1, 1.1, -3.7, 0.5)],
            wallLoops: [rectLoop(-1.1, 1.1, -3.7, 0.5)],
            extraWalls: [
                wall(-1.1, -1.9, 0.5, -1.9),
                wall(1.1, -2.8, -0.5, -2.8),
            ],
            obstacles: [
                .cannon(center: SIMD2(0.8, -1.35), direction: SIMD2(0, -1), speed: 3.2, y: 0),
                .cannon(center: SIMD2(0.8, -2.35), direction: SIMD2(-1, -0.25), speed: 3.0, y: 0),
            ],
            bonusStar: SIMD2(0.9, -3.4),
            cameraZoom: 1.4
        ),
        // 12 — gate, table, barrel and a piston guarding the top floor.
        LevelDefinition(
            course: .clockwork, number: 12, name: String(localized: "The Great Machine"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.42), holeY: 0.14,
            floors: [
                floorRect(-0.6, 0.6, -1.8, 0.5),
                floorRect(-1.2, 1.2, -3.2, -1.8),
                floorRect(-0.5, 0.5, -4.6, -3.9, y: 0.14),
            ],
            extraWalls: [
                wall(0.6, 0.5, -0.6, 0.5),
                wall(-0.6, 0.5, -0.6, -1.8),
                wall(-0.6, -1.8, -1.2, -1.8),
                wall(-1.2, -1.8, -1.2, -3.2),
                wall(-1.2, -3.2, -0.5, -3.2),
                wall(0.5, -3.2, 1.2, -3.2),
                wall(1.2, -3.2, 1.2, -1.8),
                wall(1.2, -1.8, 0.6, -1.8),
                wall(0.6, -1.8, 0.6, 0.5),
                wall(-0.5, -3.2, -0.5, -4.6, height: 0.26),
                wall(-0.5, -4.6, 0.5, -4.6, height: 0.26),
                wall(0.5, -4.6, 0.5, -3.2, height: 0.26),
            ],
            obstacles: [
                .gate(center: SIMD2(0, -1.2), size: SIMD2(0.72, 0.09), yaw: 0,
                      period: 2.0, phase: 0, baseY: 0),
                .turntable(center: SIMD2(0, -2.5), radius: 0.5, speed: 1.5, y: 0),
                .cannon(center: SIMD2(-0.85, -2.2), direction: SIMD2(1, -0.5), speed: 2.8, y: 0),
                critter(.cuckoo, at: SIMD2(0.85, -2.9), .burrow(period: 2.8)),
                .ramp(center: SIMD2(0, -3.55), width: 1.0, length: 0.7, rise: 0.14, yaw: 0),
                .movingBlock(center: SIMD2(0, -4.2), axis: SIMD2(1, 0), amplitude: 0.22,
                             speed: 1.8, size: SIMD2(0.28, 0.12), baseY: 0.14),
            ],
            bonusStar: SIMD2(-1.05, -2.95),
            cameraZoom: 1.45
        ),
    ]
}
