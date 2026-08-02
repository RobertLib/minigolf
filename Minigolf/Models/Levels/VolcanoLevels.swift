//
//  VolcanoLevels.swift
//  Minigolf
//
//  Volcano Forge — the final world. Lava replaces water, geysers kick the ball
//  around, iron gates hammer up and down and the lanes have open edges: miss
//  and there is nothing to stop you.
//

import Foundation
import simd

enum VolcanoCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one narrow crossing over the first lava trench.
        LevelDefinition(
            course: .volcano, number: 1, name: String(localized: "Cinder Path"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [
                floorRect(-0.5, 0.5, -1.3, 0.5),
                floorRect(-0.5, -0.15, -2.1, -1.3, kind: .lava),
                floorRect(-0.15, 0.15, -2.1, -1.3),
                floorRect(0.15, 0.5, -2.1, -1.3, kind: .lava),
                floorRect(-0.5, 0.5, -3.3, -2.1),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.3, 0.5)],
            bonusStar: SIMD2(0.36, -2.6),
            cameraZoom: 1.15
        ),
        // 2 — deep ash swallows anything that rolls into it.
        LevelDefinition(
            course: .volcano, number: 2, name: String(localized: "Ash Field"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -3.0),
            floors: [
                floorRect(-0.55, 0.55, -3.4, 0.5),
                floorRect(-0.55, 0.1, -2.3, -1.4, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.4, 0.5)],
            obstacles: [
                .post(center: SIMD2(0.28, -1.8), radius: 0.045),
                .post(center: SIMD2(-0.2, -2.7), radius: 0.045),
            ],
            bonusStar: SIMD2(-0.4, -1.9)
        ),
        // 3 — a geyser fires you straight at a hammering gate.
        LevelDefinition(
            course: .volcano, number: 3, name: String(localized: "Geyser Gate"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.5),
            floors: [floorRect(-0.55, 0.55, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -4.0, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -1.3), direction: SIMD2(0, -1), boost: 1.1, y: 0),
                .gate(center: SIMD2(0, -2.4), size: SIMD2(0.66, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
            ],
            bonusStar: SIMD2(0.4, -2.0),
            cameraZoom: 1.3
        ),
        // 4 — no boards along the lava: the rotor decides how straight you are.
        LevelDefinition(
            course: .volcano, number: 4, name: String(localized: "Molten Rotor"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.2),
            floors: [
                floorRect(-0.45, 0.45, -3.6, 0.5),
                floorRect(-0.85, -0.45, -2.6, -1.0, kind: .lava),
                floorRect(0.45, 0.85, -2.6, -1.0, kind: .lava),
            ],
            extraWalls: [
                wall(-0.45, 0.5, 0.45, 0.5),
                wall(0.45, 0.5, 0.45, -1.0),
                wall(0.45, -2.6, 0.45, -3.6),
                wall(0.45, -3.6, -0.45, -3.6),
                wall(-0.45, -3.6, -0.45, -2.6),
                wall(-0.45, -1.0, -0.45, 0.5),
            ],
            obstacles: [.rotor(center: SIMD2(0, -1.8), length: 0.6, speed: 1.5, baseY: 0)],
            bonusStar: SIMD2(0.3, -3.4),
            cameraZoom: 1.3
        ),
        // 5 — three half-gates alternating left and right.
        LevelDefinition(
            course: .volcano, number: 5, name: String(localized: "Iron Pistons"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.0),
            floors: [floorRect(-0.6, 0.6, -4.4, 0.5)],
            wallLoops: [rectLoop(-0.6, 0.6, -4.4, 0.5)],
            obstacles: [
                .gate(center: SIMD2(-0.3, -1.4), size: SIMD2(0.6, 0.09), yaw: 0,
                      period: 2.0, phase: 0, baseY: 0),
                .gate(center: SIMD2(0.3, -2.3), size: SIMD2(0.6, 0.09), yaw: 0,
                      period: 2.0, phase: .pi, baseY: 0),
                .gate(center: SIMD2(-0.3, -3.2), size: SIMD2(0.6, 0.09), yaw: 0,
                      period: 2.0, phase: 0, baseY: 0),
            ],
            bonusStar: SIMD2(0.45, -3.6),
            cameraZoom: 1.4
        ),
        // 6 — two lava channels with offset stepping stones.
        LevelDefinition(
            course: .volcano, number: 6, name: String(localized: "Lava Falls"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.95),
            floors: [
                floorRect(-0.7, 0.7, -1.3, 0.5),
                floorRect(-0.7, -0.5, -2.1, -1.3, kind: .lava),
                floorRect(-0.5, -0.2, -2.1, -1.3),
                floorRect(-0.2, 0.7, -2.1, -1.3, kind: .lava),
                floorRect(-0.7, 0.7, -2.6, -2.1),
                floorRect(-0.7, 0.2, -3.4, -2.6, kind: .lava),
                floorRect(0.2, 0.5, -3.4, -2.6),
                floorRect(0.5, 0.7, -3.4, -2.6, kind: .lava),
                floorRect(-0.7, 0.7, -4.3, -3.4),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.3, 0.5)],
            bonusStar: SIMD2(-0.55, -2.35),
            cameraZoom: 1.4
        ),
        // 7 — a geyser launch straight under the wrecking ball.
        LevelDefinition(
            course: .volcano, number: 7, name: String(localized: "Wrecking Ball"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.7),
            floors: [
                floorRect(-0.85, 0.85, -4.0, 0.5),
                floorRect(-0.85, 0.85, -3.2, -2.7, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.85, 0.85, -4.0, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -1.0), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .pendulum(center: SIMD2(0, -2.0), span: 0.5, arc: 0.6, speed: 1.6,
                          yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.7, -1.5),
            cameraZoom: 1.4
        ),
        // 8 — a narrow ramp is the only bridge over the flow.
        LevelDefinition(
            course: .volcano, number: 8, name: String(localized: "Forge Ramp"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -1.8, 0.5),
                floorRect(-0.5, 0.5, -2.6, -1.8, kind: .lava),
                floorRect(-0.5, 0.5, -4.0, -2.6, y: 0.13),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -1.8),
                wall(0.5, -2.6, 0.5, -4.0, height: 0.26),
                wall(0.5, -4.0, -0.5, -4.0, height: 0.26),
                wall(-0.5, -4.0, -0.5, -2.6, height: 0.26),
                wall(-0.5, -1.8, -0.5, 0.5),
            ],
            obstacles: [.ramp(center: SIMD2(0, -2.2), width: 0.5, length: 0.8, rise: 0.13, yaw: 0)],
            bonusStar: SIMD2(0.36, -3.85), bonusStarY: 0.13,
            cameraZoom: 1.3
        ),
        // 9 — the pit splits the course; the geysers pick a side for you.
        LevelDefinition(
            course: .volcano, number: 9, name: String(localized: "Twin Geysers"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.3),
            floors: [
                floorRect(-0.9, -0.3, -3.8, 0.5),
                floorRect(-0.3, 0.3, -1.2, 0.5),
                floorRect(-0.3, 0.3, -2.6, -1.2, kind: .lava),
                floorRect(-0.3, 0.3, -3.8, -2.6),
                floorRect(0.3, 0.9, -3.8, 0.5),
            ],
            wallLoops: [rectLoop(-0.9, 0.9, -3.8, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(-0.6, -1.8), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .boostPad(center: SIMD2(0.6, -1.8), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .post(center: SIMD2(0.6, -3.0), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.75, -3.5),
            cameraZoom: 1.4
        ),
        // 10 — the flow pushes you straight toward the magma.
        LevelDefinition(
            course: .volcano, number: 10, name: String(localized: "Magma Rapids"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.55, -3.1),
            floors: [
                floorRect(-0.9, 0.3, -3.6, 0.5),
                floorRect(0.3, 0.9, -1.2, 0.5),
                floorRect(0.3, 0.9, -2.8, -1.2, kind: .lava),
                floorRect(0.3, 0.9, -3.6, -2.8),
            ],
            wallLoops: [rectLoop(-0.9, 0.9, -3.6, 0.5)],
            obstacles: [
                .conveyor(rect: zone(-0.9, 0.3, -2.6, -1.4), direction: SIMD2(1, 0),
                          strength: 2.0, y: 0),
            ],
            bonusStar: SIMD2(0.6, -3.3),
            cameraZoom: 1.4
        ),
        // 11 — the crucible: two gated corridors around a lava pit.
        LevelDefinition(
            course: .volcano, number: 11, name: String(localized: "The Crucible"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6),
            floors: [
                floorRect(-1.0, 1.0, -1.6, 0.5),
                floorRect(-1.0, -0.4, -4.0, -1.6),
                floorRect(0.4, 1.0, -4.0, -1.6),
                floorRect(-0.4, 0.4, -2.1, -1.6),
                floorRect(-0.4, 0.4, -2.9, -2.1, kind: .lava),
                floorRect(-0.4, 0.4, -4.0, -2.9),
            ],
            wallLoops: [rectLoop(-1.0, 1.0, -4.0, 0.5)],
            obstacles: [
                .gate(center: SIMD2(-0.7, -1.9), size: SIMD2(0.5, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .gate(center: SIMD2(0.7, -1.9), size: SIMD2(0.5, 0.09), yaw: 0,
                      period: 2.4, phase: .pi, baseY: 0),
                .rotor(center: SIMD2(-0.7, -2.9), length: 0.36, speed: 1.6, baseY: 0),
                .rotor(center: SIMD2(0.7, -2.9), length: 0.36, speed: -1.6, baseY: 0),
            ],
            bonusStar: SIMD2(0, -1.85),
            cameraZoom: 1.55
        ),
        // 12 — the summit: lava bridge, guardian pendulum and a moving guard
        //      on the crater rim.
        LevelDefinition(
            course: .volcano, number: 12, name: String(localized: "Heart of the Volcano"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.7), holeY: 0.16,
            floors: [
                floorRect(-0.5, 0.5, -1.4, 0.5),
                floorRect(-0.5, -0.14, -2.2, -1.4, kind: .lava),
                floorRect(-0.14, 0.14, -2.2, -1.4),
                floorRect(0.14, 0.5, -2.2, -1.4, kind: .lava),
                floorRect(-0.9, 0.9, -3.4, -2.2),
                floorRect(-0.9, -0.2, -3.3, -2.9, kind: .mud),
                floorRect(-0.45, 0.45, -5.0, -3.9, y: 0.16),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -2.2),
                wall(0.5, -2.2, 0.9, -2.2),
                wall(0.9, -2.2, 0.9, -3.4),
                wall(0.9, -3.4, 0.45, -3.4),
                wall(0.45, -3.4, 0.45, -5.0, height: 0.3),
                wall(0.45, -5.0, -0.45, -5.0, height: 0.3),
                wall(-0.45, -5.0, -0.45, -3.4, height: 0.3),
                wall(-0.45, -3.4, -0.9, -3.4),
                wall(-0.9, -3.4, -0.9, -2.2),
                wall(-0.9, -2.2, -0.5, -2.2),
                wall(-0.5, -2.2, -0.5, 0.5),
            ],
            obstacles: [
                .pendulum(center: SIMD2(0, -2.6), span: 0.7, arc: 0.6, speed: 1.8,
                          yaw: 0, baseY: 0),
                .ramp(center: SIMD2(0, -3.65), width: 0.9, length: 0.5, rise: 0.16, yaw: 0),
                .movingBlock(center: SIMD2(0, -4.4), axis: SIMD2(1, 0), amplitude: 0.16,
                             speed: 1.8, size: SIMD2(0.28, 0.12), baseY: 0.16),
            ],
            bonusStar: SIMD2(-0.75, -3.15),
            cameraZoom: 1.6
        ),
    ]
}
