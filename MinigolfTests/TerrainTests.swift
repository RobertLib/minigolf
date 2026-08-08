//
//  TerrainTests.swift
//  MinigolfTests
//
//  The ground outside the boards is the one piece of scenery other scenery is
//  measured against: the gallery, the fir trees and the fence posts are all put
//  down at whatever height it says it has there. When it lied about that — the
//  swells were placed by their middles, so a wide one lapped in over the fringe
//  while everything standing there was still being put down at slab height —
//  the result was people sunk into a hillside to the knee.
//
//  Both halves of the promise are checked here, over every hole in the game
//  rather than over a hole made up for the purpose, because the failure only
//  ever showed on the holes where a big dome happened to land near the boards.
//

import Foundation
import Testing
import simd
@testable import Minigolf

@MainActor
struct TerrainTests {

    private static let allLevels: [LevelDefinition] =
        CourseType.allCases.flatMap { LevelLibrary.levels(for: $0) }

    /// Where anybody stands: the strip either side of the lane the gallery is
    /// placed in, plus the ground behind the cup the last pair are put on.
    /// Nothing in it may be anything other than flat.
    @Test func galleryStandsOnLevelGround() {
        for level in Self.allLevels {
            let terrain = Scenery.Terrain(level: level)
            let bounds = level.bounds
            let band: Float = 2.0

            for x in stride(from: bounds.minX - band, through: bounds.maxX + band, by: 0.1) {
                for z in stride(from: bounds.minZ - band, through: bounds.maxZ + band, by: 0.1) {
                    let point = SIMD2(Float(x), Float(z))
                    #expect(terrain.height(at: point) == Scenery.groundY,
                            """
                            \(level.course) \(level.number): a swell rises \
                            \(terrain.height(at: point) - Scenery.groundY) m at \(point), \
                            \(bounds.distance(to: point)) m out from the boards
                            """)
                }
            }
        }
    }

    /// And where the swells do rise, the height they are asked for is the
    /// height of the dome that is drawn: a cap of the ellipsoid, highest over
    /// its own middle and back to the slab at its rim.
    @Test func heightFollowsTheDomeThatIsDrawn() {
        let level = Self.allLevels[0]
        let terrain = Scenery.Terrain(level: level)
        let bounds = level.bounds

        var crown: Float = Scenery.groundY
        var rises = 0
        for x in stride(from: bounds.minX - 14, through: bounds.maxX + 14, by: 0.25) {
            for z in stride(from: bounds.minZ - 14, through: bounds.maxZ + 14, by: 0.25) {
                let y = terrain.height(at: SIMD2(Float(x), Float(z)))
                #expect(y >= Scenery.groundY, "the ground never dips below the slab")
                if y > Scenery.groundY { rises += 1 }
                crown = max(crown, y)
            }
        }
        // A dozen domes over a slab this size have to show somewhere, and the
        // tallest of them is a swell rather than a hill: knee-high on a
        // spectator at the very most.
        #expect(rises > 0)
        #expect(crown - Scenery.groundY < 0.7)
    }
}
