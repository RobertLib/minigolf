//
//  SceneBuilder.swift
//  Minigolf
//
//  Turns a LevelDefinition into a RealityKit entity hierarchy: floors, walls,
//  the hole with its flag, sky, terrain, lighting and themed decorations.
//

import Foundation
import RealityKit
import UIKit
import Metal
import simd

// MARK: - Physics materials

enum GamePhysics {
    static let ballRadius: Float = 0.034
    static let ballMass: Float = 0.045

    static let floorMaterial = PhysicsMaterialResource.generate(
        staticFriction: 0.45, dynamicFriction: 0.42, restitution: 0.35)

    /// Damping applied to the rolling ball on regular felt.
    static let ballLinearDamping: Float = 0.14
    static let ballAngularDamping: Float = 0.12
    /// Damping while the ball sits in a sand trap.
    static let sandLinearDamping: Float = 3.2
    /// Mud, ash and slush: thicker than sand, a ball that stops here stays.
    static let mudLinearDamping: Float = 6.5
    /// Ice barely takes any speed off the ball at all.
    static let iceLinearDamping: Float = 0.02

    /// Linear damping for a floor surface.
    static func damping(for kind: FloorPatch.Kind) -> Float {
        switch kind {
        case .sand: return sandLinearDamping
        case .mud: return mudLinearDamping
        case .ice: return iceLinearDamping
        case .green, .water, .lava: return ballLinearDamping
        }
    }
    /// Sideways rebound is driven entirely by the coordinator (see `wallBounce`),
    /// so these carry no restitution of their own — otherwise slow hits would
    /// bounce once and fast ones twice, and a bumper arena would gain energy
    /// until the ball flew out of the course. Boards are slick so a grazing shot
    /// deflects instead of scrubbing off speed.
    static let wallMaterial = PhysicsMaterialResource.generate(
        staticFriction: 0.1, dynamicFriction: 0.08, restitution: 0)
    static let bumperMaterial = PhysicsMaterialResource.generate(
        staticFriction: 0.1, dynamicFriction: 0.08, restitution: 0)
    static let ballMaterial = PhysicsMaterialResource.generate(
        staticFriction: 0.45, dynamicFriction: 0.5, restitution: 0)

    /// The solver treats impacts below a few m/s as perfectly inelastic, so no
    /// material restitution survives at putting speed and the ball glues itself
    /// to the boards. The coordinator applies the rebound by hand using these.
    static let wallBounce: Float = 0.6
    static let bumperBounce: Float = 0.9
    /// Slowest approach worth bouncing; below this the ball is just leaning.
    static let minBounceSpeed: Float = 0.12
    /// Backstop against a rebound loop pumping energy into the ball.
    static let maxBallSpeed: Float = 5.5

    /// How hard a turntable bends the ball's path, per rad/s of disc speed. The
    /// honest figure for a rolling sphere is 2/7; that is a gentle drift over a
    /// half-metre disc, so the tables here spin the ball about three times as
    /// eagerly as a record player would.
    static let turntableCurve: Float = 0.9
    /// Below this the ball has stopped rolling and the table picks it up and
    /// carries it instead.
    static let turntableCatchSpeed: Float = 0.18
    /// Outward drift of a carried ball. Friction cannot hold a ball in a circle
    /// for long, so the table always works it out to the rim and hands it back
    /// instead of parking it in the middle for good.
    static let turntableSpill: Float = 0.18
}

/// The chase camera's rig. Shared with the scene builder, which cannot size the
/// shadow cascade without knowing how far the camera is allowed to get.
enum CameraRig {
    /// Ball-to-camera offset, before the zoom multiplier.
    static let offset = SIMD3<Float>(0, 1.30, 1.04)
    /// The camera aims a little past the ball, down the lane.
    static let lookAhead = SIMD3<Float>(0, 0, -0.42)
    static let minPinch: Float = 0.7
    static let maxPinch: Float = 1.8
    /// Extra pull-back in landscape, where the lane has far less screen to run in.
    static let landscapeAspect: Float = 1.3
}

// MARK: - Build result

/// A patch of felt that changes how the ball rolls (sand, mud, ice).
struct SurfaceRegion {
    var rect: GroundRect
    var y: Float
    var damping: Float
}

/// A gap in the floor that costs a stroke to fall into.
struct HazardRegion {
    var rect: GroundRect
    var y: Float
    var kind: OutOfBoundsKind
}

/// Area that pushes the rolling ball: banked greens, belts, river currents.
struct ForceZone {
    var rect: GroundRect
    var y: Float
    /// Force in newtons, already scaled by the ball's mass.
    var force: SIMD2<Float>
}

/// A pair of rings that throw the ball from one to the other.
struct Portal {
    var a: SIMD2<Float>
    var b: SIMD2<Float>
    var radius: Float
    var y: Float
    /// Rings only fire once the ball has left them again.
    var armed = true
}

struct BoostPad {
    var center: SIMD2<Float>
    var direction: SIMD2<Float>
    var boost: Float
    var y: Float
}

/// A loop-the-loop, described the way the coordinator walks the ball around it.
/// The solver is no help here: a 3 cm ball at putting speed either catches a
/// seam between two track segments and is fired into the sky, or sticks to the
/// felt and never leaves the ground. So the ring only draws itself and the ball
/// runs along the track by hand, losing exactly the speed the climb costs.
struct LoopTrack {
    /// Middle of the run on the felt; the two mouths sit half a pitch either
    /// side of it along `axis`.
    var center: SIMD2<Float>
    /// Radius of the running surface.
    var radius: Float
    /// Travel direction through the loop (unit); either sign may be entered.
    var axis: SIMD2<Float>
    var halfWidth: Float
    var y: Float

    /// Radius the ball's centre actually travels on.
    var trackRadius: Float { max(0.02, radius - GamePhysics.ballRadius) }
    /// Distance from the entrance to the exit along `axis`.
    var pitch: Float { LoopShape.pitch(radius: radius) }

    /// The mouth a ball travelling along `axis * sign` rolls into.
    func mouth(sign: Float) -> SIMD2<Float> {
        center - axis * (sign * pitch / 2)
    }

    /// Where the ball's centre sits at `theta`, in the vertical plane of the
    /// run: x along the lane from `center`, y over the felt.
    func ballPoint(theta: Float) -> SIMD2<Float> {
        let point = LoopShape.point(theta: theta, radius: trackRadius, pitch: pitch)
        return SIMD2(point.x, point.y + (radius - trackRadius))
    }

    /// Direction of travel at `theta`; its length is the arc per radian.
    func ballTangent(theta: Float) -> SIMD2<Float> {
        LoopShape.tangent(theta: theta, radius: trackRadius, pitch: pitch)
    }
}

/// Kicker: leaves the ball with a fixed speed and lift, so a jump always covers
/// the same distance no matter how hard the putt was.
struct LaunchPad {
    var center: SIMD2<Float>
    var direction: SIMD2<Float>
    var speed: Float
    var lift: Float
    var y: Float
}

/// Barrel that holds the ball for a moment and then fires it along a fixed line.
struct Cannon {
    var center: SIMD2<Float>
    var direction: SIMD2<Float>
    var speed: Float
    var y: Float
    var radius: Float

    /// Where the ball reappears: clear of the muzzle, so a shot cannot be
    /// swallowed again by the barrel it just left.
    var exit: SIMD2<Float> { center + direction * (radius + 0.16) }
}

/// Disc turning in the floor; drags the ball along with its surface.
struct Turntable {
    var center: SIMD2<Float>
    var radius: Float
    /// Angular speed in rad/s; the sign picks the direction.
    var speed: Float
    var y: Float
}

