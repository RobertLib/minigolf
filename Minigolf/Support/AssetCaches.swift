//
//  AssetCaches.swift
//  Minigolf
//
//  The one thing that can empty the shared texture, material and mesh caches.
//

import Foundation
import UIKit

/// Everything the scene builders keep between holes, and the way back out.
///
/// Each of those caches earns its place — the notes on them say why a world's
/// textures, materials and rounded boxes are far too dear to build twice. What
/// none of them had was a floor: a session that wanders through all nine worlds
/// ends up holding every set at once, some 25 MB of it, and it only ever grows.
/// On a device already under pressure the system's answer to that is to kill
/// whichever app is holding the most.
///
/// So a memory warning empties them. Nothing on screen goes with them: the live
/// hole holds its own references to the resources it was handed, and a cache
/// only ever mapped a description to one. The next hole builds what it needs
/// again, at exactly the cost the first hole of a session already pays — which
/// is the right trade to make at the moment the alternative is being killed.
///
/// The textures go with the materials on purpose. A `ThemeMaterials` set holds
/// its own textures, so dropping `TextureFactory`'s half alone would free
/// nothing at all: the bitmaps would still be alive, just no longer reachable
/// for reuse — the worst of both.
enum AssetCaches {

    /// Empties every shared cache. Safe to call at any time.
    static func purge() {
        ThemeMaterials.purge()
        TextureFactory.purge()
        SceneBuilder.purgeMaterials()
        Prim.purge()
    }

    /// Starts listening for memory warnings. Called once, as the app opens.
    static func startWatchingMemory() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Posted on the main queue, which is the main actor — but a
            // notification block carries no isolation of its own, and the caches
            // are all main-actor state.
            MainActor.assumeIsolated { purge() }
        }
    }
}
