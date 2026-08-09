//
//  Critters.swift
//  Minigolf
//
//  The locals: two characters for every world, built out of the same handful of
//  primitives the rest of the scene uses, and walked around the felt by hand.
//
//  They are deliberately not decorations. A critter carries a kinematic body, so
//  a putt banks off it and one that walks into a ball at rest shoves it along —
//  which is the whole point. The path is a closed formula of the level clock, so
//  a character is always in the same place at the same moment and a shot that
//  was timed right once can be timed right again.
//

import Foundation
import RealityKit
import UIKit
import simd

// MARK: - Runtime

/// The traits that change how a character is carried along its path. Everything
/// else about a critter — what it looks like, how big it is — is fixed by kind.
struct CritterStyle {
    /// Turns to face the way it is going. A tumbleweed has no front, and a
    /// burrower only ever looks about.
    var facesTravel = true
    /// Rolls along the ground instead of walking.
    var rolls = false
    /// Yaw between "facing forward" and the way the model was built: a crab
    /// scuttles sideways.
    var facingOffset: Float = 0
    /// How far the character bounces with each step, and how far it leans into
    /// it. Together they are the difference between a walk and a slide.
    var bob: Float = 0.008
    var lean: Float = 0.12
    /// Slow float for the ones that never touch the ground.
    var hover: Float = 0
}

/// One character on its rounds.
final class Critter {

    /// Walks, hops and sinks; the character hangs underneath it.
    let root = Entity()
    /// The body the ball meets. It carries the knock and the step, so being hit
    /// rocks the character without disturbing where its path says it should be.
    let body = ModelEntity()
    /// The character itself, one level further in. A roll has to turn about the
    /// middle of the ball of twigs, not about the patch of felt underneath it —
    /// spun around the body's own origin, half of every turn is spent buried in
    /// the floor. Everyone else leaves this sitting at the origin.
    let art = Entity()

    let kind: CritterKind
    private let motion: CritterMotion
    private let origin: SIMD3<Float>
    private let speed: Float
    private let phase: Float
    private let style: CritterStyle
    /// How far a burrower drops. The solver answers anything within a couple of
    /// centimetres of the ball, so "gone under" has to mean the whole body plus
    /// a margin — otherwise a ball rolling over the spot trips on a character
    /// nobody can see.
    private let sinkDepth: Float

    /// Seconds of wobble left after a knock, and the direction the ball shoved
    /// it in, in world space.
    private var knock: Float = 0
    private var knockDirection = SIMD3<Float>(0, 0, 1)
    /// Yaw the character is turning toward, so the end of a patrol reads as
    /// turning round rather than as a flicker.
    private var facing: Float

    init(kind: CritterKind, center: SIMD2<Float>, motion: CritterMotion,
         speed: Float, phase: Float, baseY: Float, style: CritterStyle) {
        self.kind = kind
        self.motion = motion
        self.origin = SIMD3(center.x, baseY, center.y)
        self.speed = speed
        self.phase = phase
        self.style = style
        self.sinkDepth = kind.height + 0.06

        // Something that never turns still has to be pointed somewhere sensible:
        // along its own path, so a rolling tumbleweed rolls the way it travels.
        switch motion {
        case .patrol(let axis, _), .hop(let axis, _, _):
            let unit = Critter.unit(axis, fallback: SIMD2(1, 0))
            facing = atan2(unit.x, unit.y) + style.facingOffset
        case .circle, .burrow:
            facing = style.facingOffset
        }

        root.name = "critter"
        root.position = origin
        root.orientation = simd_quatf(angle: facing, axis: SIMD3(0, 1, 0))
        root.addChild(body)
        art.position.y = style.rolls ? kind.height / 2 : 0
        body.addChild(art)
    }