/// Attracts (positive strength) or repels (negative) the rolling ball.
struct MagnetField {
    var center: SIMD2<Float>
    var radius: Float
    /// Acceleration at the centre, in m/s², fading to zero at the rim.
    var strength: Float
    var y: Float
}

/// Wind that swells and dies on a timer.
struct WindZone {
    var rect: GroundRect
    var direction: SIMD2<Float>
    var strength: Float
    var period: Float
    var phase: Float
    var y: Float

    /// 0 = still, 1 = full gale. The blades spin off the same curve, so what the
    /// player sees is exactly what the ball feels.
    func gust(at time: Float) -> Float {
        guard period > 0 else { return 1 }
        return 0.5 + 0.5 * sin(2 * .pi * time / period + phase)
    }
}

/// Optional collectible tucked away somewhere on the hole.
struct BonusStar {
    var position: SIMD3<Float>
    var entity: Entity
    var collected = false
}

/// Everything the obstacle builders hand back to the scene.
struct ObstacleOutputs {
    var animated: [AnimatedObstacle] = []
    var bumperNames: Set<String> = []
    var forceZones: [ForceZone] = []
    var portals: [Portal] = []
    var boostPads: [BoostPad] = []
    var loops: [LoopTrack] = []
    var launchPads: [LaunchPad] = []
    var cannons: [Cannon] = []
    var turntables: [Turntable] = []
    var magnets: [MagnetField] = []
    var windZones: [WindZone] = []
}

struct BuiltScene {
    var root: Entity
    var ball: ModelEntity
    var holePosition: SIMD3<Float>
    var animated: [AnimatedObstacle]
    var surfaceRegions: [SurfaceRegion]
    var hazardRegions: [HazardRegion]
    var forceZones: [ForceZone]
    var portals: [Portal]
    var boostPads: [BoostPad]
    var loops: [LoopTrack]
    var launchPads: [LaunchPad]
    var cannons: [Cannon]
    var turntables: [Turntable]
    var magnets: [MagnetField]
    var windZones: [WindZone]
    var bonusStar: BonusStar?
    /// Footprint of the whole course: every floor patch (hazard gaps included)
    /// plus the ramps that bridge them.
    var floorRects: [GroundRect]
    var bumperNames: Set<String>
    var minFloorY: Float
}

// MARK: - Builder

enum SceneBuilder {

    static func build(level: LevelDefinition, skin: BallSkin = .classic) -> BuiltScene {
        let theme = level.course.theme
        let root = Entity()
        root.name = "levelRoot"

        var outputs = ObstacleOutputs()
        var surfaceRegions: [SurfaceRegion] = []
        var hazardRegions: [HazardRegion] = []

        let materials = ThemeMaterials(theme: theme, course: level.course)

        buildSky(theme: theme, course: level.course, into: root)
        buildTerrain(level: level, materials: materials, into: root)
        buildLights(theme: theme, level: level, into: root)

        // Floors: slabs are drawn per patch, but collision is merged per height
        // so the ball never crosses an exposed box edge mid-lane.
        for patch in level.floors {
            switch patch.kind {
            case .green:
                addFloor(patch, materials: materials, into: root)
            case .sand, .mud, .ice:
                addSurfaceOverlay(patch, materials: materials, into: root)
                surfaceRegions.append(SurfaceRegion(
                    rect: patch.rect, y: patch.y,
                    damping: GamePhysics.damping(for: patch.kind)))
            case .water, .lava:
                addHazard(patch, materials: materials, into: root)
                hazardRegions.append(HazardRegion(
                    rect: patch.rect, y: patch.y,
                    kind: patch.kind == .lava ? .lava : .water))
            }
        }
        for slab in floorColliders(for: level) {
            addFloorCollider(rect: slab.rect, y: slab.y, into: root)
        }

        // Walls
        for loop in level.wallLoops {
            for i in 0..<loop.count {
                let a = loop[i]
                let b = loop[(i + 1) % loop.count]
                addWall(WallSegment(from: a, to: b), materials: materials, theme: theme, into: root)
            }
        }
        for segment in level.extraWalls {
            addWall(segment, materials: materials, theme: theme, into: root)
        }

        // Hole + flag + tee
        let holePos = SIMD3(level.hole.x, level.holeY, level.hole.y)
        buildHole(at: holePos, theme: theme, materials: materials, into: root,
                  animated: &outputs.animated)
        buildTee(at: SIMD3(level.tee.x, 0, level.tee.y), materials: materials, into: root)

        // Obstacles
        for (index, spec) in level.obstacles.enumerated() {
            ObstacleBuilder.build(spec, index: index, theme: theme, materials: materials,
                                  into: root, outputs: &outputs)
        }

        var bonusStar: BonusStar?
        if let star = level.bonusStar {
            let position = SIMD3(star.x, level.bonusStarY + 0.05, star.y)
            let entity = buildBonusStar(at: position, materials: materials,
                                        animated: &outputs.animated)
            root.addChild(entity)
            bonusStar = BonusStar(position: position, entity: entity)
        }

        buildDecorations(level: level, theme: theme, into: root)

        let ball = buildBall(at: SIMD3(level.tee.x, GamePhysics.ballRadius + 0.002, level.tee.y),
                             skin: skin)
        root.addChild(ball)

        return BuiltScene(
            root: root,
            ball: ball,
            holePosition: holePos,
            animated: outputs.animated,
            surfaceRegions: surfaceRegions,
            hazardRegions: hazardRegions,
            forceZones: outputs.forceZones,
            portals: outputs.portals,
            boostPads: outputs.boostPads,
            loops: outputs.loops,
            launchPads: outputs.launchPads,
            cannons: outputs.cannons,
            turntables: outputs.turntables,
            magnets: outputs.magnets,
            windZones: outputs.windZones,
            bonusStar: bonusStar,
            floorRects: level.floors.map(\.rect) + rampFootprints(of: level),
            bumperNames: outputs.bumperNames,
            minFloorY: level.minFloorY
        )
    }

    // MARK: Ball

