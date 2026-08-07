//
//  Obstacles.swift
//  Minigolf
//
//  Builders for all interactive obstacles plus the per-frame animation state
//  that drives the kinematic ones (windmill blades, rotors, sliding blocks).
//

import Foundation
import RealityKit
import UIKit
import simd

// MARK: - Animation state

struct AnimatedObstacle {
    enum Kind {
        case windmillBlades(speed: Float, baseOrientation: simd_quatf)
        case rotor(speed: Float, baseY: Float)
        case movingBlock(center: SIMD3<Float>, axis: SIMD3<Float>, amplitude: Float, speed: Float)
        case flag(phase: Float)
        /// Gate sliding down into the floor and back up again.
        case gate(base: SIMD3<Float>, drop: Float, period: Float, phase: Float)
        /// Arm swinging around its pivot; the entity is the pivot itself.
        case pendulum(arc: Float, speed: Float)
        /// Chevrons riding along a belt. The entity is the belt root, whose
        /// children are spaced evenly along its local Z axis.
        case belt(length: Float, speed: Float)
        /// Slowly turning and bobbing pickup (bonus stars, portal rings).
        case spin(speed: Float, baseY: Float, bob: Float)
        /// Fan blades turning at the pace of the gust, so the player can read
        /// the wind off the propeller instead of guessing. The angle is the
        /// integral of `WindZone.gust`, which is a plain sine — worth writing
        /// out longhand so the blades never jump when the app is backgrounded.
        case gustBlades(speed: Float, period: Float, phase: Float)
        /// Ring travelling in or out on a loop: the magnet's field lines.
        case pulse(from: Float, to: Float, speed: Float, phase: Float)
    }

    var kind: Kind
    var entity: Entity

    func update(time: Float) {
        switch kind {
        case .windmillBlades(let speed, let base):
            entity.orientation = base * simd_quatf(angle: time * speed, axis: SIMD3(0, 0, 1))
        case .rotor(let speed, _):
            entity.orientation = simd_quatf(angle: time * speed, axis: SIMD3(0, 1, 0))
        case .movingBlock(let center, let axis, let amplitude, let speed):
            entity.position = center + axis * (sin(time * speed) * amplitude)
        case .flag(let phase):
            entity.orientation = simd_quatf(angle: sin(time * 2.1 + phase) * 0.16,
                                            axis: SIMD3(0, 1, 0))
        case .gate(let base, let drop, let period, let phase):
            entity.position = SIMD3(base.x, base.y - drop * Self.openness(time: time,
                                                                         period: period,
                                                                         phase: phase),
                                    base.z)
        case .pendulum(let arc, let speed):
            entity.orientation = simd_quatf(angle: arc * sin(time * speed), axis: SIMD3(0, 0, 1))
        case .belt(let length, let speed):
            let count = entity.children.count
            guard count > 0, length > 0 else { return }
            let spacing = length / Float(count)
            for (i, child) in entity.children.enumerated() {
                let travelled = (time * speed + Float(i) * spacing)
                    .truncatingRemainder(dividingBy: length)
                child.position.z = travelled - length / 2
            }
        case .spin(let speed, let baseY, let bob):
            entity.orientation = simd_quatf(angle: time * speed, axis: SIMD3(0, 1, 0))
            entity.position.y = baseY + bob * sin(time * 2.4)
        case .gustBlades(let speed, let period, let phase):
            entity.orientation = simd_quatf(angle: speed * bladeAngle(time: time, period: period,
                                                                     phase: phase),
                                            axis: SIMD3(0, 0, 1))
        case .pulse(let from, let to, let speed, let phase):
            let t = (time * speed + phase).truncatingRemainder(dividingBy: 1)
            let scale = from + (to - from) * t
            entity.scale = SIMD3(scale, 1, scale)
        }
    }

    /// ∫ gust dt for `gust(t) = 0.5 + 0.5·sin(2πt/T + φ)`.
    private func bladeAngle(time: Float, period: Float, phase: Float) -> Float {
        guard period > 0 else { return time }
        let w = 2 * Float.pi / period
        return 0.5 * time - (cos(w * time + phase) - cos(phase)) / (2 * w)
    }

    /// 0 = fully closed, 1 = fully sunk. The flat top and bottom of the curve
    /// give the player a real window instead of a knife-edge timing.
    static func openness(time: Float, period: Float, phase: Float) -> Float {
        guard period > 0 else { return 0 }
        let raw = sin(2 * .pi * time / period + phase)
        return smoothstep(raw * 0.9 + 0.5)
    }
}

// MARK: - Builders

enum ObstacleBuilder {

