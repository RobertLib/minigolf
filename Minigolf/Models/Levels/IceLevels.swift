//
//  IceLevels.swift
//  Minigolf
//
//  Frozen Fjord — the world of slick ice patches, drifting floes, banked snow
//  and freezing water. Ice barely slows the ball down, so every putt here is
//  about how little power you can get away with.
//

import Foundation
import simd

enum IceCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one frozen strip in an otherwise plain lane.
        LevelDefinition(
            course: .ice, number: 1, name: String(localized: "First Frost"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.6),
            floors: [
                floorRect(-0.5, 0.5, -3.0, 0.5),
                floorRect(-0.5, 0.5, -1.8, -1.0, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.0, 0.5)],
            // A snowman sliding about on the frozen strip. He is soft, so a putt
            // that clips him is nudged off line rather than sent back.
            obstacles: [
                critter(.snowman, at: SIMD2(0, -1.4),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 1.2),
            ],
            bonusStar: SIMD2(0.36, -2.8)
        ),
        // 2 — posts on a frozen lane: no braking, only aiming.
        LevelDefinition(
            course: .ice, number: 2, name: String(localized: "Slippery Slalom"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0),
            floors: [
                floorRect(-0.55, 0.55, -3.4, 0.5),
                floorRect(-0.55, 0.55, -2.6, -1.0, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.4, 0.5)],
            obstacles: [
                // Waddling across in front of the slalom, before the ice starts.
                critter(.penguin, at: SIMD2(0, -0.75),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
                .post(center: SIMD2(-0.2, -1.5), radius: 0.045),
                .post(center: SIMD2(0.22, -2.1), radius: 0.045),
                .post(center: SIMD2(-0.2, -2.5), radius: 0.045),
            ],
            bonusStar: SIMD2(0.42, -3.2)
        ),
        // 3 — two floes drift across the channel.
        LevelDefinition(
            course: .ice, number: 3, name: String(localized: "Iceberg Alley"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.2),
            floors: [
                floorRect(-0.6, 0.6, -3.6, 0.5),
                floorRect(-0.6, 0.6, -2.2, -1.8, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -3.6, 0.5)],
            obstacles: [
                .movingBlock(center: SIMD2(0, -1.5), axis: SIMD2(1, 0), amplitude: 0.34,
                             speed: 1.2, size: SIMD2(0.4, 0.12), baseY: 0),
                .movingBlock(center: SIMD2(0, -2.5), axis: SIMD2(1, 0), amplitude: 0.34,
                             speed: -1.5, size: SIMD2(0.4, 0.12), baseY: 0),
            ],
            bonusStar: SIMD2(-0.45, -2.35),
            cameraZoom: 1.2
        ),
        // 4 — a single icy plank across the crevasse.
        LevelDefinition(
            course: .ice, number: 4, name: String(localized: "The Crevasse"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0),
            floors: [
                floorRect(-0.55, 0.55, -1.4, 0.5),
                floorRect(-0.55, -0.13, -2.2, -1.4, kind: .water),
                floorRect(-0.13, 0.13, -2.2, -1.4),
                floorRect(-0.13, 0.13, -2.2, -1.4, kind: .ice),
                floorRect(0.13, 0.55, -2.2, -1.4, kind: .water),
                floorRect(-0.55, 0.55, -3.4, -2.2),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.4, 0.5)],
            bonusStar: SIMD2(0.4, -1.0),
            cameraZoom: 1.15
        ),
        // 5 — the whole frozen shelf leans to the left.
        LevelDefinition(
            course: .ice, number: 5, name: String(localized: "Blue Drift"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.35, -3.05),
            floors: [
                floorRect(-0.7, 0.7, -3.5, 0.5),
                floorRect(-0.7, 0.7, -2.6, -1.2, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -3.5, 0.5)],
            obstacles: [
                .slope(rect: zone(-0.7, 0.7, -2.6, -1.2), direction: SIMD2(-1, 0),
                       strength: 0.9, y: 0),
                // Sliding along the banked shelf, across the drift.
                critter(.snowman, at: SIMD2(0, -1.9),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.0),
            ],
            bonusStar: SIMD2(-0.55, -2.9),
            cameraZoom: 1.25
        ),
        // 6 — ice between two gates: stopping is not an option.
        LevelDefinition(
            course: .ice, number: 6, name: String(localized: "Frozen Gates"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.8),
            floors: [
                floorRect(-0.6, 0.6, -4.2, 0.5),
                floorRect(-0.6, 0.6, -2.4, -1.9, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -4.2, 0.5)],
            obstacles: [
                .gate(center: SIMD2(0, -1.6), size: SIMD2(0.7, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .gate(center: SIMD2(0, -2.8), size: SIMD2(0.7, 0.09), yaw: 0,
                      period: 2.4, phase: .pi, baseY: 0),
            ],
            bonusStar: SIMD2(0.45, -2.35),
            cameraZoom: 1.35
        ),
        // 7 — deep snow on one side, bare ice on the other: pick your poison.
        LevelDefinition(
            course: .ice, number: 7, name: String(localized: "Snow Bank"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0),
            floors: [
                floorRect(-0.5, 0.5, -3.4, 0.5),
                floorRect(-0.5, 0.0, -2.3, -1.5, kind: .sand),
                floorRect(0.0, 0.5, -2.3, -1.5, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -1.1), width: 1.0, height: 0.035, yaw: 0),
                // Pacing the run-out on the fast side, guarding the cup.
                critter(.penguin, at: SIMD2(0.3, -2.65),
                        .patrol(axis: alongLane, amplitude: 0.2), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.38, -1.9)
        ),
        // 8 — up the glacier ramp onto a frozen shelf.
        LevelDefinition(
            course: .ice, number: 8, name: String(localized: "Glacier Ramp"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -2.0, 0.5),
                floorRect(-0.5, 0.5, -4.0, -2.7, y: 0.13),
                floorRect(-0.5, 0.5, -3.3, -2.7, kind: .ice, y: 0.13),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -2.0),
                wall(0.5, -2.0, 0.5, -4.0, height: 0.26),
                wall(0.5, -4.0, -0.5, -4.0, height: 0.26),
                wall(-0.5, -4.0, -0.5, -2.0, height: 0.26),
                wall(-0.5, -2.0, -0.5, 0.5),
            ],
            obstacles: [.ramp(center: SIMD2(0, -2.35), width: 1.0, length: 0.7, rise: 0.13, yaw: 0)],
            bonusStar: SIMD2(0.36, -3.9), bonusStarY: 0.13,
            cameraZoom: 1.3
        ),
        // 9 — two offset planks over the fjord.
        LevelDefinition(
            course: .ice, number: 9, name: String(localized: "Twin Floes"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.85),
            floors: [
                floorRect(-0.7, 0.7, -1.2, 0.5),
                floorRect(-0.7, -0.5, -2.0, -1.2, kind: .water),
                floorRect(-0.5, -0.2, -2.0, -1.2),
                floorRect(-0.5, -0.2, -2.0, -1.2, kind: .ice),
                floorRect(-0.2, 0.7, -2.0, -1.2, kind: .water),
                floorRect(-0.7, 0.7, -2.5, -2.0),
                floorRect(-0.7, 0.25, -3.3, -2.5, kind: .water),
                floorRect(0.25, 0.55, -3.3, -2.5),
                floorRect(0.25, 0.55, -3.3, -2.5, kind: .ice),
                floorRect(0.55, 0.7, -3.3, -2.5, kind: .water),
                floorRect(-0.7, 0.7, -4.2, -3.3),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.2, 0.5)],
            // The landing floe is already the only safe ground between the two
            // planks; a penguin patrolling it makes the stop worth aiming.
            obstacles: [
                critter(.penguin, at: SIMD2(0, -2.25),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.3),
            ],
            bonusStar: SIMD2(0.55, -2.25),
            cameraZoom: 1.4
        ),
        // 10 — a snow slide throws you across the arena.
        LevelDefinition(
            course: .ice, number: 10, name: String(localized: "Avalanche"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-0.8, 0.8, -4.0, 0.5),
                floorRect(-0.8, 0.8, -3.6, -3.0, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.8, 0.8, -4.0, 0.5)],
            obstacles: [
                .conveyor(rect: zone(-0.8, 0.8, -2.4, -1.8), direction: SIMD2(1, 0),
                          strength: 2.0, y: 0),
                .bumper(center: SIMD2(0.5, -2.9), radius: 0.07),
                .bumper(center: SIMD2(-0.45, -3.1), radius: 0.07),
            ],
            bonusStar: SIMD2(0.68, -2.1),
            cameraZoom: 1.4
        ),
        // 11 — the ice tips toward open water.
        LevelDefinition(
            course: .ice, number: 11, name: String(localized: "Frostbite Bank"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.5, -3.3),
            floors: [
                floorRect(-0.9, 0.5, -3.8, 0.5),
                floorRect(0.5, 0.9, -1.4, 0.5),
                floorRect(0.5, 0.9, -3.8, -3.0),
                floorRect(0.5, 0.9, -3.0, -1.4, kind: .water),
                floorRect(-0.9, 0.5, -2.6, -1.6, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.9, 0.9, -3.8, 0.5)],
            obstacles: [
                .slope(rect: zone(-0.9, 0.5, -2.6, -1.6), direction: SIMD2(1, 0),
                       strength: 0.9, y: 0),
            ],
            bonusStar: SIMD2(0.2, -3.5),
            cameraZoom: 1.35
        ),
        // 12 — the whole fjord: gate, floe, banked ice and a frozen summit.
        LevelDefinition(
            course: .ice, number: 12, name: String(localized: "Northern Lights"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.5), holeY: 0.13,
            floors: [
                floorRect(-0.5, 0.5, -1.5, 0.5),
                floorRect(-1.0, 1.0, -3.0, -1.5),
                floorRect(-1.0, 1.0, -2.6, -2.0, kind: .ice),
                floorRect(-0.45, 0.45, -4.8, -3.6, y: 0.13),
            ],
            extraWalls: [
                wall(-0.5, 0.5, 0.5, 0.5),
                wall(0.5, 0.5, 0.5, -1.5),
                wall(0.5, -1.5, 1.0, -1.5),
                wall(1.0, -1.5, 1.0, -3.0),
                wall(1.0, -3.0, 0.45, -3.0),
                wall(0.45, -3.0, 0.45, -4.8, height: 0.26),
                wall(0.45, -4.8, -0.45, -4.8, height: 0.26),
                wall(-0.45, -4.8, -0.45, -3.0, height: 0.26),
                wall(-0.45, -3.0, -1.0, -3.0),
                wall(-1.0, -3.0, -1.0, -1.5),
                wall(-1.0, -1.5, -0.5, -1.5),
                wall(-0.5, -1.5, -0.5, 0.5),
            ],
            obstacles: [
                .gate(center: SIMD2(0, -1.1), size: SIMD2(0.6, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                .movingBlock(center: SIMD2(0, -2.3), axis: SIMD2(1, 0), amplitude: 0.45,
                             speed: 1.4, size: SIMD2(0.45, 0.12), baseY: 0),
                // Banks the frozen shelf itself, the way holes 5 and 11 do. On
                // the strip below it the drift only shoved the ball off line in
                // the last few centimetres before the ramp mouth.
                .slope(rect: zone(-1.0, 1.0, -2.6, -2.0), direction: SIMD2(-1, 0),
                       strength: 0.8, y: 0),
                critter(.snowman, at: SIMD2(-0.75, -1.75),
                        .patrol(axis: acrossLane, amplitude: 0.15), speed: 0.9),
                .ramp(center: SIMD2(0, -3.3), width: 0.9, length: 0.6, rise: 0.13, yaw: 0),
                .movingBlock(center: SIMD2(0, -4.2), axis: SIMD2(1, 0), amplitude: 0.16,
                             speed: 1.7, size: SIMD2(0.28, 0.12), baseY: 0.13),
            ],
            bonusStar: SIMD2(0.85, -2.85),
            cameraZoom: 1.55
        ),
    ]
}