    /// Walks the character to where the clock says it should be.
    func update(time: Float, dt: Float) {
        knock = max(0, knock - dt)

        let theta = time * speed + phase
        // Three steps per swing of the path: fast enough to read as walking,
        // slow enough not to buzz.
        let stride = theta * 3
        var offset = SIMD3<Float>.zero
        var heading = SIMD2<Float>(0, 1)
        var travelled: Float = 0
        var walking = true

        switch motion {
        case .patrol(let axis, let amplitude):
            let unit = Critter.unit(axis, fallback: SIMD2(1, 0))
            travelled = amplitude * sin(theta)
            offset = SIMD3(unit.x, 0, unit.y) * travelled
            heading = unit * (cos(theta) >= 0 ? 1 : -1)

        case .circle(let radius):
            offset = SIMD3(cos(theta) * radius, 0, sin(theta) * radius)
            heading = SIMD2(-sin(theta), cos(theta))
            travelled = radius * theta

        case .hop(let axis, let amplitude, let height):
            let unit = Critter.unit(axis, fallback: SIMD2(1, 0))
            let hop = Critter.hopCurve(theta: theta)
            travelled = amplitude * hop.along
            offset = SIMD3(unit.x, 0, unit.y) * travelled
            offset.y = height * hop.lift
            heading = unit * hop.direction
            // A hop is one long stride: the step bounce would fight the arc.
            walking = false

        case .burrow(let period):
            offset.y = -sinkDepth * AnimatedObstacle.openness(time: time, period: period,
                                                              phase: phase)
            // Looks about while it is up.
            let look = sin(time * 1.1 + phase) * 0.8
            heading = SIMD2(sin(look), cos(look))
            walking = false
        }

        if walking {
            offset.y += abs(sin(stride)) * style.bob
        }
        if style.hover > 0 {
            offset.y += style.hover * (1 + sin(time * 1.7 + phase)) / 2
        }
        root.position = origin + offset

        if style.facesTravel, simd_length(heading) > 0.0001 {
            let target = atan2(heading.x, heading.y) + style.facingOffset
            facing += Critter.angleDelta(from: facing, to: target) *
                      expLerpFactor(rate: 9, dt: dt)
        }
        root.orientation = simd_quatf(angle: facing, axis: SIMD3(0, 1, 0))

        // The body's own attitude: leaning into the step, with the knock laid on
        // top of it. A roller turns about its own middle instead, one level in.
        var attitude = simd_quatf(angle: 0, axis: SIMD3(0, 1, 0))
        if style.rolls {
            art.orientation = simd_quatf(angle: travelled / max(0.01, kind.height / 2),
                                         axis: SIMD3(1, 0, 0))
        } else if walking, style.lean > 0 {
            attitude = simd_quatf(angle: sin(stride) * style.lean, axis: SIMD3(0, 0, 1))
        }
        if knock > 0 {
            attitude = knockTilt() * attitude
        }
        body.orientation = attitude
    }

    /// Rocks the character. `direction` is the way the ball shoved it, in world
    /// space; it tips that way and springs back over about half a second.
    func hit(direction: SIMD3<Float>) {
        let flat = SIMD3(direction.x, 0, direction.z)
        guard simd_length(flat) > 0.0001 else { return }
        knockDirection = simd_normalize(flat)
        knock = 0.5
    }

    /// The tip itself, worked out in the body's own frame so it stays pointing
    /// the same way in the world while the character keeps walking.
    private func knockTilt() -> simd_quatf {
        let local = root.orientation.inverse.act(knockDirection)
        let flat = SIMD3(local.x, 0, local.z)
        guard simd_length(flat) > 0.0001 else { return simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)) }
        let unit = simd_normalize(flat)
        // Turning the up axis toward `unit` tips the character over that way.
        let axis = SIMD3(unit.z, 0, -unit.x)
        return simd_quatf(angle: sin(knock * 32) * knock * 0.8, axis: simd_normalize(axis))
    }

    // MARK: Path helpers

    private static func unit(_ vector: SIMD2<Float>, fallback: SIMD2<Float>) -> SIMD2<Float> {
        simd_length(vector) > 0.0001 ? simd_normalize(vector) : fallback
    }

    /// Sit, leap, sit again. One leg takes π of phase, so a hopper covers its
    /// path at the same pace a walker on the same `speed` would.
    private static func hopCurve(theta: Float) -> (along: Float, lift: Float, direction: Float) {
        let legs = theta / .pi
        let leg = legs.rounded(.down)
        let local = legs - leg
        let forward: Float = abs(leg.truncatingRemainder(dividingBy: 2)) < 0.5 ? 1 : -1
        // Crouched and still for the first part of the leg, then away.
        let hold: Float = 0.45
        let t = smoothstep((local - hold) / (1 - hold))
        return (-forward + 2 * forward * t, sin(.pi * t), forward)
    }

    /// Difference between two yaws, wrapped into −π…π, so turning round goes
    /// the short way about.
    private static func angleDelta(from: Float, to: Float) -> Float {
        var delta = (to - from).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        return delta
    }
}

// MARK: - Geometry

extension CritterKind {
    /// How tall the collider stands. Paired with `radius` in the level model,
    /// this is the whole of a critter as far as the ball is concerned — the
    /// modelled ears, claws and antennae are for the player, not the physics.
    var height: Float {
        switch self {
        case .snowman: return 0.19
        case .meerkat, .windupBot, .sentry, .alien: return 0.16
        case .penguin, .drone, .seagull, .cuckoo: return 0.14
        case .tumbleweed: return 0.15
        case .mole, .rover, .imp: return 0.12
        case .hedgehog, .frog, .turtle, .crab, .magmaBlob: return 0.09
        }
    }

    /// The bounce a putt gets off this one. A snowman is soft, a wind-up robot
    /// is not.
    var restitution: Float {
        switch self {
        case .snowman, .magmaBlob, .frog, .seagull, .alien: return 0.45
        case .windupBot, .rover, .sentry, .turtle, .drone: return 0.75
        default: return GamePhysics.wallBounce
        }
    }

