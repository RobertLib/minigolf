//
//  StormLevels.swift
//  Minigolf
//
//  Storm Coast — wind and water. Gusts swell and die on their own clock, and
//  the only way across the surf is a kicker and a well-timed putt.
//

import Foundation
import simd

enum StormCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a gentle crosswind to read.
        LevelDefinition(
            course: .storm, number: 1, name: String(localized: "Sea Breeze"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(-0.15, -2.45),
            floors: [floorRect(-0.55, 0.55, -2.9, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -2.9, 0.5)],
            obstacles: [
                // A crab scuttling along the strand line, sideways as crabs do.
                critter(.crab, at: SIMD2(0, -0.8),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.2),
                .fan(rect: zone(-0.55, 0.55, -2.2, -1.2), direction: SIMD2(1, 0),
                     strength: 0.8, period: 3.6, phase: 0, y: 0),
            ],
            bonusStar: SIMD2(0.4, -2.7)
        ),
        // 2 — the tide is out; one plank across.
        LevelDefinition(
            course: .storm, number: 2, name: String(localized: "Low Tide"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0),
            floors: [
                floorRect(-0.55, 0.55, -1.5, 0.5),
                floorRect(-0.55, -0.16, -2.4, -1.5, kind: .water),
                floorRect(-0.16, 0.16, -2.4, -1.5),
                floorRect(0.16, 0.55, -2.4, -1.5, kind: .water),
                floorRect(-0.55, 0.55, -3.5, -2.4),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.5, 0.5)],
            obstacles: [
                .fan(rect: zone(-0.55, 0.55, -1.4, -0.6), direction: SIMD2(1, 0),
                     strength: 0.8, period: 3.6, phase: 0, y: 0),
            ],
            bonusStar: SIMD2(-0.42, -3.25),
            cameraZoom: 1.1
        ),
        // 3 — the first kicker: roll onto it hard enough and it does the rest.
        LevelDefinition(
            course: .storm, number: 3, name: String(localized: "The Jetty"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.95),
            floors: [
                floorRect(-0.5, 0.5, -1.5, 0.5),
                floorRect(-0.5, 0.5, -2.05, -1.5, kind: .water),
                floorRect(-0.5, 0.5, -3.4, -2.05),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -3.4, 0.5)],
            obstacles: [
                .launchPad(center: SIMD2(0, -1.25), direction: SIMD2(0, -1), speed: 2.8,
                           lift: 1.7, y: 0),
            ],
            bonusStar: SIMD2(0.34, -3.2),
            cameraZoom: 1.15
        ),
        // 4 — the gust comes from the side, so aim into it.
        LevelDefinition(
            course: .storm, number: 4, name: String(localized: "Crosswind"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.35, -3.05),
            floors: [floorRect(-0.7, 0.7, -3.4, 0.5)],
            wallLoops: [rectLoop(-0.7, 0.7, -3.4, 0.5)],
            obstacles: [
                .fan(rect: zone(-0.7, 0.7, -2.6, -1.2), direction: SIMD2(-1, 0),
                     strength: 1.4, period: 3.2, phase: 0, y: 0),
                .post(center: SIMD2(0.25, -1.0), radius: 0.045),
                .post(center: SIMD2(-0.3, -2.9), radius: 0.045),
                // A gull hopping up the windward side, on the line the gust
                // pushes everything toward.
                critter(.seagull, at: SIMD2(-0.35, -1.7),
                        .hop(axis: alongLane, amplitude: 0.25, height: 0.1), speed: 1.0),
            ],
            bonusStar: SIMD2(-0.55, -3.25),
            cameraZoom: 1.2
        ),
        // 5 — a curved sea wall to bank off.
        LevelDefinition(
            course: .storm, number: 5, name: String(localized: "Breakwater"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.5, -3.05),
            floors: [floorRect(-1.0, 1.0, -3.4, 0.5)],
            wallLoops: [rectLoop(-1.0, 1.0, -3.4, 0.5)],
            extraWalls: arcWall(center: SIMD2(1.0, -2.0), radius: 0.8,
                                from: deg(90), to: deg(270), segments: 9),
            obstacles: [
                .bumper(center: SIMD2(-0.55, -1.4), radius: 0.07),
                .bumper(center: SIMD2(-0.2, -2.6), radius: 0.06),
                critter(.crab, at: SIMD2(-0.6, -2.05),
                        .patrol(axis: alongLane, amplitude: 0.2), speed: 1.0),
            ],
            bonusStar: SIMD2(-0.85, -3.2),
            cameraZoom: 1.3
        ),
        // 6 — a headwind that comes and goes: hit it on the lull.
        LevelDefinition(
            course: .storm, number: 6, name: String(localized: "Gale Force"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.7),
            floors: [floorRect(-0.55, 0.55, -4.2, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -4.2, 0.5)],
            obstacles: [
                .post(center: SIMD2(-0.26, -1.9), radius: 0.04),
                .post(center: SIMD2(0.26, -2.4), radius: 0.04),
                .fan(rect: zone(-0.55, 0.55, -4.2, -2.4), direction: SIMD2(0, 1),
                     strength: 2.4, period: 3.0, phase: 0, y: 0),
            ],
            bonusStar: SIMD2(0.38, -1.5),
            cameraZoom: 1.3
        ),
        // 7 — island to island, and the second kicker fires off the landing.
        LevelDefinition(
            course: .storm, number: 7, name: String(localized: "Skerry Hop"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-0.5, 0.5, -1.3, 0.5),
                floorRect(-0.5, 0.5, -1.95, -1.3, kind: .water),
                floorRect(-0.5, 0.5, -2.85, -1.95),
                floorRect(-0.5, 0.5, -3.5, -2.85, kind: .water),
                floorRect(-0.5, 0.5, -4.5, -3.5),
            ],
            wallLoops: [rectLoop(-0.5, 0.5, -4.5, 0.5)],
            obstacles: [
                .launchPad(center: SIMD2(0, -1.15), direction: SIMD2(0, -1), speed: 2.8,
                           lift: 1.7, y: 0),
                .launchPad(center: SIMD2(0, -2.7), direction: SIMD2(0, -1), speed: 2.8,
                           lift: 1.7, y: 0),
            ],
            bonusStar: SIMD2(0.34, -4.3),
            cameraZoom: 1.35
        ),
        // 8 — the kelp eats every bit of pace the wind gives you.
        LevelDefinition(
            course: .storm, number: 8, name: String(localized: "Kelp Beds"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.35, -3.0),
            floors: [
                floorRect(-0.6, 0.6, -3.5, 0.5),
                floorRect(-0.6, 0.1, -2.3, -1.5, kind: .mud),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -3.5, 0.5)],
            obstacles: [
                .fan(rect: zone(-0.6, 0.6, -1.4, -0.6), direction: SIMD2(-1, 0),
                     strength: 1.3, period: 2.8, phase: 0, y: 0),
                // Picking its way through the kelp, where the ball is slowest.
                critter(.crab, at: SIMD2(-0.25, -1.9),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.9),
            ],
            bonusStar: SIMD2(-0.45, -3.25),
            cameraZoom: 1.15
        ),
        // 9 — two fans facing each other, half a cycle apart.
        LevelDefinition(
            course: .storm, number: 9, name: String(localized: "Squall Line"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.62),
            floors: [floorRect(-0.75, 0.75, -4.0, 0.5)],
            wallLoops: [rectLoop(-0.75, 0.75, -4.0, 0.5)],
            obstacles: [
                .fan(rect: zone(-0.75, 0.75, -1.9, -1.1), direction: SIMD2(1, 0),
                     strength: 1.5, period: 3.0, phase: 0, y: 0),
                .fan(rect: zone(-0.75, 0.75, -3.0, -2.2), direction: SIMD2(-1, 0),
                     strength: 1.5, period: 3.0, phase: .pi, y: 0),
            ],
            bonusStar: SIMD2(-0.6, -3.85),
            cameraZoom: 1.3
        ),
        // 10 — the wind on the headland blows straight back down the ramp.
        LevelDefinition(
            course: .storm, number: 10, name: String(localized: "The Lighthouse"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.5), holeY: 0.14,
            floors: [
                floorRect(-0.5, 0.5, -1.9, 0.5),
                floorRect(-0.5, 0.5, -3.9, -2.6, y: 0.14),
            ],
            extraWalls: [
                wall(0.5, 0.5, -0.5, 0.5),
                wall(-0.5, 0.5, -0.5, -1.9),
                wall(-0.5, -1.9, -0.5, -3.9, height: 0.26),
                wall(-0.5, -3.9, 0.5, -3.9, height: 0.26),
                wall(0.5, -3.9, 0.5, -1.9, height: 0.26),
                wall(0.5, -1.9, 0.5, 0.5),
            ],
            obstacles: [
                .ramp(center: SIMD2(0, -2.25), width: 1.0, length: 0.7, rise: 0.14, yaw: 0),
                .fan(rect: zone(-0.5, 0.5, -3.9, -3.2), direction: SIMD2(0, 1),
                     strength: 1.6, period: 2.6, phase: 0, y: 0.14),
            ],
            bonusStar: SIMD2(0.33, -3.75), bonusStarY: 0.14,
            cameraZoom: 1.25
        ),
        // 11 — the current runs straight out to sea along the open edge.
        LevelDefinition(
            course: .storm, number: 11, name: String(localized: "Storm Surge"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.55, -3.5),
            floors: [
                floorRect(-0.6, 0.9, -3.9, 0.5),
                floorRect(-1.35, -0.6, -3.9, -1.2, kind: .water),
            ],
            extraWalls: [
                wall(-0.6, 0.5, 0.9, 0.5),
                wall(0.9, 0.5, 0.9, -3.9),
                wall(0.9, -3.9, -1.35, -3.9),
                wall(-0.6, 0.5, -0.6, -1.2),
            ],
            obstacles: [
                .conveyor(rect: zone(-0.6, 0.9, -2.7, -1.5), direction: SIMD2(-1, 0),
                          strength: 1.8, y: 0),
                .pendulum(center: SIMD2(0.2, -3.15), span: 0.55, arc: 0.75, speed: 1.7,
                          yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.45, -2.1),
            cameraZoom: 1.35
        ),
        // 12 — crosswind, then the long jump, then the climb to the point.
        LevelDefinition(
            course: .storm, number: 12, name: String(localized: "Cape Fury"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(1.3, -4.3), holeY: 0.14,
            floors: [
                floorRect(-0.6, 0.6, -1.5, 0.5),
                floorRect(-0.6, 0.6, -2.2, -1.5, kind: .water),
                floorRect(-0.6, 1.6, -3.3, -2.2),
                floorRect(1.0, 1.6, -4.6, -4.0, y: 0.14),
            ],
            extraWalls: [
                wall(-0.6, 0.5, 0.6, 0.5),
                wall(0.6, 0.5, 0.6, -2.2),
                wall(0.6, -2.2, 1.6, -2.2),
                wall(1.6, -2.2, 1.6, -3.3),
                wall(-0.6, 0.5, -0.6, -3.3),
                wall(-0.6, -3.3, 1.0, -3.3),
                wall(1.0, -3.3, 1.0, -4.6, height: 0.26),
                wall(1.0, -4.6, 1.6, -4.6, height: 0.26),
                wall(1.6, -4.6, 1.6, -3.3, height: 0.26),
            ],
            obstacles: [
                .fan(rect: zone(-0.6, 0.6, -1.0, -0.4), direction: SIMD2(1, 0),
                     strength: 1.2, period: 3.2, phase: 0, y: 0),
                .launchPad(center: SIMD2(0, -1.35), direction: SIMD2(0, -1), speed: 3.0,
                           lift: 1.7, y: 0),
                .pendulum(center: SIMD2(0.55, -2.75), span: 0.55, arc: 0.75, speed: 1.7,
                          yaw: .pi / 2, baseY: 0),
                // On the landing shelf, outside the swing of the buoy.
                critter(.crab, at: SIMD2(-0.2, -2.85),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 1.1),
                .ramp(center: SIMD2(1.3, -3.65), width: 0.6, length: 0.7, rise: 0.14, yaw: 0),
            ],
            bonusStar: SIMD2(-0.45, -3.05),
            cameraZoom: 1.5
        ),
    ]
}
