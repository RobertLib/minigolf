//
//  NeonLevels.swift
//  Minigolf
//
//  Neon Nights — a fast, glowing arcade world: bumper arenas, twin turbines,
//  plasma voids, warp portals and strobing gates.
//

import Foundation
import simd

enum NeonCourse {

    static let holes: [LevelDefinition] = [
        // 1 — gentle warmup with two bumpers.
        LevelDefinition(
            course: .neon, number: 1, name: String(localized: "Night Shift"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.55),
            floors: [floorRect(-0.45, 0.45, -3.0, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -3.0, 0.5)],
            obstacles: [
                // A patrol drone flying its circuit over the lane. The beam under
                // it is what stops the ball, so it is drawn down to the felt.
                critter(.drone, at: SIMD2(0, -0.9), .circle(radius: 0.22), speed: 1.4),
                .bumper(center: SIMD2(-0.2, -1.5), radius: 0.06),
                .bumper(center: SIMD2(0.25, -2.0), radius: 0.06),
            ],
            bonusStar: SIMD2(0.31, -2.8)
        ),
        // 2 — dogleg with a patrolling block.
        LevelDefinition(
            course: .neon, number: 2, name: String(localized: "Laser Corner"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.45, -2.85),
            floors: [
                floorRect(-0.45, 0.45, -2.4, 0.5),
                floorRect(-0.45, 1.9, -3.3, -2.4),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.5), SIMD2(-0.45, -3.3), SIMD2(1.9, -3.3),
                SIMD2(1.9, -2.4), SIMD2(0.45, -2.4), SIMD2(0.45, 0.5),
            ]],
            extraWalls: [wall(-0.43, -2.92, -0.05, -3.28)],
            obstacles: [
                .movingBlock(center: SIMD2(0.7, -2.85), axis: SIMD2(0, 1), amplitude: 0.25,
                             speed: 1.4, size: SIMD2(0.12, 0.4), baseY: 0),
            ],
            bonusStar: SIMD2(1.72, -2.6),
            cameraZoom: 1.15
        ),
        // 3 — a glowing bumper arena.
        LevelDefinition(
            course: .neon, number: 3, name: String(localized: "Pinball Palace"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.15),
            floors: [floorRect(-1.0, 1.0, -3.6, 0.5)],
            wallLoops: [rectLoop(-1.0, 1.0, -3.6, 0.5)],
            obstacles: [
                .bumper(center: SIMD2(0, -1.3), radius: 0.08),
                .bumper(center: SIMD2(-0.5, -1.9), radius: 0.07),
                .bumper(center: SIMD2(0.5, -1.9), radius: 0.07),
                .bumper(center: SIMD2(0, -2.5), radius: 0.08),
                // Circling the middle of the arena, between all four bumpers.
                critter(.drone, at: SIMD2(0, -1.9), .circle(radius: 0.25), speed: 1.6),
            ],
            bonusStar: SIMD2(-0.82, -3.35),
            cameraZoom: 1.25
        ),
        // 4 — rotor plus guard posts.
        LevelDefinition(
            course: .neon, number: 4, name: String(localized: "Night Sweeper"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.95),
            floors: [floorRect(-0.7, 0.7, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.7, 0.7, -3.4, 0.5)],
            obstacles: [
                .rotor(center: SIMD2(0, -1.6), length: 0.9, speed: 1.8, baseY: 0),
                .post(center: SIMD2(-0.35, -2.4), radius: 0.045),
                .post(center: SIMD2(0.35, -2.4), radius: 0.045),
            ],
            bonusStar: SIMD2(-0.52, -3.2),
            cameraZoom: 1.15
        ),
        // 5 — a tight S of narrow traces.
        LevelDefinition(
            course: .neon, number: 5, name: String(localized: "Circuit Board"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.2, -3.3),
            floors: [
                floorRect(-0.3, 0.3, -1.6, 0.5),
                floorRect(-1.5, 0.3, -2.2, -1.6),
                floorRect(-1.5, -0.9, -3.8, -2.2),
            ],
            wallLoops: [[
                SIMD2(0.3, 0.5), SIMD2(0.3, -2.2), SIMD2(-0.9, -2.2),
                SIMD2(-0.9, -3.8), SIMD2(-1.5, -3.8), SIMD2(-1.5, -1.6),
                SIMD2(-0.3, -1.6), SIMD2(-0.3, 0.5),
            ]],
            // A sentry pacing the last trace, in a corridor too narrow to pass
            // it on the wrong beat.
            obstacles: [
                critter(.sentry, at: SIMD2(-1.2, -2.85),
                        .patrol(axis: alongLane, amplitude: 0.2), speed: 1.0),
            ],
            bonusStar: SIMD2(0.12, -1.9),
            cameraZoom: 1.25
        ),
        // 6 — the windmill spins twice as fast at night.
        LevelDefinition(
            course: .neon, number: 6, name: String(localized: "Turbo Mill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.95),
            floors: [
                floorRect(-0.45, 0.45, -3.4, 0.5),
                floorRect(-0.45, 0.45, -2.7, -2.3, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.45, 0.45, -3.4, 0.5)],
            obstacles: [.windmill(center: SIMD2(0, -1.8), yaw: 0, speed: 2.6)],
            bonusStar: SIMD2(0.31, -3.2)
        ),
        // 7 — a raised deck with a patrolling block.
        LevelDefinition(
            course: .neon, number: 7, name: String(localized: "Sky Platform"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.5), holeY: 0.13,
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
                .ramp(center: SIMD2(0, -2.25), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                .movingBlock(center: SIMD2(0, -3.1), axis: SIMD2(1, 0), amplitude: 0.26,
                             speed: 1.6, size: SIMD2(0.3, 0.12), baseY: 0.13),
            ],
            bonusStar: SIMD2(0.31, -3.7), bonusStarY: 0.13,
            cameraZoom: 1.2
        ),
        // 8 — two crossings over glowing plasma.
        LevelDefinition(
            course: .neon, number: 8, name: String(localized: "The Void"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.85),
            floors: [
                floorRect(-0.6, 0.6, -1.4, 0.5),
                floorRect(-0.6, -0.45, -2.2, -1.4, kind: .water),
                floorRect(-0.45, -0.17, -2.2, -1.4),
                floorRect(-0.17, 0.6, -2.2, -1.4, kind: .water),
                floorRect(-0.6, 0.6, -2.6, -2.2),
                floorRect(-0.6, 0.17, -3.4, -2.6, kind: .water),
                floorRect(0.17, 0.45, -3.4, -2.6),
                floorRect(0.45, 0.6, -3.4, -2.6, kind: .water),
                floorRect(-0.6, 0.6, -4.3, -3.4),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -4.3, 0.5)],
            bonusStar: SIMD2(-0.42, -2.4),
            cameraZoom: 1.3
        ),
        // 9 — two rotors spinning in opposite directions.
        LevelDefinition(
            course: .neon, number: 9, name: String(localized: "Twin Turbines"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.62),
            floors: [floorRect(-0.8, 0.8, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.8, 0.8, -4.0, 0.5)],
            obstacles: [
                .rotor(center: SIMD2(-0.35, -1.5), length: 0.75, speed: 1.7, baseY: 0),
                .rotor(center: SIMD2(0.35, -2.6), length: 0.75, speed: -2.0, baseY: 0),
                .bumper(center: SIMD2(0, -3.15), radius: 0.07),
            ],
            bonusStar: SIMD2(-0.62, -3.8),
            cameraZoom: 1.3
        ),
        // 10 — the lane and the green are two separate islands. They sit close
        //      together so the chase camera keeps both in frame.
        LevelDefinition(
            course: .neon, number: 10, name: String(localized: "Warp Zone"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.25, -3.3),
            floors: [
                floorRect(-0.45, 0.45, -2.3, 0.5),
                floorRect(0.8, 1.7, -3.8, -1.1),
            ],
            wallLoops: [
                rectLoop(-0.45, 0.45, -2.3, 0.5),
                rectLoop(0.8, 1.7, -3.8, -1.1),
            ],
            obstacles: [
                critter(.drone, at: SIMD2(0, -0.75), .circle(radius: 0.2), speed: 1.5),
                .teleporter(a: SIMD2(0, -1.85), b: SIMD2(1.25, -1.5), radius: 0.1, y: 0),
                .bumper(center: SIMD2(-0.28, -1.15), radius: 0.05),
                .bumper(center: SIMD2(0.28, -1.45), radius: 0.05),
                .rotor(center: SIMD2(1.25, -2.5), length: 0.7, speed: 1.6, baseY: 0),
            ],
            bonusStar: SIMD2(1.55, -3.55),
            cameraZoom: 1.5
        ),
        // 11 — offset gates strobing out of phase, then a kicker.
        LevelDefinition(
            course: .neon, number: 11, name: String(localized: "Strobe Gates"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.3),
            floors: [floorRect(-0.6, 0.6, -4.7, 0.5)],
            wallLoops: [rectLoop(-0.6, 0.6, -4.7, 0.5)],
            obstacles: [
                .gate(center: SIMD2(-0.28, -1.4), size: SIMD2(0.64, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                .gate(center: SIMD2(0.28, -2.3), size: SIMD2(0.64, 0.09), yaw: 0,
                      period: 2.2, phase: .pi, baseY: 0),
                .boostPad(center: SIMD2(0, -3.0), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .bumper(center: SIMD2(0.3, -3.7), radius: 0.06),
                .post(center: SIMD2(-0.3, -3.95), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.45, -3.35),
            cameraZoom: 1.4
        ),
        // 12 — windmill, rotor, ramp and a moving guard.
        LevelDefinition(
            course: .neon, number: 12, name: String(localized: "Grand Finale"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.45), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -1.8, 0.5),
                floorRect(-0.9, 0.9, -3.0, -1.8),
                floorRect(-0.45, 0.45, -4.9, -3.7, y: 0.13),
            ],
            extraWalls: [
                wall(0.5, 0.5, -0.5, 0.5),
                wall(-0.5, 0.5, -0.5, -1.8),
                wall(-0.5, -1.8, -0.9, -1.8),
                wall(-0.9, -1.8, -0.9, -3.0),
                wall(-0.9, -3.0, -0.45, -3.0),
                wall(-0.45, -3.0, -0.45, -4.9, height: 0.26),
                wall(-0.45, -4.9, 0.45, -4.9, height: 0.26),
                wall(0.45, -4.9, 0.45, -3.0, height: 0.26),
                wall(0.45, -3.0, 0.9, -3.0),
                wall(0.9, -3.0, 0.9, -1.8),
                wall(0.9, -1.8, 0.5, -1.8),
                wall(0.5, -1.8, 0.5, 0.5),
            ],
            obstacles: [
                .windmill(center: SIMD2(0, -1.1), yaw: 0, speed: 2.2),
                .rotor(center: SIMD2(0, -2.4), length: 1.1, speed: 1.6, baseY: 0),
                // Just outside the rotor's sweep, guarding the one gap it leaves.
                critter(.sentry, at: SIMD2(0.7, -2.85),
                        .patrol(axis: alongLane, amplitude: 0.1), speed: 1.2),
                .ramp(center: SIMD2(0, -3.35), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                .movingBlock(center: SIMD2(0, -4.1), axis: SIMD2(1, 0), amplitude: 0.25,
                             speed: 1.8, size: SIMD2(0.3, 0.12), baseY: 0.13),
            ],
            bonusStar: SIMD2(-0.72, -2.85),
            cameraZoom: 1.35
        ),
    ]
}
