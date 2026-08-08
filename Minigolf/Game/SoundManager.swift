//
//  SoundManager.swift
//  Minigolf
//
//  Lightweight AVAudioPlayer based playback for short effects. The music is a
//  different problem — looping and crossfading full tracks — and lives in
//  MusicPlayer; this type owns it and forwards the settings toggle.
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
    /// primed up front.
    private var voices: [SoundEffect: [AVAudioPlayer]] = [:]
    private var nextVoice: [SoundEffect: Int] = [:]

    /// Built on `queue` during preload, and only ever touched there. The queue
    /// is serial and preload is the first thing on it, so anything that asks for
    /// music later finds it ready.
    private var music: MusicPlayer?

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
            queue.async { [self] in music?.setEnabled(newValue) }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        soundOn = defaults.object(forKey: "minigolf.sound") as? Bool ?? true
        musicOn = defaults.object(forKey: "minigolf.music") as? Bool ?? true
        let startEnabled = musicOn

        queue.async { [self] in
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            preload()
            let player = MusicPlayer(queue: queue)
            music = player
            player.setEnabled(startEnabled)
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

    /// Puts `track` on, crossfading from whatever was playing. Safe to call with
    /// the track that is already up — it is then a no-op, so a screen can simply
    /// declare what it wants to hear.
    func playMusic(_ track: MusicTrack) {
        queue.async { [self] in music?.play(track) }
    }
}
