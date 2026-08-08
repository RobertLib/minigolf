//
//  ContentView.swift
//  Minigolf
//
//  Root view: switches between the menu, course selection, gameplay and the
//  final rating screen.
//

import SwiftUI

struct ContentView: View {
    @State private var controller = GameController()

    var body: some View {
        ZStack {
            switch controller.phase {
            case .menu:
                MainMenuView(controller: controller)
                    .transition(.opacity)
            case .courseSelect:
                CourseSelectView(controller: controller)
                    .transition(.opacity)
            case .holeSelect:
                HoleSelectView(controller: controller)
                    .transition(.opacity)
            case .clubhouse:
                ClubhouseView(controller: controller)
                    .transition(.opacity)
            case .playing:
                GameContainerView(controller: controller)
                    .transition(.opacity)
            case .finalRating:
                FinalRatingView(controller: controller)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: controller.phase)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        // One place decides what should be playing, rather than every screen
        // remembering to ask for it. `musicTrack` is derived from the phase and
        // the current world, so entering a world crossfades into its theme and
        // backing out to the menus crossfades away from it.
        .onChange(of: controller.musicTrack) { _, track in
            SoundManager.shared.playMusic(track)
        }
        .onAppear {
            SoundManager.shared.playMusic(controller.musicTrack)
            controller.prewarmMenuTextures()
        }
    }
}

#Preview {
    ContentView()
}
