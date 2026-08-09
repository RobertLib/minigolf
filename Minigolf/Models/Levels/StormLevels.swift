//
//  StormLevels.swift
//  Minigolf
//
//  Storm Coast — a shoreline. None of these holes is a shape anybody drew: they
//  are what is left when the sea has taken the rest, so the plan of every one is
//  a staircase of headlands with coves bitten out between them, and the felt
//  steps sideways as often as it runs on. Surf fills the bites, causeways cross
//  them where they can, and where they cannot there is a kicker on the near side
//  and a prayer.
//
//  The herringbone (Filzgolf 15) and the Swedish step (Filzgolf 24) are the two
//  standard lanes that belong on a coast, and both are here: groynes reaching
//  out from alternate boards, and a raised bench with the cup dead in the middle
//  of it.
//

import Foundation
import simd

enum StormCourse {

    static let holes: [LevelDefinition] = [
        // 1 — the first headland. Two steps of shore and a cove between them,
        //     with the surf coming into it: the short way is across the mouth
        //     of the cove, the safe way round the head of it.
        LevelDefinition(
            course: .storm, number: 1, name: String(localized: "Sea Breeze"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.15, -4.75),
            floors: [
                floorRect(-0.95, 0.95, -2.10, 0.50),
                floorRect(-0.95, 1.75, -3.10, -2.10),
                floorRect(0.35, 1.75, -5.30, -3.10),
                floorRect(-0.95, 0.35, -5.30, -3.10, kind: .water),
            ],
            wallLoops: [[
                SIMD2(-0.95, 0.50), SIMD2(0.95, 0.50), SIMD2(0.95, -2.10),
                SIMD2(1.75, -2.10), SIMD2(1.75, -5.30), SIMD2(-0.95, -5.30),
                SIMD2(-0.95, -2.10),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.8, height: 0.03, yaw: 0),
                .fan(rect: zone(-0.90, 1.70, -3.05, -2.15), direction: SIMD2(1, 0),
                     strength: 2.0, period: 3.2, phase: 0, y: 0),
                .post(center: SIMD2(1.05, -2.60), radius: 0.05),
                critter(.crab, at: SIMD2(1.05, -3.70),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.0),
                critter(.seagull, at: SIMD2(1.15, -5.05),
                        .hop(axis: acrossLane, amplitude: 0.26, height: 0.18), speed: 1.1),
            ],
            bonusStar: SIMD2(-0.70, -2.60),
            cameraZoom: 1.85
        ),
        // 2 — the gap. The shore is cut clean through and there is no causeway:
        //     a kicker on the near lip throws the ball the same distance every
        //     time, and the far lip is only a little wider than the ball.
        LevelDefinition(
            course: .storm, number: 2, name: String(localized: "Surf Jump"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.75, -5.15),
            floors: [
                floorRect(-1.15, 1.15, -1.70, 0.50),
                floorRect(-1.15, 1.15, -2.80, -1.70, kind: .water),
                floorRect(-1.15, 1.15, -4.20, -2.80),
                floorRect(-1.15, 0.20, -4.80, -4.20, kind: .water),
                floorRect(0.20, 1.55, -4.80, -4.20),
                floorRect(-1.15, 1.55, -5.80, -4.80),
            ],
            wallLoops: [[
                SIMD2(-1.15, 0.50), SIMD2(1.15, 0.50), SIMD2(1.15, -4.20),
                SIMD2(1.55, -4.20), SIMD2(1.55, -5.80), SIMD2(-1.15, -5.80),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.2, height: 0.03, yaw: 0),
                .launchPad(center: SIMD2(0, -1.52), direction: SIMD2(0, -1),
                           speed: 2.6, lift: 3.0, y: 0),
                .fan(rect: zone(-1.10, 1.10, -3.55, -2.85), direction: SIMD2(1, 0),
                     strength: 2.2, period: 3.0, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0.85, -4.50),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.0),
                critter(.seagull, at: SIMD2(-0.55, -5.30),
                        .hop(axis: acrossLane, amplitude: 0.34, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(-0.90, -3.20),
            cameraZoom: 2.0
        ),
        // 3 — the groynes (Filzgolf 15). Four of them reach out from alternate
        //     boards into a gale that is blowing across all of it.
        LevelDefinition(
            course: .storm, number: 3, name: String(localized: "Gale Alley"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.05),
            floors: [
                floorRect(-1.00, 1.00, -4.30, 0.50),
                floorRect(-1.45, 1.45, -5.60, -4.30),
            ],
            wallLoops: [[
                SIMD2(-1.00, 0.50), SIMD2(1.00, 0.50), SIMD2(1.00, -4.30),
                SIMD2(1.45, -4.30), SIMD2(1.45, -5.60), SIMD2(-1.45, -5.60),
                SIMD2(-1.45, -4.30), SIMD2(-1.00, -4.30),
            ]],
            extraWalls: [
                wall(-1.00, -1.00, -0.10, -1.20),
                wall(1.00, -1.85, 0.10, -2.05),
                wall(-1.00, -2.70, -0.10, -2.90),
                wall(1.00, -3.40, 0.10, -3.60),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 2.0, height: 0.028, yaw: 0),
                .fan(rect: zone(-0.95, 0.95, -3.85, -0.75), direction: SIMD2(1, 0),
                     strength: 2.4, period: 3.4, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0.55, -2.45),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.0),
                critter(.seagull, at: SIMD2(0, -5.30),
                        .hop(axis: acrossLane, amplitude: 0.45, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(1.22, -4.70),
            cameraZoom: 2.0
        ),
        // 4 — the breakwater. Two arms of stone stand off the shore with a gap
        //     in each, and the gaps are not in line: the ball has to be worked
        //     along behind the first arm before the second one opens.
        LevelDefinition(
            course: .storm, number: 4, name: String(localized: "Breakwater"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.95, -4.85),
            floors: [
                floorRect(-1.55, 1.55, -1.60, 0.50),
                floorRect(-1.20, 1.20, -4.00, -1.60),
                floorRect(-1.55, -1.20, -4.00, -1.60, kind: .water),
                floorRect(1.20, 1.55, -4.00, -1.60, kind: .water),
                floorRect(-1.55, 1.55, -5.40, -4.00),
            ],
            wallLoops: [rectLoop(-1.55, 1.55, -5.40, 0.50)],
            extraWalls: [
                wall(-1.20, -2.20, 0.55, -2.20),
                wall(0.95, -2.20, 1.20, -2.20),
                wall(-1.20, -3.40, -0.55, -3.40),
                wall(-0.15, -3.40, 1.20, -3.40),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 3.0, height: 0.028, yaw: 0),
                .fan(rect: zone(-1.15, 1.15, -3.35, -2.25), direction: SIMD2(-1, 0),
                     strength: 2.0, period: 3.0, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0.75, -2.80),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.0),
                critter(.seagull, at: SIMD2(-0.95, -5.10),
                        .hop(axis: acrossLane, amplitude: 0.40, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(1.35, -4.75),
            cameraZoom: 2.05
        ),
        // 5 — the riptide. Three belts of water run across the shore in
        //     alternate directions; the felt between them is dry, and narrow.
        LevelDefinition(
            course: .storm, number: 5, name: String(localized: "Riptide"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -5.05),
            floors: [
                floorRect(-1.60, 1.60, -1.20, 0.50),
                floorRect(-1.60, 1.60, -5.60, -1.20),
            ],
            wallLoops: [rectLoop(-1.60, 1.60, -5.60, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 3.1, height: 0.028, yaw: 0),
                .conveyor(rect: zone(-1.55, 1.55, -2.10, -1.45), direction: SIMD2(1, 0),
                          strength: 2.2, y: 0),
                .conveyor(rect: zone(-1.55, 1.55, -3.30, -2.65), direction: SIMD2(-1, 0),
                          strength: 2.4, y: 0),
                .conveyor(rect: zone(-1.55, 1.55, -4.50, -3.85), direction: SIMD2(1, 0),
                          strength: 2.0, y: 0),
                .post(center: SIMD2(-0.35, -2.40), radius: 0.05),
                .post(center: SIMD2(0.45, -3.60), radius: 0.05),
                critter(.crab, at: SIMD2(-1.20, -4.20),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.0),
                critter(.seagull, at: SIMD2(0.85, -5.35),
                        .hop(axis: acrossLane, amplitude: 0.36, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.35, -2.75),
            cameraZoom: 2.1
        ),
        // 6 — the point. The shore climbs in one step to a bench with the cup
        //     dead in the middle of it (Filzgolf 24), and the bench is out on a
        //     spit with the sea round three sides.
        LevelDefinition(
            course: .storm, number: 6, name: String(localized: "Lighthouse Point"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.15), holeY: 0.14,
            floors: [
                floorRect(-1.45, 1.45, -2.70, 0.50),
                floorRect(-0.55, 0.55, -3.30, -2.70),
                floorRect(-1.45, -0.55, -4.00, -2.70, kind: .water),
                floorRect(0.55, 1.45, -4.00, -2.70, kind: .water),
                floorRect(-1.10, 1.10, -5.80, -3.90, y: 0.14),
                floorRect(-1.45, -1.10, -5.80, -3.30, kind: .water),
                floorRect(1.10, 1.45, -5.80, -3.30, kind: .water),
                floorRect(-1.10, 1.10, -6.40, -5.80, kind: .water),
            ],
            extraWalls: [
                wall(-1.45, 0.50, 1.45, 0.50),
                wall(-1.45, 0.50, -1.45, -2.70),
                wall(1.45, 0.50, 1.45, -2.70),
                wall(-1.45, -2.70, -0.55, -2.70),
                wall(0.55, -2.70, 1.45, -2.70),
                wall(-0.55, -2.70, -0.55, -3.30),
                wall(0.55, -2.70, 0.55, -3.30),
                wall(-0.55, -3.30, -0.25, -3.30, height: 0.26),
                wall(0.25, -3.30, 0.55, -3.30, height: 0.26),
                wall(-1.10, -3.90, -0.25, -3.90, height: 0.26),
                wall(0.25, -3.90, 1.10, -3.90, height: 0.26),
                wall(-1.10, -3.90, -1.10, -5.80, height: 0.26),
                wall(1.10, -3.90, 1.10, -5.80, height: 0.26),
                wall(-1.10, -5.80, 1.10, -5.80, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.8, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.40, 1.40, -1.85, -1.00), direction: SIMD2(1, 0),
                     strength: 2.2, period: 3.0, phase: 0, y: 0),
                .ramp(center: SIMD2(0, -3.60), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                critter(.crab, at: SIMD2(-0.70, -4.55),
                        .patrol(axis: acrossLane, amplitude: 0.26), speed: 1.0, baseY: 0.14),
                critter(.seagull, at: SIMD2(0.70, -5.50),
                        .hop(axis: acrossLane, amplitude: 0.28, height: 0.20),
                        speed: 1.2, baseY: 0.14),
            ],
            bonusStar: SIMD2(0.85, -4.35), bonusStarY: 0.14,
            cameraZoom: 2.05
        ),
        // 7 — the squall. The shore steps twice to the left and once back, and
        //      the wind changes with it: on each step it blows the other way.
        LevelDefinition(
            course: .storm, number: 7, name: String(localized: "Squall"), par: 5,
            tee: SIMD2(0.55, 0), hole: SIMD2(-1.35, -5.05),
            floors: [
                floorRect(-0.15, 1.25, -1.60, 0.50),
                floorRect(-1.15, 1.25, -3.10, -1.60),
                floorRect(-2.05, 0.35, -4.50, -3.10),
                floorRect(-2.05, -0.55, -5.60, -4.50),
            ],
            wallLoops: [[
                SIMD2(-0.15, 0.50), SIMD2(1.25, 0.50), SIMD2(1.25, -3.10),
                SIMD2(0.35, -3.10), SIMD2(0.35, -4.50), SIMD2(-0.55, -4.50),
                SIMD2(-0.55, -5.60), SIMD2(-2.05, -5.60), SIMD2(-2.05, -3.10),
                SIMD2(-1.15, -3.10), SIMD2(-1.15, -1.60), SIMD2(-0.15, -1.60),
            ]],
            obstacles: [
                .bump(center: SIMD2(0.55, -0.70), width: 1.3, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.10, 1.20, -3.05, -1.70), direction: SIMD2(-1, 0),
                     strength: 2.2, period: 3.0, phase: 0, y: 0),
                .fan(rect: zone(-2.00, 0.30, -4.45, -3.20), direction: SIMD2(1, 0),
                     strength: 2.0, period: 3.0, phase: 1.5, y: 0),
                critter(.crab, at: SIMD2(-0.35, -2.35),
                        .patrol(axis: acrossLane, amplitude: 0.40), speed: 1.0),
                critter(.seagull, at: SIMD2(-1.35, -5.30),
                        .hop(axis: acrossLane, amplitude: 0.34, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(1.05, -2.75),
            cameraZoom: 2.15
        ),
        // 8 — the tide pools. A shelf of rock with the sea standing in it: five
        //      pools, none of them in line with the next, and dry stone between.
        LevelDefinition(
            course: .storm, number: 8, name: String(localized: "Tide Pools"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.55, -5.25),
            floors: [
                floorRect(-1.70, 1.70, -1.10, 0.50),
                floorRect(-1.70, -0.95, -2.10, -1.10, kind: .water),
                floorRect(-0.95, 1.70, -2.10, -1.10),
                floorRect(-1.70, 1.70, -2.60, -2.10),
                floorRect(-1.70, 0.25, -3.60, -2.60),
                floorRect(0.25, 1.10, -3.60, -2.60, kind: .water),
                floorRect(1.10, 1.70, -3.60, -2.60),
                floorRect(-1.70, 1.70, -4.10, -3.60),
                floorRect(-1.70, -1.05, -5.00, -4.10, kind: .water),
                floorRect(-1.05, 0.15, -5.00, -4.10),
                floorRect(0.15, 0.95, -5.00, -4.10, kind: .water),
                floorRect(0.95, 1.70, -5.00, -4.10),
                floorRect(-1.70, 1.70, -5.60, -5.00),
            ],
            wallLoops: [rectLoop(-1.70, 1.70, -5.60, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 3.3, height: 0.028, yaw: 0),
                .post(center: SIMD2(0.60, -1.60), radius: 0.05),
                .post(center: SIMD2(-0.55, -3.10), radius: 0.05),
                critter(.crab, at: SIMD2(1.38, -3.10),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.0),
                critter(.seagull, at: SIMD2(0.55, -5.45),
                        .hop(axis: acrossLane, amplitude: 0.45, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.45, -3.10),
            cameraZoom: 2.15
        ),
        // 9 — the surge. A cove open to the sea at both ends with a causeway
        //      across the middle of it, and the wind straight down the cove.
        LevelDefinition(
            course: .storm, number: 9, name: String(localized: "Storm Surge"), par: 5,
            tee: SIMD2(-1.30, 0), hole: SIMD2(1.30, -4.85),
            floors: [
                floorRect(-1.75, -0.55, -3.40, 0.50),
                floorRect(-0.55, 0.55, -2.90, -2.20),
                floorRect(0.55, 1.75, -3.40, 0.50),
                floorRect(-0.55, 0.55, -3.40, -2.90, kind: .water),
                floorRect(-0.55, 0.55, -2.20, 0.50, kind: .water),
                floorRect(-1.75, 1.75, -5.40, -3.40),
            ],
            wallLoops: [rectLoop(-1.75, 1.75, -5.40, 0.50)],
            obstacles: [
                .bump(center: SIMD2(-1.15, -0.70), width: 0.85, height: 0.03, yaw: 0),
                .fan(rect: zone(-0.50, 0.50, -2.85, -2.25), direction: SIMD2(0, -1),
                     strength: 2.6, period: 2.8, phase: 0, y: 0),
                .post(center: SIMD2(-1.30, -2.05), radius: 0.05),
                critter(.crab, at: SIMD2(1.15, -1.95),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.0),
                critter(.seagull, at: SIMD2(0, -4.95),
                        .hop(axis: acrossLane, amplitude: 0.60, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.45, -4.55),
            cameraZoom: 2.2
        ),
        // 10 — the cliff path. Four ledges stepping down the headland, each one
        //      hanging out over the water further than the last.
        LevelDefinition(
            course: .storm, number: 10, name: String(localized: "Cliff Path"), par: 5,
            tee: SIMD2(-1.30, 0), hole: SIMD2(1.45, -5.35),
            floors: [
                floorRect(-1.80, -0.60, -1.40, 0.50),
                floorRect(-0.60, 2.10, -1.40, 0.50, kind: .water),
                floorRect(-1.80, 0.30, -2.60, -1.40),
                floorRect(0.30, 2.10, -2.60, -1.40, kind: .water),
                floorRect(-1.80, -0.90, -3.80, -2.60, kind: .water),
                floorRect(-0.90, 1.20, -3.80, -2.60),
                floorRect(1.20, 2.10, -3.80, -2.60, kind: .water),
                floorRect(-1.80, 0.00, -5.00, -3.80, kind: .water),
                floorRect(0.00, 2.10, -5.00, -3.80),
                floorRect(-1.80, 0.60, -5.70, -5.00, kind: .water),
                floorRect(0.60, 2.10, -5.70, -5.00),
            ],
            wallLoops: [rectLoop(-1.80, 2.10, -5.70, 0.50)],
            obstacles: [
                .bump(center: SIMD2(-1.20, -0.70), width: 1.0, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.75, 0.25, -2.55, -1.50), direction: SIMD2(1, 0),
                     strength: 2.0, period: 3.2, phase: 0, y: 0),
                critter(.crab, at: SIMD2(0.15, -3.20),
                        .patrol(axis: acrossLane, amplitude: 0.40), speed: 1.0),
                .post(center: SIMD2(1.05, -4.40), radius: 0.05),
                critter(.seagull, at: SIMD2(0.95, -5.35),
                        .hop(axis: acrossLane, amplitude: 0.25, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.55, -2.00),
            cameraZoom: 2.25
        ),
        // 11 — the maelstrom. A ring of rock round deep water, and the wind
        //      goes round it too: whichever way you set off, half the lap is
        //      into the teeth of it.
        LevelDefinition(
            course: .storm, number: 11, name: String(localized: "Maelstrom"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.05),
            floors: [
                floorRect(-1.75, 1.75, -1.70, 0.50),
                floorRect(-1.75, -0.70, -4.10, -1.70),
                floorRect(0.70, 1.75, -4.10, -1.70),
                floorRect(-1.75, 1.75, -5.50, -4.10),
                floorRect(-0.70, 0.70, -4.10, -1.70, kind: .water),
            ],
            wallLoops: [rectLoop(-1.75, 1.75, -5.50, 0.50)],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 3.4, height: 0.028, yaw: 0),
                .fan(rect: zone(-1.70, -0.75, -4.05, -1.75), direction: SIMD2(0, 1),
                     strength: 2.2, period: 3.0, phase: 0, y: 0),
                .fan(rect: zone(0.75, 1.70, -4.05, -1.75), direction: SIMD2(0, -1),
                     strength: 2.2, period: 3.0, phase: 1.5, y: 0),
                .post(center: SIMD2(-1.22, -2.90), radius: 0.05),
                .post(center: SIMD2(1.22, -2.90), radius: 0.05),
                critter(.crab, at: SIMD2(0, -4.55),
                        .patrol(axis: acrossLane, amplitude: 0.70), speed: 1.0),
                critter(.seagull, at: SIMD2(0, -5.30),
                        .hop(axis: acrossLane, amplitude: 0.50, height: 0.20), speed: 1.2),
            ],
            bonusStar: SIMD2(1.50, -5.10),
            cameraZoom: 2.25
        ),
        // 12 — the whole coast: the cove, the gap with the kicker over it, the
        //      groynes, and the last bench out on the point with the sea round
        //      three sides of it.
        LevelDefinition(
            course: .storm, number: 12, name: String(localized: "Storm Coast"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.40), holeY: 0.14,
            floors: [
                floorRect(-1.10, 1.10, -1.40, 0.50),
                floorRect(-1.10, 1.85, -2.40, -1.40),
                floorRect(0.45, 1.85, -3.60, -2.40),
                floorRect(-1.10, 0.45, -3.60, -2.40, kind: .water),
                floorRect(-1.10, 1.85, -4.40, -3.60),
                floorRect(-1.10, 1.85, -5.10, -4.40, kind: .water),
                floorRect(-1.10, 1.85, -5.40, -5.10),
                floorRect(-0.95, 0.95, -7.10, -6.00, y: 0.14),
                floorRect(-1.10, -0.95, -7.10, -5.40, kind: .water),
                floorRect(0.95, 1.85, -7.10, -5.40, kind: .water),
                floorRect(-0.95, 0.95, -7.60, -7.10, kind: .water),
            ],
            extraWalls: [
                wall(-1.10, 0.50, 1.10, 0.50),
                wall(-1.10, 0.50, -1.10, -1.40),
                wall(1.10, 0.50, 1.10, -1.40),
                wall(1.10, -1.40, 1.85, -1.40),
                wall(1.85, -1.40, 1.85, -5.40),
                wall(-1.10, -1.40, -1.10, -5.40),
                wall(-1.10, -5.40, -0.25, -5.40, height: 0.26),
                wall(0.25, -5.40, 1.85, -5.40, height: 0.26),
                wall(-0.95, -6.00, -0.25, -6.00, height: 0.26),
                wall(0.25, -6.00, 0.95, -6.00, height: 0.26),
                wall(-0.95, -6.00, -0.95, -7.10, height: 0.26),
                wall(0.95, -6.00, 0.95, -7.10, height: 0.26),
                wall(-0.95, -7.10, 0.95, -7.10, height: 0.26),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 2.1, height: 0.03, yaw: 0),
                .fan(rect: zone(-1.05, 1.80, -2.35, -1.50), direction: SIMD2(1, 0),
                     strength: 2.2, period: 3.2, phase: 0, y: 0),
                critter(.crab, at: SIMD2(1.15, -3.00),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.0),
                .launchPad(center: SIMD2(0.35, -3.75), direction: SIMD2(0, -1),
                           speed: 2.6, lift: 3.0, y: 0),
                .ramp(center: SIMD2(0, -5.70), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                critter(.seagull, at: SIMD2(0, -6.75),
                        .hop(axis: acrossLane, amplitude: 0.30, height: 0.20),
                        speed: 1.2, baseY: 0.14),
            ],
            bonusStar: SIMD2(1.68, -3.40),
            cameraZoom: 2.35
        ),
    ]
}
