//
//  GardenLevels.swift
//  Minigolf
//
//  Green Garden — the introductory world. It opens on a single lane with one
//  hedgehog on it and closes on a windmill, a pond and a raised finishing green,
//  so the twelve holes are also the tutorial: banks, sand, islands, forks,
//  timing, water and a change of height, one new idea at a time.
//
//  The world sets the scale the rest of the game grows from. Hole 1 is a metre
//  wide and three long; hole 12 is three metres by six, with the boards curving
//  round the corners the way a real course kerbs them.
//

import Foundation
import simd

enum GardenCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a plain straight lane, with two boards angled in front of the cup
        //     so a firm putt down the middle is rewarded rather than merely
        //     tolerated. The hedgehog is the first thing on the course that
        //     moves, and the first thing that proves the locals are solid.
        LevelDefinition(
            course: .garden, number: 1, name: String(localized: "First Steps"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.45),
            floors: [floorRect(-0.5, 0.5, -2.9, 0.5)],
            wallLoops: [rectLoop(-0.5, 0.5, -2.9, 0.5)],
            extraWalls: [
                wall(-0.5, -2.02, -0.24, -2.22),
                wall(0.5, -2.02, 0.24, -2.22),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 1.0, height: 0.028, yaw: 0),
                critter(.hedgehog, at: SIMD2(0, -1.25),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 1.1),
                .post(center: SIMD2(0.2, -2.7), radius: 0.04),
            ],
            bonusStar: SIMD2(0.36, -2.75)
        ),
        // 2 — staggered posts and a rise to carry: the first hole that asks for
        //     a line rather than a direction.
        LevelDefinition(
            course: .garden, number: 2, name: String(localized: "Slalom"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.0),
            floors: [floorRect(-0.55, 0.55, -3.5, 0.5)],
            wallLoops: [rectLoop(-0.55, 0.55, -3.5, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.55), width: 1.1, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.2, -1.1), radius: 0.045),
                .post(center: SIMD2(0.24, -1.75), radius: 0.045),
                .post(center: SIMD2(-0.2, -2.4), radius: 0.045),
            ],
            bonusStar: SIMD2(0.38, -3.25)
        ),
        // 3 — the corner is banked. A putt driven into the curve comes out of it
        //     pointing down the second leg, which is the whole trick of minigolf
        //     and worth teaching on the third hole.
        LevelDefinition(
            course: .garden, number: 3, name: String(localized: "Banked Corner"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.8, -3.1),
            floors: [
                floorRect(-0.5, 0.5, -2.6, 0.5),
                floorRect(-0.5, 2.2, -3.6, -2.6),
            ],
            wallLoops: [[
                SIMD2(-0.5, 0.5), SIMD2(-0.5, -3.6), SIMD2(2.2, -3.6),
                SIMD2(2.2, -2.6), SIMD2(0.5, -2.6), SIMD2(0.5, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(0.05, -3.05), radius: 0.55,
                                from: deg(180), to: deg(270), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -1.3), width: 1.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.28, -2.0), radius: 0.04),
                .block(center: SIMD2(0.62, -3.42), size: SIMD3(0.36, 0.14, 0.16),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(1.0, -2.85), radius: 0.04),
                critter(.hedgehog, at: SIMD2(1.25, -3.1),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
            ],
            bonusStar: SIMD2(-0.22, -3.3),
            cameraZoom: 1.3
        ),
        // 4 — two boards reaching in from opposite sides, with the sand laid
        //     where the lazy line through them goes.
        LevelDefinition(
            course: .garden, number: 4, name: String(localized: "Sand Trap"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.6),
            floors: [
                floorRect(-0.6, 0.6, -4.0, 0.5),
                floorRect(-0.6, 0.2, -2.4, -1.5, kind: .sand),
                floorRect(0.05, 0.6, -2.7, -2.2, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.6, 0.6, -4.0, 0.5)],
            extraWalls: [
                wall(-0.6, -1.15, -0.12, -1.15),
                wall(0.6, -3.0, 0.12, -3.0),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 1.2, height: 0.03, yaw: 0),
                .block(center: SIMD2(0.45, -1.3), size: SIMD3(0.28, 0.14, 0.2),
                       yaw: 0, baseY: 0),
                // The mole works the clean side of the trap: the way round the
                // sand is only open while he is down.
                critter(.mole, at: SIMD2(0.35, -1.95), .burrow(period: 2.6), phase: 0.4),
                critter(.hedgehog, at: SIMD2(0, -2.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
                .post(center: SIMD2(-0.28, -2.95), radius: 0.04),
                .post(center: SIMD2(0.26, -3.4), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.44, -2.05),
            cameraZoom: 1.15
        ),
        // 5 — a hedge down the middle splits the hole in two: the left way is
        //     short and buried in sand, the right way is clean and longer. The
        //     first hole that is a choice rather than a line.
        LevelDefinition(
            course: .garden, number: 5, name: String(localized: "Two Ways Round"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-1.15, 1.15, -4.3, 0.5),
                floorRect(-1.15, -0.42, -2.9, -1.5, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.15, 1.15, -4.3, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.2, height: 0.03, yaw: 0),
                .block(center: SIMD2(0, -2.2), size: SIMD3(0.74, 0.16, 1.9),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(0.75, -1.7), radius: 0.04),
                .post(center: SIMD2(0.75, -2.8), radius: 0.04),
                critter(.hedgehog, at: SIMD2(-0.76, -3.55),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 0.9),
                critter(.mole, at: SIMD2(0.7, -3.5), .burrow(period: 3.0)),
            ],
            bonusStar: SIMD2(-0.9, -2.2),
            cameraZoom: 1.4
        ),
        // 6 — the timeless classic. The lane is wider than the mill, so the gap
        //     between its housing and the boards is filled in on both sides:
        //     under the blades is the only way past.
        LevelDefinition(
            course: .garden, number: 6, name: String(localized: "The Windmill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.9),
            floors: [floorRect(-0.65, 0.65, -4.5, 0.5)],
            wallLoops: [rectLoop(-0.65, 0.65, -4.5, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -1.0), width: 1.3, height: 0.03, yaw: 0),
                .windmill(center: SIMD2(0, -2.1), yaw: 0, speed: 1.7),
                .block(center: SIMD2(-0.555, -2.1), size: SIMD3(0.22, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.555, -2.1), size: SIMD3(0.22, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.3, -3.1), radius: 0.04),
                .post(center: SIMD2(0.28, -3.4), radius: 0.04),
                critter(.mole, at: SIMD2(-0.3, -3.75), .burrow(period: 2.8), phase: 0.6),
            ],
            bonusStar: SIMD2(0.45, -4.25),
            cameraZoom: 1.25
        ),
        // 7 — the green is up a ramp, and it is wider than the lane that feeds
        //     it, so the climb opens out into somewhere with room to miss.
        LevelDefinition(
            course: .garden, number: 7, name: String(localized: "King of the Hill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.7), holeY: 0.13,
            floors: [
                floorRect(-0.45, 0.45, -1.9, 0.5),
                floorRect(-1.0, 1.0, -4.3, -2.6, y: 0.13),
            ],
            extraWalls: [
                wall(-0.45, 0.5, 0.45, 0.5),
                wall(-0.45, 0.5, -0.45, -1.9),
                wall(0.45, 0.5, 0.45, -1.9),
                // Retaining boards around the plateau: they stand on the lower
                // floor, so one board guards both heights at once.
                wall(-1.0, -2.6, -0.45, -2.6, height: 0.26),
                wall(0.45, -2.6, 1.0, -2.6, height: 0.26),
                wall(-1.0, -2.6, -1.0, -4.3, height: 0.26),
                wall(-1.0, -4.3, 1.0, -4.3, height: 0.26),
                wall(1.0, -4.3, 1.0, -2.6, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -1.0), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.28, -1.45), radius: 0.04),
                .ramp(center: SIMD2(0, -2.25), width: 0.9, length: 0.7, rise: 0.13, yaw: 0),
                .block(center: SIMD2(-0.68, -3.2), size: SIMD3(0.36, 0.14, 0.5),
                       yaw: 0, baseY: 0.13),
                .block(center: SIMD2(0.68, -3.5), size: SIMD3(0.36, 0.14, 0.5),
                       yaw: 0, baseY: 0.13),
                critter(.mole, at: SIMD2(0, -3.1), .burrow(period: 2.6), baseY: 0.13),
                critter(.hedgehog, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.13),
            ],
            bonusStar: SIMD2(-0.8, -4.05), bonusStarY: 0.13,
            cameraZoom: 1.35
        ),
        // 8 — an S-shaped walk between the hedges, with the far turn banked so
        //     the ball can be swung round it instead of stopped and re-aimed.
        LevelDefinition(
            course: .garden, number: 8, name: String(localized: "Garden Path"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.5, -4.15),
            floors: [
                floorRect(-0.5, 0.5, -1.7, 0.5),
                floorRect(-2.0, 0.5, -2.7, -1.7),
                floorRect(-2.0, -1.0, -4.6, -2.7),
            ],
            wallLoops: [[
                SIMD2(0.5, 0.5), SIMD2(0.5, -2.7), SIMD2(-1.0, -2.7),
                SIMD2(-1.0, -4.6), SIMD2(-2.0, -4.6), SIMD2(-2.0, -1.7),
                SIMD2(-0.5, -1.7), SIMD2(-0.5, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-1.4, -2.3), radius: 0.6,
                                from: deg(90), to: deg(180), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.1, -2.15), radius: 0.04),
                .block(center: SIMD2(-0.4, -2.2), size: SIMD3(0.34, 0.14, 0.5),
                       yaw: 0, baseY: 0),
                critter(.hedgehog, at: SIMD2(-0.75, -2.2),
                        .patrol(axis: alongLane, amplitude: 0.28), speed: 0.9),
                .post(center: SIMD2(-1.75, -3.15), radius: 0.04),
                critter(.mole, at: SIMD2(-1.5, -3.4), .burrow(period: 3.0)),
                .post(center: SIMD2(-1.25, -3.9), radius: 0.04),
            ],
            bonusStar: SIMD2(0.28, -2.4),
            cameraZoom: 1.5
        ),
        // 9 — two ways over the water: a plank straight down the line of play,
        //     or a proper bridge over on the right for anyone who would rather
        //     spend a stroke than a life.
        LevelDefinition(
            course: .garden, number: 9, name: String(localized: "The Pond"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.5, -3.95),
            floors: [
                floorRect(-1.1, 1.1, -1.6, 0.5),
                floorRect(-1.1, -0.17, -2.6, -1.6, kind: .water),
                floorRect(-0.17, 0.17, -2.6, -1.6),
                floorRect(0.17, 0.68, -2.6, -1.6, kind: .water),
                floorRect(0.68, 1.1, -2.6, -1.6),
                floorRect(-1.1, 1.1, -4.6, -2.6),
            ],
            wallLoops: [rectLoop(-1.1, 1.1, -4.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 2.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.42, -1.05), radius: 0.04),
                .post(center: SIMD2(-0.85, -2.95), radius: 0.04),
                critter(.hedgehog, at: SIMD2(-0.5, -3.2),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.2),
                .block(center: SIMD2(0.55, -3.3), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0),
                critter(.mole, at: SIMD2(0.15, -4.2), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(0.9, -4.3),
            cameraZoom: 1.4
        ),
        // 10 — the felt is banked to the right for most of its length, and the
        //      only shelter from it is a horseshoe of boards on the far side
        //      with the star sitting in it.
        LevelDefinition(
            course: .garden, number: 10, name: String(localized: "Sloping Lawn"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(1.0, -4.1),
            floors: [floorRect(-1.3, 1.3, -4.7, 0.5)],
            wallLoops: [rectLoop(-1.3, 1.3, -4.7, 0.5)],
            extraWalls: arcWall(center: SIMD2(-0.62, -2.6), radius: 0.62,
                                from: deg(105), to: deg(255), segments: 8),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 2.6, height: 0.03, yaw: 0),
                .slope(rect: zone(-0.6, 1.3, -3.7, -1.5), direction: SIMD2(1, 0),
                       strength: 1.0, y: 0),
                .post(center: SIMD2(0.55, -1.9), radius: 0.04),
                .post(center: SIMD2(1.05, -2.6), radius: 0.04),
                .bumper(center: SIMD2(0.35, -3.2), radius: 0.06),
                critter(.mole, at: SIMD2(-0.2, -3.9), .burrow(period: 3.0)),
                critter(.hedgehog, at: SIMD2(0.6, -4.35),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1),
            ],
            bonusStar: SIMD2(-1.0, -2.6),
            cameraZoom: 1.5
        ),
        // 11 — three staggered hedges, each with one way through, and the last
        //      of them is an arch. Going left means threading the tunnel; going
        //      right is open but twice as far.
        LevelDefinition(
            course: .garden, number: 11, name: String(localized: "Hedge Maze"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.95, -4.5),
            floors: [floorRect(-1.4, 1.4, -5.0, 0.5)],
            wallLoops: [rectLoop(-1.4, 1.4, -5.0, 0.5)],
            obstacles: [
                .block(center: SIMD2(-0.62, -1.35), size: SIMD3(1.56, 0.16, 0.22),
                       yaw: 0, baseY: 0),
                critter(.mole, at: SIMD2(-1.0, -2.9), .burrow(period: 2.8)),
                .block(center: SIMD2(0.6, -2.4), size: SIMD3(1.6, 0.16, 0.22),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(-0.04, -3.45), size: SIMD3(1.58, 0.16, 0.22),
                       yaw: 0, baseY: 0),
                .tunnel(center: SIMD2(-1.0, -3.45), width: 0.3, length: 0.7, yaw: 0),
                .block(center: SIMD2(-1.3, -3.45), size: SIMD3(0.2, 0.16, 0.22),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(1.1, -4.2), radius: 0.04),
                critter(.hedgehog, at: SIMD2(0.5, -4.6),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.1),
                .post(center: SIMD2(-0.3, -4.7), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.2, -1.85),
            cameraZoom: 1.6
        ),
        // 12 — everything the garden has, in order: the mill, the shoulders
        //      that funnel a putt out of the narrow lane into the wide one, the
        //      pond with a single plank over it, and a last climb to a green
        //      that has its own gallery of locals on it.
        LevelDefinition(
            course: .garden, number: 12, name: String(localized: "Grand Garden"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.0), holeY: 0.14,
            floors: [
                floorRect(-0.65, 0.65, -2.0, 0.5),
                floorRect(-0.65, -0.1, -0.9, -0.45, kind: .sand),
                floorRect(-1.5, 1.5, -3.0, -2.0),
                floorRect(-1.5, -0.2, -3.9, -3.0, kind: .water),
                floorRect(-0.2, 0.22, -3.9, -3.0),
                floorRect(0.22, 1.5, -3.9, -3.0, kind: .water),
                floorRect(-1.5, 1.5, -4.4, -3.9),
                floorRect(-1.1, 1.1, -5.4, -4.7, y: 0.14),
            ],
            extraWalls: [
                wall(-0.65, 0.5, 0.65, 0.5),
                wall(0.65, 0.5, 0.65, -2.0),
                wall(0.65, -2.0, 1.5, -2.0),
                wall(1.5, -2.0, 1.5, -4.4),
                wall(1.5, -4.4, 0.45, -4.4),
                wall(-0.45, -4.4, -1.5, -4.4),
                wall(-1.5, -4.4, -1.5, -2.0),
                wall(-1.5, -2.0, -0.65, -2.0),
                wall(-0.65, -2.0, -0.65, 0.5),
                wall(-1.1, -4.7, -0.45, -4.7, height: 0.26),
                wall(0.45, -4.7, 1.1, -4.7, height: 0.26),
                wall(1.1, -4.7, 1.1, -5.4, height: 0.26),
                wall(1.1, -5.4, -1.1, -5.4, height: 0.26),
                wall(-1.1, -5.4, -1.1, -4.7, height: 0.26),
            ]
            // Shoulders on both sides of the mouth: a putt that comes out of the
            // narrow lane wide is turned back down the hole instead of parking
            // itself in a corner.
            + arcWall(center: SIMD2(-0.95, -2.55), radius: 0.55,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(0.95, -2.55), radius: 0.55,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .windmill(center: SIMD2(0, -1.35), yaw: 0, speed: 1.9),
                .block(center: SIMD2(-0.555, -1.35), size: SIMD3(0.22, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.555, -1.35), size: SIMD3(0.22, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(-0.55, -2.5), radius: 0.04),
                .bumper(center: SIMD2(0.6, -2.45), radius: 0.06),
                critter(.hedgehog, at: SIMD2(0, -2.6),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                critter(.mole, at: SIMD2(-0.75, -4.15), .burrow(period: 2.8)),
                .ramp(center: SIMD2(0, -4.55), width: 0.9, length: 0.6, rise: 0.14, yaw: 0),
                .block(center: SIMD2(0.8, -5.0), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.14),
                critter(.hedgehog, at: SIMD2(-0.6, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.9, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.25, -4.15),
            cameraZoom: 1.7
        ),
    ]
}
