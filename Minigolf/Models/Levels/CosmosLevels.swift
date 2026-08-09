//
//  CosmosLevels.swift
//  Minigolf
//
//  Orbital Station — a station plan. Every hole is modules and the tubes between
//  them: a hub with arms off it, a ring corridor with the hub in the middle, a
//  spur that dead-ends at an airlock. Nothing here is a lane and nothing is a
//  landscape; the felt is a floor plan drawn by an engineer, and outside it is
//  the void, which the ball is welcome to leave by at any time.
//
//  Two of the standard lanes suit a station and are built as such: the loop
//  (WMF 2 "Salto"), which is simply a transfer tube, and the mid-course target
//  field (Filzgolf 31), where the cup is in the middle of the plan with the
//  floor going on past it in every direction.
//

import Foundation
import simd

enum CosmosCourse {

    /// Modules are turned with three boards to the corner, like everything else
    /// on the station: a pressure vessel has no square corners.
    private static let turn: Float = 0.42

    static let holes: [LevelDefinition] = [
        // 1 — the docking bay. A tube from the airlock into one module, with
        //     the void either side of the tube instead of boards.
        LevelDefinition(
            course: .cosmos, number: 1, name: String(localized: "Docking Bay"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.90),
            floors: [
                floorRect(-0.38, 0.38, -2.30, 0.50),
            ] + roundedFloor(-1.35, 1.35, -4.80, -2.30, far: turn, steps: 3),
            extraWalls: [
                wall(-0.38, 0.50, 0.38, 0.50),
                wall(-0.38, 0.50, -0.38, -2.30),
                wall(0.38, 0.50, 0.38, -2.30),
                wall(-1.35, -2.30, -0.38, -2.30),
                wall(0.38, -2.30, 1.35, -2.30),
            ] + roundedKerb(-1.35, 1.35, -4.80, -2.30, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.55), width: 0.76, height: 0.028, yaw: 0),
                critter(.rover, at: SIMD2(0, -1.60),
                        .patrol(axis: acrossLane, amplitude: 0.12), speed: 1.0),
                .magnet(center: SIMD2(0, -3.10), radius: 0.55, strength: -1.8, y: 0),
                critter(.alien, at: SIMD2(-0.95, -4.15),
                        .patrol(axis: acrossLane, amplitude: 0.26), speed: 1.2),
            ],
            bonusStar: SIMD2(1.05, -3.10),
            cameraZoom: 1.95
        ),
        // 2 — the transfer tube (WMF 2). The module beyond it can only be
        //     reached through the loop, and the loop wants a certain speed:
        //     too slow and the ball rolls back out of the mouth it went in.
        LevelDefinition(
            course: .cosmos, number: 2, name: String(localized: "First Loop"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -5.20),
            floors: [
                floorRect(-0.55, 0.55, -3.00, 0.50),
            ] + roundedFloor(-1.40, 1.40, -6.00, -3.00, far: turn, steps: 3),
            extraWalls: [
                wall(-0.55, 0.50, 0.55, 0.50),
                wall(-0.55, 0.50, -0.55, -3.00),
                wall(0.55, 0.50, 0.55, -3.00),
                wall(-1.40, -3.00, -0.55, -3.00),
                wall(0.55, -3.00, 1.40, -3.00),
            ] + roundedKerb(-1.40, 1.40, -6.00, -3.00, far: turn, steps: 3),
            obstacles: [
                .boostPad(center: SIMD2(0, -0.85), direction: SIMD2(0, -1),
                          boost: 1.3, y: 0),
                .loop(center: SIMD2(0, -1.80), radius: 0.30, width: 0.5, yaw: 0, y: 0),
                .bumper(center: SIMD2(-0.75, -3.70), radius: 0.08),
                critter(.rover, at: SIMD2(0, -4.35),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.1),
                critter(.alien, at: SIMD2(-0.85, -5.20),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.2),
            ],
            bonusStar: SIMD2(1.15, -4.10),
            cameraZoom: 2.1
        ),
        // 3 — the hub. Four arms off one round room, and the tractor beam in
        //     the middle of it pulls everything back toward the centre: which
        //     arm the ball ends up in is only half a decision.
        LevelDefinition(
            course: .cosmos, number: 3, name: String(localized: "Tractor Beam"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.00),
            floors: [
                floorRect(-0.38, 0.38, -1.60, 0.50),
            ] + roundedFloor(-1.20, 1.20, -5.70, -1.60, far: turn, near: turn, steps: 3)
              + [
                floorRect(-2.30, -1.20, -3.40, -2.70),
                floorRect(1.20, 2.30, -3.40, -2.70),
                floorRect(-0.38, 0.38, -6.30, -5.70),
              ],
            extraWalls: [
                wall(-0.38, 0.50, 0.38, 0.50),
                wall(-0.38, 0.50, -0.38, -1.60),
                wall(0.38, 0.50, 0.38, -1.60),
                wall(-0.78, -1.60, -0.38, -1.60),
                wall(0.38, -1.60, 0.78, -1.60),
                wall(-2.30, -2.70, -1.20, -2.70),
                wall(-2.30, -2.70, -2.30, -3.40),
                wall(-2.30, -3.40, -1.20, -3.40),
                wall(1.20, -2.70, 2.30, -2.70),
                wall(2.30, -2.70, 2.30, -3.40),
                wall(1.20, -3.40, 2.30, -3.40),
                wall(-0.78, -5.70, -0.38, -5.70),
                wall(0.38, -5.70, 0.78, -5.70),
                wall(-0.38, -5.70, -0.38, -6.30),
                wall(0.38, -5.70, 0.38, -6.30),
                wall(-0.38, -6.30, 0.38, -6.30),
            ] + roundedKerb(-1.20, 1.20, -5.70, -1.60, far: turn, near: turn,
                            steps: 3, openFar: true)
                  .filter { !(abs($0.from.x - 1.20) < 0.001 && abs($0.to.x - 1.20) < 0.001)
                            && !(abs($0.from.x + 1.20) < 0.001 && abs($0.to.x + 1.20) < 0.001) }
              + [
                wall(-1.20, -1.78, -1.20, -2.70), wall(-1.20, -3.40, -1.20, -5.40),
                wall(1.20, -1.78, 1.20, -2.70), wall(1.20, -3.40, 1.20, -5.40),
              ],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.76, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -3.05), radius: 0.85, strength: 2.4, y: 0),
                critter(.rover, at: SIMD2(1.85, -3.05),
                        .patrol(axis: alongLane, amplitude: 0.18), speed: 1.1),
                critter(.alien, at: SIMD2(0, -4.60),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.85, -3.05),
            cameraZoom: 2.2
        ),
        // 4 — the airlock. Two modules with a pressure door between them that
        //     is only open half the time, and a spur off the first one that
        //     goes nowhere at all except to the star.
        LevelDefinition(
            course: .cosmos, number: 4, name: String(localized: "Airlock"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.40),
            floors: [
                floorRect(-0.38, 0.38, -1.20, 0.50),
            ] + roundedFloor(-1.15, 1.15, -3.20, -1.20, far: turn, near: turn, steps: 3)
              + [
                floorRect(1.15, 2.05, -2.55, -1.85),
                floorRect(-0.38, 0.38, -3.80, -3.20),
              ]
              + roundedFloor(-1.30, 1.30, -6.20, -3.80, far: turn, steps: 3),
            extraWalls: [
                wall(-0.38, 0.50, 0.38, 0.50),
                wall(-0.38, 0.50, -0.38, -1.20),
                wall(0.38, 0.50, 0.38, -1.20),
                wall(-0.73, -1.20, -0.38, -1.20),
                wall(0.38, -1.20, 0.73, -1.20),
                wall(1.15, -1.85, 2.05, -1.85),
                wall(2.05, -1.85, 2.05, -2.55),
                wall(1.15, -2.55, 2.05, -2.55),
                wall(-0.73, -3.20, -0.38, -3.20),
                wall(0.38, -3.20, 0.73, -3.20),
                wall(-0.38, -3.20, -0.38, -3.80),
                wall(0.38, -3.20, 0.38, -3.80),
                wall(-1.30, -3.80, -0.38, -3.80),
                wall(0.38, -3.80, 1.30, -3.80),
            ] + roundedKerb(-1.15, 1.15, -3.20, -1.20, far: turn, near: turn,
                            steps: 3, openFar: true)
                  .filter { !(abs($0.from.x - 1.15) < 0.001 && abs($0.to.x - 1.15) < 0.001) }
              + [wall(1.15, -1.73, 1.15, -1.85), wall(1.15, -2.55, 1.15, -2.67)]
              + roundedKerb(-1.30, 1.30, -6.20, -3.80, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.76, height: 0.03, yaw: 0),
                .turntable(center: SIMD2(0, -2.20), radius: 0.50, speed: 1.6, y: 0),
                .gate(center: SIMD2(0, -3.50), size: SIMD2(0.60, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0),
                critter(.rover, at: SIMD2(0, -4.60),
                        .patrol(axis: acrossLane, amplitude: 0.50), speed: 1.1),
                critter(.alien, at: SIMD2(-0.85, -5.40),
                        .patrol(axis: acrossLane, amplitude: 0.28), speed: 1.2),
            ],
            bonusStar: SIMD2(1.85, -2.20),
            cameraZoom: 2.2
        ),
        // 5 — the repulsor. One long module with a field in the middle of it
        //     that pushes everything away: the felt is open, and the middle of
        //     it is the one place the ball cannot be made to stay.
        LevelDefinition(
            course: .cosmos, number: 5, name: String(localized: "Repulsor"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.95),
            floors: [
                floorRect(-0.40, 0.40, -1.10, 0.50),
            ] + roundedFloor(-1.60, 1.60, -5.60, -1.10, far: turn, steps: 3),
            extraWalls: [
                wall(-0.40, 0.50, 0.40, 0.50),
                wall(-0.40, 0.50, -0.40, -1.10),
                wall(0.40, 0.50, 0.40, -1.10),
                wall(-1.60, -1.10, -0.40, -1.10),
                wall(0.40, -1.10, 1.60, -1.10),
            ] + roundedKerb(-1.60, 1.60, -5.60, -1.10, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.8, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -2.60), radius: 0.95, strength: -2.6, y: 0),
                .magnet(center: SIMD2(-1.05, -4.00), radius: 0.55, strength: 2.0, y: 0),
                .bumper(center: SIMD2(1.05, -3.30), radius: 0.08),
                critter(.rover, at: SIMD2(0.85, -4.55),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.1),
                critter(.alien, at: SIMD2(0, -5.30),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.35, -2.20),
            cameraZoom: 2.15
        ),
        // 6 — the centrifuge. A ring corridor with the drum in the middle of
        //     it: whichever way round you set off, the drum's rim is turning
        //     against you for half the lap.
        LevelDefinition(
            course: .cosmos, number: 6, name: String(localized: "Centrifuge"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.60),
            floors: [
                floorRect(-1.70, 1.70, -1.20, 0.50),
                floorRect(-1.70, -0.75, -3.70, -1.20),
                floorRect(0.75, 1.70, -3.70, -1.20),
                floorRect(-1.70, 1.70, -5.10, -3.70),
            ],
            wallLoops: [
                rectLoop(-1.70, 1.70, -5.10, 0.50),
                rectLoop(-0.75, 0.75, -3.70, -1.20),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 3.3, height: 0.028, yaw: 0),
                .turntable(center: SIMD2(-1.22, -2.45), radius: 0.42, speed: 2.0, y: 0),
                .turntable(center: SIMD2(1.22, -2.45), radius: 0.42, speed: -2.0, y: 0),
                critter(.rover, at: SIMD2(0, -4.10),
                        .patrol(axis: acrossLane, amplitude: 0.75), speed: 1.1),
                critter(.alien, at: SIMD2(0, -4.90),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.2),
            ],
            bonusStar: SIMD2(1.45, -4.55),
            cameraZoom: 2.2
        ),
        // 7 — the mass driver. A long spine with a barrel set into the wall of
        //     it: whichever way the ball rolls in, it comes out pointing at the
        //     module the cup is in.
        LevelDefinition(
            course: .cosmos, number: 7, name: String(localized: "Mass Driver"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(1.55, -5.15),
            floors: [
                floorRect(-0.45, 0.45, -2.40, 0.50),
                floorRect(-1.30, 0.45, -3.30, -2.40),
                floorRect(0.45, 2.40, -3.30, -2.40),
            ] + roundedFloor(0.60, 2.40, -5.90, -3.30, far: turn, steps: 3),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -2.40),
                wall(0.45, 0.50, 0.45, -2.40),
                wall(-1.30, -2.40, -0.45, -2.40),
                wall(0.45, -2.40, 2.40, -2.40),
                wall(-1.30, -2.40, -1.30, -3.30),
                wall(-1.30, -3.30, 0.60, -3.30),
                wall(2.40, -2.40, 2.40, -3.30),
            ] + roundedKerb(0.60, 2.40, -5.90, -3.30, far: turn, steps: 3),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                .cannon(center: SIMD2(-0.85, -2.85), direction: SIMD2(0.6, -1),
                        speed: 3.6, y: 0),
                .bumper(center: SIMD2(1.55, -2.85), radius: 0.08),
                critter(.rover, at: SIMD2(1.55, -4.30),
                        .patrol(axis: acrossLane, amplitude: 0.45), speed: 1.1),
                critter(.alien, at: SIMD2(1.55, -5.55),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.05, -2.85),
            cameraZoom: 2.25
        ),
        // 8 — zero G. Belts run in both directions down the same module and
        //     nothing on it is still: the only line to the cup is one that
        //     crosses both of them at the right angle.
        LevelDefinition(
            course: .cosmos, number: 8, name: String(localized: "Zero-G Deck"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.85, -5.35),
            floors: [
                floorRect(-0.45, 0.45, -1.20, 0.50),
            ] + roundedFloor(-1.70, 1.70, -5.90, -1.20, far: turn, steps: 3),
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -1.20),
                wall(0.45, 0.50, 0.45, -1.20),
                wall(-1.70, -1.20, -0.45, -1.20),
                wall(0.45, -1.20, 1.70, -1.20),
            ] + roundedKerb(-1.70, 1.70, -5.90, -1.20, far: turn, steps: 3),
            obstacles: [
                .conveyor(rect: zone(-1.65, 1.65, -2.55, -1.75), direction: SIMD2(1, 0),
                          strength: 2.6, y: 0),
                .conveyor(rect: zone(-1.65, 1.65, -3.95, -3.15), direction: SIMD2(-1, 0),
                          strength: 2.8, y: 0),
                .bumper(center: SIMD2(0, -2.85), radius: 0.08),
                .bumper(center: SIMD2(1.20, -4.50), radius: 0.08),
                critter(.rover, at: SIMD2(0, -4.55),
                        .patrol(axis: acrossLane, amplitude: 0.60), speed: 1.1),
                critter(.alien, at: SIMD2(0.85, -5.35),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.45, -3.55),
            cameraZoom: 2.25
        ),
        // 9 — the asteroid gap. The station ends, there is a hundred metres of
        //      nothing, and the next module is on the far side of it: one
        //      kicker, one landing, and a bay of rocks to get through after.
        LevelDefinition(
            course: .cosmos, number: 9, name: String(localized: "Asteroid Gap"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -6.05),
            floors: [
                floorRect(-0.95, 0.95, -1.90, 0.50),
                floorRect(-0.95, 0.95, -3.10, -1.90, kind: .water),
                floorRect(-0.95, 0.95, -4.10, -3.10),
                floorRect(-1.70, 1.70, -6.70, -4.10),
                floorRect(-1.70, -0.95, -4.10, -3.10, kind: .water),
                floorRect(0.95, 1.70, -4.10, -3.10, kind: .water),
                floorRect(-1.70, 1.70, -3.10, -1.90, kind: .water),
            ],
            extraWalls: [
                wall(-0.95, 0.50, 0.95, 0.50),
                wall(-0.95, 0.50, -0.95, -1.90),
                wall(0.95, 0.50, 0.95, -1.90),
                wall(-1.70, -4.10, -1.70, -6.70),
                wall(1.70, -4.10, 1.70, -6.70),
                wall(-1.70, -6.70, 1.70, -6.70),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 1.8, height: 0.03, yaw: 0),
                .launchPad(center: SIMD2(0, -1.72), direction: SIMD2(0, -1),
                           speed: 2.9, lift: 3.0, y: 0),
                .bumper(center: SIMD2(-0.75, -4.75), radius: 0.09),
                .bumper(center: SIMD2(0.75, -5.35), radius: 0.09),
                .bumper(center: SIMD2(-0.55, -5.95), radius: 0.09),
                critter(.rover, at: SIMD2(1.30, -4.60),
                        .patrol(axis: alongLane, amplitude: 0.26), speed: 1.1),
                critter(.alien, at: SIMD2(-1.20, -6.30),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
            ],
            bonusStar: SIMD2(1.45, -6.35),
            cameraZoom: 2.3
        ),
        // 10 — the wormhole. Three modules with no tube anywhere between them:
        //      the only ways across are two pairs of rings, and the second pair
        //      lands the ball further back than the first left it.
        LevelDefinition(
            course: .cosmos, number: 10, name: String(localized: "Wormhole"), par: 6,
            tee: SIMD2(-1.55, 0), hole: SIMD2(1.55, -4.55),
            floors: roundedFloor(-2.30, -0.80, -3.10, 0.50, far: turn, steps: 3)
                + roundedFloor(-0.55, 0.55, -5.40, -1.20, far: turn, near: turn, steps: 3)
                + roundedFloor(0.80, 2.30, -6.10, -2.50, far: turn, near: turn, steps: 3),
            wallLoops: [
                roundedLoop(-2.30, -0.80, -3.10, 0.50, far: turn, steps: 3),
                roundedLoop(-0.55, 0.55, -5.40, -1.20, far: turn, near: turn, steps: 3),
                roundedLoop(0.80, 2.30, -6.10, -2.50, far: turn, near: turn, steps: 3),
            ],
            obstacles: [
                .bump(center: SIMD2(-1.55, -0.70), width: 1.4, height: 0.03, yaw: 0),
                .teleporter(a: SIMD2(-1.55, -2.40), b: SIMD2(0, -1.75),
                            radius: 0.13, y: 0),
                .teleporter(a: SIMD2(0, -4.75), b: SIMD2(1.55, -3.15),
                            radius: 0.13, y: 0),
                critter(.rover, at: SIMD2(0, -3.25),
                        .patrol(axis: acrossLane, amplitude: 0.16), speed: 1.1),
                critter(.alien, at: SIMD2(1.55, -5.55),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2),
            ],
            bonusStar: SIMD2(-1.55, -2.85),
            cameraZoom: 2.3
        ),
        // 11 — the reactor. The cup is in the middle of the plan rather than at
        //      the end of it (Filzgolf 31), with the floor going on past it in
        //      every direction and a beam over it that has to be timed.
        LevelDefinition(
            course: .cosmos, number: 11, name: String(localized: "Reactor Core"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.25),
            floors: [
                floorRect(-0.45, 0.45, -4.00, 0.50),
                floorRect(-2.00, 2.00, -5.30, -4.00),
                floorRect(-0.90, 0.90, -7.20, -5.30),
                floorRect(-2.00, 2.00, -8.50, -7.20),
                floorRect(-2.00, -0.90, -7.20, -5.30, kind: .water),
                floorRect(0.90, 2.00, -7.20, -5.30, kind: .water),
            ],
            extraWalls: [
                wall(-0.45, 0.50, 0.45, 0.50),
                wall(-0.45, 0.50, -0.45, -4.00),
                wall(0.45, 0.50, 0.45, -4.00),
                wall(-2.00, -4.00, -0.45, -4.00),
                wall(0.45, -4.00, 2.00, -4.00),
                wall(-2.00, -4.00, -2.00, -8.50),
                wall(2.00, -4.00, 2.00, -8.50),
                wall(-2.00, -8.50, 2.00, -8.50),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.75), width: 0.9, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(0, -4.75), span: 1.5, arc: deg(52),
                          speed: 1.6, yaw: 0, baseY: 0),
                .magnet(center: SIMD2(0, -6.25), radius: 0.60, strength: 1.8, y: 0),
                .rotor(center: SIMD2(0, -7.65), length: 1.0, speed: 1.8, baseY: 0),
                critter(.rover, at: SIMD2(-1.55, -7.90),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.1),
                critter(.alien, at: SIMD2(1.55, -4.55),
                        .patrol(axis: acrossLane, amplitude: 0.30), speed: 1.2),
            ],
            bonusStar: SIMD2(1.55, -7.90),
            cameraZoom: 2.35
        ),
        // 12 — the whole station: the tube, the hub with the beam in it, the
        //      loop out of the far side, the gap, and the observation deck a
        //      hand above everything else with the cup on it.
        LevelDefinition(
            course: .cosmos, number: 12, name: String(localized: "Event Horizon"), par: 6,
            tee: SIMD2(0, 0), hole: SIMD2(0, -7.10), holeY: 0.15,
            floors: [
                floorRect(-0.42, 0.42, -1.20, 0.50),
            ] + roundedFloor(-1.35, 1.35, -3.40, -1.20, far: turn, near: turn, steps: 3)
              + [
                floorRect(-0.42, 0.42, -4.20, -3.40),
                floorRect(-1.20, 1.20, -5.10, -4.20),
                floorRect(-1.20, -0.25, -5.90, -5.10, kind: .water),
                floorRect(-0.25, 0.25, -5.90, -5.10),
                floorRect(0.25, 1.20, -5.90, -5.10, kind: .water),
                floorRect(-1.20, 1.20, -6.40, -5.90),
              ]
              + roundedFloor(-1.15, 1.15, -7.80, -6.90, far: turn, steps: 3, y: 0.15),
            extraWalls: [
                wall(-0.42, 0.50, 0.42, 0.50),
                wall(-0.42, 0.50, -0.42, -1.20),
                wall(0.42, 0.50, 0.42, -1.20),
                wall(-0.93, -1.20, -0.42, -1.20),
                wall(0.42, -1.20, 0.93, -1.20),
                wall(-0.93, -3.40, -0.42, -3.40),
                wall(0.42, -3.40, 0.93, -3.40),
                wall(-0.42, -3.40, -0.42, -4.20),
                wall(0.42, -3.40, 0.42, -4.20),
                wall(-1.20, -4.20, -0.42, -4.20),
                wall(0.42, -4.20, 1.20, -4.20),
                wall(-1.20, -4.20, -1.20, -6.40),
                wall(1.20, -4.20, 1.20, -6.40),
                wall(-1.20, -6.40, -0.25, -6.40, height: 0.28),
                wall(0.25, -6.40, 1.20, -6.40, height: 0.28),
                wall(-1.15, -6.90, -0.25, -6.90, height: 0.28),
                wall(0.25, -6.90, 1.15, -6.90, height: 0.28),
            ] + roundedKerb(-1.35, 1.35, -3.40, -1.20, far: turn, near: turn,
                            steps: 3, openFar: true)
              + roundedKerb(-1.15, 1.15, -7.80, -6.90, far: turn, steps: 3,
                            baseY: 0, height: 0.28),
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.84, height: 0.03, yaw: 0),
                .magnet(center: SIMD2(0, -2.30), radius: 0.80, strength: 2.2, y: 0),
                .loop(center: SIMD2(0, -4.65), radius: 0.28, width: 0.5, yaw: 0, y: 0),
                .boostPad(center: SIMD2(0, -3.80), direction: SIMD2(0, -1),
                          boost: 1.2, y: 0),
                .ramp(center: SIMD2(0, -6.65), width: 0.5, length: 0.5,
                      rise: 0.15, yaw: 0),
                critter(.rover, at: SIMD2(0.85, -6.15),
                        .patrol(axis: acrossLane, amplitude: 0.24), speed: 1.1),
                critter(.alien, at: SIMD2(0, -7.55),
                        .patrol(axis: acrossLane, amplitude: 0.34), speed: 1.2, baseY: 0.15),
            ],
            bonusStar: SIMD2(1.10, -2.30),
            cameraZoom: 2.4
        ),
    ]
}
