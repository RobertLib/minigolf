//
//  CosmosLevels.swift
//  Minigolf
//
//  Orbital Station — the last world, and the only one where the ball routinely
//  leaves the felt. Vertical loops that only a driven putt will carry, tractor
//  beams that bend every line, mass drivers, gaps with nothing under them, and a
//  reactor with a core you cannot cross. The holes are the largest in the game
//  and most of them are played in three or four distinct stages.
//

import Foundation
import simd

enum CosmosCourse {

    static let holes: [LevelDefinition] = [
        // 1 — a quiet arrival. One plate, one beam, and a service rover doing
        //     its rounds across the bay.
        LevelDefinition(
            course: .cosmos, number: 1, name: String(localized: "Docking Bay"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.4, -4.9),
            floors: [floorRect(-1.1, 1.1, -5.2, 0.5)],
            wallLoops: [rectLoop(-1.1, 1.1, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.2, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.2), direction: SIMD2(0, -1), boost: 1.0, y: 0),
                .magnet(center: SIMD2(0, -2.4), radius: 0.5, strength: 1.8, y: 0),
                critter(.rover, at: SIMD2(0, -3.4),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 0.9),
                .bumper(center: SIMD2(-0.85, -4.0), radius: 0.06),
                .bumper(center: SIMD2(0.85, -4.0), radius: 0.06),
                critter(.alien, at: SIMD2(0, -4.6),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
                .post(center: SIMD2(-0.6, -5.0), radius: 0.04),
            ],
            bonusStar: SIMD2(-0.9, -5.0),
            cameraZoom: 1.6
        ),
        // 2 — the first loop. The plate hands out exactly enough speed to carry
        //     it; the ways round it either side are open, and half a metre wide.
        LevelDefinition(
            course: .cosmos, number: 2, name: String(localized: "First Loop"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.9),
            floors: [floorRect(-1.2, 1.2, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.2, 1.2, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 2.4, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.1), direction: SIMD2(0, -1), boost: 1.6, y: 0),
                .block(center: SIMD2(-0.55, -2.1), size: SIMD3(0.86, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.55, -2.1), size: SIMD3(0.86, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -2.1), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                critter(.rover, at: SIMD2(0, -3.4),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 0.9),
                .magnet(center: SIMD2(0, -4.2), radius: 0.5, strength: -2.0, y: 0),
                .bumper(center: SIMD2(0.9, -4.6), radius: 0.06),
                critter(.alien, at: SIMD2(-0.7, -4.9),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.0),
            ],
            bonusStar: SIMD2(1.05, -5.15),
            cameraZoom: 1.7
        ),
        // 3 — one beam pulling everything toward the middle of the deck and two
        //     more pushing out of the corners it delivers to.
        LevelDefinition(
            course: .cosmos, number: 3, name: String(localized: "Tractor Beam"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.7, -5.1),
            floors: [floorRect(-1.5, 1.5, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.5, 1.5, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.0, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -1.8), radius: 0.7, strength: 2.4, y: 0),
                .post(center: SIMD2(-0.9, -2.6), radius: 0.04),
                .post(center: SIMD2(0.9, -2.6), radius: 0.04),
                .magnet(center: SIMD2(-0.7, -3.4), radius: 0.55, strength: -2.2, y: 0),
                .magnet(center: SIMD2(0.7, -3.4), radius: 0.55, strength: -2.2, y: 0),
                critter(.alien, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.0),
                .bumper(center: SIMD2(-1.25, -4.7), radius: 0.06),
                .bumper(center: SIMD2(1.25, -4.7), radius: 0.06),
                critter(.rover, at: SIMD2(-0.6, -5.1),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 0.9),
            ],
            bonusStar: SIMD2(-1.3, -1.5),
            cameraZoom: 1.8
        ),
        // 4 — through the loop first, then wait for the hatch, then hold the
        //     deck against a beam that wants the ball in the middle of it.
        LevelDefinition(
            course: .cosmos, number: 4, name: String(localized: "Airlock"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.3, -5.4),
            floors: [floorRect(-1.6, 1.6, -6.0, 0.5)],
            wallLoops: [rectLoop(-1.6, 1.6, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.6), width: 3.2, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0, -1.0), direction: SIMD2(0, -1), boost: 1.5, y: 0),
                .block(center: SIMD2(-0.7, -2.0), size: SIMD3(1.16, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.7, -2.0), size: SIMD3(1.16, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -2.0), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                .gate(center: SIMD2(0, -3.2), size: SIMD2(3.2, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                critter(.rover, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 0.9),
                .magnet(center: SIMD2(0, -4.8), radius: 0.6, strength: 2.0, y: 0),
                .bumper(center: SIMD2(1.1, -5.2), radius: 0.06),
                critter(.alien, at: SIMD2(-0.8, -5.4),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
            ],
            bonusStar: SIMD2(1.35, -3.9),
            cameraZoom: 1.85
        ),
        // 5 — three coils wired to push, staggered down the deck, with a portal
        //     in the corner the third one throws everything into.
        LevelDefinition(
            course: .cosmos, number: 5, name: String(localized: "Repulsor"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.8, -5.5),
            floors: [floorRect(-1.7, 1.7, -6.0, 0.5)],
            wallLoops: [rectLoop(-1.7, 1.7, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(-0.6, -1.6), radius: 0.5, strength: -2.4, y: 0),
                .bumper(center: SIMD2(1.35, -1.8), radius: 0.06),
                .magnet(center: SIMD2(0.6, -2.6), radius: 0.5, strength: -2.4, y: 0),
                .bumper(center: SIMD2(-1.35, -2.8), radius: 0.06),
                .magnet(center: SIMD2(-0.6, -3.6), radius: 0.5, strength: -2.4, y: 0),
                .teleporter(a: SIMD2(-1.35, -4.9), b: SIMD2(1.35, -3.9), radius: 0.1, y: 0),
                critter(.alien, at: SIMD2(0, -4.4),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.0),
                critter(.rover, at: SIMD2(0, -5.4),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.9),
                .post(center: SIMD2(1.0, -5.6), radius: 0.04),
            ],
            bonusStar: SIMD2(1.5, -5.6),
            cameraZoom: 1.9
        ),
        // 6 — the ring drags the ball off its line, then the plate has to put
        //     enough back on it to carry the loop at the far end.
        LevelDefinition(
            course: .cosmos, number: 6, name: String(localized: "Centrifuge"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.5, -5.6),
            floors: [floorRect(-1.75, 1.75, -6.2, 0.5)],
            wallLoops: [rectLoop(-1.75, 1.75, -6.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.5, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -1.8), radius: 0.9, speed: 1.5, y: 0),
                .bumper(center: SIMD2(-1.35, -1.8), radius: 0.06),
                .bumper(center: SIMD2(1.35, -1.8), radius: 0.06),
                .boostPad(center: SIMD2(0, -2.9), direction: SIMD2(0, -1), boost: 1.6, y: 0),
                .block(center: SIMD2(-0.75, -3.7), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.75, -3.7), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -3.7), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                critter(.rover, at: SIMD2(0, -4.8),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 0.9),
                critter(.alien, at: SIMD2(-0.8, -5.6),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
            ],
            bonusStar: SIMD2(1.45, -5.7),
            cameraZoom: 1.95
        ),
        // 7 — the driver fires hard enough to carry the loop on its own, and a
        //     beam past it decides whether that was a good idea.
        LevelDefinition(
            course: .cosmos, number: 7, name: String(localized: "Mass Driver"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.5, -5.8),
            floors: [floorRect(-1.8, 1.8, -6.4, 0.5)],
            wallLoops: [rectLoop(-1.8, 1.8, -6.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.6, height: 0.03, yaw: 0),
                .cannon(center: SIMD2(0, -1.6), direction: SIMD2(0, -1), speed: 3.8, y: 0),
                .block(center: SIMD2(-0.75, -2.8), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.75, -2.8), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -2.8), radius: 0.2, width: 0.17, yaw: 0, y: 0),
                .magnet(center: SIMD2(0, -4.0), radius: 0.7, strength: -2.2, y: 0),
                critter(.rover, at: SIMD2(0, -4.8),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 0.9),
                .bumper(center: SIMD2(-1.45, -5.2), radius: 0.06),
                .bumper(center: SIMD2(1.45, -5.2), radius: 0.06),
                critter(.alien, at: SIMD2(-0.7, -5.8),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
            ],
            bonusStar: SIMD2(1.5, -6.0),
            cameraZoom: 2.0
        ),
        // 8 — frictionless plating between four coils, two pulling and two
        //     pushing. There is nothing here to stop against.
        LevelDefinition(
            course: .cosmos, number: 8, name: String(localized: "Zero-G Deck"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.9),
            floors: [
                floorRect(-1.9, 1.9, -6.4, 0.5),
                floorRect(-1.9, 1.9, -4.6, -1.4, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.9, 1.9, -6.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.8, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(-0.8, -2.2), radius: 0.6, strength: 2.0, y: 0),
                .magnet(center: SIMD2(0.8, -2.2), radius: 0.6, strength: -2.0, y: 0),
                .bumper(center: SIMD2(-1.55, -2.9), radius: 0.06),
                .bumper(center: SIMD2(1.55, -2.9), radius: 0.06),
                .magnet(center: SIMD2(-0.8, -3.6), radius: 0.6, strength: -2.0, y: 0),
                .magnet(center: SIMD2(0.8, -3.6), radius: 0.6, strength: 2.0, y: 0),
                critter(.rover, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 0.9),
                critter(.alien, at: SIMD2(-0.9, -5.8),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
                .movingBlock(center: SIMD2(0.9, -5.8), axis: acrossLane, amplitude: 0.7,
                             speed: 1.2, size: SIMD2(0.45, 0.2), baseY: 0),
            ],
            bonusStar: SIMD2(1.6, -1.0),
            cameraZoom: 2.05
        ),
        // 9 — two gaps with nothing under them, a loop between them, and a plate
        //     to put back the speed the first jump takes off.
        LevelDefinition(
            course: .cosmos, number: 9, name: String(localized: "Asteroid Gap"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(-0.6, -6.3),
            floors: [
                floorRect(-1.8, 1.8, -2.2, 0.5),
                floorRect(-1.8, 1.8, -3.0, -2.2, kind: .water),
                floorRect(-1.8, 1.8, -4.6, -3.0),
                floorRect(-1.8, 1.8, -5.2, -4.6, kind: .water),
                floorRect(-1.8, 1.8, -6.6, -5.2),
            ],
            wallLoops: [rectLoop(-1.8, 1.8, -6.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.6, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -1.2), radius: 0.04),
                .post(center: SIMD2(0.5, -1.2), radius: 0.04),
                .launchPad(center: SIMD2(0, -1.9), direction: SIMD2(0, -1), speed: 3.5,
                           lift: 1.95, y: 0),
                .boostPad(center: SIMD2(0, -3.3), direction: SIMD2(0, -1), boost: 1.5, y: 0),
                .block(center: SIMD2(-0.75, -3.8), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.75, -3.8), size: SIMD3(1.26, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -3.8), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                .launchPad(center: SIMD2(0, -4.4), direction: SIMD2(0, -1), speed: 3.3,
                           lift: 1.75, y: 0),
                critter(.rover, at: SIMD2(0, -5.8),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 0.9),
                .bumper(center: SIMD2(-1.55, -6.2), radius: 0.06),
                critter(.alien, at: SIMD2(0.8, -6.3),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.0),
            ],
            bonusStar: SIMD2(1.6, -4.2),
            cameraZoom: 2.1
        ),
        // 10 — two decks with no way between them but the cross-band at the top
        //      and a portal. The cup is on the far deck behind a loop.
        LevelDefinition(
            course: .cosmos, number: 10, name: String(localized: "Wormhole"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(-1.3, -6.1),
            floors: [
                floorRect(-0.8, 0.8, -3.0, 0.5),
                floorRect(-2.0, 2.0, -3.8, -3.0),
                floorRect(-2.0, -0.6, -6.6, -3.8),
                floorRect(0.6, 2.0, -6.6, -3.8),
            ],
            wallLoops: [[
                SIMD2(0.8, 0.5), SIMD2(0.8, -3.0), SIMD2(2.0, -3.0),
                SIMD2(2.0, -6.6), SIMD2(0.6, -6.6), SIMD2(0.6, -3.8),
                SIMD2(-0.6, -3.8), SIMD2(-0.6, -6.6), SIMD2(-2.0, -6.6),
                SIMD2(-2.0, -3.0), SIMD2(-0.8, -3.0), SIMD2(-0.8, 0.5),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.6, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -1.6), radius: 0.6, strength: 2.0, y: 0),
                .teleporter(a: SIMD2(0, -2.6), b: SIMD2(1.3, -4.4), radius: 0.1, y: 0),
                .post(center: SIMD2(0.9, -4.2), radius: 0.04),
                .boostPad(center: SIMD2(-1.3, -4.4), direction: SIMD2(0, -1),
                          boost: 1.6, y: 0),
                critter(.rover, at: SIMD2(1.3, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.9),
                .block(center: SIMD2(-1.72, -5.0), size: SIMD3(0.56, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(-0.88, -5.0), size: SIMD3(0.56, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(-1.3, -5.0), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                .bumper(center: SIMD2(1.7, -6.2), radius: 0.06),
                critter(.alien, at: SIMD2(-1.3, -6.4),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.0),
            ],
            bonusStar: SIMD2(1.8, -4.2),
            cameraZoom: 2.2
        ),
        // 11 — a ring of decking around a core that cannot be crossed and pulls
        //      the whole way round. Left is a hatch, right is a loop, and the
        //      beam is trying to drop the ball into the middle of both.
        LevelDefinition(
            course: .cosmos, number: 11, name: String(localized: "Reactor Core"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.3),
            floors: [
                floorRect(-0.8, 0.8, -2.0, 0.5),
                floorRect(-2.0, -0.6, -5.6, -2.0),
                floorRect(0.6, 2.0, -5.6, -2.0),
                floorRect(-0.6, 0.6, -2.6, -2.0),
                floorRect(-0.6, 0.6, -5.0, -2.6, kind: .lava),
                floorRect(-0.6, 0.6, -5.6, -5.0),
                floorRect(-2.0, 2.0, -6.8, -5.6),
            ],
            wallLoops: [[
                SIMD2(0.8, 0.5), SIMD2(0.8, -2.0), SIMD2(2.0, -2.0),
                SIMD2(2.0, -6.8), SIMD2(-2.0, -6.8), SIMD2(-2.0, -2.0),
                SIMD2(-0.8, -2.0), SIMD2(-0.8, 0.5),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.6, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -3.8), radius: 0.9, strength: 2.2, y: 0),
                .gate(center: SIMD2(-1.3, -3.8), size: SIMD2(1.4, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .boostPad(center: SIMD2(1.3, -3.0), direction: SIMD2(0, -1),
                          boost: 1.4, y: 0),
                .block(center: SIMD2(0.9, -4.2), size: SIMD3(0.5, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(1.71, -4.2), size: SIMD3(0.5, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(1.305, -4.2), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                critter(.rover, at: SIMD2(-1.3, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 0.9),
                critter(.alien, at: SIMD2(0, -6.0),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.0),
                .bumper(center: SIMD2(-1.7, -6.3), radius: 0.06),
                .bumper(center: SIMD2(1.7, -6.3), radius: 0.06),
            ],
            bonusStar: SIMD2(-1.75, -2.6),
            cameraZoom: 2.25
        ),
        // 12 — the event horizon. A loop off the tee, shoulders into the ring,
        //      a driver across it, a jump over the void, two beams pulling
        //      against each other on the landing deck, and the observation floor
        //      above it all.
        LevelDefinition(
            course: .cosmos, number: 12, name: String(localized: "Event Horizon"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -7.0), holeY: 0.2,
            floors: [
                floorRect(-0.9, 0.9, -2.2, 0.5),
                floorRect(-2.2, 2.2, -3.8, -2.2),
                floorRect(-2.2, 2.2, -4.8, -3.8, kind: .water),
                floorRect(-2.2, 2.2, -6.0, -4.8),
                floorRect(-1.6, 1.6, -7.4, -6.6, y: 0.2),
            ],
            extraWalls: [
                wall(-0.9, 0.5, 0.9, 0.5),
                wall(0.9, 0.5, 0.9, -2.2),
                wall(0.9, -2.2, 2.2, -2.2),
                wall(2.2, -2.2, 2.2, -6.0),
                wall(2.2, -6.0, 0.45, -6.0),
                wall(-0.45, -6.0, -2.2, -6.0),
                wall(-2.2, -6.0, -2.2, -2.2),
                wall(-2.2, -2.2, -0.9, -2.2),
                wall(-0.9, -2.2, -0.9, 0.5),
                wall(-1.6, -6.6, -0.45, -6.6, height: 0.36),
                wall(0.45, -6.6, 1.6, -6.6, height: 0.36),
                wall(1.6, -6.6, 1.6, -7.4, height: 0.36),
                wall(1.6, -7.4, -1.6, -7.4, height: 0.36),
                wall(-1.6, -7.4, -1.6, -6.6, height: 0.36),
            ]
            + arcWall(center: SIMD2(-1.6, -2.8), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.6, -2.8), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .boostPad(center: SIMD2(0, -0.8), direction: SIMD2(0, -1), boost: 1.6, y: 0),
                .block(center: SIMD2(-0.55, -1.5), size: SIMD3(0.7, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .block(center: SIMD2(0.55, -1.5), size: SIMD3(0.7, 0.12, 0.62),
                       yaw: 0, baseY: 0),
                .loop(center: SIMD2(0, -1.5), radius: 0.19, width: 0.17, yaw: 0, y: 0),
                critter(.rover, at: SIMD2(0, -2.7),
                        .patrol(axis: acrossLane, amplitude: 1.0), speed: 0.9),
                .bumper(center: SIMD2(-1.2, -2.9), radius: 0.06),
                .bumper(center: SIMD2(1.2, -2.9), radius: 0.06),
                .cannon(center: SIMD2(-1.8, -3.3), direction: SIMD2(1, 0), speed: 3.4, y: 0),
                .launchPad(center: SIMD2(0, -3.5), direction: SIMD2(0, -1), speed: 3.7,
                           lift: 2.2, y: 0),
                .magnet(center: SIMD2(-1.0, -5.3), radius: 0.7, strength: 2.2, y: 0),
                .magnet(center: SIMD2(1.0, -5.3), radius: 0.7, strength: -2.2, y: 0),
                critter(.alien, at: SIMD2(0, -5.6),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.0),
                .ramp(center: SIMD2(0, -6.3), width: 0.9, length: 0.6, rise: 0.2, yaw: 0),
                .block(center: SIMD2(1.2, -7.0), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.2),
                critter(.rover, at: SIMD2(-0.9, -7.0),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.9, baseY: 0.2),
            ],
            bonusStar: SIMD2(1.9, -5.3),
            cameraZoom: 2.4
        ),
    ]
}
