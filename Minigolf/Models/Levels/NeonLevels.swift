//
//  NeonLevels.swift
//  Minigolf
//
//  Neon Nights — the pinball world. Bumpers that give a ball back more than it
//  arrived with, accelerator plates, warp rings, walls of firewalls opening in
//  sequence, and a spiral you have to drive all the way round. Holes here are
//  wide on purpose: there is usually more than one line, and the fast one is
//  never the calm one.
//

import Foundation
import simd

enum NeonCourse {

    static let holes: [LevelDefinition] = [
        // 1 — the plate hands out speed and the bumpers hand it back. One lane,
        //     so the world's two new toys arrive with nowhere to hide.
        LevelDefinition(
            course: .neon, number: 1, name: String(localized: "Power Up"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.9),
            floors: [floorRect(-0.8, 0.8, -4.5, 0.5)],
            wallLoops: [rectLoop(-0.8, 0.8, -4.5, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.6, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.3), direction: SIMD2(0, -1), boost: 1.2, y: 0),
                critter(.drone, at: SIMD2(0, -1.9),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.2),
                .bumper(center: SIMD2(-0.45, -2.2), radius: 0.06),
                .bumper(center: SIMD2(0.45, -2.2), radius: 0.06),
                .bumper(center: SIMD2(0, -2.9), radius: 0.06),
                .post(center: SIMD2(-0.35, -3.5), radius: 0.04),
                .post(center: SIMD2(0.35, -3.5), radius: 0.04),
                critter(.sentry, at: SIMD2(0, -4.35),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
            ],
            bonusStar: SIMD2(0.6, -4.25),
            cameraZoom: 1.3
        ),
        // 2 — a proper pinball table: five bumpers and two curved kickers built
        //     into the side walls, so a putt hit hard here never comes back the
        //     way it went in.
        LevelDefinition(
            course: .neon, number: 2, name: String(localized: "Bumper Alley"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.4),
            floors: [floorRect(-1.3, 1.3, -5.0, 0.5)],
            wallLoops: [rectLoop(-1.3, 1.3, -5.0, 0.5)],
            extraWalls: arcWall(center: SIMD2(-1.95, -2.5), radius: 0.9,
                                from: deg(-40), to: deg(40), segments: 6)
                      + arcWall(center: SIMD2(1.95, -3.4), radius: 0.9,
                                from: deg(140), to: deg(220), segments: 6),
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.6, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-0.5, -1.5), radius: 0.07),
                .bumper(center: SIMD2(0.5, -1.5), radius: 0.07),
                .bumper(center: SIMD2(0, -2.2), radius: 0.07),
                .bumper(center: SIMD2(-0.6, -2.9), radius: 0.07),
                .bumper(center: SIMD2(0.6, -2.9), radius: 0.07),
                critter(.drone, at: SIMD2(0, -3.5),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.3),
                critter(.sentry, at: SIMD2(-0.9, -4.6),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
                .post(center: SIMD2(0.7, -4.6), radius: 0.04),
            ],
            bonusStar: SIMD2(1.15, -1.6),
            cameraZoom: 1.6
        ),
        // 3 — four light walls staggered across the hole, each with its gap on
        //      the opposite side. Four corners, and a bumper waiting in two of
        //      them.
        LevelDefinition(
            course: .neon, number: 3, name: String(localized: "Light Cycle"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.1, -4.9),
            floors: [floorRect(-1.5, 1.5, -5.2, 0.5)],
            wallLoops: [rectLoop(-1.5, 1.5, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.0, height: 0.03, yaw: 0),
                .block(center: SIMD2(-0.35, -1.4), size: SIMD3(2.3, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                .bumper(center: SIMD2(1.15, -1.95), radius: 0.07),
                .block(center: SIMD2(0.35, -2.5), size: SIMD3(2.3, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                critter(.drone, at: SIMD2(1.15, -3.0),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.2),
                .bumper(center: SIMD2(-1.15, -3.05), radius: 0.07),
                .block(center: SIMD2(-0.35, -3.6), size: SIMD3(2.3, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                critter(.sentry, at: SIMD2(-1.15, -4.05),
                        .patrol(axis: alongLane, amplitude: 0.2), speed: 1.0),
                .block(center: SIMD2(0.35, -4.5), size: SIMD3(2.3, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(0.5, -5.0), radius: 0.04),
            ],
            bonusStar: SIMD2(1.3, -4.95),
            cameraZoom: 1.7
        ),
        // 4 — a lattice of light walls with two warp pairs threaded through it,
        //      each one crossing to the far corner. The long way round is always
        //      open; it is just very long.
        LevelDefinition(
            course: .neon, number: 4, name: String(localized: "Warp Grid"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.8),
            floors: [floorRect(-1.6, 1.6, -5.2, 0.5)],
            wallLoops: [rectLoop(-1.6, 1.6, -5.2, 0.5)],
            extraWalls: [
                wall(-0.8, -1.2, -0.8, -2.6),
                wall(0.8, -1.2, 0.8, -2.6),
                wall(-1.6, -2.9, -0.4, -2.9),
                wall(0.4, -2.9, 1.6, -2.9),
                wall(-0.8, -3.4, -0.8, -4.8),
                wall(0.8, -3.4, 0.8, -4.8),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.2, height: 0.03, yaw: 0),
                critter(.sentry, at: SIMD2(0, -1.2),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
                .teleporter(a: SIMD2(-1.2, -1.9), b: SIMD2(1.2, -4.1), radius: 0.1, y: 0),
                .teleporter(a: SIMD2(1.2, -1.9), b: SIMD2(-1.2, -4.1), radius: 0.1, y: 0),
                .bumper(center: SIMD2(0, -2.0), radius: 0.07),
                critter(.drone, at: SIMD2(0, -3.6),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.3),
                .bumper(center: SIMD2(0, -4.3), radius: 0.07),
                .post(center: SIMD2(-0.4, -4.9), radius: 0.04),
                .post(center: SIMD2(0.4, -4.9), radius: 0.04),
            ],
            bonusStar: SIMD2(1.4, -3.2),
            cameraZoom: 1.75
        ),
        // 5 — two bars turning against each other, a firewall the full width of
        //      the deck, and a block still sweeping the green behind it.
        LevelDefinition(
            course: .neon, number: 5, name: String(localized: "Rotor Deck"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.9, -5.15),
            floors: [floorRect(-1.4, 1.4, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.4, 1.4, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.8, height: 0.03, yaw: 0),
                critter(.sentry, at: SIMD2(1.1, -1.2),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.0),
                .rotor(center: SIMD2(-0.6, -1.6), length: 1.0, speed: 1.6, baseY: 0),
                .rotor(center: SIMD2(0.6, -2.6), length: 1.0, speed: -1.8, baseY: 0),
                .gate(center: SIMD2(0, -3.5), size: SIMD2(2.8, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.15, -4.2), radius: 0.07),
                .bumper(center: SIMD2(1.15, -4.2), radius: 0.07),
                critter(.drone, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.3),
                .movingBlock(center: SIMD2(-0.2, -4.9), axis: acrossLane, amplitude: 0.8,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
            ],
            bonusStar: SIMD2(-1.2, -5.15),
            cameraZoom: 1.8
        ),
        // 6 — two funnels, one pointing in and one pointing out, with a bumper
        //      parked between them. The plate at the top decides how violently
        //      the whole arrangement happens.
        LevelDefinition(
            course: .neon, number: 6, name: String(localized: "The Flippers"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.0),
            floors: [floorRect(-1.5, 1.5, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.5, 1.5, -5.4, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -1.0), direction: SIMD2(0, -1), boost: 1.1, y: 0),
                .bump(center: SIMD2(0, -0.6), width: 3.0, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-1.2, -1.6), radius: 0.07),
                .bumper(center: SIMD2(1.2, -1.6), radius: 0.07),
                .block(center: SIMD2(-0.55, -2.4), size: SIMD3(0.7, 0.16, 0.14),
                       yaw: deg(35), baseY: 0),
                .block(center: SIMD2(0.55, -2.4), size: SIMD3(0.7, 0.16, 0.14),
                       yaw: deg(-35), baseY: 0),
                .bumper(center: SIMD2(0, -3.15), radius: 0.07),
                critter(.sentry, at: SIMD2(-1.2, -3.2),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.0),
                .block(center: SIMD2(-0.6, -3.9), size: SIMD3(0.7, 0.16, 0.14),
                       yaw: deg(-35), baseY: 0),
                .block(center: SIMD2(0.6, -3.9), size: SIMD3(0.7, 0.16, 0.14),
                       yaw: deg(35), baseY: 0),
                critter(.drone, at: SIMD2(0, -4.7),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.3),
            ],
            bonusStar: SIMD2(1.35, -4.9),
            cameraZoom: 1.8
        ),
        // 7 — a spiral. The outer ring opens at the bottom and the inner one at
        //      the top, so the ball has to be driven the whole way round before
        //      it may turn inward. The cup is dead centre.
        LevelDefinition(
            course: .neon, number: 7, name: String(localized: "Neon Spiral"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -2.9),
            floors: [floorRect(-1.7, 1.7, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.7, 1.7, -5.4, 0.5)],
            extraWalls: arcWall(center: SIMD2(0, -2.9), radius: 1.35,
                                from: deg(-60), to: deg(240), segments: 14)
                      + arcWall(center: SIMD2(0, -2.9), radius: 0.85,
                                from: deg(120), to: deg(420), segments: 14),
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -1.2), radius: 0.04),
                .post(center: SIMD2(0.5, -1.2), radius: 0.04),
                .bumper(center: SIMD2(-1.5, -1.4), radius: 0.07),
                .bumper(center: SIMD2(1.5, -1.4), radius: 0.07),
                .bumper(center: SIMD2(-1.4, -4.6), radius: 0.07),
                .bumper(center: SIMD2(1.4, -4.6), radius: 0.07),
                critter(.drone, at: SIMD2(0, -4.6), .circle(radius: 0.45), speed: 1.1),
                critter(.sentry, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.0),
            ],
            bonusStar: SIMD2(1.05, -2.9),
            cameraZoom: 1.85
        ),
        // 8 — three belts running alternate ways with nothing between them but
        //      the width of the ball. Aim for where the next one will take you,
        //      not for where the cup is.
        LevelDefinition(
            course: .neon, number: 8, name: String(localized: "Data Stream"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.2, -5.2),
            floors: [floorRect(-1.7, 1.7, -5.6, 0.5)],
            wallLoops: [rectLoop(-1.7, 1.7, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .post(center: SIMD2(1.0, -1.6), radius: 0.04),
                .conveyor(rect: zone(-1.7, 0, -2.4, -1.4), direction: SIMD2(1, 0),
                          strength: 2.6, y: 0),
                .bumper(center: SIMD2(-1.45, -3.0), radius: 0.07),
                critter(.drone, at: SIMD2(0, -2.9),
                        .patrol(axis: alongLane, amplitude: 0.4), speed: 1.2),
                .conveyor(rect: zone(0, 1.7, -3.6, -2.6), direction: SIMD2(-1, 0),
                          strength: 2.6, y: 0),
                .bumper(center: SIMD2(1.45, -4.2), radius: 0.07),
                .conveyor(rect: zone(-1.7, 0, -4.8, -3.8), direction: SIMD2(1, 0),
                          strength: 2.6, y: 0),
                .post(center: SIMD2(-1.0, -5.0), radius: 0.04),
                critter(.sentry, at: SIMD2(0, -5.2),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.0),
            ],
            bonusStar: SIMD2(-1.5, -2.0),
            cameraZoom: 1.9
        ),
        // 9 — a plate, then a kicker, then nothing at all for the best part of a
        //      metre. The jump always throws the same distance, so the gap can
        //      be trusted — the trouble is everything waiting on the far side.
        LevelDefinition(
            course: .neon, number: 9, name: String(localized: "Overdrive"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.5, -5.7),
            floors: [
                floorRect(-1.7, 1.7, -2.4, 0.5),
                floorRect(-1.7, 1.7, -3.3, -2.4, kind: .water),
                floorRect(-1.7, 1.7, -6.0, -3.3),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.2), direction: SIMD2(0, -1), boost: 1.4, y: 0),
                .bumper(center: SIMD2(-1.4, -1.6), radius: 0.07),
                .bumper(center: SIMD2(1.4, -1.6), radius: 0.07),
                .launchPad(center: SIMD2(0, -2.1), direction: SIMD2(0, -1), speed: 3.4,
                           lift: 1.9, y: 0),
                critter(.drone, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.3),
                .bumper(center: SIMD2(-1.5, -4.4), radius: 0.07),
                .bumper(center: SIMD2(1.5, -4.4), radius: 0.07),
                .movingBlock(center: SIMD2(0, -4.8), axis: acrossLane, amplitude: 0.9,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.sentry, at: SIMD2(-1.2, -5.5),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.0),
                .post(center: SIMD2(1.2, -5.5), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.5, -5.7),
            cameraZoom: 1.95
        ),
        // 10 — three firewalls across the whole deck, opening a third of a cycle
        //      apart. Held at the right speed a ball goes through all three on
        //      one putt; anything else is a hole played one wall at a time.
        LevelDefinition(
            course: .neon, number: 10, name: String(localized: "Firewall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.6),
            floors: [floorRect(-1.8, 1.8, -6.0, 0.5)],
            wallLoops: [rectLoop(-1.8, 1.8, -6.0, 0.5)],
            obstacles: [
                .boostPad(center: SIMD2(0, -0.9), direction: SIMD2(0, -1), boost: 1.2, y: 0),
                .bump(center: SIMD2(0, -0.5), width: 3.6, height: 0.03, yaw: 0),
                .gate(center: SIMD2(0, -1.4), size: SIMD2(3.6, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.5, -2.1), radius: 0.07),
                .bumper(center: SIMD2(1.5, -2.1), radius: 0.07),
                .gate(center: SIMD2(0, -2.8), size: SIMD2(3.6, 0.09), yaw: 0,
                      period: 2.4, phase: 0.8, baseY: 0),
                .bumper(center: SIMD2(-1.5, -3.5), radius: 0.07),
                .bumper(center: SIMD2(1.5, -3.5), radius: 0.07),
                .gate(center: SIMD2(0, -4.2), size: SIMD2(3.6, 0.09), yaw: 0,
                      period: 2.4, phase: 1.6, baseY: 0),
                critter(.sentry, at: SIMD2(-1.2, -4.8),
                        .patrol(axis: alongLane, amplitude: 0.3), speed: 1.0),
                critter(.drone, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.3),
            ],
            bonusStar: SIMD2(1.55, -5.6),
            cameraZoom: 2.0
        ),
        // 11 — the grid proper. Four light walls, a warp that skips two of them,
        //      and a drone and a sentry patrolling the corridors the warp does
        //      not help with.
        LevelDefinition(
            course: .neon, number: 11, name: String(localized: "The Grid"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.4, -5.7),
            floors: [floorRect(-1.9, 1.9, -6.2, 0.5)],
            wallLoops: [rectLoop(-1.9, 1.9, -6.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.8, height: 0.03, yaw: 0),
                .block(center: SIMD2(-1.0, -1.5), size: SIMD3(1.8, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                .bumper(center: SIMD2(0.9, -1.95), radius: 0.07),
                .teleporter(a: SIMD2(-1.5, -2.1), b: SIMD2(1.5, -4.2), radius: 0.1, y: 0),
                .block(center: SIMD2(1.0, -2.6), size: SIMD3(1.8, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                critter(.drone, at: SIMD2(1.4, -3.2),
                        .patrol(axis: alongLane, amplitude: 0.35), speed: 1.2),
                .block(center: SIMD2(-1.0, -3.7), size: SIMD3(1.8, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                critter(.sentry, at: SIMD2(-1.4, -4.3),
                        .patrol(axis: alongLane, amplitude: 0.35), speed: 1.0),
                .block(center: SIMD2(1.0, -4.8), size: SIMD3(1.8, 0.16, 0.2),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(0, -5.6), radius: 0.04),
                .post(center: SIMD2(-1.0, -5.9), radius: 0.04),
            ],
            bonusStar: SIMD2(1.7, -5.9),
            cameraZoom: 2.05
        ),
        // 12 — the whole table at once: launch off the plate, through the
        //      bumper chamber and its shoulders, a warp across the deck, one
        //      firewall the full width, a funnel and the last climb.
        LevelDefinition(
            course: .neon, number: 12, name: String(localized: "Neon Nights"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.2), holeY: 0.18,
            floors: [
                floorRect(-0.75, 0.75, -1.8, 0.5),
                floorRect(-2.0, 2.0, -3.4, -1.8),
                floorRect(-2.0, 2.0, -5.0, -3.4),
                floorRect(-1.5, 1.5, -6.6, -5.6, y: 0.18),
            ],
            extraWalls: [
                wall(-0.75, 0.5, 0.75, 0.5),
                wall(0.75, 0.5, 0.75, -1.8),
                wall(0.75, -1.8, 2.0, -1.8),
                wall(2.0, -1.8, 2.0, -5.0),
                wall(2.0, -5.0, 0.45, -5.0),
                wall(-0.45, -5.0, -2.0, -5.0),
                wall(-2.0, -5.0, -2.0, -1.8),
                wall(-2.0, -1.8, -0.75, -1.8),
                wall(-0.75, -1.8, -0.75, 0.5),
                wall(-1.5, -5.6, -0.45, -5.6, height: 0.34),
                wall(0.45, -5.6, 1.5, -5.6, height: 0.34),
                wall(1.5, -5.6, 1.5, -6.6, height: 0.34),
                wall(1.5, -6.6, -1.5, -6.6, height: 0.34),
                wall(-1.5, -6.6, -1.5, -5.6, height: 0.34),
            ]
            + arcWall(center: SIMD2(-1.4, -2.4), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.4, -2.4), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .boostPad(center: SIMD2(0, -0.9), direction: SIMD2(0, -1), boost: 1.3, y: 0),
                .bump(center: SIMD2(0, -1.4), width: 1.5, height: 0.035, yaw: 0),
                critter(.drone, at: SIMD2(0, -2.2),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.3),
                .bumper(center: SIMD2(-0.9, -2.4), radius: 0.07),
                .bumper(center: SIMD2(0.9, -2.4), radius: 0.07),
                .teleporter(a: SIMD2(-1.7, -2.6), b: SIMD2(1.7, -4.4), radius: 0.1, y: 0),
                .bumper(center: SIMD2(0, -3.0), radius: 0.07),
                .gate(center: SIMD2(0, -3.9), size: SIMD2(4.0, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .block(center: SIMD2(-0.6, -4.5), size: SIMD3(0.8, 0.16, 0.14),
                       yaw: deg(-35), baseY: 0),
                .block(center: SIMD2(0.6, -4.5), size: SIMD3(0.8, 0.16, 0.14),
                       yaw: deg(35), baseY: 0),
                .ramp(center: SIMD2(0, -5.3), width: 0.9, length: 0.6, rise: 0.18, yaw: 0),
                .block(center: SIMD2(0.95, -6.2), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.18),
                critter(.sentry, at: SIMD2(-0.9, -6.3),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.18),
            ],
            bonusStar: SIMD2(-1.75, -4.6),
            cameraZoom: 2.15
        ),
    ]
}
