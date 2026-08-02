//
//  SoundManager.swift
//  Minigolf
//
//  Lightweight AVAudioPlayer based playback for short effects plus a looping
//  ambient music track. All sound files are small generated WAVs in the bundle.
//

import Foundation
import AVFoundation

enum SoundEffect: String, CaseIterable {
    case tap
    case hit
    case bounce
    case bumper
    case hole
    case splash
    case sizzle
    case portal
    case boost
    case loop
    case cannon
    case star
    case fail
    case success
    case gameOver = "gameover"

    /// Players kept ready for this effect. Only the ones that can retrigger
    /// while the previous one is still sounding need more than a single voice: a
    /// ball rattling along the boards asks for `.bounce` every 90 ms, whereas
    /// the fanfare that ends a run never overlaps itself.
    var voices: Int {
        switch self {
        case .bounce, .bumper: return 4
        case .hit, .boost, .portal, .star, .tap: return 2
        default: return 1
        }
    }
}

final class SoundManager {

    static let shared = SoundManager()

    /// Ready-to-play voices per effect, round-robined by `play`.
    ///
    /// Building an `AVAudioPlayer` parses the file and spins up an audio unit,
    /// and the first `play()` on a fresh one finishes that setup — a few
    /// milliseconds on whichever thread asked for it. Effects are triggered from
    /// the physics callbacks, so that thread is the one rendering the scene: a
    /// player made per sound put its cost straight into the frame. Every voice
    /// is therefore built and primed once, up front.
    private var voices: [SoundEffect: [AVAudioPlayer]] = [:]
    private var nextVoice: [SoundEffect: Int] = [:]
    private var musicPlayer: AVAudioPlayer?

    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "minigolf.sound") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "minigolf.sound")
        }
    }

    var musicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "minigolf.music") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "minigolf.music")
            if newValue { playMusic() } else { stopMusic() }
        }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        preload()
    }

    private func preload() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                  let data = try? Data(contentsOf: url)
            else { continue }

            let players = (0..<effect.voices).compactMap { _ -> AVAudioPlayer? in
                guard let player = try? AVAudioPlayer(data: data) else { return nil }
                player.prepareToPlay()
                return player
            }
            guard !players.isEmpty else { continue }
            voices[effect] = players
            nextVoice[effect] = 0
        }
    }

    func play(_ effect: SoundEffect, volume: Float = 1.0) {
        guard soundEnabled, let players = voices[effect], !players.isEmpty else { return }

        // Round-robin, so a retrigger layers over the tail of the one before it
        // rather than cutting it off mid-sound.
        let index = nextVoice[effect] ?? 0
        nextVoice[effect] = (index + 1) % players.count

        let player = players[index]
        player.volume = min(max(volume, 0), 1)
        player.currentTime = 0
        player.play()
    }

    func playMusic() {
        guard musicEnabled else { return }
        if let musicPlayer, musicPlayer.isPlaying { return }
        guard let url = Bundle.main.url(forResource: "music", withExtension: "wav") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = 0.22
        musicPlayer?.play()
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}
