//
//  IceLevels.swift
//  Minigolf
//
//  Frozen Fjord — ice that barely slows a ball at all, so every hole here is
//  really about how much speed to give it. Banked bowls, drifting floes over
//  open water, greens that tilt under the ice, and a finale with a fjord to
//  cross and an iced terrace to hold.
//

import Foundation
import simd

enum IceCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one band of ice across an otherwise ordinary lane, so the world's
        //     one big idea arrives on its own before anything is stacked on it.
        LevelDefinition(
            course: .ice, number: 1, name: String(localized: "First Frost"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.4),
            floors: [
                floorRect(-0.7, 0.7, -4.0, 0.5),
                floorRect(-0.7, 0.7, -2.4, -1.5, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.7, 0.7, -4.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.4, height: 0.03, yaw: 0),
                critter(.penguin, at: SIMD2(0, -1.15),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
                .post(center: SIMD2(-0.3, -2.8), radius: 0.04),
                .post(center: SIMD2(0.3, -2.8), radius: 0.04),
                critter(.snowman, at: SIMD2(0, -3.75),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
            ],
            bonusStar: SIMD2(0.5, -3.7),
            cameraZoom: 1.2
        ),
        // 2 — now the ice runs most of the hole and there are posts standing on
        //     it. Nothing here is hard to reach; everything is hard to stop near.
        LevelDefinition(
            course: .ice, number: 2, name: String(localized: "Black Ice"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.9),
            floors: [
                floorRect(-0.8, 0.8, -4.4, 0.5),
                floorRect(-0.8, 0.8, -3.4, -1.2, kind: .ice),
            ],
            wallLoops: [rectLoop(-0.8, 0.8, -4.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 1.6, height: 0.03, yaw: 0),
                critter(.snowman, at: SIMD2(0.3, -1.0),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.7),
                .post(center: SIMD2(-0.35, -1.6), radius: 0.04),
                .post(center: SIMD2(0.35, -2.2), radius: 0.04),
                .post(center: SIMD2(-0.35, -2.8), radius: 0.04),
                .bumper(center: SIMD2(0.5, -3.3), radius: 0.06),
                critter(.penguin, at: SIMD2(-0.4, -4.3),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0),
            ],
            bonusStar: SIMD2(0.6, -4.15),
            cameraZoom: 1.3
        ),
        // 3 — open water with two crossings, and the far bank tilts to the left
        //     under a sheet of ice, so landing on it is only half of the job.
        LevelDefinition(
            course: .ice, number: 3, name: String(localized: "Drifting Floes"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.3, -4.2),
            floors: [
                floorRect(-1.2, 1.2, -1.8, 0.5),
                floorRect(-1.2, -0.5, -3.2, -1.8, kind: .water),
                floorRect(-0.5, -0.1, -3.2, -1.8),
                floorRect(-0.1, 0.55, -3.2, -1.8, kind: .water),
                floorRect(0.55, 1.2, -3.2, -1.8),
                floorRect(-1.2, 1.2, -4.8, -3.2),
                floorRect(-1.2, 1.2, -4.6, -3.4, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.2, 1.2, -4.8, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 2.4, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.2, -1.3), radius: 0.04),
                critter(.snowman, at: SIMD2(0.8, -1.2),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 0.7),
                .post(center: SIMD2(0.95, -2.5), radius: 0.04),
                .slope(rect: zone(-1.2, 1.2, -4.6, -3.4), direction: SIMD2(-1, 0),
                       strength: 0.9, y: 0),
                .movingBlock(center: SIMD2(0, -3.7), axis: acrossLane, amplitude: 0.7,
                             speed: 1.1, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(-0.9, -3.9), radius: 0.06),
                critter(.penguin, at: SIMD2(0.6, -4.4),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.1),
            ],
            bonusStar: SIMD2(1.05, -4.55),
            cameraZoom: 1.55
        ),
        // 4 — a long left-hander with the whole outside of the turn iced over.
        //     The bank is there to be used; on this surface it is the only thing
        //     that will bring the ball round.
        LevelDefinition(
            course: .ice, number: 4, name: String(localized: "Glacier Bank"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-2.0, -3.35),
            floors: [
                floorRect(-0.6, 0.6, -2.8, 0.5),
                floorRect(-2.4, 0.6, -3.9, -2.8),
                floorRect(-2.4, -0.3, -3.9, -2.8, kind: .ice),
            ],
            wallLoops: [[
                SIMD2(0.6, 0.5), SIMD2(0.6, -3.9), SIMD2(-2.4, -3.9),
                SIMD2(-2.4, -2.8), SIMD2(-0.6, -2.8), SIMD2(-0.6, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(-0.05, -3.25), radius: 0.65,
                                from: deg(270), to: deg(360), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -1.0), width: 1.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.25, -1.8), radius: 0.04),
                critter(.snowman, at: SIMD2(0, -2.4),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
                .bumper(center: SIMD2(-0.9, -3.3), radius: 0.06),
                .post(center: SIMD2(-1.2, -3.75), radius: 0.04),
                .movingBlock(center: SIMD2(-1.5, -3.35), axis: alongLane, amplitude: 0.35,
                             speed: 1.0, size: SIMD2(0.25, 0.3), baseY: 0),
                critter(.penguin, at: SIMD2(-2.2, -3.15),
                        .patrol(axis: alongLane, amplitude: 0.22), speed: 1.0),
            ],
            bonusStar: SIMD2(0.3, -3.6),
            cameraZoom: 1.6
        ),
        // 5 — a ring of boards standing in the middle of the hole with a mouth
        //     on either side. Round the outside is safe and slow; through the
        //     bowl is quick, and the bowl is iced.
        LevelDefinition(
            course: .ice, number: 5, name: String(localized: "Snow Bowl"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.5),
            floors: [
                floorRect(-1.5, 1.5, -5.0, 0.5),
                floorRect(-1.1, 1.1, -3.6, -1.8, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.5, 1.5, -5.0, 0.5)],
            extraWalls: arcWall(center: SIMD2(0, -2.7), radius: 1.05,
                                from: deg(20), to: deg(160), segments: 10)
                      + arcWall(center: SIMD2(0, -2.7), radius: 1.05,
                                from: deg(200), to: deg(340), segments: 10),
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.0, height: 0.03, yaw: 0),
                critter(.snowman, at: SIMD2(0, -1.4),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.8),
                .post(center: SIMD2(-1.3, -1.5), radius: 0.04),
                .post(center: SIMD2(1.3, -1.5), radius: 0.04),
                .bumper(center: SIMD2(-1.3, -3.6), radius: 0.06),
                .bumper(center: SIMD2(1.3, -3.6), radius: 0.06),
                .movingBlock(center: SIMD2(0, -4.0), axis: acrossLane, amplitude: 0.6,
                             speed: 1.1, size: SIMD2(0.45, 0.2), baseY: 0),
                critter(.penguin, at: SIMD2(0, -4.9),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 1.1),
            ],
            bonusStar: SIMD2(0, -2.7),
            cameraZoom: 1.7
        ),
        // 6 — one plank over the channel with a hatch halfway along it, then a
        //     far bank that is iced and tilted and has a floe sliding across it.
        LevelDefinition(
            course: .ice, number: 6, name: String(localized: "Icebreaker"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.7, -4.6),
            floors: [
                floorRect(-1.4, 1.4, -1.9, 0.5),
                floorRect(-1.4, -0.25, -3.3, -1.9, kind: .water),
                floorRect(-0.25, 0.25, -3.3, -1.9),
                floorRect(0.25, 1.4, -3.3, -1.9, kind: .water),
                floorRect(-1.4, 1.4, -5.2, -3.3),
                floorRect(-1.4, 1.4, -5.0, -3.5, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.4, 1.4, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 2.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.5, -1.4), radius: 0.04),
                .post(center: SIMD2(0.5, -1.4), radius: 0.04),
                .gate(center: SIMD2(0, -2.6), size: SIMD2(0.5, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                critter(.penguin, at: SIMD2(0, -3.7),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.1),
                .slope(rect: zone(-1.4, 1.4, -5.0, -3.5), direction: SIMD2(1, 0),
                       strength: 0.8, y: 0),
                .movingBlock(center: SIMD2(0, -4.3), axis: acrossLane, amplitude: 0.8,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(-1.15, -4.6), radius: 0.06),
                critter(.snowman, at: SIMD2(-0.6, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
            ],
            bonusStar: SIMD2(-1.2, -4.0),
            cameraZoom: 1.75
        ),
        // 7 — the terrace above the falls is iced and tilted back toward the
        //      ramp, so a ball parked up there without enough on it comes
        //      straight back down the way it came.
        LevelDefinition(
            course: .ice, number: 7, name: String(localized: "Frozen Falls"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.9), holeY: 0.17,
            floors: [
                floorRect(-0.55, 0.55, -1.9, 0.5),
                floorRect(-1.3, 1.3, -3.0, -1.9),
                floorRect(-1.1, 1.1, -5.4, -3.6, y: 0.17),
                floorRect(-1.1, 1.1, -5.2, -3.7, kind: .ice, y: 0.17),
            ],
            extraWalls: [
                wall(-0.55, 0.5, 0.55, 0.5),
                wall(0.55, 0.5, 0.55, -1.9),
                wall(0.55, -1.9, 1.3, -1.9),
                wall(1.3, -1.9, 1.3, -3.0),
                wall(1.3, -3.0, 0.45, -3.0),
                wall(-0.45, -3.0, -1.3, -3.0),
                wall(-1.3, -3.0, -1.3, -1.9),
                wall(-1.3, -1.9, -0.55, -1.9),
                wall(-0.55, -1.9, -0.55, 0.5),
                wall(-1.1, -3.6, -0.45, -3.6, height: 0.32),
                wall(0.45, -3.6, 1.1, -3.6, height: 0.32),
                wall(1.1, -3.6, 1.1, -5.4, height: 0.32),
                wall(1.1, -5.4, -1.1, -5.4, height: 0.32),
                wall(-1.1, -5.4, -1.1, -3.6, height: 0.32),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.1, height: 0.03, yaw: 0),
                .post(center: SIMD2(0.35, -1.4), radius: 0.04),
                .bumper(center: SIMD2(-0.9, -2.4), radius: 0.06),
                .bumper(center: SIMD2(0.9, -2.4), radius: 0.06),
                critter(.snowman, at: SIMD2(0, -2.5),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 0.8),
                .ramp(center: SIMD2(0, -3.3), width: 0.9, length: 0.6, rise: 0.17, yaw: 0),
                .slope(rect: zone(-1.1, 1.1, -5.2, -3.7), direction: SIMD2(0, 1),
                       strength: 0.9, y: 0.17),
                .movingBlock(center: SIMD2(0, -4.2), axis: acrossLane, amplitude: 0.6,
                             speed: 1.2, size: SIMD2(0.45, 0.2), baseY: 0.17),
                critter(.penguin, at: SIMD2(-0.6, -5.2),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.17),
            ],
            bonusStar: SIMD2(1.15, -2.5),
            cameraZoom: 1.8
        ),
        // 8 — a crevasse the length of the hole. The narrow ledge is straight
        //      down the line of play; the wide one is a detour with a hatch on it.
        LevelDefinition(
            course: .ice, number: 8, name: String(localized: "Crevasse"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-1.0, -4.7),
            floors: [
                floorRect(-1.6, 1.6, -1.7, 0.5),
                floorRect(-1.6, -0.95, -3.6, -1.7, kind: .water),
                floorRect(-0.95, -0.5, -3.6, -1.7),
                floorRect(-0.5, 0.9, -3.6, -1.7, kind: .water),
                floorRect(0.9, 1.6, -3.6, -1.7),
                floorRect(-1.6, 1.6, -5.4, -3.6),
                floorRect(-1.6, 1.6, -5.2, -4.4, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.6, 1.6, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.2, height: 0.03, yaw: 0),
                .slope(rect: zone(-1.6, 1.6, -1.6, -0.6), direction: SIMD2(-1, 0),
                       strength: 1.0, y: 0),
                .post(center: SIMD2(-0.7, -2.2), radius: 0.04),
                .gate(center: SIMD2(1.25, -2.6), size: SIMD2(0.7, 0.09), yaw: 0,
                      period: 2.4, phase: 0.4, baseY: 0),
                critter(.penguin, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.1),
                .bumper(center: SIMD2(1.2, -4.2), radius: 0.06),
                .movingBlock(center: SIMD2(-0.5, -4.9), axis: acrossLane, amplitude: 0.6,
                             speed: 1.1, size: SIMD2(0.45, 0.2), baseY: 0),
                critter(.snowman, at: SIMD2(1.2, -5.1),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.7),
            ],
            bonusStar: SIMD2(1.45, -3.3),
            cameraZoom: 1.85
        ),
        // 9 — two banked sheets tilted against each other. Whatever line goes in
        //      comes out the other end pointing somewhere else entirely.
        LevelDefinition(
            course: .ice, number: 9, name: String(localized: "Blizzard Bowl"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.1, -5.1),
            floors: [
                floorRect(-1.7, 1.7, -5.6, 0.5),
                floorRect(-1.7, 0.0, -3.0, -1.4, kind: .ice),
                floorRect(0.0, 1.7, -4.6, -3.0, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.4, height: 0.03, yaw: 0),
                .slope(rect: zone(-1.7, 0.0, -3.0, -1.4), direction: SIMD2(-1, 0),
                       strength: 1.1, y: 0),
                .bumper(center: SIMD2(-1.45, -2.2), radius: 0.06),
                critter(.snowman, at: SIMD2(0, -2.2),
                        .patrol(axis: alongLane, amplitude: 0.4), speed: 0.8),
                .slope(rect: zone(0.0, 1.7, -4.6, -3.0), direction: SIMD2(1, 0),
                       strength: 1.1, y: 0),
                .movingBlock(center: SIMD2(0, -3.6), axis: acrossLane, amplitude: 0.9,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .bumper(center: SIMD2(1.45, -3.8), radius: 0.06),
                .post(center: SIMD2(0.4, -4.6), radius: 0.04),
                critter(.penguin, at: SIMD2(-0.8, -4.8),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                .block(center: SIMD2(-1.2, -5.2), size: SIMD3(0.6, 0.16, 0.4),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(-1.5, -3.9),
            cameraZoom: 1.9
        ),
        // 10 — two summits off one court, each up its own ramp. The cup is on
        //      the left one behind a hatch; the star is on the right one behind
        //      a floe, and there is no route between them up top.
        LevelDefinition(
            course: .ice, number: 10, name: String(localized: "Twin Peaks"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.95, -5.0), holeY: 0.16,
            floors: [
                floorRect(-1.8, 1.8, -3.4, 0.5),
                floorRect(-1.8, 1.8, -3.3, -2.0, kind: .ice),
                floorRect(-1.6, -0.3, -5.6, -4.1, y: 0.16),
                floorRect(0.3, 1.6, -5.6, -4.1, y: 0.16),
            ],
            extraWalls: [
                wall(-1.8, 0.5, 1.8, 0.5),
                wall(1.8, 0.5, 1.8, -3.4),
                wall(1.8, -3.4, 1.35, -3.4),
                wall(0.55, -3.4, -0.55, -3.4),
                wall(-1.35, -3.4, -1.8, -3.4),
                wall(-1.8, -3.4, -1.8, 0.5),
                wall(-1.6, -4.1, -1.35, -4.1, height: 0.3),
                wall(-0.55, -4.1, -0.3, -4.1, height: 0.3),
                wall(-0.3, -4.1, -0.3, -5.6, height: 0.3),
                wall(-0.3, -5.6, -1.6, -5.6, height: 0.3),
                wall(-1.6, -5.6, -1.6, -4.1, height: 0.3),
                wall(0.3, -4.1, 0.55, -4.1, height: 0.3),
                wall(1.35, -4.1, 1.6, -4.1, height: 0.3),
                wall(1.6, -4.1, 1.6, -5.6, height: 0.3),
                wall(1.6, -5.6, 0.3, -5.6, height: 0.3),
                wall(0.3, -5.6, 0.3, -4.1, height: 0.3),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 3.6, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-0.6, -1.6), radius: 0.06),
                .bumper(center: SIMD2(0.6, -1.6), radius: 0.06),
                critter(.snowman, at: SIMD2(0, -2.4),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 0.8),
                .post(center: SIMD2(1.5, -2.5), radius: 0.04),
                .ramp(center: SIMD2(-0.95, -3.75), width: 0.8, length: 0.7,
                      rise: 0.16, yaw: 0),
                .ramp(center: SIMD2(0.95, -3.75), width: 0.8, length: 0.7,
                      rise: 0.16, yaw: 0),
                .gate(center: SIMD2(-0.95, -4.5), size: SIMD2(1.3, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0.16),
                .movingBlock(center: SIMD2(0.95, -4.7), axis: acrossLane, amplitude: 0.4,
                             speed: 1.1, size: SIMD2(0.35, 0.2), baseY: 0.16),
                critter(.penguin, at: SIMD2(-0.95, -5.4),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.16),
            ],
            bonusStar: SIMD2(0.95, -5.2), bonusStarY: 0.16,
            cameraZoom: 1.95
        ),
        // 11 — three sheets of ice, each tilted against the last. Nothing on
        //      this hole holds a line for more than a metre.
        LevelDefinition(
            course: .ice, number: 11, name: String(localized: "Avalanche"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-1.3, -5.5),
            floors: [
                floorRect(-1.8, 1.8, -6.0, 0.5),
                floorRect(-1.8, 1.8, -4.8, -1.4, kind: .ice),
            ],
            wallLoops: [rectLoop(-1.8, 1.8, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.6, height: 0.03, yaw: 0),
                .slope(rect: zone(-1.8, 1.8, -2.6, -1.4), direction: SIMD2(1, 0),
                       strength: 1.2, y: 0),
                .bumper(center: SIMD2(-1.5, -2.0), radius: 0.06),
                .slope(rect: zone(-1.8, 1.8, -4.0, -2.8), direction: SIMD2(-1, 0),
                       strength: 1.3, y: 0),
                critter(.snowman, at: SIMD2(0, -3.2),
                        .patrol(axis: alongLane, amplitude: 0.4), speed: 0.8),
                .bumper(center: SIMD2(1.5, -3.4), radius: 0.06),
                .slope(rect: zone(-1.8, 1.8, -4.8, -4.2), direction: SIMD2(1, 0),
                       strength: 1.1, y: 0),
                .movingBlock(center: SIMD2(0, -4.5), axis: acrossLane, amplitude: 1.0,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                .post(center: SIMD2(-0.6, -5.0), radius: 0.04),
                critter(.penguin, at: SIMD2(0.6, -5.4),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.1),
                .block(center: SIMD2(0.9, -5.7), size: SIMD3(0.7, 0.16, 0.4),
                       yaw: 0, baseY: 0),
            ],
            bonusStar: SIMD2(1.55, -5.7),
            cameraZoom: 2.0
        ),
        // 12 — the fjord. A hatch on the way out, shoulders into the sound, one
        //      floe-crossed plank over the water, and a terrace at the top that
        //      is both iced and tilted.
        LevelDefinition(
            course: .ice, number: 12, name: String(localized: "Frozen Fjord"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.85), holeY: 0.18,
            floors: [
                floorRect(-0.7, 0.7, -1.8, 0.5),
                floorRect(-0.7, 0.7, -1.6, -0.7, kind: .ice),
                floorRect(-2.0, 2.0, -3.1, -1.8),
                floorRect(-2.0, -0.3, -4.0, -3.1, kind: .water),
                floorRect(-0.3, 0.25, -4.0, -3.1),
                floorRect(0.25, 2.0, -4.0, -3.1, kind: .water),
                floorRect(-2.0, 2.0, -4.7, -4.0),
                floorRect(-1.4, 1.4, -6.2, -5.3, y: 0.18),
                floorRect(-1.4, 1.4, -6.1, -5.4, kind: .ice, y: 0.18),
            ],
            extraWalls: [
                wall(-0.7, 0.5, 0.7, 0.5),
                wall(0.7, 0.5, 0.7, -1.8),
                wall(0.7, -1.8, 2.0, -1.8),
                wall(2.0, -1.8, 2.0, -4.7),
                wall(2.0, -4.7, 0.45, -4.7),
                wall(-0.45, -4.7, -2.0, -4.7),
                wall(-2.0, -4.7, -2.0, -1.8),
                wall(-2.0, -1.8, -0.7, -1.8),
                wall(-0.7, -1.8, -0.7, 0.5),
                wall(-1.4, -5.3, -0.45, -5.3, height: 0.34),
                wall(0.45, -5.3, 1.4, -5.3, height: 0.34),
                wall(1.4, -5.3, 1.4, -6.2, height: 0.34),
                wall(1.4, -6.2, -1.4, -6.2, height: 0.34),
                wall(-1.4, -6.2, -1.4, -5.3, height: 0.34),
            ]
            + arcWall(center: SIMD2(-1.4, -2.4), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.4, -2.4), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 1.4, height: 0.035, yaw: 0),
                .gate(center: SIMD2(0, -1.35), size: SIMD2(1.4, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.0, -2.5), radius: 0.06),
                .bumper(center: SIMD2(1.0, -2.5), radius: 0.06),
                critter(.snowman, at: SIMD2(0, -2.7),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 0.9),
                .movingBlock(center: SIMD2(-0.02, -3.55), axis: alongLane, amplitude: 0.35,
                             speed: 1.0, size: SIMD2(0.3, 0.25), baseY: 0),
                critter(.penguin, at: SIMD2(-1.4, -4.35),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.1),
                .bumper(center: SIMD2(1.5, -4.35), radius: 0.06),
                .ramp(center: SIMD2(0, -5.0), width: 0.9, length: 0.6, rise: 0.18, yaw: 0),
                .slope(rect: zone(-1.4, 1.4, -6.1, -5.4), direction: SIMD2(1, 0),
                       strength: 1.0, y: 0.18),
                .block(center: SIMD2(1.15, -5.9), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.18),
                critter(.penguin, at: SIMD2(-0.85, -5.9),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.0, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.75, -4.35),
            cameraZoom: 2.1
        ),
    ]
}