    static func build(_ spec: ObstacleSpec, index: Int, theme: CourseTheme,
                      materials: ThemeMaterials, into root: Entity,
                      outputs: inout ObstacleOutputs) {
        switch spec {
        case .windmill(let center, let yaw, let speed):
            buildWindmill(center: center, yaw: yaw, speed: speed, theme: theme,
                          materials: materials, into: root, animated: &outputs.animated)
        case .rotor(let center, let length, let speed, let baseY):
            buildRotor(center: center, length: length, speed: speed, baseY: baseY,
                       theme: theme, into: root, animated: &outputs.animated)
        case .movingBlock(let center, let axis, let amplitude, let speed, let size, let baseY):
            buildMovingBlock(center: center, axis: axis, amplitude: amplitude, speed: speed,
                             size: size, baseY: baseY, theme: theme, into: root,
                             animated: &outputs.animated)
        case .bumper(let center, let radius):
            buildBumper(center: center, radius: radius, index: index, theme: theme,
                        into: root, bumperNames: &outputs.bumperNames)
        case .post(let center, let radius):
            buildPost(center: center, radius: radius, theme: theme, into: root)
        case .bump(let center, let width, let height, let yaw):
            buildBump(center: center, width: width, height: height, yaw: yaw,
                      materials: materials, into: root)
        case .ramp(let center, let width, let length, let rise, let yaw):
            buildRamp(center: center, width: width, length: length, rise: rise, yaw: yaw,
                      materials: materials, into: root)
        case .block(let center, let size, let yaw, let baseY):
            buildBlock(center: center, size: size, yaw: yaw, baseY: baseY,
                       materials: materials, into: root)
        case .tunnel(let center, let width, let length, let yaw):
            buildTunnel(center: center, width: width, length: length, yaw: yaw,
                        materials: materials, into: root)
        case .slope(let rect, let direction, let strength, let y):
            buildSlope(rect: rect, direction: direction, strength: strength, y: y,
                       materials: materials, into: root, outputs: &outputs)
        case .conveyor(let rect, let direction, let strength, let y):
            buildConveyor(rect: rect, direction: direction, strength: strength, y: y,
                          materials: materials, into: root, outputs: &outputs)
        case .teleporter(let a, let b, let radius, let y):
            buildTeleporter(a: a, b: b, radius: radius, y: y, materials: materials,
                            into: root, outputs: &outputs)
        case .gate(let center, let size, let yaw, let period, let phase, let baseY):
            buildGate(center: center, size: size, yaw: yaw, period: period, phase: phase,
                      baseY: baseY, theme: theme, materials: materials, into: root,
                      animated: &outputs.animated)
        case .pendulum(let center, let span, let arc, let speed, let yaw, let baseY):
            buildPendulum(center: center, span: span, arc: arc, speed: speed, yaw: yaw,
                          baseY: baseY, theme: theme, materials: materials, into: root,
                          animated: &outputs.animated)
        case .boostPad(let center, let direction, let boost, let y):
            buildBoostPad(center: center, direction: direction, boost: boost, y: y,
                          materials: materials, into: root, outputs: &outputs)
        case .loop(let center, let radius, let width, let yaw, let y):
            buildLoop(center: center, radius: radius, width: width, yaw: yaw, y: y,
                      theme: theme, materials: materials, into: root, outputs: &outputs)
        case .launchPad(let center, let direction, let speed, let lift, let y):
            buildLaunchPad(center: center, direction: direction, speed: speed, lift: lift,
                           y: y, theme: theme, materials: materials, into: root,
                           outputs: &outputs)
        case .cannon(let center, let direction, let speed, let y):
            buildCannon(center: center, direction: direction, speed: speed, y: y,
                        theme: theme, materials: materials, into: root, outputs: &outputs)
        case .turntable(let center, let radius, let speed, let y):
            buildTurntable(center: center, radius: radius, speed: speed, y: y,
                           materials: materials, into: root, outputs: &outputs)
        case .magnet(let center, let radius, let strength, let y):
            buildMagnet(center: center, radius: radius, strength: strength, y: y,
                        theme: theme, materials: materials, into: root, outputs: &outputs)
        case .fan(let rect, let direction, let strength, let period, let phase, let y):
            buildFan(rect: rect, direction: direction, strength: strength, period: period,
                     phase: phase, y: y, materials: materials, into: root, outputs: &outputs)
        }
    }

