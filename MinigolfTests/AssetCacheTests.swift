//
//  AssetCacheTests.swift
//  MinigolfTests
//
//  The shared caches are what keep the second hole of a world cheap, and until
//  a memory warning arrives they only ever grow. What is checked here is the way
//  back out: that emptying them really does let go of what they were holding,
//  that a hole built afterwards is no worse for it, and — the part with teeth —
//  that the warning reaches them at all.
//
//  That last one is worth a test rather than a reading of the code. The handler
//  hangs off a notification block, which carries no isolation of its own and has
//  to claim the main actor by hand; a claim like that is checked at runtime in
//  Swift 6 and a wrong one takes the process down. Posting the notification for
//  real is the only way to find out which it is.
//

import Foundation
import RealityKit
import UIKit
import Testing
import simd
@testable import Minigolf

@MainActor
struct AssetCacheTests {

    /// A texture is a class, so identity says plainly whether the second ask was
    /// answered out of the cache or drawn again.
    @Test func aPurgeReallyEmptiesTheCaches() {
        let key = "cache-test-purge"
        let first = TextureFactory.speckle(.systemGreen, .white, key: key)
        let second = TextureFactory.speckle(.systemGreen, .white, key: key)
        #expect(first != nil)
        #expect(first === second, "the second ask should have come from the cache")

        AssetCaches.purge()

        let rebuilt = TextureFactory.speckle(.systemGreen, .white, key: key)
        #expect(rebuilt != nil, "the factory stopped working after a purge")
        #expect(rebuilt !== second, "the texture survived the purge it was meant to go in")
    }

    /// The point of dropping them mid-session is that nothing else notices. A
    /// hole built on empty caches is the first hole of a session again: slower
    /// to assemble, identical once it is there.
    @Test func aHoleStillBuildsOnEmptyCaches() {
        let level = LevelLibrary.level(course: .neon, number: 1)
        _ = SceneBuilder.build(level: level)

        AssetCaches.purge()

        let scene = SceneBuilder.build(level: level)
        #expect(scene.root.children.count > 0, "an empty hole came out of empty caches")
        #expect(simd_distance(scene.ball.position.xz, level.tee) < 0.001)
        #expect(simd_distance(scene.holePosition.xz, level.hole) < 0.001)
    }

    /// End to end, through the real notification. A handler that claimed the
    /// main actor wrongly would not fail this — it would trap, and take the test
    /// run with it, which is exactly the signal wanted.
    @Test func aMemoryWarningReachesTheCaches() async throws {
        AssetCaches.startWatchingMemory()

        let key = "cache-test-warning"
        let before = TextureFactory.speckle(.systemPink, .black, key: key)
        #expect(before != nil)

        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        // The block is posted to the main queue rather than run where it was
        // raised, so it lands on a later turn than this one.
        try await Task.sleep(for: .milliseconds(200))

        let after = TextureFactory.speckle(.systemPink, .black, key: key)
        #expect(after !== before, "the memory warning never reached the caches")
    }
}
