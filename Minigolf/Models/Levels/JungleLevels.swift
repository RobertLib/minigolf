//
//  JungleLevels.swift
//  Minigolf
//
//  Jungle Temple — mud that eats a putt, vines swinging across the lane, rivers
//  that carry the ball sideways and the first stone portals. The temple itself
//  turns up halfway through the world as a raised green, and by the finale the
//  hole has a river, a gorge, a portal pair and a climb in it.
//

import Foundation
import simd

enum JungleCourse {

    static let holes: [LevelDefinition] = [
        // 1 — the mud is the lesson: it does not stop a putt, it eats one. The
        //     frog is here to show that the locals now jump, and that a ball can
        //     be threaded underneath one.
        LevelDefinition(
            course: .jungle, number: 1, name: String(localized: "Temple Steps"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.15),
            floors: [
                floorRect(-0.65, 0.65, -3.7, 0.5),
                floorRect(-0.65, 0.05, -2.05, -1.35, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.65, 0.65, -3.7, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.3, height: 0.03, yaw: 0),
                critter(.frog, at: SIMD2(0, -1.7),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14), speed: 1.0),
                .post(center: SIMD2(-0.28, -2.5), radius: 0.04),
                .post(center: SIMD2(0.28, -2.5), radius: 0.04),
                critter(.turtle, at: SIMD2(0, -2.9),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
            ],
            bonusStar: SIMD2(0.45, -3.45),
            cameraZoom: 1.1
        ),
        // 2 — a vine sweeping the full width of the lane, with a mud belt laid
        //     just past it so a ball that survives the swing still has to arrive
        //     with something left.
        LevelDefinition(
            course: .jungle, number: 2, name: String(localized: "Vine Bridge"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.5),
            floors: [
                floorRect(-0.7, 0.7, -4.0, 0.5),
                floorRect(-0.7, 0.7, -2.5, -2.0, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.4, height: 0.03, yaw: 0),
                critter(.turtle, at: SIMD2(-0.35, -1.15),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.7),
                .pendulum(center: SIMD2(0, -1.6), span: 0.9, arc: 0.7, speed: 1.6,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.3, -2.9), radius: 0.04),
                .post(center: SIMD2(0.3, -2.9), radius: 0.04),
                critter(.frog, at: SIMD2(0, -3.2),
                        .hop(axis: acrossLane, amplitude: 0.28, height: 0.13), speed: 1.1),
            ],
            bonusStar: SIMD2(0.5, -3.8),
            cameraZoom: 1.2
        ),
        // 3 — a stone spine down the middle of the hole and a pair of portals
        //     that ignore it. Round the end is always possible; through the ring
        //     is a stroke shorter.
        LevelDefinition(
            course: .jungle, number: 3, name: String(localized: "Ancient Portals"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.6, -3.8),
            floors: [
                floorRect(-1.1, 1.1, -4.2, 0.5),
                floorRect(0.0, 1.1, -3.0, -2.2, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.1, 1.1, -4.2, 0.5)],
            extraWalls: [wall(0, -1.2, 0, -3.4)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.2, height: 0.03, yaw: 0),
                .teleporter(a: SIMD2(-0.65, -2.2), b: SIMD2(0.65, -1.6), radius: 0.1, y: 0),
                .post(center: SIMD2(0.35, -2.6), radius: 0.04),
                .post(center: SIMD2(0.85, -3.1), radius: 0.04),
                critter(.frog, at: SIMD2(-0.6, -3.4),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14), speed: 1.1),
                critter(.turtle, at: SIMD2(-0.3, -3.95),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.7),
            ],
            bonusStar: SIMD2(-0.9, -4.0),
            cameraZoom: 1.45
        ),
        // 4 — a river runs across the hole. It carries a slow ball clean off its
        //     line, so the crossing has to be taken fast or aimed upstream.
        LevelDefinition(
            course: .jungle, number: 4, name: String(localized: "River Crossing"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.7, -3.7),
            floors: [
                floorRect(-1.2, 1.2, -4.4, 0.5),
                floorRect(-1.2, -0.2, -3.5, -2.9, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.2, 1.2, -4.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.4, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -1.5), radius: 0.04),
                .post(center: SIMD2(0.5, -1.5), radius: 0.04),
                .conveyor(rect: zone(-1.2, 1.2, -2.6, -2.0), direction: SIMD2(1, 0),
                          strength: 3.0, y: 0),
                .bumper(center: SIMD2(1.05, -2.3), radius: 0.06),
                critter(.turtle, at: SIMD2(-0.8, -3.1),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
                .block(center: SIMD2(0.5, -3.4), size: SIMD3(0.5, 0.16, 0.4),
                       yaw: 0, baseY: 0),
                critter(.frog, at: SIMD2(0.4, -4.0),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14), speed: 1.1),
            ],
            bonusStar: SIMD2(1.0, -4.15),
            cameraZoom: 1.5
        ),
        // 5 — the temple itself: a wide court with a vine over it, then a ramp
        //     up onto the terrace where the cup sits between two stone blocks.
        LevelDefinition(
            course: .jungle, number: 5, name: String(localized: "Temple Terrace"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.5), holeY: 0.16,
            floors: [
                floorRect(-1.3, 1.3, -3.0, 0.5),
                floorRect(-1.3, -0.4, -2.4, -1.7, kind: .mud),
                floorRect(-1.1, 1.1, -5.0, -3.6, y: 0.16),
            ],
            extraWalls: [
                wall(-1.3, 0.5, 1.3, 0.5),
                wall(1.3, 0.5, 1.3, -3.0),
                wall(1.3, -3.0, 0.45, -3.0),
                wall(-0.45, -3.0, -1.3, -3.0),
                wall(-1.3, -3.0, -1.3, 0.5),
                wall(-1.1, -3.6, -0.45, -3.6, height: 0.3),
                wall(0.45, -3.6, 1.1, -3.6, height: 0.3),
                wall(1.1, -3.6, 1.1, -5.0, height: 0.3),
                wall(1.1, -5.0, -1.1, -5.0, height: 0.3),
                wall(-1.1, -5.0, -1.1, -3.6, height: 0.3),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.6, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -1.6), span: 1.0, arc: 0.75, speed: 1.5,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.5, -2.3), radius: 0.04),
                .post(center: SIMD2(0.5, -2.3), radius: 0.04),
                critter(.turtle, at: SIMD2(0, -2.6),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.8),
                .ramp(center: SIMD2(0, -3.3), width: 0.9, length: 0.6, rise: 0.16, yaw: 0),
                .block(center: SIMD2(-0.7, -4.2), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.16),
                .block(center: SIMD2(0.7, -4.2), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.16),
                critter(.frog, at: SIMD2(0, -4.85),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14),
                        speed: 1.1, baseY: 0.16),
            ],
            bonusStar: SIMD2(1.15, -2.6),
            cameraZoom: 1.65
        ),
        // 6 — three vines in a row, swinging at different rates. There is a
        //     moment when all three are clear; there is also a way to play it
        //     one vine at a time.
        LevelDefinition(
            course: .jungle, number: 6, name: String(localized: "Swinging Vines"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.5),
            floors: [
                floorRect(-0.9, 0.9, -5.0, 0.5),
                floorRect(-0.9, 0.9, -3.2, -2.9, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.9, 0.9, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.8, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -1.5), span: 1.1, arc: 0.7, speed: 1.4,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.55, -2.05), radius: 0.04),
                .pendulum(center: SIMD2(0, -2.6), span: 1.1, arc: 0.7, speed: -1.7,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(0.55, -3.15), radius: 0.04),
                .pendulum(center: SIMD2(0, -3.7), span: 1.1, arc: 0.7, speed: 1.9,
                          yaw: 0, baseY: 0),
                critter(.turtle, at: SIMD2(-0.5, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
                critter(.frog, at: SIMD2(0, -4.85),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14), speed: 1.2),
            ],
            bonusStar: SIMD2(0.7, -4.8),
            cameraZoom: 1.45
        ),
        // 7 — the gorge. One plank across it, and the plank is banked: a ball
        //     left to roll gently over drifts off the side of it.
        LevelDefinition(
            course: .jungle, number: 7, name: String(localized: "Rope Bridge"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.8, -4.4),
            floors: [
                floorRect(-1.4, 1.4, -1.8, 0.5),
                floorRect(-1.4, -0.22, -3.4, -1.8, kind: .water),
                floorRect(-0.22, 0.22, -3.4, -1.8),
                floorRect(0.22, 1.4, -3.4, -1.8, kind: .water),
                floorRect(-1.4, 1.4, -5.0, -3.4),
            ],
            wallLoops: [rectLoop(-1.4, 1.4, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.45, -1.3), radius: 0.04),
                .post(center: SIMD2(0.45, -1.3), radius: 0.04),
                .slope(rect: zone(-0.22, 0.22, -3.4, -1.8), direction: SIMD2(1, 0),
                       strength: 0.8, y: 0),
                .pendulum(center: SIMD2(0, -2.6), span: 0.8, arc: 0.5, speed: 1.6,
                          yaw: 0, baseY: 0),
                critter(.turtle, at: SIMD2(0, -3.9),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.8),
                .bumper(center: SIMD2(1.1, -4.0), radius: 0.06),
                .block(center: SIMD2(0.6, -4.6), size: SIMD3(0.5, 0.16, 0.35),
                       yaw: 0, baseY: 0),
                critter(.frog, at: SIMD2(-1.0, -4.7),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.14), speed: 1.1),
            ],
            bonusStar: SIMD2(1.25, -4.7),
            cameraZoom: 1.65
        ),
        // 8 — two portal pairs and two long stone spines. Every route through
        //     here is a ring; the question is which one lands you on the right
        //     side of the last block.
        LevelDefinition(
            course: .jungle, number: 8, name: String(localized: "Twin Portals"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.25, -4.85),
            floors: [
                floorRect(-1.5, 1.5, -5.2, 0.5),
                floorRect(0.5, 1.5, -2.0, -1.2, kind: .mud),
                floorRect(-1.5, -0.5, -3.4, -2.4, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.5, 1.5, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.0, height: 0.03, yaw: 0),
                .teleporter(a: SIMD2(-1.05, -1.6), b: SIMD2(1.05, -3.6), radius: 0.1, y: 0),
                .post(center: SIMD2(0, -2.0), radius: 0.04),
                .block(center: SIMD2(-0.55, -2.4), size: SIMD3(0.22, 0.16, 2.0),
                       yaw: 0, baseY: 0),
                .teleporter(a: SIMD2(1.05, -1.6), b: SIMD2(0, -4.4), radius: 0.1, y: 0),
                critter(.frog, at: SIMD2(0, -3.0),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.15), speed: 1.1),
                .block(center: SIMD2(0.55, -3.2), size: SIMD3(0.22, 0.16, 2.0),
                       yaw: 0, baseY: 0),
                critter(.turtle, at: SIMD2(-1.0, -4.4),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 0.8),
                .bumper(center: SIMD2(1.25, -4.8), radius: 0.06),
            ],
            bonusStar: SIMD2(1.3, -2.6),
            cameraZoom: 1.75
        ),
        // 9 — the mud is on both flanks and the clean channel down the middle is
        //     swept by a bar, then a block, then a vine. Wide is slow, straight
        //     is timed.
        LevelDefinition(
            course: .jungle, number: 9, name: String(localized: "Mud Pit"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.9, -4.85),
            floors: [
                floorRect(-1.55, 1.55, -5.3, 0.5),
                floorRect(-1.55, -0.35, -3.6, -1.6, kind: .mud),
                floorRect(0.35, 1.55, -3.6, -1.6, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.55, 1.55, -5.3, 0.5)],
            obstacles: [
                .pendulum(center: SIMD2(0, -1.2), span: 1.2, arc: 0.7, speed: 1.5,
                          yaw: 0, baseY: 0),
                .bump(center: SIMD2(0, -0.8), width: 3.1, height: 0.03, yaw: 0),
                .rotor(center: SIMD2(0, -2.0), length: 0.9, speed: 1.5, baseY: 0),
                critter(.turtle, at: SIMD2(-1.1, -2.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
                critter(.frog, at: SIMD2(1.1, -2.6),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.15), speed: 1.1),
                .movingBlock(center: SIMD2(0, -2.9), axis: acrossLane, amplitude: 0.55,
                             speed: 1.1, size: SIMD2(0.4, 0.2), baseY: 0),
                .post(center: SIMD2(-0.6, -3.9), radius: 0.04),
                .post(center: SIMD2(0.6, -3.9), radius: 0.04),
                .bumper(center: SIMD2(0, -4.3), radius: 0.06),
                .block(center: SIMD2(-1.0, -4.7), size: SIMD3(0.5, 0.16, 0.4),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-1.35, -4.9),
            cameraZoom: 1.8
        ),
        // 10 — a long dogleg with a river running the wrong way across the turn
        //      and the outer corner banked to catch what the river takes.
        LevelDefinition(
            course: .jungle, number: 10, name: String(localized: "Jaguar Run"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.6, -4.6),
            floors: [
                floorRect(-0.6, 0.6, -2.2, 0.5),
                floorRect(-2.2, 1.0, -3.4, -2.2),
                floorRect(-2.2, -1.0, -5.0, -3.4),
                floorRect(-2.2, -1.0, -4.3, -3.6, kind: .mud),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -2.2), SIMD2(1.0, -2.2),
                SIMD2(1.0, -3.4), SIMD2(-1.0, -3.4), SIMD2(-1.0, -5.0),
                SIMD2(-2.2, -5.0), SIMD2(-2.2, -2.2), SIMD2(-0.6, -2.2),
                SIMD2(-0.6, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-1.65, -2.75), radius: 0.55,
                                from: deg(90), to: deg(180), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.2, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -1.6), span: 1.0, arc: 0.7, speed: 1.6,
                          yaw: 0, baseY: 0),
                .conveyor(rect: zone(-2.2, 1.0, -3.0, -2.6), direction: SIMD2(-1, 0),
                          strength: 2.5, y: 0),
                .bumper(center: SIMD2(0.75, -2.6), radius: 0.06),
                critter(.turtle, at: SIMD2(-0.4, -2.8),
                        .patrol(axis: alongLane, amplitude: 0.25), speed: 0.8),
                .post(center: SIMD2(-1.35, -3.8), radius: 0.04),
                critter(.frog, at: SIMD2(-1.9, -4.0),
                        .hop(axis: alongLane, amplitude: 0.3, height: 0.15), speed: 1.1),
                .block(center: SIMD2(-1.2, -4.4), size: SIMD3(0.3, 0.16, 0.5),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(-1.85, -4.75), radius: 0.04),
            ],
            bonusStar: SIMD2(0.8, -3.15),
            cameraZoom: 1.8
        ),
        // 11 — the stair. The ramp is off to one side, so the climb has to be
        //      set up from the far corner of the court rather than driven at.
        LevelDefinition(
            course: .jungle, number: 11, name: String(localized: "Serpent Stair"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.6, -5.1), holeY: 0.18,
            floors: [
                floorRect(-1.6, 1.6, -3.6, 0.5),
                floorRect(-1.6, -0.6, -3.5, -2.7, kind: .mud),
                floorRect(-1.2, 1.2, -5.6, -4.3, y: 0.18),
            ],
            extraWalls: [
                wall(-1.6, 0.5, 1.6, 0.5),
                wall(1.6, 0.5, 1.6, -3.6),
                wall(1.6, -3.6, 1.2, -3.6),
                wall(0.5, -3.6, -1.6, -3.6),
                wall(-1.6, -3.6, -1.6, 0.5),
                wall(-1.2, -4.3, 0.5, -4.3, height: 0.32),
                wall(1.2, -4.3, 1.2, -5.6, height: 0.32),
                wall(1.2, -5.6, -1.2, -5.6, height: 0.32),
                wall(-1.2, -5.6, -1.2, -4.3, height: 0.32),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.2, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(-0.5, -1.5), span: 1.2, arc: 0.75, speed: 1.5,
                          yaw: 0, baseY: 0),
                .teleporter(a: SIMD2(-1.3, -2.4), b: SIMD2(1.3, -1.2), radius: 0.1, y: 0),
                .bumper(center: SIMD2(0, -2.4), radius: 0.06),
                .post(center: SIMD2(-1.2, -3.0), radius: 0.04),
                critter(.turtle, at: SIMD2(0.6, -2.9),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 0.8),
                .ramp(center: SIMD2(0.85, -3.95), width: 0.7, length: 0.7, rise: 0.18, yaw: 0),
                .block(center: SIMD2(0.6, -4.9), size: SIMD3(0.4, 0.14, 0.6),
                       yaw: 0, baseY: 0.18),
                critter(.frog, at: SIMD2(0, -5.35),
                        .hop(axis: acrossLane, amplitude: 0.3, height: 0.15),
                        speed: 1.1, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.4, -3.35),
            cameraZoom: 1.9
        ),
        // 12 — the lost temple. A vine at the gate, shoulders into the court, a
        //      river across it, the gorge with one plank, a portal pair on the
        //      far bank and the last climb to the altar.
        LevelDefinition(
            course: .jungle, number: 12, name: String(localized: "Lost Temple"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.55), holeY: 0.18,
            floors: [
                floorRect(-0.7, 0.7, -1.7, 0.5),
                floorRect(-1.8, 1.8, -3.0, -1.7),
                floorRect(-1.8, -0.9, -2.2, -1.75, kind: .mud),
                floorRect(-1.8, -0.25, -3.9, -3.0, kind: .water),
                floorRect(-0.25, 0.3, -3.9, -3.0),
                floorRect(0.3, 1.8, -3.9, -3.0, kind: .water),
                floorRect(-1.8, 1.8, -4.6, -3.9),
                floorRect(-1.3, 1.3, -5.9, -5.2, y: 0.18),
            ],
            extraWalls: [
                wall(-0.7, 0.5, 0.7, 0.5),
                wall(0.7, 0.5, 0.7, -1.7),
                wall(0.7, -1.7, 1.8, -1.7),
                wall(1.8, -1.7, 1.8, -4.6),
                wall(1.8, -4.6, 0.45, -4.6),
                wall(-0.45, -4.6, -1.8, -4.6),
                wall(-1.8, -4.6, -1.8, -1.7),
                wall(-1.8, -1.7, -0.7, -1.7),
                wall(-0.7, -1.7, -0.7, 0.5),
                wall(-1.3, -5.2, -0.45, -5.2, height: 0.32),
                wall(0.45, -5.2, 1.3, -5.2, height: 0.32),
                wall(1.3, -5.2, 1.3, -5.9, height: 0.32),
                wall(1.3, -5.9, -1.3, -5.9, height: 0.32),
                wall(-1.3, -5.9, -1.3, -5.2, height: 0.32),
            ]
            + arcWall(center: SIMD2(-1.25, -2.25), radius: 0.55,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.25, -2.25), radius: 0.55,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.4, height: 0.035, yaw: 0),
                .pendulum(center: SIMD2(0, -1.2), span: 1.0, arc: 0.7, speed: 1.7,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(-1.5, -2.0), radius: 0.04),
                .bumper(center: SIMD2(-0.85, -2.35), radius: 0.06),
                .bumper(center: SIMD2(0.85, -2.35), radius: 0.06),
                .conveyor(rect: zone(-1.8, 1.8, -2.7, -2.3), direction: SIMD2(1, 0),
                          strength: 2.2, y: 0),
                critter(.turtle, at: SIMD2(0, -2.9),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 0.9),
                .teleporter(a: SIMD2(-1.5, -4.3), b: SIMD2(1.5, -4.1), radius: 0.1, y: 0),
                .movingBlock(center: SIMD2(0, -4.25), axis: acrossLane, amplitude: 0.8,
                             speed: 1.1, size: SIMD2(0.5, 0.2), baseY: 0),
                .ramp(center: SIMD2(0, -4.9), width: 0.9, length: 0.6, rise: 0.18, yaw: 0),
                .block(center: SIMD2(0.85, -5.7), size: SIMD3(0.4, 0.14, 0.4),
                       yaw: 0, baseY: 0.18),
                critter(.frog, at: SIMD2(-0.7, -5.7),
                        .hop(axis: acrossLane, amplitude: 0.28, height: 0.15),
                        speed: 1.1, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.6, -4.45),
            cameraZoom: 2.0
        ),
    ]
}
