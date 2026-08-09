//
//  ClockworkLevels.swift
//  Minigolf
//
//  Clockwork Works — brass, and everything in it turns. Turntables take a ball
//  over and hand it back somewhere else, cannons swallow it and fire it on a
//  fixed bearing, pistons sweep the halls and the gates all run off the same
//  escapement. The world's holes are long because most of the travelling is
//  done by the machinery.
//

import Foundation
import simd

enum ClockworkCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one turntable, dead centre. A ball rolled across its edge leaves
        //     pointing somewhere else entirely; a ball that stops on it is taken
        //     for a ride and put down on the rim.
        LevelDefinition(
            course: .clockwork, number: 1, name: String(localized: "First Gear"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.4),
            floors: [floorRect(-1.0, 1.0, -5.0, 0.5)],
            wallLoops: [rectLoop(-1.0, 1.0, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.0, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -2.0), radius: 0.55, speed: 1.4, y: 0),
                .post(center: SIMD2(-0.75, -2.9), radius: 0.04),
                .post(center: SIMD2(0.75, -2.9), radius: 0.04),
                critter(.windupBot, at: SIMD2(0, -3.5),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.1),
                .bumper(center: SIMD2(-0.7, -4.2), radius: 0.06),
                critter(.cuckoo, at: SIMD2(0.6, -4.3), .burrow(period: 2.6)),
                .post(center: SIMD2(0, -4.7), radius: 0.04),
            ],
            bonusStar: SIMD2(0.85, -4.85),
            cameraZoom: 1.55
        ),
        // 2 — the barrel takes whatever rolls in and fires it down the second
        //     leg on its own bearing. Getting into it is the shot; what happens
        //     after is the machine's business.
        LevelDefinition(
            course: .clockwork, number: 2, name: String(localized: "The Cannon"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.95, -3.1),
            floors: [
                floorRect(-0.6, 0.6, -2.5, 0.5),
                floorRect(-2.3, 0.6, -3.7, -2.5),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -3.7), SIMD2(-2.3, -3.7),
                SIMD2(-2.3, -2.5), SIMD2(-0.6, -2.5), SIMD2(-0.6, 0.5),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -1.0), width: 1.2, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -1.8), radius: 0.5, speed: 1.5, y: 0),
                .cannon(center: SIMD2(0, -3.1), direction: SIMD2(-1, 0), speed: 3.4, y: 0),
                critter(.windupBot, at: SIMD2(-1.1, -3.1),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                .bumper(center: SIMD2(-1.6, -2.8), radius: 0.06),
                critter(.cuckoo, at: SIMD2(-0.6, -3.5), .burrow(period: 2.4)),
                .post(center: SIMD2(-2.05, -3.5), radius: 0.04),
            ],
            bonusStar: SIMD2(0.35, -3.4),
            cameraZoom: 1.6
        ),
        // 3 — three pistons running at three different rates, then a shutter.
        //     There is a rhythm to it; there is also a way to stop between them
        //     and start again, at the cost of a stroke each time.
        LevelDefinition(
            course: .clockwork, number: 3, name: String(localized: "Escapement"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.8, -5.1),
            floors: [floorRect(-1.3, 1.3, -5.2, 0.5)],
            wallLoops: [rectLoop(-1.3, 1.3, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.6, height: 0.03, yaw: 0),
                .movingBlock(center: SIMD2(-0.6, -1.5), axis: acrossLane, amplitude: 0.6,
                             speed: 1.0, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(-1.05, -2.0), radius: 0.06),
                .movingBlock(center: SIMD2(0.6, -2.5), axis: acrossLane, amplitude: 0.6,
                             speed: -1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(1.05, -3.0), radius: 0.06),
                .movingBlock(center: SIMD2(-0.6, -3.5), axis: acrossLane, amplitude: 0.6,
                             speed: 1.4, size: SIMD2(0.5, 0.2), baseY: 0),
                .gate(center: SIMD2(0, -4.3), size: SIMD2(2.6, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                critter(.windupBot, at: SIMD2(0, -4.8),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.1),
                critter(.cuckoo, at: SIMD2(0.8, -5.1), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.15, -4.9),
            cameraZoom: 1.75
        ),
        // 4 — three plates in a row, each turning against the last, each with a
        //     bumper set where the one before it throws the ball.
        LevelDefinition(
            course: .clockwork, number: 4, name: String(localized: "Turntable Row"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.3),
            floors: [floorRect(-1.5, 1.5, -5.6, 0.5)],
            wallLoops: [rectLoop(-1.5, 1.5, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.0, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(-0.75, -1.6), radius: 0.6, speed: 1.5, y: 0),
                .bumper(center: SIMD2(1.2, -1.6), radius: 0.06),
                .turntable(center: SIMD2(0.75, -2.9), radius: 0.6, speed: -1.7, y: 0),
                .bumper(center: SIMD2(-1.2, -2.9), radius: 0.06),
                .turntable(center: SIMD2(-0.75, -4.2), radius: 0.6, speed: 1.9, y: 0),
                .bumper(center: SIMD2(1.2, -4.2), radius: 0.06),
                critter(.windupBot, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.1),
                critter(.cuckoo, at: SIMD2(1.0, -5.3), .burrow(period: 2.4)),
                .post(center: SIMD2(-1.2, -5.3), radius: 0.04),
            ],
            bonusStar: SIMD2(1.35, -5.35),
            cameraZoom: 1.85
        ),
        // 5 — two belts running opposite ways with a piston sweeping the gap
        //     after each of them. Everything on this hole is on a timetable.
        LevelDefinition(
            course: .clockwork, number: 5, name: String(localized: "Piston Hall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.55),
            floors: [floorRect(-1.6, 1.6, -5.8, 0.5)],
            wallLoops: [rectLoop(-1.6, 1.6, -5.8, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.2, height: 0.03, yaw: 0),
                .conveyor(rect: zone(-1.6, 1.6, -2.2, -1.6), direction: SIMD2(1, 0),
                          strength: 2.8, y: 0),
                .bumper(center: SIMD2(-1.35, -2.6), radius: 0.06),
                .movingBlock(center: SIMD2(0, -2.9), axis: acrossLane, amplitude: 0.9,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .conveyor(rect: zone(-1.6, 1.6, -3.9, -3.3), direction: SIMD2(-1, 0),
                          strength: 2.8, y: 0),
                .bumper(center: SIMD2(1.35, -4.2), radius: 0.06),
                .movingBlock(center: SIMD2(0, -4.6), axis: acrossLane, amplitude: 0.9,
                             speed: -1.3, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.windupBot, at: SIMD2(0, -5.3),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.1),
                critter(.cuckoo, at: SIMD2(-1.0, -5.5), .burrow(period: 2.4)),
                .post(center: SIMD2(1.0, -5.5), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.4, -1.2),
            cameraZoom: 1.9
        ),
        // 6 — three shutters a third of a cycle apart, with a cuckoo popping up
        //     in the gap between each pair. Everything here runs on the same
        //     two-second beat, and learning it is the hole.
        LevelDefinition(
            course: .clockwork, number: 6, name: String(localized: "Cuckoo Clock"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.6, -5.6),
            floors: [floorRect(-1.65, 1.65, -5.8, 0.5)],
            wallLoops: [rectLoop(-1.65, 1.65, -5.8, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.3, height: 0.03, yaw: 0),
                .gate(center: SIMD2(-0.8, -1.5), size: SIMD2(1.7, 0.09), yaw: 0,
                      period: 2.0, phase: 0, baseY: 0),
                critter(.cuckoo, at: SIMD2(0, -2.1), .burrow(period: 2.0)),
                .gate(center: SIMD2(0.8, -2.7), size: SIMD2(1.7, 0.09), yaw: 0,
                      period: 2.0, phase: 0.66, baseY: 0),
                critter(.cuckoo, at: SIMD2(0, -3.3), .burrow(period: 2.0), phase: 1.0),
                .gate(center: SIMD2(-0.8, -3.9), size: SIMD2(1.7, 0.09), yaw: 0,
                      period: 2.0, phase: 1.33, baseY: 0),
                .turntable(center: SIMD2(0, -4.9), radius: 0.65, speed: 1.6, y: 0),
                .bumper(center: SIMD2(-1.4, -4.9), radius: 0.06),
                .bumper(center: SIMD2(1.4, -4.9), radius: 0.06),
                critter(.windupBot, at: SIMD2(-0.5, -5.5),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.1),
            ],
            bonusStar: SIMD2(1.45, -5.6),
            cameraZoom: 1.9
        ),
        // 7 — the hall widens into two wings, each with a belt feeding a barrel
        //     that fires down the far end. Whichever wing takes the ball, the
        //     machinery does the second half of the hole.
        LevelDefinition(
            course: .clockwork, number: 7, name: String(localized: "Double Cannon"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.1),
            floors: [
                floorRect(-0.7, 0.7, -2.2, 0.5),
                floorRect(-2.0, 2.0, -3.4, -2.2),
                floorRect(-2.0, 2.0, -5.4, -3.4),
            ],
            extraWalls: [
                wall(-0.7, 0.5, 0.7, 0.5),
                wall(0.7, 0.5, 0.7, -2.2),
                wall(0.7, -2.2, 2.0, -2.2),
                wall(2.0, -2.2, 2.0, -5.4),
                wall(2.0, -5.4, -2.0, -5.4),
                wall(-2.0, -5.4, -2.0, -2.2),
                wall(-2.0, -2.2, -0.7, -2.2),
                wall(-0.7, -2.2, -0.7, 0.5),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.4, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -1.6), radius: 0.55, speed: 1.6, y: 0),
                .conveyor(rect: zone(-2.0, 0, -3.0, -2.4), direction: SIMD2(-1, 0),
                          strength: 2.6, y: 0),
                .conveyor(rect: zone(0, 2.0, -3.0, -2.4), direction: SIMD2(1, 0),
                          strength: 2.6, y: 0),
                .cannon(center: SIMD2(-1.7, -2.8), direction: SIMD2(0, -1), speed: 3.4, y: 0),
                .cannon(center: SIMD2(1.7, -2.8), direction: SIMD2(0, -1), speed: 3.4, y: 0),
                critter(.windupBot, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.2),
                .bumper(center: SIMD2(-1.2, -4.4), radius: 0.06),
                .bumper(center: SIMD2(1.2, -4.4), radius: 0.06),
                critter(.cuckoo, at: SIMD2(0, -4.9), .burrow(period: 2.4)),
                .post(center: SIMD2(-0.6, -5.1), radius: 0.04),
                .post(center: SIMD2(0.6, -5.1), radius: 0.04),
            ],
            bonusStar: SIMD2(1.75, -5.1),
            cameraZoom: 2.05
        ),
        // 8 — one plate a metre across, with four bumpers set around it. A ball
        //      that dares to cross the middle is thrown at one of them; going
        //      round the outside means playing the whole hole in the margin.
        LevelDefinition(
            course: .clockwork, number: 8, name: String(localized: "The Governor"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.2, -5.75),
            floors: [floorRect(-1.8, 1.8, -6.0, 0.5)],
            wallLoops: [rectLoop(-1.8, 1.8, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.6, height: 0.03, yaw: 0),
                critter(.windupBot, at: SIMD2(0, -1.4),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.2),
                .bumper(center: SIMD2(-1.5, -1.8), radius: 0.06),
                .bumper(center: SIMD2(1.5, -1.8), radius: 0.06),
                .turntable(center: SIMD2(0, -2.8), radius: 1.0, speed: 1.5, y: 0),
                .bumper(center: SIMD2(-1.5, -3.8), radius: 0.06),
                .bumper(center: SIMD2(1.5, -3.8), radius: 0.06),
                .gate(center: SIMD2(0, -4.6), size: SIMD2(3.6, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                critter(.cuckoo, at: SIMD2(-0.8, -5.4), .burrow(period: 2.6)),
                .movingBlock(center: SIMD2(0.6, -5.4), axis: acrossLane, amplitude: 0.7,
                             speed: 1.2, size: SIMD2(0.45, 0.2), baseY: 0),
                .post(center: SIMD2(-1.5, -5.7), radius: 0.04),
            ],
            bonusStar: SIMD2(1.6, -5.75),
            cameraZoom: 2.05
        ),
        // 9 — a ratchet: five legs, each one shorter than the last, with a plate
        //      turning in two of the corners so the turn is never simply a turn.
        LevelDefinition(
            course: .clockwork, number: 9, name: String(localized: "Ratchet"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.6, -5.9),
            floors: [
                floorRect(-0.6, 0.6, -1.6, 0.5),
                floorRect(-2.0, 0.6, -2.8, -1.6),
                floorRect(-2.0, -0.8, -4.2, -2.8),
                floorRect(-2.0, 1.0, -5.4, -4.2),
                floorRect(0.0, 1.0, -6.2, -5.4),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -2.8), SIMD2(-0.8, -2.8),
                SIMD2(-0.8, -4.2), SIMD2(1.0, -4.2), SIMD2(1.0, -6.2),
                SIMD2(0.0, -6.2), SIMD2(0.0, -5.4), SIMD2(-2.0, -5.4),
                SIMD2(-2.0, -1.6), SIMD2(-0.6, -1.6), SIMD2(-0.6, 0.5),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.2, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(-1.4, -2.2), radius: 0.55, speed: 1.6, y: 0),
                .bumper(center: SIMD2(0.2, -2.4), radius: 0.06),
                critter(.windupBot, at: SIMD2(-1.4, -3.5),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                .turntable(center: SIMD2(-1.4, -4.8), radius: 0.55, speed: -1.7, y: 0),
                critter(.cuckoo, at: SIMD2(0.5, -4.5), .burrow(period: 2.4)),
                .gate(center: SIMD2(0.5, -5.0), size: SIMD2(1.0, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .post(center: SIMD2(0.85, -5.6), radius: 0.04),
                .bumper(center: SIMD2(0.25, -5.9), radius: 0.06),
            ],
            bonusStar: SIMD2(-1.8, -4.9),
            cameraZoom: 2.05
        ),
        // 10 — the mainspring: three belts alternating across the hole with a
        //      plate turning in the corner each one delivers to.
        LevelDefinition(
            course: .clockwork, number: 10, name: String(localized: "Mainspring"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.4, -5.9),
            floors: [floorRect(-1.9, 1.9, -6.2, 0.5)],
            wallLoops: [rectLoop(-1.9, 1.9, -6.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 3.8, height: 0.03, yaw: 0),
                .conveyor(rect: zone(-1.9, 1.9, -1.8, -1.2), direction: SIMD2(1, 0),
                          strength: 2.8, y: 0),
                .bumper(center: SIMD2(-1.6, -2.2), radius: 0.06),
                .turntable(center: SIMD2(1.2, -2.6), radius: 0.65, speed: 1.7, y: 0),
                .conveyor(rect: zone(-1.9, 1.9, -3.4, -2.8), direction: SIMD2(-1, 0),
                          strength: 2.8, y: 0),
                .bumper(center: SIMD2(1.6, -3.8), radius: 0.06),
                critter(.windupBot, at: SIMD2(0, -3.9),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.2),
                .turntable(center: SIMD2(-1.2, -4.2), radius: 0.65, speed: -1.7, y: 0),
                .conveyor(rect: zone(-1.9, 1.9, -5.0, -4.4), direction: SIMD2(1, 0),
                          strength: 2.8, y: 0),
                critter(.cuckoo, at: SIMD2(-0.6, -5.6), .burrow(period: 2.4)),
                .movingBlock(center: SIMD2(0.8, -5.6), axis: acrossLane, amplitude: 0.8,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .post(center: SIMD2(1.7, -5.9), radius: 0.04),
            ],
            bonusStar: SIMD2(1.7, -0.7),
            cameraZoom: 2.15
        ),
        // 11 — two plates at the gate, a bar across the middle, a full-width
        //      shutter and a belt that feeds a barrel pointing back across the
        //      hole. The last third is played by whatever comes out of it.
        LevelDefinition(
            course: .clockwork, number: 11, name: String(localized: "The Great Works"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -6.1),
            floors: [floorRect(-2.0, 2.0, -6.4, 0.5)],
            wallLoops: [rectLoop(-2.0, 2.0, -6.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 4.0, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(-1.1, -1.7), radius: 0.6, speed: 1.6, y: 0),
                .turntable(center: SIMD2(1.1, -1.7), radius: 0.6, speed: -1.6, y: 0),
                .rotor(center: SIMD2(0, -2.8), length: 1.4, speed: 1.6, baseY: 0),
                .gate(center: SIMD2(0, -3.7), size: SIMD2(4.0, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .conveyor(rect: zone(-2.0, 2.0, -4.8, -4.2), direction: SIMD2(-1, 0),
                          strength: 2.6, y: 0),
                .cannon(center: SIMD2(-1.6, -4.4), direction: SIMD2(1, 0), speed: 3.2, y: 0),
                critter(.windupBot, at: SIMD2(0, -5.2),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.2),
                .bumper(center: SIMD2(-1.7, -5.6), radius: 0.06),
                .bumper(center: SIMD2(1.7, -5.6), radius: 0.06),
                critter(.cuckoo, at: SIMD2(0.8, -5.9), .burrow(period: 2.4)),
                .movingBlock(center: SIMD2(-0.6, -6.0), axis: acrossLane, amplitude: 0.8,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
            ],
            bonusStar: SIMD2(-1.85, -2.9),
            cameraZoom: 2.2
        ),
        // 12 — the works entire. A plate at the gate, a bar across the rim, a
        //      belt into the barrel that fires the length of the hall, a shutter
        //      the full width, a piston behind it, and a geared terrace with a
        //      plate of its own beside the cup.
        LevelDefinition(
            course: .clockwork, number: 12, name: String(localized: "Clockwork Works"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.7, -6.6), holeY: 0.2,
            floors: [
                floorRect(-0.85, 0.85, -2.0, 0.5),
                floorRect(-2.2, 2.2, -3.6, -2.0),
                floorRect(-2.2, 2.2, -5.4, -3.6),
                floorRect(-1.6, 1.6, -7.0, -6.0, y: 0.2),
            ],
            extraWalls: [
                wall(-0.85, 0.5, 0.85, 0.5),
                wall(0.85, 0.5, 0.85, -2.0),
                wall(0.85, -2.0, 2.2, -2.0),
                wall(2.2, -2.0, 2.2, -5.4),
                wall(2.2, -5.4, 0.45, -5.4),
                wall(-0.45, -5.4, -2.2, -5.4),
                wall(-2.2, -5.4, -2.2, -2.0),
                wall(-2.2, -2.0, -0.85, -2.0),
                wall(-0.85, -2.0, -0.85, 0.5),
                wall(-1.6, -6.0, -0.45, -6.0, height: 0.36),
                wall(0.45, -6.0, 1.6, -6.0, height: 0.36),
                wall(1.6, -6.0, 1.6, -7.0, height: 0.36),
                wall(1.6, -7.0, -1.6, -7.0, height: 0.36),
                wall(-1.6, -7.0, -1.6, -6.0, height: 0.36),
            ]
            + arcWall(center: SIMD2(-1.6, -2.6), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.6, -2.6), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 1.7, height: 0.035, yaw: 0),
                .turntable(center: SIMD2(0, -1.5), radius: 0.6, speed: 1.7, y: 0),
                .rotor(center: SIMD2(0, -2.6), length: 1.4, speed: 1.7, baseY: 0),
                .bumper(center: SIMD2(-1.1, -2.7), radius: 0.06),
                .bumper(center: SIMD2(1.1, -2.7), radius: 0.06),
                .conveyor(rect: zone(-2.2, 2.2, -3.3, -2.9), direction: SIMD2(1, 0),
                          strength: 2.8, y: 0),
                .cannon(center: SIMD2(1.8, -3.1), direction: SIMD2(0, -1), speed: 3.4, y: 0),
                .gate(center: SIMD2(0, -4.1), size: SIMD2(4.4, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .movingBlock(center: SIMD2(0, -4.8), axis: acrossLane, amplitude: 1.2,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.windupBot, at: SIMD2(-1.4, -4.9),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.1),
                .ramp(center: SIMD2(0, -5.7), width: 0.9, length: 0.6, rise: 0.2, yaw: 0),
                .turntable(center: SIMD2(-0.7, -6.5), radius: 0.45, speed: 1.5, y: 0.2),
                .block(center: SIMD2(1.35, -6.4), size: SIMD3(0.35, 0.14, 0.5),
                       yaw: 0, baseY: 0.2),
                critter(.cuckoo, at: SIMD2(0.1, -6.9), .burrow(period: 2.4), baseY: 0.2),
            ],
            bonusStar: SIMD2(1.95, -3.9),
            cameraZoom: 2.3
        ),
    ]
}
