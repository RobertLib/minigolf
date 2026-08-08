//
//  SceneBuildTests.swift
//  MinigolfTests
//
//  The scene builder turns a hole's data into the thing the coordinator plays.
//  Only half of what it produces is visible: the entities are the half anybody
//  would notice going wrong, and the other half — the force zones, the loops,
//  the cannon muzzles, the footprint the out-of-bounds net is cut from — is a
//  set of plain values handed straight to the physics, where a piece going
//  missing makes a hole behave oddly rather than look wrong.
//
//  `Tools/validate_levels.swift` already proves each hole is playable as data.
//  What is checked here is the step after it: that every piece of that data
//  arrives, that it arrives where it was put, and that nothing in the geometry
//  comes out as a number a renderer cannot draw. Every hole in the game goes
//  through it, because the builders branch on what a hole happens to contain and
//  a made-up one would only exercise the branches it was written for.
//
//  A world at a time, and everything about a hole checked off a single build:
//  assembling one costs the best part of 30 ms, so a test per assertion would
//  have paid that six times over for every hole in the game.
//

import Foundation
import RealityKit
import Testing
import simd
@testable import Minigolf

@MainActor
struct SceneBuildTests {

    @Test(arguments: CourseType.allCases)
    func everyHoleBuildsIntoAPlayableScene(course: CourseType) {
        for level in LevelLibrary.levels(for: course) {
            let scene = SceneBuilder.build(level: level)
            let hole = "\(course) \(level.number)"

            checkTeeAndCup(scene, level, hole)
            checkFootprint(scene, level, hole)
            checkObstaclesArrived(scene, level, hole)
            checkBonusStar(scene, level, hole)
            checkHazardsAndSurfaces(scene, level, hole)
            checkTransformsAreNumbers(scene, hole)
            checkDirectionsAreUnitVectors(scene, hole)
        }
    }

