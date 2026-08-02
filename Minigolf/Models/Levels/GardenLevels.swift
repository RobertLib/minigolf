//
//  GardenLevels.swift
//  Minigolf
//
//  Green Garden — the introductory world. Teaches banking off walls, sand,
//  speed bumps, the windmill, a raised green and a first taste of water.
//

import Foundation
import simd

enum GardenCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a plain straight lane.
        LevelDefinition(
            course: .garden, number: 1, name: String(localized: "First Steps"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.2),
            floors: [floorRect(-0.45, 0.45, -2.7, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -2.7, 0.5)],
            bonusStar: SIMD2(0.32, -2.5)
        ),
        // 2 — staggered posts.
        LevelDefinition(
            course: .garden, number: 2, name: String(localized: "Slalom"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.8),
            floors: [floorRect(-0.5, 0.5, -3.3, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.3, 0.5)],
            obstacles: [
                .post(center: SIMD2(-0.18, -1.2), radius: 0.04),
                .post(center: SIMD2(0.22, -1.9), radius: 0.04),
                .post(center: SIMD2(-0.18, -2.4), radius: 0.04),
            ],
            bonusStar: SIMD2(0.36, -3.1)
        ),
        // 3 — bank off the corner wall.
        LevelDefinition(
            course: .garden, number: 3, name: String(localized: "Dogleg Right"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.45, -3.05),
            floors: [
                floorRect(-0.45, 0.45, -2.6, 0.5),
                floorRect(-0.45, 1.9, -3.5, -2.6),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.5), SIMD2(-0.45, -3.5), SIMD2(1.9, -3.5),
                SIMD2(1.9, -2.6), SIMD2(0.45, -2.6), SIMD2(0.45, 0.5),
            ]],
            extraWalls: [wall(-0.43, -3.1, -0.05, -3.48)],
            bonusStar: SIMD2(0.75, -2.85),
            cameraZoom: 1.15
        ),
        // 4 — punch through or thread the gap.
        LevelDefinition(
            course: .garden, number: 4, name: String(localized: "Sand Trap"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [
                floorRect(-0.5, 0.5, -3.4, 0.5),
                floorRect(-0.5, 0.15, -2.2, -1.4, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            bonusStar: SIMD2(-0.34, -1.8)
        ),
        // 5 — speed bump plus guarding posts.
        LevelDefinition(
            course: .garden, number: 5, name: String(localized: "Over the Hill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.7),
            floors: [floorRect(-0.45, 0.45, -3.2, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -3.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -1.4), width: 0.9, height: 0.035, yaw: 0),
                .post(center: SIMD2(-0.22, -2.05), radius: 0.04),
                .post(center: SIMD2(0.22, -2.3), radius: 0.04),
            ],
            bonusStar: SIMD2(0.3, -3.0)
        ),
        // 6 — the timeless classic.
        LevelDefinition(
            course: .garden, number: 6, name: String(localized: "The Windmill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [floorRect(-0.45, 0.45, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -3.4, 0.5)],
            obstacles: [.windmill(center: SIMD2(0, -1.7), yaw: 0, speed: 1.6)],
            bonusStar: SIMD2(0.31, -3.2)
        ),
        // 7 — ramp up to a raised green.
        LevelDefinition(
            course: .garden, number: 7, name: String(localized: "King of the Hill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0), holeY: 0.13,
            floors: [
                floorRect(-0.45, 0.45, -1.7, 0.5),
                floorRect(-0.45, 0.45, -3.5, -2.4, y: 0.13),
            ],
            extraWalls: [
                wall(0.45, 0.5, -0.45, 0.5),
                wall(-0.45, 0.5, -0.45, -1.7),
                wall(-0.45, -1.7, -0.45, -3.5, height: 0.26),
                wall(-0.45, -3.5, 0.45, -3.5, height: 0.26),
                wall(0.45, -3.5, 0.45, -1.7, height: 0.26),
                wall(0.45, -1.7, 0.45, 0.5),
            ],
            obstacles: [.ramp(center: SIMD2(0, -2.05), width: 0.9, length: 0.7, rise: 0.13, yaw: 0)],
            bonusStar: SIMD2(0.31, -3.3), bonusStarY: 0.13
        ),
        // 8 — an S-shaped walk between hedges.
        LevelDefinition(
            course: .garden, number: 8, name: String(localized: "Garden Path"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.25, -3.8),
            floors: [
                floorRect(-0.45, 0.45, -1.8, 0.5),
                floorRect(-1.7, 0.45, -2.7, -1.8),
                floorRect(-1.7, -0.8, -4.3, -2.7),
            ],
            wallLoops: [[
                SIMD2(0.45, 0.5), SIMD2(0.45, -2.7), SIMD2(-0.8, -2.7),
                SIMD2(-0.8, -4.3), SIMD2(-1.7, -4.3), SIMD2(-1.7, -1.8),
                SIMD2(-0.45, -1.8), SIMD2(-0.45, 0.5),
            ]],
            bonusStar: SIMD2(0.28, -2.5),
            cameraZoom: 1.3
        ),
        // 9 — keep your nerve on the narrow bridge.
        LevelDefinition(
            course: .garden, number: 9, name: String(localized: "The Pond"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.1),
            floors: [
                floorRect(-0.5, 0.5, -1.5, 0.5),
                floorRect(-0.5, -0.14, -2.3, -1.5, kind: .water),
                floorRect(-0.14, 0.14, -2.3, -1.5),
                floorRect(0.14, 0.5, -2.3, -1.5, kind: .water),
                floorRect(-0.5, 0.5, -3.6, -2.3),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.6, 0.5)],
            bonusStar: SIMD2(0.35, -3.35),
            cameraZoom: 1.1
        ),
        // 10 — the felt is banked: everything drifts right.
        LevelDefinition(
            course: .garden, number: 10, name: String(localized: "Sloping Lawn"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.24, -3.05),
            floors: [floorRect(-0.6, 0.6, -3.5, 0.5)],
            wallLoops: [rectLoop(-0.6, 0.6, -3.5, 0.5)],
            obstacles: [
                .slope(rect: zone(-0.6, 0.6, -2.5, -1.1), direction: SIMD2(1, 0),
                       strength: 1.1, y: 0),
                .post(center: SIMD2(0.28, -2.75), radius: 0.04),
            ],
            bonusStar: SIMD2(0.44, -3.3),
            cameraZoom: 1.15
        ),
        // 11 — the only way through is the arch.
        LevelDefinition(
            course: .garden, number: 11, name: String(localized: "Hedge Tunnel"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.5),
            floors: [floorRect(-0.5, 0.5, -3.9, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.9, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -1.1), width: 1.0, height: 0.03, yaw: 0),
                .tunnel(center: SIMD2(0, -2.1), width: 0.3, length: 1.0, yaw: 0),
                .block(center: SIMD2(-0.35, -2.1), size: SIMD3(0.31, 0.16, 1.0),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.35, -2.1), size: SIMD3(0.31, 0.16, 1.0),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.2, -3.0), radius: 0.04),
            ],
            bonusStar: SIMD2(0.36, -3.7),
            cameraZoom: 1.2
        ),
        // 12 — windmill, sand and a dogleg finale.
        LevelDefinition(
            course: .garden, number: 12, name: String(localized: "Grand Garden"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.45, -2.65),
            floors: [
                floorRect(-0.45, 0.45, -2.2, 0.5),
                floorRect(-0.45, 0.05, -1.6, -1.0, kind: .sand),
                floorRect(-1.9, 0.45, -3.1, -2.2),
            ],
            wallLoops: [[
                SIMD2(0.45, 0.5), SIMD2(0.45, -3.1), SIMD2(-1.9, -3.1),
                SIMD2(-1.9, -2.2), SIMD2(-0.45, -2.2), SIMD2(-0.45, 0.5),
            ]],
            obstacles: [
                .windmill(center: SIMD2(0, -1.9), yaw: 0, speed: 1.8),
                .post(center: SIMD2(-0.7, -2.5), radius: 0.04),
                .post(center: SIMD2(-1.0, -2.85), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.7, -2.45),
            cameraZoom: 1.25
        ),
    ]
}
