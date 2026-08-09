//
//  JungleLevels.swift
//  Minigolf
//
//  Jungle Temple — architecture rather than landscape. Every hole is a plan of
//  rooms: courts of different sizes joined by doorways that never line up, a
//  cross-shaped cloister, a coil of corridors, and the labyrinth itself, which
//  is the one standard lane in the book with the cup in the middle of the
//  obstacle rather than beyond it. Four mouths open off its face and only one
//  of them leads anywhere.
//
//  So the silhouette here is a floor plan — stepped, chambered, right-angled —
//  and the felt is the space left between the walls rather than a lane laid on
//  the ground.
//

import Foundation
import simd

enum JungleCourse {

    static let holes: [LevelDefinition] = [
        // 1 — three courts, each stepped off the last, with the doorway between
        //     them at the far side from the one before. Nothing can be driven
        //     straight through: each room has to be crossed before the next one
        //     opens.
        LevelDefinition(
            course: .jungle, number: 1, name: String(localized: "Temple Steps"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.75, -3.35),
            floors: [
                floorRect(-0.55, 0.55, -1.10, 0.50),
                floorRect(-1.10, 0.30, -2.45, -1.10),
                floorRect(-0.30, 1.25, -3.75, -2.45),
            ],
            wallLoops: [[
                SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -1.10),
                SIMD2(0.30, -1.10), SIMD2(0.30, -2.45), SIMD2(1.25, -2.45),
                SIMD2(1.25, -3.75), SIMD2(-0.30, -3.75), SIMD2(-0.30, -2.45),
                SIMD2(-1.10, -2.45), SIMD2(-1.10, -1.10), SIMD2(-0.55, -1.10),
            ]],
            extraWalls: [
                // The first doorway, narrowed to a third of the wall it is in.
                wall(-1.10, -1.10, -0.50, -1.10),
                wall(-0.20, -1.10, 0.30, -1.10),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 1.0, height: 0.028, yaw: 0),
                // The second doorway is a gap beside a block rather than a wall.
                .block(center: SIMD2(-0.12, -2.45), size: SIMD3(0.36, 0.16, 0.10),
                       yaw: 0, baseY: 0),
                critter(.frog, at: SIMD2(-0.70, -1.85),
                        .hop(axis: acrossLane, amplitude: 0.28, height: 0.14), speed: 1.0),
                critter(.turtle, at: SIMD2(0.75, -2.95),
                        .patrol(axis: acrossLane, amplitude: 0.38), speed: 0.7),
            ],
            bonusStar: SIMD2(-0.90, -1.55),
            cameraZoom: 1.5
        ),
        // 2 — the windows (WMF 8). Three halls, each offset from the last, and
        //     the wall between them pierced by a single opening on the side the
        //     ball is not on.
        LevelDefinition(
            course: .jungle, number: 2, name: String(localized: "The Windows"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.60, -3.45),
            floors: [
                floorRect(-0.95, 0.95, -1.30, 0.50),
                floorRect(-1.25, 0.65, -2.55, -1.30),
                floorRect(-0.65, 1.25, -3.90, -2.55),
            ],
            wallLoops: [[
                SIMD2(-0.95, 0.50), SIMD2(0.95, 0.50), SIMD2(0.95, -1.30),
                SIMD2(0.65, -1.30), SIMD2(0.65, -2.55), SIMD2(1.25, -2.55),
                SIMD2(1.25, -3.90), SIMD2(-0.65, -3.90), SIMD2(-0.65, -2.55),
                SIMD2(-1.25, -2.55), SIMD2(-1.25, -1.30), SIMD2(-0.95, -1.30),
            ]],
            extraWalls: [
                wall(-1.25, -1.30, -0.80, -1.30),
                wall(-0.52, -1.30, 0.65, -1.30),
                wall(-0.65, -2.55, 0.50, -2.55),
                wall(0.78, -2.55, 1.25, -2.55),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.66, -1.90), radius: 0.045),
                critter(.turtle, at: SIMD2(0.10, -2.05),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 0.7),
                critter(.frog, at: SIMD2(0.60, -3.05),
                        .hop(axis: acrossLane, amplitude: 0.30, height: 0.15), speed: 1.1),
            ],
            bonusStar: SIMD2(-1.05, -1.75),
            cameraZoom: 1.6
        ),
        // 3 — the cross (Filzgolf 25). A cloister in the shape of a plus, with
        //     a stone set corner-on where the arms meet: the cup is straight
        //     ahead, and the only lines to it are off the wings.
        LevelDefinition(
            course: .jungle, number: 3, name: String(localized: "The Cloister"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-0.50, 0.50, -4.40, 0.50),
                floorRect(-1.60, 1.60, -3.40, -2.50),
                floorRect(-1.60, -0.85, -3.25, -2.65, kind: .mud),
            ],
            wallLoops: [[
                SIMD2(-0.50, 0.50), SIMD2(0.50, 0.50), SIMD2(0.50, -2.50),
                SIMD2(1.60, -2.50), SIMD2(1.60, -3.40), SIMD2(0.50, -3.40),
                SIMD2(0.50, -4.40), SIMD2(-0.50, -4.40), SIMD2(-0.50, -3.40),
                SIMD2(-1.60, -3.40), SIMD2(-1.60, -2.50), SIMD2(-0.50, -2.50),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.9, height: 0.03, yaw: 0),
                .block(center: SIMD2(0, -2.95), size: SIMD3(0.34, 0.16, 0.34),
                       yaw: deg(45), baseY: 0),
                critter(.turtle, at: SIMD2(1.20, -2.95),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 0.7),
                critter(.frog, at: SIMD2(0, -3.75),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.15), speed: 1.1),
            ],
            bonusStar: SIMD2(1.35, -2.75),
            cameraZoom: 1.6
        ),
        // 4 — the ford. The river crosses in two staggered reaches with a bar
        //     of gravel between them, so the crossing is a zig: right first,
        //     then left, and a straight putt at the flag is in the water.
        LevelDefinition(
            course: .jungle, number: 4, name: String(localized: "River Crossing"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-0.55, -4.05),
            floors: [
                floorRect(-1.05, 1.05, -2.20, 0.50),
                floorRect(-1.05, -0.15, -2.90, -2.20, kind: .water),
                floorRect(-0.15, 1.05, -2.90, -2.20),
                floorRect(0.20, 1.05, -3.60, -2.90, kind: .water),
                floorRect(-1.05, 0.20, -3.60, -2.90),
                floorRect(-1.05, 1.05, -4.40, -3.60),
            ],
            wallLoops: [rectLoop(-1.05, 1.05, -4.40, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 2.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.62, -1.05), radius: 0.045),
                critter(.turtle, at: SIMD2(0.60, -2.55),
                        .patrol(axis: alongLane, amplitude: 0.22), speed: 0.6),
                critter(.frog, at: SIMD2(-0.60, -3.25),
                        .hop(axis: alongLane, amplitude: 0.22, height: 0.16), speed: 1.0),
            ],
            bonusStar: SIMD2(0.85, -4.10),
            cameraZoom: 1.55
        ),
        // 5 — the terrace. A corridor into a court, and the court's far side is
        //     a step up onto the temple platform with the cup on it. The ramp
        //     is half the width of the court it leaves.
        LevelDefinition(
            course: .jungle, number: 5, name: String(localized: "Temple Terrace"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.20), holeY: 0.13,
            floors: [
                floorRect(-0.45, 0.45, -1.40, 0.50),
                floorRect(-1.35, 1.35, -3.20, -1.40),
                floorRect(-1.35, -0.55, -2.95, -1.85, kind: .mud),
                floorRect(-1.00, 1.00, -4.60, -3.80, y: 0.13),
            ],
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -1.40),
                wall(0.45, 0.50, 0.45, -1.40),
                wall(-1.35, -1.40, -0.45, -1.40),
                wall(0.45, -1.40, 1.35, -1.40),
                wall(-1.35, -1.40, -1.35, -3.20),
                wall(1.35, -1.40, 1.35, -3.20),
                wall(-1.35, -3.20, -0.25, -3.20, height: 0.26),
                wall(0.25, -3.20, 1.35, -3.20, height: 0.26),
                wall(-1.00, -3.80, -0.25, -3.80, height: 0.26),
                wall(0.25, -3.80, 1.00, -3.80, height: 0.26),
                wall(-1.00, -3.80, -1.00, -4.60, height: 0.26),
                wall(1.00, -3.80, 1.00, -4.60, height: 0.26),
                wall(-1.00, -4.60, 1.00, -4.60, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.70, -2.10), radius: 0.05),
                .post(center: SIMD2(-0.30, -2.75), radius: 0.05),
                critter(.turtle, at: SIMD2(0.80, -2.80),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 0.7),
                .ramp(center: SIMD2(0, -3.50), width: 0.5, length: 0.6,
                      rise: 0.13, yaw: 0),
                critter(.frog, at: SIMD2(-0.55, -4.30),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.15),
                        speed: 1.0, baseY: 0.13),
            ],
            bonusStar: SIMD2(0.78, -4.40), bonusStarY: 0.13,
            cameraZoom: 1.75
        ),
        // 6 — the gallery. One long narrow room with two alcoves off it and a
        //     vine swinging across at each third: the alcoves are the only
        //     shelter, and one of them has the star in it.
        LevelDefinition(
            course: .jungle, number: 6, name: String(localized: "Swinging Vines"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-0.55, 0.55, -4.40, 0.50),
                floorRect(-1.20, -0.55, -2.20, -1.50),
                floorRect(0.55, 1.20, -3.40, -2.70),
            ],
            wallLoops: [[
                SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -2.70),
                SIMD2(1.20, -2.70), SIMD2(1.20, -3.40), SIMD2(0.55, -3.40),
                SIMD2(0.55, -4.40), SIMD2(-0.55, -4.40), SIMD2(-0.55, -2.20),
                SIMD2(-1.20, -2.20), SIMD2(-1.20, -1.50), SIMD2(-0.55, -1.50),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -1.25), span: 0.9, arc: deg(46),
                          speed: 1.5, yaw: 0, baseY: 0),
                .pendulum(center: SIMD2(0, -2.45), span: 0.9, arc: deg(46),
                          speed: 1.8, yaw: 0, baseY: 0),
                .pendulum(center: SIMD2(0, -3.65), span: 0.9, arc: deg(46),
                          speed: 1.6, yaw: 0, baseY: 0),
                critter(.turtle, at: SIMD2(0.88, -3.05),
                        .patrol(axis: alongLane, amplitude: 0.20), speed: 0.6),
                critter(.frog, at: SIMD2(0, -4.20),
                        .hop(axis: acrossLane, amplitude: 0.24, height: 0.15), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.92, -1.85),
            cameraZoom: 1.8
        ),
        // 7 — the labyrinth (WMF 11). Four mouths open off its face and three
        //     of them are cells with nothing in them; the second from the left
        //     runs through to the chamber in the middle, where the cup is. The
        //     lane in is narrower than the face, so the right mouth has to be
        //     reached off a board.
        LevelDefinition(
            course: .jungle, number: 7, name: String(localized: "The Labyrinth"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.80),
            floors: [
                floorRect(-0.45, 0.45, -1.60, 0.50),
                floorRect(-1.50, 1.50, -4.30, -1.60),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -1.60),
                SIMD2(1.50, -1.60), SIMD2(1.50, -4.30), SIMD2(-1.50, -4.30),
                SIMD2(-1.50, -1.60), SIMD2(-0.45, -1.60),
            ]],
            extraWalls: [
                // The face, with its four mouths.
                wall(-1.50, -2.30, -1.20, -2.30),
                wall(-0.95, -2.30, -0.55, -2.30),
                wall(-0.30, -2.30, 0.30, -2.30),
                wall(0.55, -2.30, 0.95, -2.30),
                wall(1.20, -2.30, 1.50, -2.30),
                // The cells behind it.
                wall(-0.75, -2.30, -0.75, -3.30),
                wall(0, -2.30, 0, -3.30),
                wall(0.75, -2.30, 0.75, -3.30),
                wall(-1.50, -3.30, -0.75, -3.30),
                wall(0, -3.30, 1.50, -3.30),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.95, -1.90), radius: 0.045),
                critter(.turtle, at: SIMD2(-0.38, -2.80),
                        .patrol(axis: alongLane, amplitude: 0.24), speed: 0.6),
                critter(.frog, at: SIMD2(0, -4.05),
                        .hop(axis: acrossLane, amplitude: 0.40, height: 0.16), speed: 1.1),
            ],
            bonusStar: SIMD2(1.12, -2.85),
            cameraZoom: 1.85
        ),
        // 8 — twin galleries. Two long rooms with no door between them except
        //     the pair of portals halfway down, and a link round the far end
        //     for anyone who misses them — four times as far.
        LevelDefinition(
            course: .jungle, number: 8, name: String(localized: "Twin Portals"), par: 4,
            tee: SIMD2(-0.75, 0), hole: SIMD2(0.75, -4.05),
            floors: [
                floorRect(-1.30, -0.20, -4.40, 0.50),
                floorRect(0.20, 1.30, -4.40, 0.50),
                floorRect(-1.30, 1.30, -5.10, -4.40),
                floorRect(-1.30, -0.20, -3.60, -2.80, kind: .mud),
            ],
            wallLoops: [[
                SIMD2(-1.30, 0.50), SIMD2(-0.20, 0.50), SIMD2(-0.20, -4.40),
                SIMD2(0.20, -4.40), SIMD2(0.20, 0.50), SIMD2(1.30, 0.50),
                SIMD2(1.30, -5.10), SIMD2(-1.30, -5.10),
            ]],
            obstacles: [
                .bump(center: SIMD2(-0.75, -0.70), width: 1.0, height: 0.03, yaw: 0),
                .teleporter(a: SIMD2(-0.75, -2.40), b: SIMD2(0.75, -1.20),
                            radius: 0.13, y: 0),
                .post(center: SIMD2(0.75, -2.05), radius: 0.045),
                critter(.turtle, at: SIMD2(0.75, -3.10),
                        .patrol(axis: acrossLane, amplitude: 0.24), speed: 0.7),
                critter(.frog, at: SIMD2(-0.75, -4.75),
                        .hop(axis: acrossLane, amplitude: 0.34, height: 0.16), speed: 1.0),
            ],
            bonusStar: SIMD2(0.28, -4.75),
            cameraZoom: 1.9
        ),
        // 9 — the coil. One wall hangs off the left of the court and a second
        //     drops from the end of it, so the way in to the middle runs down
        //     the outside, along the bottom and back up: a G rather than a
        //     lane, and the cup is in the eye of it.
        LevelDefinition(
            course: .jungle, number: 9, name: String(localized: "Serpent Coil"), par: 4,
            tee: SIMD2(0.90, 0), hole: SIMD2(-0.30, -2.05),
            floors: [
                floorRect(-1.30, 1.30, -3.80, 0.50),
                floorRect(-1.30, -0.30, -2.55, -1.55, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.30, 1.30, -3.80, 0.50)],
            extraWalls: [
                wall(-1.30, -1.30, 0.50, -1.30),
                wall(0.50, -1.30, 0.50, -2.60),
            ],
            obstacles: [
                .bump(center: SIMD2(0.90, -0.70), width: 0.75, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.92, -2.20), radius: 0.05),
                critter(.turtle, at: SIMD2(0, -3.30),
                        .patrol(axis: acrossLane, amplitude: 0.60), speed: 0.8),
                critter(.frog, at: SIMD2(-0.95, -2.05),
                        .hop(axis: alongLane, amplitude: 0.26, height: 0.15), speed: 1.0),
            ],
            bonusStar: SIMD2(-1.05, -0.85),
            cameraZoom: 1.7
        ),
        // 10 — the run. A long corridor with the cats' gauntlet in it, a hard
        //      left into the mud gallery, and a bay at the end of that with the
        //      cup tucked into its far corner.
        LevelDefinition(
            course: .jungle, number: 10, name: String(localized: "Jaguar Run"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.75, -4.05),
            floors: [
                floorRect(-0.50, 0.50, -2.60, 0.50),
                floorRect(-0.50, 2.20, -3.60, -2.60),
                floorRect(0.30, 2.20, -3.45, -2.75, kind: .mud),
                floorRect(1.30, 2.20, -4.40, -3.60),
            ],
            wallLoops: [[
                SIMD2(-0.50, 0.50), SIMD2(0.50, 0.50), SIMD2(0.50, -2.60),
                SIMD2(2.20, -2.60), SIMD2(2.20, -4.40), SIMD2(1.30, -4.40),
                SIMD2(1.30, -3.60), SIMD2(-0.50, -3.60),
            ]],
            extraWalls: arcWall(center: SIMD2(-0.05, -3.05), radius: 0.55,
                                from: deg(180), to: deg(270), segments: 4),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                .rotor(center: SIMD2(0, -1.40), length: 0.7, speed: 1.6, baseY: 0),
                .rotor(center: SIMD2(0, -2.20), length: 0.7, speed: -1.9, baseY: 0),
                critter(.turtle, at: SIMD2(1.20, -3.10),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 0.7),
                critter(.frog, at: SIMD2(1.75, -3.85),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.15), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.26, -3.32),
            cameraZoom: 1.85
        ),
        // 11 — the stair. Court, ramp, and an L-shaped platform above it: the
        //      cup is round the corner of the upper floor, so the climb has to
        //      be finished before the hole can even be seen.
        LevelDefinition(
            course: .jungle, number: 11, name: String(localized: "Serpent Stair"), par: 4,
            tee: SIMD2(-0.35, 0), hole: SIMD2(1.10, -4.05), holeY: 0.13,
            floors: [
                floorRect(-1.10, 0.40, -3.00, 0.50),
                floorRect(-1.10, 1.60, -4.50, -3.60, y: 0.13),
            ],
            extraWalls: [
                wall(-1.10, 0.50, 0.40, 0.50),
                wall(-1.10, 0.50, -1.10, -3.00),
                wall(0.40, 0.50, 0.40, -3.00),
                wall(-1.10, -3.00, -0.60, -3.00, height: 0.26),
                wall(-0.10, -3.00, 0.40, -3.00, height: 0.26),
                wall(-1.10, -3.60, -0.60, -3.60, height: 0.26),
                wall(-0.10, -3.60, 1.60, -3.60, height: 0.26),
                wall(-1.10, -3.60, -1.10, -4.50, height: 0.26),
                wall(-1.10, -4.50, 1.60, -4.50, height: 0.26),
                wall(1.60, -3.60, 1.60, -4.50, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(-0.35, -0.75), width: 1.4, height: 0.03, yaw: 0),
                .ramp(center: SIMD2(-0.35, -3.30), width: 0.5, length: 0.6,
                      rise: 0.13, yaw: 0),
                .block(center: SIMD2(0.35, -4.15), size: SIMD3(0.16, 0.14, 0.44),
                       yaw: 0, baseY: 0.13),
                critter(.turtle, at: SIMD2(-0.60, -4.05),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 0.7, baseY: 0.13),
                critter(.frog, at: SIMD2(1.10, -4.30),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.15),
                        speed: 1.1, baseY: 0.13),
            ],
            bonusStar: SIMD2(-0.88, -1.45),
            cameraZoom: 1.7
        ),
        // 12 — the lost temple: the corridor, the great hall, the river with
        //      one causeway over it, the inner court and the high platform, in
        //      that order and with no way of skipping any of them.
        LevelDefinition(
            course: .jungle, number: 12, name: String(localized: "Lost Temple"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.80), holeY: 0.14,
            floors: [
                floorRect(-0.50, 0.50, -1.50, 0.50),
                floorRect(-1.50, 1.50, -3.00, -1.50),
                floorRect(-1.50, -0.55, -2.85, -1.95, kind: .mud),
                floorRect(-1.50, -0.25, -3.60, -3.00, kind: .water),
                floorRect(-0.25, 0.25, -3.60, -3.00),
                floorRect(0.25, 1.50, -3.60, -3.00, kind: .water),
                floorRect(-1.50, 1.50, -4.85, -3.60),
                floorRect(-1.10, 1.10, -6.15, -5.45, y: 0.14),
            ],
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -1.50),
                wall(0.50, 0.50, 0.50, -1.50),
                wall(-1.50, -1.50, -0.50, -1.50),
                wall(0.50, -1.50, 1.50, -1.50),
                wall(-1.50, -1.50, -1.50, -4.85),
                wall(1.50, -1.50, 1.50, -4.85),
                wall(-1.50, -4.85, -0.25, -4.85, height: 0.26),
                wall(0.25, -4.85, 1.50, -4.85, height: 0.26),
                wall(-1.10, -5.45, -0.25, -5.45, height: 0.26),
                wall(0.25, -5.45, 1.10, -5.45, height: 0.26),
                wall(-1.10, -5.45, -1.10, -6.15, height: 0.26),
                wall(1.10, -5.45, 1.10, -6.15, height: 0.26),
                wall(-1.10, -6.15, 1.10, -6.15, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -2.10), span: 1.1, arc: deg(50),
                          speed: 1.6, yaw: 0, baseY: 0),
                .post(center: SIMD2(0.95, -2.60), radius: 0.05),
                critter(.turtle, at: SIMD2(-0.95, -3.95),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 0.7),
                .ramp(center: SIMD2(0, -5.15), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .block(center: SIMD2(-0.72, -5.75), size: SIMD3(0.30, 0.14, 0.36),
                       yaw: 0, baseY: 0.14),
                critter(.frog, at: SIMD2(0.55, -5.95),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.15),
                        speed: 1.1, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.28, -3.95),
            cameraZoom: 2.0
        ),
    ]
}
