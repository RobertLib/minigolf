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

    /// Everything that touches an `AVAudioPlayer` runs here, and nothing else
    /// does.
    ///
    /// Neither `play()` nor rewinding with `currentTime = 0` is cheap: one starts
    /// an audio queue, the other flushes and re-primes its buffers, and both talk
    /// to the audio server, so either can hold up the caller for a millisecond or
    /// more. Effects are asked for from the RealityKit update and collision
    /// callbacks, which run on the main thread inside the frame — so that stall
    /// used to land in the frame, and the game genuinely ran smoother with sound
    /// switched off. Posting the work here instead leaves the main thread with a
    /// flag test and a `dispatch_async`.
    ///
    /// The queue is serial, which also orders `preload` ahead of every playback
    /// block: loading can start off the main thread during launch without the
    /// first tap arriving to find an empty bank.
    private let queue = DispatchQueue(label: "minigolf.sound", qos: .userInitiated)

    /// Ready-to-play voices per effect, round-robined by `play`. Owned by
    /// `queue`.
    ///
    /// Building an `AVAudioPlayer` parses the file and spins up an audio unit,
    /// and `prepareToPlay` allocates its buffers — work worth doing once rather
    /// than on the frame that wants the sound. Every voice is therefore built and
    /// primed up front, the music track included.
    private var voices: [SoundEffect: [AVAudioPlayer]] = [:]
    private var nextVoice: [SoundEffect: Int] = [:]
    private var musicPlayer: AVAudioPlayer?

    /// The settings toggles, mirrored in memory. `soundEnabled` is read on every
    /// single effect — several times a frame while a ball rattles along the
    /// boards — which is no place for a `UserDefaults` lookup. Main thread only.
    private var soundOn: Bool
    private var musicOn: Bool

    var soundEnabled: Bool {
        get { soundOn }
        set {
            soundOn = newValue
            UserDefaults.standard.set(newValue, forKey: "minigolf.sound")
        }
    }

    var musicEnabled: Bool {
        get { musicOn }
        set {
            musicOn = newValue
            UserDefaults.standard.set(newValue, forKey: "minigolf.music")
            if newValue { playMusic() } else { stopMusic() }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        soundOn = defaults.object(forKey: "minigolf.sound") as? Bool ?? true
        musicOn = defaults.object(forKey: "minigolf.music") as? Bool ?? true

        queue.async { [self] in
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            preload()
        }
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

        if let url = Bundle.main.url(forResource: "music", withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0.22
            player.prepareToPlay()
            musicPlayer = player
        }
    }

    func play(_ effect: SoundEffect, volume: Float = 1.0) {
        guard soundOn else { return }
        let level = min(max(volume, 0), 1)

        queue.async { [self] in
            guard let players = voices[effect], !players.isEmpty else { return }

            // Round-robin, so a retrigger layers over the tail of the one before
            // it rather than cutting it off mid-sound.
            let index = nextVoice[effect] ?? 0
            nextVoice[effect] = (index + 1) % players.count

            let player = players[index]
            player.volume = level
            player.currentTime = 0
            player.play()
        }
    }

    func playMusic() {
        guard musicOn else { return }
        queue.async { [self] in
            guard let musicPlayer, !musicPlayer.isPlaying else { return }
            musicPlayer.play()
        }
    }

    /// Pauses rather than discards: the track is a 16-second loop kept primed for
    /// the whole session, so toggling music back on costs nothing and does not
    /// re-parse the file.
    func stopMusic() {
        queue.async { [self] in
            musicPlayer?.pause()
        }
    }
}
