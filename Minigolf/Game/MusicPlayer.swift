//
//  MusicPlayer.swift
//  Minigolf
//
//  Gapless playback of the per-world music playlists, crossfading from one
//  track to the next and again when the world changes.
//

import Foundation
// See `SoundManager` for why this import is `@preconcurrency`: the engine, its
// nodes and the decoded buffers all move between `queue` and `loader`, and none
// of those AVFAudio types carries a Sendable annotation saying that is allowed.
@preconcurrency import AVFoundation
import UIKit

/// One playlist per world, plus the one the menus play.
///
/// The tracks themselves are listed in `MusicLibrary.swift`, which is generated
/// from `Tools/music_sources.json` — this enum only names the worlds.
///
/// `nonisolated` so the name of a world, and the list of files behind it, can be
/// read from the audio queue as well as from the menu that asks for it. It is a
/// name and a few string constants; there is nothing here to isolate.
nonisolated enum MusicTrack: String {
    case menu
    case garden
    case desert
    case jungle
    case ice
    case neon
    case volcano
    case clockwork
    case storm
    case cosmos

    init(course: CourseType) {
        self = MusicTrack(rawValue: course.rawValue) ?? .menu
    }
}

/// Two decks feeding a mixer, so one track can fade out under the next rather
/// than cutting — used both between the tracks of a world and between worlds.
///
/// `AVAudioPlayer` is the obvious choice here and the wrong one, for two
/// reasons. It cannot overlap two files, so every change would be a cut or a
/// gap; and the tracks are AAC, whose priming and padding frames put a short
/// but plainly audible hole at the seam of anything it loops. Decoding to PCM
/// and handing the buffer to an `AVAudioPlayerNode` puts the transition inside
/// the render callback, where it is sample-accurate.
///
/// State lives on `queue`, the serial queue `SoundManager` also uses for
/// effects; decoding is the one thing pushed off it, onto `loader`.
///
/// `nonisolated` because that queue is the isolation, and the main actor —
/// which everything else in the app defaults to — is the one place this must
/// not run: decoding a minute of AAC there is the hitch the split exists to
/// avoid. The compiler cannot check a queue the way it checks an actor, so the
/// rule is stated here instead: every stored property below is touched only
/// from `queue`, and the entry points are called from it.
nonisolated final class MusicPlayer: @unchecked Sendable {

    private struct Deck {
        let player = AVAudioPlayerNode()
        let mixer = AVAudioMixerNode()
        var track: MusicTrack?
        /// Bumped by every fade on this deck, so a fade still in flight stops
        /// stepping the volume the moment a newer one takes over.
        var fadeGeneration = 0
    }

    /// Playback level for the deck in front. Music sits under the effects, which
    /// are the ones carrying information about the shot.
    private static let level: Float = 0.5
    /// Long, because these are whole pieces rather than loops of one idea, and
    /// two of them are rarely in the same key or tempo. A short crossfade
    /// between them is heard as a collision; a long one reads as one piece
    /// giving way to another.
    private static let fadeDuration = 2.2
    private static let fadeSteps = 44
    /// How long before the crossfade to start decoding the next track.
    /// Generous on purpose: decoding early costs nothing but a buffer sitting
    /// in memory a few seconds longer, and a simulator takes over two seconds
    /// to decode a minute of AAC.
    private static let loadHeadroom = 4.0

    private let queue: DispatchQueue
    /// Where tracks are decoded, so a minute of AAC never blocks the queue the
    /// effects are played from.
    private let loader = DispatchQueue(label: "cz.rob.Minigolf.music.loader",
                                       qos: .utility)
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100,
                                       channels: 2)!
    private var decks = [Deck(), Deck()]
    private var front = 0

    private var enabled = false
    /// The world that should be playing, whether or not it currently is —
    /// music may be switched off, or the session may have been interrupted.
    private var wanted: MusicTrack?
    /// What is left of the current world's shuffled playlist.
    private var upNext: [String] = []
    /// The last resource started, so a reshuffle does not hand it back first.
    private var lastPlayed: String?
    /// Bumped by every track start. A handover booked by an older start finds
    /// its generation stale and does nothing, which is how a world change, a
    /// mute or an interruption cancels the sequence without a timer to cancel.
    private var playGeneration = 0

    init(queue: DispatchQueue) {
        self.queue = queue
        for deck in decks {
            engine.attach(deck.player)
            engine.attach(deck.mixer)
            deck.mixer.outputVolume = 0
        }
        connectDecks()
        engine.prepare()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleInterruption),
                           name: AVAudioSession.interruptionNotification,
                           object: nil)
        center.addObserver(self, selector: #selector(handleConfigurationChange),
                           name: .AVAudioEngineConfigurationChange,
                           object: engine)
        center.addObserver(self, selector: #selector(handleForeground),
                           name: UIApplication.didBecomeActiveNotification,
                           object: nil)
    }

    // MARK: - Control

    /// Switches to `track`'s playlist, crossfading from whatever is playing.
    /// Asking again for the world already up is ignored, so leaving a hole for
    /// the pause menu and coming back does not restart the music.
    func play(_ track: MusicTrack) {
        wanted = track
        guard enabled else { return }
        guard decks[front].track != track || !decks[front].player.isPlaying else { return }
        startWorld(track)
    }

    func setEnabled(_ on: Bool) {
        guard on != enabled else { return }
        enabled = on
        if on {
            if let wanted { startWorld(wanted) }
        } else {
            let index = front
            fade(deck: index, to: 0) { [self] in
                // Music can be switched back on inside the couple of seconds
                // this fade lasts, and a deck that was not playing when it
                // started — nothing has yet, or an interruption stopped it —
                // never gets its fade generation bumped by the track that
                // follows. Without this the fade-out of silence would arrive
                // late and stop whatever is playing by then.
                guard !enabled else { return }
                stopAll()
                engine.pause()
            }
            for other in decks.indices where other != index {
                fade(deck: other, to: 0)
            }
        }
    }

    // MARK: - Playback

    /// Begins a world, from the top of a freshly shuffled playlist.
    private func startWorld(_ track: MusicTrack) {
        upNext = shuffled(track.resources)
        advance(to: track)
    }

    /// Plays the next track of the current world, crossfading out the one
    /// before it and booking the crossfade after this one.
    ///
    /// This is why a world is a playlist rather than one repeating loop. A
    /// forty-second loop is heard six times while somebody lines up a putt, and
    /// by the fourth the melody has stopped being music and become a noise the
    /// game makes. Each track here plays once and hands over to a different one;
    /// nothing comes back until the whole playlist has.
    private func advance(to track: MusicTrack, at startAt: DispatchTime = .now(),
                         attempt: Int = 0) {
        guard enabled, startEngine() else { return }
        if upNext.isEmpty { upNext = shuffled(track.resources) }
        guard !upNext.isEmpty else { return }

        let name = upNext.removeFirst()
        playGeneration += 1
        let generation = playGeneration
        lastPlayed = name

        // Decoding happens off `queue`. A minute of AAC is 21 MB of float PCM
        // and takes long enough to matter — over two seconds on a simulator —
        // and `queue` is the same serial queue the effects run on, so doing it
        // here would put a hole in the sound of whatever shot the player took
        // while the track was changing. This used to be a world change only,
        // and rare; now it is every track.
        //
        // `startAt` is when the music is due, not when the decode finished:
        // decoding early must not make the change early, or every track would
        // lose its last few seconds. A deadline already past fires at once,
        // which is exactly what should happen if the decode overran.
        loader.async { [self] in
            let buffer = loadBuffer(named: name)
            queue.asyncAfter(deadline: startAt) { [self] in
                guard generation == playGeneration, enabled, wanted == track else { return }
                guard let buffer else {
                    // A missing or malformed file must not take the world down
                    // with it. Skip it and try the next, but only as many times
                    // as there are tracks, so a world whose files are all
                    // broken stops rather than spinning.
                    guard attempt < track.resources.count else { return }
                    advance(to: track, attempt: attempt + 1)
                    return
                }
                startPlaying(buffer, of: track, generation: generation)
            }
        }
    }

    /// Swaps the decoded buffer onto the idle deck and crossfades to it.
    private func startPlaying(_ buffer: AVAudioPCMBuffer, of track: MusicTrack,
                              generation: Int) {
        guard startEngine() else { return }
        let previous = front
        let next = (front + 1) % decks.count
        front = next

        decks[next].track = track
        let player = decks[next].player
        player.stop()
        decks[next].mixer.outputVolume = 0
        player.scheduleBuffer(buffer, at: nil, options: [])
        player.play()

        fade(deck: next, to: Self.level)
        if decks[previous].player.isPlaying {
            fade(deck: previous, to: 0) { [self] in
                decks[previous].player.stop()
                decks[previous].track = nil
            }
        }

        // Hand over before the audio runs out, so the two overlap rather than
        // meeting at a silence. Scheduling from here rather than from the
        // node's completion handler keeps the whole sequence on `upNext`, and
        // means a world change simply outdates this one via `playGeneration`.
        //
        // Two different moments, and they have to be kept apart: when the next
        // track starts decoding, and when it starts playing. Decoding early is
        // free, so it happens with room to spare; playing early is not, because
        // every track would then lose its ending.
        let seconds = Double(buffer.frameLength) / buffer.format.sampleRate
        let playIn = max(0.5, seconds - Self.fadeDuration)
        let decodeIn = max(0.1, playIn - Self.loadHeadroom)
        let playAt = DispatchTime.now() + playIn
        queue.asyncAfter(deadline: .now() + decodeIn) { [self] in
            guard generation == playGeneration, enabled, wanted == track else { return }
            advance(to: track, at: playAt)
        }
    }

    /// A play order that never repeats a track across the join between one
    /// pass and the next — the one place a shuffle can still hand you the same
    /// thing twice in a row, and the one the ear notices.
    private func shuffled(_ names: [String]) -> [String] {
        guard names.count > 1 else { return names }
        var order = names.shuffled()
        if order.first == lastPlayed, let swap = order.indices.dropFirst().randomElement() {
            order.swapAt(0, swap)
        }
        return order
    }

    private func stopAll() {
        playGeneration += 1
        upNext = []
        for index in decks.indices {
            decks[index].fadeGeneration += 1
            decks[index].player.stop()
            decks[index].mixer.outputVolume = 0
            decks[index].track = nil
        }
    }

    /// Steps a deck's volume to `target`.
    ///
    /// `AVAudioMixerNode.outputVolume` jumps rather than ramps, so a fade has to
    /// be stepped by hand. Both sides are shaped equal-power, which keeps the
    /// crossfade from dipping in the middle the way a pair of linear ramps does.
    private func fade(deck index: Int, to target: Float,
                      completion: (@Sendable () -> Void)? = nil) {
        decks[index].fadeGeneration += 1
        let generation = decks[index].fadeGeneration
        let mixer = decks[index].mixer
        let from = mixer.outputVolume
        let rising = target > from
        let step = Self.fadeDuration / Double(Self.fadeSteps)

        for i in 1...Self.fadeSteps {
            queue.asyncAfter(deadline: .now() + step * Double(i)) { [self] in
                guard generation == decks[index].fadeGeneration else { return }
                if i == Self.fadeSteps {
                    mixer.outputVolume = target
                    completion?()
                    return
                }
                let t = Float(i) / Float(Self.fadeSteps)
                mixer.outputVolume = rising
                    ? from + (target - from) * sin(t * .pi / 2)
                    : target + (from - target) * cos(t * .pi / 2)
            }
        }
    }

    // MARK: - Resources

    /// Decodes one track to PCM. Deliberately not cached: a decoded 60-second
    /// stereo track is around 21 MB, and the only moment two are needed at once
    /// is the couple of seconds a crossfade lasts.
    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url),
              file.processingFormat.sampleRate == format.sampleRate,
              file.processingFormat.channelCount == format.channelCount,
              file.length > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length))
        else { return nil }

        do {
            try file.read(into: buffer)
        } catch {
            return nil
        }
        return buffer.frameLength > 0 ? buffer : nil
    }

    private func connectDecks() {
        for deck in decks {
            engine.connect(deck.player, to: deck.mixer, format: format)
            engine.connect(deck.mixer, to: engine.mainMixerNode, format: format)
        }
    }

    private func startEngine() -> Bool {
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Session events

    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }

        queue.async { [self] in
            switch type {
            case .began:
                // A stopped player node loses its schedule, so coming back means
                // starting the track over rather than resuming it.
                stopAll()
            default:
                restart()
            }
        }
    }

    /// A route change — headphones in or out, an AirPlay hop — tears the
    /// engine's connections down. Rebuilding them and restarting the current
    /// track is the only way back to sound.
    @objc private func handleConfigurationChange(_ note: Notification) {
        queue.async { [self] in
            stopAll()
            connectDecks()
            restart()
        }
    }

    /// `.ambient` audio is silenced while the app is in the background, and the
    /// engine does not always survive the round trip.
    @objc private func handleForeground(_ note: Notification) {
        queue.async { [self] in
            guard enabled, !engine.isRunning || !decks[front].player.isPlaying
            else { return }
            restart()
        }
    }

    private func restart() {
        guard enabled, let wanted else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        startWorld(wanted)
    }
}
