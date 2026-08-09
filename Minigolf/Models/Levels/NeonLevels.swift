//
//  NeonLevels.swift
//  Minigolf
//
//  Neon Nights — a printed circuit. Nothing on this course is curved: every
//  hole is traces of one constant width meeting at right angles, with junctions,
//  islands and dead ends where a board would be. It is the opposite of the
//  garden, where the corners are all banked, and of the desert, where the boards
//  run at an angle — here the ball either takes the corner square or it does not
//  take it.
//
//  Three of the standard lanes fit the idiom straight off and are built as such:
//  the twin gates hard against the boards (Filzgolf 29), the diamond with a
//  finger's width past it either side (WMF 27) and the lying loop (WMF 5), which
//  in a circuit is simply a coil.
//

import Foundation
import simd

enum NeonCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one trace with two square corners in it and a boost pad on the
        //     second, so the hole teaches the two things the world is made of:
        //     no banking, and speed you did not ask for.
        LevelDefinition(
            course: .neon, number: 1, name: String(localized: "Power Up"), par: 3,
            tee: SIMD2(0, 0), hole: SIMD2(0.82, -2.90),
            floors: [
                floorRect(-0.40, 0.40, -1.10, 0.50),
                floorRect(-0.40, 1.20, -1.85, -1.10),
                floorRect(0.45, 1.20, -3.20, -1.85),
            ],
            wallLoops: [[
                SIMD2(-0.40, 0.50), SIMD2(0.40, 0.50), SIMD2(0.40, -1.10),
                SIMD2(1.20, -1.10), SIMD2(1.20, -3.20), SIMD2(0.45, -3.20),
                SIMD2(0.45, -1.85), SIMD2(-0.40, -1.85),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.60), width: 0.8, height: 0.028, yaw: 0),
                .boostPad(center: SIMD2(0.82, -1.48), direction: SIMD2(0, -1),
                          boost: 1.1, y: 0),
                critter(.drone, at: SIMD2(0.82, -2.35),
                        .patrol(axis: acrossLane, amplitude: 0.22), speed: 1.4),
                critter(.sentry, at: SIMD2(-0.05, -1.48), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(-0.22, -1.48),
            cameraZoom: 1.5
        ),
        // 2 — twin gates (Filzgolf 29). The wall across the wide part of the
        //     trace is solid everywhere except hard against each board, so the
        //     only two ways through are the two places a putt never goes.
        LevelDefinition(
            course: .neon, number: 2, name: String(localized: "Twin Gates"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.55),
            floors: [
                floorRect(-0.75, 0.75, -1.20, 0.50),
                floorRect(-1.20, 1.20, -2.90, -1.20),
                floorRect(-0.75, 0.75, -4.00, -2.90),
            ],
            wallLoops: [[
                SIMD2(-0.75, 0.50), SIMD2(0.75, 0.50), SIMD2(0.75, -1.20),
                SIMD2(1.20, -1.20), SIMD2(1.20, -2.90), SIMD2(0.75, -2.90),
                SIMD2(0.75, -4.00), SIMD2(-0.75, -4.00), SIMD2(-0.75, -2.90),
                SIMD2(-1.20, -2.90), SIMD2(-1.20, -1.20), SIMD2(-0.75, -1.20),
            ]],
            extraWalls: [wall(-0.95, -2.05, 0.95, -2.05)],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 1.4, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(0, -1.55), radius: 0.08),
                critter(.drone, at: SIMD2(-1.05, -2.50),
                        .patrol(axis: alongLane, amplitude: 0.24), speed: 1.4),
                critter(.sentry, at: SIMD2(0, -3.20), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(1.05, -2.55),
            cameraZoom: 1.7
        ),
        // 3 — the diamond (WMF 27). It stands corner-on in the middle of the
        //     trace with a finger's width of felt past it either side, so the
        //     hole is one line and there is no second-best version of it.
        LevelDefinition(
            course: .neon, number: 3, name: String(localized: "The Diamond"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.05),
            floors: [
                floorRect(-0.50, 0.50, -1.10, 0.50),
                floorRect(-1.15, 1.15, -4.60, -1.10),
            ],
            wallLoops: [[
                SIMD2(-0.50, 0.50), SIMD2(0.50, 0.50), SIMD2(0.50, -1.10),
                SIMD2(1.15, -1.10), SIMD2(1.15, -4.60), SIMD2(-1.15, -4.60),
                SIMD2(-1.15, -1.10), SIMD2(-0.50, -1.10),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 0.9, height: 0.028, yaw: 0),
                .block(center: SIMD2(0, -2.30), size: SIMD3(1.40, 0.16, 1.40),
                       yaw: deg(45), baseY: 0),
                .bumper(center: SIMD2(-0.72, -1.45), radius: 0.07),
                .bumper(center: SIMD2(0.72, -1.45), radius: 0.07),
                critter(.drone, at: SIMD2(0, -3.55),
                        .patrol(axis: acrossLane, amplitude: 0.62), speed: 1.5),
                critter(.sentry, at: SIMD2(0.85, -4.25), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(-1.07, -2.30),
            cameraZoom: 1.75
        ),
        // 4 — three traces with no join anywhere on the board: the only way off
        //     one and onto the next is a warp, and each warp lands the ball
        //     further up its new trace than it left the old one.
        LevelDefinition(
            course: .neon, number: 4, name: String(localized: "Warp Grid"), par: 4,
            tee: SIMD2(-1.10, 0), hole: SIMD2(1.30, -3.20),
            floors: [
                floorRect(-1.45, -0.75, -3.60, 0.50),
                floorRect(-0.25, 0.45, -3.60, 0.50),
                floorRect(0.95, 1.65, -3.60, 0.50),
            ],
            wallLoops: [
                rectLoop(-1.45, -0.75, -3.60, 0.50),
                rectLoop(-0.25, 0.45, -3.60, 0.50),
                rectLoop(0.95, 1.65, -3.60, 0.50),
            ],
            obstacles: [
                .teleporter(a: SIMD2(-1.10, -2.00), b: SIMD2(0.10, -0.90),
                            radius: 0.13, y: 0),
                .teleporter(a: SIMD2(0.10, -2.90), b: SIMD2(1.30, -1.30),
                            radius: 0.13, y: 0),
                .bump(center: SIMD2(-1.10, -0.70), width: 0.6, height: 0.03, yaw: 0),
                critter(.drone, at: SIMD2(0.10, -1.90),
                        .patrol(axis: acrossLane, amplitude: 0.20), speed: 1.5),
                critter(.sentry, at: SIMD2(1.30, -2.30), .burrow(period: 2.4)),
            ],
            bonusStar: SIMD2(-1.10, -3.30),
            cameraZoom: 1.85
        ),
        // 5 — the coil (WMF 5). One wall hangs off the left board, a second
        //     drops from the end of it and a third turns back under, so the
        //     trace winds inward: down the outside, along the bottom, up the
        //     far side and in — and the cup is in the eye.
        LevelDefinition(
            course: .neon, number: 5, name: String(localized: "The Coil"), par: 4,
            tee: SIMD2(0.85, 0), hole: SIMD2(0.02, -1.35),
            floors: [floorRect(-1.20, 1.20, -3.60, 0.50)],
            wallLoops: [rectLoop(-1.20, 1.20, -3.60, 0.50)],
            extraWalls: [
                wall(-1.20, -1.00, 0.55, -1.00),
                wall(0.55, -1.00, 0.55, -2.55),
                wall(0.55, -2.55, -0.50, -2.55),
                wall(-0.50, -2.55, -0.50, -1.70),
            ],
            obstacles: [
                .bump(center: SIMD2(0.85, -0.60), width: 0.65, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(0.85, -3.15), direction: SIMD2(-1, 0),
                          boost: 0.9, y: 0),
                critter(.drone, at: SIMD2(-0.85, -2.10),
                        .patrol(axis: alongLane, amplitude: 0.30), speed: 1.4),
                critter(.sentry, at: SIMD2(-0.30, -1.58), .burrow(period: 3.0)),
            ],
            bonusStar: SIMD2(0, -3.25),
            cameraZoom: 1.8
        ),
        // 6 — the table. A chute into a bay full of bumpers with a pair of
        //     flippers across the mouth of the cup: the one hole on the course
        //     where the ball is supposed to be out of control.
        LevelDefinition(
            course: .neon, number: 6, name: String(localized: "The Flippers"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.90),
            floors: [
                floorRect(-0.45, 0.45, -1.30, 0.50),
                floorRect(-1.50, 1.50, -4.30, -1.30),
            ],
            wallLoops: [[
                SIMD2(-0.45, 0.50), SIMD2(0.45, 0.50), SIMD2(0.45, -1.30),
                SIMD2(1.50, -1.30), SIMD2(1.50, -4.30), SIMD2(-1.50, -4.30),
                SIMD2(-1.50, -1.30), SIMD2(-0.45, -1.30),
            ]],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(0, -1.85), radius: 0.09),
                .bumper(center: SIMD2(-0.80, -2.35), radius: 0.09),
                .bumper(center: SIMD2(0.80, -2.35), radius: 0.09),
                .bumper(center: SIMD2(-0.42, -3.00), radius: 0.075),
                .bumper(center: SIMD2(0.42, -3.00), radius: 0.075),
                .rotor(center: SIMD2(-0.95, -3.55), length: 0.6, speed: 2.2, baseY: 0),
                .rotor(center: SIMD2(0.95, -3.55), length: 0.6, speed: -2.2, baseY: 0),
                critter(.drone, at: SIMD2(0, -4.15),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.6),
            ],
            bonusStar: SIMD2(1.30, -2.05),
            cameraZoom: 1.85
        ),
        // 7 — four lanes off one bus, each with a gate on a different beat.
        //     Every lane goes through; only one of them is open when the ball
        //     gets there, and which one that is depends on the first putt.
        LevelDefinition(
            course: .neon, number: 7, name: String(localized: "Bus Lanes"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -3.65),
            floors: [
                floorRect(-1.55, 1.55, -1.10, 0.50),
                floorRect(-1.55, -1.05, -3.20, -1.10),
                floorRect(-0.75, -0.25, -3.20, -1.10),
                floorRect(0.25, 0.75, -3.20, -1.10),
                floorRect(1.05, 1.55, -3.20, -1.10),
                floorRect(-1.55, 1.55, -4.10, -3.20),
            ],
            wallLoops: [
                rectLoop(-1.55, 1.55, -4.10, 0.50),
                rectLoop(-1.05, -0.75, -3.20, -1.10),
                rectLoop(-0.25, 0.25, -3.20, -1.10),
                rectLoop(0.75, 1.05, -3.20, -1.10),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.62), width: 3.0, height: 0.028, yaw: 0),
                .gate(center: SIMD2(-1.30, -2.15), size: SIMD2(0.50, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0),
                .gate(center: SIMD2(-0.50, -2.15), size: SIMD2(0.50, 0.13), yaw: 0,
                      period: 3.0, phase: 0.75, baseY: 0),
                .gate(center: SIMD2(0.50, -2.15), size: SIMD2(0.50, 0.13), yaw: 0,
                      period: 3.0, phase: 1.5, baseY: 0),
                .gate(center: SIMD2(1.30, -2.15), size: SIMD2(0.50, 0.13), yaw: 0,
                      period: 3.0, phase: 2.25, baseY: 0),
                critter(.drone, at: SIMD2(0, -3.90),
                        .patrol(axis: acrossLane, amplitude: 0.95), speed: 1.6),
                critter(.sentry, at: SIMD2(-1.30, -1.45), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.30, -1.45),
            cameraZoom: 1.9
        ),
        // 8 — the stream. Belts run the length of one leg and the width of the
        //     next, so the ball is being carried the whole way and the putt is
        //     only ever a correction.
        LevelDefinition(
            course: .neon, number: 8, name: String(localized: "Data Stream"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(1.65, -4.05),
            floors: [
                floorRect(-0.55, 0.55, -2.40, 0.50),
                floorRect(-0.55, 2.10, -3.40, -2.40),
                floorRect(1.20, 2.10, -4.40, -3.40),
            ],
            wallLoops: [[
                SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -2.40),
                SIMD2(2.10, -2.40), SIMD2(2.10, -4.40), SIMD2(1.20, -4.40),
                SIMD2(1.20, -3.40), SIMD2(-0.55, -3.40),
            ]],
            obstacles: [
                .conveyor(rect: zone(-0.50, 0.50, -2.20, -0.90), direction: SIMD2(0, -1),
                          strength: 2.6, y: 0),
                .conveyor(rect: zone(-0.20, 1.90, -3.30, -2.55), direction: SIMD2(1, 0),
                          strength: 2.4, y: 0),
                .post(center: SIMD2(0.20, -1.55), radius: 0.045),
                critter(.drone, at: SIMD2(1.00, -2.90),
                        .patrol(axis: alongLane, amplitude: 0.24), speed: 1.5),
                critter(.sentry, at: SIMD2(1.65, -3.70), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(-0.30, -3.05),
            cameraZoom: 1.9
        ),
        // 9 — overdrive. A long narrow run into a loop that has to be taken at
        //     speed, and a wide floor beyond it to catch whatever comes out.
        LevelDefinition(
            course: .neon, number: 9, name: String(localized: "Overdrive"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.85, -5.20),
            floors: [
                floorRect(-0.60, 0.60, -3.20, 0.50),
                floorRect(-1.40, 1.40, -6.00, -3.20),
            ],
            wallLoops: [[
                SIMD2(-0.60, 0.50), SIMD2(0.60, 0.50), SIMD2(0.60, -3.20),
                SIMD2(1.40, -3.20), SIMD2(1.40, -6.00), SIMD2(-1.40, -6.00),
                SIMD2(-1.40, -3.20), SIMD2(-0.60, -3.20),
            ]],
            obstacles: [
                .boostPad(center: SIMD2(0, -0.95), direction: SIMD2(0, -1),
                          boost: 1.3, y: 0),
                .loop(center: SIMD2(0, -1.90), radius: 0.30, width: 0.5, yaw: 0, y: 0),
                .bumper(center: SIMD2(-0.60, -3.85), radius: 0.08),
                .bumper(center: SIMD2(0.60, -4.35), radius: 0.08),
                critter(.drone, at: SIMD2(0, -4.90),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.6),
                critter(.sentry, at: SIMD2(-0.95, -5.35), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(-1.15, -4.10),
            cameraZoom: 2.0
        ),
        // 10 — the firewall. Four halls, alternately wide and narrow, and a
        //      shutter in each: nothing about the hole is hard except getting
        //      all four beats right in a row.
        LevelDefinition(
            course: .neon, number: 10, name: String(localized: "Firewall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.45),
            floors: [
                floorRect(-0.90, 0.90, -1.40, 0.50),
                floorRect(-1.40, 1.40, -3.20, -1.40),
                floorRect(-0.90, 0.90, -4.60, -3.20),
                floorRect(-1.40, 1.40, -6.00, -4.60),
            ],
            wallLoops: [[
                SIMD2(-0.90, 0.50), SIMD2(0.90, 0.50), SIMD2(0.90, -1.40),
                SIMD2(1.40, -1.40), SIMD2(1.40, -3.20), SIMD2(0.90, -3.20),
                SIMD2(0.90, -4.60), SIMD2(1.40, -4.60), SIMD2(1.40, -6.00),
                SIMD2(-1.40, -6.00), SIMD2(-1.40, -4.60), SIMD2(-0.90, -4.60),
                SIMD2(-0.90, -3.20), SIMD2(-1.40, -3.20), SIMD2(-1.40, -1.40),
                SIMD2(-0.90, -1.40),
            ]],
            obstacles: [
                .gate(center: SIMD2(0, -0.95), size: SIMD2(0.90, 0.13), yaw: 0,
                      period: 2.8, phase: 0, baseY: 0),
                .gate(center: SIMD2(-0.55, -2.30), size: SIMD2(1.20, 0.13), yaw: 0,
                      period: 3.2, phase: 0.8, baseY: 0),
                .gate(center: SIMD2(0, -3.95), size: SIMD2(0.90, 0.13), yaw: 0,
                      period: 2.6, phase: 1.4, baseY: 0),
                .gate(center: SIMD2(0.55, -5.05), size: SIMD2(1.20, 0.13), yaw: 0,
                      period: 3.4, phase: 0.4, baseY: 0),
                .bumper(center: SIMD2(0.95, -2.30), radius: 0.08),
                critter(.drone, at: SIMD2(0, -1.70),
                        .patrol(axis: acrossLane, amplitude: 0.75), speed: 1.6),
                critter(.sentry, at: SIMD2(-0.95, -5.60), .burrow(period: 2.6)),
            ],
            bonusStar: SIMD2(1.20, -2.65),
            cameraZoom: 2.05
        ),
        // 11 — the grid. A bus down the middle, two rails across it and a riser
        //      at each end joining them, with the bus itself cut through in the
        //      middle: the ball has to leave the straight line and come back to
        //      it, and either way round is the same length.
        LevelDefinition(
            course: .neon, number: 11, name: String(localized: "The Grid"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.75),
            floors: [
                floorRect(-0.55, 0.55, -5.20, 0.50),
                floorRect(-1.60, 1.60, -2.10, -1.40),
                floorRect(-1.60, 1.60, -3.90, -3.20),
                floorRect(-1.60, -0.90, -3.20, -2.10),
                floorRect(0.90, 1.60, -3.20, -2.10),
            ],
            wallLoops: [
                [
                    SIMD2(-0.55, 0.50), SIMD2(0.55, 0.50), SIMD2(0.55, -1.40),
                    SIMD2(1.60, -1.40), SIMD2(1.60, -3.90), SIMD2(0.55, -3.90),
                    SIMD2(0.55, -5.20), SIMD2(-0.55, -5.20), SIMD2(-0.55, -3.90),
                    SIMD2(-1.60, -3.90), SIMD2(-1.60, -1.40), SIMD2(-0.55, -1.40),
                ],
                rectLoop(-0.90, -0.55, -3.20, -2.10),
                rectLoop(0.55, 0.90, -3.20, -2.10),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.70), width: 0.9, height: 0.03, yaw: 0),
                // The bus is cut here, so the rails are the only way south.
                .block(center: SIMD2(0, -2.65), size: SIMD3(1.10, 0.16, 0.30),
                       yaw: 0, baseY: 0),
                .boostPad(center: SIMD2(-1.25, -2.65), direction: SIMD2(0, -1),
                          boost: 0.9, y: 0),
                .bumper(center: SIMD2(1.25, -2.65), radius: 0.08),
                critter(.drone, at: SIMD2(0, -3.55),
                        .patrol(axis: acrossLane, amplitude: 0.85), speed: 1.6),
                critter(.sentry, at: SIMD2(0, -4.30), .burrow(period: 2.8)),
            ],
            bonusStar: SIMD2(-1.40, -1.75),
            cameraZoom: 2.05
        ),
        // 12 — the whole board: a trace with two square corners, a bay with the
        //      diamond in it, and a last leg up onto a raised deck where the
        //      cup sits behind a shutter.
        LevelDefinition(
            course: .neon, number: 12, name: String(localized: "Neon Nights"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-0.60, -6.20), holeY: 0.14,
            floors: [
                floorRect(-0.50, 0.50, -1.20, 0.50),
                floorRect(-1.30, 0.50, -2.10, -1.20),
                floorRect(-1.30, -0.45, -3.70, -2.10),
                floorRect(-1.70, 0.50, -5.25, -3.70),
                floorRect(-1.45, 0.25, -6.50, -5.85, y: 0.14),
            ],
            // The outline is open along the bottom, where the ramp climbs onto
            // the deck, so it is boarded as two chains rather than a ring.
            extraWalls: wallPath([
                SIMD2(-0.50, 0.50), SIMD2(0.50, 0.50), SIMD2(0.50, -2.10),
                SIMD2(-0.45, -2.10), SIMD2(-0.45, -3.70), SIMD2(0.50, -3.70),
                SIMD2(0.50, -5.25),
            ]) + wallPath([
                SIMD2(-0.50, 0.50), SIMD2(-0.50, -1.20), SIMD2(-1.30, -1.20),
                SIMD2(-1.30, -3.70), SIMD2(-1.70, -3.70), SIMD2(-1.70, -5.25),
            ]) + [
                wall(-1.70, -5.25, -0.85, -5.25, height: 0.28),
                wall(-0.35, -5.25, 0.50, -5.25, height: 0.28),
                wall(-1.45, -5.85, -0.85, -5.85, height: 0.28),
                wall(-0.35, -5.85, 0.25, -5.85, height: 0.28),
                wall(-1.45, -5.85, -1.45, -6.50, height: 0.28),
                wall(0.25, -5.85, 0.25, -6.50, height: 0.28),
                wall(-1.45, -6.50, 0.25, -6.50, height: 0.28),
            ],
            obstacles: [
                .bump(center: SIMD2(0, -0.65), width: 0.9, height: 0.03, yaw: 0),
                .boostPad(center: SIMD2(-0.90, -1.65), direction: SIMD2(0, -1),
                          boost: 1.0, y: 0),
                .block(center: SIMD2(-0.88, -2.90), size: SIMD3(0.40, 0.16, 0.40),
                       yaw: deg(45), baseY: 0),
                .bumper(center: SIMD2(-1.30, -4.25), radius: 0.08),
                critter(.drone, at: SIMD2(-0.60, -4.25),
                        .patrol(axis: acrossLane, amplitude: 0.55), speed: 1.6),
                .ramp(center: SIMD2(-0.60, -5.55), width: 0.5, length: 0.6,
                      rise: 0.14, yaw: 0),
                .gate(center: SIMD2(-0.60, -6.00), size: SIMD2(0.60, 0.13), yaw: 0,
                      period: 3.0, phase: 0, baseY: 0.14),
                critter(.sentry, at: SIMD2(0, -6.35), .burrow(period: 2.6), baseY: 0.14),
            ],
            bonusStar: SIMD2(0.30, -4.35),
            cameraZoom: 2.1
        ),
    ]
}