    private static func staticPhysics(_ entity: ModelEntity, shape: ShapeResource,
                                      material: PhysicsMaterialResource = GamePhysics.wallMaterial) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default, material: material, mode: .static))
    }

    private static func kinematicPhysics(_ entity: ModelEntity, shape: ShapeResource) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.wallMaterial, mode: .kinematic))
    }

    // MARK: Windmill

    private static func buildWindmill(center: SIMD2<Float>, yaw: Float, speed: Float,
                                      theme: CourseTheme, materials: ThemeMaterials,
                                      into root: Entity, animated: inout [AnimatedObstacle]) {
        let group = Entity()
        group.name = "windmill"
        group.position = SIMD3(center.x, 0, center.y)
        group.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))

        let wallMaterial = materials.wall
        let gapHalf: Float = 0.12
        let blockWidth: Float = 0.34
        let blockHeight: Float = 0.22

        // Gate blocks on both sides of the opening.
        for side: Float in [-1, 1] {
            let block = ModelEntity(
                mesh: .generateBox(width: blockWidth, height: blockHeight,
                                   depth: 0.16, cornerRadius: 0.01),
                materials: [wallMaterial]
            )
            block.name = "wall"
            block.position = SIMD3(side * (gapHalf + blockWidth / 2), blockHeight / 2, 0)
            staticPhysics(block, shape: .generateBox(width: blockWidth, height: blockHeight, depth: 0.16))
            group.addChild(block)
        }

        // Header beam and mill tower above the gate.
        let beam = ModelEntity(
            mesh: .generateBox(width: (gapHalf + blockWidth) * 2, height: 0.08,
                               depth: 0.16, cornerRadius: 0.01),
            materials: [wallMaterial]
        )
        beam.position = SIMD3(0, blockHeight + 0.04, 0)
        group.addChild(beam)

        let tower = ModelEntity(
            mesh: .generateBox(width: 0.3, height: 0.24, depth: 0.15, cornerRadius: 0.01),
            materials: [SceneBuilder.simpleMaterial(theme.wallTopColor, roughness: 0.7)]
        )
        tower.position = SIMD3(0, blockHeight + 0.08 + 0.12, 0)
        group.addChild(tower)

        // Simple pitched roof.
        let roofMaterial = SceneBuilder.simpleMaterial(theme.accent, roughness: 0.6)
        for side: Float in [-1, 1] {
            let slab = ModelEntity(
                mesh: .generateBox(width: 0.2, height: 0.02, depth: 0.17, cornerRadius: 0.005),
                materials: [roofMaterial]
            )
            slab.position = SIMD3(side * 0.075, blockHeight + 0.08 + 0.24 + 0.045, 0)
            slab.orientation = simd_quatf(angle: side * 0.62, axis: SIMD3(0, 0, 1))
            group.addChild(slab)
        }

        // Rotating blades in front of the gate (facing the tee at +Z).
        let bladesRoot = Entity()
        bladesRoot.name = "bladesRoot"
        bladesRoot.position = SIMD3(0, 0.325, 0.105)
        group.addChild(bladesRoot)

        let hub = ModelEntity(
            mesh: .generateSphere(radius: 0.032),
            materials: [SceneBuilder.simpleMaterial(UIColor(white: 0.9, alpha: 1), roughness: 0.5)]
        )
        bladesRoot.addChild(hub)

        let bladeMaterial = SceneBuilder.simpleMaterial(theme.accent, roughness: 0.6)
        for i in 0..<4 {
            let blade = ModelEntity(
                mesh: .generateBox(width: 0.05, height: 0.3, depth: 0.018, cornerRadius: 0.008),
                materials: [bladeMaterial]
            )
            blade.name = "wall"
            let holder = Entity()
            holder.orientation = simd_quatf(angle: Float(i) * .pi / 2, axis: SIMD3(0, 0, 1))
            blade.position = SIMD3(0, 0.165, 0)
            kinematicPhysics(blade, shape: .generateBox(width: 0.05, height: 0.3, depth: 0.018))
            holder.addChild(blade)
            bladesRoot.addChild(holder)
        }

        animated.append(AnimatedObstacle(
            kind: .windmillBlades(speed: speed, baseOrientation: bladesRoot.orientation),
            entity: bladesRoot))
        root.addChild(group)
    }

    // MARK: Rotor

    private static func buildRotor(center: SIMD2<Float>, length: Float, speed: Float,
                                   baseY: Float, theme: CourseTheme, into root: Entity,
                                   animated: inout [AnimatedObstacle]) {
        let hub = ModelEntity(
            mesh: .generateCylinder(height: 0.07, radius: 0.045),
            materials: [SceneBuilder.simpleMaterial(UIColor(white: 0.88, alpha: 1), roughness: 0.4)]
        )
        hub.position = SIMD3(center.x, baseY + 0.035, center.y)
        root.addChild(hub)

        let barPivot = Entity()
        barPivot.name = "rotorPivot"
        barPivot.position = SIMD3(center.x, baseY + 0.034, center.y)
        root.addChild(barPivot)

        var barMaterial = PhysicallyBasedMaterial()
        barMaterial.baseColor = .init(tint: theme.accent)
        barMaterial.roughness = 0.55
        if theme.emissiveWalls {
            barMaterial.emissiveColor = .init(color: theme.accent)
            barMaterial.emissiveIntensity = 1.3
        }
        let bar = ModelEntity(
            mesh: .generateBox(width: length, height: 0.05, depth: 0.05, cornerRadius: 0.015),
            materials: [barMaterial]
        )
        bar.name = "wall"
        kinematicPhysics(bar, shape: .generateBox(width: length, height: 0.05, depth: 0.05))
        barPivot.addChild(bar)

        animated.append(AnimatedObstacle(kind: .rotor(speed: speed, baseY: baseY), entity: barPivot))
    }

    // MARK: Moving block

    private static func buildMovingBlock(center: SIMD2<Float>, axis: SIMD2<Float>,
                                         amplitude: Float, speed: Float, size: SIMD2<Float>,
                                         baseY: Float, theme: CourseTheme, into root: Entity,
                                         animated: inout [AnimatedObstacle]) {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: theme.accent)
        material.roughness = 0.5
        if theme.emissiveWalls {
            material.emissiveColor = .init(color: theme.accent)
            material.emissiveIntensity = 1.2
        }
        let block = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.1, depth: size.y, cornerRadius: 0.012),
            materials: [material]
        )
        block.name = "wall"
        let center3 = SIMD3(center.x, baseY + 0.05, center.y)
        block.position = center3
        kinematicPhysics(block, shape: .generateBox(width: size.x, height: 0.1, depth: size.y))
        root.addChild(block)

        animated.append(AnimatedObstacle(
            kind: .movingBlock(center: center3,
                               axis: simd_normalize(SIMD3(axis.x, 0, axis.y)),
                               amplitude: amplitude, speed: speed),
            entity: block))
    }

    // MARK: Bumper, post, bump

    private static func buildBumper(center: SIMD2<Float>, radius: Float, index: Int,
                                    theme: CourseTheme, into root: Entity,
                                    bumperNames: inout Set<String>) {
        let name = "bumper-\(index)"
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: theme.accent)
        material.roughness = 0.4
        material.emissiveColor = .init(color: theme.accent)
        material.emissiveIntensity = theme.emissiveWalls ? 1.8 : 0.4

        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.09, radius: radius),
            materials: [material]
        )
        body.name = name
        body.position = SIMD3(center.x, 0.045, center.y)
        body.components.set(CollisionComponent(shapes: [
            .generateConvex(from: .generateCylinder(height: 0.09, radius: radius))
        ]))
        body.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.bumperMaterial, mode: .static))
        root.addChild(body)

        let cap = ModelEntity(
            mesh: .generateCylinder(height: 0.012, radius: radius * 0.85),
            materials: [SceneBuilder.simpleMaterial(UIColor(white: 0.95, alpha: 1), roughness: 0.35)]
        )
        cap.position.y = 0.05
        body.addChild(cap)

        bumperNames.insert(name)
    }

    private static func buildPost(center: SIMD2<Float>, radius: Float,
                                  theme: CourseTheme, into root: Entity) {
        let emissive = theme.emissiveWalls
        let color = emissive ? theme.wallTopColor : UIColor(white: 0.93, alpha: 1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = 0.55
        if emissive {
            material.emissiveColor = .init(color: color)
            material.emissiveIntensity = 1.6
        }
        let post = ModelEntity(
            mesh: .generateCylinder(height: 0.11, radius: radius),
            materials: [material]
        )
        post.name = "wall"
        post.position = SIMD3(center.x, 0.055, center.y)
        post.components.set(CollisionComponent(shapes: [
            .generateConvex(from: .generateCylinder(height: 0.11, radius: radius))
        ]))
        post.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.wallMaterial, mode: .static))
        root.addChild(post)

        if !emissive {
            let cap = ModelEntity(
                mesh: .generateSphere(radius: radius * 1.05),
                materials: [SceneBuilder.simpleMaterial(theme.accent, roughness: 0.5)]
            )
            cap.position.y = 0.06
            post.addChild(cap)
        }
    }

    private static func buildBump(center: SIMD2<Float>, width: Float, height: Float,
                                  yaw: Float, materials: ThemeMaterials, into root: Entity) {
        // A crest only as tall as `height` shows above the felt; the cylinder it
        // is cut from is buried deep, so the ball meets a ~22° rise instead of a
        // near-vertical lip. A radius near the ball's own would just be a wall.
        let crest = max(0.01, height)
        let radius = crest * 12
        let span = max(0.05, width - 0.008)   // tuck the end caps under the boards

        // Plain felt rather than mowing stripes: the tiling of a barely-exposed
        // cylinder cap never lines up with the lane, and a flat lighter tone
        // reads as a mound.
        let mesh = MeshResource.generateCylinder(height: span, radius: radius)
        let bump = ModelEntity(mesh: mesh, materials: [materials.bumpCrest])
        bump.name = "bumpCrest"
        bump.position = SIMD3(center.x, crest - radius, center.y)
        bump.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0)) *
                           simd_quatf(angle: .pi / 2, axis: SIMD3(0, 0, 1))
        bump.components.set(CollisionComponent(shapes: [.generateConvex(from: mesh)]))
        bump.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.floorMaterial, mode: .static))
        root.addChild(bump)
    }

    // MARK: Ramp, block, tunnel

    private static func buildRamp(center: SIMD2<Float>, width: Float, length: Float,
                                  rise: Float, yaw: Float, materials: ThemeMaterials,
                                  into root: Entity) {
        let angle = atan2(rise, length)
        let thickness: Float = 0.05
        // The slab keeps going past its foot, sinking under the lower floor. A
        // bare leading edge sitting exactly at floor level is a knife edge: a
        // ball arriving at speed catches it and is thrown upwards at the edge's
        // normal instead of driving up the slope.
        let buried: Float = 0.2
        let slabLength = sqrt(length * length + rise * rise) + buried

        let slab = ModelEntity(
            mesh: .generateBox(width: width, height: thickness, depth: slabLength),
            materials: [materials.felt(size: SIMD2(width, slabLength))]
        )
        slab.name = "ramp"
        let spin = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
        let normal = spin.act(SIMD3<Float>(0, cos(angle), sin(angle)))
        let downhill = spin.act(SIMD3<Float>(0, -sin(angle), cos(angle)))
        // At the top the ball rides a hair below the upper green — its centre sits
        // square to the slope, not to the world — and clips that green's leading
        // edge head-on. A few millimetres of lift carries it clear; the ball drops
        // the same few millimetres onto the plateau instead.
        let lift: Float = 0.005
        // Surface midpoint (shifted for the buried tail) minus half the thickness.
        let surfaceMid = SIMD3(center.x, rise / 2 + lift, center.y) + downhill * (buried / 2)
        slab.position = surfaceMid - normal * (thickness / 2)
        slab.orientation = spin * simd_quatf(angle: angle, axis: SIMD3(1, 0, 0))
        slab.components.set(CollisionComponent(shapes: [
            .generateBox(width: width, height: thickness, depth: slabLength)
        ]))
        slab.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.floorMaterial, mode: .static))
        root.addChild(slab)
    }

    private static func buildBlock(center: SIMD2<Float>, size: SIMD3<Float>, yaw: Float,
                                   baseY: Float, materials: ThemeMaterials, into root: Entity) {
        let block = ModelEntity(
            mesh: .generateBox(width: size.x, height: size.y, depth: size.z, cornerRadius: 0.008),
            materials: [materials.wall]
        )
        block.name = "wall"
        block.position = SIMD3(center.x, baseY + size.y / 2, center.y)
        block.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
        staticPhysics(block, shape: .generateBox(width: size.x, height: size.y, depth: size.z))
        root.addChild(block)
    }

    // MARK: Slopes and belts

    /// Chevron made of two angled bars, pointing along local +Z.
    private static func chevron(size: Float, material: UnlitMaterial) -> Entity {
        let group = Entity()
        for side: Float in [-1, 1] {
            let bar = ModelEntity(
                mesh: .generateBox(width: size, height: 0.004, depth: 0.012, cornerRadius: 0.002),
                materials: [material])
            bar.position = SIMD3(side * size * 0.33, 0, -size * 0.26)
            bar.orientation = simd_quatf(angle: side * 0.72, axis: SIMD3(0, 1, 0))
            group.addChild(bar)
        }
        return group
    }

    /// Yaw that turns local +Z into `direction` on the XZ plane.
    private static func yaw(for direction: SIMD2<Float>) -> Float {
        atan2(direction.x, direction.y)
    }

    /// Banked green: a translucent wash with a sparse row of drift arrows. The
    /// push itself comes from the force zone the coordinator applies.
    private static func buildSlope(rect: GroundRect, direction: SIMD2<Float>, strength: Float,
                                   y: Float, materials: ThemeMaterials, into root: Entity,
                                   outputs: inout ObstacleOutputs) {
        let size = rect.size
        let skin = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.005, depth: size.y, cornerRadius: 0.004),
            materials: [materials.slopeTint])
        skin.name = "slope"
        skin.position = SIMD3(rect.center.x, y + 0.0016, rect.center.y)
        root.addChild(skin)

        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(1, 0)
        let arrows = Entity()
        arrows.position = SIMD3(rect.center.x, y + 0.005, rect.center.y)
        arrows.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))
        // Two rows across the zone read as a gradient without hiding the felt.
        for row in -1...1 where row != 0 {
            let mark = chevron(size: 0.1, material: materials.chevron)
            mark.position = SIMD3(Float(row) * min(size.x, size.y) * 0.22, 0, 0)
            arrows.addChild(mark)
        }
        root.addChild(arrows)

        // A bank only creeps: a ball that stops on one is nudged on its way
        // rather than carried, the way it would trickle down a real slope.
        outputs.forceZones.append(ForceZone(
            rect: rect, y: y, force: unit * strength * GamePhysics.ballMass,
            carry: unit * (strength * 0.28)))
    }

    /// Belt: a recessed bed with chevrons riding along it, plus a much stronger
    /// force zone than a slope.
    private static func buildConveyor(rect: GroundRect, direction: SIMD2<Float>, strength: Float,
                                      y: Float, materials: ThemeMaterials, into root: Entity,
                                      outputs: inout ObstacleOutputs) {
        let size = rect.size
        let bed = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.006, depth: size.y, cornerRadius: 0.004),
            materials: [materials.beltBed])
        bed.name = "belt"
        bed.position = SIMD3(rect.center.x, y + 0.0018, rect.center.y)
        root.addChild(bed)

        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(1, 0)
        let travel = abs(unit.x) * size.x + abs(unit.y) * size.y
        // The speed of the bed itself: the chevrons run at it, and so does a
        // ball the belt has picked up.
        let running = max(0.35, strength * 0.45)
        let belt = Entity()
        belt.position = SIMD3(rect.center.x, y + 0.007, rect.center.y)
        belt.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))
        let across = abs(unit.x) * size.y + abs(unit.y) * size.x
        let lanes = max(1, Int((across / 0.3).rounded()))
        for lane in 0..<lanes {
            let offset = across * (Float(lane) + 0.5) / Float(lanes) - across / 2
            let rider = Entity()
            rider.position.x = offset
            belt.addChild(rider)
            // Each lane is its own animated strip so the chevrons stay in step.
            let strip = Entity()
            for _ in 0..<3 {
                strip.addChild(chevron(size: 0.11, material: materials.chevron))
            }
            rider.addChild(strip)
            outputs.animated.append(AnimatedObstacle(
                kind: .belt(length: travel, speed: running), entity: strip))
        }
        root.addChild(belt)

        outputs.forceZones.append(ForceZone(
            rect: rect, y: y, force: unit * strength * GamePhysics.ballMass,
            carry: unit * running))
    }

    // MARK: Teleporter

    private static func buildTeleporter(a: SIMD2<Float>, b: SIMD2<Float>, radius: Float,
                                        y: Float, materials: ThemeMaterials, into root: Entity,
                                        outputs: inout ObstacleOutputs) {
        for center in [a, b] {
            let group = Entity()
            group.name = "portal"
            group.position = SIMD3(center.x, y + 0.004, center.y)

            let core = ModelEntity(
                mesh: .generateCylinder(height: 0.004, radius: radius * 0.82),
                materials: [materials.portalCore])
            group.addChild(core)

            // Six pegs around the rim: cheap, and the rotation sells the swirl.
            let ring = Entity()
            for i in 0..<6 {
                let peg = ModelEntity(
                    mesh: .generateBox(width: 0.026, height: 0.03, depth: 0.026,
                                       cornerRadius: 0.006),
                    materials: [materials.portalRim])
                let angle = Float(i) * .pi / 3
                peg.position = SIMD3(cos(angle) * radius, 0.012, sin(angle) * radius)
                ring.addChild(peg)
            }
            group.addChild(ring)
            outputs.animated.append(AnimatedObstacle(
                kind: .spin(speed: 0.9, baseY: 0, bob: 0), entity: ring))

            root.addChild(group)
        }

        outputs.portals.append(Portal(a: a, b: b, radius: radius, y: y))
    }

    // MARK: Gate

    private static func buildGate(center: SIMD2<Float>, size: SIMD2<Float>, yaw: Float,
                                  period: Float, phase: Float, baseY: Float,
                                  theme: CourseTheme, materials: ThemeMaterials,
                                  into root: Entity, animated: inout [AnimatedObstacle]) {
        let height: Float = 0.13
        // The frame stays put so the player can read where the gate will appear.
        let frame = ModelEntity(
            mesh: .generateBox(width: size.x + 0.06, height: 0.02, depth: size.y + 0.05,
                               cornerRadius: 0.006),
            materials: [materials.metal])
        frame.position = SIMD3(center.x, baseY + 0.002, center.y)
        frame.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
        root.addChild(frame)

        var barMaterial = PhysicallyBasedMaterial()
        barMaterial.baseColor = .init(tint: theme.accent)
        barMaterial.roughness = 0.4
        barMaterial.metallic = 0.5
        if theme.emissiveWalls {
            barMaterial.emissiveColor = .init(color: theme.accent)
            barMaterial.emissiveIntensity = 1.3
        }

        let gate = ModelEntity(
            mesh: .generateBox(width: size.x, height: height, depth: size.y, cornerRadius: 0.008),
            materials: [barMaterial])
        gate.name = "wall"
        let base = SIMD3(center.x, baseY + height / 2, center.y)
        gate.position = base
        gate.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
        kinematicPhysics(gate, shape: .generateBox(width: size.x, height: height, depth: size.y))
        root.addChild(gate)

        // Sink far enough that the crown clears the felt when open.
        animated.append(AnimatedObstacle(
            kind: .gate(base: base, drop: height + 0.02, period: period, phase: phase),
            entity: gate))
    }

    // MARK: Pendulum

    private static func buildPendulum(center: SIMD2<Float>, span: Float, arc: Float,
                                      speed: Float, yaw: Float, baseY: Float,
                                      theme: CourseTheme, materials: ThemeMaterials,
                                      into root: Entity, animated: inout [AnimatedObstacle]) {
        let pivotHeight: Float = 0.42
        let armLength: Float = 0.36

        // The arm hangs from a small anchor above the lane rather than from a
        // gantry: any leg tall enough to carry the pivot would stand in exactly
        // the gap the player is trying to putt through.
        let anchor = ModelEntity(
            mesh: .generateBox(width: 0.09, height: 0.05, depth: 0.09, cornerRadius: 0.012),
            materials: [materials.metal])
        anchor.position = SIMD3(center.x, baseY + pivotHeight + 0.03, center.y)
        root.addChild(anchor)

        // Swinging arm. Its pivot sits at the anchor, the bob just above the felt.
        let pivot = Entity()
        pivot.name = "pendulumPivot"
        pivot.position = SIMD3(center.x, baseY + pivotHeight, center.y)
        pivot.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))

        let swing = Entity()
        pivot.addChild(swing)

        let rod = ModelEntity(
            mesh: .generateCylinder(height: armLength, radius: 0.012),
            materials: [SceneBuilder.simpleMaterial(theme.wallTopColor, roughness: 0.8)])
        rod.position = SIMD3(0, -armLength / 2, 0)
        swing.addChild(rod)

        var bobMaterial = PhysicallyBasedMaterial()
        bobMaterial.baseColor = .init(tint: theme.accent)
        bobMaterial.roughness = 0.45
        if theme.emissiveWalls {
            bobMaterial.emissiveColor = .init(color: theme.accent)
            bobMaterial.emissiveIntensity = 1.2
        }
        // The bob lies along the swing direction, so it sweeps a wide band of
        // the lane instead of a thin line.
        let bob = ModelEntity(
            mesh: .generateBox(width: span, height: 0.07, depth: 0.07, cornerRadius: 0.02),
            materials: [bobMaterial])
        bob.name = "wall"
        bob.position = SIMD3(0, -armLength + 0.005, 0)
        kinematicPhysics(bob, shape: .generateBox(width: span, height: 0.07, depth: 0.07))
        swing.addChild(bob)

        root.addChild(pivot)
        animated.append(AnimatedObstacle(kind: .pendulum(arc: arc, speed: speed), entity: swing))
    }

    // MARK: Boost pad

    private static func buildBoostPad(center: SIMD2<Float>, direction: SIMD2<Float>,
                                      boost: Float, y: Float, materials: ThemeMaterials,
                                      into root: Entity, outputs: inout ObstacleOutputs) {
        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(0, -1)
        let pad = Entity()
        pad.name = "boostPad"
        pad.position = SIMD3(center.x, y + 0.002, center.y)
        pad.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))

        let bed = ModelEntity(
            mesh: .generateBox(width: 0.19, height: 0.005, depth: 0.19, cornerRadius: 0.03),
            materials: [materials.beltBed])
        pad.addChild(bed)

        for i in 0..<2 {
            let mark = chevron(size: 0.13, material: materials.chevron)
            mark.position = SIMD3(0, 0.005, Float(i) * 0.06 - 0.03)
            pad.addChild(mark)
        }
        root.addChild(pad)

        outputs.boostPads.append(BoostPad(center: center, direction: unit, boost: boost, y: y))
    }

    // MARK: Loop

    /// Loop-the-loop. Only the track is built here — the ball is walked around
    /// it by the coordinator — plus the run-up strips that show which way it
    /// goes and the two boards that funnel the putt into the entrance.
    ///
    /// The track is stretched along the lane by one pitch: it leaves the felt at
    /// the entrance, winds once around and touches down again at the exit, the
    /// two ends crossing over each other low down exactly the way a toy loop is
    /// built. A closed circle would put the exit back on top of the entrance and
    /// stand on the lane like a hoop with no way in or out.
    private static func buildLoop(center: SIMD2<Float>, radius: Float, width: Float,
                                  yaw: Float, y: Float, theme: CourseTheme,
                                  materials: ThemeMaterials, into root: Entity,
                                  outputs: inout ObstacleOutputs) {
        let halfWidth = max(0.06, width / 2)
        let pitch = LoopShape.pitch(radius: radius)
        let group = Entity()
        group.name = "loop"
        // Local frame: +Z runs along the lane, +Y is up and the origin sits on
        // the felt halfway between the two mouths.
        group.position = SIMD3(center.x, y, center.y)
        group.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))

        var railMaterial = PhysicallyBasedMaterial()
        railMaterial.baseColor = .init(tint: theme.accent)
        railMaterial.roughness = 0.35
        railMaterial.metallic = 0.7
        if theme.emissiveWalls {
            railMaterial.emissiveColor = .init(color: theme.accent)
            railMaterial.emissiveIntensity = 1.5
        }
        let bandThickness: Float = 0.014
        // Half the band, plus a hair of clearance so the track does not fight
        // the felt where it flattens out into the mouths.
        let bandOffset = bandThickness / 2 + 0.0015
        let railOffset = halfWidth + 0.013
        let railWidth: Float = 0.022
        let railHeight: Float = 0.026

        /// Places a piece of track: `theta` is measured from the entrance and
        /// the piece's inner face ends up exactly on the running surface.
        func place(_ entity: ModelEntity, theta: Float, lateral: Float) {
            let point = LoopShape.point(theta: theta, radius: radius, pitch: pitch)
            let tangent = LoopShape.tangent(theta: theta, radius: radius, pitch: pitch)
            let slope = atan2(tangent.y, tangent.x)
            // Outward normal: the direction of travel turned a quarter turn.
            let seat = point + SIMD2(sin(slope), -cos(slope)) * bandOffset
            entity.position = SIMD3(lateral, seat.y, seat.x)
            entity.orientation = simd_quatf(angle: -slope, axis: SIMD3(1, 0, 0))
            group.addChild(entity)
        }

        // The whole turn is swept, mouth to mouth. Both ends run out flat and
        // sink under the felt on their own, so there is no knife edge left to
        // saw through a ball that is 7 cm across.
        //
        // Two rails and a ladder of ties, not a solid band: a closed sleeve of
        // track hides its own far side and the loop ends up looking like a
        // barrel, while through a ladder the ball can be watched all the way
        // round — which is the whole point of a loop.
        let segments = 36
        let step = 2 * Float.pi / Float(segments)
        for i in 0..<segments {
            let from = LoopShape.point(theta: Float(i) * step, radius: radius, pitch: pitch)
            let to = LoopShape.point(theta: Float(i + 1) * step, radius: radius, pitch: pitch)
            let chord = simd_distance(from, to) + 0.005
            let theta = (Float(i) + 0.5) * step
            if i % 2 == 0 {
                place(ModelEntity(mesh: .generateBox(width: halfWidth * 2,
                                                     height: bandThickness,
                                                     depth: chord * 0.55),
                                  materials: [materials.beltBed]),
                      theta: theta, lateral: 0)
            }
            for side: Float in [-1, 1] {
                place(ModelEntity(mesh: .generateBox(width: railWidth, height: railHeight,
                                                     depth: chord, cornerRadius: 0.006),
                                  materials: [railMaterial]),
                      theta: theta, lateral: side * railOffset)
            }
        }

        // Run-up and run-out: a strip laid on the felt with a rail down each
        // side, so which end the ball goes in and which it comes out of can be
        // read at a glance. Decoration only — the guide boards do the blocking.
        let lead: Float = 0.16
        for end: Float in [-1, 1] {
            let mid = end * (pitch / 2 + lead / 2)
            let strip = ModelEntity(
                mesh: .generateBox(width: halfWidth * 2, height: 0.004, depth: lead),
                materials: [materials.beltBed])
            strip.position = SIMD3(0, 0.002, mid)
            group.addChild(strip)
            for side: Float in [-1, 1] {
                let rail = ModelEntity(
                    mesh: .generateBox(width: railWidth, height: railHeight, depth: lead,
                                       cornerRadius: 0.006),
                    materials: [railMaterial])
                rail.position = SIMD3(side * railOffset, 0.006, mid)
                group.addChild(rail)
            }
        }
        root.addChild(group)

        // Guide boards down both sides of the whole run.
        let axis = SIMD2(sin(yaw), cos(yaw))
        let across = SIMD2(cos(yaw), -sin(yaw))
        let boardLength = pitch + 2 * lead
        for side: Float in [-1, 1] {
            let mid = center + across * (side * (halfWidth + 0.028))
            let board = ModelEntity(
                mesh: .generateBox(width: 0.055, height: 0.085, depth: boardLength,
                                   cornerRadius: 0.008),
                materials: [materials.wall])
            board.name = "wall"
            board.position = SIMD3(mid.x, y + 0.0425, mid.y)
            board.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            staticPhysics(board, shape: .generateBox(width: 0.055, height: 0.085,
                                                     depth: boardLength))
            root.addChild(board)
        }

        outputs.loops.append(LoopTrack(center: center, radius: radius, axis: axis,
                                       halfWidth: halfWidth, y: y))
    }

    // MARK: Launch pad

    /// Kicker wedge. Like the boost pad it carries no collider: a 5 cm lip built
    /// out of real geometry either stops the ball dead or flips it, while the
    /// coordinator can hand every jump the same speed and the same arc.
    private static func buildLaunchPad(center: SIMD2<Float>, direction: SIMD2<Float>,
                                       speed: Float, lift: Float, y: Float,
                                       theme: CourseTheme, materials: ThemeMaterials,
                                       into root: Entity, outputs: inout ObstacleOutputs) {
        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(0, -1)
        let length: Float = 0.24
        let rise: Float = 0.055
        let pad = Entity()
        pad.name = "launchPad"
        pad.position = SIMD3(center.x, y, center.y)
        pad.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))

        let angle = atan2(rise, length)
        let slab = ModelEntity(
            mesh: .generateBox(width: 0.22, height: 0.014, depth: length + 0.03,
                               cornerRadius: 0.004),
            materials: [materials.metal])
        slab.position = SIMD3(0, rise / 2, 0)
        slab.orientation = simd_quatf(angle: -angle, axis: SIMD3(1, 0, 0))
        pad.addChild(slab)

        // Cheeks along the sides read as a ramp rather than a floating plate.
        for side: Float in [-1, 1] {
            let cheek = ModelEntity(
                mesh: .generateBox(width: 0.014, height: rise, depth: length,
                                   cornerRadius: 0.004),
                materials: [materials.beltBed])
            cheek.position = SIMD3(side * 0.115, rise / 2 - 0.004, 0)
            cheek.orientation = simd_quatf(angle: -angle, axis: SIMD3(1, 0, 0))
            pad.addChild(cheek)
        }

        var lipMaterial = PhysicallyBasedMaterial()
        lipMaterial.baseColor = .init(tint: theme.accent)
        lipMaterial.roughness = 0.4
        if theme.emissiveWalls {
            lipMaterial.emissiveColor = .init(color: theme.accent)
            lipMaterial.emissiveIntensity = 1.4
        }
        let lip = ModelEntity(
            mesh: .generateBox(width: 0.22, height: 0.016, depth: 0.02, cornerRadius: 0.005),
            materials: [lipMaterial])
        lip.position = SIMD3(0, rise + 0.006, length / 2)
        pad.addChild(lip)

        for i in 0..<2 {
            let mark = chevron(size: 0.12, material: materials.chevron)
            mark.position = SIMD3(0, 0.012 + Float(i) * 0.028, Float(i) * 0.08 - 0.06)
            pad.addChild(mark)
        }
        root.addChild(pad)

        outputs.launchPads.append(LaunchPad(center: center, direction: unit, speed: speed,
                                            lift: lift, y: y))
    }

    // MARK: Cannon

    private static func buildCannon(center: SIMD2<Float>, direction: SIMD2<Float>,
                                    speed: Float, y: Float, theme: CourseTheme,
                                    materials: ThemeMaterials, into root: Entity,
                                    outputs: inout ObstacleOutputs) {
        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(0, -1)
        let mouth: Float = 0.1
        let group = Entity()
        group.name = "cannon"
        group.position = SIMD3(center.x, y, center.y)
        group.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))

        // Loading plate. Nothing here collides — the ball is swallowed by the
        // zone before it could touch anything, from whichever side it rolls in.
        let plate = ModelEntity(
            mesh: .generateCylinder(height: 0.006, radius: mouth),
            materials: [materials.beltBed])
        plate.position.y = 0.003
        group.addChild(plate)

        // Collar around the plate, left open toward the barrel.
        for i in 0..<10 {
            let angle = Float(i) * .pi / 5
            guard abs(sin(angle)) > 0.35 || cos(angle) < 0 else { continue }
            let peg = ModelEntity(
                mesh: .generateBox(width: 0.026, height: 0.03, depth: 0.026, cornerRadius: 0.006),
                materials: [materials.metal])
            peg.position = SIMD3(cos(angle) * mouth, 0.015, sin(angle) * mouth)
            group.addChild(peg)
        }

        var barrelMaterial = PhysicallyBasedMaterial()
        barrelMaterial.baseColor = .init(tint: theme.accent)
        barrelMaterial.roughness = 0.4
        barrelMaterial.metallic = 0.6
        if theme.emissiveWalls {
            barrelMaterial.emissiveColor = .init(color: theme.accent)
            barrelMaterial.emissiveIntensity = 1.2
        }
        let barrel = ModelEntity(
            mesh: .generateCylinder(height: 0.2, radius: 0.05),
            materials: [barrelMaterial])
        barrel.name = "cannonBarrel"
        barrel.position = SIMD3(0, 0.05, mouth + 0.06)
        barrel.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        group.addChild(barrel)

        let muzzle = ModelEntity(
            mesh: .generateCylinder(height: 0.022, radius: 0.06),
            materials: [materials.metal])
        muzzle.position = SIMD3(0, 0.05, mouth + 0.15)
        muzzle.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        group.addChild(muzzle)
        root.addChild(group)

        outputs.cannons.append(Cannon(center: center, direction: unit, speed: speed,
                                      y: y, radius: mouth))
    }

    // MARK: Turntable

    private static func buildTurntable(center: SIMD2<Float>, radius: Float, speed: Float,
                                       y: Float, materials: ThemeMaterials, into root: Entity,
                                       outputs: inout ObstacleOutputs) {
        let disc = Entity()
        disc.name = "turntable"
        disc.position = SIMD3(center.x, y + 0.0018, center.y)

        let bed = ModelEntity(
            mesh: .generateCylinder(height: 0.006, radius: radius),
            materials: [materials.beltBed])
        disc.addChild(bed)

        // Spokes turn a flat disc into something the eye can follow round.
        for i in 0..<6 {
            let spoke = ModelEntity(
                mesh: .generateBox(width: radius * 0.9, height: 0.005, depth: 0.022,
                                   cornerRadius: 0.004),
                materials: [materials.chevron])
            spoke.position = SIMD3(cos(Float(i) * .pi / 3) * radius * 0.45, 0.005,
                                   sin(Float(i) * .pi / 3) * radius * 0.45)
            spoke.orientation = simd_quatf(angle: -Float(i) * .pi / 3, axis: SIMD3(0, 1, 0))
            disc.addChild(spoke)
        }
        let hub = ModelEntity(
            mesh: .generateCylinder(height: 0.012, radius: radius * 0.16),
            materials: [materials.metal])
        hub.position.y = 0.008
        disc.addChild(hub)

        root.addChild(disc)
        outputs.animated.append(AnimatedObstacle(
            kind: .spin(speed: speed, baseY: y + 0.0018, bob: 0), entity: disc))
        outputs.turntables.append(Turntable(center: center, radius: radius, speed: speed, y: y))
    }

    // MARK: Magnet

    private static func buildMagnet(center: SIMD2<Float>, radius: Float, strength: Float,
                                    y: Float, theme: CourseTheme, materials: ThemeMaterials,
                                    into root: Entity, outputs: inout ObstacleOutputs) {
        let group = Entity()
        group.name = "magnet"
        group.position = SIMD3(center.x, y + 0.002, center.y)

        let core = ModelEntity(
            mesh: .generateCylinder(height: 0.008, radius: radius * 0.13),
            materials: [materials.portalCore])
        core.position.y = 0.004
        group.addChild(core)

        // Every ring carries the same number of pegs at the same spacing, so a
        // travelling ring lines up with the rim as it passes instead of reading
        // as loose confetti.
        let pegs = 14
        func ring(fraction: Float, material: any RealityKit.Material) -> Entity {
            let entity = Entity()
            for i in 0..<pegs {
                let angle = Float(i) * 2 * .pi / Float(pegs)
                let peg = ModelEntity(
                    mesh: .generateBox(width: 0.022, height: 0.008, depth: 0.022,
                                       cornerRadius: 0.004),
                    materials: [material])
                peg.position = SIMD3(cos(angle) * radius * fraction, 0.004,
                                     sin(angle) * radius * fraction)
                entity.addChild(peg)
            }
            return entity
        }

        // The rim marks where the field ends.
        group.addChild(ring(fraction: 0.94, material: materials.beltBed))

        // Two rings sliding along the field: inward when the magnet pulls,
        // outward when it pushes. That travel is the only cue the player gets,
        // so it always matches the sign of the force.
        for phase: Float in [0, 0.5] {
            let travelling = ring(fraction: 0.94, material: materials.chevron)
            group.addChild(travelling)
            outputs.animated.append(AnimatedObstacle(
                kind: .pulse(from: strength >= 0 ? 1 : 0.15, to: strength >= 0 ? 0.15 : 1,
                             speed: 0.5, phase: phase),
                entity: travelling))
        }
        root.addChild(group)

        outputs.magnets.append(MagnetField(center: center, radius: radius,
                                           strength: strength, y: y))
    }

    // MARK: Fan

    private static func buildFan(rect: GroundRect, direction: SIMD2<Float>, strength: Float,
                                 period: Float, phase: Float, y: Float,
                                 materials: ThemeMaterials, into root: Entity,
                                 outputs: inout ObstacleOutputs) {
        let unit = simd_length(direction) > 0 ? simd_normalize(direction) : SIMD2(0, -1)
        let size = rect.size

        let skin = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.005, depth: size.y, cornerRadius: 0.004),
            materials: [materials.slopeTint])
        skin.name = "wind"
        skin.position = SIMD3(rect.center.x, y + 0.0016, rect.center.y)
        root.addChild(skin)

        let arrows = Entity()
        arrows.position = SIMD3(rect.center.x, y + 0.005, rect.center.y)
        arrows.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))
        for row in -1...1 where row != 0 {
            let mark = chevron(size: 0.11, material: materials.chevron)
            mark.position = SIMD3(Float(row) * min(size.x, size.y) * 0.24, 0, 0)
            arrows.addChild(mark)
        }
        root.addChild(arrows)

        // The housing stands off the upwind edge, clear of the felt, and high
        // enough that a ball blown past it rolls underneath.
        let reach = abs(unit.x) * size.x + abs(unit.y) * size.y
        let anchor = rect.center - unit * (reach / 2 + 0.17)
        let tower = Entity()
        tower.position = SIMD3(anchor.x, y, anchor.y)
        tower.orientation = simd_quatf(angle: yaw(for: unit), axis: SIMD3(0, 1, 0))

        let post = ModelEntity(
            mesh: .generateCylinder(height: 0.3, radius: 0.018),
            materials: [materials.metal])
        post.position.y = 0.12
        tower.addChild(post)

        let housing = ModelEntity(
            mesh: .generateBox(width: 0.1, height: 0.1, depth: 0.06, cornerRadius: 0.02),
            materials: [materials.metal])
        housing.position = SIMD3(0, 0.27, -0.03)
        tower.addChild(housing)

        let blades = Entity()
        blades.position = SIMD3(0, 0.27, 0.01)
        for i in 0..<4 {
            let blade = ModelEntity(
                mesh: .generateBox(width: 0.036, height: 0.15, depth: 0.008,
                                   cornerRadius: 0.014),
                materials: [materials.accent])
            blade.position = SIMD3(0, 0.08, 0)
            let holder = Entity()
            holder.orientation = simd_quatf(angle: Float(i) * .pi / 2, axis: SIMD3(0, 0, 1))
            holder.addChild(blade)
            blades.addChild(holder)
        }
        tower.addChild(blades)
        root.addChild(tower)

        outputs.animated.append(AnimatedObstacle(
            kind: .gustBlades(speed: 9, period: period, phase: phase), entity: blades))
        outputs.windZones.append(WindZone(rect: rect, direction: unit, strength: strength,
                                          period: period, phase: phase, y: y))
    }

    private static func buildTunnel(center: SIMD2<Float>, width: Float, length: Float,
                                    yaw: Float, materials: ThemeMaterials, into root: Entity) {
        let group = Entity()
        group.position = SIMD3(center.x, 0, center.y)
        group.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))

        let sideHeight: Float = 0.16
        for side: Float in [-1, 1] {
            let sideWall = ModelEntity(
                mesh: .generateBox(width: 0.05, height: sideHeight, depth: length),
                materials: [materials.wall]
            )
            sideWall.name = "wall"
            sideWall.position = SIMD3(side * (width / 2 + 0.025), sideHeight / 2, 0)
            staticPhysics(sideWall, shape: .generateBox(width: 0.05, height: sideHeight, depth: length))
            group.addChild(sideWall)
        }
        let roof = ModelEntity(
            mesh: .generateBox(width: width + 0.1, height: 0.04, depth: length),
            materials: [materials.wall]
        )
        roof.position = SIMD3(0, sideHeight + 0.02, 0)
        group.addChild(roof)
        root.addChild(group)
    }
}