    static func buildBall(at position: SIMD3<Float>, skin: BallSkin = .classic) -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: skin.baseColor)
        material.roughness = .init(floatLiteral: skin.roughness)
        material.metallic = .init(floatLiteral: skin.metallic)
        if let glow = skin.glow {
            material.emissiveColor = .init(color: glow)
            material.emissiveIntensity = skin.glowIntensity
        }

        let ball = ModelEntity(
            mesh: .generateSphere(radius: GamePhysics.ballRadius),
            materials: [material]
        )
        ball.name = "ball"
        ball.position = position

        var body = PhysicsBodyComponent(
            massProperties: .init(mass: GamePhysics.ballMass),
            material: GamePhysics.ballMaterial,
            mode: .dynamic
        )
        body.linearDamping = GamePhysics.ballLinearDamping
        body.angularDamping = GamePhysics.ballAngularDamping
        body.isContinuousCollisionDetectionEnabled = true
        ball.components.set(body)
        ball.components.set(CollisionComponent(shapes: [.generateSphere(radius: GamePhysics.ballRadius)]))
        return ball
    }

    // MARK: Floors, sand, water, walls

    /// Where two floor slabs butt together, the box edge of the one being entered
    /// sits right at playing height. The solver sees the ball closing on it and
    /// pushes back along the edge normal, which launches the ball instead of
    /// letting it roll across. So collision is not built per patch: each height
    /// becomes a single slab where that is possible, and where it is not — holes
    /// whose gaps have to stay real holes — the patches are cut into lengthwise
    /// bands instead, leaving seams only alongside the line of play.
    private static func floorColliders(for level: LevelDefinition) -> [(rect: GroundRect, y: Float)] {
        let greens = level.floors.filter { $0.kind == .green }
        let hazards = level.floors.filter { $0.kind.isHazard }.map(\.rect)
        var slabs: [(rect: GroundRect, y: Float)] = []

        for y in Set(greens.map(\.y)).sorted() {
            let group = greens.filter { $0.y == y }
            guard var merged = group.first?.rect else { continue }
            for patch in group.dropFirst() { merged = merged.union(patch.rect) }

            let wouldSwallow = hazards.contains { overlaps($0, merged) }
                || greens.contains { $0.y != y && overlaps($0.rect, merged) }
            if wouldSwallow {
                slabs.append(contentsOf: lengthwiseBands(of: group).map { (rect: $0, y: y) })
            } else {
                slabs.append((rect: merged, y: y))
            }
        }
        return slabs
    }

    /// Splits patches into bands between their X boundaries and fuses each band's
    /// contiguous Z runs. A bridge across water then shares one uninterrupted
    /// slab with the greens at both ends.
    private static func lengthwiseBands(of group: [FloorPatch]) -> [GroundRect] {
        let cuts = Set(group.flatMap { [$0.rect.minX, $0.rect.maxX] }).sorted()
        var bands: [GroundRect] = []

        for (x0, x1) in zip(cuts, cuts.dropFirst()) where x1 - x0 > 0.0001 {
            let mid = (x0 + x1) / 2
            let spans = group
                .filter { $0.rect.minX < mid && mid < $0.rect.maxX }
                .map { ($0.rect.minZ, $0.rect.maxZ) }
                .sorted { $0.0 < $1.0 }

            var run: (Float, Float)?
            for span in spans {
                if let open = run, span.0 <= open.1 + 0.0001 {
                    run = (open.0, max(open.1, span.1))
                } else {
                    if let open = run { bands.append(GroundRect(x0: x0, x1: x1, z0: open.0, z1: open.1)) }
                    run = span
                }
            }
            if let open = run { bands.append(GroundRect(x0: x0, x1: x1, z0: open.0, z1: open.1)) }
        }
        return bands
    }

    /// A ramp is the only floor a level owns that is not a `FloorPatch`, and the
    /// gap it bridges is wider than the out-of-bounds margin — without this the
    /// ball is called out the moment it starts climbing.
    private static func rampFootprints(of level: LevelDefinition) -> [GroundRect] {
        level.obstacles.compactMap { spec in
            guard case .ramp(let center, let width, let length, _, let yaw) = spec else { return nil }
            let halfW = width / 2, halfL = length / 2
            let c = abs(cos(yaw)), s = abs(sin(yaw))
            let extent = SIMD2(halfW * c + halfL * s, halfW * s + halfL * c)
            return GroundRect(x0: center.x - extent.x, x1: center.x + extent.x,
                              z0: center.y - extent.y, z1: center.y + extent.y)
        }
    }

    /// Strict overlap: rectangles that merely share an edge do not count.
    private static func overlaps(_ a: GroundRect, _ b: GroundRect) -> Bool {
        a.minX < b.maxX && b.minX < a.maxX && a.minZ < b.maxZ && b.minZ < a.maxZ
    }

    private static func addFloorCollider(rect: GroundRect, y: Float, into root: Entity) {
        let size = rect.size
        let height = y + 0.06
        let entity = Entity()
        entity.name = "floorCollision"
        entity.position = SIMD3(rect.center.x, y - height / 2, rect.center.y)
        entity.components.set(CollisionComponent(shapes: [
            .generateBox(width: size.x, height: height, depth: size.y)
        ]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.floorMaterial, mode: .static))
        root.addChild(entity)
    }

    /// Visual slab only — collision comes from `addFloorCollider`.
    private static func addFloor(_ patch: FloorPatch, materials: ThemeMaterials, into root: Entity) {
        let size = patch.rect.size
        let height = patch.y + 0.06
        let entity = ModelEntity(
            mesh: .generateBox(width: size.x, height: height, depth: size.y),
            materials: [materials.felt(size: size)]
        )
        entity.name = "floor"
        entity.position = SIMD3(patch.rect.center.x, patch.y - height / 2, patch.rect.center.y)
        root.addChild(entity)
    }

    /// Sand, mud and ice are paper-thin skins on top of the felt. They carry no
    /// collider: a 6 mm lip is an invisible kerb for a 34 mm ball, and the
    /// coordinator applies their damping from the region list anyway.
    private static func addSurfaceOverlay(_ patch: FloorPatch, materials: ThemeMaterials,
                                          into root: Entity) {
        let size = patch.rect.size
        let entity = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.006, depth: size.y, cornerRadius: 0.003),
            materials: [materials.overlay(kind: patch.kind, size: size)]
        )
        entity.name = "surface"
        entity.position = SIMD3(patch.rect.center.x, patch.y + 0.001, patch.rect.center.y)
        root.addChild(entity)
    }

    private static func addHazard(_ patch: FloorPatch, materials: ThemeMaterials,
                                 into root: Entity) {
        let size = patch.rect.size
        // Visual-only surface below floor level; the ball falls through the gap.
        let entity = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.004, depth: size.y),
            materials: [patch.kind == .lava ? materials.lava : materials.water]
        )
        entity.name = patch.kind == .lava ? "lava" : "water"
        entity.position = SIMD3(patch.rect.center.x, patch.y - 0.045, patch.rect.center.y)
        root.addChild(entity)
    }

    private static func addWall(_ segment: WallSegment, materials: ThemeMaterials,
                                theme: CourseTheme, into root: Entity) {
        let delta = segment.to - segment.from
        let length = simd_length(delta)
        guard length > 0.001 else { return }
        let mid = (segment.from + segment.to) / 2
        let yaw = atan2(-delta.y, delta.x)
        let boxLength = length + segment.thickness

        let entity = ModelEntity(
            mesh: .generateBox(width: boxLength, height: segment.height,
                               depth: segment.thickness, cornerRadius: 0.008),
            materials: [materials.wall]
        )
        entity.name = "wall"
        entity.position = SIMD3(mid.x, segment.baseY + segment.height / 2, mid.y)
        entity.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
        entity.components.set(CollisionComponent(shapes: [
            .generateBox(width: boxLength, height: segment.height, depth: segment.thickness)
        ]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default, material: GamePhysics.wallMaterial, mode: .static))
        root.addChild(entity)

        // Glowing top strip in the neon world.
        if theme.emissiveWalls {
            let strip = ModelEntity(
                mesh: .generateBox(width: boxLength, height: 0.012,
                                   depth: segment.thickness + 0.006, cornerRadius: 0.005),
                materials: [materials.wallGlow]
            )
            strip.position = SIMD3(0, segment.height / 2 + 0.006, 0)
            entity.addChild(strip)
        }
    }

    // MARK: Hole, flag, tee

    private static func buildHole(at position: SIMD3<Float>, theme: CourseTheme,
                                  materials: ThemeMaterials, into root: Entity,
                                  animated: inout [AnimatedObstacle]) {
        let group = Entity()
        group.name = "holeGroup"
        group.position = position

        let rim = ModelEntity(
            mesh: .generateCylinder(height: 0.004, radius: 0.068),
            materials: [materials.holeRim]
        )
        rim.position.y = 0.002
        group.addChild(rim)

        let cup = ModelEntity(
            mesh: .generateCylinder(height: 0.005, radius: 0.054),
            materials: [materials.holeCup]
        )
        cup.position.y = 0.0035
        group.addChild(cup)

        // Flag pole + flag
        let pole = ModelEntity(
            mesh: .generateCylinder(height: 0.42, radius: 0.006),
            materials: [materials.pole]
        )
        pole.position.y = 0.21
        group.addChild(pole)

        let flag = ModelEntity(
            mesh: .generateBox(width: 0.16, height: 0.09, depth: 0.006, cornerRadius: 0.002),
            materials: [materials.flag]
        )
        flag.position = SIMD3(0.085, 0.365, 0)
        let flagPivot = Entity()
        flagPivot.position = SIMD3(0, 0, 0)
        flagPivot.addChild(flag)
        group.addChild(flagPivot)
        animated.append(AnimatedObstacle(kind: .flag(phase: 0), entity: flagPivot))

        root.addChild(group)
    }

    private static func buildTee(at position: SIMD3<Float>, materials: ThemeMaterials, into root: Entity) {
        let tee = ModelEntity(
            mesh: .generateCylinder(height: 0.004, radius: 0.055),
            materials: [materials.teeMarker]
        )
        tee.position = position + SIMD3(0, 0.002, 0)
        tee.name = "tee"
        root.addChild(tee)
    }

    /// Spinning, bobbing collectible. No collider — the coordinator picks it up
    /// from the distance to the ball, so it can never deflect a putt.
    private static func buildBonusStar(at position: SIMD3<Float>, materials: ThemeMaterials,
                                       animated: inout [AnimatedObstacle]) -> Entity {
        let group = Entity()
        group.name = "bonusStar"
        group.position = position

        let core = ModelEntity(mesh: .generateSphere(radius: 0.018), materials: [materials.star])
        group.addChild(core)

        // Three crossed spikes read as a sparkle from every camera angle.
        for i in 0..<3 {
            let spike = ModelEntity(
                mesh: .generateBox(width: 0.062, height: 0.008, depth: 0.008, cornerRadius: 0.003),
                materials: [materials.star])
            spike.orientation = simd_quatf(angle: Float(i) * .pi / 3, axis: SIMD3(0, 1, 0)) *
                                simd_quatf(angle: Float(i) * 0.5, axis: SIMD3(1, 0, 0))
            group.addChild(spike)
        }

        animated.append(AnimatedObstacle(
            kind: .spin(speed: 1.8, baseY: position.y, bob: 0.014), entity: group))
        return group
    }

    // MARK: Environment

    private static func buildSky(theme: CourseTheme, course: CourseType, into root: Entity) {
        guard let texture = TextureFactory.sky(theme: theme, key: course.rawValue) else { return }
        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        let sky = ModelEntity(mesh: .generateSphere(radius: 28), materials: [material])
        sky.name = "sky"
        // Flip so the inside of the sphere is visible.
        sky.scale = SIMD3(-1, 1, 1)
        sky.position = SIMD3(0, 0, -1.5)
        root.addChild(sky)
    }

    private static func buildTerrain(level: LevelDefinition, materials: ThemeMaterials, into root: Entity) {
        let bounds = level.bounds
        let entity = ModelEntity(
            mesh: .generateBox(width: bounds.size.x + 14, height: 0.05, depth: bounds.size.y + 14),
            materials: [materials.ground]
        )
        entity.name = "terrain"
        entity.position = SIMD3(bounds.center.x, -0.25, bounds.center.y)
        root.addChild(entity)
    }

    /// How far this hole's shadow cascade has to reach.
    ///
    /// The 5 m default is fitted to a camera a couple of metres above the felt.
    /// Pinched all the way out on a big hole the camera sits over 6 m from the
    /// ball and the far boards are another 4 m past that, so the course — the
    /// ball's own contact shadow included — falls outside the cascade and the
    /// hole goes flat. Measured per hole rather than set by one worldwide
    /// constant: the shadow map has a fixed resolution, so every extra metre of
    /// reach is sharpness taken off the small holes that never needed it.
    private static func shadowDistance(for level: LevelDefinition) -> Float {
        let bounds = level.bounds
        let zoom = level.cameraZoom * CameraRig.maxPinch * CameraRig.landscapeAspect
        let corners = [
            SIMD3<Float>(bounds.minX, 0, bounds.minZ), SIMD3<Float>(bounds.maxX, 0, bounds.minZ),
            SIMD3<Float>(bounds.minX, 0, bounds.maxZ), SIMD3<Float>(bounds.maxX, 0, bounds.maxZ),
        ]
        // Worst case: the ball parked in one corner with the far corner still
        // wanting a shadow.
        var reach: Float = 0
        for ball in corners {
            let camera = ball + CameraRig.offset * zoom
            for target in corners { reach = max(reach, simd_distance(camera, target)) }
        }
        return reach
    }

    private static func buildLights(theme: CourseTheme, level: LevelDefinition, into root: Entity) {
        let sun = Entity()
        sun.name = "sun"
        sun.components.set(DirectionalLightComponent(color: theme.sunColor,
                                                     intensity: theme.sunIntensity))
        var shadow = DirectionalLightComponent.Shadow()
        shadow.shadowProjection = .automatic(maximumDistance: shadowDistance(for: level))
        sun.components.set(shadow)
        sun.look(at: SIMD3(-0.45, -1, -0.6), from: .zero, relativeTo: nil)
        root.addChild(sun)

        let fill = Entity()
        fill.name = "fill"
        fill.components.set(DirectionalLightComponent(color: .white,
                                                      intensity: theme.fillIntensity))
        fill.look(at: SIMD3(0.5, -0.7, 0.4), from: .zero, relativeTo: nil)
        root.addChild(fill)

        // Dark worlds need accent point lights for atmosphere.
        if theme.accentLights {
            let bounds = level.bounds
            let positions = [
                SIMD3(bounds.center.x, 1.1, bounds.minZ + bounds.size.y * 0.25),
                SIMD3(bounds.center.x, 1.1, bounds.minZ + bounds.size.y * 0.75),
            ]
            for (i, pos) in positions.enumerated() {
                let light = Entity()
                light.components.set(PointLightComponent(
                    color: i == 0 ? theme.accent : theme.wallTopColor,
                    intensity: 3000,
                    attenuationRadius: 5
                ))
                light.position = pos
                root.addChild(light)
            }
        }
    }

    // MARK: Decorations

    private static func buildDecorations(level: LevelDefinition, theme: CourseTheme, into root: Entity) {
        var rng = SplitMix64(seed: UInt64(level.course.order * 100 + level.number))
        let bounds = level.bounds
        let noGo = level.floors.map { $0.rect.expanded(by: 0.32) }

        let count = 22
        var placed: [SIMD2<Float>] = []
        for _ in 0..<count {
            // Sample in a band around the course.
            let x = rng.float(in: (bounds.minX - 2.4)...(bounds.maxX + 2.4))
            let z = rng.float(in: (bounds.minZ - 2.2)...(bounds.maxZ + 1.6))
            let point = SIMD2(x, z)
            if noGo.contains(where: { $0.contains(point) }) { continue }
            if placed.contains(where: { simd_distance($0, point) < 0.5 }) { continue }
            placed.append(point)

            let decor = makeDecoration(course: level.course, theme: theme, rng: &rng)
            decor.position = SIMD3(point.x, -0.225, point.y)
            root.addChild(decor)
        }
    }

    private static func makeDecoration(course: CourseType, theme: CourseTheme,
                                       rng: inout SplitMix64) -> Entity {
        let group = Entity()
        switch course {
        case .garden:
            if rng.chance(0.55) {
                // Tree
                let height = rng.float(in: 0.5...0.9)
                let trunk = ModelEntity(
                    mesh: .generateCylinder(height: height * 0.5, radius: 0.035),
                    materials: [simpleMaterial(UIColor(red: 0.42, green: 0.29, blue: 0.18, alpha: 1), roughness: 0.9)])
                trunk.position.y = height * 0.25
                group.addChild(trunk)
                let canopyColor = UIColor(
                    red: 0.18 + CGFloat(rng.float(in: 0...0.12)),
                    green: 0.5 + CGFloat(rng.float(in: 0...0.2)),
                    blue: 0.2, alpha: 1)
                let canopy = ModelEntity(
                    mesh: .generateSphere(radius: height * 0.32),
                    materials: [simpleMaterial(canopyColor, roughness: 0.95)])
                canopy.position.y = height * 0.62
                canopy.scale = SIMD3(1, 1.15, 1)
                group.addChild(canopy)
            } else if rng.chance(0.5) {
                // Bush
                let bush = ModelEntity(
                    mesh: .generateSphere(radius: rng.float(in: 0.1...0.18)),
                    materials: [simpleMaterial(UIColor(red: 0.25, green: 0.55, blue: 0.25, alpha: 1), roughness: 0.95)])
                bush.scale = SIMD3(1.2, 0.8, 1.2)
                bush.position.y = 0.06
                group.addChild(bush)
            } else {
                // Flower
                let stemHeight = rng.float(in: 0.1...0.16)
                let stem = ModelEntity(
                    mesh: .generateCylinder(height: stemHeight, radius: 0.006),
                    materials: [simpleMaterial(UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 1), roughness: 0.9)])
                stem.position.y = stemHeight / 2
                group.addChild(stem)
                let petals: [UIColor] = [.systemPink, .systemYellow, .white, .systemOrange]
                let head = ModelEntity(
                    mesh: .generateSphere(radius: 0.028),
                    materials: [simpleMaterial(petals[Int(rng.next() % 4)], roughness: 0.7)])
                head.position.y = stemHeight + 0.02
                group.addChild(head)
            }
        case .desert:
            if rng.chance(0.5) {
                // Cactus
                let height = rng.float(in: 0.3...0.55)
                let green = UIColor(red: 0.3, green: 0.55, blue: 0.3, alpha: 1)
                let body = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.05),
                    materials: [simpleMaterial(green, roughness: 0.85)])
                body.position.y = height / 2
                group.addChild(body)
                let arm = ModelEntity(
                    mesh: .generateCylinder(height: height * 0.4, radius: 0.032),
                    materials: [simpleMaterial(green, roughness: 0.85)])
                arm.position = SIMD3(0.08, height * 0.55, 0)
                group.addChild(arm)
                let cap = ModelEntity(
                    mesh: .generateSphere(radius: 0.05),
                    materials: [simpleMaterial(green, roughness: 0.85)])
                cap.position.y = height
                group.addChild(cap)
            } else {
                // Rock
                let rock = ModelEntity(
                    mesh: .generateSphere(radius: rng.float(in: 0.08...0.2)),
                    materials: [simpleMaterial(UIColor(red: 0.6, green: 0.5, blue: 0.42, alpha: 1), roughness: 1.0)])
                rock.scale = SIMD3(1.3, rng.float(in: 0.5...0.75), 1.0)
                rock.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)), axis: SIMD3(0, 1, 0))
                rock.position.y = 0.03
                group.addChild(rock)
            }
        case .jungle:
            if rng.chance(0.5) {
                // Palm: bare trunk with a crown of drooping fronds.
                let height = rng.float(in: 0.55...0.95)
                let trunk = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.028),
                    materials: [simpleMaterial(UIColor(red: 0.38, green: 0.30, blue: 0.20, alpha: 1),
                                               roughness: 0.9)])
                trunk.position.y = height / 2
                trunk.orientation = simd_quatf(angle: rng.float(in: -0.1...0.1), axis: SIMD3(0, 0, 1))
                group.addChild(trunk)
                let frondColor = UIColor(red: 0.16, green: 0.42 + CGFloat(rng.float(in: 0...0.16)),
                                         blue: 0.20, alpha: 1)
                // Each frond hangs off the crown, so the holder sits at the top
                // of the trunk and only tilts the leaf outward and down.
                for i in 0..<5 {
                    let frond = ModelEntity(
                        mesh: .generateBox(width: 0.26, height: 0.012, depth: 0.08,
                                           cornerRadius: 0.03),
                        materials: [simpleMaterial(frondColor, roughness: 0.95)])
                    frond.position = SIMD3(0.14, 0, 0)
                    let holder = Entity()
                    holder.position.y = height - 0.02
                    holder.orientation = simd_quatf(angle: Float(i) * 1.256, axis: SIMD3(0, 1, 0)) *
                                         simd_quatf(angle: -0.42, axis: SIMD3(0, 0, 1))
                    holder.addChild(frond)
                    group.addChild(holder)
                }
            } else if rng.chance(0.55) {
                // Fern clump
                let color = UIColor(red: 0.17, green: 0.44, blue: 0.22, alpha: 1)
                for i in 0..<4 {
                    let leaf = ModelEntity(
                        mesh: .generateBox(width: 0.05, height: 0.16, depth: 0.02,
                                           cornerRadius: 0.02),
                        materials: [simpleMaterial(color, roughness: 0.95)])
                    leaf.position = SIMD3(0, 0.08, 0)
                    let holder = Entity()
                    holder.orientation = simd_quatf(angle: Float(i) * 1.57, axis: SIMD3(0, 1, 0)) *
                                         simd_quatf(angle: 0.42, axis: SIMD3(0, 0, 1))
                    holder.addChild(leaf)
                    group.addChild(holder)
                }
            } else {
                // Toppled temple column
                let height = rng.float(in: 0.18...0.34)
                let stone = simpleMaterial(theme.wallTopColor, roughness: 0.95)
                let column = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.055),
                    materials: [stone])
                column.position.y = height / 2
                group.addChild(column)
                let capital = ModelEntity(
                    mesh: .generateBox(width: 0.14, height: 0.035, depth: 0.14, cornerRadius: 0.008),
                    materials: [stone])
                capital.position.y = height
                group.addChild(capital)
                group.orientation = simd_quatf(angle: rng.float(in: -0.2...0.2), axis: SIMD3(0, 0, 1))
            }
        case .ice:
            if rng.chance(0.45) {
                // Snow-laden fir
                let height = rng.float(in: 0.5...0.9)
                let trunk = ModelEntity(
                    mesh: .generateCylinder(height: height * 0.3, radius: 0.026),
                    materials: [simpleMaterial(UIColor(red: 0.34, green: 0.26, blue: 0.20, alpha: 1),
                                               roughness: 0.9)])
                trunk.position.y = height * 0.15
                group.addChild(trunk)
                let needle = simpleMaterial(UIColor(red: 0.14, green: 0.34, blue: 0.28, alpha: 1),
                                            roughness: 0.9)
                for i in 0..<3 {
                    let t = Float(i)
                    let tier = ModelEntity(
                        mesh: .generateCone(height: height * 0.4, radius: height * (0.22 - t * 0.05)),
                        materials: [needle])
                    tier.position.y = height * (0.3 + t * 0.22)
                    group.addChild(tier)
                }
                let cap = ModelEntity(
                    mesh: .generateSphere(radius: height * 0.07),
                    materials: [simpleMaterial(.white, roughness: 0.85)])
                cap.position.y = height * 0.92
                group.addChild(cap)
            } else if rng.chance(0.55) {
                // Ice shard
                let height = rng.float(in: 0.22...0.5)
                var material = PhysicallyBasedMaterial()
                material.baseColor = .init(tint: theme.iceColor)
                material.roughness = 0.12
                material.metallic = 0.1
                material.blending = .transparent(opacity: 0.82)
                let shard = ModelEntity(
                    mesh: .generateCone(height: height, radius: height * 0.24),
                    materials: [material])
                shard.position.y = height / 2
                shard.orientation = simd_quatf(angle: rng.float(in: -0.2...0.2), axis: SIMD3(0, 0, 1))
                group.addChild(shard)
            } else {
                // Snow drift
                let drift = ModelEntity(
                    mesh: .generateSphere(radius: rng.float(in: 0.12...0.24)),
                    materials: [simpleMaterial(UIColor(white: 0.97, alpha: 1), roughness: 0.85)])
                drift.scale = SIMD3(1.4, rng.float(in: 0.35...0.6), 1.2)
                drift.position.y = 0.03
                group.addChild(drift)
            }
        case .volcano:
            if rng.chance(0.4) {
                // Basalt spire
                let height = rng.float(in: 0.3...0.7)
                let rock = simpleMaterial(UIColor(red: 0.17, green: 0.15, blue: 0.15, alpha: 1),
                                          roughness: 1.0)
                let spire = ModelEntity(
                    mesh: .generateBox(width: 0.13, height: height, depth: 0.13, cornerRadius: 0.01),
                    materials: [rock])
                spire.position.y = height / 2
                spire.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)), axis: SIMD3(0, 1, 0)) *
                                    simd_quatf(angle: rng.float(in: -0.12...0.12), axis: SIMD3(0, 0, 1))
                group.addChild(spire)
            } else if rng.chance(0.5) {
                // Glowing vent
                var material = PhysicallyBasedMaterial()
                material.baseColor = .init(tint: theme.lavaColor)
                material.emissiveColor = .init(color: theme.lavaColor)
                material.emissiveIntensity = 2.2
                material.roughness = 0.6
                let pool = ModelEntity(
                    mesh: .generateCylinder(height: 0.02, radius: rng.float(in: 0.09...0.2)),
                    materials: [material])
                pool.position.y = 0.02
                group.addChild(pool)
                let crust = ModelEntity(
                    mesh: .generateSphere(radius: 0.07),
                    materials: [simpleMaterial(UIColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 1),
                                               roughness: 1.0)])
                crust.scale = SIMD3(1.5, 0.4, 1.3)
                crust.position.y = 0.01
                group.addChild(crust)
            } else {
                // Charred stump
                let height = rng.float(in: 0.22...0.45)
                let charred = simpleMaterial(UIColor(red: 0.14, green: 0.11, blue: 0.10, alpha: 1),
                                             roughness: 1.0)
                let trunk = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.03),
                    materials: [charred])
                trunk.position.y = height / 2
                group.addChild(trunk)
                let branch = ModelEntity(
                    mesh: .generateCylinder(height: height * 0.5, radius: 0.018),
                    materials: [charred])
                branch.position = SIMD3(0.05, height * 0.8, 0)
                branch.orientation = simd_quatf(angle: 0.7, axis: SIMD3(0, 0, 1))
                group.addChild(branch)
            }
        case .clockwork:
            if rng.chance(0.45) {
                // Cog on a stand: a hub with teeth around it.
                let brass = simpleMaterial(theme.wallTopColor, roughness: 0.35, metallic: 0.8)
                let radius = rng.float(in: 0.14...0.26)
                let post = ModelEntity(
                    mesh: .generateCylinder(height: 0.16, radius: 0.02),
                    materials: [simpleMaterial(UIColor(white: 0.35, alpha: 1), roughness: 0.6)])
                post.position.y = 0.08
                group.addChild(post)
                let cog = Entity()
                cog.position.y = 0.16
                cog.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
                let disc = ModelEntity(
                    mesh: .generateCylinder(height: 0.03, radius: radius),
                    materials: [brass])
                disc.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
                cog.addChild(disc)
                for i in 0..<10 {
                    let angle = Float(i) * .pi / 5
                    let tooth = ModelEntity(
                        mesh: .generateBox(width: 0.05, height: 0.05, depth: 0.03,
                                           cornerRadius: 0.008),
                        materials: [brass])
                    tooth.position = SIMD3(cos(angle) * radius, sin(angle) * radius, 0)
                    tooth.orientation = simd_quatf(angle: angle, axis: SIMD3(0, 0, 1))
                    cog.addChild(tooth)
                }
                group.addChild(cog)
            } else if rng.chance(0.5) {
                // Boiler with a chimney
                let iron = simpleMaterial(UIColor(red: 0.30, green: 0.24, blue: 0.20, alpha: 1),
                                          roughness: 0.7, metallic: 0.4)
                let height = rng.float(in: 0.22...0.4)
                let drum = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.11),
                    materials: [iron])
                drum.position.y = height / 2
                group.addChild(drum)
                let pipe = ModelEntity(
                    mesh: .generateCylinder(height: 0.22, radius: 0.026),
                    materials: [simpleMaterial(theme.wallTopColor, roughness: 0.4, metallic: 0.7)])
                pipe.position = SIMD3(0.05, height + 0.11, 0)
                group.addChild(pipe)
            } else {
                // Stack of crates
                let wood = simpleMaterial(UIColor(red: 0.44, green: 0.30, blue: 0.16, alpha: 1),
                                          roughness: 0.95)
                for i in 0..<2 {
                    let side = rng.float(in: 0.12...0.18)
                    let crate = ModelEntity(
                        mesh: .generateBox(width: side, height: side, depth: side,
                                           cornerRadius: 0.006),
                        materials: [wood])
                    crate.position = SIMD3(rng.float(in: -0.04...0.04), side * (Float(i) + 0.5),
                                           rng.float(in: -0.04...0.04))
                    crate.orientation = simd_quatf(angle: rng.float(in: 0...1.2),
                                                   axis: SIMD3(0, 1, 0))
                    group.addChild(crate)
                }
            }
        case .storm:
            if rng.chance(0.4) {
                // Wave-worn boulder
                let rock = ModelEntity(
                    mesh: .generateSphere(radius: rng.float(in: 0.1...0.24)),
                    materials: [simpleMaterial(UIColor(red: 0.34, green: 0.37, blue: 0.40, alpha: 1),
                                               roughness: 0.9)])
                rock.scale = SIMD3(1.25, rng.float(in: 0.5...0.8), 1.1)
                rock.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)),
                                              axis: SIMD3(0, 1, 0))
                rock.position.y = 0.04
                group.addChild(rock)
            } else if rng.chance(0.5) {
                // Mooring post with a lantern on top
                let height = rng.float(in: 0.3...0.55)
                let post = ModelEntity(
                    mesh: .generateCylinder(height: height, radius: 0.035),
                    materials: [simpleMaterial(UIColor(red: 0.33, green: 0.27, blue: 0.22, alpha: 1),
                                               roughness: 0.95)])
                post.position.y = height / 2
                post.orientation = simd_quatf(angle: rng.float(in: -0.1...0.1), axis: SIMD3(0, 0, 1))
                group.addChild(post)
                var glass = PhysicallyBasedMaterial()
                glass.baseColor = .init(tint: theme.accent)
                glass.emissiveColor = .init(color: theme.accent)
                glass.emissiveIntensity = 1.4
                glass.roughness = 0.3
                let lamp = ModelEntity(mesh: .generateSphere(radius: 0.035), materials: [glass])
                lamp.position.y = height + 0.02
                group.addChild(lamp)
            } else {
                // Tussock of salt grass
                let color = UIColor(red: 0.42, green: 0.48, blue: 0.32, alpha: 1)
                for i in 0..<5 {
                    let blade = ModelEntity(
                        mesh: .generateBox(width: 0.014, height: rng.float(in: 0.12...0.2),
                                           depth: 0.01, cornerRadius: 0.005),
                        materials: [simpleMaterial(color, roughness: 0.95)])
                    blade.position = SIMD3(0, 0.07, 0)
                    let holder = Entity()
                    holder.orientation = simd_quatf(angle: Float(i) * 1.256, axis: SIMD3(0, 1, 0)) *
                                         simd_quatf(angle: rng.float(in: 0.3...0.7),
                                                    axis: SIMD3(0, 0, 1))
                    holder.addChild(blade)
                    group.addChild(holder)
                }
            }
        case .cosmos:
            if rng.chance(0.4) {
                // Solar array on a mast
                let mast = ModelEntity(
                    mesh: .generateCylinder(height: 0.34, radius: 0.014),
                    materials: [simpleMaterial(UIColor(white: 0.7, alpha: 1),
                                               roughness: 0.3, metallic: 0.8)])
                mast.position.y = 0.17
                group.addChild(mast)
                var panelMaterial = PhysicallyBasedMaterial()
                panelMaterial.baseColor = .init(tint: UIColor(red: 0.10, green: 0.16, blue: 0.42,
                                                              alpha: 1))
                panelMaterial.emissiveColor = .init(color: theme.groundDetail)
                panelMaterial.emissiveIntensity = 0.5
                panelMaterial.roughness = 0.2
                panelMaterial.metallic = 0.6
                for side: Float in [-1, 1] {
                    let panel = ModelEntity(
                        mesh: .generateBox(width: 0.22, height: 0.008, depth: 0.13,
                                           cornerRadius: 0.004),
                        materials: [panelMaterial])
                    panel.position = SIMD3(side * 0.13, 0.33, 0)
                    panel.orientation = simd_quatf(angle: side * 0.3, axis: SIMD3(0, 0, 1))
                    group.addChild(panel)
                }
            } else if rng.chance(0.5) {
                // Dish antenna
                let stand = ModelEntity(
                    mesh: .generateCylinder(height: 0.18, radius: 0.02),
                    materials: [simpleMaterial(UIColor(white: 0.55, alpha: 1),
                                               roughness: 0.35, metallic: 0.7)])
                stand.position.y = 0.09
                group.addChild(stand)
                let dish = ModelEntity(
                    mesh: .generateCone(height: 0.1, radius: rng.float(in: 0.11...0.17)),
                    materials: [simpleMaterial(UIColor(white: 0.86, alpha: 1), roughness: 0.4)])
                dish.position.y = 0.24
                dish.orientation = simd_quatf(angle: .pi, axis: SIMD3(0, 0, 1)) *
                                   simd_quatf(angle: rng.float(in: -0.5...0.5), axis: SIMD3(1, 0, 0))
                group.addChild(dish)
            } else {
                // Drifting chunk of rock, lit from the station
                let stone = ModelEntity(
                    mesh: .generateSphere(radius: rng.float(in: 0.08...0.18)),
                    materials: [simpleMaterial(UIColor(red: 0.26, green: 0.25, blue: 0.28, alpha: 1),
                                               roughness: 1.0)])
                stone.scale = SIMD3(1.2, rng.float(in: 0.6...0.9), 1.0)
                stone.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)),
                                               axis: SIMD3(0, 1, 0))
                stone.position.y = rng.float(in: 0.05...0.3)
                group.addChild(stone)
            }
        case .neon:
            // Glowing crystals
            let palette = [theme.accent, theme.wallTopColor,
                           UIColor(red: 0.55, green: 0.3, blue: 1.0, alpha: 1)]
            let color = palette[Int(rng.next() % 3)]
            let height = rng.float(in: 0.25...0.6)
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: color)
            material.emissiveColor = .init(color: color)
            material.emissiveIntensity = 1.6
            material.roughness = 0.35
            let crystal = ModelEntity(
                mesh: .generateCone(height: height, radius: height * 0.2),
                materials: [material])
            crystal.position.y = height / 2
            crystal.orientation = simd_quatf(angle: rng.float(in: -0.15...0.15), axis: SIMD3(0, 0, 1))
            group.addChild(crystal)
        }
        return group
    }

    static func simpleMaterial(_ color: UIColor, roughness: Float,
                               metallic: Float = 0) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: metallic)
        return material
    }
}