    var style: CritterStyle {
        switch self {
        case .tumbleweed:
            return CritterStyle(facesTravel: false, rolls: true, bob: 0, lean: 0)
        case .crab:
            return CritterStyle(facingOffset: .pi / 2, bob: 0.004, lean: 0.16)
        case .drone:
            return CritterStyle(bob: 0, lean: 0.14, hover: 0.012)
        case .alien:
            return CritterStyle(bob: 0, lean: 0.08, hover: 0.016)
        case .magmaBlob, .turtle:
            return CritterStyle(bob: 0.004, lean: 0.06)
        case .mole, .meerkat, .cuckoo:
            return CritterStyle(bob: 0, lean: 0)
        case .snowman:
            return CritterStyle(bob: 0.006, lean: 0.15)
        case .rover:
            return CritterStyle(bob: 0.002, lean: 0.04)
        default:
            return CritterStyle()
        }
    }

    /// Burrowers come up through a hole in the felt, and the hole has to be
    /// visible before they do — a character appearing out of blank green reads
    /// as a bug, and the player gets no warning where to expect one.
    var burrowRim: UIColor? {
        switch self {
        case .mole: return UIColor(red: 0.30, green: 0.22, blue: 0.14, alpha: 1)
        case .meerkat: return UIColor(red: 0.72, green: 0.60, blue: 0.40, alpha: 1)
        case .cuckoo: return UIColor(red: 0.62, green: 0.46, blue: 0.20, alpha: 1)
        default: return nil
        }
    }
}

// MARK: - Builder

enum CritterBuilder {

