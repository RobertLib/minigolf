//
//  IceLevels.swift
//  Minigolf
//
//  Frozen Fjord — water is the shape of this world. Where the desert pinches
//  its holes with boards and the jungle walls them into rooms, the fjord cuts
//  them out of open water: channels between two arms of it, causeways across
//  it, a crack running the length of a hole with two planks over it, and the
//  lightning lane — the zig-zag every course in the book has one of — stepped
//  across the floes.
//
//  Ice sheets are laid where a hole most needs the ball not to stop, so the
//  same channel plays quite differently on the way down it and on the way back.
//

import Foundation
import simd

enum IceCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a channel with water either side of it and a pan at the end. The
        //     boards run out where the water starts, so for most of the hole
        //     there is nothing to bank off at all.
        LevelDefinition(
            course: .ice, number: 1, name: String(localized: "First Frost"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.75),
            floors: [
                floorRect(-0.55, 0.55, -0.60, 0.50),
                floorRect(-0.55, 0.55, -3.30, -0.60),
                floorRect(-0.55, 0.55, -2.60, -1.60, kind: .ice),
                floorRect(-1.35, -0.55, -3.30, -0.60, kind: .water),
                floorRect(0.55, 1.35, -3.30, -0.60, kind: .water),
                floorRect(-1.35, 1.35, -4.20, -3.30),
            ],
            wallLoops: [[
                SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -0.60),
                SIMD2(1.35, -0.60), SIMD2(1.35, -4.20), SIMD2(-1.35, -4.20),
                SIMD2(-1.35, -0.60), SIMD2(-0.55, -0.60),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.35), width: 1.0, height: 0.028, yaw: 0),
                critter(.snowman, at: SIMD2(0, -1.15),
                        .patrol(axis: acrossLane, amplitude: 0.18), speed: 0.8),
                critter(.penguin, at: SIMD2(0, -3.90),
                        .patrol(axis: acrossLane, amplitude: 0.75), speed: 1.3),
            ],
            bonusStar: SIMD2(1.12, -3.75),
            cameraZoom: 1.55
        ),
        // 2 — black ice. A plain lane, except that the middle third of it has
        //     no grip at all, so the putt has to be weighted for a surface the
        //     ball is not on yet.
        LevelDefinition(
            course: .ice, number: 2, name: String(localized: "Black Ice"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.40),
            floors: [
                floorRect(-0.45, 0.45, -2.60, 0.50),
                floorRect(-0.45, 0.45, -2.20, -1.00, kind: .ice),
                floorRect(-1.15, 1.15, -3.90, -2.60),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -2.60),
                SIMD2(1.15, -2.60), SIMD2(1.15, -3.90), SIMD2(-1.15, -3.90),
                SIMD2(-1.15, -2.60), SIMD2(-0.45, -2.60),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.22, -1.55), radius: 0.04),
                .post(center: SIMD2(0.24, -2.15), radius: 0.04),
                critter(.penguin, at: SIMD2(-0.60, -3.10),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
                critter(.snowman, at: SIMD2(0.70, -3.55),
                        .patrol(axis: alongLane, amplitude: 0.22), speed: 0.7),
            ],
            bonusStar: SIMD2(-0.95, -3.55),
            cameraZoom: 1.55
        ),
        // 3 — the jump (WMF 7). Open water right across the fjord, a kicker on
        //     the near bank that throws the ball the same distance every time,
        //     and a ledge along the left for anyone who would rather walk round
        //     and spend the stroke.
        LevelDefinition(
            course: .ice, number: 3, name: String(localized: "The Crossing"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.70, -3.85),
            floors: [
                floorRect(-1.10, 1.10, -1.60, 0.50),
                floorRect(-0.75, 1.10, -2.70, -1.60, kind: .water),
                floorRect(-1.10, -0.75, -2.70, -1.60),
                floorRect(-1.10, 1.10, -4.30, -2.70),
                floorRect(-0.40, 1.10, -3.90, -2.95, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.10, 1.10, -4.30, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 2.1, height: 0.028, yaw: 0),
                .launchPad(center: SIMD2(0, -1.42), direction: SIMD2(0, -1),
                           speed: 2.6, lift: 3.0, y: 0),
                critter(.penguin, at: SIMD2(-0.92, -3.30),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.1),
                critter(.snowman, at: SIMD2(0.70, -4.10),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 0.8),
            ],
            bonusStar: SIMD2(-0.92, -2.15),
            cameraZoom: 1.75
        ),
        // 4 — the lightning lane (WMF 19). Five short legs, each stepping off
        //      the end of the last, and the two widest of them iced so the ball
        //      arrives at the turn faster than it left the one before.
        LevelDefinition(
            course: .ice, number: 4, name: String(localized: "The Lightning"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.75, -3.95),
            floors: [
                floorRect(-0.45, 0.45, -1.00, 0.50),
                floorRect(-0.45, 1.20, -1.80, -1.00),
                floorRect(-0.30, 1.20, -1.72, -1.08, kind: .ice),
                floorRect(0.30, 1.20, -2.60, -1.80),
                floorRect(-1.20, 1.20, -3.40, -2.60),
                floorRect(-1.10, 1.10, -3.32, -2.68, kind: .ice),
                floorRect(-1.20, -0.30, -4.30, -3.40),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -1.00),
                SIMD2(1.20, -1.00), SIMD2(1.20, -3.40), SIMD2(-0.30, -3.40),
                SIMD2(-0.30, -4.30), SIMD2(-1.20, -4.30), SIMD2(-1.20, -2.60),
                SIMD2(0.30, -2.60), SIMD2(0.30, -1.80), SIMD2(-0.45, -1.80),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.75, -1.40), radius: 0.045),
                critter(.penguin, at: SIMD2(0.75, -2.20),
                        .patrol(axis: acrossLane, amplitude: 0.26), speed: 1.2),
                .post(center: SIMD2(-0.60, -3.00), radius: 0.045),
                critter(.snowman, at: SIMD2(-0.75, -3.75),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 0.7),
            ],
            bonusStar: SIMD2(1.10, -2.50),
            cameraZoom: 1.85
        ),
        // 5 — the bowl. A chute a third the width of what it feeds, and what it
        //     feeds is a round basin ringed with ice: a putt driven in hard
        //     goes round the wall twice before it settles.
        LevelDefinition(
            course: .ice, number: 5, name: String(localized: "Snow Bowl"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -4.30),
            floors: [
                floorRect(-0.40, 0.40, -2.60, 0.50),
            ] + roundedFloor(-1.30, 1.30, -5.00, -2.60, far: 0.42, near: 0.42, steps: 3)
              // The sheet stays inside the basin's widest course: an overlay is
              // a skin on one patch of felt, not a wash over several.
              + [floorRect(-1.15, 1.15, -4.45, -3.15, kind: .ice)],
            extraWalls: [
                wall(-0.40, 0.50, 0.40, 0.50),
                wall(-0.40, 0.50, -0.40, -2.60),
                wall(0.40, 0.50, 0.40, -2.60),
                wall(-0.88, -2.60, -0.40, -2.60),
                wall(0.40, -2.60, 0.88, -2.60),
            ] + roundedKerb(-1.30, 1.30, -5.00, -2.60,
                        far: 0.42, near: 0.42, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.18, -1.70), radius: 0.04),
                .bumper(center: SIMD2(0, -3.55), radius: 0.09),
                critter(.penguin, at: SIMD2(-0.85, -4.30),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.2),
                critter(.snowman, at: SIMD2(0, -4.70),
                        .patrol(axis: acrossLane, amplitude: 0.40), speed: 0.8),
            ],
            bonusStar: SIMD2(-0.95, -3.20),
            cameraZoom: 1.85
        ),
        // 6 — the ditch (Filzgolf 21). One plank over the water and a gate on
        //     the far bank lined up with it, so the carry has to be timed; the
        //     bank beyond is iced and slopes away from the cup.
        LevelDefinition(
            course: .ice, number: 6, name: String(localized: "The Trench"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.85, -3.90),
            floors: [
                floorRect(-1.10, 1.10, -1.80, 0.50),
                floorRect(-1.10, -0.20, -2.35, -1.80, kind: .water),
                floorRect(-0.20, 0.20, -2.35, -1.80),
                floorRect(0.20, 1.10, -2.35, -1.80, kind: .water),
                floorRect(-1.10, 1.10, -2.95, -2.35),
                floorRect(-1.35, 1.35, -4.30, -2.95),
                floorRect(-1.25, 1.25, -4.20, -3.05, kind: .ice),
            ],
            wallLoops: [[
                SIMD2(-1.10, 0.50), SIMD2(1.10, 0.50), SIMD2(1.10, -2.95),
                SIMD2(1.35, -2.95), SIMD2(1.35, -4.30), SIMD2(-1.35, -4.30),
                SIMD2(-1.35, -2.95), SIMD2(-1.10, -2.95),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 2.1, height: 0.03, yaw: 0),
                .gate(center: SIMD2(0, -2.62), size: SIMD2(0.52, 0.13), yaw: 0,
                      period: 3.2, phase: 0, baseY: 0),
                .post(center: SIMD2(-0.80, -2.62), radius: 0.045),
                .post(center: SIMD2(0.80, -2.62), radius: 0.045),
                critter(.penguin, at: SIMD2(0.55, -3.60),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
                critter(.snowman, at: SIMD2(-0.85, -4.10),
                        .patrol(axis: acrossLane, amplitude: 0.24), speed: 0.7),
            ],
            bonusStar: SIMD2(1.15, -3.35),
            cameraZoom: 1.75
        ),
        // 7 — the falls. A court, a ramp up the ice cliff, and a terrace on top
        //     that is one sheet of ice from edge to edge.
        LevelDefinition(
            course: .ice, number: 7, name: String(localized: "Frozen Falls"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.70, -4.90), holeY: 0.14,
            floors: [
                floorRect(-1.20, 1.20, -3.30, 0.50),
                floorRect(-1.20, 1.20, -5.50, -3.90, y: 0.14),
                floorRect(-1.10, 1.10, -5.40, -4.00, kind: .ice, y: 0.14),
            ],
            extraWalls: [
                wall(-1.20, 0.50, 1.20, 0.50),
                wall(-1.20, 0.50, -1.20, -3.30),
                wall(1.20, 0.50, 1.20, -3.30),
                wall(-1.20, -3.30, -0.25, -3.30, height: 0.26),
                wall(0.25, -3.30, 1.20, -3.30, height: 0.26),
                wall(-1.20, -3.90, -0.25, -3.90, height: 0.26),
                wall(0.25, -3.90, 1.20, -3.90, height: 0.26),
                wall(-1.20, -3.90, -1.20, -5.50, height: 0.26),
                wall(1.20, -3.90, 1.20, -5.50, height: 0.26),
                wall(-1.20, -5.50, 1.20, -5.50, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.3, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.55, -1.40), radius: 0.05),
                .ramp(center: SIMD2(0, -3.60), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .block(center: SIMD2(-0.35, -4.60), size: SIMD3(0.16, 0.14, 0.50),
                       yaw: 0, baseY: 0.14),
                critter(.penguin, at: SIMD2(0.70, -4.25),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.3, baseY: 0.14),
                critter(.snowman, at: SIMD2(-0.80, -5.25),
                        .patrol(axis: acrossLane, amplitude: 0.26), speed: 0.7, baseY: 0.14),
            ],
            bonusStar: SIMD2(-0.95, -4.60), bonusStarY: 0.14,
            cameraZoom: 1.8
        ),
        // 8 — the crevasse. A crack down the whole length of the hole with two
        //     planks over it, one early and narrow, one late and wide: cross
        //     early and the second half is long, cross late and the first is.
        LevelDefinition(
            course: .ice, number: 8, name: String(localized: "Crevasse"), par: 4,
            tee: SIMD2(-0.85, 0), hole: SIMD2(0.85, -3.80),
            floors: [
                floorRect(-1.45, -0.30, -4.20, 0.50),
                floorRect(0.30, 1.45, -4.20, 0.50),
                floorRect(-0.30, 0.30, -1.40, 0.50, kind: .water),
                floorRect(-0.30, 0.30, -1.75, -1.40),
                floorRect(-0.30, 0.30, -3.10, -1.75, kind: .water),
                floorRect(-0.30, 0.30, -3.45, -3.10),
                floorRect(-0.30, 0.30, -4.20, -3.45, kind: .water),
                floorRect(0.30, 1.45, -3.05, -2.05, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.45, 1.45, -4.20, 0.50)],
            obstacles: [
                .bump(center: SIMD2(-0.85, -0.60), width: 1.05, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.85, -2.40), radius: 0.05),
                critter(.penguin, at: SIMD2(-0.85, -3.40),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.2),
                .post(center: SIMD2(0.85, -1.30), radius: 0.05),
                critter(.snowman, at: SIMD2(1.00, -4.00),
                        .patrol(axis: acrossLane, amplitude: 0.24), speed: 0.7),
            ],
            bonusStar: SIMD2(1.22, -0.85),
            cameraZoom: 1.85
        ),
        // 9 — the fork. The narrow arm is iced and a metre shorter; the wide
        //     one is plain felt and goes the long way round the floe.
        LevelDefinition(
            course: .ice, number: 9, name: String(localized: "Two Arms"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.60),
            floors: [
                floorRect(-1.30, 1.30, -1.30, 0.50),
                floorRect(-1.30, -0.75, -3.10, -1.30),
                floorRect(-1.30, -0.75, -3.00, -1.40, kind: .ice),
                floorRect(0.20, 1.30, -3.10, -1.30),
                floorRect(-1.30, 1.30, -4.00, -3.10),
            ],
            wallLoops: [
                rectLoop(-1.30, 1.30, -4.00, 0.50),
                rectLoop(-0.75, 0.20, -3.10, -1.30),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 2.5, height: 0.028, yaw: 0),
                .post(center: SIMD2(0.75, -1.85), radius: 0.05),
                .post(center: SIMD2(0.75, -2.60), radius: 0.05),
                critter(.penguin, at: SIMD2(0, -3.75),
                        .patrol(axis: acrossLane, amplitude: 0.85), speed: 1.4),
                critter(.snowman, at: SIMD2(-1.02, -2.20),
                        .patrol(axis: acrossLane, amplitude: 0.16), speed: 0.7),
            ],
            bonusStar: SIMD2(1.10, -3.75),
            cameraZoom: 1.75
        ),
        // 10 — the peaks. One high floor in the shape of an L, up either of two
        //      ramps: the left one lands on the arm the cup is on, the right on
        //      the arm the star is on, and there is no crossing between them
        //      except back down and round.
        LevelDefinition(
            course: .ice, number: 10, name: String(localized: "Twin Peaks"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.90, -4.00), holeY: 0.14,
            floors: [
                floorRect(-1.60, 1.60, -2.20, 0.50),
                floorRect(-1.60, -0.20, -4.40, -2.80, y: 0.14),
                floorRect(-0.20, 1.60, -3.60, -2.80, y: 0.14),
                floorRect(-0.10, 1.50, -3.50, -2.90, kind: .ice, y: 0.14),
            ],
            extraWalls: [
                wall(-1.60, 0.50, 1.60, 0.50),
                wall(-1.60, 0.50, -1.60, -2.20),
                wall(1.60, 0.50, 1.60, -2.20),
                wall(-1.60, -2.20, -1.15, -2.20, height: 0.26),
                wall(-0.65, -2.20, 0.65, -2.20, height: 0.26),
                wall(1.15, -2.20, 1.60, -2.20, height: 0.26),
                wall(-1.60, -2.80, -1.15, -2.80, height: 0.26),
                wall(-0.65, -2.80, 0.65, -2.80, height: 0.26),
                wall(1.15, -2.80, 1.60, -2.80, height: 0.26),
                wall(-1.60, -2.80, -1.60, -4.40, height: 0.26),
                wall(-1.60, -4.40, -0.20, -4.40, height: 0.26),
                wall(-0.20, -4.40, -0.20, -3.60, height: 0.26),
                wall(-0.20, -3.60, 1.60, -3.60, height: 0.26),
                wall(1.60, -2.80, 1.60, -3.60, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 3.1, height: 0.03, yaw: 0),
                .ramp(center: SIMD2(-0.90, -2.50), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .ramp(center: SIMD2(0.90, -2.50), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .post(center: SIMD2(0, -1.55), radius: 0.05),
                critter(.snowman, at: SIMD2(-0.90, -3.35),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 0.7, baseY: 0.14),
                critter(.penguin, at: SIMD2(0.70, -3.20),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.3, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.30, -3.25), bonusStarY: 0.14,
            cameraZoom: 1.95
        ),
        // 11 — the avalanche. The top field is banked hard to the left, then
        //      the plot pinches to a channel and opens again: whatever the
        //      slope did to the ball has to be undone before the pinch.
        LevelDefinition(
            course: .ice, number: 11, name: String(localized: "Avalanche"), par: 5,
            tee: SIMD2(0.60, 0), hole: SIMD2(0, -5.15),
            floors: [
                floorRect(-1.70, 1.70, -3.20, 0.50),
                floorRect(-1.10, 1.10, -4.60, -3.20),
                floorRect(-1.70, 1.70, -5.70, -4.60),
                floorRect(-1.00, 1.00, -4.50, -3.30, kind: .ice),
            ],
            wallLoops: [
                [
                    SIMD2(-1.70, 0.50), SIMD2(1.70, 0.50), SIMD2(1.70, -3.20),
                    SIMD2(1.10, -3.20), SIMD2(1.10, -4.60), SIMD2(1.70, -4.60),
                    SIMD2(1.70, -5.70), SIMD2(-1.70, -5.70), SIMD2(-1.70, -4.60),
                    SIMD2(-1.10, -4.60), SIMD2(-1.10, -3.20), SIMD2(-1.70, -3.20),
                ],
                rectLoop(-1.05, -0.45, -2.60, -1.60),
                rectLoop(0.45, 1.05, -2.60, -1.60),
            ],
            obstacles: [
                .bump(center: SIMD2(0.60, -0.70), width: 1.6, height: 0.03, yaw: 0),
                .slope(rect: zone(-1.65, 1.65, -3.15, -1.10), direction: SIMD2(-1, 0),
                       strength: 1.2, y: 0),
                critter(.penguin, at: SIMD2(0, -2.10),
                        .patrol(axis: alongLane, amplitude: 0.34), speed: 1.3),
                .post(center: SIMD2(0, -3.85), radius: 0.05),
                critter(.snowman, at: SIMD2(-1.20, -5.20),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 0.8),
            ],
            bonusStar: SIMD2(1.45, -5.35),
            cameraZoom: 2.05
        ),
        // 12 — the fjord itself: a channel in from the sea, a hard turn at the
        //      head of it, a reach with open water down one side and a round
        //      basin at the very end with the cup in the middle of it.
        LevelDefinition(
            course: .ice, number: 12, name: String(localized: "Frozen Fjord"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.25, -5.30),
            floors: [
                floorRect(-0.50, 0.50, -1.60, 0.50),
                floorRect(-1.70, 0.50, -2.50, -1.60),
                floorRect(-1.60, 0.40, -2.42, -1.68, kind: .ice),
                floorRect(-1.70, -0.80, -4.55, -2.50),
                floorRect(-0.80, 0.50, -4.55, -2.50, kind: .water),
            ] + roundedFloor(-1.95, -0.55, -5.95, -4.55, far: 0.42, steps: 3),
            extraWalls: [
                wall(-0.50, 0.50, 0.50, 0.50),
                wall(-0.50, 0.50, -0.50, -1.60),
                wall(0.50, 0.50, 0.50, -1.60),
                wall(-1.70, -1.60, -0.50, -1.60),
                wall(-1.70, -1.60, -1.70, -4.55),
                wall(0.50, -1.60, 0.50, -4.55),
                wall(-1.95, -4.55, -1.70, -4.55),
                wall(-0.80, -4.55, -0.55, -4.55),
            ] + roundedKerb(-1.95, -0.55, -5.95, -4.55, far: 0.42, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.80), width: 0.9, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.10, -2.05), radius: 0.05),
                critter(.penguin, at: SIMD2(-1.05, -2.05),
                        .patrol(axis: acrossLane, amplitude: 0.32), speed: 1.3),
                .post(center: SIMD2(-1.25, -3.10), radius: 0.05),
                critter(.snowman, at: SIMD2(-1.25, -3.75),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 0.7),
                .bumper(center: SIMD2(-1.25, -5.65), radius: 0.08),
            ],
            bonusStar: SIMD2(-1.55, -2.05),
            cameraZoom: 2.05
        ),
    ]
}
