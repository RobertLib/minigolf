//
//  VolcanoLevels.swift
//  Minigolf
//
//  Volcano Forge — the world laid out in rings. Where the neon course is square
//  and the desert diagonal, everything here is concentric: a cone with the cup
//  in the crater on top of it (the standard "Vulkan" lane, and the only one in
//  the book where the target stands above the felt rather than in it), craters
//  with a ring of stone round them, a moat with one causeway over it, and fields
//  pitted with vents that have to be threaded rather than crossed.
//
//  Lava is the boundary rather than the boards: for most of these holes the felt
//  simply stops, and where it stops there is nothing to bank off.
//

import Foundation
import simd

enum VolcanoCourse {

    static let holes: [LevelDefinition] = [
        // 1 — the causeway. A metre of felt across the flow with nothing at its
        //     edges, opening into a round green on the far side.
        LevelDefinition(
            course: .volcano, number: 1, name: String(localized: "Forge Gate"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.65),
            floors: [
                floorRect(-0.45, 0.45, -3.50, 0.50),
                floorRect(-1.30, -0.45, -3.50, -0.70, kind: .lava),
                floorRect(0.45, 1.30, -3.50, -0.70, kind: .lava),
            ] + roundedFloor(-1.30, 1.30, -5.50, -3.50, far: 0.42, steps: 3),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -0.70),
                wall(0.45, 0.50, 0.45, -0.70),
            ] + roundedKerb(-1.30, 1.30, -5.50, -3.50, far: 0.42, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.40), width: 0.9, height: 0.028, yaw: 0),
                critter(.imp, at: SIMD2(0, -1.60),
                        .patrol(axis: acrossLane, amplitude: 0.18), speed: 1.2),
                .post(center: SIMD2(-0.22, -2.30), radius: 0.04),
                critter(.magmaBlob, at: SIMD2(0, -4.95),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 0.9),
            ],
            bonusStar: SIMD2(1.05, -3.90),
            cameraZoom: 1.8
        ),
        // 2 — the volcano itself (WMF 16). A moat of lava with one plank across
        //     it, a ramp up the flank and a crater on top with the cup in it:
        //     the only hole on the course where the target is over your head.
        LevelDefinition(
            course: .volcano, number: 2, name: String(localized: "The Cone"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.95), holeY: 0.16,
            floors: [
                floorRect(-1.60, 1.60, -3.50, 0.50),
                floorRect(-0.30, 0.30, -3.90, -3.50),
                floorRect(-1.60, -0.30, -5.80, -3.50, kind: .lava),
                floorRect(0.30, 1.60, -5.80, -3.50, kind: .lava),
                floorRect(-0.30, 0.30, -5.80, -3.90, kind: .lava),
                floorRect(-0.70, 0.70, -5.40, -4.50, y: 0.16),
            ],
            extraWalls: [
                wall(-1.60, 0.50, 1.60, 0.50),
                wall(-1.60, 0.50, -1.60, -3.50),
                wall(1.60, 0.50, 1.60, -3.50),
                wall(-1.60, -3.50, -0.30, -3.50),
                wall(0.30, -3.50, 1.60, -3.50),
                // The crater rim: it stands out of the lava, so one board is
                // both the flank of the cone and the kerb round the green.
                wall(-0.70, -4.50, -0.25, -4.50, height: 0.34),
                wall(0.25, -4.50, 0.70, -4.50, height: 0.34),
                wall(-0.70, -4.50, -0.70, -5.40, height: 0.34),
                wall(0.70, -4.50, 0.70, -5.40, height: 0.34),
                wall(-0.70, -5.40, 0.70, -5.40, height: 0.34),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 3.1, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-0.75, -1.70), radius: 0.08),
                .bumper(center: SIMD2(0.75, -1.70), radius: 0.08),
                critter(.imp, at: SIMD2(0, -2.15),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 1.3),
                .ramp(center: SIMD2(0, -4.20), width: 0.5, length: 0.6,
                      rise: 0.16, yaw: 0),
                critter(.magmaBlob, at: SIMD2(0, -5.20),
                        .patrol(axis: acrossLane, amplitude: 0.20), speed: 0.8, baseY: 0.16),
            ],
            bonusStar: SIMD2(1.40, -2.25),
            cameraZoom: 1.9
        ),
        // 3 — the crater. A ring of stone round the vent, and the two ways
        //     round it are not the same: the west rim is half the width of the
        //     east one and a metre shorter.
        LevelDefinition(
            course: .volcano, number: 3, name: String(localized: "Crater Ring"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.75),
            floors: [
                floorRect(-1.50, 1.50, -2.10, 0.50),
                floorRect(-1.50, -0.90, -4.30, -2.10),
                floorRect(0.55, 1.50, -4.30, -2.10),
                floorRect(-1.50, 1.50, -5.20, -4.30),
                floorRect(-0.90, 0.55, -4.30, -2.10, kind: .lava),
            ],
            wallLoops: [rectLoop(-1.50, 1.50, -5.20, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 2.9, height: 0.028, yaw: 0),
                .post(center: SIMD2(1.02, -2.75), radius: 0.05),
                .post(center: SIMD2(1.02, -3.65), radius: 0.05),
                critter(.imp, at: SIMD2(-1.20, -3.20),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.2),
                critter(.magmaBlob, at: SIMD2(0, -4.95),
                        .patrol(axis: acrossLane, amplitude: 0.80), speed: 0.9),
            ],
            bonusStar: SIMD2(-1.25, -3.95),
            cameraZoom: 1.8
        ),
        // 4 — the side vent (Filzgolf 17). The climb runs straight, but the cup
        //     is not on the platform it lands on: it is round the corner in a
        //     pocket off the side of it, out of sight from the tee.
        LevelDefinition(
            course: .volcano, number: 4, name: String(localized: "Side Vent"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.65, -3.70), holeY: 0.14,
            floors: [
                floorRect(-1.20, 1.20, -2.70, 0.50),
                floorRect(-1.20, 1.20, -4.10, -3.30, y: 0.14),
                floorRect(-2.10, -1.20, -4.10, -3.30, y: 0.14),
                floorRect(-1.10, 1.10, -2.10, -1.15, kind: .mud),
            ],
            extraWalls: [
                wall(-1.20, 0.50, 1.20, 0.50),
                wall(-1.20, 0.50, -1.20, -2.70),
                wall(1.20, 0.50, 1.20, -2.70),
                wall(-1.20, -2.70, -0.25, -2.70, height: 0.26),
                wall(0.25, -2.70, 1.20, -2.70, height: 0.26),
                wall(-2.10, -3.30, -0.25, -3.30, height: 0.26),
                wall(0.25, -3.30, 1.20, -3.30, height: 0.26),
                wall(-2.10, -3.30, -2.10, -4.10, height: 0.26),
                wall(-2.10, -4.10, 1.20, -4.10, height: 0.26),
                wall(1.20, -3.30, 1.20, -4.10, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.3, height: 0.03, yaw: 0),
                .ramp(center: SIMD2(0, -3.00), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .block(center: SIMD2(0.30, -3.70), size: SIMD3(0.16, 0.14, 0.50),
                       yaw: 0, baseY: 0.14),
                critter(.imp, at: SIMD2(-0.70, -3.70),
                        .patrol(axis: alongLane, amplitude: 0.24), speed: 1.2, baseY: 0.14),
                critter(.magmaBlob, at: SIMD2(0.85, -3.70),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 0.8, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.00, -1.60),
            cameraZoom: 1.9
        ),
        // 5 — the chamber. A slot into a round hall with an obsidian plug in
        //     the middle of it: every line to the cup is a line off the wall,
        //     and the wall is a circle.
        LevelDefinition(
            course: .volcano, number: 5, name: String(localized: "Magma Chamber"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.80),
            floors: [
                floorRect(-0.45, 0.45, -2.30, 0.50),
            ] + roundedFloor(-1.60, 1.60, -5.60, -2.30, far: 0.42, near: 0.42, steps: 3),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -2.30),
                wall(0.45, 0.50, 0.45, -2.30),
                wall(-1.18, -2.30, -0.45, -2.30),
                wall(0.45, -2.30, 1.18, -2.30),
            ] + roundedKerb(-1.60, 1.60, -5.60, -2.30,
                        far: 0.42, near: 0.42, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.9, height: 0.03, yaw: 0),
                .block(center: SIMD2(0, -3.65), size: SIMD3(0.85, 0.18, 0.85),
                       yaw: deg(45), baseY: 0),
                .bumper(center: SIMD2(-1.10, -3.00), radius: 0.08),
                .bumper(center: SIMD2(1.10, -3.00), radius: 0.08),
                critter(.imp, at: SIMD2(0, -5.25),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.3),
                critter(.magmaBlob, at: SIMD2(-1.15, -4.40),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 0.8),
            ],
            bonusStar: SIMD2(1.25, -4.40),
            cameraZoom: 1.95
        ),
        // 6 — ash. Three halls, wide, narrow, wide, all of them under a hand's
        //     depth of it, and an iron shutter in each doorway.
        LevelDefinition(
            course: .volcano, number: 6, name: String(localized: "Ash Fall"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.10),
            floors: [
                floorRect(-0.90, 0.90, -2.50, 0.50),
                floorRect(-1.60, 1.60, -4.40, -2.50),
                floorRect(-1.50, 1.50, -4.30, -2.60, kind: .mud),
                floorRect(-0.90, 0.90, -5.60, -4.40),
            ],
            wallLoops: [[
                SIMD2(-0.90, 0.50), SIMD2(0.90, 0.50), SIMD2(0.90, -2.50),
                SIMD2(1.60, -2.50), SIMD2(1.60, -4.40), SIMD2(0.90, -4.40),
                SIMD2(0.90, -5.60), SIMD2(-0.90, -5.60), SIMD2(-0.90, -4.40),
                SIMD2(-1.60, -4.40), SIMD2(-1.60, -2.50), SIMD2(-0.90, -2.50),
            ]],
            obstacles: [
                .gate(center: SIMD2(0, -1.05), size: SIMD2(0.90, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.15, -3.10), radius: 0.08),
                .bumper(center: SIMD2(1.15, -3.80), radius: 0.08),
                .gate(center: SIMD2(0, -4.80), size: SIMD2(0.90, 0.13), yaw: 0,
                      period: 3.4, phase: 1.2, baseY: 0),
                critter(.imp, at: SIMD2(0, -3.45),
                        .patrol(axis: acrossLane, amplitude: 0.60), speed: 1.3),
                critter(.magmaBlob, at: SIMD2(0, -5.35),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 0.8),
            ],
            bonusStar: SIMD2(1.35, -3.45),
            cameraZoom: 1.9
        ),
        // 7 — obsidian. Two long blades of it cross the plot from opposite
        //     boards, and each leaves its gap at the far end from the last, so
        //     the hole is walked corner to corner.
        LevelDefinition(
            course: .volcano, number: 7, name: String(localized: "Obsidian Bank"), par: 5,
            tee: SIMD2(-0.40, 0), hole: SIMD2(0.85, -4.70),
            floors: [
                floorRect(-1.60, 0.80, -2.60, 0.50),
                floorRect(-1.60, 1.60, -4.10, -2.60),
                floorRect(-0.80, 1.60, -5.20, -4.10),
            ],
            wallLoops: [[
                SIMD2(-1.60, 0.50), SIMD2(0.80, 0.50), SIMD2(0.80, -2.60),
                SIMD2(1.60, -2.60), SIMD2(1.60, -5.20), SIMD2(-0.80, -5.20),
                SIMD2(-0.80, -4.10), SIMD2(-1.60, -4.10),
            ]],
            extraWalls: [
                wall(-1.60, -1.30, 0.30, -2.05),
                wall(1.60, -3.10, -0.60, -3.85),
            ],
            obstacles: [
                .bump(center: SIMD2(-0.40, -0.70), width: 2.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.55, -1.55), radius: 0.05),
                critter(.imp, at: SIMD2(0.90, -2.95),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.3),
                .bumper(center: SIMD2(-1.15, -3.30), radius: 0.08),
                critter(.magmaBlob, at: SIMD2(0.85, -4.95),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 0.9),
            ],
            bonusStar: SIMD2(-1.35, -3.40),
            cameraZoom: 2.0
        ),
        // 8 — the crucible. A hall, a lip across the mouth of the basin, and
        //     the basin itself: over the lip too hard and the ball goes round
        //     the far wall and back out of it.
        LevelDefinition(
            course: .volcano, number: 8, name: String(localized: "The Crucible"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -5.10),
            floors: [
                floorRect(-0.45, 0.45, -2.60, 0.50),
                floorRect(-1.40, 1.40, -4.00, -2.60),
            ] + roundedFloor(-1.30, 1.30, -6.00, -4.00, far: 0.42, steps: 3),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -2.60),
                wall(0.45, 0.50, 0.45, -2.60),
                wall(-1.40, -2.60, -0.45, -2.60),
                wall(0.45, -2.60, 1.40, -2.60),
                wall(-1.40, -2.60, -1.40, -4.00),
                wall(1.40, -2.60, 1.40, -4.00),
                wall(-1.40, -4.00, -1.30, -4.00),
                wall(1.30, -4.00, 1.40, -4.00),
            ] + roundedKerb(-1.30, 1.30, -6.00, -4.00, far: 0.42, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.22, -1.75), radius: 0.045),
                critter(.imp, at: SIMD2(0, -3.30),
                        .patrol(axis: acrossLane, amplitude: 0.60), speed: 1.3),
                // The lip: a rise right across the mouth of the basin.
                .bump(center: SIMD2(0, -4.15), width: 2.4, height: 0.06, yaw: 0),
                .bumper(center: SIMD2(0, -4.85), radius: 0.09),
                critter(.magmaBlob, at: SIMD2(0, -5.65),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 0.9),
            ],
            bonusStar: SIMD2(-1.05, -5.10),
            cameraZoom: 2.0
        ),
        // 9 — the flow. Three channels between two running streams, and the
        //     widest of them is the one that comes out furthest from the cup.
        LevelDefinition(
            course: .volcano, number: 9, name: String(localized: "Lava Flow"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.95),
            floors: [
                floorRect(-1.70, 1.70, -1.20, 0.50),
                floorRect(-1.70, -1.10, -4.40, -1.20),
                floorRect(-1.10, -0.55, -4.40, -1.20, kind: .lava),
                floorRect(-0.55, 0.35, -4.40, -1.20),
                floorRect(0.35, 0.95, -4.40, -1.20, kind: .lava),
                floorRect(0.95, 1.70, -4.40, -1.20),
                floorRect(-1.70, 1.70, -5.40, -4.40),
            ],
            wallLoops: [rectLoop(-1.70, 1.70, -5.40, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 3.3, height: 0.028, yaw: 0),
                .post(center: SIMD2(-0.10, -2.10), radius: 0.05),
                .post(center: SIMD2(-0.10, -3.30), radius: 0.05),
                critter(.imp, at: SIMD2(1.32, -2.60),
                        .patrol(axis: alongLane, amplitude: 0.34), speed: 1.3),
                critter(.magmaBlob, at: SIMD2(-1.40, -3.40),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 0.8),
                .bumper(center: SIMD2(0, -4.70), radius: 0.08),
            ],
            bonusStar: SIMD2(-1.40, -4.85),
            cameraZoom: 2.05
        ),
        // 10 — the terrace. The upper floor is split down the middle by a vent,
        //      and the ramp lands on the wrong side of it: the cup is on the
        //      other, round the far end.
        LevelDefinition(
            course: .volcano, number: 10, name: String(localized: "Forge Terrace"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.95, -3.70), holeY: 0.15,
            floors: [
                floorRect(-1.50, 1.50, -2.40, 0.50),
                floorRect(-1.50, -0.35, -4.40, -3.00, y: 0.15),
                floorRect(0.45, 1.50, -4.40, -3.00, y: 0.15),
                floorRect(-0.35, 0.45, -4.40, -3.00, kind: .lava, y: 0.15),
                floorRect(-1.50, 1.50, -5.10, -4.40, y: 0.15),
            ],
            extraWalls: [
                wall(-1.50, 0.50, 1.50, 0.50),
                wall(-1.50, 0.50, -1.50, -2.40),
                wall(1.50, 0.50, 1.50, -2.40),
                wall(-1.50, -2.40, -1.15, -2.40, height: 0.28),
                wall(-0.65, -2.40, 1.50, -2.40, height: 0.28),
                wall(-1.50, -3.00, -1.15, -3.00, height: 0.28),
                wall(-0.65, -3.00, 1.50, -3.00, height: 0.28),
                wall(-1.50, -3.00, -1.50, -5.10, height: 0.28),
                wall(1.50, -3.00, 1.50, -5.10, height: 0.28),
                wall(-1.50, -5.10, 1.50, -5.10, height: 0.28),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.9, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(0.80, -1.55), radius: 0.08),
                critter(.imp, at: SIMD2(0, -1.90),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.3),
                .ramp(center: SIMD2(-0.90, -2.70), width: 0.5, length: 0.6,
                      rise: 0.15, yaw: 0),
                .block(center: SIMD2(-0.90, -4.05), size: SIMD3(0.16, 0.14, 0.44),
                       yaw: 0, baseY: 0.15),
                critter(.magmaBlob, at: SIMD2(0, -4.75),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 0.9, baseY: 0.15),
            ],
            bonusStar: SIMD2(-1.25, -3.35), bonusStarY: 0.15,
            cameraZoom: 2.1
        ),
        // 11 — pyroclast. An open field with three vents blown out of it, each
        //      offset from the last, so the ball is never on the same side of
        //      the plot for two of them running.
        LevelDefinition(
            course: .volcano, number: 11, name: String(localized: "Pyroclast"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.60, -5.30),
            floors: [
                floorRect(-1.80, 1.80, -1.10, 0.50),
                floorRect(-1.80, -0.85, -2.00, -1.10),
                floorRect(-0.85, -0.05, -2.00, -1.10, kind: .lava),
                floorRect(-0.05, 1.80, -2.00, -1.10),
                floorRect(-1.80, 1.80, -2.60, -2.00),
                floorRect(-1.80, 0.35, -3.50, -2.60),
                floorRect(0.35, 1.15, -3.50, -2.60, kind: .lava),
                floorRect(1.15, 1.80, -3.50, -2.60),
                floorRect(-1.80, 1.80, -4.10, -3.50),
                floorRect(-1.80, -1.05, -5.00, -4.10),
                floorRect(-1.05, -0.25, -5.00, -4.10, kind: .lava),
                floorRect(-0.25, 1.80, -5.00, -4.10),
                floorRect(-1.80, 1.80, -5.60, -5.00),
            ],
            wallLoops: [rectLoop(-1.80, 1.80, -5.60, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 3.5, height: 0.028, yaw: 0),
                .bumper(center: SIMD2(1.30, -1.55), radius: 0.08),
                .bumper(center: SIMD2(-1.25, -3.05), radius: 0.08),
                critter(.imp, at: SIMD2(0, -2.30),
                        .patrol(axis: acrossLane, amplitude: 0.95), speed: 1.4),
                critter(.magmaBlob, at: SIMD2(0.70, -3.80),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 0.9),
                // On the felt beside the third vent, not in it: a post standing
                // in the middle of a vent has nothing under it and can only be
                // met by a ball already on its way down.
                .post(center: SIMD2(0.10, -4.55), radius: 0.05),
            ],
            bonusStar: SIMD2(-1.55, -3.05),
            cameraZoom: 2.15
        ),
        // 12 — the forge. The causeway, the floor of the caldera, the great
        //      moat with one plank over it and the cone at the far side of it:
        //      every idea on the course, in the order it was taught.
        LevelDefinition(
            course: .volcano, number: 12, name: String(localized: "Volcano Forge"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -7.05), holeY: 0.18,
            floors: [
                floorRect(-0.50, 0.50, -1.60, 0.50),
                floorRect(-1.40, -0.50, -1.60, -0.60, kind: .lava),
                floorRect(0.50, 1.40, -1.60, -0.60, kind: .lava),
                floorRect(-1.60, 1.60, -5.60, -1.60),
                floorRect(-1.50, 1.50, -3.30, -1.75, kind: .mud),
                floorRect(-0.30, 0.30, -6.00, -5.60),
                floorRect(-1.60, -0.30, -7.80, -5.60, kind: .lava),
                floorRect(0.30, 1.60, -7.80, -5.60, kind: .lava),
                floorRect(-0.30, 0.30, -7.80, -6.00, kind: .lava),
                floorRect(-0.70, 0.70, -7.50, -6.60, y: 0.18),
            ],
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -0.60),
                wall(0.50, 0.50, 0.50, -0.60),
                wall(-1.60, -1.60, -0.50, -1.60),
                wall(0.50, -1.60, 1.60, -1.60),
                wall(-1.60, -1.60, -1.60, -5.60),
                wall(1.60, -1.60, 1.60, -5.60),
                wall(-1.60, -5.60, -0.30, -5.60),
                wall(0.30, -5.60, 1.60, -5.60),
                wall(-0.70, -6.60, -0.25, -6.60, height: 0.36),
                wall(0.25, -6.60, 0.70, -6.60, height: 0.36),
                wall(-0.70, -6.60, -0.70, -7.50, height: 0.36),
                wall(0.70, -6.60, 0.70, -7.50, height: 0.36),
                wall(-0.70, -7.50, 0.70, -7.50, height: 0.36),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.35), width: 0.9, height: 0.028, yaw: 0),
                critter(.imp, at: SIMD2(0, -1.10),
                        .patrol(axis: acrossLane, amplitude: 0.16), speed: 1.2),
                .bumper(center: SIMD2(-0.85, -2.15), radius: 0.08),
                .bumper(center: SIMD2(0.85, -2.15), radius: 0.08),
                .gate(center: SIMD2(0, -2.90), size: SIMD2(0.80, 0.13), yaw: 0,
                      period: 3.2, phase: 0, baseY: 0),
                .ramp(center: SIMD2(0, -6.30), width: 0.5, length: 0.6,
                      rise: 0.18, yaw: 0),
                critter(.magmaBlob, at: SIMD2(0, -7.25),
                        .patrol(axis: acrossLane, amplitude: 0.20), speed: 0.8, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.35, -2.55),
            cameraZoom: 2.15
        ),
    ]
}
