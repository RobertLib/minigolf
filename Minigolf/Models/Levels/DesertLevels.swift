//
//  DesertLevels.swift
//  Minigolf
//
//  Desert Oasis — where the garden is laid out in corridors, the desert is laid
//  out in *basins*. Every hole here is a wide pan of felt pinched to a neck and
//  opened out again, or a wadi split into channels by the rock between them, and
//  the boards that shape them run at an angle far more often than square: the
//  half-angle lane, the "V" and the long diagonal off one board are the three
//  standard obstacles that make a hole out of an open space rather than a lane.
//
//  So the silhouette to look for is an hourglass or a delta, never a corridor,
//  and the target is a shallow pan with the cup in it rather than a round green.
//

import Foundation
import simd

enum DesertCourse {

    static let holes: [LevelDefinition] = [
        // 1 — the hourglass. Two pans and a neck a hand wide between them: the
        //     whole hole is one aimed putt, and the neck is what it is aimed at.
        LevelDefinition(
            course: .desert, number: 1, name: String(localized: "Oasis Gate"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.55),
            floors: [
                floorRect(-0.85, 0.85, -1.20, 0.50),
                // Clear of the speed bump's foot: the mound is a fat cylinder
                // buried deep, and its flank reaches 0.13 m either side of the
                // crest — a trap laid over that is drawn inside the mound.
                floorRect(-0.85, -0.30, -1.20, -0.79, kind: .sand),
                floorRect(-0.24, 0.24, -1.90, -1.20),
                floorRect(-0.95, 0.95, -3.25, -1.90),
            ],
            wallLoops: [[
                SIMD2(-0.85, 0.50), SIMD2(0.85, 0.50), SIMD2(0.85, -1.20),
                SIMD2(0.24, -1.20), SIMD2(0.24, -1.90), SIMD2(0.95, -1.90),
                SIMD2(0.95, -3.25), SIMD2(-0.95, -3.25), SIMD2(-0.95, -1.90),
                SIMD2(-0.24, -1.90), SIMD2(-0.24, -1.20), SIMD2(-0.85, -1.20),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 1.6, height: 0.028, yaw: 0),
                critter(.meerkat, at: SIMD2(-0.52, -2.20), .burrow(period: 2.6)),
                critter(.tumbleweed, at: SIMD2(0, -2.95),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 1.2),
            ],
            bonusStar: SIMD2(0.70, -2.20),
            cameraZoom: 1.3
        ),
        // 2 — the "V" (WMF 17). Two long boards close in from the sides to a
        //     gap the width of three balls, with the cup straight behind it.
        //     There is a pocket at the foot of each arm, and nothing in it.
        LevelDefinition(
            course: .desert, number: 2, name: String(localized: "The Funnel"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.20),
            floors: [
                floorRect(-1.10, 1.10, -3.90, 0.50),
                // In front of the left arm rather than across it: a trap the
                // boards run through is cut in two, and half of it ends up in
                // the pocket, which is meant to be empty.
                floorRect(-1.10, -0.50, -1.36, -0.90, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.10, 1.10, -3.90, 0.50)],
            extraWalls: [
                wall(-1.10, -1.40, -0.12, -2.55),
                wall(1.10, -1.40, 0.12, -2.55),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.1, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.40, -1.10), radius: 0.045),
                .post(center: SIMD2(0.44, -1.05), radius: 0.045),
                critter(.tumbleweed, at: SIMD2(0, -1.75),
                        .patrol(axis: acrossLane, amplitude: 0.42), speed: 1.3),
                critter(.meerkat, at: SIMD2(-0.55, -3.05), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(-0.93, -1.80),
            cameraZoom: 1.5
        ),
        // 3 — blunt cones (WMF 12) in a lane that opens out in two steps, so
        //     each cone stands in a wider space than the one before it and the
        //     rebound off it has further to travel.
        LevelDefinition(
            course: .desert, number: 3, name: String(localized: "Blunt Cones"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.10),
            floors: [
                floorRect(-0.40, 0.40, -1.30, 0.50),
                floorRect(-0.80, 0.80, -2.30, -1.30),
                floorRect(-1.30, 1.30, -3.60, -2.30),
                floorRect(-1.30, -0.55, -3.30, -2.55, kind: .sand),
            ],
            wallLoops: [[
                SIMD2(-0.40, 0.50), SIMD2(0.40, 0.50), SIMD2(0.40, -1.30),
                SIMD2(0.80, -1.30), SIMD2(0.80, -2.30), SIMD2(1.30, -2.30),
                SIMD2(1.30, -3.60), SIMD2(-1.30, -3.60), SIMD2(-1.30, -2.30),
                SIMD2(-0.80, -2.30), SIMD2(-0.80, -1.30), SIMD2(-0.40, -1.30),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.8, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-0.28, -1.80), radius: 0.09),
                .bumper(center: SIMD2(0.38, -2.70), radius: 0.10),
                critter(.meerkat, at: SIMD2(0.55, -1.85), .burrow(period: 2.6)),
                critter(.tumbleweed, at: SIMD2(0, -3.38),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.05, -2.55),
            cameraZoom: 1.45
        ),
        // 4 — the wadi. Three dry channels cut through the rock, no two the
        //     same width: the left one is short and full of sand, the middle is
        //     open, the right is the narrowest and has a rise in it.
        LevelDefinition(
            course: .desert, number: 4, name: String(localized: "Three Wadis"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.35),
            floors: [
                floorRect(-1.35, 1.35, -1.10, 0.50),
                floorRect(-1.35, -0.85, -2.90, -1.10),
                floorRect(-1.35, -0.85, -2.60, -1.50, kind: .sand),
                floorRect(-0.35, 0.35, -2.90, -1.10),
                floorRect(0.90, 1.35, -2.90, -1.10),
                floorRect(-1.35, 1.35, -3.75, -2.90),
            ],
            wallLoops: [
                rectLoop(-1.35, 1.35, -3.75, 0.50),
                rectLoop(-0.85, -0.35, -2.90, -1.10),
                rectLoop(0.35, 0.90, -2.90, -1.10),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 2.6, height: 0.028, yaw: 0),
                .bump(center: SIMD2(1.125, -2.05), width: 0.42, height: 0.05, yaw: 0),
                .post(center: SIMD2(0, -1.55), radius: 0.045),
                critter(.meerkat, at: SIMD2(0, -2.45), .burrow(period: 2.4)),
                critter(.tumbleweed, at: SIMD2(0, -3.58),
                        .patrol(axis: acrossLane, amplitude: 0.75), speed: 1.4),
            ],
            bonusStar: SIMD2(1.12, -1.55),
            cameraZoom: 1.55
        ),
        // 5 — the step (Filzgolf 24). The green stands a hand above the pan and
        //     the cup sits dead in the middle of it, so the climb has to be
        //     driven hard enough to get up and softly enough to stay.
        LevelDefinition(
            course: .desert, number: 5, name: String(localized: "The Step"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.20), holeY: 0.12,
            floors: [
                floorRect(-0.90, 0.90, -3.00, 0.50),
                floorRect(-0.90, -0.20, -1.70, -1.05, kind: .sand),
                floorRect(-1.20, 1.20, -4.80, -3.60, y: 0.12),
            ],
            extraWalls: [
                wall(-0.90, 0.50, 0.90, 0.50),
                wall(-0.90, 0.50, -0.90, -3.00),
                wall(0.90, 0.50, 0.90, -3.00),
                wall(-0.90, -3.00, -0.25, -3.00, height: 0.24),
                wall(0.25, -3.00, 0.90, -3.00, height: 0.24),
                wall(-1.20, -3.60, -0.25, -3.60, height: 0.24),
                wall(0.25, -3.60, 1.20, -3.60, height: 0.24),
                wall(-1.20, -3.60, -1.20, -4.80, height: 0.24),
                wall(1.20, -3.60, 1.20, -4.80, height: 0.24),
                wall(-1.20, -4.80, 1.20, -4.80, height: 0.24),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.7, height: 0.03, yaw: 0),
                .ramp(center: SIMD2(0, -3.30), width: 0.5, length: 0.6, rise: 0.12, yaw: 0),
                .block(center: SIMD2(-0.64, -4.05), size: SIMD3(0.32, 0.14, 0.28),
                       yaw: 0, baseY: 0.12),
                .block(center: SIMD2(0.64, -4.42), size: SIMD3(0.32, 0.14, 0.28),
                       yaw: 0, baseY: 0.12),
                critter(.meerkat, at: SIMD2(0.30, -4.55), .burrow(period: 2.6), baseY: 0.12),
                critter(.tumbleweed, at: SIMD2(0, -1.40),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.3),
            ],
            bonusStar: SIMD2(-1.00, -4.55), bonusStarY: 0.12,
            cameraZoom: 1.5
        ),
        // 6 — the fork. A rock island splits the wadi: the left arm is wide and
        //     half of it is sand, the right is a clean channel two thirds the
        //     width. Both come out on the same pan.
        LevelDefinition(
            course: .desert, number: 6, name: String(localized: "Scorpion Rocks"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.80),
            floors: [
                floorRect(-1.45, 1.45, -1.30, 0.50),
                floorRect(-1.45, -0.40, -3.30, -1.30),
                floorRect(-1.45, -0.55, -2.95, -1.65, kind: .sand),
                floorRect(0.55, 1.45, -3.30, -1.30),
                floorRect(-1.45, 1.45, -4.20, -3.30),
            ],
            wallLoops: [
                rectLoop(-1.45, 1.45, -4.20, 0.50),
                rectLoop(-0.40, 0.55, -3.30, -1.30),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 2.8, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(1.00, -1.85), radius: 0.075),
                .bumper(center: SIMD2(1.00, -2.75), radius: 0.075),
                critter(.meerkat, at: SIMD2(-0.90, -3.05), .burrow(period: 2.8)),
                critter(.tumbleweed, at: SIMD2(0, -4.02),
                        .patrol(axis: acrossLane, amplitude: 0.85), speed: 1.4),
            ],
            bonusStar: SIMD2(1.22, -3.75),
            cameraZoom: 1.7
        ),
        // 7 — quicksand. The middle of the pan is one great sheet of it, and
        //     the firm going is the rim: a metre further round, and worth it.
        LevelDefinition(
            course: .desert, number: 7, name: String(localized: "Quicksand"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.90),
            floors: [
                floorRect(-1.40, 1.40, -3.10, 0.50),
                floorRect(-0.95, 0.95, -2.60, -0.85, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.40, 1.40, -3.10, 0.50)],
            obstacles: [
                .post(center: SIMD2(-1.18, -1.35), radius: 0.05),
                .post(center: SIMD2(1.18, -2.05), radius: 0.05),
                critter(.tumbleweed, at: SIMD2(1.18, -1.10),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.1),
                critter(.meerkat, at: SIMD2(-1.15, -2.50), .burrow(period: 2.4)),
            ],
            bonusStar: SIMD2(-1.20, -1.85),
            cameraZoom: 1.45
        ),
        // 8 — the humps. Two plateaus off the same pan, each up its own ramp:
        //     the cup on the far one, the star on the near one, and no way from
        //     either back to the other except down and round.
        LevelDefinition(
            course: .desert, number: 8, name: String(localized: "Camel Humps"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.90, -4.95), holeY: 0.12,
            floors: [
                floorRect(-1.55, 1.55, -5.80, 0.50),
                floorRect(-1.55, -0.25, -2.85, -1.95, y: 0.12),
                floorRect(0.25, 1.55, -5.35, -4.45, y: 0.12),
            ],
            wallLoops: [rectLoop(-1.55, 1.55, -5.80, 0.50)],
            extraWalls: [
                // Hump A, open only at its ramp mouth.
                wall(-1.55, -1.95, -1.15, -1.95, height: 0.24),
                wall(-0.65, -1.95, -0.25, -1.95, height: 0.24),
                wall(-0.25, -1.95, -0.25, -2.85, height: 0.24),
                wall(-1.55, -2.85, -0.25, -2.85, height: 0.24),
                wall(-1.55, -1.95, -1.55, -2.85, height: 0.24),
                // Hump B.
                wall(0.25, -4.45, 0.65, -4.45, height: 0.24),
                wall(1.15, -4.45, 1.55, -4.45, height: 0.24),
                wall(0.25, -4.45, 0.25, -5.35, height: 0.24),
                wall(0.25, -5.35, 1.55, -5.35, height: 0.24),
                wall(1.55, -4.45, 1.55, -5.35, height: 0.24),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 3.0, height: 0.03, yaw: 0),
                .ramp(center: SIMD2(-0.90, -1.65), width: 0.5, length: 0.6,
                      rise: 0.12, yaw: 0),
                .ramp(center: SIMD2(0.90, -4.15), width: 0.5, length: 0.6,
                      rise: 0.12, yaw: 0),
                .post(center: SIMD2(0.30, -2.30), radius: 0.05),
                critter(.tumbleweed, at: SIMD2(0.20, -1.30),
                        .patrol(axis: acrossLane, amplitude: 0.60), speed: 1.3),
                critter(.meerkat, at: SIMD2(-0.90, -2.55), .burrow(period: 2.6), baseY: 0.12),
                critter(.tumbleweed, at: SIMD2(-0.80, -5.50),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
            ],
            bonusStar: SIMD2(-0.90, -2.20), bonusStarY: 0.12,
            cameraZoom: 1.8
        ),
        // 9 — the sidewinder. Five short legs, each stepping off the last, so
        //     the hole crawls across the plot instead of running down it. Every
        //     turn is banked; a putt with the right weight takes two of them.
        LevelDefinition(
            course: .desert, number: 9, name: String(localized: "Sidewinder"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.40, -4.05),
            floors: [
                floorRect(-0.45, 0.45, -1.10, 0.50),
                floorRect(-0.45, 1.25, -1.90, -1.10),
                floorRect(0.35, 1.25, -2.70, -1.90),
                floorRect(-0.85, 1.25, -3.50, -2.70),
                floorRect(-0.85, 0.05, -4.40, -3.50),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -1.10),
                SIMD2(1.25, -1.10), SIMD2(1.25, -3.50), SIMD2(0.05, -3.50),
                SIMD2(0.05, -4.40), SIMD2(-0.85, -4.40), SIMD2(-0.85, -2.70),
                SIMD2(0.35, -2.70), SIMD2(0.35, -1.90), SIMD2(-0.45, -1.90),
            ]],
            extraWalls: arcWall(center: SIMD2(0.80, -1.55), radius: 0.45,
                                from: deg(0), to: deg(90), segments: 3)
                + arcWall(center: SIMD2(0.80, -3.05), radius: 0.45,
                          from: deg(270), to: deg(360), segments: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.05, -1.50), radius: 0.045),
                critter(.tumbleweed, at: SIMD2(0.80, -2.30),
                        .patrol(axis: alongLane, amplitude: 0.32), speed: 1.2),
                .post(center: SIMD2(-0.45, -3.10), radius: 0.045),
                critter(.meerkat, at: SIMD2(-0.40, -3.75), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.05, -2.30),
            cameraZoom: 1.8
        ),
        // 10 — the oasis. A ring of felt round standing water, and no bridge:
        //      the straight line at the flag is a stroke thrown away, so the
        //      hole is really about which way round is shorter from where the
        //      first putt leaves the ball.
        LevelDefinition(
            course: .desert, number: 10, name: String(localized: "The Oasis"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-1.50, 1.50, -1.20, 0.50),
                floorRect(-1.50, -0.60, -3.30, -1.20),
                floorRect(0.60, 1.50, -3.30, -1.20),
                floorRect(-1.50, 1.50, -4.20, -3.30),
                floorRect(-0.60, 0.60, -3.30, -1.20, kind: .water),
            ],
            wallLoops: [rectLoop(-1.50, 1.50, -4.20, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 2.9, height: 0.028, yaw: 0),
                .bumper(center: SIMD2(-1.05, -1.65), radius: 0.075),
                .bumper(center: SIMD2(1.05, -2.85), radius: 0.075),
                critter(.meerkat, at: SIMD2(-1.05, -2.60), .burrow(period: 2.8)),
                critter(.tumbleweed, at: SIMD2(0, -3.95),
                        .patrol(axis: acrossLane, amplitude: 0.85), speed: 1.4),
            ],
            bonusStar: SIMD2(1.25, -3.75),
            cameraZoom: 1.75
        ),
        // 11 — the sandstorm. The plot opens out in two steps and the wind
        //      crosses it in gusts, so the wide part is only wide while the
        //      blades are still.
        LevelDefinition(
            course: .desert, number: 11, name: String(localized: "Sandstorm"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.10, -3.85),
            floors: [
                floorRect(-0.55, 0.55, -1.30, 0.50),
                floorRect(-1.20, 1.20, -2.60, -1.30),
                floorRect(-1.75, 1.75, -4.30, -2.60),
                floorRect(0.35, 1.60, -4.10, -3.10, kind: .sand),
            ],
            wallLoops: [[
                SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -1.30),
                SIMD2(1.20, -1.30), SIMD2(1.20, -2.60), SIMD2(1.75, -2.60),
                SIMD2(1.75, -4.30), SIMD2(-1.75, -4.30), SIMD2(-1.75, -2.60),
                SIMD2(-1.20, -2.60), SIMD2(-1.20, -1.30), SIMD2(-0.55, -1.30),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.0, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.20, 1.20, -2.55, -1.35), direction: SIMD2(-1, 0),
                     strength: 2.4, period: 3.2, phase: 0, y: 0),
                // The gust stops at the drift it has piled up: wind blowing over
                // a sand trap draws its tint over the sand's own and works
                // against the damping, so the ball is shoved through the trap
                // instead of being held by it.
                .fan(rect: zone(-1.70, 0.35, -4.20, -2.65), direction: SIMD2(1, 0),
                     strength: 2.0, period: 3.2, phase: 1.6, y: 0),
                .gate(center: SIMD2(-0.55, -2.60), size: SIMD2(0.60, 0.13), yaw: 0,
                      period: 3.6, phase: 0.4, baseY: 0),
                .post(center: SIMD2(0.62, -2.95), radius: 0.05),
                critter(.tumbleweed, at: SIMD2(0, -3.30),
                        .patrol(axis: acrossLane, amplitude: 0.95), speed: 1.5),
                critter(.meerkat, at: SIMD2(-1.45, -3.20), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.50, -3.60),
            cameraZoom: 1.85
        ),
        // 12 — the crown. The hourglass again, then the wadi pan, then water
        //      with one causeway over it, and last a climb to the crown itself
        //      with the cup on top of it.
        LevelDefinition(
            course: .desert, number: 12, name: String(localized: "Desert Crown"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.45), holeY: 0.14,
            floors: [
                floorRect(-0.85, 0.85, -1.30, 0.50),
                floorRect(-0.26, 0.26, -1.95, -1.30),
                floorRect(-1.60, 1.60, -3.40, -1.95),
                floorRect(-1.60, -0.60, -3.10, -2.20, kind: .sand),
                floorRect(-1.60, -0.20, -4.05, -3.40, kind: .water),
                floorRect(-0.20, 0.20, -4.05, -3.40),
                floorRect(0.20, 1.60, -4.05, -3.40, kind: .water),
                floorRect(-1.60, 1.60, -4.45, -4.05),
                floorRect(-1.10, 1.10, -5.80, -5.05, y: 0.14),
            ],
            // The outline is open along the back edge, where the ramp climbs onto
            // the crown, so it is boarded as one chain rather than a ring: a ring
            // lays a board straight across the ramp mouth and seals the cup off.
            extraWalls: wallPath([
                SIMD2(-1.60, -4.45), SIMD2(-1.60, -1.95), SIMD2(-0.26, -1.95),
                SIMD2(-0.26, -1.30), SIMD2(-0.85, -1.30), SIMD2(-0.85, 0.50),
                SIMD2(0.85, 0.50), SIMD2(0.85, -1.30), SIMD2(0.26, -1.30),
                SIMD2(0.26, -1.95), SIMD2(1.60, -1.95), SIMD2(1.60, -4.45),
            ]) + [
                wall(-1.60, -4.45, -0.25, -4.45, height: 0.26),
                wall(0.25, -4.45, 1.60, -4.45, height: 0.26),
                wall(-1.10, -5.05, -0.25, -5.05, height: 0.26),
                wall(0.25, -5.05, 1.10, -5.05, height: 0.26),
                wall(-1.10, -5.05, -1.10, -5.80, height: 0.26),
                wall(1.10, -5.05, 1.10, -5.80, height: 0.26),
                wall(-1.10, -5.80, 1.10, -5.80, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 1.6, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(0.75, -2.45), radius: 0.08),
                // The bank stops where the sand begins, so it feeds the trap
                // instead of being laid over it: a slope that reaches into the
                // sand tints it twice over and creeps the ball out again.
                .slope(rect: zone(-0.60, 1.55, -3.35, -2.05), direction: SIMD2(-1, 0),
                       strength: 0.9, y: 0),
                critter(.tumbleweed, at: SIMD2(0.60, -3.00),
                        .patrol(axis: acrossLane, amplitude: 0.65), speed: 1.4),
                critter(.meerkat, at: SIMD2(-1.15, -4.25), .burrow(period: 2.6)),
                .ramp(center: SIMD2(0, -4.75), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .block(center: SIMD2(-0.72, -5.42), size: SIMD3(0.30, 0.14, 0.36),
                       yaw: 0, baseY: 0.14),
                critter(.tumbleweed, at: SIMD2(0.55, -5.60),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.1, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.35, -2.60),
            cameraZoom: 2.0
        ),
    ]
}
