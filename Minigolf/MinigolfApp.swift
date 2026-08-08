//
//  MinigolfApp.swift
//  Minigolf
//
//  Created by Robert Libšanský on 02.08.2026.
//

import SwiftUI

@main
struct MinigolfApp: App {

    init() {
        AssetCaches.startWatchingMemory()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