// MARK: - Theme materials

struct ThemeMaterials {
    let theme: CourseTheme
    let course: CourseType

    private let feltTexture: TextureResource?
    private let sandTexture: TextureResource?
    private let mudTexture: TextureResource?
    private let iceTexture: TextureResource?
    private let groundTexture: TextureResource?

    let wall: PhysicallyBasedMaterial
    let wallGlow: UnlitMaterial
    let water: PhysicallyBasedMaterial
    let lava: PhysicallyBasedMaterial
    let holeRim: PhysicallyBasedMaterial
    let holeCup: UnlitMaterial
    let pole: PhysicallyBasedMaterial
    let flag: PhysicallyBasedMaterial
    let teeMarker: PhysicallyBasedMaterial
    let ground: any RealityKit.Material
    let accent: PhysicallyBasedMaterial
    /// Speed bumps: felt lifted toward the light so a 4 cm crest still reads.
    let bumpCrest: PhysicallyBasedMaterial
    /// Tinted skin marking a banked green.
    let slopeTint: PhysicallyBasedMaterial
    /// Belt bed and the chevrons that ride along it.
    let beltBed: PhysicallyBasedMaterial
    let chevron: UnlitMaterial
    /// Portal ring, its swirling core, and the pegs around the rim.
    let portalRim: PhysicallyBasedMaterial
    let portalCore: UnlitMaterial
    /// Machined steel for gates and pendulum hardware.
    let metal: PhysicallyBasedMaterial
    let star: UnlitMaterial

