//
//  DesertLevels.swift
//  Minigolf
//
//  Desert Oasis — sand everywhere, and the first world that makes the player
//  read a whole hole before hitting it. Banked corners come back wider, the
//  rotors arrive, and by the end there is a pool to carry and a crowned green
//  behind a gate.
//

import Foundation
import simd

enum DesertCourse {

    static let holes: [LevelDefinition] = [
        // 1 — an easy opener, but the sand is already in the way of the lazy
        //     line and the boards in front of the cup only accept a straight one.
        LevelDefinition(
            course: .desert, number: 1, name: String(localized: "Oasis Gate"), par: 2,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [
                floorRect(-0.55, 0.55, -3.4, 0.5),
                floorRect(-0.55, 0.1, -2.1, -1.3, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.55, 0.55, -3.4, 0.5)],
            extraWalls: [
                wall(-0.55, -2.45, -0.26, -2.62),
                wall(0.55, -2.45, 0.26, -2.62),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.1, height: 0.03, yaw: 0),
                critter(.tumbleweed, at: SIMD2(0, -1.65),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 1.0),
                .post(center: SIMD2(-0.26, -2.15), radius: 0.04),
                .post(center: SIMD2(0.26, -2.15), radius: 0.04),
            ],
            bonusStar: SIMD2(0.38, -3.15)
        ),
        // 2 — a long left-hand dogleg with the outer corner rounded off, and a
        //     rotor sweeping the second leg once the turn is behind you.
        LevelDefinition(
            course: .desert, number: 2, name: String(localized: "Dune Bank"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(-1.9, -3.2),
            floors: [
                floorRect(-0.5, 0.5, -2.7, 0.5),
                floorRect(-2.3, 0.5, -3.7, -2.7),
                floorRect(-1.5, -0.4, -3.7, -3.2, kind: .sand),
            ],
            wallLoops: [[
                SIMD2(0.5, 0.5), SIMD2(0.5, -3.7), SIMD2(-2.3, -3.7),
                SIMD2(-2.3, -2.7), SIMD2(-0.5, -2.7), SIMD2(-0.5, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-0.1, -3.1), radius: 0.6,
                                from: deg(270), to: deg(360), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -1.1), width: 1.0, height: 0.032, yaw: 0),
                .post(center: SIMD2(0.26, -1.9), radius: 0.04),
                critter(.meerkat, at: SIMD2(-0.6, -2.95), .burrow(period: 2.6)),
                .rotor(center: SIMD2(-1.0, -3.2), length: 0.7, speed: 1.4, baseY: 0),
                .post(center: SIMD2(-1.5, -3.55), radius: 0.04),
                .bumper(center: SIMD2(-2.05, -2.95), radius: 0.06),
            ],
            bonusStar: SIMD2(0.2, -3.45),
            cameraZoom: 1.4
        ),
        // 3 — three crests in a row. Each one steals speed and turns the ball a
        //     little, so the block waiting on the far side is never met twice
        //     from the same angle.
        LevelDefinition(
            course: .desert, number: 3, name: String(localized: "Rolling Dunes"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.8),
            floors: [
                floorRect(-0.7, 0.7, -4.4, 0.5),
                floorRect(-0.7, -0.05, -2.75, -2.05, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.4, height: 0.035, yaw: 0),
                .post(center: SIMD2(-0.3, -1.4), radius: 0.04),
                .bump(center: SIMD2(0, -1.9), width: 1.4, height: 0.04, yaw: 0),
                .movingBlock(center: SIMD2(0, -2.4), axis: acrossLane, amplitude: 0.35,
                             speed: 1.0, size: SIMD2(0.35, 0.2), baseY: 0),
                .bump(center: SIMD2(0, -2.9), width: 1.4, height: 0.035, yaw: 0),
                critter(.tumbleweed, at: SIMD2(0, -3.35),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1),
                .post(center: SIMD2(0.3, -3.6), radius: 0.04),
            ],
            bonusStar: SIMD2(0.5, -4.15),
            cameraZoom: 1.25
        ),
        // 4 — an open field strewn with rocks. Nothing here blocks the hole, but
        //     nothing lets a putt through unbent either.
        LevelDefinition(
            course: .desert, number: 4, name: String(localized: "Scorpion Rocks"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.9, -3.9),
            floors: [
                floorRect(-1.3, 1.3, -4.4, 0.5),
                floorRect(0.3, 1.3, -2.0, -1.4, kind: .sand),
                floorRect(-1.3, -0.3, -3.4, -2.9, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.3, 1.3, -4.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.6, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-0.4, -1.5), radius: 0.06),
                .bumper(center: SIMD2(0.45, -2.1), radius: 0.06),
                .block(center: SIMD2(-0.85, -2.6), size: SIMD3(0.5, 0.16, 0.7),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(0, -2.9), radius: 0.04),
                .block(center: SIMD2(0.6, -3.15), size: SIMD3(0.45, 0.16, 0.6),
                       yaw: 0, baseY: 0),
                critter(.meerkat, at: SIMD2(-0.3, -3.5), .burrow(period: 2.8)),
                critter(.tumbleweed, at: SIMD2(0.2, -0.95),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.1, -4.15),
            cameraZoom: 1.5
        ),
        // 5 — two bars turning against each other, then a hatch that is the only
        //     way onto the last stretch: the first hole that has to be timed
        //     twice in a row.
        LevelDefinition(
            course: .desert, number: 5, name: String(localized: "Rotor Alley"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.0),
            floors: [
                floorRect(-0.8, 0.8, -4.6, 0.5),
                floorRect(-0.8, 0.8, -2.6, -2.1, kind: .sand),
            ],
            wallLoops: [rectLoop(-0.8, 0.8, -4.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.6, height: 0.03, yaw: 0),
                .rotor(center: SIMD2(0, -1.6), length: 0.9, speed: 1.5, baseY: 0),
                .post(center: SIMD2(-0.5, -2.3), radius: 0.04),
                .post(center: SIMD2(0.5, -2.3), radius: 0.04),
                .rotor(center: SIMD2(0, -2.9), length: 0.9, speed: -1.7, baseY: 0),
                .gate(center: SIMD2(0, -3.5), size: SIMD2(1.0, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .block(center: SIMD2(-0.65, -3.5), size: SIMD3(0.3, 0.16, 0.12),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.65, -3.5), size: SIMD3(0.3, 0.16, 0.12),
                       yaw: 0, baseY: 0),
                critter(.meerkat, at: SIMD2(0, -4.35), .burrow(period: 3.0)),
            ],
            bonusStar: SIMD2(0.6, -4.35),
            cameraZoom: 1.35
        ),
        // 6 — a horseshoe. The cup is barely two metres from the tee in a
        //     straight line and five and a half the way the ball has to go, and
        //     the turn at the bottom is banked so the run back up can be taken
        //     in one.
        LevelDefinition(
            course: .desert, number: 6, name: String(localized: "The Long Bank"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.4, -1.85),
            floors: [
                floorRect(-0.6, 0.6, -3.0, 0.5),
                floorRect(-1.9, 0.6, -4.0, -3.0),
                floorRect(-1.9, -0.9, -3.0, -1.4),
                floorRect(-1.9, -0.9, -2.9, -2.3, kind: .sand),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -4.0), SIMD2(-1.9, -4.0),
                SIMD2(-1.9, -1.4), SIMD2(-0.9, -1.4), SIMD2(-0.9, -3.0),
                SIMD2(-0.6, -3.0), SIMD2(-0.6, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-1.3, -3.4), radius: 0.6,
                                from: deg(180), to: deg(270), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -1.0), width: 1.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.3, -1.8), radius: 0.04),
                .rotor(center: SIMD2(0, -2.4), length: 0.8, speed: 1.4, baseY: 0),
                .bumper(center: SIMD2(0.3, -3.5), radius: 0.06),
                critter(.tumbleweed, at: SIMD2(-1.0, -3.5),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                critter(.meerkat, at: SIMD2(-1.4, -2.6), .burrow(period: 2.8)),
                .post(center: SIMD2(-1.15, -2.2), radius: 0.04),
            ],
            bonusStar: SIMD2(0.35, -3.6),
            cameraZoom: 1.55
        ),
        // 7 — two great drifts of sand laid across the lane in opposite
        //     directions. There is a clean line through both, and the block
        //     sliding across the neck of it decides when you may take it.
        LevelDefinition(
            course: .desert, number: 7, name: String(localized: "Quicksand"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-1.0, 1.0, -4.6, 0.5),
                floorRect(-1.0, 0.35, -2.0, -1.2, kind: .sand),
                floorRect(-0.35, 1.0, -3.3, -2.5, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.0, 1.0, -4.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.55, -1.6), radius: 0.04),
                .movingBlock(center: SIMD2(0, -2.25), axis: acrossLane, amplitude: 0.5,
                             speed: 1.1, size: SIMD2(0.4, 0.18), baseY: 0),
                critter(.meerkat, at: SIMD2(-0.5, -2.9), .burrow(period: 2.6)),
                .post(center: SIMD2(-0.6, -3.6), radius: 0.04),
                critter(.tumbleweed, at: SIMD2(0.4, -3.8),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.2),
                .bumper(center: SIMD2(0.7, -4.2), radius: 0.06),
            ],
            bonusStar: SIMD2(-0.85, -4.3),
            cameraZoom: 1.45
        ),
        // 8 — the lane opens into an apron, the apron climbs, and the green on
        //     top is shut behind a hatch that runs its whole width.
        LevelDefinition(
            course: .desert, number: 8, name: String(localized: "Camel Humps"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.4), holeY: 0.15,
            floors: [
                floorRect(-0.55, 0.55, -1.9, 0.5),
                floorRect(-1.2, 1.2, -2.8, -1.9),
                floorRect(-1.2, -0.3, -2.75, -2.0, kind: .sand),
                floorRect(-1.0, 1.0, -4.9, -3.5, y: 0.15),
            ],
            extraWalls: [
                wall(-0.55, 0.5, 0.55, 0.5),
                wall(0.55, 0.5, 0.55, -1.9),
                wall(0.55, -1.9, 1.2, -1.9),
                wall(1.2, -1.9, 1.2, -2.8),
                wall(1.2, -2.8, 0.45, -2.8),
                wall(-0.45, -2.8, -1.2, -2.8),
                wall(-1.2, -2.8, -1.2, -1.9),
                wall(-1.2, -1.9, -0.55, -1.9),
                wall(-0.55, -1.9, -0.55, 0.5),
                wall(-1.0, -3.5, -0.45, -3.5, height: 0.28),
                wall(0.45, -3.5, 1.0, -3.5, height: 0.28),
                wall(1.0, -3.5, 1.0, -4.9, height: 0.28),
                wall(1.0, -4.9, -1.0, -4.9, height: 0.28),
                wall(-1.0, -4.9, -1.0, -3.5, height: 0.28),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.1, height: 0.035, yaw: 0),
                .bumper(center: SIMD2(-0.8, -2.35), radius: 0.06),
                .bumper(center: SIMD2(0.8, -2.35), radius: 0.06),
                critter(.meerkat, at: SIMD2(0, -2.4), .burrow(period: 2.4)),
                .ramp(center: SIMD2(0, -3.15), width: 0.9, length: 0.7, rise: 0.15, yaw: 0),
                .gate(center: SIMD2(0, -3.9), size: SIMD2(2.0, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0.15),
                .block(center: SIMD2(-0.7, -4.1), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.15),
                critter(.tumbleweed, at: SIMD2(0.6, -4.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.15),
            ],
            bonusStar: SIMD2(1.05, -2.4),
            cameraZoom: 1.6
        ),
        // 9 — the pool the world is named for. Round it left or right; both
        //     channels are guarded, and the wide one is not the safe one.
        LevelDefinition(
            course: .desert, number: 9, name: String(localized: "The Oasis"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.3),
            floors: [
                floorRect(-1.5, 1.5, -1.8, 0.5),
                floorRect(-1.5, -0.75, -3.2, -1.8),
                floorRect(-0.75, 0.75, -3.2, -1.8, kind: .water),
                floorRect(0.75, 1.5, -3.2, -1.8),
                floorRect(-1.5, 1.5, -5.0, -3.2),
            ],
            wallLoops: [rectLoop(-1.5, 1.5, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(-1.1, -1.4), radius: 0.04),
                .post(center: SIMD2(1.1, -1.4), radius: 0.04),
                .bumper(center: SIMD2(-1.15, -2.5), radius: 0.06),
                .bumper(center: SIMD2(1.15, -2.5), radius: 0.06),
                critter(.tumbleweed, at: SIMD2(-1.1, -3.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1),
                critter(.meerkat, at: SIMD2(1.0, -3.7), .burrow(period: 2.8)),
                .block(center: SIMD2(0, -3.75), size: SIMD3(0.7, 0.16, 0.25),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(0, -4.75), radius: 0.04),
            ],
            bonusStar: SIMD2(1.32, -2.9),
            cameraZoom: 1.6
        ),
        // 10 — a proper zigzag: five legs, two of the corners banked, and a
        //      hatch on the last one so the run home cannot simply be blasted.
        LevelDefinition(
            course: .desert, number: 10, name: String(localized: "Sidewinder"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.1, -4.85),
            floors: [
                floorRect(-0.55, 0.55, -1.5, 0.5),
                floorRect(-1.6, 0.55, -2.4, -1.5),
                floorRect(-1.6, -0.6, -3.4, -2.4),
                floorRect(-1.6, -0.6, -3.3, -2.6, kind: .sand),
                floorRect(-1.6, 1.6, -4.3, -3.4),
                floorRect(0.6, 1.6, -5.2, -4.3),
            ],
            wallLoops: [[
                SIMD2(0.55, 0.5), SIMD2(0.55, -2.4), SIMD2(-0.6, -2.4),
                SIMD2(-0.6, -3.4), SIMD2(1.6, -3.4), SIMD2(1.6, -5.2),
                SIMD2(0.6, -5.2), SIMD2(0.6, -4.3), SIMD2(-1.6, -4.3),
                SIMD2(-1.6, -1.5), SIMD2(-0.55, -1.5), SIMD2(-0.55, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-1.1, -2.0), radius: 0.5,
                                from: deg(90), to: deg(180), segments: 4)
                      + arcWall(center: SIMD2(1.1, -3.9), radius: 0.5,
                                from: deg(0), to: deg(90), segments: 4),
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.1, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.25, -2.0), radius: 0.04),
                critter(.tumbleweed, at: SIMD2(-1.1, -2.9),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.0),
                .rotor(center: SIMD2(-1.1, -3.85), length: 0.8, speed: 1.5, baseY: 0),
                .bumper(center: SIMD2(0, -3.85), radius: 0.06),
                critter(.meerkat, at: SIMD2(0.75, -3.8), .burrow(period: 2.6)),
                .gate(center: SIMD2(1.1, -4.5), size: SIMD2(1.0, 0.09), yaw: 0,
                      period: 2.4, phase: 0.3, baseY: 0),
                .post(center: SIMD2(0.85, -4.95), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.35, -4.05),
            cameraZoom: 1.7
        ),
        // 11 — open ground, a following wind of an accelerator plate, and two
        //      blocks patrolling the width of it. Speed is easy to come by here
        //      and hard to spend well.
        LevelDefinition(
            course: .desert, number: 11, name: String(localized: "Sandstorm"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.2, -4.7),
            floors: [
                floorRect(-1.7, 1.7, -5.4, 0.5),
                floorRect(-1.7, -0.4, -2.6, -1.6, kind: .sand),
                floorRect(0.4, 1.7, -3.8, -2.8, kind: .sand),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.4, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.5), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .bumper(center: SIMD2(1.35, -1.9), radius: 0.06),
                .movingBlock(center: SIMD2(-0.6, -2.3), axis: acrossLane, amplitude: 0.6,
                             speed: 1.0, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(-1.35, -3.3), radius: 0.06),
                .movingBlock(center: SIMD2(0.7, -3.3), axis: acrossLane, amplitude: 0.6,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.tumbleweed, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.2),
                .post(center: SIMD2(-1.6, -4.2), radius: 0.04),
                .block(center: SIMD2(0.4, -4.8), size: SIMD3(0.6, 0.16, 0.3),
                       yaw: 0, baseY: 0),
                critter(.meerkat, at: SIMD2(-0.6, -4.9), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(1.5, -5.05),
            cameraZoom: 1.75
        ),
        // 12 — the world's whole vocabulary in one hole: a rotor on the way out,
        //      shoulders that turn a wide putt back down the middle, the pool
        //      with one plank over it, a block sweeping the far bank and a
        //      crowned green behind a hatch.
        LevelDefinition(
            course: .desert, number: 12, name: String(localized: "Desert Crown"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.35), holeY: 0.15,
            floors: [
                floorRect(-0.65, 0.65, -1.8, 0.5),
                floorRect(-1.8, 1.8, -3.0, -1.8),
                floorRect(-1.8, -0.7, -2.9, -2.0, kind: .sand),
                floorRect(0.7, 1.8, -2.9, -2.0, kind: .sand),
                floorRect(-1.8, -0.3, -3.8, -3.0, kind: .water),
                floorRect(-0.3, 0.25, -3.8, -3.0),
                floorRect(0.25, 1.8, -3.8, -3.0, kind: .water),
                floorRect(-1.8, 1.8, -4.4, -3.8),
                floorRect(-1.3, 1.3, -5.7, -5.0, y: 0.15),
            ],
            extraWalls: [
                wall(-0.65, 0.5, 0.65, 0.5),
                wall(0.65, 0.5, 0.65, -1.8),
                wall(0.65, -1.8, 1.8, -1.8),
                wall(1.8, -1.8, 1.8, -4.4),
                wall(1.8, -4.4, 0.45, -4.4),
                wall(-0.45, -4.4, -1.8, -4.4),
                wall(-1.8, -4.4, -1.8, -1.8),
                wall(-1.8, -1.8, -0.65, -1.8),
                wall(-0.65, -1.8, -0.65, 0.5),
                wall(-1.3, -5.0, -0.45, -5.0, height: 0.28),
                wall(0.45, -5.0, 1.3, -5.0, height: 0.28),
                wall(1.3, -5.0, 1.3, -5.7, height: 0.28),
                wall(1.3, -5.7, -1.3, -5.7, height: 0.28),
                wall(-1.3, -5.7, -1.3, -5.0, height: 0.28),
            ]
            + arcWall(center: SIMD2(-1.25, -2.35), radius: 0.55,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.25, -2.35), radius: 0.55,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.3, height: 0.035, yaw: 0),
                .rotor(center: SIMD2(0, -1.35), length: 0.9, speed: 1.6, baseY: 0),
                .bumper(center: SIMD2(-0.9, -2.4), radius: 0.06),
                .bumper(center: SIMD2(0.9, -2.4), radius: 0.06),
                critter(.tumbleweed, at: SIMD2(0, -2.5),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.2),
                .movingBlock(center: SIMD2(0, -4.1), axis: acrossLane, amplitude: 0.7,
                             speed: 1.1, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.meerkat, at: SIMD2(-1.2, -4.1), .burrow(period: 2.6)),
                .ramp(center: SIMD2(0, -4.7), width: 0.9, length: 0.6, rise: 0.15, yaw: 0),
                .gate(center: SIMD2(0, -5.15), size: SIMD2(2.6, 0.09), yaw: 0,
                      period: 2.8, phase: 0, baseY: 0.15),
                .block(center: SIMD2(0.9, -5.5), size: SIMD3(0.4, 0.14, 0.4),
                       yaw: 0, baseY: 0.15),
                critter(.tumbleweed, at: SIMD2(-0.75, -5.5),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 1.0, baseY: 0.15),
            ],
            bonusStar: SIMD2(1.55, -4.15),
            cameraZoom: 1.85
        ),
    ]
}
