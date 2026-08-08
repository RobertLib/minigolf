//
//  Scenery.swift
//  Minigolf
//
//  The world outside the boards: the sky, the ground the hole stands on, the
//  landmarks on the skyline and the weather drifting through the air.
//
//  None of it carries a collider and nothing here is ever asked a question by
//  the physics — it exists so the hole has somewhere to be. Placement runs off
//  the hole's own `SplitMix64` seed the way the decorations do, so a hole looks
//  the same every time it is replayed, and everything that moves is a pure
//  function of the game clock, like the obstacles and the critters.
//

import Foundation
import RealityKit
import UIKit
import simd

enum Scenery {

    /// Top surface of the terrain slab: what every prop outside the course
    /// stands on.
    static let groundY: Float = -0.225

    /// How far past the boards the ground runs before the sky takes over.
    ///
    /// The slab has to end somewhere, and wherever it ends it draws a straight
    /// line across the view. 24 m puts that line comfortably behind the
    /// skyline props at full pinch-out, so what the player reads as the horizon
    /// is the ridge of hills rather than the edge of a box.
    private static let terrainMargin: Float = 24

    /// Ring the skyline sits on, measured out from the edge of the course.
    /// Inside the slab, outside the band the small decorations use.
    private static let horizonRing: ClosedRange<Float> = 8.5...12.0

    /// How many of each thing a hole gets.
    ///
    /// All of this is draw calls, and none of it is gameplay — so the counts
    /// are collected here rather than buried at their use sites, and they are
    /// deliberately modest. The camera sits a metre over the felt looking down
    /// the lane: the skyline is the part that is on screen least, so it is the
    /// part with the fewest pieces, and the weather is a shared mesh and a
    /// shared material however many specks it runs.
    private static let mountCount = 10
    private static let landmarkCount = 12

    // MARK: - Sky