    /// The welded floor mesh is what the ball actually rolls on. It is built off
    /// the main actor, ahead of the scene, and a height that fails to produce
    /// one falls back to a box over the whole green — playable, but it paves
    /// over that height's gaps, so a hole that quietly lost its mesh stops
    /// dropping the ball into its own water.
    @Test(arguments: CourseType.allCases)
    func everyFloorHeightGetsACollisionMesh(course: CourseType) async {
        for level in LevelLibrary.levels(for: course) {
            let shapes = await SceneBuilder.floorShapes(of: level)
            for y in Set(level.floors.filter { $0.kind == .green }.map(\.y)) {
                #expect(shapes[y] != nil,
                        "\(course) \(level.number): no collision mesh at height \(y)")
            }
        }
    }

    // MARK: - The ball, the cup and the ground between them

    /// The two positions every hole turns on. The tee is where the first putt is
    /// played from; the cup is what the aim guide, the hole magnet and the
    /// capture test all measure against. Either arriving off by a scene graph's
    /// worth of offset makes the hole unplayable in a way no screenshot shows.
    private func checkTeeAndCup(_ scene: BuiltScene, _ level: LevelDefinition, _ hole: String) {
        #expect(simd_distance(scene.ball.position.xz, level.tee) < 0.001,
                "\(hole): the ball is teed up at \(scene.ball.position.xz), not \(level.tee)")
        #expect(scene.ball.position.y > level.minFloorY,
                "\(hole): the ball starts below the lowest floor")

        #expect(simd_distance(scene.holePosition.xz, level.hole) < 0.001,
                "\(hole): the cup is at \(scene.holePosition.xz), not \(level.hole)")
        #expect(abs(scene.holePosition.y - level.holeY) < 0.001,
                "\(hole): the cup sits at y \(scene.holePosition.y), not \(level.holeY)")
    }

    /// `floorRects` is the safety net: a ball found outside every one of them is
    /// called out of bounds and costs a stroke. The tee and the cup are the two
    /// places the ball is guaranteed to be, so a footprint missing either would
    /// penalise a player for standing still.
    private func checkFootprint(_ scene: BuiltScene, _ level: LevelDefinition, _ hole: String) {
        #expect(!scene.floorRects.isEmpty, "\(hole): no floor at all")
        #expect(scene.floorRects.contains { $0.contains(level.tee) },
                "\(hole): the tee at \(level.tee) is outside the course footprint")
        #expect(scene.floorRects.contains { $0.contains(level.hole) },
                "\(hole): the cup at \(level.hole) is outside the course footprint")
        #expect(scene.minFloorY == level.minFloorY,
                "\(hole): the out-of-bounds floor is \(scene.minFloorY), not \(level.minFloorY)")
    }

    // MARK: - Everything the coordinator is handed

    /// Every obstacle the coordinator drives by hand has to reach it. These are
    /// the ones with no collider of their own: a portal that never arrives is a
    /// ring the ball rolls straight through, and nothing else in the game would
    /// say so.
    private func checkObstaclesArrived(_ scene: BuiltScene, _ level: LevelDefinition,
                                       _ hole: String) {
        let want = SpecTally(level)
        #expect(scene.forceZones.count == want.forceZones, "\(hole): force zones")
        #expect(scene.windZones.count == want.windZones, "\(hole): wind zones")
        #expect(scene.portals.count == want.portals, "\(hole): portals")
        #expect(scene.boostPads.count == want.boostPads, "\(hole): boost pads")
        #expect(scene.launchPads.count == want.launchPads, "\(hole): launch pads")
        #expect(scene.loops.count == want.loops, "\(hole): loops")
        #expect(scene.cannons.count == want.cannons, "\(hole): cannons")
        #expect(scene.turntables.count == want.turntables, "\(hole): turntables")
        #expect(scene.magnets.count == want.magnets, "\(hole): magnets")
        #expect(scene.critters.count == want.critters, "\(hole): critters")
        // Bumpers are matched to their collision events by name, so two sharing
        // one would make each answer for the other's hits.
        #expect(scene.bumperNames.count == want.bumpers, "\(hole): bumper names")
    }

    /// A bonus star is a permanent mark against the hole it was collected on, so
    /// the one the level hides has to be the one the scene puts down.
    private func checkBonusStar(_ scene: BuiltScene, _ level: LevelDefinition, _ hole: String) {
        guard let wanted = level.bonusStar else {
            #expect(scene.bonusStar == nil, "\(hole): a star nobody asked for")
            return
        }
        guard let star = scene.bonusStar else {
            Issue.record("\(hole): the hidden star was never built")
            return
        }
        #expect(simd_distance(star.position.xz, wanted) < 0.001,
                "\(hole): the star is at \(star.position.xz), not \(wanted)")
        #expect(!star.collected, "\(hole): the star starts already collected")
    }

    /// Water and lava are gaps in the floor rather than surfaces on it, and
    /// which of the two the ball fell into decides the sound it makes and the
    /// message the player gets. Sand, mud and ice are the opposite: no gap, only
    /// a change in how quickly the ball gives up its pace.
    private func checkHazardsAndSurfaces(_ scene: BuiltScene, _ level: LevelDefinition,
                                         _ hole: String) {
        let hazards = level.floors.filter(\.kind.isHazard)
        #expect(scene.hazardRegions.count == hazards.count, "\(hole): hazard count")
        for patch in hazards {
            let kind: OutOfBoundsKind = patch.kind == .water ? .water : .lava
            #expect(scene.hazardRegions.contains {
                $0.kind == kind && $0.rect.contains(patch.rect.center)
            }, "\(hole): no \(kind) region over the patch at \(patch.rect.center)")
        }

        let overlays = level.floors.filter(\.kind.isOverlay)
        #expect(scene.surfaceRegions.count == overlays.count, "\(hole): surface count")
        for region in scene.surfaceRegions {
            #expect(region.damping != GamePhysics.ballLinearDamping,
                    "\(hole): a patch of sand or ice that rolls like plain felt")
        }
    }

    // MARK: - Nothing a renderer or a solver cannot use

    /// One NaN in a transform takes the entity it belongs to — and everything
    /// under it — out of the picture, silently. They come from normalising a
    /// zero-length direction, which is exactly what a hand-written level file
    /// can ask for by accident.
    private func checkTransformsAreNumbers(_ scene: BuiltScene, _ hole: String) {
        var checked = 0
        walk(scene.root) { entity in
            checked += 1
            let t = entity.transform
            #expect(t.translation.isFinite && t.scale.isFinite && t.rotation.vector.isFinite,
                    """
                    \(hole): "\(entity.name)" has a transform that is not a \
                    number — \(t.translation), \(t.scale), \(t.rotation.vector)
                    """)
        }
        #expect(checked > 1, "\(hole): an empty scene")
    }

    /// The same for the values handed to the physics. A zero-length direction on
    /// a belt or a cannon normalises to NaN and takes the ball with it the
    /// moment it rolls on.
    private func checkDirectionsAreUnitVectors(_ scene: BuiltScene, _ hole: String) {
        func isUnit(_ v: SIMD2<Float>) -> Bool { abs(simd_length(v) - 1) < 0.001 }

        for pad in scene.boostPads {
            #expect(isUnit(pad.direction), "\(hole): boost pad direction")
        }
        for pad in scene.launchPads {
            #expect(isUnit(pad.direction), "\(hole): launch pad direction")
            #expect(pad.lift > 0, "\(hole): a kicker with no lift clears no gap")
        }
        for cannon in scene.cannons {
            #expect(isUnit(cannon.direction), "\(hole): cannon direction")
            // The muzzle has to clear the mouth, or the shot is swallowed again.
            #expect(simd_distance(cannon.exit, cannon.center) > cannon.radius,
                    "\(hole): the cannon fires the ball back into its own barrel")
        }
        for loop in scene.loops {
            #expect(isUnit(loop.axis), "\(hole): loop axis")
            #expect(loop.trackRadius > 0, "\(hole): a loop the ball cannot fit round")
            // Stretched, not closed: the two mouths are a pitch apart.
            #expect(simd_distance(loop.mouth(sign: 1), loop.mouth(sign: -1)) > 0.001,
                    "\(hole): a loop whose entrance and exit are the same place")
        }
        for zone in scene.windZones {
            #expect(isUnit(zone.direction), "\(hole): wind direction")
        }
        for portal in scene.portals {
            #expect(portal.armed, "\(hole): a portal that starts spent")
            #expect(simd_distance(portal.a, portal.b) > portal.radius,
                    "\(hole): a portal pair close enough to swallow its own exit")
        }
        for disc in scene.turntables {
            #expect(disc.radius > GamePhysics.ballRadius, "\(hole): turntable radius")
        }
        for magnet in scene.magnets {
            #expect(magnet.radius > 0, "\(hole): a magnet with no reach")
        }
    }

    // MARK: - Helpers

    private func walk(_ entity: Entity, _ visit: (Entity) -> Void) {
        visit(entity)
        for child in entity.children {
            walk(child, visit)
        }
    }

    /// What a hole asked for, counted by the kind of thing each spec turns into.
    /// Held against the built scene, this is what catches a spec quietly falling
    /// on the floor between the level file and the physics.
    private struct SpecTally {
        var forceZones = 0      // banked greens and belts, both
        var windZones = 0
        var portals = 0
        var boostPads = 0
        var launchPads = 0
        var loops = 0
        var cannons = 0
        var turntables = 0
        var magnets = 0
        var bumpers = 0
        var critters = 0

        init(_ level: LevelDefinition) {
            for spec in level.obstacles {
                switch spec {
                case .slope, .conveyor: forceZones += 1
                case .fan: windZones += 1
                case .teleporter: portals += 1
                case .boostPad: boostPads += 1
                case .launchPad: launchPads += 1
                case .loop: loops += 1
                case .cannon: cannons += 1
                case .turntable: turntables += 1
                case .magnet: magnets += 1
                case .bumper: bumpers += 1
                case .critter: critters += 1
                default: break
                }
            }
        }
    }
}

private extension SIMD3<Float> {
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

private extension SIMD4<Float> {
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite && w.isFinite }
}