    init(theme: CourseTheme, course: CourseType) {
        self.theme = theme
        self.course = course

        feltTexture = TextureFactory.stripes(theme.feltTop, theme.feltStripe, key: course.rawValue)
        sandTexture = TextureFactory.speckle(theme.sandColor, theme.sandDetail,
                                             key: "sand-\(course.rawValue)")
        mudTexture = TextureFactory.speckle(theme.mudColor, theme.mudColor.darkened(),
                                            key: "mud-\(course.rawValue)", seed: 11, dots: 700)
        iceTexture = TextureFactory.cracks(theme.iceColor, .white, key: course.rawValue)
        // The glowing worlds get a Tron grid under the course instead of dirt.
        if theme.emissiveWalls {
            groundTexture = TextureFactory.grid(theme.groundColor, theme.groundDetail,
                                                key: course.rawValue)
        } else {
            groundTexture = TextureFactory.speckle(theme.groundColor, theme.groundDetail,
                                                   key: "ground-\(course.rawValue)", seed: 5, dots: 1400)
        }

        var wallMat = PhysicallyBasedMaterial()
        wallMat.baseColor = .init(tint: theme.wallColor)
        wallMat.roughness = 0.75
        wall = wallMat

        var glow = UnlitMaterial()
        glow.color = .init(tint: theme.wallTopColor)
        wallGlow = glow

        var waterMat = PhysicallyBasedMaterial()
        waterMat.baseColor = .init(tint: theme.waterColor)
        waterMat.roughness = 0.08
        waterMat.metallic = 0.1
        waterMat.blending = .transparent(opacity: 0.9)
        if theme.emissiveWalls {
            waterMat.emissiveColor = .init(color: theme.waterColor)
            waterMat.emissiveIntensity = 1.4
        }
        water = waterMat

        // Molten rock, not a flat orange rectangle: the crack texture doubles as
        // dark crust over the glow, and the emissive stays low enough to keep it.
        var lavaMat = PhysicallyBasedMaterial()
        if let crust = TextureFactory.cracks(theme.lavaColor, UIColor(white: 0.06, alpha: 1),
                                            key: "lava-\(course.rawValue)") {
            let texture = ThemeMaterials.tiled(crust)
            lavaMat.baseColor = .init(tint: .white, texture: texture)
            lavaMat.emissiveColor = .init(color: theme.lavaColor, texture: texture)
        } else {
            lavaMat.baseColor = .init(tint: theme.lavaColor)
            lavaMat.emissiveColor = .init(color: theme.lavaColor)
        }
        lavaMat.roughness = 0.65
        lavaMat.emissiveIntensity = 1.5
        lava = lavaMat

        var rimMat = PhysicallyBasedMaterial()
        rimMat.baseColor = .init(tint: UIColor(white: 0.95, alpha: 1))
        rimMat.roughness = 0.5
        holeRim = rimMat

        var cupMat = UnlitMaterial()
        cupMat.color = .init(tint: UIColor(white: 0.03, alpha: 1))
        holeCup = cupMat

        pole = SceneBuilder.simpleMaterial(UIColor(white: 0.92, alpha: 1), roughness: 0.4, metallic: 0.3)

        var flagMat = PhysicallyBasedMaterial()
        flagMat.baseColor = .init(tint: theme.accent)
        flagMat.roughness = 0.7
        if theme.emissiveWalls {
            flagMat.emissiveColor = .init(color: theme.accent)
            flagMat.emissiveIntensity = 1.2
        }
        flag = flagMat

        var teeMat = PhysicallyBasedMaterial()
        teeMat.baseColor = .init(tint: theme.feltStripe.withAlphaComponent(1))
        teeMat.roughness = 0.9
        teeMarker = teeMat

        if theme.emissiveWalls, let groundTexture {
            // Tron-style glowing grid: unlit keeps the night truly dark.
            var neonGround = UnlitMaterial()
            neonGround.color = .init(tint: .white, texture: ThemeMaterials.tiled(groundTexture))
            neonGround.textureCoordinateTransform = .init(scale: SIMD2(12, 12))
            ground = neonGround
        } else {
            var groundMat = PhysicallyBasedMaterial()
            if let groundTexture {
                groundMat.baseColor = .init(tint: .white, texture: ThemeMaterials.tiled(groundTexture))
                groundMat.textureCoordinateTransform = .init(scale: SIMD2(12, 12))
            } else {
                groundMat.baseColor = .init(tint: theme.groundColor)
            }
            groundMat.roughness = 1.0
            ground = groundMat
        }

        accent = SceneBuilder.simpleMaterial(theme.accent, roughness: 0.55)

        var crestColor = UIColor.white
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (1, 1, 1, 1)
        if theme.feltTop.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let lift: CGFloat = theme.emissiveWalls ? 0.30 : 0.22
            crestColor = UIColor(red: r + (1 - r) * lift, green: g + (1 - g) * lift,
                                 blue: b + (1 - b) * lift, alpha: a)
        }
        bumpCrest = SceneBuilder.simpleMaterial(crestColor, roughness: 0.92)