    static func buildSky(theme: CourseTheme, course: CourseType, into root: Entity) {
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

    // MARK: - Terrain

    static func buildTerrain(level: LevelDefinition, theme: CourseTheme,
                             materials: ThemeMaterials, into root: Entity) {
        let bounds = level.bounds
        let size = bounds.size + SIMD2(repeating: terrainMargin)
        // Speckle stays the same size on screen whatever the hole measures: the
        // tile count follows the slab instead of being fixed at its old width.
        let slab = ModelEntity(
            mesh: .generateBox(width: size.x, height: 0.05, depth: size.y),
            materials: [materials.groundMaterial(tiles: max(size.x, size.y) / 1.25)]
        )
        slab.name = "terrain"
        slab.position = SIMD3(bounds.center.x, groundY - 0.025, bounds.center.y)
        root.addChild(slab)

        buildMounds(level: level, theme: theme, into: root)
    }

    /// Low swells in the ground around the course.
    ///
    /// A single slab reads as a table top no matter how good the texture on it
    /// is — the giveaway is that the silhouette against the sky is perfectly
    /// straight. A dozen wide, shallow domes break that line without adding
    /// anything the ball can ever reach.
    private static func buildMounds(level: LevelDefinition, theme: CourseTheme, into root: Entity) {
        var rng = SplitMix64(seed: UInt64(level.course.order * 613 + level.number * 17 + 3))
        let bounds = level.bounds
        let half = bounds.size / 2

        // Three shared tones rather than one per mound: same variation on
        // screen, a third of the materials for the renderer to sort.
        let tones = [
            SceneBuilder.simpleMaterial(theme.groundColor, roughness: 1.0),
            SceneBuilder.simpleMaterial(theme.groundColor.blended(with: theme.groundDetail,
                                                                  amount: 0.45), roughness: 1.0),
            SceneBuilder.simpleMaterial(theme.groundColor.blended(with: theme.skyHorizon,
                                                                  amount: 0.18), roughness: 1.0),
        ]

        for i in 0..<mountCount {
            let slice = 2 * Float.pi / Float(mountCount)
            let angle = (Float(i) + rng.float(in: 0.1...0.9)) * slice
            let distance = rng.float(in: 3.0...9.0)
            let radius = rng.float(in: 1.0...2.8)
            let dome = Prim.sphere(radius: radius, material: tones[Int(rng.next() % 3)])
            dome.scale *= SIMD3(rng.float(in: 0.8...1.3),
                                rng.float(in: 0.10...0.22),
                                rng.float(in: 0.8...1.3))
            // Sunk to its waist, so only the swell shows above the slab.
            dome.position = SIMD3(bounds.center.x + cos(angle) * (half.x + distance),
                                  groundY - 0.02,
                                  bounds.center.y + sin(angle) * (half.y + distance))
            root.addChild(dome)
        }
    }

    // MARK: - Apron

    /// How far the paving runs out from the boards. A lane is about a metre
    /// across, so much more than this stops reading as a path and starts
    /// reading as a plaza the hole happens to sit on.
    static let apronWidth: Float = 0.45

    /// The plot the hole stands on: paving around the boards, with a kerb along
    /// its outer edge.
    ///
    /// Two things make this the best metre of scenery in the scene. It is the
    /// one the camera never loses — sitting a metre above the felt and looking
    /// down the lane, the player has the strip beside the boards in shot on
    /// every single frame, and until now that strip was bare terrain. And it
    /// closes a hole in the geometry: a floor slab stops 6 cm under the felt
    /// while the terrain is 22 cm down, so the course was floating over a
    /// finger-wide gap that showed from any low angle.
    ///
    /// Built as a frame from the hole's bounding box rather than per floor
    /// patch. The interior is left completely alone, so no part of it can land
    /// on a water hazard, fight a felt slab for the same depth, or double up
    /// with itself where two patches meet.
    static func buildApron(level: LevelDefinition, theme: CourseTheme, into root: Entity) {
        // Tucked a couple of centimetres under the floor slabs, so the seam at
        // the boards is covered rather than butted.
        let inner = level.bounds.expanded(by: -0.02)
        let outer = level.bounds.expanded(by: apronWidth)
        let top: Float = -0.07
        let depth = top - (groundY - 0.01)

        // Mixed toward the side of the boards, never their lit top: the top is
        // the world's brightest colour, and a metre-wide band of it running the
        // length of the lane pulls the eye clean off the felt. In the neon
        // worlds that is not a figure of speech — the top is pure cyan.
        let paving = SceneBuilder.simpleMaterial(
            theme.groundColor.blended(with: theme.wallColor, amount: 0.45).darkened(by: 0.08),
            roughness: 1.0)

        func slab(x0: Float, x1: Float, z0: Float, z1: Float) {
            let entity = Prim.box(width: x1 - x0,
                                  height: depth,
                                  depth: z1 - z0,
                                  material: paving)
            entity.name = "apron"
            entity.position = SIMD3((x0 + x1) / 2, top - depth / 2, (z0 + z1) / 2)
            root.addChild(entity)
        }
        slab(x0: outer.minX, x1: outer.maxX, z0: outer.minZ, z1: inner.minZ)
        slab(x0: outer.minX, x1: outer.maxX, z0: inner.maxZ, z1: outer.maxZ)
        slab(x0: outer.minX, x1: inner.minX, z0: inner.minZ, z1: inner.maxZ)
        slab(x0: inner.maxX, x1: outer.maxX, z0: inner.minZ, z1: inner.maxZ)

        // Kerb. The glowing worlds get a light strip instead of a stone lip —
        // same outline, read off emission rather than off a sun they barely
        // have. It stops 2 cm below the felt, well clear of anything the ball
        // can touch.
        let kerbMaterial: any RealityKit.Material
        if theme.emissiveWalls {
            var lit = UnlitMaterial()
            // Dimmed hard: a full-strength strip this close to the camera is a
            // floodlight, not a trim.
            lit.color = .init(tint: theme.wallTopColor.darkened(by: 0.55))
            kerbMaterial = lit
        } else {
            kerbMaterial = SceneBuilder.simpleMaterial(theme.wallTopColor.darkened(by: 0.2),
                                                       roughness: 0.65)
        }
        let lip: Float = 0.06
        func kerb(x0: Float, x1: Float, z0: Float, z1: Float) {
            let entity = Prim.roundedBox(width: x1 - x0,
                                         height: 0.06,
                                         depth: z1 - z0,
                                         cornerRadius: 0.012,
                                         material: kerbMaterial)
            entity.name = "kerb"
            entity.position = SIMD3((x0 + x1) / 2, top - 0.01, (z0 + z1) / 2)
            root.addChild(entity)
        }
        kerb(x0: outer.minX, x1: outer.maxX, z0: outer.minZ, z1: outer.minZ + lip)
        kerb(x0: outer.minX, x1: outer.maxX, z0: outer.maxZ - lip, z1: outer.maxZ)
        kerb(x0: outer.minX, x1: outer.minX + lip, z0: outer.minZ + lip, z1: outer.maxZ - lip)
        kerb(x0: outer.maxX - lip, x1: outer.maxX, z0: outer.minZ + lip, z1: outer.maxZ - lip)
    }

    // MARK: - Skyline

    static func buildHorizon(level: LevelDefinition, theme: CourseTheme, into root: Entity) {
        var rng = SplitMix64(seed: UInt64(level.course.order * 7919 + level.number * 131 + 5))
        let bounds = level.bounds
        let half = bounds.size / 2

        for i in 0..<landmarkCount {
            let slice = 2 * Float.pi / Float(landmarkCount)
            let angle = (Float(i) + rng.float(in: 0.15...0.85)) * slice
            let distance = rng.float(in: horizonRing)
            let landmark = makeLandmark(course: level.course, theme: theme, rng: &rng)
            landmark.position = SIMD3(bounds.center.x + cos(angle) * (half.x + distance),
                                      groundY,
                                      bounds.center.y + sin(angle) * (half.y + distance))
            landmark.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)),
                                              axis: SIMD3(0, 1, 0))
            root.addChild(landmark)
        }

        // The orbital station has no skyline to speak of, so it gets the one
        // thing that reads as distance in vacuum: something enormous, far off.
        if level.course == .cosmos {
            root.addChild(makePlanet(theme: theme, bounds: bounds, rng: &rng))
        }
    }

    /// Everything on the skyline is washed toward the sky before it is drawn.
    ///
    /// Distance eats contrast, and without that wash a hill 10 m out is painted
    /// in exactly the same greens as the felt 1 m out — the eye then reads the
    /// two as the same distance and the hole loses its depth.
    private static func faded(_ color: UIColor, _ theme: CourseTheme,
                              _ amount: CGFloat = 0.32) -> UIColor {
        color.blended(with: theme.skyHorizon, amount: amount)
    }

    private static func makeLandmark(course: CourseType, theme: CourseTheme,
                                     rng: inout SplitMix64) -> Entity {
        let group = Entity()
        switch course {
        case .garden:
            if rng.chance(0.65) {
                // Rolling hill with a copse on its shoulder.
                let radius = rng.float(in: 2.2...4.0)
                let lift = rng.float(in: 0.30...0.48)
                let hillMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.32, green: 0.50, blue: 0.26, alpha: 1), theme),
                    roughness: 1.0)
                let hill = Prim.sphere(radius: radius, material: hillMaterial)
                hill.scale *= SIMD3(1, lift, rng.float(in: 0.8...1.2))
                group.addChild(hill)

                let canopy = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.20, green: 0.40, blue: 0.20, alpha: 1), theme, 0.24),
                    roughness: 1.0)
                for _ in 0..<Int(rng.float(in: 3...6)) {
                    // Trees ride the dome, so the height comes off its profile
                    // rather than being guessed — otherwise half of them float.
                    let offset = rng.float(in: -0.6...0.6) * radius
                    let side = rng.float(in: -0.4...0.4) * radius
                    let t = sqrt(max(0, 1 - (offset * offset + side * side) / (radius * radius)))
                    let tree = Prim.sphere(radius: rng.float(in: 0.28...0.5),
                                           material: canopy)
                    tree.scale *= SIMD3(1, 1.5, 1)
                    tree.position = SIMD3(offset, radius * lift * t, side)
                    group.addChild(tree)
                }
            } else {
                // A row of poplars marking a field boundary.
                let bark = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.24, green: 0.38, blue: 0.20, alpha: 1), theme, 0.26),
                    roughness: 1.0)
                for i in 0..<5 {
                    let height = rng.float(in: 1.6...2.8)
                    let poplar = Prim.cone(height: height, radius: 0.26, material: bark)
                    poplar.position = SIMD3(Float(i - 2) * 0.75 + rng.float(in: -0.1...0.1),
                                            height / 2, rng.float(in: -0.2...0.2))
                    group.addChild(poplar)
                }
            }

        case .desert:
            if rng.chance(0.55) {
                // Mesa: flat-topped, layered, the shape the whole world is
                // named after.
                let width = rng.float(in: 2.6...4.4)
                var y: Float = 0
                for tier in 0..<3 {
                    let tierHeight = rng.float(in: 0.5...1.0)
                    let shrink = 1 - Float(tier) * 0.22
                    let rock = SceneBuilder.simpleMaterial(
                        faded(UIColor(red: 0.70 - CGFloat(tier) * 0.06,
                                      green: 0.44 - CGFloat(tier) * 0.05,
                                      blue: 0.30, alpha: 1), theme, 0.28 + CGFloat(tier) * 0.04),
                        roughness: 1.0)
                    let slab = Prim.roundedBox(width: width * shrink,
                                               height: tierHeight,
                                               depth: width * shrink * rng.float(in: 0.7...1.0),
                                               cornerRadius: 0.06,
                                               material: rock)
                    slab.position.y = y + tierHeight / 2
                    slab.orientation = simd_quatf(angle: rng.float(in: -0.12...0.12),
                                                  axis: SIMD3(0, 1, 0))
                    group.addChild(slab)
                    y += tierHeight
                }
            } else {
                // Dune: one long crest, always broadside to the course.
                let duneMaterial = SceneBuilder.simpleMaterial(
                    faded(theme.sandColor, theme, 0.22),
                    roughness: 1.0)
                let dune = Prim.sphere(radius: rng.float(in: 2.4...4.2),
                                       material: duneMaterial)
                dune.scale *= SIMD3(rng.float(in: 1.2...1.8), rng.float(in: 0.22...0.36), 0.7)
                group.addChild(dune)
            }

        case .jungle:
            if rng.chance(0.7) {
                // A wall of canopy: overlapping crowns on stilts, no gaps.
                let leaf = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.14, green: 0.34, blue: 0.18, alpha: 1), theme, 0.26),
                    roughness: 1.0)
                let trunk = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.30, green: 0.24, blue: 0.16, alpha: 1), theme, 0.3),
                    roughness: 1.0)
                for i in 0..<3 {
                    let height = rng.float(in: 1.6...2.8)
                    let x = Float(i - 1) * rng.float(in: 0.9...1.4)
                    let stem = Prim.cylinder(height: height, radius: 0.1, material: trunk)
                    stem.position = SIMD3(x, height / 2, 0)
                    group.addChild(stem)
                    let crown = Prim.sphere(radius: rng.float(in: 0.9...1.5),
                                            material: leaf)
                    crown.scale *= SIMD3(1.2, 0.75, 1.2)
                    crown.position = SIMD3(x, height + 0.2, rng.float(in: -0.3...0.3))
                    group.addChild(crown)
                }
            } else {
                // Stepped temple, half swallowed by the trees.
                let stone = SceneBuilder.simpleMaterial(
                    faded(theme.wallTopColor, theme, 0.3), roughness: 1.0)
                let base = rng.float(in: 2.6...3.8)
                var y: Float = 0
                for tier in 0..<4 {
                    let side = base * (1 - Float(tier) * 0.2)
                    let tierHeight: Float = 0.42
                    let block = Prim.roundedBox(width: side,
                                                height: tierHeight,
                                                depth: side,
                                                cornerRadius: 0.02,
                                                material: stone)
                    block.position.y = y + tierHeight / 2
                    group.addChild(block)
                    y += tierHeight
                }
            }

        case .ice:
            if rng.chance(0.7) {
                // Peak with a snow cap — the cap is what makes it read as a
                // mountain rather than a grey cone.
                let height = rng.float(in: 2.6...4.4)
                let radius = rng.float(in: 1.2...2.0)
                let rockMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.44, green: 0.52, blue: 0.62, alpha: 1), theme, 0.34),
                    roughness: 1.0)
                let rock = Prim.cone(height: height, radius: radius, material: rockMaterial)
                rock.position.y = height / 2
                group.addChild(rock)
                let capMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(white: 0.98, alpha: 1), theme, 0.14),
                    roughness: 0.9)
                let cap = Prim.cone(height: height * 0.34,
                                    radius: radius * 0.36,
                                    material: capMaterial)
                cap.position.y = height * 0.83
                group.addChild(cap)
            } else {
                // Berg adrift: translucent, so the sky shows through the edges.
                var glass = PhysicallyBasedMaterial()
                glass.baseColor = .init(tint: faded(theme.iceColor, theme, 0.2))
                glass.roughness = 0.14
                glass.metallic = 0.1
                glass.blending = .transparent(opacity: 0.85)
                for i in 0..<3 {
                    let height = rng.float(in: 0.8...1.9)
                    let shard = Prim.roundedBox(width: rng.float(in: 0.7...1.4),
                                                height: height,
                                                depth: rng.float(in: 0.7...1.4),
                                                cornerRadius: 0.05,
                                                material: glass)
                    shard.position = SIMD3(Float(i - 1) * rng.float(in: 0.5...0.9), height / 2,
                                           rng.float(in: -0.4...0.4))
                    shard.orientation = simd_quatf(angle: rng.float(in: -0.3...0.3),
                                                   axis: SIMD3(0, 0, 1))
                    group.addChild(shard)
                }
            }

        case .neon:
            // Skyline tower. The dark worlds are lit by almost nothing, so the
            // silhouette has to come from the windows rather than the sun.
            let height = rng.float(in: 2.4...5.2)
            let width = rng.float(in: 0.6...1.3)
            let shellMaterial = SceneBuilder.simpleMaterial(
                UIColor(red: 0.06, green: 0.05, blue: 0.13, alpha: 1),
                roughness: 0.6)
            let shell = Prim.roundedBox(width: width,
                                        height: height,
                                        depth: width * 0.8,
                                        cornerRadius: 0.03,
                                        material: shellMaterial)
            shell.position.y = height / 2
            group.addChild(shell)

            let hue = rng.chance(0.5) ? theme.accent : theme.wallTopColor
            var strip = UnlitMaterial()
            strip.color = .init(tint: hue)
            let bands = Int(rng.float(in: 3...6))
            for i in 0..<bands {
                let band = Prim.box(width: width * 1.02,
                                    height: 0.05,
                                    depth: width * 0.82,
                                    material: strip)
                band.position.y = height * (Float(i) + 0.8) / Float(bands + 1)
                group.addChild(band)
            }
            // Aircraft light on the roof.
            let beacon = Prim.sphere(radius: 0.07, material: strip)
            beacon.position.y = height + 0.06
            group.addChild(beacon)

        case .volcano:
            if rng.chance(0.6) {
                // Cone with a lit crater and a column of smoke over it.
                let height = rng.float(in: 2.4...4.2)
                let radius = rng.float(in: 1.6...2.8)
                let coneMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.16, green: 0.13, blue: 0.13, alpha: 1), theme, 0.22),
                    roughness: 1.0)
                let cone = Prim.cone(height: height, radius: radius, material: coneMaterial)
                cone.position.y = height / 2
                group.addChild(cone)

                var molten = PhysicallyBasedMaterial()
                molten.baseColor = .init(tint: theme.lavaColor)
                molten.emissiveColor = .init(color: theme.lavaColor)
                molten.emissiveIntensity = 2.4
                molten.roughness = 0.6
                let crater = Prim.cylinder(height: 0.05,
                                           radius: radius * 0.17,
                                           material: molten)
                crater.position.y = height * 0.99
                group.addChild(crater)

                let ash = SceneBuilder.simpleMaterial(
                    faded(UIColor(white: 0.22, alpha: 1), theme, 0.4), roughness: 1.0)
                for i in 0..<3 {
                    let t = Float(i)
                    let puff = Prim.sphere(radius: 0.35 + t * 0.22, material: ash)
                    puff.position = SIMD3(rng.float(in: -0.3...0.3) * (t + 1),
                                          height + 0.4 + t * 0.75, rng.float(in: -0.2...0.2))
                    group.addChild(puff)
                }
            } else {
                // Basalt ridge: slabs tipped against each other.
                let rock = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.19, green: 0.16, blue: 0.16, alpha: 1), theme, 0.24),
                    roughness: 1.0)
                for i in 0..<4 {
                    let height = rng.float(in: 1.0...2.6)
                    let slab = Prim.roundedBox(width: rng.float(in: 0.5...0.9),
                                               height: height,
                                               depth: rng.float(in: 0.5...0.9),
                                               cornerRadius: 0.03,
                                               material: rock)
                    slab.position = SIMD3(Float(i - 2) * 0.7, height / 2, rng.float(in: -0.4...0.4))
                    slab.orientation = simd_quatf(angle: rng.float(in: -0.22...0.22),
                                                  axis: SIMD3(0, 0, 1))
                    group.addChild(slab)
                }
            }

        case .clockwork:
            if rng.chance(0.55) {
                // Factory chimney, brass-banded, still working.
                let height = rng.float(in: 2.4...4.0)
                let radius = rng.float(in: 0.24...0.42)
                let brickMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.42, green: 0.26, blue: 0.19, alpha: 1), theme, 0.26),
                    roughness: 1.0)
                let brick = Prim.cylinder(height: height,
                                          radius: radius,
                                          material: brickMaterial)
                brick.position.y = height / 2
                group.addChild(brick)
                let bandMaterial = SceneBuilder.simpleMaterial(
                    faded(theme.wallTopColor, theme, 0.2),
                    roughness: 0.4,
                    metallic: 0.7)
                let band = Prim.cylinder(height: 0.12,
                                         radius: radius * 1.18,
                                         material: bandMaterial)
                band.position.y = height - 0.2
                group.addChild(band)
                let smoke = SceneBuilder.simpleMaterial(
                    faded(UIColor(white: 0.55, alpha: 1), theme, 0.45), roughness: 1.0)
                for i in 0..<2 {
                    let puff = Prim.sphere(radius: 0.24 + Float(i) * 0.16, material: smoke)
                    puff.position = SIMD3(rng.float(in: -0.2...0.2), height + 0.3 + Float(i) * 0.6,
                                          rng.float(in: -0.2...0.2))
                    group.addChild(puff)
                }
            } else {
                // Gear tower: a housing with the movement on show.
                let iron = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 1), theme, 0.26),
                    roughness: 0.8, metallic: 0.3)
                let brass = SceneBuilder.simpleMaterial(faded(theme.wallTopColor, theme, 0.18),
                                                        roughness: 0.35, metallic: 0.8)
                let height = rng.float(in: 1.8...3.2)
                let housing = Prim.roundedBox(width: 1.0,
                                              height: height,
                                              depth: 1.0,
                                              cornerRadius: 0.05,
                                              material: iron)
                housing.position.y = height / 2
                group.addChild(housing)
                for i in 0..<2 {
                    let radius = rng.float(in: 0.34...0.55)
                    let cog = Prim.cylinder(height: 0.12, radius: radius, material: brass)
                    cog.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
                    cog.position = SIMD3(rng.float(in: -0.3...0.3),
                                         height * (0.4 + Float(i) * 0.4), 0.52)
                    group.addChild(cog)
                }
            }

        case .storm:
            if rng.chance(0.65) {
                // Sea stack, tipped by a century of weather.
                let height = rng.float(in: 1.6...3.4)
                let width = rng.float(in: 1.2...2.6)
                let cliffMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.32, green: 0.35, blue: 0.38, alpha: 1), theme, 0.3),
                    roughness: 1.0)
                let cliff = Prim.roundedBox(width: width,
                                            height: height,
                                            depth: width * rng.float(in: 0.6...1.0),
                                            cornerRadius: 0.08,
                                            material: cliffMaterial)
                cliff.position.y = height / 2
                cliff.orientation = simd_quatf(angle: rng.float(in: -0.14...0.14),
                                               axis: SIMD3(0, 0, 1))
                group.addChild(cliff)
                let turfMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.30, green: 0.38, blue: 0.26, alpha: 1), theme, 0.3),
                    roughness: 1.0)
                let turf = Prim.sphere(radius: width * 0.5, material: turfMaterial)
                turf.scale *= SIMD3(1, 0.2, 1)
                turf.position.y = height
                group.addChild(turf)
            } else {
                // Lighthouse. One warm light in a grey world does more for the
                // mood than any amount of rock.
                let height = rng.float(in: 2.2...3.2)
                let towerMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(white: 0.88, alpha: 1), theme, 0.2),
                    roughness: 0.8)
                let tower = Prim.cone(height: height, radius: 0.42, material: towerMaterial)
                tower.position.y = height / 2
                group.addChild(tower)
                let stripeMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.75, green: 0.20, blue: 0.16, alpha: 1), theme, 0.2),
                    roughness: 0.8)
                let stripe = Prim.cylinder(height: height * 0.16,
                                           radius: 0.31,
                                           material: stripeMaterial)
                stripe.position.y = height * 0.62
                group.addChild(stripe)
                var lamp = UnlitMaterial()
                lamp.color = .init(tint: theme.accent)
                let light = Prim.sphere(radius: 0.16, material: lamp)
                light.position.y = height + 0.06
                group.addChild(light)
                let roofMaterial = SceneBuilder.simpleMaterial(
                    faded(UIColor(red: 0.28, green: 0.30, blue: 0.34, alpha: 1), theme, 0.2),
                    roughness: 0.8)
                let roof = Prim.cone(height: 0.24, radius: 0.22, material: roofMaterial)
                roof.position.y = height + 0.3
                group.addChild(roof)
            }

        case .cosmos:
            // Debris on station approach: nothing stands on the deck out here,
            // it hangs.
            let stone = SceneBuilder.simpleMaterial(
                faded(UIColor(red: 0.22, green: 0.21, blue: 0.25, alpha: 1), theme, 0.2),
                roughness: 1.0)
            let lift = rng.float(in: 0.8...3.2)
            for i in 0..<3 {
                let rock = Prim.sphere(radius: rng.float(in: 0.3...0.9), material: stone)
                rock.scale *= SIMD3(1.3, rng.float(in: 0.6...0.9), 1.0)
                rock.position = SIMD3(rng.float(in: -0.9...0.9), lift + Float(i) * 0.3,
                                      rng.float(in: -0.9...0.9))
                rock.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)),
                                              axis: SIMD3(0, 1, 0))
                group.addChild(rock)
            }
        }
        return group
    }

    /// The gas giant the station orbits: one sphere, one ring, both far enough
    /// out to sit dead still while the camera moves.
    private static func makePlanet(theme: CourseTheme, bounds: GroundRect,
                                   rng: inout SplitMix64) -> Entity {
        let group = Entity()
        let radius: Float = 3.4
        var body = PhysicallyBasedMaterial()
        body.baseColor = .init(tint: UIColor(red: 0.34, green: 0.26, blue: 0.46, alpha: 1))
        body.emissiveColor = .init(color: UIColor(red: 0.20, green: 0.16, blue: 0.34, alpha: 1))
        body.emissiveIntensity = 0.5
        body.roughness = 1.0
        let planet = Prim.sphere(radius: radius, material: body)
        group.addChild(planet)

        var ring = PhysicallyBasedMaterial()
        ring.baseColor = .init(tint: theme.wallTopColor)
        ring.emissiveColor = .init(color: theme.accent)
        ring.emissiveIntensity = 0.35
        ring.roughness = 0.8
        ring.blending = .transparent(opacity: 0.42)
        let halo = Prim.cylinder(height: 0.04, radius: radius * 1.75, material: ring)
        halo.orientation = simd_quatf(angle: 0.34, axis: SIMD3(1, 0, 0))
        group.addChild(halo)

        let angle = rng.float(in: 2.2...4.1)   // behind the hole, down the lane
        group.position = SIMD3(bounds.center.x + cos(angle) * 19,
                               6.5,
                               bounds.center.y + sin(angle) * 19)
        return group
    }

    // MARK: - Weather

    /// One kind of speck drifting through a world's air.
    private struct WeatherRecipe {
        var count: Int
        var color: UIColor
        var opacity: Float
        /// Dimensions of a single speck: rain is a streak, pollen a dot.
        var size: SIMD3<Float>
        /// Metres per second, before the per-speck sway.
        var velocity: SIMD3<Float>
        /// Sideways wander, in metres.
        var sway: Float
        /// Bottom of the band of air the field fills, above the felt.
        ///
        /// Only what actually falls is allowed to start at zero. A speck that
        /// hovers a centimetre over the green does not read as being in the air
        /// at all from a camera looking down the lane — it reads as litter
        /// stuck to the felt, and worse, as something the player has to work
        /// out whether the ball will hit.
        var lowest: Float
        var height: Float
    }

    /// Snow, embers, fireflies, rain — whatever this world has in the air.
    ///
    /// A hole is a still life otherwise: the felt does not move, the walls do
    /// not move, and outside the one obstacle that turns, nothing tells the
    /// player the world is running. Three dozen specks on a loop fix that for
    /// the price of one shared mesh and one shared material.
    static func buildWeather(level: LevelDefinition, theme: CourseTheme,
                             into root: Entity, animated: inout [AnimatedObstacle]) {
        let recipe = weather(for: level.course, theme: theme)
        guard recipe.count > 0 else { return }

        var rng = SplitMix64(seed: UInt64(level.course.order * 331 + level.number * 29 + 7))
        let bounds = level.bounds
        // Kept tight around the course: spread the same specks over the whole
        // terrain and the weather reads as a few stray dots instead of a fall.
        let span = SIMD3(bounds.size.x + 3.6, recipe.height, bounds.size.y + 3.6)
        let origin = SIMD3(bounds.center.x - span.x / 2,
                           recipe.lowest,
                           bounds.center.y - span.z / 2)

        var material = UnlitMaterial()
        material.color = .init(tint: recipe.color)
        material.blending = .transparent(opacity: .init(floatLiteral: recipe.opacity))
        let mesh = MeshResource.generateBox(size: 1, cornerRadius: 0.3)

        let field = Entity()
        field.name = "weather"
        root.addChild(field)

        for _ in 0..<recipe.count {
            let speck = ModelEntity(mesh: mesh, materials: [material])
            speck.scale = recipe.size
            // Each speck gets its own drift rate, or the whole field falls as
            // one sheet.
            let rate = rng.float(in: 0.75...1.3)
            field.addChild(speck)
            animated.append(AnimatedObstacle(
                kind: .drift(origin: origin, span: span,
                             seed: SIMD3(rng.float(in: 0...span.x),
                                         rng.float(in: 0...span.y),
                                         rng.float(in: 0...span.z)),
                             velocity: recipe.velocity * rate,
                             sway: recipe.sway,
                             phase: rng.float(in: 0...(2 * .pi))),
                entity: speck))
        }
    }

    private static func weather(for course: CourseType, theme: CourseTheme) -> WeatherRecipe {
        switch course {
        case .garden:
            // Pollen catching the afternoon sun.
            return WeatherRecipe(count: 22,
                                 color: UIColor(red: 1.0, green: 0.97, blue: 0.76, alpha: 1),
                                 opacity: 0.42, size: SIMD3(repeating: 0.014),
                                 velocity: SIMD3(0.11, 0.045, 0.03), sway: 0.12,
                                 lowest: 0.30, height: 1.7)
        case .desert:
            // Sand on the wind, streaked out along the gust.
            return WeatherRecipe(count: 24,
                                 color: theme.sandColor,
                                 opacity: 0.28, size: SIMD3(0.055, 0.010, 0.010),
                                 velocity: SIMD3(0.95, 0.02, 0.06), sway: 0.07,
                                 lowest: 0.22, height: 1.4)
        case .jungle:
            // Fireflies, low and slow under the canopy.
            return WeatherRecipe(count: 16,
                                 color: UIColor(red: 0.95, green: 1.0, blue: 0.45, alpha: 1),
                                 opacity: 0.8, size: SIMD3(repeating: 0.017),
                                 velocity: SIMD3(0.07, 0.035, 0.05), sway: 0.24,
                                 lowest: 0.28, height: 1.1)
        case .ice:
            // Snow: the one thing that is meant to land on the green.
            return WeatherRecipe(count: 36,
                                 color: .white,
                                 opacity: 0.8, size: SIMD3(repeating: 0.016),
                                 velocity: SIMD3(0.12, -0.34, 0.05), sway: 0.13,
                                 lowest: 0, height: 3.0)
        case .neon:
            // Sparks rising off the grid.
            return WeatherRecipe(count: 22,
                                 color: theme.accent,
                                 opacity: 0.7, size: SIMD3(repeating: 0.013),
                                 velocity: SIMD3(0.04, 0.22, 0.03), sway: 0.11,
                                 lowest: 0.18, height: 2.4)
        case .volcano:
            return WeatherRecipe(count: 24,
                                 color: theme.lavaColor,
                                 opacity: 0.8, size: SIMD3(repeating: 0.013),
                                 velocity: SIMD3(0.10, 0.36, 0.06), sway: 0.15,
                                 lowest: 0.15, height: 2.8)
        case .clockwork:
            // Steam off the machinery, drifting up and away.
            return WeatherRecipe(count: 16,
                                 color: UIColor(white: 0.82, alpha: 1),
                                 opacity: 0.22, size: SIMD3(repeating: 0.06),
                                 velocity: SIMD3(0.14, 0.24, 0.05), sway: 0.10,
                                 lowest: 0.40, height: 2.4)
        case .storm:
            // Rain, hard and blown sideways — the world is named for it.
            return WeatherRecipe(count: 42,
                                 color: UIColor(red: 0.80, green: 0.88, blue: 0.95, alpha: 1),
                                 opacity: 0.34, size: SIMD3(0.008, 0.17, 0.008),
                                 velocity: SIMD3(0.6, -3.4, 0.12), sway: 0,
                                 lowest: 0, height: 3.2)
        case .cosmos:
            // Dust in the station lights, weightless in every direction.
            return WeatherRecipe(count: 22,
                                 color: theme.wallTopColor,
                                 opacity: 0.4, size: SIMD3(repeating: 0.011),
                                 velocity: SIMD3(0.06, 0.05, 0.08), sway: 0.16,
                                 lowest: 0.45, height: 2.5)
        }
    }
}
