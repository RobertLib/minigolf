//
//  CosmosLevels.swift
//  Minigolf
//
//  Orbital Station — the last world. Vertical loops that only a firm putt will
//  carry, tractor beams that bend every line, mass drivers and the void.
//

import Foundation
import simd

enum CosmosCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a quiet arrival, with one accelerator plate.
        LevelDefinition(
            course: .cosmos, number: 1, name: String(localized: "Docking Bay"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.7),
            floors: [floorRect(-0.5, 0.5, -3.2, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.2, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -1.4), direction: SIMD2(0, -1), boost: 0.9, y: 0),
                // A service rover crossing the bay on its rounds.
                critter(.rover, at: SIMD2(0, -2.1),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 0.8),
            ],
            bonusStar: SIMD2(0.34, -2.95)
        ),
        // 2 — the accelerator gives you the speed the loop needs. Come in short
        //     and the ball simply rolls back out of the mouth.
        LevelDefinition(
            course: .cosmos, number: 2, name: String(localized: "First Loop"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.1),
            floors: [floorRect(-0.5, 0.5, -3.6, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -3.6, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -1.0), direction: SIMD2(0, -1), boost: 1.5, y: 0),
                .block(center: SIMD2(-0.31, -1.9), size: SIMD3(0.38, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.31, -1.9), size: SIMD3(0.38, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -1.9), radius: 0.19, width: 0.17, yaw: 0, y: 0),
            ],
            bonusStar: SIMD2(0.34, -3.35),
            cameraZoom: 1.15
        ),
        // 3 — the beam pulls everything toward its core.
        LevelDefinition(
            course: .cosmos, number: 3, name: String(localized: "Tractor Beam"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.5, -2.95),
            floors: [floorRect(-0.8, 0.8, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.8, 0.8, -3.4, 0.5)],
            obstacles: [
                .magnet(center: SIMD2(0, -1.8), radius: 0.55, strength: 2.2, y: 0),
                // A little green passenger drifting about outside the beam.
                critter(.alien, at: SIMD2(0, -0.85),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.9),
            ],
            bonusStar: SIMD2(-0.62, -3.15),
            cameraZoom: 1.2
        ),
        // 4 — through the loop first, then wait for the hatch.
        LevelDefinition(
            course: .cosmos, number: 4, name: String(localized: "Airlock"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.7),
            floors: [floorRect(-0.5, 0.5, -4.2, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -4.2, 0.5)],
            obstacles: [
                .block(center: SIMD2(-0.31, -1.9), size: SIMD3(0.38, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.31, -1.9), size: SIMD3(0.38, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -1.9), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                .gate(center: SIMD2(0, -3.0), size: SIMD2(0.5, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.34, -3.95),
            cameraZoom: 1.3
        ),
        // 5 — the same coils, wired the other way round.
        LevelDefinition(
            course: .cosmos, number: 5, name: String(localized: "Repulsor"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.2),
            floors: [floorRect(-0.9, 0.9, -3.6, 0.5)],
            wallLoops: [rectLoop(-0.9, 0.9, -3.6, 0.5)],
            obstacles: [
                .magnet(center: SIMD2(-0.38, -1.6), radius: 0.45, strength: -2.4, y: 0),
                .magnet(center: SIMD2(0.38, -2.5), radius: 0.45, strength: -2.4, y: 0),
                critter(.alien, at: SIMD2(0, -2.9),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1),
            ],
            bonusStar: SIMD2(0.72, -1.4),
            cameraZoom: 1.25
        ),
        // 6 — the ring drags the ball off its line right before the loop.
        LevelDefinition(
            course: .cosmos, number: 6, name: String(localized: "Centrifuge"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.62),
            floors: [floorRect(-0.85, 0.85, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.85, 0.85, -4.0, 0.5)],
            obstacles: [
                .turntable(center: SIMD2(0, -1.6), radius: 0.6, speed: 1.4, y: 0),
                .loop(center: SIMD2(0, -2.9), radius: 0.19, width: 0.17, yaw: 0, y: 0),
            ],
            bonusStar: SIMD2(-0.68, -3.85),
            cameraZoom: 1.35
        ),
        // 7 — the driver fires hard enough to carry the loop on its own.
        LevelDefinition(
            course: .cosmos, number: 7, name: String(localized: "Mass Driver"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-2.3, -2.35),
            floors: [
                floorRect(-0.5, 0.5, -1.8, 0.5),
                floorRect(-2.6, 0.5, -2.8, -1.8),
            ],
            wallLoops: [[
                SIMD2(0.5, 0.5), SIMD2(0.5, -2.8), SIMD2(-2.6, -2.8),
                SIMD2(-2.6, -1.8), SIMD2(-0.5, -1.8), SIMD2(-0.5, 0.5),
            ]],
            obstacles: [
                .cannon(center: SIMD2(0, -2.3), direction: SIMD2(-1, 0), speed: 3.4, y: 0),
                .loop(center: SIMD2(-1.0, -2.3), radius: 0.2, width: 0.17, yaw: deg(90), y: 0),
            ],
            bonusStar: SIMD2(0.32, -2.6),
            cameraZoom: 1.5
        ),
        // 8 — frictionless plating between two coils of opposite sign.
        LevelDefinition(
            course: .cosmos, number: 8, name: String(localized: "Zero-G Deck"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.35),
            floors: [
                floorRect(-0.8, 0.8, -3.8, 0.5),
                floorRect(-0.8, 0.8, -2.8, -1.2, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.8, 0.8, -3.8, 0.5)],
            obstacles: [
                .magnet(center: SIMD2(-0.45, -2.0), radius: 0.5, strength: 1.8, y: 0),
                .magnet(center: SIMD2(0.45, -2.0), radius: 0.5, strength: -1.8, y: 0),
            ],
            bonusStar: SIMD2(0.62, -1.0),
            cameraZoom: 1.25
        ),
        // 9 — nothing under the gap but stars.
        LevelDefinition(
            course: .cosmos, number: 9, name: String(localized: "Asteroid Gap"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.3),
            floors: [
                floorRect(-0.5, 0.5, -1.5, 0.5),
                floorRect(-0.5, 0.5, -2.35, -1.5, kind: .water),
                floorRect(-0.5, 0.5, -3.6, -2.35),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.6, 0.5)],
            obstacles: [
                .launchPad(center: SIMD2(0, -1.3), direction: SIMD2(0, -1), speed: 3.2,
                           lift: 1.75, y: 0),
                .bumper(center: SIMD2(0.28, -2.9), radius: 0.06),
                .post(center: SIMD2(-0.3, -3.1), radius: 0.04),
            ],
            bonusStar: SIMD2(0.36, -3.5),
            cameraZoom: 1.2
        ),
        // 10 — the portal hands the ball over with its speed intact; the plate
        //      tops it up, and the loop takes the rest.
        LevelDefinition(
            course: .cosmos, number: 10, name: String(localized: "Wormhole"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.4, -3.72),
            floors: [
                floorRect(-0.5, 0.5, -2.6, 0.5),
                floorRect(0.9, 1.9, -4.0, -1.2),
            ],
            wallLoops: [
                rectLoop(-0.5, 0.5, -2.6, 0.5),
                rectLoop(0.9, 1.9, -4.0, -1.2),
            ],
            obstacles: [
                .teleporter(a: SIMD2(0, -2.1), b: SIMD2(1.4, -1.7), radius: 0.1, y: 0),
                .boostPad(center: SIMD2(1.4, -2.25), direction: SIMD2(0, -1), boost: 1.4, y: 0),
                .loop(center: SIMD2(1.4, -3.0), radius: 0.19, width: 0.17, yaw: 0, y: 0),
            ],
            bonusStar: SIMD2(-0.34, -2.4),
            cameraZoom: 1.55
        ),
        // 11 — a ring of decking around the core, and the core pulls.
        LevelDefinition(
            course: .cosmos, number: 11, name: String(localized: "Reactor Core"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-0.6, 0.6, -1.6, 0.5),
                floorRect(-1.4, -0.45, -3.6, -1.6),
                floorRect(0.45, 1.4, -3.6, -1.6),
                floorRect(-0.45, 0.45, -2.2, -1.6),
                floorRect(-0.45, 0.45, -3.6, -3.0),
                floorRect(-0.45, 0.45, -3.0, -2.2, kind: .lava),
                floorRect(-1.4, 1.4, -4.4, -3.6),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -1.6), SIMD2(1.4, -1.6),
                SIMD2(1.4, -4.4), SIMD2(-1.4, -4.4), SIMD2(-1.4, -1.6),
                SIMD2(-0.6, -1.6), SIMD2(-0.6, 0.5),
            ]],
            obstacles: [
                .magnet(center: SIMD2(0, -2.6), radius: 0.8, strength: 2.0, y: 0),
                .loop(center: SIMD2(0.92, -2.6), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                .gate(center: SIMD2(-0.92, -2.6), size: SIMD2(0.72, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                // Working the gated deck: past the hatch is not past everything.
                critter(.rover, at: SIMD2(-0.92, -3.2),
                        .patrol(axis: acrossLane, amplitude: 0.2), speed: 0.9),
            ],
            bonusStar: SIMD2(-1.15, -2.0),
            cameraZoom: 1.5
        ),
        // 12 — loop, driver, kicker, void. Everything the station has.
        LevelDefinition(
            course: .cosmos, number: 12, name: String(localized: "Event Horizon"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.2, -4.3),
            floors: [
                floorRect(-0.55, 0.55, -1.6, 0.5),
                floorRect(-1.6, 0.55, -2.7, -1.6),
                floorRect(-1.6, 0.55, -3.5, -2.7, kind: .water),
                floorRect(-1.6, 0.55, -4.6, -3.5),
            ],
            wallLoops: [[
                SIMD2(0.55, 0.5), SIMD2(0.55, -4.6), SIMD2(-1.6, -4.6),
                SIMD2(-1.6, -1.6), SIMD2(-0.55, -1.6), SIMD2(-0.55, 0.5),
            ]],
            obstacles: [
                .loop(center: SIMD2(0, -1.15), radius: 0.2, width: 0.17, yaw: 0, y: 0),
                .cannon(center: SIMD2(-1.15, -2.05), direction: SIMD2(0, -1), speed: 3.4, y: 0),
                .launchPad(center: SIMD2(-1.15, -2.55), direction: SIMD2(0, -1), speed: 3.2,
                           lift: 1.8, y: 0),
                .magnet(center: SIMD2(-0.55, -4.05), radius: 0.5, strength: -2.0, y: 0),
                critter(.alien, at: SIMD2(-0.4, -2.3),
                        .patrol(axis: alongLane, amplitude: 0.2), speed: 0.8),
            ],
            bonusStar: SIMD2(0.3, -2.3),
            cameraZoom: 1.55
        ),
    ]
}