    static func build(kind: CritterKind, center: SIMD2<Float>, motion: CritterMotion,
                      speed: Float, phase: Float, baseY: Float,
                      theme: CourseTheme, materials: ThemeMaterials,
                      into root: Entity, critters: inout [Critter]) {
        let critter = Critter(kind: kind, center: center, motion: motion, speed: speed,
                              phase: phase, baseY: baseY, style: kind.style)

        critter.body.name = "critter"
        let height = kind.height
        let shape = ShapeResource
            .generateConvex(from: .generateCylinder(height: height, radius: kind.radius))
            .offsetBy(translation: SIMD3(0, height / 2, 0))
        critter.body.components.set(CollisionComponent(shapes: [shape]))
        critter.body.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.wallMaterial, mode: .kinematic))
        critter.art.addChild(model(kind: kind, theme: theme))

        // The hole a burrower comes out of stays behind on the felt while the
        // character itself drops out of sight.
        if case .burrow = motion, let rimColor = kind.burrowRim {
            let rim = ModelEntity(
                mesh: Prim.cylinderMesh(height: 0.004, radius: kind.radius + 0.022),
                materials: [SceneBuilder.simpleMaterial(rimColor, roughness: 0.95)])
            rim.position = SIMD3(center.x, baseY + 0.002, center.y)
            root.addChild(rim)
            let pit = ModelEntity(
                mesh: Prim.cylinderMesh(height: 0.004, radius: kind.radius + 0.004),
                materials: [SceneBuilder.simpleMaterial(rimColor.darkened(by: 0.6),
                                                        roughness: 1.0)])
            pit.position.y = 0.0025
            rim.addChild(pit)
        }

        root.addChild(critter.root)
        critters.append(critter)
    }

    // MARK: Primitives

    private static func matte(_ color: UIColor, _ roughness: Float = 0.85) -> PhysicallyBasedMaterial {
        SceneBuilder.simpleMaterial(color, roughness: roughness)
    }

    private static func shiny(_ color: UIColor, metallic: Float = 0.8) -> PhysicallyBasedMaterial {
        SceneBuilder.simpleMaterial(color, roughness: 0.35, metallic: metallic)
    }

    private static func glow(_ color: UIColor, intensity: Float = 1.6) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = 0.4
        material.emissiveColor = .init(color: color)
        material.emissiveIntensity = intensity
        return material
    }

    // The four shape helpers below build every character in the game, a dozen
    // parts at a time, and a hole now carries two or three characters. None of
    // these parts collides with anything — the body's own hull, built above, is
    // the only collider a critter has — so they can all come off `Prim`'s
    // shared meshes instead of generating one apiece.
    private static func ball(_ radius: Float, _ material: any RealityKit.Material,
                             at position: SIMD3<Float>,
                             scale: SIMD3<Float> = .one) -> ModelEntity {
        let entity = Prim.sphere(radius: radius, material: material)
        entity.position = position
        entity.scale *= scale
        return entity
    }

    private static func slab(_ size: SIMD3<Float>, _ material: any RealityKit.Material,
                             at position: SIMD3<Float>, yaw: Float = 0,
                             roll: Float = 0) -> ModelEntity {
        let entity = Prim.roundedBox(width: size.x, height: size.y, depth: size.z,
                                     cornerRadius: min(size.x, min(size.y, size.z)) * 0.3,
                                     material: material)
        entity.position = position
        entity.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0)) *
                             simd_quatf(angle: roll, axis: SIMD3(0, 0, 1))
        return entity
    }

    /// Cone pointing along +Z unless `pitch` says otherwise — a snout, a beak,
    /// a carrot nose. RealityKit builds cones up the Y axis, so it is laid down
    /// once here instead of at every call.
    private static func spike(height: Float, radius: Float, _ material: any RealityKit.Material,
                              at position: SIMD3<Float>, pitch: Float = .pi / 2,
                              yaw: Float = 0) -> ModelEntity {
        let entity = Prim.cone(height: height, radius: radius, material: material)
        entity.position = position
        entity.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0)) *
                             simd_quatf(angle: pitch, axis: SIMD3(1, 0, 0))
        return entity
    }

    private static func rod(height: Float, radius: Float, _ material: any RealityKit.Material,
                            at position: SIMD3<Float>, tilt: Float = 0,
                            axis: SIMD3<Float> = SIMD3(0, 0, 1)) -> ModelEntity {
        let entity = Prim.cylinder(height: height, radius: radius, material: material)
        entity.position = position
        entity.orientation = simd_quatf(angle: tilt, axis: axis)
        return entity
    }

    /// A pair of eyes looking along +Z. Every character gets them: it is the one
    /// thing that turns a lump of primitives into somebody.
    private static func eyes(at height: Float, spread: Float, forward: Float,
                             radius: Float = 0.008,
                             color: UIColor = UIColor(white: 0.06, alpha: 1),
                             scale: SIMD3<Float> = .one) -> Entity {
        let group = Entity()
        for side: Float in [-1, 1] {
            group.addChild(ball(radius, matte(color, 0.3),
                                at: SIMD3(side * spread, height, forward), scale: scale))
        }
        return group
    }

    // MARK: The cast

    private static func model(kind: CritterKind, theme: CourseTheme) -> Entity {
        let group = Entity()
        switch kind {

        // Green Garden ------------------------------------------------------
        case .hedgehog:
            let fur = matte(UIColor(red: 0.45, green: 0.34, blue: 0.26, alpha: 1), 0.95)
            let quill = matte(UIColor(red: 0.28, green: 0.20, blue: 0.15, alpha: 1), 0.95)
            group.addChild(ball(0.05, fur, at: SIMD3(0, 0.042, 0),
                                scale: SIMD3(1.0, 0.82, 1.25)))
            // Three rows of spines standing off the back. They have to start at
            // the skin, not inside it: a quill rooted at the centre of the body
            // is swallowed whole and the hedgehog reads as a pebble.
            for i in 0..<9 {
                let across = Float(i % 3 - 1) * 0.026
                let row = Float(i / 3)
                group.addChild(spike(height: 0.05, radius: 0.013, quill,
                                     at: SIMD3(across, 0.074 - abs(across) * 0.35 - row * 0.006,
                                               0.012 - row * 0.028),
                                     pitch: -0.7, yaw: across * 6))
            }
            group.addChild(spike(height: 0.045, radius: 0.018, fur,
                                 at: SIMD3(0, 0.034, 0.058)))
            group.addChild(ball(0.008, matte(UIColor(white: 0.08, alpha: 1), 0.3),
                                at: SIMD3(0, 0.034, 0.082)))
            group.addChild(eyes(at: 0.058, spread: 0.022, forward: 0.05, radius: 0.008))

        case .mole:
            let fur = matte(UIColor(red: 0.32, green: 0.28, blue: 0.30, alpha: 1), 0.95)
            group.addChild(ball(0.042, fur, at: SIMD3(0, 0.05, 0), scale: SIMD3(1, 1.05, 1.1)))
            group.addChild(spike(height: 0.035, radius: 0.016,
                                 matte(UIColor(red: 0.85, green: 0.60, blue: 0.60, alpha: 1)),
                                 at: SIMD3(0, 0.045, 0.038)))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.016, fur, at: SIMD3(side * 0.038, 0.02, 0.022),
                                    scale: SIMD3(0.8, 1, 1.4)))
            }
            // Eyes shut: a mole underground has no use for them, and two closed
            // slits read far better than beads on a face this small.
            for side: Float in [-1, 1] {
                group.addChild(slab(SIMD3(0.012, 0.003, 0.004),
                                    matte(UIColor(white: 0.1, alpha: 1), 0.3),
                                    at: SIMD3(side * 0.019, 0.062, 0.03)))
            }

        // Desert Oasis ------------------------------------------------------
        case .tumbleweed:
            // A ball of dry twigs. Thin sticks vanish at playing distance, so
            // these are chunky and there are enough of them to read as a mass
            // from any angle — a knot at the middle holds them together.
            // Built around its own centre, not standing on the felt: the roll
            // turns it about the origin of `Critter.art`.
            let twig = matte(UIColor(red: 0.62, green: 0.52, blue: 0.30, alpha: 1), 1.0)
            let dry = matte(UIColor(red: 0.50, green: 0.41, blue: 0.22, alpha: 1), 1.0)
            group.addChild(ball(0.032, dry, at: .zero))
            for i in 0..<13 {
                let a = Float(i) * 0.698
                let b = Float(i) * 1.117
                let branch = slab(SIMD3(0.15, 0.013, 0.013), i.isMultiple(of: 3) ? dry : twig,
                                  at: .zero)
                branch.orientation = simd_quatf(angle: a, axis: SIMD3(0, 1, 0)) *
                                     simd_quatf(angle: b, axis: SIMD3(0, 0, 1))
                group.addChild(branch)
            }

        case .meerkat:
            let coat = matte(UIColor(red: 0.78, green: 0.64, blue: 0.42, alpha: 1), 0.95)
            group.addChild(ball(0.03, coat, at: SIMD3(0, 0.06, 0), scale: SIMD3(1, 1.9, 1)))
            group.addChild(ball(0.031, coat, at: SIMD3(0, 0.125, 0.004),
                                scale: SIMD3(1, 1, 1.15)))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.012, coat, at: SIMD3(side * 0.026, 0.142, 0),
                                    scale: SIMD3(1, 1, 0.5)))
                group.addChild(ball(0.011, matte(UIColor(white: 0.9, alpha: 1)),
                                    at: SIMD3(side * 0.028, 0.06, 0.012),
                                    scale: SIMD3(0.5, 1.1, 1)))
            }
            group.addChild(eyes(at: 0.132, spread: 0.015, forward: 0.028, radius: 0.009,
                                scale: SIMD3(1, 1.1, 0.6)))
            group.addChild(ball(0.007, matte(UIColor(white: 0.08, alpha: 1), 0.3),
                                at: SIMD3(0, 0.122, 0.032)))

        // Jungle Temple -----------------------------------------------------
        case .frog:
            let skin = matte(UIColor(red: 0.32, green: 0.66, blue: 0.28, alpha: 1), 0.6)
            group.addChild(ball(0.048, skin, at: SIMD3(0, 0.032, 0),
                                scale: SIMD3(1.05, 0.72, 1.2)))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.019, skin, at: SIMD3(side * 0.021, 0.062, 0.016)))
                group.addChild(ball(0.009, matte(UIColor(white: 0.05, alpha: 1), 0.25),
                                    at: SIMD3(side * 0.024, 0.066, 0.03)))
                // Folded back legs.
                group.addChild(ball(0.018, skin, at: SIMD3(side * 0.04, 0.022, -0.028),
                                    scale: SIMD3(0.7, 0.8, 1.3)))
            }

        case .turtle:
            let shell = matte(UIColor(red: 0.30, green: 0.42, blue: 0.24, alpha: 1), 0.8)
            let skin = matte(UIColor(red: 0.52, green: 0.60, blue: 0.36, alpha: 1), 0.9)
            group.addChild(ball(0.07, shell, at: SIMD3(0, 0.022, 0),
                                scale: SIMD3(1, 0.62, 1.15)))
            // Plates, so the dome reads as a shell rather than a pebble.
            for i in 0..<5 {
                let a = Float(i) * 1.256
                group.addChild(ball(0.016, matte(UIColor(red: 0.38, green: 0.52, blue: 0.30,
                                                         alpha: 1), 0.8),
                                    at: SIMD3(cos(a) * 0.035, 0.058, sin(a) * 0.04),
                                    scale: SIMD3(1, 0.35, 1)))
            }
            group.addChild(ball(0.026, skin, at: SIMD3(0, 0.03, 0.075),
                                scale: SIMD3(0.9, 0.9, 1.1)))
            group.addChild(eyes(at: 0.04, spread: 0.013, forward: 0.094, radius: 0.006))
            for side: Float in [-1, 1] {
                for front: Float in [-1, 1] {
                    group.addChild(ball(0.017, skin,
                                        at: SIMD3(side * 0.058, 0.014, front * 0.045),
                                        scale: SIMD3(1, 0.7, 1.2)))
                }
            }

        // Frozen Fjord ------------------------------------------------------
        case .snowman:
            let snow = matte(UIColor(white: 0.97, alpha: 1), 0.85)
            let coal = matte(UIColor(white: 0.08, alpha: 1), 0.4)
            group.addChild(ball(0.055, snow, at: SIMD3(0, 0.05, 0)))
            group.addChild(ball(0.04, snow, at: SIMD3(0, 0.115, 0)))
            group.addChild(ball(0.03, snow, at: SIMD3(0, 0.163, 0)))
            group.addChild(spike(height: 0.035, radius: 0.009,
                                 matte(UIColor(red: 0.95, green: 0.52, blue: 0.12, alpha: 1)),
                                 at: SIMD3(0, 0.163, 0.04)))
            group.addChild(eyes(at: 0.174, spread: 0.012, forward: 0.024, radius: 0.006))
            for i in 0..<2 {
                group.addChild(ball(0.006, coal, at: SIMD3(0, 0.108 - Float(i) * 0.026, 0.036)))
            }
            // Twig arms and a scarf in the world's own colour.
            for side: Float in [-1, 1] {
                group.addChild(rod(height: 0.06, radius: 0.004,
                                   matte(UIColor(red: 0.38, green: 0.28, blue: 0.18, alpha: 1)),
                                   at: SIMD3(side * 0.062, 0.128, 0),
                                   tilt: side * 1.1))
            }
            group.addChild(rod(height: 0.012, radius: 0.034,
                               matte(theme.accent, 0.8), at: SIMD3(0, 0.141, 0)))

        case .penguin:
            let coat = matte(UIColor(red: 0.14, green: 0.16, blue: 0.22, alpha: 1), 0.7)
            let bill = matte(UIColor(red: 0.95, green: 0.62, blue: 0.15, alpha: 1), 0.6)
            group.addChild(ball(0.048, coat, at: SIMD3(0, 0.062, 0),
                                scale: SIMD3(0.95, 1.3, 0.85)))
            group.addChild(ball(0.036, matte(UIColor(white: 0.96, alpha: 1), 0.8),
                                at: SIMD3(0, 0.055, 0.022), scale: SIMD3(0.85, 1.25, 0.5)))
            group.addChild(spike(height: 0.028, radius: 0.011, bill,
                                 at: SIMD3(0, 0.105, 0.032)))
            group.addChild(eyes(at: 0.118, spread: 0.015, forward: 0.03, radius: 0.006))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.03, coat, at: SIMD3(side * 0.044, 0.06, 0),
                                    scale: SIMD3(0.3, 1.1, 0.7)))
                group.addChild(slab(SIMD3(0.022, 0.008, 0.034), bill,
                                    at: SIMD3(side * 0.018, 0.005, 0.014)))
            }

        // Neon Nights -------------------------------------------------------
        case .drone:
            let shell = shiny(UIColor(white: 0.75, alpha: 1))
            group.addChild(ball(0.03, shell, at: SIMD3(0, 0.088, 0),
                                scale: SIMD3(1.2, 0.9, 1.2)))
            group.addChild(ball(0.014, glow(theme.accent, intensity: 2.4),
                                at: SIMD3(0, 0.084, 0.026), scale: SIMD3(1, 0.8, 0.6)))
            for i in 0..<6 {
                let a = Float(i) * .pi / 3
                group.addChild(slab(SIMD3(0.018, 0.008, 0.018),
                                    glow(theme.wallTopColor, intensity: 1.8),
                                    at: SIMD3(cos(a) * 0.05, 0.076, sin(a) * 0.05)))
            }
            // The beam is what the ball actually meets, so it has to be drawn
            // all the way down to the felt.
            var beam = PhysicallyBasedMaterial()
            beam.baseColor = .init(tint: theme.accent)
            beam.emissiveColor = .init(color: theme.accent)
            beam.emissiveIntensity = 1.2
            beam.blending = .transparent(opacity: 0.35)
            let cone = ModelEntity(mesh: .generateCone(height: 0.072, radius: 0.052),
                                   materials: [beam])
            cone.position.y = 0.036
            cone.orientation = simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0))
            group.addChild(cone)

        case .sentry:
            let casing = shiny(theme.wallColor.darkened(by: 0.1), metallic: 0.5)
            group.addChild(rod(height: 0.02, radius: 0.058, casing, at: SIMD3(0, 0.01, 0)))
            group.addChild(rod(height: 0.085, radius: 0.042, casing, at: SIMD3(0, 0.062, 0)))
            group.addChild(rod(height: 0.008, radius: 0.05,
                               glow(theme.wallTopColor, intensity: 1.8),
                               at: SIMD3(0, 0.108, 0)))
            group.addChild(ball(0.034, glow(theme.accent, intensity: 2.2),
                                at: SIMD3(0, 0.132, 0), scale: SIMD3(1, 0.9, 1)))
            group.addChild(ball(0.012, matte(UIColor(white: 0.05, alpha: 1), 0.2),
                                at: SIMD3(0, 0.132, 0.028), scale: SIMD3(1, 1.4, 0.6)))

        // Volcano Forge -----------------------------------------------------
        case .imp:
            let rock = matte(UIColor(red: 0.18, green: 0.14, blue: 0.14, alpha: 1), 1.0)
            let ember = glow(theme.lavaColor, intensity: 2.4)
            group.addChild(ball(0.044, rock, at: SIMD3(0, 0.048, 0),
                                scale: SIMD3(1, 1.05, 0.95)))
            for side: Float in [-1, 1] {
                group.addChild(spike(height: 0.032, radius: 0.011, rock,
                                     at: SIMD3(side * 0.022, 0.086, -0.006),
                                     pitch: -0.35, yaw: side * 0.4))
                group.addChild(ball(0.016, rock, at: SIMD3(side * 0.046, 0.03, 0.008),
                                    scale: SIMD3(0.7, 1, 1)))
                // Cracks in the crust glowing from the inside, front and back:
                // seen from behind on this world's near-black felt, an imp with
                // a lit face only is a smudge.
                for face: Float in [1, -1] {
                    group.addChild(slab(SIMD3(0.006, 0.026, 0.004), ember,
                                        at: SIMD3(side * 0.03, 0.036, face * 0.03),
                                        roll: side * 0.5))
                }
            }
            group.addChild(ball(0.038, ember, at: SIMD3(0, 0.014, 0),
                                scale: SIMD3(1, 0.35, 1)))
            group.addChild(eyes(at: 0.058, spread: 0.016, forward: 0.036, radius: 0.008,
                                color: UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)))
            group.addChild(ball(0.008, ember, at: SIMD3(0, 0.058, 0.036),
                                scale: SIMD3(2.6, 0.5, 0.4)))

        case .magmaBlob:
            group.addChild(ball(0.062, glow(theme.lavaColor, intensity: 1.8),
                                at: SIMD3(0, 0.03, 0), scale: SIMD3(1, 0.62, 1)))
            // Crust over the back only. Pulled across the whole blob it hides
            // the face, and what is left is a glowing ring nobody reads as a
            // creature.
            group.addChild(ball(0.054, matte(UIColor(red: 0.16, green: 0.13, blue: 0.12,
                                                     alpha: 1), 1.0),
                                at: SIMD3(0, 0.044, -0.018), scale: SIMD3(1.0, 0.4, 0.85)))
            group.addChild(eyes(at: 0.054, spread: 0.02, forward: 0.04, radius: 0.011,
                                color: UIColor(white: 0.97, alpha: 1)))
            group.addChild(eyes(at: 0.056, spread: 0.02, forward: 0.048, radius: 0.006))

        // Clockwork Works ---------------------------------------------------
        case .windupBot:
            let brass = shiny(theme.wallTopColor)
            let iron = shiny(UIColor(white: 0.68, alpha: 1), metallic: 0.6)
            group.addChild(rod(height: 0.072, radius: 0.044, brass, at: SIMD3(0, 0.056, 0)))
            group.addChild(slab(SIMD3(0.062, 0.048, 0.05), iron, at: SIMD3(0, 0.117, 0)))
            group.addChild(eyes(at: 0.124, spread: 0.017, forward: 0.028, radius: 0.011,
                                color: UIColor(red: 1.0, green: 0.72, blue: 0.15, alpha: 1)))
            group.addChild(slab(SIMD3(0.03, 0.006, 0.004),
                                matte(UIColor(white: 0.12, alpha: 1), 0.5),
                                at: SIMD3(0, 0.106, 0.026)))
            // Wind-up key on the back.
            group.addChild(rod(height: 0.022, radius: 0.008, iron,
                               at: SIMD3(0, 0.07, -0.052), tilt: .pi / 2, axis: SIMD3(1, 0, 0)))
            for turn: Float in [0, .pi / 2] {
                group.addChild(slab(SIMD3(0.03, 0.006, 0.006), iron,
                                    at: SIMD3(0, 0.07, -0.064), yaw: 0, roll: turn))
            }
            for side: Float in [-1, 1] {
                group.addChild(slab(SIMD3(0.026, 0.016, 0.04), iron,
                                    at: SIMD3(side * 0.024, 0.01, 0.004)))
            }

        case .cuckoo:
            let feather = matte(UIColor(red: 0.82, green: 0.36, blue: 0.24, alpha: 1), 0.8)
            group.addChild(rod(height: 0.04, radius: 0.01, shiny(theme.wallTopColor),
                               at: SIMD3(0, 0.02, 0)))
            group.addChild(ball(0.032, feather, at: SIMD3(0, 0.068, 0),
                                scale: SIMD3(1, 1, 1.15)))
            group.addChild(ball(0.024, feather, at: SIMD3(0, 0.105, 0.012)))
            group.addChild(spike(height: 0.024, radius: 0.009,
                                 matte(UIColor(red: 0.96, green: 0.72, blue: 0.18, alpha: 1)),
                                 at: SIMD3(0, 0.104, 0.03)))
            group.addChild(eyes(at: 0.114, spread: 0.012, forward: 0.019, radius: 0.006))
            group.addChild(slab(SIMD3(0.02, 0.006, 0.036), feather,
                                at: SIMD3(0, 0.072, -0.034), yaw: 0, roll: 0.5))

        // Storm Coast -------------------------------------------------------
        case .crab:
            let carapace = matte(UIColor(red: 0.85, green: 0.32, blue: 0.22, alpha: 1), 0.6)
            group.addChild(ball(0.05, carapace, at: SIMD3(0, 0.03, 0),
                                scale: SIMD3(1.3, 0.6, 0.9)))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.02, carapace, at: SIMD3(side * 0.058, 0.026, 0.034),
                                    scale: SIMD3(1, 0.8, 1.2)))
                group.addChild(rod(height: 0.022, radius: 0.004, carapace,
                                   at: SIMD3(side * 0.016, 0.055, 0.012)))
                group.addChild(ball(0.007, matte(UIColor(white: 0.06, alpha: 1), 0.3),
                                    at: SIMD3(side * 0.016, 0.068, 0.012)))
                for leg in 0..<3 {
                    group.addChild(slab(SIMD3(0.03, 0.005, 0.005), carapace,
                                        at: SIMD3(side * 0.058, 0.012,
                                                  -0.012 - Float(leg) * 0.016),
                                        yaw: side * 0.5))
                }
            }

        case .seagull:
            let plume = matte(UIColor(white: 0.95, alpha: 1), 0.8)
            let wing = matte(UIColor(white: 0.62, alpha: 1), 0.85)
            let bill = matte(UIColor(red: 0.96, green: 0.66, blue: 0.16, alpha: 1), 0.6)
            group.addChild(ball(0.042, plume, at: SIMD3(0, 0.058, -0.004),
                                scale: SIMD3(0.9, 0.95, 1.25)))
            group.addChild(ball(0.026, plume, at: SIMD3(0, 0.104, 0.026)))
            group.addChild(spike(height: 0.03, radius: 0.008, bill,
                                 at: SIMD3(0, 0.102, 0.05)))
            group.addChild(eyes(at: 0.112, spread: 0.014, forward: 0.026, radius: 0.006))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.032, wing, at: SIMD3(side * 0.036, 0.058, -0.008),
                                    scale: SIMD3(0.35, 0.8, 1.2)))
                group.addChild(rod(height: 0.03, radius: 0.004, bill,
                                   at: SIMD3(side * 0.014, 0.017, 0)))
            }
            group.addChild(slab(SIMD3(0.03, 0.008, 0.036), wing,
                                at: SIMD3(0, 0.052, -0.05), yaw: 0, roll: 0.3))

        // Orbital Station ---------------------------------------------------
        case .alien:
            let skin = matte(UIColor(red: 0.42, green: 0.82, blue: 0.46, alpha: 1), 0.5)
            group.addChild(ball(0.03, skin, at: SIMD3(0, 0.052, 0),
                                scale: SIMD3(1, 1.15, 0.9)))
            group.addChild(ball(0.042, skin, at: SIMD3(0, 0.11, 0),
                                scale: SIMD3(1, 1.1, 0.95)))
            group.addChild(eyes(at: 0.118, spread: 0.019, forward: 0.032, radius: 0.012,
                                scale: SIMD3(0.8, 1.3, 0.4)))
            group.addChild(rod(height: 0.03, radius: 0.003, skin, at: SIMD3(0, 0.16, -0.004)))
            group.addChild(ball(0.009, glow(theme.accent, intensity: 2.2),
                                at: SIMD3(0, 0.178, -0.004)))
            for side: Float in [-1, 1] {
                group.addChild(ball(0.012, skin, at: SIMD3(side * 0.034, 0.05, 0),
                                    scale: SIMD3(0.7, 1.4, 0.7)))
            }

        case .rover:
            let hull = shiny(UIColor(white: 0.82, alpha: 1), metallic: 0.5)
            let dark = matte(UIColor(white: 0.18, alpha: 1), 0.7)
            group.addChild(slab(SIMD3(0.11, 0.042, 0.13), hull, at: SIMD3(0, 0.052, 0)))
            for side: Float in [-1, 1] {
                for front: Float in [-1, 1] {
                    group.addChild(rod(height: 0.014, radius: 0.024, dark,
                                       at: SIMD3(side * 0.058, 0.026, front * 0.042),
                                       tilt: .pi / 2))
                }
            }
            var panel = PhysicallyBasedMaterial()
            panel.baseColor = .init(tint: UIColor(red: 0.12, green: 0.18, blue: 0.45, alpha: 1))
            panel.emissiveColor = .init(color: theme.groundDetail)
            panel.emissiveIntensity = 0.5
            panel.roughness = 0.2
            panel.metallic = 0.6
            group.addChild(slab(SIMD3(0.1, 0.006, 0.07), panel, at: SIMD3(0, 0.076, -0.02)))
            group.addChild(rod(height: 0.04, radius: 0.007, hull, at: SIMD3(0, 0.094, 0.038)))
            group.addChild(ball(0.016, glow(theme.accent, intensity: 1.8),
                                at: SIMD3(0, 0.116, 0.042), scale: SIMD3(1.4, 0.8, 0.7)))
        }
        return group
    }
}
