//
//  StormLevels.swift
//  Minigolf
//
//  Storm Coast — the wind is the world. It swells and dies on a fixed cycle and
//  the blades turning beside a gust say exactly when, so every hole here is a
//  question of when to hit rather than how hard. Between the gusts there is
//  surf to carry, ledges above it and, at the end, a point to climb.
//

import Foundation
import simd

enum StormCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one gust across the middle of the lane. Wait for the lull and the
        //     hole is straightforward; hit into the swell and it is not.
        LevelDefinition(
            course: .storm, number: 1, name: String(localized: "Sea Breeze"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.4),
            floors: [floorRect(-1.1, 1.1, -5.0, 0.5)],
            wallLoops: [rectLoop(-1.1, 1.1, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -1.2), radius: 0.04),
                .post(center: SIMD2(0.5, -1.2), radius: 0.04),
                .fan(rect: zone(-1.1, 1.1, -2.6, -1.6), direction: SIMD2(1, 0),
                     strength: 2.2, period: 3.0, phase: 0, y: 0),
                .bumper(center: SIMD2(0.9, -2.1), radius: 0.06),
                .bumper(center: SIMD2(-0.9, -2.1), radius: 0.06),
                .post(center: SIMD2(-0.75, -3.9), radius: 0.04),
                critter(.crab, at: SIMD2(0, -3.3),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.0),
                critter(.seagull, at: SIMD2(0, -4.0),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.16), speed: 1.1),
                .post(center: SIMD2(-0.7, -4.6), radius: 0.04),
            ],
            bonusStar: SIMD2(0.9, -4.75),
            cameraZoom: 1.6
        ),
        // 2 — the surf has no crossing. The kicker throws the same distance
        //     every time, and the gust on the far shore decides where that
        //     distance ends up.
        LevelDefinition(
            course: .storm, number: 2, name: String(localized: "Surf Jump"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.0),
            floors: [
                floorRect(-1.2, 1.2, -2.2, 0.5),
                floorRect(-1.2, 1.2, -3.3, -2.2, kind: .water),
                floorRect(-1.2, 1.2, -5.4, -3.3),
            ],
            wallLoops: [rectLoop(-1.2, 1.2, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.4, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.45, -1.2), radius: 0.04),
                .post(center: SIMD2(0.45, -1.2), radius: 0.04),
                .bumper(center: SIMD2(1.0, -1.6), radius: 0.06),
                .launchPad(center: SIMD2(0, -1.9), direction: SIMD2(0, -1), speed: 3.6,
                           lift: 2.1, y: 0),
                .fan(rect: zone(-1.2, 1.2, -4.6, -3.6), direction: SIMD2(-1, 0),
                     strength: 2.4, period: 2.8, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0, -4.1),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.0),
                .bumper(center: SIMD2(-1.0, -4.9), radius: 0.06),
                critter(.seagull, at: SIMD2(0.6, -5.0),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.16), speed: 1.1),
                .post(center: SIMD2(1.0, -5.1), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.0, -1.6),
            cameraZoom: 1.7
        ),
        // 3 — three gusts, each a third of a cycle behind the last, blowing
        //     alternate ways. There is one moment when all three are lulling.
        LevelDefinition(
            course: .storm, number: 3, name: String(localized: "Gale Alley"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -5.2),
            floors: [floorRect(-1.4, 1.4, -5.6, 0.5)],
            wallLoops: [rectLoop(-1.4, 1.4, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -0.9), radius: 0.04),
                .bumper(center: SIMD2(0.55, -0.9), radius: 0.06),
                .fan(rect: zone(-1.4, 1.4, -1.9, -1.3), direction: SIMD2(1, 0),
                     strength: 2.4, period: 2.6, phase: 0, y: 0),
                .bumper(center: SIMD2(-1.15, -2.2), radius: 0.06),
                .fan(rect: zone(-1.4, 1.4, -3.1, -2.5), direction: SIMD2(-1, 0),
                     strength: 2.4, period: 2.6, phase: 0.87, y: 0),
                .bumper(center: SIMD2(1.15, -3.4), radius: 0.06),
                .fan(rect: zone(-1.4, 1.4, -4.3, -3.7), direction: SIMD2(1, 0),
                     strength: 2.4, period: 2.6, phase: 1.73, y: 0),
                critter(.crab, at: SIMD2(0, -4.8),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.0),
                critter(.seagull, at: SIMD2(-0.8, -5.2),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.16), speed: 1.1),
                .post(center: SIMD2(0.8, -5.3), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.2, -1.0),
            cameraZoom: 1.8
        ),
        // 4 — a breakwater half a metre wide out into the bay, with boards
        //     angled to feed it and a bar swinging over the middle of the walk.
        LevelDefinition(
            course: .storm, number: 4, name: String(localized: "Breakwater"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.9, -5.2),
            floors: [
                floorRect(-1.6, 1.6, -1.8, 0.5),
                floorRect(-1.6, -0.2, -3.6, -1.8, kind: .water),
                floorRect(-0.2, 0.35, -3.6, -1.8),
                floorRect(0.35, 1.6, -3.6, -1.8, kind: .water),
                floorRect(-1.6, 1.6, -5.6, -3.6),
            ],
            wallLoops: [rectLoop(-1.6, 1.6, -5.6, 0.5)],
            extraWalls: [
                wall(-1.0, -1.75, -0.25, -1.9),
                wall(1.0, -1.75, 0.4, -1.9),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.6), width: 3.2, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.6, 1.6, -1.7, -0.9), direction: SIMD2(1, 0),
                     strength: 2.6, period: 2.6, phase: 0, y: 0),
                .post(center: SIMD2(-0.6, -1.3), radius: 0.04),
                .post(center: SIMD2(0.6, -1.3), radius: 0.04),
                .pendulum(center: SIMD2(0.07, -2.7), span: 0.6, arc: 0.45, speed: 1.6,
                          yaw: 0, baseY: 0),
                critter(.crab, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.0),
                .bumper(center: SIMD2(-1.3, -4.6), radius: 0.06),
                .bumper(center: SIMD2(1.3, -4.6), radius: 0.06),
                critter(.seagull, at: SIMD2(0, -5.2),
                        .hop(axis: acrossLane, amplitude: 0.5, height: 0.17), speed: 1.1),
                .post(center: SIMD2(0.9, -5.4), radius: 0.04),
            ],
            bonusStar: SIMD2(1.4, -4.9),
            cameraZoom: 1.85
        ),
        // 5 — a current running one way across the approach and a gust running
        //     the other across the landing. The causeway between them is a metre
        //     wide and has a crab on it.
        LevelDefinition(
            course: .storm, number: 5, name: String(localized: "Riptide"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.9, -5.5),
            floors: [
                floorRect(-1.7, 1.7, -2.2, 0.5),
                floorRect(-1.7, -0.5, -3.4, -2.2, kind: .water),
                floorRect(-0.5, 0.5, -3.4, -2.2),
                floorRect(0.5, 1.7, -3.4, -2.2, kind: .water),
                floorRect(-1.7, 1.7, -5.8, -3.4),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -5.8, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .conveyor(rect: zone(-1.7, 1.7, -2.0, -1.2), direction: SIMD2(1, 0),
                          strength: 2.8, y: 0),
                .post(center: SIMD2(-0.75, -1.9), radius: 0.04),
                .post(center: SIMD2(0.75, -1.9), radius: 0.04),
                critter(.crab, at: SIMD2(0, -2.8),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.0),
                .fan(rect: zone(-1.7, 1.7, -4.6, -3.8), direction: SIMD2(-1, 0),
                     strength: 2.6, period: 2.8, phase: 0, y: 0),
                .bumper(center: SIMD2(1.45, -4.2), radius: 0.06),
                .bumper(center: SIMD2(-1.45, -5.0), radius: 0.06),
                .movingBlock(center: SIMD2(-0.6, -5.2), axis: acrossLane, amplitude: 0.7,
                             speed: 1.2, size: SIMD2(0.45, 0.2), baseY: 0),
                critter(.seagull, at: SIMD2(0.2, -5.5),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.17), speed: 1.1),
            ],
            bonusStar: SIMD2(-1.5, -1.0),
            cameraZoom: 1.9
        ),
        // 6 — the point. The ramp up to the lighthouse is at the far corner of
        //     the bay, so the climb has to be lined up from across the water
        //     rather than driven at.
        LevelDefinition(
            course: .storm, number: 6, name: String(localized: "Lighthouse Point"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.4, -5.4), holeY: 0.18,
            floors: [
                floorRect(-0.7, 0.7, -2.4, 0.5),
                floorRect(-2.2, 1.2, -3.8, -2.4),
                floorRect(-2.2, -0.6, -6.0, -4.6, y: 0.18),
            ],
            extraWalls: [
                wall(-0.7, 0.5, 0.7, 0.5),
                wall(0.7, 0.5, 0.7, -2.4),
                wall(0.7, -2.4, 1.2, -2.4),
                wall(1.2, -2.4, 1.2, -3.8),
                wall(1.2, -3.8, -1.0, -3.8),
                wall(-1.8, -3.8, -2.2, -3.8),
                wall(-2.2, -3.8, -2.2, -2.4),
                wall(-2.2, -2.4, -0.7, -2.4),
                wall(-0.7, -2.4, -0.7, 0.5),
                wall(-2.2, -4.6, -1.8, -4.6, height: 0.34),
                wall(-1.0, -4.6, -0.6, -4.6, height: 0.34),
                wall(-0.6, -4.6, -0.6, -6.0, height: 0.34),
                wall(-0.6, -6.0, -2.2, -6.0, height: 0.34),
                wall(-2.2, -6.0, -2.2, -4.6, height: 0.34),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.4, height: 0.03, yaw: 0),
                .fan(rect: zone(-0.7, 0.7, -2.2, -1.4), direction: SIMD2(1, 0),
                     strength: 2.2, period: 2.6, phase: 0, y: 0),
                .bumper(center: SIMD2(0.9, -2.9), radius: 0.06),
                .pendulum(center: SIMD2(-1.4, -3.1), span: 1.0, arc: 0.6, speed: 1.6,
                          yaw: 0, baseY: 0),
                critter(.crab, at: SIMD2(0, -3.2),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.0),
                .ramp(center: SIMD2(-1.4, -4.2), width: 0.8, length: 0.8, rise: 0.18, yaw: 0),
                critter(.seagull, at: SIMD2(-1.4, -4.9),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.17),
                        speed: 1.1, baseY: 0.18),
                .block(center: SIMD2(-0.95, -5.6), size: SIMD3(0.35, 0.14, 0.5),
                       yaw: 0, baseY: 0.18),
                .block(center: SIMD2(-2.0, -5.7), size: SIMD3(0.3, 0.14, 0.3),
                       yaw: 0, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.0, -3.5),
            cameraZoom: 2.0
        ),
        // 7 — two gusts blowing into each other across the tee shot, the kicker
        //     over the surf, and a third gust across the landing.
        LevelDefinition(
            course: .storm, number: 7, name: String(localized: "Squall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -5.6),
            floors: [
                floorRect(-1.8, 1.8, -2.6, 0.5),
                floorRect(-1.8, 1.8, -3.5, -2.6, kind: .water),
                floorRect(-1.8, 1.8, -6.0, -3.5),
            ],
            wallLoops: [rectLoop(-1.8, 1.8, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.6, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.8, 0, -2.0, -1.2), direction: SIMD2(1, 0),
                     strength: 2.6, period: 2.6, phase: 0, y: 0),
                .fan(rect: zone(0, 1.8, -2.0, -1.2), direction: SIMD2(-1, 0),
                     strength: 2.6, period: 2.6, phase: 1.3, y: 0),
                .launchPad(center: SIMD2(0, -2.3), direction: SIMD2(0, -1), speed: 3.6,
                           lift: 2.1, y: 0),
                critter(.crab, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 1.0),
                .bumper(center: SIMD2(-1.5, -4.6), radius: 0.06),
                .bumper(center: SIMD2(1.5, -4.6), radius: 0.06),
                .fan(rect: zone(-1.8, 1.8, -5.4, -4.8), direction: SIMD2(1, 0),
                     strength: 2.8, period: 3.0, phase: 0, y: 0),
                critter(.seagull, at: SIMD2(-0.8, -5.6),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.17), speed: 1.1),
                .post(center: SIMD2(0.8, -5.7), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.6, -1.6),
            cameraZoom: 2.0
        ),
        // 8 — two pools cut into the shore, offset so the dry line through the
        //     first one is the wrong side of the second.
        LevelDefinition(
            course: .storm, number: 8, name: String(localized: "Tide Pools"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.2, -5.9),
            floors: [
                floorRect(-1.9, 1.9, -1.8, 0.5),
                floorRect(-1.9, -1.0, -3.2, -1.8),
                floorRect(-1.0, 0.1, -3.2, -1.8, kind: .water),
                floorRect(0.1, 1.9, -3.2, -1.8),
                floorRect(-1.9, 1.9, -3.9, -3.2),
                floorRect(-1.9, -0.1, -5.3, -3.9),
                floorRect(-0.1, 1.0, -5.3, -3.9, kind: .water),
                floorRect(1.0, 1.9, -5.3, -3.9),
                floorRect(-1.9, 1.9, -6.2, -5.3),
            ],
            wallLoops: [rectLoop(-1.9, 1.9, -6.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.6, -1.3), radius: 0.04),
                .post(center: SIMD2(0.6, -1.3), radius: 0.04),
                critter(.crab, at: SIMD2(-1.4, -2.5),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
                .bumper(center: SIMD2(1.4, -2.5), radius: 0.06),
                .fan(rect: zone(-1.9, 1.9, -3.8, -3.3), direction: SIMD2(1, 0),
                     strength: 2.6, period: 2.8, phase: 0, y: 0),
                .bumper(center: SIMD2(-1.4, -4.6), radius: 0.06),
                critter(.seagull, at: SIMD2(1.45, -4.6),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.17), speed: 1.1),
                .movingBlock(center: SIMD2(0, -5.8), axis: acrossLane, amplitude: 1.0,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .post(center: SIMD2(1.6, -6.0), radius: 0.04),
            ],
            bonusStar: SIMD2(1.7, -2.5),
            cameraZoom: 2.1
        ),
        // 9 — two stretches of open surf, one after the other, each with its own
        //     kicker and its own gust waiting on the far side.
        LevelDefinition(
            course: .storm, number: 9, name: String(localized: "Storm Surge"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.0),
            floors: [
                floorRect(-1.9, 1.9, -2.4, 0.5),
                floorRect(-1.9, 1.9, -3.2, -2.4, kind: .water),
                floorRect(-1.9, 1.9, -4.4, -3.2),
                floorRect(-1.9, 1.9, -5.2, -4.4, kind: .water),
                floorRect(-1.9, 1.9, -6.4, -5.2),
            ],
            wallLoops: [rectLoop(-1.9, 1.9, -6.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.8, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.9, 1.9, -2.0, -1.2), direction: SIMD2(1, 0),
                     strength: 2.8, period: 2.6, phase: 0, y: 0),
                .launchPad(center: SIMD2(0, -2.1), direction: SIMD2(0, -1), speed: 3.5,
                           lift: 1.95, y: 0),
                .fan(rect: zone(-1.9, 1.9, -4.0, -3.4), direction: SIMD2(-1, 0),
                     strength: 2.8, period: 2.6, phase: 1.3, y: 0),
                critter(.crab, at: SIMD2(0, -3.8),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 1.0),
                .launchPad(center: SIMD2(0, -4.1), direction: SIMD2(0, -1), speed: 3.5,
                           lift: 1.95, y: 0),
                .bumper(center: SIMD2(-1.6, -5.8), radius: 0.06),
                .bumper(center: SIMD2(1.6, -5.8), radius: 0.06),
                critter(.seagull, at: SIMD2(-0.7, -6.0),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.17), speed: 1.1),
                .post(center: SIMD2(0.7, -6.1), radius: 0.04),
            ],
            bonusStar: SIMD2(1.7, -3.8),
            cameraZoom: 2.15
        ),
        // 10 — two ledges above the water, on opposite sides of the hole, with a
        //      bar swinging over the first and a block sliding along the second.
        LevelDefinition(
            course: .storm, number: 10, name: String(localized: "Cliff Path"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.2, -6.3),
            floors: [
                floorRect(-2.0, 2.0, -1.6, 0.5),
                floorRect(-2.0, -1.2, -3.6, -1.6),
                floorRect(-1.2, 2.0, -3.6, -1.6, kind: .water),
                floorRect(-2.0, 2.0, -4.2, -3.6),
                floorRect(-2.0, 0.6, -6.0, -4.2, kind: .water),
                floorRect(0.6, 2.0, -6.0, -4.2),
                floorRect(-2.0, 2.0, -6.6, -6.0),
            ],
            wallLoops: [rectLoop(-2.0, 2.0, -6.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.5), width: 4.0, height: 0.03, yaw: 0),
                .fan(rect: zone(-2.0, 2.0, -1.4, -0.6), direction: SIMD2(-1, 0),
                     strength: 2.6, period: 2.6, phase: 0, y: 0),
                critter(.crab, at: SIMD2(-1.6, -2.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
                .pendulum(center: SIMD2(-1.6, -3.2), span: 0.7, arc: 0.5, speed: 1.6,
                          yaw: 0, baseY: 0),
                .fan(rect: zone(-2.0, 2.0, -4.1, -3.7), direction: SIMD2(1, 0),
                     strength: 2.8, period: 2.8, phase: 0, y: 0),
                .bumper(center: SIMD2(1.5, -3.9), radius: 0.06),
                critter(.seagull, at: SIMD2(1.3, -5.1),
                        .hop(axis: acrossLane, amplitude: 0.35, height: 0.17), speed: 1.1),
                .movingBlock(center: SIMD2(1.3, -5.6), axis: acrossLane, amplitude: 0.3,
                             speed: 1.1, size: SIMD2(0.3, 0.2), baseY: 0),
                .bumper(center: SIMD2(-1.6, -6.3), radius: 0.06),
                .post(center: SIMD2(0.2, -6.3), radius: 0.04),
            ],
            bonusStar: SIMD2(1.75, -6.3),
            cameraZoom: 2.2
        ),
        // 11 — a current, a gust against it and a whirlpool of a turntable in the
        //      middle of the bay. Very little on this hole finishes where it was
        //      aimed.
        LevelDefinition(
            course: .storm, number: 11, name: String(localized: "Maelstrom"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.35),
            floors: [floorRect(-2.05, 2.05, -6.6, 0.5)],
            wallLoops: [rectLoop(-2.05, 2.05, -6.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 4.1, height: 0.03, yaw: 0),
                .conveyor(rect: zone(-2.05, 2.05, -1.8, -1.2), direction: SIMD2(1, 0),
                          strength: 3.0, y: 0),
                .post(center: SIMD2(1.8, -2.0), radius: 0.04),
                .fan(rect: zone(-2.05, 2.05, -3.0, -2.2), direction: SIMD2(-1, 0),
                     strength: 3.0, period: 2.6, phase: 0, y: 0),
                .bumper(center: SIMD2(-1.75, -3.6), radius: 0.06),
                .bumper(center: SIMD2(1.75, -3.6), radius: 0.06),
                .turntable(center: SIMD2(0, -4.0), radius: 1.0, speed: 1.5, y: 0),
                critter(.crab, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 1.0),
                .fan(rect: zone(-2.05, 2.05, -5.8, -5.2), direction: SIMD2(1, 0),
                     strength: 2.8, period: 3.0, phase: 0, y: 0),
                critter(.seagull, at: SIMD2(-0.9, -6.2),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.17), speed: 1.1),
                .movingBlock(center: SIMD2(0.9, -6.2), axis: acrossLane, amplitude: 0.7,
                             speed: 1.2, size: SIMD2(0.45, 0.2), baseY: 0),
            ],
            bonusStar: SIMD2(-1.85, -6.3),
            cameraZoom: 2.25
        ),
        // 12 — the coast entire. A gust in the channel, shoulders into the bay,
        //      a bar over the neck, the kicker across the surf, a gale on the far
        //      shore and a headland at the top that tilts toward the sea.
        LevelDefinition(
            course: .storm, number: 12, name: String(localized: "Storm Coast"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.8), holeY: 0.2,
            floors: [
                floorRect(-0.85, 0.85, -2.0, 0.5),
                floorRect(-2.2, 2.2, -3.4, -2.0),
                floorRect(-2.2, 2.2, -4.4, -3.4, kind: .water),
                floorRect(-2.2, 2.2, -5.6, -4.4),
                floorRect(-1.6, 1.6, -7.2, -6.2, y: 0.2),
            ],
            extraWalls: [
                wall(-0.85, 0.5, 0.85, 0.5),
                wall(0.85, 0.5, 0.85, -2.0),
                wall(0.85, -2.0, 2.2, -2.0),
                wall(2.2, -2.0, 2.2, -5.6),
                wall(2.2, -5.6, 0.45, -5.6),
                wall(-0.45, -5.6, -2.2, -5.6),
                wall(-2.2, -5.6, -2.2, -2.0),
                wall(-2.2, -2.0, -0.85, -2.0),
                wall(-0.85, -2.0, -0.85, 0.5),
                wall(-1.6, -6.2, -0.45, -6.2, height: 0.36),
                wall(0.45, -6.2, 1.6, -6.2, height: 0.36),
                wall(1.6, -6.2, 1.6, -7.2, height: 0.36),
                wall(1.6, -7.2, -1.6, -7.2, height: 0.36),
                wall(-1.6, -7.2, -1.6, -6.2, height: 0.36),
            ]
            + arcWall(center: SIMD2(-1.6, -2.6), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.6, -2.6), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 1.7, height: 0.035, yaw: 0),
                .fan(rect: zone(-0.85, 0.85, -1.8, -1.1), direction: SIMD2(1, 0),
                     strength: 2.4, period: 2.6, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0, -2.5),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 1.0),
                .bumper(center: SIMD2(-1.1, -2.7), radius: 0.06),
                .bumper(center: SIMD2(1.1, -2.7), radius: 0.06),
                .pendulum(center: SIMD2(0, -3.0), span: 1.2, arc: 0.7, speed: 1.6,
                          yaw: 0, baseY: 0),
                .launchPad(center: SIMD2(0, -3.2), direction: SIMD2(0, -1), speed: 3.6,
                           lift: 2.2, y: 0),
                .fan(rect: zone(-2.2, 2.2, -5.2, -4.6), direction: SIMD2(-1, 0),
                     strength: 3.0, period: 2.8, phase: 0, y: 0),
                critter(.seagull, at: SIMD2(-1.5, -5.0),
                        .hop(axis: acrossLane, amplitude: 0.4, height: 0.17), speed: 1.1),
                .bumper(center: SIMD2(1.6, -5.0), radius: 0.06),
                .ramp(center: SIMD2(0, -5.9), width: 0.9, length: 0.6, rise: 0.2, yaw: 0),
                .slope(rect: zone(-1.6, 1.6, -7.1, -6.3), direction: SIMD2(1, 0),
                       strength: 0.9, y: 0.2),
                .block(center: SIMD2(1.2, -6.8), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.2),
                critter(.crab, at: SIMD2(-0.9, -6.8),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.2),
            ],
            bonusStar: SIMD2(1.9, -5.0),
            cameraZoom: 2.35
        ),
    ]
}
