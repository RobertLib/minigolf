//
//  GardenLevels.swift
//  Minigolf
//
//  Green Garden — the introductory world, and the one laid out closest to the
//  book. A standard miniature golf lane is 6.25 m of felt 0.90 m wide that ends
//  in a target circle 1.40 m across, and that silhouette — a tight corridor
//  opening into a round green — is what every hole here is built from.
//
//  The twelve are the classics in the order a beginner can take them: the plain
//  straight lane, bars off alternating boards, the right angle, the pyramids,
//  the mill, twin passages, the plateau, the S, the ditch, the waves, the
//  horseshoe, and a last hole with the lot on it.
//
//  Lanes are 0.90–1.00 m wide, greens 1.40 m, and every round green is turned
//  with three boards to the corner — the most an axis-aligned floor can be
//  rounded before the felt starts showing outside the kerb.
//

import Foundation
import simd

enum GardenCourse {

    /// Every target green on this course is turned the same way, so the corner
    /// the ball banks off reads the same on all twelve holes.
    private static let turn: Float = 0.42
    private static let turnSteps = 3

    static let holes: [LevelDefinition] = [
        // 1 — the plain straight lane (WMF 20). A 0.90 m corridor, one rise to
        //     carry and one hedgehog crossing it, opening into the full round
        //     green. Hit it straight and firm and it drops.
        LevelDefinition(
            course: .garden, number: 1, name: String(localized: "First Steps"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.42),
            floors: [floorRect(-0.45, 0.45, -1.60, 0.50)]
                + roundedFloor(-0.70, 0.70, -3.10, -1.60, far: turn, steps: turnSteps),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -1.60),
                wall(0.45, 0.50, 0.45, -1.60),
                // Shoulders: the mouth is narrower than the green behind it, so
                // a putt that arrives wide is turned back in rather than parked.
                wall(-0.70, -1.60, -0.45, -1.60),
                wall(0.45, -1.60, 0.70, -1.60),
            ] + roundedKerb(-0.70, 0.70, -3.10, -1.60,
                        far: turn, steps: turnSteps),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.028, yaw: 0),
                critter(.hedgehog, at: SIMD2(0, -1.15),
                        .patrol(axis: acrossLane, amplitude: 0.18), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.52, -2.00),
            cameraZoom: 1.1
        ),
        // 2 — bars (WMF 10). Three of them reach in from alternating boards and
        //     the ball has to be threaded between them, not over: the first
        //     hole that asks for a line rather than a direction.
        LevelDefinition(
            course: .garden, number: 2, name: String(localized: "The Bars"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.30),
            floors: [floorRect(-0.50, 0.50, -1.60, 0.50)]
                + roundedFloor(-0.72, 0.72, -2.95, -1.60, far: turn, steps: turnSteps),
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -1.60),
                wall(0.50, 0.50, 0.50, -1.60),
                wall(-0.72, -1.60, -0.50, -1.60),
                wall(0.50, -1.60, 0.72, -1.60),
            ] + roundedKerb(-0.72, 0.72, -2.95, -1.60,
                        far: turn, steps: turnSteps),
            obstacles: [
                .block(center: SIMD2(-0.16, -0.55), size: SIMD3(0.68, 0.14, 0.07),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.16, -0.98), size: SIMD3(0.68, 0.14, 0.07),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(-0.16, -1.40), size: SIMD3(0.68, 0.14, 0.07),
                       yaw: 0, baseY: 0),
                // The last bar throws everything right, so the mole works the
                // right-hand half of the green.
                critter(.mole, at: SIMD2(0.36, -2.00), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(-0.56, -1.90),
            cameraZoom: 1.2
        ),
        // 3 — the right angle (WMF 18). Straight down, hard left, and a bay off
        //     the far end of the cross leg with the cup in it. The dead corner
        //     is banked, so a putt driven into the curve comes out of it
        //     pointing down the second leg — the whole trick of minigolf.
        LevelDefinition(
            course: .garden, number: 3, name: String(localized: "The Right Angle"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.22, -3.12),
            floors: [
                floorRect(-0.45, 0.45, -1.70, 0.50),
                floorRect(-1.75, 0.45, -3.00, -1.70),
                floorRect(-1.75, -0.70, -3.45, -3.00),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -3.00),
                SIMD2(-0.70, -3.00), SIMD2(-0.70, -3.45), SIMD2(-1.75, -3.45),
                SIMD2(-1.75, -1.70), SIMD2(-0.45, -1.70),
            ]],
            extraWalls: arcWall(center: SIMD2(-0.10, -2.45), radius: 0.55,
                                from: deg(270), to: deg(360), segments: 4),
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.20, -1.45), radius: 0.04),
                critter(.hedgehog, at: SIMD2(-0.95, -2.35),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.0),
                critter(.mole, at: SIMD2(-1.55, -2.40), .burrow(period: 3.0)),
            ],
            bonusStar: SIMD2(-1.55, -1.95),
            cameraZoom: 1.4
        ),
        // 4 — the pyramids (WMF 1). Two of them stand in the lane corner-on and
        //     the only ways past are the two slots against the boards; the
        //     lazy line between them is where the sand is.
        LevelDefinition(
            course: .garden, number: 4, name: String(localized: "Pyramids"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.30),
            floors: [
                floorRect(-0.50, 0.50, -2.40, 0.50),
                floorRect(-0.26, 0.26, -1.85, -1.20, kind: .sand),
            ] + roundedFloor(-0.72, 0.72, -3.95, -2.40, far: turn, steps: turnSteps),
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -2.40),
                wall(0.50, 0.50, 0.50, -2.40),
                wall(-0.72, -2.40, -0.50, -2.40),
                wall(0.50, -2.40, 0.72, -2.40),
            ] + roundedKerb(-0.72, 0.72, -3.95, -2.40,
                        far: turn, steps: turnSteps),
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 1.0, height: 0.03, yaw: 0),
                // Corner-on, so each one deflects rather than stops: 0.24 m of
                // clear felt against the board either side.
                .block(center: SIMD2(-0.09, -1.10), size: SIMD3(0.36, 0.16, 0.36),
                       yaw: deg(45), baseY: 0),
                .block(center: SIMD2(0.09, -1.95), size: SIMD3(0.36, 0.16, 0.36),
                       yaw: deg(45), baseY: 0),
                critter(.mole, at: SIMD2(-0.34, -1.95), .burrow(period: 2.8), phase: 0.4),
                critter(.hedgehog, at: SIMD2(0, -3.00),
                        .patrol(axis: acrossLane, amplitude: 0.32), speed: 1.0),
            ],
            bonusStar: SIMD2(0.56, -2.85),
            cameraZoom: 1.3
        ),
        // 5 — the mill. The lane is wider than the mill house, so the gaps
        //     either side are filled in: under the blades is the only way
        //     through, and beyond it the felt opens into a square target field
        //     with the cup tight against the back board.
        LevelDefinition(
            course: .garden, number: 5, name: String(localized: "The Windmill"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.55),
            floors: [
                floorRect(-0.45, 0.45, -2.40, 0.50),
                floorRect(-1.05, 1.05, -4.00, -2.40),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -2.40),
                SIMD2(1.05, -2.40), SIMD2(1.05, -4.00), SIMD2(-1.05, -4.00),
                SIMD2(-1.05, -2.40), SIMD2(-0.45, -2.40),
            ]],
            // Shoulders inside the target field: a putt that squirts out of the
            // gate wide is turned back down the middle instead of hugging a
            // corner where no line to the cup exists.
            extraWalls: arcWall(center: SIMD2(-0.60, -2.95), radius: 0.55,
                                from: deg(90), to: deg(180), segments: 4)
                + arcWall(center: SIMD2(0.60, -2.95), radius: 0.55,
                          from: deg(0), to: deg(90), segments: 4),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 0.9, height: 0.03, yaw: 0),
                .windmill(center: SIMD2(0, -1.70), yaw: 0, speed: 1.7),
                .block(center: SIMD2(-0.355, -1.70), size: SIMD3(0.19, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.355, -1.70), size: SIMD3(0.19, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                critter(.mole, at: SIMD2(0, -3.10), .burrow(period: 2.8), phase: 0.6),
                critter(.hedgehog, at: SIMD2(-0.60, -3.65),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.1),
            ],
            bonusStar: SIMD2(0.82, -3.70),
            cameraZoom: 1.4
        ),
        // 6 — passages (WMF 14). The lane forks into two corridors, each with
        //     its own rise to carry, and they run back together in a shared
        //     green. Left is short and blind, right is longer and open.
        LevelDefinition(
            course: .garden, number: 6, name: String(localized: "Two Passages"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-0.85, 0.85, -1.15, 0.50),
                floorRect(-0.85, -0.15, -2.70, -1.15),
                floorRect(0.15, 0.85, -2.70, -1.15),
            ] + roundedFloor(-0.85, 0.85, -4.35, -2.70, far: turn, steps: turnSteps),
            extraWalls: [
                wall(-0.85, 0.50, 0.85, 0.50),
                wall(-0.85, 0.50, -0.85, -2.70),
                wall(0.85, 0.50, 0.85, -2.70),
                // The spine between the passages, capped at both ends so the
                // fork reads as two corridors rather than one wide lane.
                wall(-0.15, -1.15, -0.15, -2.70),
                wall(0.15, -1.15, 0.15, -2.70),
                wall(-0.15, -1.15, 0.15, -1.15),
                wall(-0.15, -2.70, 0.15, -2.70),
            ] + roundedKerb(-0.85, 0.85, -4.35, -2.70,
                        far: turn, steps: turnSteps),
            obstacles: [
                .bump(center: SIMD2(-0.50, -1.95), width: 0.7, height: 0.045, yaw: 0),
                .bump(center: SIMD2(0.50, -2.05), width: 0.7, height: 0.032, yaw: 0),
                .post(center: SIMD2(-0.50, -1.45), radius: 0.045),
                critter(.mole, at: SIMD2(0.50, -1.55), .burrow(period: 2.6)),
                critter(.hedgehog, at: SIMD2(0, -3.45),
                        .patrol(axis: acrossLane, amplitude: 0.38), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.62, -2.35),
            cameraZoom: 1.45
        ),
        // 7 — the plateau (WMF 22). The green stands a hand higher than the
        //     lane and the ramp up to it is narrower than either, so the climb
        //     has to be aimed as well as driven.
        LevelDefinition(
            course: .garden, number: 7, name: String(localized: "The Plateau"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75), holeY: 0.13,
            floors: [
                floorRect(-0.55, 0.55, -2.20, 0.50),
            ] + roundedFloor(-0.80, 0.80, -4.60, -2.80, far: turn, steps: turnSteps, y: 0.13),
            extraWalls: [
                wall(-0.55, 0.50, 0.55, 0.50),
                wall(-0.55, 0.50, -0.55, -2.20),
                wall(0.55, 0.50, 0.55, -2.20),
                // Retaining boards: they stand on the lower floor and are tall
                // enough to guard the plateau as well, so one kerb serves both.
                // They also close the lane off either side of the ramp mouth,
                // which is the only way up.
                wall(-0.80, -2.20, -0.30, -2.20, height: 0.26),
                wall(0.30, -2.20, 0.80, -2.20, height: 0.26),
                wall(-0.80, -2.20, -0.80, -2.80, height: 0.26),
                wall(0.80, -2.20, 0.80, -2.80, height: 0.26),
                wall(-0.80, -2.80, -0.30, -2.80, height: 0.26),
                wall(0.30, -2.80, 0.80, -2.80, height: 0.26),
            ] + roundedKerb(-0.80, 0.80, -4.60, -2.80,
                        far: turn, steps: turnSteps,
                        baseY: 0, height: 0.26),
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 1.1, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.26, -1.50), radius: 0.04),
                .ramp(center: SIMD2(0, -2.50), width: 0.6, length: 0.6, rise: 0.13, yaw: 0),
                .block(center: SIMD2(-0.58, -3.55), size: SIMD3(0.30, 0.14, 0.44),
                       yaw: 0, baseY: 0.13),
                critter(.mole, at: SIMD2(0.42, -3.35), .burrow(period: 2.6), baseY: 0.13),
                critter(.hedgehog, at: SIMD2(0, -4.25),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.0, baseY: 0.13),
            ],
            bonusStar: SIMD2(0.60, -4.00), bonusStarY: 0.13,
            cameraZoom: 1.4
        ),
        // 8 — the S. Three legs and two turns the other way from each other,
        //     both banked, so the hole can be played round in one long swinging
        //     putt or walked leg by leg.
        LevelDefinition(
            course: .garden, number: 8, name: String(localized: "Garden Path"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.25, -3.25),
            floors: [
                floorRect(-0.45, 0.45, -1.15, 0.50),
                floorRect(-1.70, 0.45, -2.05, -1.15),
                floorRect(-1.70, -0.80, -3.70, -2.05),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -2.05),
                SIMD2(-0.80, -2.05), SIMD2(-0.80, -3.70), SIMD2(-1.70, -3.70),
                SIMD2(-1.70, -1.15), SIMD2(-0.45, -1.15),
            ]],
            extraWalls: arcWall(center: SIMD2(-0.10, -1.50), radius: 0.55,
                                from: deg(270), to: deg(360), segments: 4)
                + arcWall(center: SIMD2(-1.20, -1.65), radius: 0.50,
                          from: deg(90), to: deg(180), segments: 4),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.62, -1.60), radius: 0.04),
                critter(.hedgehog, at: SIMD2(-1.25, -2.45),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 0.9),
                .post(center: SIMD2(-1.00, -2.95), radius: 0.04),
                critter(.mole, at: SIMD2(-1.45, -3.15), .burrow(period: 3.0)),
            ],
            bonusStar: SIMD2(-1.52, -3.55),
            cameraZoom: 1.5
        ),
        // 9 — the ditch (Filzgolf 21). Water right across the lane with one
        //     plank over it, and a gate on the far bank so the carry has to be
        //     timed as well as aimed. Left of the plank is a longer dry way
        //     round for anyone who would rather spend a stroke than a ball.
        LevelDefinition(
            course: .garden, number: 9, name: String(localized: "The Ditch"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.30, -3.85),
            floors: [
                floorRect(-1.25, 0.85, -1.35, 0.50),
                floorRect(-1.25, -0.85, -2.20, -1.35),
                floorRect(-0.85, -0.14, -2.20, -1.35, kind: .water),
                floorRect(-0.14, 0.14, -2.20, -1.35),
                floorRect(0.14, 0.85, -2.20, -1.35, kind: .water),
                floorRect(-1.25, 0.85, -2.60, -2.20),
            ] + roundedFloor(-1.05, 1.05, -4.40, -2.60, far: turn, steps: turnSteps),
            extraWalls: [
                wall(-1.25, 0.50, 0.85, 0.50),
                wall(-1.25, 0.50, -1.25, -2.60),
                wall(0.85, 0.50, 0.85, -2.60),
                wall(-1.25, -2.60, -1.05, -2.60),
                wall(0.85, -2.60, 1.05, -2.60),
            ] + roundedKerb(-1.05, 1.05, -4.40, -2.60,
                        far: turn, steps: turnSteps),
            obstacles: [
                .bump(center: SIMD2(-0.20, -0.80), width: 2.0, height: 0.03, yaw: 0),
                // The gate on the far bank, straight ahead of the plank.
                .gate(center: SIMD2(0, -2.42), size: SIMD2(0.52, 0.13), yaw: 0,
                      period: 3.4, phase: 0, baseY: 0),
                .post(center: SIMD2(-1.05, -2.42), radius: 0.045),
                critter(.hedgehog, at: SIMD2(-0.45, -3.30),
                        .patrol(axis: acrossLane, amplitude: 0.32), speed: 1.2),
                critter(.mole, at: SIMD2(0.60, -3.30), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(-1.05, -1.05),
            cameraZoom: 1.6
        ),
        // 10 — the waves and the target hill (WMF 4 and 28). Two swells across
        //      a wide lane, then a mound in the green with the cup behind it:
        //      too soft and the wave holds the ball, too firm and the mound
        //      throws it past.
        LevelDefinition(
            course: .garden, number: 10, name: String(localized: "Double Waves"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.90),
            floors: [
                floorRect(-0.70, 0.70, -2.35, 0.50),
            ] + roundedFloor(-1.15, 1.15, -4.55, -2.35, far: 0.42, near: 0, steps: turnSteps),
            extraWalls: [
                wall(-0.70, 0.50, 0.70, 0.50),
                wall(-0.70, 0.50, -0.70, -2.35),
                wall(0.70, 0.50, 0.70, -2.35),
                wall(-1.15, -2.35, -0.70, -2.35),
                wall(0.70, -2.35, 1.15, -2.35),
            ] + roundedKerb(-1.15, 1.15, -4.55, -2.35,
                        far: 0.42, steps: turnSteps),
            obstacles: [
                .bump(center: SIMD2(0, -0.95), width: 1.4, height: 0.05, yaw: 0),
                .bump(center: SIMD2(0, -1.75), width: 1.4, height: 0.05, yaw: 0),
                // The target hill: the cup sits in its lee, so the ball has to
                // be rolled round the shoulder rather than driven at the flag.
                .bump(center: SIMD2(0, -3.35), width: 0.8, height: 0.06, yaw: 0),
                .post(center: SIMD2(-0.55, -3.05), radius: 0.045),
                .post(center: SIMD2(0.55, -3.05), radius: 0.045),
                critter(.hedgehog, at: SIMD2(-0.72, -4.05),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.0),
                critter(.mole, at: SIMD2(0.72, -4.05), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(0.95, -2.85),
            cameraZoom: 1.5
        ),
        // 11 — the horseshoe (Filzgolf 28). Out along one arm, round the head
        //      of the shoe and back down the other, with the cup finishing a
        //      metre from the tee. The head is banked, so a firm putt carries
        //      itself round; a soft one has to be walked.
        LevelDefinition(
            course: .garden, number: 11, name: String(localized: "The Horseshoe"), par: 4,
            tee: SIMD2(-0.80, 0), hole: SIMD2(0.80, -0.50),
            floors: [
                floorRect(-1.15, -0.45, -2.35, 0.50),
                floorRect(-1.15, 1.15, -3.10, -2.35),
                floorRect(0.45, 1.15, -3.10, 0.50),
            ],
            wallLoops: [
                [
                    SIMD2(-1.15, 0.50), SIMD2(1.15, 0.50), SIMD2(1.15, -3.10),
                    SIMD2(-1.15, -3.10),
                ],
                // The island the shoe wraps round.
                rectLoop(-0.45, 0.45, -2.35, 0.50),
            ],
            extraWalls: arcWall(center: SIMD2(-0.70, -2.65), radius: 0.45,
                                from: deg(180), to: deg(270), segments: 4)
                + arcWall(center: SIMD2(0.70, -2.65), radius: 0.45,
                          from: deg(270), to: deg(360), segments: 4),
            obstacles: [
                .bump(center: SIMD2(-0.80, -0.80), width: 0.7, height: 0.03, yaw: 0),
                critter(.mole, at: SIMD2(-0.80, -1.75), .burrow(period: 2.8)),
                critter(.hedgehog, at: SIMD2(0, -2.72),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.2),
                .post(center: SIMD2(0.98, -1.90), radius: 0.045),
                .block(center: SIMD2(0.80, -1.25), size: SIMD3(0.34, 0.14, 0.14),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-0.80, -2.72),
            cameraZoom: 1.5
        ),
        // 12 — the long lane, with everything the garden has on it in the order
        //      it was taught: the mill gate, the ditch, and a last climb to a
        //      raised round green with its own gallery of locals on it.
        LevelDefinition(
            course: .garden, number: 12, name: String(localized: "Grand Garden"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.95), holeY: 0.14,
            floors: [
                floorRect(-0.50, 0.50, -2.55, 0.50),
                floorRect(-0.50, -0.10, -0.95, -0.50, kind: .sand),
                floorRect(-1.15, 1.15, -3.50, -2.55),
                floorRect(-1.15, -0.18, -4.15, -3.50, kind: .water),
                floorRect(-0.18, 0.18, -4.15, -3.50),
                floorRect(0.18, 1.15, -4.15, -3.50, kind: .water),
                floorRect(-1.15, 1.15, -4.70, -4.15),
            ] + roundedFloor(-0.95, 0.95, -6.60, -5.30, far: turn, steps: turnSteps, y: 0.14),
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -2.55),
                wall(0.50, 0.50, 0.50, -2.55),
                wall(-1.15, -2.55, -0.50, -2.55),
                wall(0.50, -2.55, 1.15, -2.55),
                wall(-1.15, -2.55, -1.15, -4.70),
                wall(1.15, -2.55, 1.15, -4.70),
                // Retaining boards round the raised green. They stand on the
                // lower floor, so one kerb guards the bank and the green both,
                // and they close the far bank off either side of the ramp.
                wall(-1.15, -4.70, -0.30, -4.70, height: 0.28),
                wall(0.30, -4.70, 1.15, -4.70, height: 0.28),
                wall(-0.95, -5.30, -0.30, -5.30, height: 0.28),
                wall(0.30, -5.30, 0.95, -5.30, height: 0.28),
            ] + roundedKerb(-0.95, 0.95, -6.60, -5.30,
                        far: turn, steps: turnSteps,
                        baseY: 0, height: 0.28)
                + arcWall(center: SIMD2(-0.70, -3.10), radius: 0.55,
                          from: deg(90), to: deg(180), segments: 4)
                + arcWall(center: SIMD2(0.70, -3.10), radius: 0.55,
                          from: deg(0), to: deg(90), segments: 4),
            obstacles: [
                .windmill(center: SIMD2(0, -2.05), yaw: 0, speed: 1.9),
                .block(center: SIMD2(-0.405, -2.05), size: SIMD3(0.19, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.405, -2.05), size: SIMD3(0.19, 0.16, 0.16),
                       yaw: 0, baseY: 0),
                .bumper(center: SIMD2(-0.60, -3.22), radius: 0.06),
                critter(.hedgehog, at: SIMD2(0.55, -3.22),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.1),
                critter(.mole, at: SIMD2(-0.70, -4.30), .burrow(period: 2.8)),
                .ramp(center: SIMD2(0, -5.00), width: 0.6, length: 0.6, rise: 0.14, yaw: 0),
                .block(center: SIMD2(0.66, -5.85), size: SIMD3(0.34, 0.14, 0.44),
                       yaw: 0, baseY: 0.14),
                critter(.hedgehog, at: SIMD2(-0.48, -5.95),
                        .patrol(axis: acrossLane, amplitude: 0.24), speed: 0.9, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.00, -4.30),
            cameraZoom: 1.8
        ),
    ]
}