        // A banked green is a lie the physics tells, so the skin has to sell it:
        // a translucent wash plus the drift arrows built on top.
        var slopeMat = PhysicallyBasedMaterial()
        slopeMat.baseColor = .init(tint: crestColor)
        slopeMat.roughness = 0.85
        slopeMat.blending = .transparent(opacity: 0.55)
        slopeTint = slopeMat

        beltBed = SceneBuilder.simpleMaterial(theme.wallColor.darkened(by: 0.2), roughness: 0.55)

        var chevronMat = UnlitMaterial(color: theme.accent)
        chevronMat.blending = .transparent(opacity: 0.95)
        chevron = chevronMat

        var rimMaterial = PhysicallyBasedMaterial()
        rimMaterial.baseColor = .init(tint: theme.accent)
        rimMaterial.roughness = 0.3
        rimMaterial.metallic = 0.6
        rimMaterial.emissiveColor = .init(color: theme.accent)
        rimMaterial.emissiveIntensity = 1.4
        portalRim = rimMaterial

        // Pale cyan core reads as "way through" against both the jungle's gold
        // rings and the neon world's magenta ones.
        var coreMat = UnlitMaterial(color: UIColor(red: 0.72, green: 0.95, blue: 1.0, alpha: 1))
        coreMat.blending = .transparent(opacity: 0.85)
        portalCore = coreMat

