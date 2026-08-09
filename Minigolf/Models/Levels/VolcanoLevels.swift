//
//  VolcanoLevels.swift
//  Minigolf
//
//  Volcano Forge — lava is a hazard you cannot bridge with a wall, so most of
//  these holes are about getting across something. Geysers throw the ball over
//  a lake, iron gates open on a count, ash slows everything down and the last
//  hole has a forge floor above the crater.
//

import Foundation
import simd

enum VolcanoCourse {

    static let holes: [LevelDefinition] = [
        // 1 — one narrow causeway through the lava, then an iron gate. Neither
        //     is difficult on its own; taken in one putt they are.
        LevelDefinition(
            course: .volcano, number: 1, name: String(localized: "Forge Gate"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.3),
            floors: [
                floorRect(-0.9, 0.9, -1.8, 0.5),
                floorRect(-0.9, -0.2, -2.6, -1.8, kind: .lava),
                floorRect(-0.2, 0.2, -2.6, -1.8),
                floorRect(0.2, 0.9, -2.6, -1.8, kind: .lava),
                floorRect(-0.9, 0.9, -5.0, -2.6),
            ],
            wallLoops: [rectLoop(-0.9, 0.9, -5.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 1.8, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.4, -1.3), radius: 0.04),
                .post(center: SIMD2(0.4, -1.3), radius: 0.04),
                .gate(center: SIMD2(0, -3.2), size: SIMD2(1.8, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .post(center: SIMD2(-0.55, -3.55), radius: 0.04),
                .bumper(center: SIMD2(0.65, -3.55), radius: 0.06),
                critter(.imp, at: SIMD2(0, -3.8),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 1.2),
                .bumper(center: SIMD2(-0.6, -4.6), radius: 0.06),
                critter(.magmaBlob, at: SIMD2(0.5, -4.7),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.8),
            ],
            bonusStar: SIMD2(0.65, -4.85),
            cameraZoom: 1.5
        ),
        // 2 — no causeway at all. The geyser throws exactly as far every time,
        //     so the carry can be trusted; what cannot is the reception.
        LevelDefinition(
            course: .volcano, number: 2, name: String(localized: "Geyser"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -4.6),
            floors: [
                floorRect(-1.0, 1.0, -2.2, 0.5),
                floorRect(-1.0, 1.0, -3.2, -2.2, kind: .lava),
                floorRect(-1.0, 1.0, -5.2, -3.2),
            ],
            wallLoops: [rectLoop(-1.0, 1.0, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.0, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.45, -1.3), radius: 0.04),
                .post(center: SIMD2(0.45, -1.3), radius: 0.04),
                .launchPad(center: SIMD2(0, -1.9), direction: SIMD2(0, -1), speed: 3.4,
                           lift: 2.0, y: 0),
                .post(center: SIMD2(-0.7, -3.6), radius: 0.04),
                .bumper(center: SIMD2(0.7, -3.6), radius: 0.06),
                critter(.imp, at: SIMD2(0, -3.8),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.3),
                .bumper(center: SIMD2(-0.8, -4.3), radius: 0.06),
                .bumper(center: SIMD2(0.8, -4.3), radius: 0.06),
                critter(.magmaBlob, at: SIMD2(0, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
            ],
            bonusStar: SIMD2(0.8, -5.0),
            cameraZoom: 1.55
        ),
        // 3 — two flows running opposite ways with a bar turning below them. The
        //     belts are strong enough that arriving anywhere is a plan.
        LevelDefinition(
            course: .volcano, number: 3, name: String(localized: "Lava Flow"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0.3, -4.85),
            floors: [floorRect(-1.4, 1.4, -5.2, 0.5)],
            wallLoops: [rectLoop(-1.4, 1.4, -5.2, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 2.8, height: 0.03, yaw: 0),
                .conveyor(rect: zone(-1.4, 1.4, -2.4, -1.8), direction: SIMD2(1, 0),
                          strength: 3.2, y: 0),
                .bumper(center: SIMD2(1.2, -2.1), radius: 0.06),
                critter(.imp, at: SIMD2(0, -2.7),
                        .patrol(axis: acrossLane, amplitude: 0.7), speed: 1.3),
                .conveyor(rect: zone(-1.4, 1.4, -3.6, -3.0), direction: SIMD2(-1, 0),
                          strength: 3.2, y: 0),
                .bumper(center: SIMD2(-1.2, -3.3), radius: 0.06),
                .rotor(center: SIMD2(0, -4.2), length: 1.0, speed: 1.6, baseY: 0),
                critter(.magmaBlob, at: SIMD2(-0.8, -4.9),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
                .post(center: SIMD2(0.9, -4.9), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.25, -1.5),
            cameraZoom: 1.7
        ),
        // 4 — three iron gates, each covering the opposite half of the hole and
        //     each a beat behind the last.
        LevelDefinition(
            course: .volcano, number: 4, name: String(localized: "Iron Gates"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.9, -5.1),
            floors: [floorRect(-1.5, 1.5, -5.4, 0.5)],
            wallLoops: [rectLoop(-1.5, 1.5, -5.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.0, height: 0.03, yaw: 0),
                .gate(center: SIMD2(-0.7, -1.6), size: SIMD2(1.6, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                .post(center: SIMD2(-1.2, -2.2), radius: 0.04),
                .gate(center: SIMD2(0.7, -2.8), size: SIMD2(1.6, 0.09), yaw: 0,
                      period: 2.2, phase: 0.7, baseY: 0),
                .post(center: SIMD2(1.2, -3.4), radius: 0.04),
                critter(.imp, at: SIMD2(0, -3.4),
                        .patrol(axis: acrossLane, amplitude: 0.6), speed: 1.3),
                .gate(center: SIMD2(-0.7, -4.0), size: SIMD2(1.6, 0.09), yaw: 0,
                      period: 2.2, phase: 1.4, baseY: 0),
                .bumper(center: SIMD2(1.2, -4.6), radius: 0.06),
                .block(center: SIMD2(0.5, -4.95), size: SIMD3(0.7, 0.16, 0.25),
                       yaw: 0, baseY: 0),
                critter(.magmaBlob, at: SIMD2(0.3, -5.15),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
            ],
            bonusStar: SIMD2(1.3, -5.15),
            cameraZoom: 1.8
        ),
        // 5 — two causeways, neither of them lined up with the other, and ash
        //     laid across the ground between them so nothing arrives quickly.
        LevelDefinition(
            course: .volcano, number: 5, name: String(localized: "Cinder Path"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(-0.9, -5.2),
            floors: [
                floorRect(-1.6, 1.6, -2.0, 0.5),
                floorRect(-1.6, -0.6, -3.0, -2.0, kind: .lava),
                floorRect(-0.6, 0.5, -3.0, -2.0),
                floorRect(0.5, 1.6, -3.0, -2.0, kind: .lava),
                floorRect(-1.6, 1.6, -3.8, -3.0),
                floorRect(-1.6, 1.6, -3.7, -3.1, kind: .mud),
                floorRect(-1.6, 0.1, -4.7, -3.8, kind: .lava),
                floorRect(0.1, 1.1, -4.7, -3.8),
                floorRect(1.1, 1.6, -4.7, -3.8, kind: .lava),
                floorRect(-1.6, 1.6, -5.6, -4.7),
            ],
            wallLoops: [rectLoop(-1.6, 1.6, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.2, height: 0.03, yaw: 0),
                .post(center: SIMD2(-0.35, -1.4), radius: 0.04),
                .post(center: SIMD2(0.35, -1.4), radius: 0.04),
                .post(center: SIMD2(-1.35, -1.4), radius: 0.04),
                .bumper(center: SIMD2(1.35, -1.4), radius: 0.06),
                .gate(center: SIMD2(-0.05, -2.5), size: SIMD2(1.1, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                critter(.imp, at: SIMD2(0, -3.4),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.3),
                .rotor(center: SIMD2(0.6, -4.25), length: 0.7, speed: 1.5, baseY: 0),
                .bumper(center: SIMD2(-1.3, -5.1), radius: 0.06),
                critter(.magmaBlob, at: SIMD2(0.6, -5.3),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
            ],
            bonusStar: SIMD2(1.35, -5.3),
            cameraZoom: 1.85
        ),
        // 6 — the lake fills the middle of the hole and the two channels round
        //      it each have a hammer swinging in them. Pick a side and commit.
        LevelDefinition(
            course: .volcano, number: 6, name: String(localized: "Magma Chamber"), par: 4,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.25),
            floors: [
                floorRect(-1.7, 1.7, -1.8, 0.5),
                floorRect(-1.7, -0.7, -4.0, -1.8),
                floorRect(-0.7, 0.7, -4.0, -1.8, kind: .lava),
                floorRect(0.7, 1.7, -4.0, -1.8),
                floorRect(-1.7, 1.7, -5.6, -4.0),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -5.6, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.4, height: 0.03, yaw: 0),
                .bumper(center: SIMD2(-1.45, -1.4), radius: 0.06),
                .bumper(center: SIMD2(1.45, -1.4), radius: 0.06),
                critter(.magmaBlob, at: SIMD2(1.2, -2.0),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
                .pendulum(center: SIMD2(-1.2, -2.9), span: 0.8, arc: 0.6, speed: 1.6,
                          yaw: 0, baseY: 0),
                .pendulum(center: SIMD2(1.2, -2.9), span: 0.8, arc: 0.6, speed: -1.8,
                          yaw: 0, baseY: 0),
                critter(.imp, at: SIMD2(-1.2, -3.8),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.2),
                .rotor(center: SIMD2(0, -4.6), length: 1.2, speed: 1.5, baseY: 0),
                .post(center: SIMD2(-0.7, -5.2), radius: 0.04),
                .post(center: SIMD2(0.7, -5.2), radius: 0.04),
            ],
            bonusStar: SIMD2(1.45, -4.4),
            cameraZoom: 1.9
        ),
        // 7 — a gate at the mouth, a geyser over the crater and a deep field of
        //      ash on the far side with a bar turning in it.
        LevelDefinition(
            course: .volcano, number: 7, name: String(localized: "Ash Fall"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -5.7),
            floors: [
                floorRect(-1.7, 1.7, -2.6, 0.5),
                floorRect(-1.7, 1.7, -3.5, -2.6, kind: .lava),
                floorRect(-1.7, 1.7, -6.0, -3.5),
                floorRect(-1.7, 1.7, -5.4, -4.4, kind: .mud),
            ],
            wallLoops: [rectLoop(-1.7, 1.7, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.4, height: 0.03, yaw: 0),
                .gate(center: SIMD2(0, -1.4), size: SIMD2(3.4, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.45, -2.0), radius: 0.06),
                .bumper(center: SIMD2(1.45, -2.0), radius: 0.06),
                .launchPad(center: SIMD2(0, -2.3), direction: SIMD2(0, -1), speed: 3.5,
                           lift: 2.0, y: 0),
                critter(.imp, at: SIMD2(0, -4.0),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.3),
                .rotor(center: SIMD2(-0.8, -4.9), length: 0.9, speed: 1.5, baseY: 0),
                critter(.magmaBlob, at: SIMD2(0.9, -5.0),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 0.8),
                .block(center: SIMD2(-1.3, -5.7), size: SIMD3(0.6, 0.16, 0.3),
                       yaw: 0, baseY: 0),
                .post(center: SIMD2(1.4, -5.7), radius: 0.04),
            ],
            bonusStar: SIMD2(-1.45, -4.0),
            cameraZoom: 1.95
        ),
        // 8 — a long left-hander with the lake taking the whole inside of the
        //      turn, a hammer over the neck and a gate on the way home.
        LevelDefinition(
            course: .volcano, number: 8, name: String(localized: "Obsidian Bank"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(-2.0, -5.2),
            floors: [
                floorRect(-0.7, 0.7, -2.6, 0.5),
                floorRect(-2.6, -1.4, -3.3, -2.6, kind: .lava),
                floorRect(-1.4, 1.1, -3.3, -2.6),
                floorRect(-2.6, 1.1, -4.1, -3.3),
                floorRect(-2.6, -1.4, -5.8, -4.1),
            ],
            wallLoops: [[
                SIMD2(0.7, 0.5), SIMD2(0.7, -2.6), SIMD2(1.1, -2.6),
                SIMD2(1.1, -4.1), SIMD2(-1.4, -4.1), SIMD2(-1.4, -5.8),
                SIMD2(-2.6, -5.8), SIMD2(-2.6, -2.6), SIMD2(-0.7, -2.6),
                SIMD2(-0.7, 0.5),
            ]],
            extraWalls: arcWall(center: SIMD2(0.55, -3.55), radius: 0.55,
                                from: deg(270), to: deg(360), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.4, height: 0.035, yaw: 0),
                .rotor(center: SIMD2(0, -1.7), length: 0.9, speed: 1.6, baseY: 0),
                .pendulum(center: SIMD2(-0.15, -2.95), span: 1.2, arc: 0.65, speed: 1.5,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(0.3, -2.0), radius: 0.04),
                .bumper(center: SIMD2(0.8, -3.7), radius: 0.06),
                .bumper(center: SIMD2(-1.0, -3.7), radius: 0.06),
                critter(.imp, at: SIMD2(-0.6, -3.75),
                        .patrol(axis: acrossLane, amplitude: 0.5), speed: 1.3),
                critter(.magmaBlob, at: SIMD2(-2.0, -4.5),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 0.8),
                .gate(center: SIMD2(-2.0, -4.8), size: SIMD2(1.2, 0.09), yaw: 0,
                      period: 2.4, phase: 0, baseY: 0),
                .post(center: SIMD2(-1.65, -5.5), radius: 0.04),
            ],
            bonusStar: SIMD2(0.85, -2.9),
            cameraZoom: 2.0
        ),
        // 9 — the crucible: a gate to get out of, a geyser to get across, and
        //      two bars turning in opposite directions around the cup.
        LevelDefinition(
            course: .volcano, number: 9, name: String(localized: "Crucible"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.55),
            floors: [
                floorRect(-1.8, 1.8, -2.4, 0.5),
                floorRect(-1.8, 1.8, -3.6, -2.4, kind: .lava),
                floorRect(-1.8, 1.8, -6.0, -3.6),
            ],
            wallLoops: [rectLoop(-1.8, 1.8, -6.0, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.7), width: 3.6, height: 0.03, yaw: 0),
                .gate(center: SIMD2(0, -1.3), size: SIMD2(3.6, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .bumper(center: SIMD2(-1.5, -1.6), radius: 0.06),
                .bumper(center: SIMD2(1.5, -1.6), radius: 0.06),
                .launchPad(center: SIMD2(0, -2.1), direction: SIMD2(0, -1), speed: 3.6,
                           lift: 2.15, y: 0),
                critter(.imp, at: SIMD2(0, -4.2),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.3),
                critter(.magmaBlob, at: SIMD2(1.5, -4.3),
                        .patrol(axis: acrossLane, amplitude: 0.25), speed: 0.8),
                .post(center: SIMD2(-0.5, -4.7), radius: 0.04),
                .post(center: SIMD2(0.5, -4.7), radius: 0.04),
                .rotor(center: SIMD2(-1.0, -5.0), length: 0.9, speed: 1.6, baseY: 0),
                .rotor(center: SIMD2(1.0, -5.0), length: 0.9, speed: -1.6, baseY: 0),
            ],
            bonusStar: SIMD2(-1.55, -4.3),
            cameraZoom: 2.0
        ),
        // 10 — the causeway across the crater is half a metre wide and has a
        //      gate on it, and the forge floor above is reached by a ramp with
        //      a hammer swinging beside its foot.
        LevelDefinition(
            course: .volcano, number: 10, name: String(localized: "Forge Terrace"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -5.85), holeY: 0.18,
            floors: [
                floorRect(-0.8, 0.8, -2.0, 0.5),
                floorRect(-1.8, 1.8, -3.4, -2.0),
                floorRect(-1.8, -0.3, -4.2, -3.4, kind: .lava),
                floorRect(-0.3, 0.3, -4.2, -3.4),
                floorRect(0.3, 1.8, -4.2, -3.4, kind: .lava),
                floorRect(-1.8, 1.8, -4.9, -4.2),
                floorRect(-1.4, 1.4, -6.2, -5.5, y: 0.18),
            ],
            extraWalls: [
                wall(-0.8, 0.5, 0.8, 0.5),
                wall(0.8, 0.5, 0.8, -2.0),
                wall(0.8, -2.0, 1.8, -2.0),
                wall(1.8, -2.0, 1.8, -4.9),
                wall(1.8, -4.9, 0.45, -4.9),
                wall(-0.45, -4.9, -1.8, -4.9),
                wall(-1.8, -4.9, -1.8, -2.0),
                wall(-1.8, -2.0, -0.8, -2.0),
                wall(-0.8, -2.0, -0.8, 0.5),
                wall(-1.4, -5.5, -0.45, -5.5, height: 0.34),
                wall(0.45, -5.5, 1.4, -5.5, height: 0.34),
                wall(1.4, -5.5, 1.4, -6.2, height: 0.34),
                wall(1.4, -6.2, -1.4, -6.2, height: 0.34),
                wall(-1.4, -6.2, -1.4, -5.5, height: 0.34),
            ]
            + arcWall(center: SIMD2(-1.25, -2.55), radius: 0.55,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.25, -2.55), radius: 0.55,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.9), width: 1.6, height: 0.035, yaw: 0),
                .rotor(center: SIMD2(0, -1.5), length: 0.9, speed: 1.7, baseY: 0),
                .bumper(center: SIMD2(-0.9, -2.6), radius: 0.06),
                .bumper(center: SIMD2(0.9, -2.6), radius: 0.06),
                critter(.imp, at: SIMD2(0, -2.9),
                        .patrol(axis: acrossLane, amplitude: 0.8), speed: 1.3),
                .gate(center: SIMD2(0, -3.8), size: SIMD2(0.6, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                critter(.magmaBlob, at: SIMD2(-1.2, -4.55),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 0.8),
                .pendulum(center: SIMD2(0.9, -4.55), span: 0.9, arc: 0.6, speed: 1.6,
                          yaw: 0, baseY: 0),
                .ramp(center: SIMD2(0, -5.2), width: 0.9, length: 0.6, rise: 0.18, yaw: 0),
                .block(center: SIMD2(1.05, -5.9), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.18),
                critter(.imp, at: SIMD2(-0.8, -5.9),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1, baseY: 0.18),
            ],
            bonusStar: SIMD2(1.55, -4.55),
            cameraZoom: 2.1
        ),
        // 11 — two hammers at the gate, a bar in the middle, one gated causeway
        //      between two pools and a block still sweeping the run home.
        LevelDefinition(
            course: .volcano, number: 11, name: String(localized: "Pyroclast"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0.2, -6.05),
            floors: [
                floorRect(-1.9, 1.9, -3.6, 0.5),
                floorRect(-1.9, 1.9, -2.6, -1.6, kind: .mud),
                floorRect(-1.9, -0.9, -4.4, -3.6, kind: .lava),
                floorRect(-0.9, 0.9, -4.4, -3.6),
                floorRect(0.9, 1.9, -4.4, -3.6, kind: .lava),
                floorRect(-1.9, 1.9, -6.4, -4.4),
            ],
            wallLoops: [rectLoop(-1.9, 1.9, -6.4, 0.5)],
            obstacles: [
                .bump(center: SIMD2(0, -0.8), width: 3.8, height: 0.03, yaw: 0),
                .pendulum(center: SIMD2(-0.9, -1.3), span: 1.2, arc: 0.7, speed: 1.6,
                          yaw: 0, baseY: 0),
                .pendulum(center: SIMD2(0.9, -1.3), span: 1.2, arc: 0.7, speed: -1.8,
                          yaw: 0, baseY: 0),
                .post(center: SIMD2(1.7, -2.0), radius: 0.04),
                .rotor(center: SIMD2(0, -3.0), length: 1.2, speed: 1.6, baseY: 0),
                .gate(center: SIMD2(0, -4.0), size: SIMD2(1.8, 0.09), yaw: 0,
                      period: 2.2, phase: 0, baseY: 0),
                critter(.imp, at: SIMD2(0, -4.9),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.3),
                .bumper(center: SIMD2(-1.6, -5.0), radius: 0.06),
                .bumper(center: SIMD2(1.6, -5.0), radius: 0.06),
                .movingBlock(center: SIMD2(0.8, -5.8), axis: acrossLane, amplitude: 0.8,
                             speed: 1.2, size: SIMD2(0.5, 0.2), baseY: 0),
                critter(.magmaBlob, at: SIMD2(-0.9, -5.9),
                        .patrol(axis: acrossLane, amplitude: 0.35), speed: 0.8),
            ],
            bonusStar: SIMD2(-1.7, -2.1),
            cameraZoom: 2.15
        ),
        // 12 — the forge. A bar at the gate, shoulders into the crater rim, a
        //      full-width shutter, the geyser over the lake, a hammer on the far
        //      shore and a forge floor that tilts under the ball at the end.
        LevelDefinition(
            course: .volcano, number: 12, name: String(localized: "Volcano Forge"), par: 5,
            tee: SIMD2(0, 0), hole: SIMD2(0, -6.4), holeY: 0.2,
            floors: [
                floorRect(-0.8, 0.8, -1.9, 0.5),
                floorRect(-2.1, 2.1, -3.3, -1.9),
                floorRect(-2.1, 2.1, -4.3, -3.3, kind: .lava),
                floorRect(-2.1, 2.1, -5.2, -4.3),
                floorRect(-1.5, 1.5, -6.8, -5.8, y: 0.2),
            ],
            extraWalls: [
                wall(-0.8, 0.5, 0.8, 0.5),
                wall(0.8, 0.5, 0.8, -1.9),
                wall(0.8, -1.9, 2.1, -1.9),
                wall(2.1, -1.9, 2.1, -5.2),
                wall(2.1, -5.2, 0.45, -5.2),
                wall(-0.45, -5.2, -2.1, -5.2),
                wall(-2.1, -5.2, -2.1, -1.9),
                wall(-2.1, -1.9, -0.8, -1.9),
                wall(-0.8, -1.9, -0.8, 0.5),
                wall(-1.5, -5.8, -0.45, -5.8, height: 0.36),
                wall(0.45, -5.8, 1.5, -5.8, height: 0.36),
                wall(1.5, -5.8, 1.5, -6.8, height: 0.36),
                wall(1.5, -6.8, -1.5, -6.8, height: 0.36),
                wall(-1.5, -6.8, -1.5, -5.8, height: 0.36),
            ]
            + arcWall(center: SIMD2(-1.5, -2.5), radius: 0.6,
                      from: deg(90), to: deg(180), segments: 5)
            + arcWall(center: SIMD2(1.5, -2.5), radius: 0.6,
                      from: deg(0), to: deg(90), segments: 5),
            obstacles: [
                .bump(center: SIMD2(0, -0.85), width: 1.6, height: 0.035, yaw: 0),
                .rotor(center: SIMD2(0, -1.4), length: 1.0, speed: 1.8, baseY: 0),
                critter(.imp, at: SIMD2(0, -2.4),
                        .patrol(axis: acrossLane, amplitude: 0.9), speed: 1.3),
                .bumper(center: SIMD2(-1.0, -2.6), radius: 0.06),
                .bumper(center: SIMD2(1.0, -2.6), radius: 0.06),
                .gate(center: SIMD2(0, -2.9), size: SIMD2(4.2, 0.09), yaw: 0,
                      period: 2.6, phase: 0, baseY: 0),
                .launchPad(center: SIMD2(0, -3.1), direction: SIMD2(0, -1), speed: 3.7,
                           lift: 2.15, y: 0),
                critter(.magmaBlob, at: SIMD2(-1.4, -4.75),
                        .patrol(axis: acrossLane, amplitude: 0.4), speed: 0.8),
                .rotor(center: SIMD2(1.3, -4.75), length: 0.9, speed: -1.6, baseY: 0),
                .ramp(center: SIMD2(0, -5.5), width: 0.9, length: 0.6, rise: 0.2, yaw: 0),
                .slope(rect: zone(-1.5, 1.5, -6.7, -5.9), direction: SIMD2(1, 0),
                       strength: 0.9, y: 0.2),
                .block(center: SIMD2(1.15, -6.4), size: SIMD3(0.4, 0.14, 0.5),
                       yaw: 0, baseY: 0.2),
                critter(.imp, at: SIMD2(-0.85, -6.4),
                        .patrol(axis: acrossLane, amplitude: 0.3), speed: 1.1, baseY: 0.2),
            ],
            bonusStar: SIMD2(1.85, -4.75),
            cameraZoom: 2.25
        ),
    ]
}
