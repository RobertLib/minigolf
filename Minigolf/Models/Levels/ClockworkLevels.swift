//
//  ClockworkLevels.swift
//  Minigolf
//
//  Clockwork Works — a gear train. Every hole is round chambers strung on
//  straight shafts: the ball drops into a wheel, is carried round it by whatever
//  is turning in there and leaves through a slot on the far side into the next
//  one. A chamber is 2.0–3.2 m across and a shaft 0.6–0.7 m wide, so the gap
//  between them is the whole difficulty — a wheel is easy to get into and hard
//  to leave in the direction you meant.
//
//  Two standard lanes fit a machine shop exactly and are built as such: the
//  optical illusion (Filzgolf 5), four gates equally spaced with the first one
//  wider than the rest, and the hollow (Filzgolf 26), where the target is the
//  bowl itself rather than a cup in a floor.
//

import Foundation
import simd

enum ClockworkCourse {

    /// Chambers are turned with three boards to the corner, the same as the
    /// garden's greens — a wheel has to read as a wheel from the tee.
    private static let turn: Float = 0.42

    static let holes: [LevelDefinition] = [
        // 1 — one wheel on the end of one shaft, with a turntable set into it.
        //     Where the ball ends up depends on where on the disc it lands.
        LevelDefinition(
            course: .clockwork, number: 1, name: String(localized: "First Gear"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.85),
            floors: [
                floorRect(-0.35, 0.35, -1.80, 0.50),
            ] + roundedFloor(-1.30, 1.30, -4.40, -1.80, far: turn, near: turn, steps: 3),
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.80),
                wall(0.35, 0.50, 0.35, -1.80),
                wall(-0.88, -1.80, -0.35, -1.80),
                wall(0.35, -1.80, 0.88, -1.80),
            ] + roundedKerb(-1.30, 1.30, -4.40, -1.80, far: turn, near: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.7, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -2.85), radius: 0.55, speed: 1.6, y: 0),
                critter(.windupBot, at: SIMD2(-1.00, -3.60),
                        .patrol(axis: acrossLane, amplitude: 0.20), speed: 1.2),
                critter(.cuckoo, at: SIMD2(0.95, -2.20), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.05, -3.55),
            cameraZoom: 1.85
        ),
        // 2 — two wheels on one line, with the escapement between them: the
        //     shaft out of the first is only open every other beat.
        LevelDefinition(
            course: .clockwork, number: 2, name: String(localized: "Escapement"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.60),
            floors: [
                floorRect(-0.32, 0.32, -1.00, 0.50),
            ] + roundedFloor(-1.05, 1.05, -3.00, -1.00, far: turn, near: turn, steps: 3)
              + [floorRect(-0.32, 0.32, -3.60, -3.00)]
              + roundedFloor(-1.05, 1.05, -5.60, -3.60, far: turn, near: turn, steps: 3),
            extraWalls: [
                wall(-0.32, 0.50, 0.32, 0.50),
                wall(-0.32, 0.50, -0.32, -1.00),
                wall(0.32, 0.50, 0.32, -1.00),
                wall(-0.63, -1.00, -0.32, -1.00),
                wall(0.32, -1.00, 0.63, -1.00),
                wall(-0.63, -3.00, -0.32, -3.00),
                wall(0.32, -3.00, 0.63, -3.00),
                wall(-0.32, -3.00, -0.32, -3.60),
                wall(0.32, -3.00, 0.32, -3.60),
                wall(-0.63, -3.60, -0.32, -3.60),
                wall(0.32, -3.60, 0.63, -3.60),
            ] + roundedKerb(-1.05, 1.05, -3.00, -1.00, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.05, 1.05, -5.60, -3.60, far: turn, near: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.6, height: 0.03, yaw: 0),
                .rotor(center: SIMD2(0, -2.00), length: 1.4, speed: 1.5, baseY: 0),
                .gate(center: SIMD2(0, -3.30), size: SIMD2(0.60, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0),
                critter(.windupBot, at: SIMD2(0, -5.00),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 1.2),
                critter(.cuckoo, at: SIMD2(-0.80, -4.30), .burrow(period: 2.4)),
            ],
            bonusStar: SIMD2(0.85, -2.35),
            cameraZoom: 1.95
        ),
        // 3 — the governor. One big wheel with two arms swinging over it on
        //     different beats, and a shaft out of the far side into a bay: the
        //     arms have to be got past twice, once each way.
        LevelDefinition(
            course: .clockwork, number: 3, name: String(localized: "The Governor"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.55, -4.95),
            floors: [
                floorRect(-0.35, 0.35, -1.30, 0.50),
            ] + roundedFloor(-1.25, 1.25, -3.90, -1.30, far: turn, near: turn, steps: 3)
              + [
                floorRect(-0.32, 0.32, -4.50, -3.90),
                floorRect(-1.10, 1.10, -5.40, -4.50),
              ],
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.30),
                wall(0.35, 0.50, 0.35, -1.30),
                wall(-0.83, -1.30, -0.35, -1.30),
                wall(0.35, -1.30, 0.83, -1.30),
                wall(-0.83, -3.90, -0.32, -3.90),
                wall(0.32, -3.90, 0.83, -3.90),
                wall(-0.32, -3.90, -0.32, -4.50),
                wall(0.32, -3.90, 0.32, -4.50),
                wall(-1.10, -4.50, -0.32, -4.50),
                wall(0.32, -4.50, 1.10, -4.50),
                wall(-1.10, -4.50, -1.10, -5.40),
                wall(1.10, -4.50, 1.10, -5.40),
                wall(-1.10, -5.40, 1.10, -5.40),
            ] + roundedKerb(-1.25, 1.25, -3.90, -1.30, far: turn, near: turn,
                            steps: 3, openFar: true),
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.7, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -2.10), span: 1.6, arc: deg(50),
                          speed: 1.4, yaw: 0, baseY: 0),
                .pendulum(center: SIMD2(0, -3.20), span: 1.6, arc: deg(50),
                          speed: -1.8, yaw: 0, baseY: 0),
                critter(.cuckoo, at: SIMD2(-0.85, -2.60), .burrow(period: 2.6)),
                critter(.windupBot, at: SIMD2(-0.55, -4.95),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.1),
            ],
            bonusStar: SIMD2(1.05, -2.60),
            cameraZoom: 2.0
        ),
        // 4 — three wheels on one line, their discs turning the opposite way
        //     from each other, and a shaft the width of two balls between them:
        //     a wheel is easy to get into and hard to leave where you meant to.
        LevelDefinition(
            course: .clockwork, number: 4, name: String(localized: "Turntable Row"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.55, -6.10),
            floors: [
                floorRect(-0.32, 0.32, -0.90, 0.50),
            ] + roundedFloor(-1.05, 1.05, -2.60, -0.90, far: turn, near: turn, steps: 3)
              + [floorRect(-0.32, 0.32, -3.20, -2.60)]
              + roundedFloor(-1.05, 1.05, -4.90, -3.20, far: turn, near: turn, steps: 3)
              + [floorRect(-0.32, 0.32, -5.50, -4.90)]
              + roundedFloor(-1.05, 1.05, -7.00, -5.50, far: turn, near: turn, steps: 3),
            extraWalls: [
                wall(-0.32, 0.50, 0.32, 0.50),
                wall(-0.32, 0.50, -0.32, -0.90),
                wall(0.32, 0.50, 0.32, -0.90),
                wall(-0.63, -0.90, -0.32, -0.90),
                wall(0.32, -0.90, 0.63, -0.90),
                wall(-0.63, -2.60, -0.32, -2.60),
                wall(0.32, -2.60, 0.63, -2.60),
                wall(-0.32, -2.60, -0.32, -3.20),
                wall(0.32, -2.60, 0.32, -3.20),
                wall(-0.63, -3.20, -0.32, -3.20),
                wall(0.32, -3.20, 0.63, -3.20),
                wall(-0.63, -4.90, -0.32, -4.90),
                wall(0.32, -4.90, 0.63, -4.90),
                wall(-0.32, -4.90, -0.32, -5.50),
                wall(0.32, -4.90, 0.32, -5.50),
                wall(-0.63, -5.50, -0.32, -5.50),
                wall(0.32, -5.50, 0.63, -5.50),
            ] + roundedKerb(-1.05, 1.05, -2.60, -0.90, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.05, 1.05, -4.90, -3.20, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.05, 1.05, -7.00, -5.50, far: turn, near: turn, steps: 3),
            obstacles: [
                .turntable(center: SIMD2(0, -1.75), radius: 0.48, speed: 1.8, y: 0),
                .turntable(center: SIMD2(0, -4.05), radius: 0.48, speed: -1.8, y: 0),
                critter(.cuckoo, at: SIMD2(0.75, -1.20), .burrow(period: 2.6)),
                critter(.windupBot, at: SIMD2(-0.70, -4.05),
                        .patrol(axis: acrossLane, amplitude: 0.18), speed: 1.2),
                .bumper(center: SIMD2(-0.55, -6.10), radius: 0.08),
            ],
            bonusStar: SIMD2(-0.85, -2.20),
            cameraZoom: 2.2
        ),
        // 5 — the piston hall, and the one square room on the course: three
        //     rams sliding across a straight gallery on three different beats.
        LevelDefinition(
            course: .clockwork, number: 5, name: String(localized: "Piston Hall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.30),
            floors: [
                floorRect(-0.75, 0.75, -1.20, 0.50),
                floorRect(-1.35, 1.35, -4.40, -1.20),
                floorRect(-0.75, 0.75, -5.80, -4.40),
            ],
            wallLoops: [[
                SIMD2(-0.75, 0.50), SIMD2(0.75, 0.50), SIMD2(0.75, -1.20),
                SIMD2(1.35, -1.20), SIMD2(1.35, -4.40), SIMD2(0.75, -4.40),
                SIMD2(0.75, -5.80), SIMD2(-0.75, -5.80), SIMD2(-0.75, -4.40),
                SIMD2(-1.35, -4.40), SIMD2(-1.35, -1.20), SIMD2(-0.75, -1.20),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.4, height: 0.03, yaw: 0),
                .movingBlock(center: SIMD2(0, -1.80), axis: acrossLane, amplitude: 0.75,
                             speed: 1.2, size: SIMD2(0.55, 0.20), baseY: 0),
                .movingBlock(center: SIMD2(0, -2.80), axis: acrossLane, amplitude: 0.75,
                             speed: 1.6, size: SIMD2(0.55, 0.20), baseY: 0),
                .movingBlock(center: SIMD2(0, -3.80), axis: acrossLane, amplitude: 0.75,
                             speed: 0.9, size: SIMD2(0.55, 0.20), baseY: 0),
                critter(.windupBot, at: SIMD2(0, -5.00),
                        .patrol(axis: acrossLane, amplitude: 0.32), speed: 1.2),
                critter(.cuckoo, at: SIMD2(0, -5.60), .burrow(period: 2.4)),
            ],
            bonusStar: SIMD2(1.15, -2.30),
            cameraZoom: 2.05
        ),
        // 6 — the cuckoo. A wheel at the bottom of the works and a second one a
        //     hand higher, up the ramp out of the first: the bird lives on the
        //     upper floor and the cup is behind it.
        LevelDefinition(
            course: .clockwork, number: 6, name: String(localized: "Cuckoo Clock"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.05), holeY: 0.15,
            floors: [
                floorRect(-0.35, 0.35, -1.10, 0.50),
            ] + roundedFloor(-1.20, 1.20, -3.30, -1.10, far: turn, near: turn, steps: 3)
              + [floorRect(-0.30, 0.30, -3.90, -3.30)]
              + roundedFloor(-1.15, 1.15, -5.80, -4.50, far: turn, steps: 3, y: 0.15),
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.10),
                wall(0.35, 0.50, 0.35, -1.10),
                wall(-0.78, -1.10, -0.35, -1.10),
                wall(0.35, -1.10, 0.78, -1.10),
                wall(-0.78, -3.30, -0.30, -3.30),
                wall(0.30, -3.30, 0.78, -3.30),
                wall(-0.30, -3.30, -0.30, -3.90, height: 0.28),
                wall(0.30, -3.30, 0.30, -3.90, height: 0.28),
                wall(-1.15, -4.50, -0.25, -4.50, height: 0.28),
                wall(0.25, -4.50, 1.15, -4.50, height: 0.28),
            ] + roundedKerb(-1.20, 1.20, -3.30, -1.10, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.15, 1.15, -5.80, -4.50, far: turn, steps: 3,
                            baseY: 0, height: 0.28),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.7, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -2.20), radius: 0.52, speed: -1.7, y: 0),
                .ramp(center: SIMD2(0, -4.20), width: 0.5, length: 0.6,
                      rise: 0.15, yaw: 0),
                critter(.cuckoo, at: SIMD2(0, -4.85), .burrow(period: 2.2), baseY: 0.15),
                critter(.windupBot, at: SIMD2(-0.75, -5.45),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.2, baseY: 0.15),
            ],
            bonusStar: SIMD2(1.00, -2.55),
            cameraZoom: 2.1
        ),
        // 7 — the barrel. The shaft out of the first wheel is blind: the only
        //     way on is the cannon in the wall of it, and which way the cannon
        //     is pointing has nothing to do with which way the ball rolled in.
        LevelDefinition(
            course: .clockwork, number: 7, name: String(localized: "Double Cannon"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(1.30, -4.60),
            floors: [
                floorRect(-0.35, 0.35, -1.20, 0.50),
            ] + roundedFloor(-1.20, 1.20, -3.20, -1.20, far: turn, near: turn, steps: 3)
              + [floorRect(-0.78, 0.78, -3.55, -3.20)]
              + roundedFloor(0.10, 2.30, -5.60, -3.55, far: turn, steps: 3),
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.20),
                wall(0.35, 0.50, 0.35, -1.20),
                wall(-0.78, -1.20, -0.35, -1.20),
                wall(0.35, -1.20, 0.78, -1.20),
                wall(-0.78, -3.20, -0.78, -3.55),
                wall(0.78, -3.20, 0.78, -3.55),
                wall(-0.78, -3.55, 0.10, -3.55),
                wall(0.78, -3.55, 2.30, -3.55),
            ] + roundedKerb(-1.20, 1.20, -3.20, -1.20, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(0.10, 2.30, -5.60, -3.55, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.7, height: 0.03, yaw: 0),
                .cannon(center: SIMD2(-0.62, -2.20), direction: SIMD2(1, -0.55),
                        speed: 3.4, y: 0),
                .turntable(center: SIMD2(0.55, -2.20), radius: 0.42, speed: 2.0, y: 0),
                critter(.cuckoo, at: SIMD2(0.62, -4.10), .burrow(period: 2.4)),
                critter(.windupBot, at: SIMD2(1.30, -5.10),
                        .patrol(axis: acrossLane, amplitude: 0.42), speed: 1.2),
            ],
            bonusStar: SIMD2(-0.95, -2.90),
            cameraZoom: 2.15
        ),
        // 8 — the optical illusion (Filzgolf 5). Four gates at even spacing,
        //     the first of them wider than the three behind it, so the line
        //     that goes through the first one comfortably does not go through
        //     the fourth at all.
        LevelDefinition(
            course: .clockwork, number: 8, name: String(localized: "Optical Illusion"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.55),
            floors: [
                floorRect(-1.05, 1.05, -4.60, 0.50),
            ] + roundedFloor(-1.35, 1.35, -6.30, -4.60, far: turn, steps: 3),
            extraWalls: [
                wall(-1.05, 0.50, 1.05, 0.50),
                wall(-1.05, 0.50, -1.05, -4.60),
                wall(1.05, 0.50, 1.05, -4.60),
                wall(-1.35, -4.60, -1.05, -4.60),
                wall(1.05, -4.60, 1.35, -4.60),
                // Four faces, evenly spaced; the mouth in the first is a third
                // wider than the rest and every one is a shade left of the last.
                wall(-1.05, -1.10, -0.24, -1.10), wall(0.24, -1.10, 1.05, -1.10),
                wall(-1.05, -2.10, -0.32, -2.10), wall(0.10, -2.10, 1.05, -2.10),
                wall(-1.05, -3.10, -0.40, -3.10), wall(-0.02, -3.10, 1.05, -3.10),
                wall(-1.05, -4.10, -0.48, -4.10), wall(-0.14, -4.10, 1.05, -4.10),
            ] + roundedKerb(-1.35, 1.35, -6.30, -4.60, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 2.0, height: 0.028, yaw: 0),
                critter(.cuckoo, at: SIMD2(0.70, -1.60), .burrow(period: 2.6)),
                critter(.windupBot, at: SIMD2(0, -5.95),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
                .bumper(center: SIMD2(-0.85, -5.05), radius: 0.08),
            ],
            bonusStar: SIMD2(0.85, -3.60),
            cameraZoom: 2.15
        ),
        // 9 — the ratchet. Four chambers stepping sideways, each one entered
        //     through the corner of the last: there is no straight line through
        //     any two of them.
        LevelDefinition(
            course: .clockwork, number: 9, name: String(localized: "Ratchet"), par: 5,
            tee: SIMD2(-0.25, 0), hole: SIMD2(1.85, -5.75),
            floors: [
                floorRect(-0.85, 0.35, -1.60, 0.50),
                floorRect(-0.85, 1.05, -2.40, -1.60),
                floorRect(-0.15, 1.05, -3.90, -2.40),
                floorRect(-0.15, 1.75, -4.70, -3.90),
                floorRect(0.55, 1.75, -5.40, -4.70),
                floorRect(0.55, 2.45, -6.10, -5.40),
            ],
            wallLoops: [[
                SIMD2(-0.85, 0.50), SIMD2(0.35, 0.50), SIMD2(0.35, -1.60),
                SIMD2(1.05, -1.60), SIMD2(1.05, -3.90), SIMD2(1.75, -3.90),
                SIMD2(1.75, -5.40), SIMD2(2.45, -5.40), SIMD2(2.45, -6.10),
                SIMD2(0.55, -6.10), SIMD2(0.55, -4.70), SIMD2(-0.15, -4.70),
                SIMD2(-0.15, -2.40), SIMD2(-0.85, -2.40),
            ]],
            obstacles: [
                .bump(center: SIMD2(-0.25, -0.70), width: 1.1, height: 0.03, yaw: 0),
                .rotor(center: SIMD2(0.45, -3.15), length: 0.9, speed: 1.6, baseY: 0),
                critter(.cuckoo, at: SIMD2(-0.55, -1.95), .burrow(period: 2.4)),
                .bumper(center: SIMD2(0.95, -4.30), radius: 0.08),
                critter(.windupBot, at: SIMD2(1.20, -5.75),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.2),
            ],
            bonusStar: SIMD2(-0.70, -2.25),
            cameraZoom: 2.2
        ),
        // 10 — the mainspring. One wheel with the coil wound inside it: three
        //      walls hung off the kerb, each shorter than the last, and the cup
        //      in the middle where they run out.
        LevelDefinition(
            course: .clockwork, number: 10, name: String(localized: "Mainspring"), par: 5,
            tee: SIMD2(1.15, 0), hole: SIMD2(0.02, -2.25),
            floors: [
                floorRect(0.75, 1.55, -1.00, 0.50),
            ] + roundedFloor(-1.55, 1.55, -4.30, -1.00, far: turn, near: turn, steps: 3),
            extraWalls: [
                wall(0.75, 0.50, 1.55, 0.50),
                wall(0.75, 0.50, 0.75, -1.00),
                wall(1.55, 0.50, 1.55, -1.00),
                wall(-1.13, -1.00, 0.75, -1.00),
                wall(1.55, -1.00, 1.13, -1.00),
                // The coil.
                wall(-1.55, -1.65, 0.55, -1.65),
                wall(0.55, -1.65, 0.55, -3.30),
                wall(0.55, -3.30, -0.80, -3.30),
                wall(-0.80, -3.30, -0.80, -2.55),
            ] + roundedKerb(-1.55, 1.55, -4.30, -1.00, far: turn, near: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(1.15, -0.60), width: 0.7, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(1.20, -3.80), direction: SIMD2(-1, 0),
                          boost: 1.0, y: 0),
                critter(.windupBot, at: SIMD2(-1.15, -2.80),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.2),
                critter(.cuckoo, at: SIMD2(-0.30, -2.35), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(0, -3.90),
            cameraZoom: 2.2
        ),
        // 11 — the great works. Two wheels side by side off one shaft, joined
        //      round the back, with a magnet in the left one and a turntable in
        //      the right: the same putt does something different in each.
        LevelDefinition(
            course: .clockwork, number: 11, name: String(localized: "The Great Works"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.35),
            floors: [
                floorRect(-0.35, 0.35, -1.10, 0.50),
                floorRect(-1.90, 1.90, -1.70, -1.10),
                floorRect(-1.90, -0.55, -3.90, -1.70),
                floorRect(0.55, 1.90, -3.90, -1.70),
                floorRect(-1.90, 1.90, -4.50, -3.90),
            ] + roundedFloor(-1.20, 1.20, -6.00, -4.50, far: turn, steps: 3),
            wallLoops: [rectLoop(-0.55, 0.55, -3.90, -1.70)],
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.10),
                wall(0.35, 0.50, 0.35, -1.10),
                wall(-1.90, -1.10, -0.35, -1.10),
                wall(0.35, -1.10, 1.90, -1.10),
                wall(-1.90, -1.10, -1.90, -4.50),
                wall(1.90, -1.10, 1.90, -4.50),
                wall(-1.90, -4.50, -1.20, -4.50),
                wall(1.20, -4.50, 1.90, -4.50),
            ] + roundedKerb(-1.20, 1.20, -6.00, -4.50, far: turn, steps: 3),
            obstacles: [
                .magnet(center: SIMD2(-1.22, -2.80), radius: 0.62, strength: 2.2, y: 0),
                .turntable(center: SIMD2(1.22, -2.80), radius: 0.55, speed: 2.0, y: 0),
                critter(.cuckoo, at: SIMD2(0, -4.20), .burrow(period: 2.4)),
                critter(.windupBot, at: SIMD2(0, -5.70),
                        .patrol(axis: acrossLane, amplitude: 0.50), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.55, -4.20),
            cameraZoom: 2.2
        ),
        // 12 — the whole train: shaft, wheel, escapement, cannon and a last
        //      wheel a hand above the rest with the cup on it.
        LevelDefinition(
            course: .clockwork, number: 12, name: String(localized: "Clockwork Works"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -7.15), holeY: 0.15,
            floors: [
                floorRect(-0.35, 0.35, -1.10, 0.50),
            ] + roundedFloor(-1.25, 1.25, -3.30, -1.10, far: turn, near: turn, steps: 3)
              + [
                floorRect(-0.30, 0.30, -3.90, -3.30),
                floorRect(-1.50, 1.50, -6.00, -3.90),
              ]
              + roundedFloor(-1.20, 1.20, -7.90, -6.60, far: turn, steps: 3, y: 0.15),
            extraWalls: [
                wall(-0.35, 0.50, 0.35, 0.50),
                wall(-0.35, 0.50, -0.35, -1.10),
                wall(0.35, 0.50, 0.35, -1.10),
                wall(-0.83, -1.10, -0.35, -1.10),
                wall(0.35, -1.10, 0.83, -1.10),
                wall(-0.83, -3.30, -0.30, -3.30),
                wall(0.30, -3.30, 0.83, -3.30),
                wall(-0.30, -3.30, -0.30, -3.90),
                wall(0.30, -3.30, 0.30, -3.90),
                wall(-1.50, -3.90, -0.30, -3.90),
                wall(0.30, -3.90, 1.50, -3.90),
                wall(-1.50, -3.90, -1.50, -6.00),
                wall(1.50, -3.90, 1.50, -6.00),
                wall(-1.50, -6.00, -0.25, -6.00, height: 0.28),
                wall(0.25, -6.00, 1.50, -6.00, height: 0.28),
                wall(-1.20, -6.60, -0.25, -6.60, height: 0.28),
                wall(0.25, -6.60, 1.20, -6.60, height: 0.28),
            ] + roundedKerb(-1.25, 1.25, -3.30, -1.10, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.20, 1.20, -7.90, -6.60, far: turn, steps: 3,
                            baseY: 0, height: 0.28),
            obstacles: [
                .turntable(center: SIMD2(0, -2.20), radius: 0.52, speed: 1.8, y: 0),
                .gate(center: SIMD2(0, -3.60), size: SIMD2(0.60, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0),
                .movingBlock(center: SIMD2(0, -4.30), axis: acrossLane, amplitude: 0.85,
                             speed: 1.4, size: SIMD2(0.50, 0.20), baseY: 0),
                .ramp(center: SIMD2(0, -6.30), width: 0.5, length: 0.6,
                      rise: 0.15, yaw: 0),
                critter(.cuckoo, at: SIMD2(0.80, -7.15), .burrow(period: 2.4), baseY: 0.15),
                critter(.windupBot, at: SIMD2(-0.75, -7.55),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.2, baseY: 0.15),
            ],
            bonusStar: SIMD2(-1.00, -2.60),
            cameraZoom: 2.25
        ),
    ]
}