        metal = SceneBuilder.simpleMaterial(UIColor(white: 0.62, alpha: 1),
                                           roughness: 0.35, metallic: 0.85)
        star = UnlitMaterial(color: UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1))
    }

    /// Skin for a sand, mud or ice patch.
    func overlay(kind: FloorPatch.Kind, size: SIMD2<Float>) -> PhysicallyBasedMaterial {
        switch kind {
        case .mud:
            return textured(mudTexture, tint: theme.mudColor, size: size,
                            tile: 0.6, roughness: 1.0)
        case .ice:
            var material = textured(iceTexture, tint: theme.iceColor, size: size,
                                    tile: 0.8, roughness: 0.08)
            material.metallic = 0.15
            material.blending = .transparent(opacity: 0.88)
            return material
        default:
            return sand(size: size)
        }
    }

    private func textured(_ texture: TextureResource?, tint: UIColor, size: SIMD2<Float>,
                          tile: Float, roughness: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        if let texture {
            material.baseColor = .init(tint: .white, texture: ThemeMaterials.tiled(texture))
            let repeats = SIMD2(max(1, (size.x / tile).rounded()), max(1, (size.y / tile).rounded()))
            material.textureCoordinateTransform = .init(scale: repeats)
        } else {
            material.baseColor = .init(tint: tint)
        }
        material.roughness = .init(floatLiteral: roughness)
        return material
    }

    /// Felt material with mowing stripes scaled to the patch size.
    func felt(size: SIMD2<Float>) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        if let feltTexture {
            material.baseColor = .init(tint: .white, texture: ThemeMaterials.tiled(feltTexture))
            let repeats = SIMD2(max(1, (size.x / 0.9).rounded()), max(1, (size.y / 0.9).rounded()))
            material.textureCoordinateTransform = .init(scale: repeats)
        } else {
            material.baseColor = .init(tint: theme.feltTop)
        }
        material.roughness = 0.92
        return material
    }

    func sand(size: SIMD2<Float>) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        if let sandTexture {
            material.baseColor = .init(tint: .white, texture: ThemeMaterials.tiled(sandTexture))
            let repeats = SIMD2(max(1, (size.x / 0.5).rounded()), max(1, (size.y / 0.5).rounded()))
            material.textureCoordinateTransform = .init(scale: repeats)
        } else {
            material.baseColor = .init(tint: theme.sandColor)
        }
        material.roughness = 1.0
        return material
    }

    /// Wraps a texture with a repeating sampler.
    static func tiled(_ resource: TextureResource) -> MaterialParameters.Texture {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        return MaterialParameters.Texture(resource, sampler: .init(descriptor))
    }
}

// MARK: - Colour helpers

extension UIColor {
    /// The same colour pushed toward black — detail speckle, belt beds.
    func darkened(by amount: CGFloat = 0.35) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let k = 1 - amount
        return UIColor(red: r * k, green: g * k, blue: b * k, alpha: a)
    }
}
