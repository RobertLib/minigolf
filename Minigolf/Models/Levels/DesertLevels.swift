//
//  DesertLevels.swift
//  Minigolf
//
//  Desert Oasis — sand traps, sliding gate blocks, bumper bazaars, a mesa
//  plateau, water crossings and the first timed iron gates and geysers.
//

import Foundation
import simd

enum DesertCourse {

    static let holes: [LevelDefinition] = [
        // 1 — sand pockets on both flanks.
        LevelDefinition(
            course: .desert, number: 1, name: String(localized: "Warm Sands"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.5),
            floors: [
                floorRect(-0.5, 0.5, -3.0, 0.5),
                floorRect(-0.5, -0.15, -1.8, -1.1, kind: .sand),
                floorRect(0.15, 0.5, -2.6, -1.9, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.0, 0.5)],
            // A meerkat keeping watch from the near sand pocket.
            obstacles: [
                critter(.meerkat, at: SIMD2(-0.33, -1.45), .burrow(period: 3.2)),
            ],
            bonusStar: SIMD2(0.35, -2.3)
        ),
        // 2 — dogleg left between the rocks.
        LevelDefinition(
            course: .desert, number: 2, name: String(localized: "Canyon Turn"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.45, -3.05),
            floors: [
                floorRect(-0.45, 0.45, -2.6, 0.5),
                floorRect(-1.9, 0.45, -3.5, -2.6),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.5), SIMD2(-0.45, -2.6), SIMD2(-1.9, -2.6),
                SIMD2(-1.9, -3.5), SIMD2(0.45, -3.5), SIMD2(0.45, 0.5),
            ]],
            extraWalls: [wall(0.05, -3.48, 0.43, -3.1)],
            obstacles: [
                .post(center: SIMD2(-0.6, -3.0), radius: 0.05),
                .post(center: SIMD2(-1.0, -3.25), radius: 0.05),
            ],
            bonusStar: SIMD2(-1.7, -2.85),
            cameraZoom: 1.15
        ),
        // 3 — a sliding block guards the lane.
        LevelDefinition(
            course: .desert, number: 3, name: String(localized: "The Gatekeeper"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [floorRect(-0.5, 0.5, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            obstacles: [
                .movingBlock(center: SIMD2(0, -1.7), axis: SIMD2(1, 0), amplitude: 0.3,
                             speed: 1.2, size: SIMD2(0.4, 0.12), baseY: 0),
            ],
            bonusStar: SIMD2(0.36, -3.2)
        ),
        // 4 — bounce your way through.
        LevelDefinition(
            course: .desert, number: 4, name: String(localized: "Bazaar Bumpers"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [floorRect(-0.9, 0.9, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.9, 0.9, -3.4, 0.5)],
            obstacles: [
                .bumper(center: SIMD2(0, -1.5), radius: 0.07),
                .bumper(center: SIMD2(-0.45, -2.1), radius: 0.07),
                .bumper(center: SIMD2(0.45, -2.1), radius: 0.07),
            ],
            bonusStar: SIMD2(-0.72, -2.7),
            cameraZoom: 1.2
        ),
        // 5 — angled walls guide you into a needle.
        LevelDefinition(
            course: .desert, number: 5, name: String(localized: "The Funnel"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.85),
            floors: [
                floorRect(-0.9, 0.9, -1.8, 0.5),
                floorRect(-0.25, 0.25, -3.3, -1.8),
            ],
            wallLoops: [[
                SIMD2(0.9, 0.5), SIMD2(0.9, -1.8), SIMD2(0.25, -1.8),
                SIMD2(0.25, -3.3), SIMD2(-0.25, -3.3), SIMD2(-0.25, -1.8),
                SIMD2(-0.9, -1.8), SIMD2(-0.9, 0.5),
            ]],
            extraWalls: [
                wall(0.9, -1.2, 0.25, -1.79),
                wall(-0.9, -1.2, -0.25, -1.79),
            ],
            // On the bank-shot line into the left funnel wall — off the straight
            // lane, but in front of the boards, not in the dead corner behind them.
            bonusStar: SIMD2(-0.6, -1.25),
            cameraZoom: 1.15
        ),
        // 6 — two smooth crests.
        LevelDefinition(
            course: .desert, number: 6, name: String(localized: "Rolling Dunes"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.3),
            floors: [floorRect(-0.45, 0.45, -3.8, 0.5)],
            wallLoops: [rectLoop(-0.45, 0.45, -3.8, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -1.2), width: 0.9, height: 0.04, yaw: 0),
                .bump(center: SIMD2(0, -2.2), width: 0.9, height: 0.04, yaw: 0),
                // Blowing across the trough between the two dunes.
                critter(.tumbleweed, at: SIMD2(0, -1.7),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.3),
            ],
            bonusStar: SIMD2(0.31, -3.6),
            cameraZoom: 1.15
        ),
        // 7 — time your shot past the rotor.
        LevelDefinition(
            course: .desert, number: 7, name: String(localized: "The Sweeper"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.7),
            floors: [floorRect(-0.8, 0.8, -3.2, 0.5)],
            wallLoops: [rectLoop(-0.8, 0.8, -3.2, 0.5)],
            obstacles: [.rotor(center: SIMD2(0, -1.85), length: 1.0, speed: 1.3, baseY: 0)],
            bonusStar: SIMD2(-0.62, -3.0),
            cameraZoom: 1.15
        ),
        // 8 — climb the ramp, then turn right on the plateau.
        LevelDefinition(
            course: .desert, number: 8, name: String(localized: "Mesa"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.1, -3.35), holeY: 0.13,
            floors: [
                floorRect(-0.45, 0.45, -2.3, 0.5),
                floorRect(-0.45, 1.6, -3.7, -3.0, y: 0.13),
            ],
            extraWalls: [
                wall(0.45, 0.5, -0.45, 0.5),
                wall(-0.45, 0.5, -0.45, -2.3),
                wall(-0.45, -2.3, -0.45, -3.7, height: 0.26),
                wall(-0.45, -3.7, 1.6, -3.7, height: 0.26),
                wall(1.6, -3.7, 1.6, -3.0, height: 0.26),
                wall(1.6, -3.0, 0.45, -3.0, height: 0.26),
                wall(0.45, -3.0, 0.45, -2.3, height: 0.26),
                wall(0.45, -2.3, 0.45, 0.5),
            ],
            obstacles: [
                .ramp(center: SIMD2(0, -2.65), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                // Standing sentry on the mesa, right where the plateau turns.
                critter(.meerkat, at: SIMD2(0.5, -3.35), .burrow(period: 2.8),
                        phase: .pi / 2, baseY: 0.13),
            ],
            bonusStar: SIMD2(1.42, -3.5), bonusStarY: 0.13,
            cameraZoom: 1.25
        ),
        // 9 — two water crossings, offset bridges.
        LevelDefinition(
            course: .desert, number: 9, name: String(localized: "The Oasis"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-0.7, 0.7, -1.3, 0.5),
                floorRect(-0.7, -0.55, -2.1, -1.3, kind: .water),
                floorRect(-0.55, -0.27, -2.1, -1.3),
                floorRect(-0.27, 0.27, -2.1, -1.3, kind: .water),
                floorRect(0.27, 0.55, -2.1, -1.3),
                floorRect(0.55, 0.7, -2.1, -1.3, kind: .water),
                floorRect(-0.7, 0.7, -2.5, -2.1),
                floorRect(-0.7, -0.14, -3.3, -2.5, kind: .water),
                floorRect(-0.14, 0.14, -3.3, -2.5),
                floorRect(0.14, 0.7, -3.3, -2.5, kind: .water),
                floorRect(-0.7, 0.7, -4.2, -3.3),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.2, 0.5)],
            bonusStar: SIMD2(0.5, -2.3),
            cameraZoom: 1.3
        ),
        // 10 — two iron gates rising and falling out of phase.
        LevelDefinition(
            course: .desert, number: 10, name: String(localized: "Scarab Gates"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6),
            floors: [floorRect(-0.55, 0.55, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -4.0, 0.5)],
            obstacles: [
                .gate(center: SIMD2(0, -1.5), size: SIMD2(0.66, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .gate(center: SIMD2(0, -2.6), size: SIMD2(0.66, 0.09), yaw: 0,
                      period: 2.6, phase: .pi, baseY: 0),
                .post(center: SIMD2(0, -3.05), radius: 0.045),
            ],
            bonusStar: SIMD2(-0.4, -2.05),
            cameraZoom: 1.25
        ),
        // 11 — geysers kick the ball down a long, sandy lane.
        LevelDefinition(
            course: .desert, number: 11, name: String(localized: "Geyser Run"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.15),
            floors: [
                floorRect(-0.5, 0.5, -4.6, 0.5),
                floorRect(-0.5, 0.5, -2.7, -2.1, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -4.6, 0.5)],
            obstacles: [
                critter(.tumbleweed, at: SIMD2(0, -1.05),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.6),
                .boostPad(center: SIMD2(0, -1.5), direction: SIMD2(0, -1), boost: 1.1, y: 0),
                .boostPad(center: SIMD2(0, -3.2), direction: SIMD2(0, -1), boost: 0.9, y: 0),
                .post(center: SIMD2(-0.24, -3.7), radius: 0.04),
                .post(center: SIMD2(0.24, -3.9), radius: 0.04),
            ],
            bonusStar: SIMD2(0.36, -2.4),
            cameraZoom: 1.35
        ),
        // 12 — everything the desert has to offer.
        LevelDefinition(
            course: .desert, number: 12, name: String(localized: "The Gauntlet"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.15),
            floors: [
                floorRect(-0.5, 0.5, -4.6, 0.5),
                floorRect(-0.5, 0.5, -2.4, -1.9, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -4.6, 0.5)],
            obstacles: [
                .movingBlock(center: SIMD2(0, -1.3), axis: SIMD2(1, 0), amplitude: 0.28,
                             speed: 1.5, size: SIMD2(0.35, 0.12), baseY: 0),
                .bump(center: SIMD2(0, -3.0), width: 1.0, height: 0.035, yaw: 0),
                .movingBlock(center: SIMD2(0, -3.7), axis: SIMD2(1, 0), amplitude: 0.28,
                             speed: 1.9, size: SIMD2(0.35, 0.12), baseY: 0),
                // Last word on the hole: a meerkat popping up beside the cup.
                critter(.meerkat, at: SIMD2(-0.3, -4.4), .burrow(period: 2.4)),
            ],
            bonusStar: SIMD2(0.36, -4.4),
            cameraZoom: 1.3
        ),
    ]
}
