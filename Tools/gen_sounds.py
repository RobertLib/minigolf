#!/usr/bin/env python3
"""Generate all game sound effects + ambient music loop as WAV files."""
import math
import random
import struct
import wave
import os

# Relative to this script, so the generator works from any checkout. The old
# absolute path also spelled the project folder with a capital M and only
# resolved by grace of a case-insensitive filesystem — on a case-sensitive one
# `makedirs` would have quietly created a second tree and written the sounds
# where the app never looks.
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "Minigolf", "Resources", "Sounds")
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write_wav(name, samples, sr=44100, peak=0.85):
    m = max(1e-9, max(abs(s) for s in samples))
    scale = peak / m if m > peak else 1.0
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = b"".join(
            struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print("wrote", name, len(samples) / sr, "s")


def silence(dur, sr=44100):
    return [0.0] * int(dur * sr)


def add(base, extra, offset=0, gain=1.0, wrap=False):
    for i, s in enumerate(extra):
        j = offset + i
        if wrap:
            j %= len(base)
        elif j >= len(base):
            break
        base[j] += s * gain
    return base


def tone(freq, dur, sr=44100, attack=0.004, decay=None, shape="sine", harmonics=None):
    n = int(dur * sr)
    out = []
    decay = decay if decay is not None else dur
    harmonics = harmonics or [(1, 1.0)]
    for i in range(n):
        t = i / sr
        env = min(1.0, t / attack) * math.exp(-3.5 * t / decay)
        v = 0.0
        for mult, amp in harmonics:
            ph = 2 * math.pi * freq * mult * t
            if shape == "sine":
                v += amp * math.sin(ph)
            elif shape == "tri":
                v += amp * (2 / math.pi) * math.asin(math.sin(ph))
        out.append(v * env)
    return out


def noise_burst(dur, sr=44100, decay=0.05, lp=0.15):
    n = int(dur * sr)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / sr
        env = math.exp(-t / decay)
        raw = random.uniform(-1, 1)
        prev = prev + lp * (raw - prev)  # crude one-pole lowpass
        out.append(prev * env)
    return out


SR = 44100

# --- tap: tiny UI click
tap = tone(1500, 0.05, attack=0.001, decay=0.018)
add(tap, noise_burst(0.02, decay=0.006, lp=0.5), 0, 0.25)
write_wav("tap.wav", tap, peak=0.5)

# --- hit: putter impact (low thump + noise snap)
hit = tone(170, 0.14, attack=0.001, decay=0.05, harmonics=[(1, 1.0), (2.7, 0.35)])
add(hit, noise_burst(0.05, decay=0.012, lp=0.4), 0, 0.55)
write_wav("hit.wav", hit, peak=0.8)

# --- bounce: wall knock
bounce = tone(300, 0.09, attack=0.001, decay=0.035, harmonics=[(1, 1.0), (3.1, 0.25)])
add(bounce, noise_burst(0.03, decay=0.008, lp=0.45), 0, 0.4)
write_wav("bounce.wav", bounce, peak=0.65)

# --- bumper: springy boing (rising pitch wobble)
n = int(0.22 * SR)
bumper = []
for i in range(n):
    t = i / SR
    env = min(1.0, t / 0.002) * math.exp(-9 * t)
    f = 320 + 260 * min(1.0, t * 14) + 30 * math.sin(2 * math.pi * 28 * t)
    bumper.append(env * math.sin(2 * math.pi * f * t))
write_wav("bumper.wav", bumper, peak=0.75)

# --- hole: ball drop + happy chime
hole = silence(0.75)
add(hole, tone(140, 0.1, attack=0.001, decay=0.04), 0, 0.9)
for k, midi in enumerate([72, 76, 79]):  # C5 E5 G5
    f = 440 * 2 ** ((midi - 69) / 12)
    add(hole, tone(f, 0.4, attack=0.004, decay=0.3, shape="tri",
                   harmonics=[(1, 1.0), (2, 0.2)]),
        int((0.08 + 0.09 * k) * SR), 0.55)
write_wav("hole.wav", hole, peak=0.8)

# --- splash
n = int(0.5 * SR)
splash = []
prev = 0.0
for i in range(n):
    t = i / SR
    env = min(1.0, t / 0.01) * math.exp(-6.5 * t)
    lp = 0.32 - 0.25 * min(1.0, t * 3)  # darkening over time
    raw = random.uniform(-1, 1)
    prev = prev + lp * (raw - prev)
    splash.append(prev * env)
add(splash, tone(180, 0.12, attack=0.002, decay=0.06), 0, 0.4)
write_wav("splash.wav", splash, peak=0.7)

# --- sizzle: lava swallowing the ball (bright noise burst, quick fizz out)
n = int(0.6 * SR)
sizzle = []
prev = 0.0
for i in range(n):
    t = i / SR
    env = min(1.0, t / 0.006) * math.exp(-4.0 * t)
    lp = 0.55 - 0.4 * min(1.0, t * 2)
    raw = random.uniform(-1, 1)
    prev = prev + lp * (raw - prev)
    sizzle.append(prev * env)
add(sizzle, tone(90, 0.25, attack=0.002, decay=0.1,
                 harmonics=[(1, 1.0), (1.5, 0.4)]), 0, 0.5)
write_wav("sizzle.wav", sizzle, peak=0.7)

# --- portal: swoop up, shimmer out
n = int(0.5 * SR)
portal = []
for i in range(n):
    t = i / SR
    env = min(1.0, t / 0.01) * math.exp(-5.5 * t)
    f = 420 + 900 * min(1.0, t * 5) + 90 * math.sin(2 * math.pi * 11 * t)
    v = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 1.5 * t)
    portal.append(env * v)
add(portal, noise_burst(0.12, decay=0.03, lp=0.6), 0, 0.2)
write_wav("portal.wav", portal, peak=0.7)

# --- boost: short upward zap
n = int(0.26 * SR)
boost = []
for i in range(n):
    t = i / SR
    env = min(1.0, t / 0.003) * math.exp(-11 * t)
    f = 260 + 1500 * min(1.0, t * 9)
    boost.append(env * (math.sin(2 * math.pi * f * t)
                        + 0.25 * math.sin(2 * math.pi * f * 2 * t)))
write_wav("boost.wav", boost, peak=0.7)

# --- star: bright two-note pickup chime
star = silence(0.7)
for k, midi in enumerate([88, 95]):  # E6 B6
    f = 440 * 2 ** ((midi - 69) / 12)
    add(star, tone(f, 0.45, attack=0.002, decay=0.28, shape="tri",
                   harmonics=[(1, 1.0), (2, 0.22)]),
        int(0.07 * k * SR), 0.6)
write_wav("star.wav", star, peak=0.7)

# --- fail: descending double beep
fail = silence(0.55)
add(fail, tone(392, 0.22, attack=0.005, decay=0.16, shape="tri"), 0, 0.8)
add(fail, tone(294, 0.3, attack=0.005, decay=0.22, shape="tri"), int(0.18 * SR), 0.8)
write_wav("fail.wav", fail, peak=0.6)

# --- success: fanfare arpeggio
succ = silence(1.7)
for k, midi in enumerate([60, 64, 67, 72, 76]):  # C4 E4 G4 C5 E5
    f = 440 * 2 ** ((midi - 69) / 12)
    add(succ, tone(f, 0.9, attack=0.006, decay=0.55, shape="tri",
                   harmonics=[(1, 1.0), (2, 0.3), (3, 0.12)]),
        int(0.11 * k * SR), 0.6)
# final chord
for midi in [72, 76, 79]:
    f = 440 * 2 ** ((midi - 69) / 12)
    add(succ, tone(f, 1.0, attack=0.01, decay=0.7, shape="tri"), int(0.62 * SR), 0.35)
write_wav("success.wav", succ, peak=0.8)

# --- gameover: sad descending line
go = silence(1.9)
for k, midi in enumerate([69, 65, 62, 57]):  # A4 F4 D4 A3
    f = 440 * 2 ** ((midi - 69) / 12)
    add(go, tone(f, 0.8, attack=0.01, decay=0.5,
                 harmonics=[(1, 1.0), (2, 0.18)]),
        int(0.3 * k * SR), 0.7)
write_wav("gameover.wav", go, peak=0.65)

# --- music: gentle 16s pad loop (Cmaj7 -> Am7 -> Fmaj7 -> G6)
MSR = 32000
total = 16.0
music = [0.0] * int(total * MSR)
chords = [
    [48, 55, 64, 71],  # C  G  E  B
    [45, 52, 60, 67],  # A  E  C  G
    [41, 48, 57, 64],  # F  C  A  E
    [43, 50, 59, 64],  # G  D  B  E
]


def pad_note(freq, dur, sr):
    n = int(dur * sr)
    out = []
    for i in range(n):
        t = i / sr
        a = min(1.0, t / 1.2)
        r = min(1.0, (dur - t) / 1.4)
        env = a * r
        v = (math.sin(2 * math.pi * freq * t)
             + 0.35 * math.sin(2 * math.pi * freq * 2 * t)
             + 0.12 * math.sin(2 * math.pi * freq * 3.01 * t))
        # slow shimmer
        v *= 1 + 0.08 * math.sin(2 * math.pi * 0.7 * t + freq)
        out.append(v * env)
    return out


for c, chord in enumerate(chords):
    start = int(c * 4.0 * MSR)
    for midi in chord:
        f = 440 * 2 ** ((midi - 69) / 12)
        add(music, pad_note(f, 4.6, MSR), start, 0.16, wrap=True)

# sparse pentatonic bells
bell_times = [1.0, 3.2, 5.5, 7.4, 9.0, 11.3, 13.6, 15.2]
bell_notes = [84, 79, 76, 81, 74, 79, 84, 76]
for bt, midi in zip(bell_times, bell_notes):
    f = 440 * 2 ** ((midi - 69) / 12)
    note = tone(f, 1.6, sr=MSR, attack=0.005, decay=1.1,
                harmonics=[(1, 1.0), (2, 0.25)])
    add(music, note, int(bt * MSR), 0.10, wrap=True)

write_wav("music.wav", music, sr=MSR, peak=0.6)

# --- loop: doppler whoosh for a ball riding round the ring. Appended after the
# music so every sound above keeps its own slice of the seeded noise stream.
n = int(0.55 * SR)
loop = []
for i in range(n):
    t = i / SR
    env = math.sin(math.pi * min(1.0, t / 0.5)) ** 1.4
    # pitch rises into the top of the loop and falls away out of it
    f = 300 + 520 * math.sin(math.pi * min(1.0, t / 0.5))
    v = math.sin(2 * math.pi * f * t) * 0.55
    loop.append(env * v)
add(loop, noise_burst(0.5, decay=0.4, lp=0.25), 0, 0.7)
write_wav("loop.wav", loop, peak=0.6)

# --- cannon: breech thump, then the shot
cannon = silence(0.65)
add(cannon, tone(90, 0.3, attack=0.002, decay=0.09,
                 harmonics=[(1, 1.0), (2, 0.4), (3, 0.15)]), 0, 0.9)
add(cannon, noise_burst(0.3, decay=0.07, lp=0.35), int(0.01 * SR), 0.8)
crack = []
for i in range(int(0.25 * SR)):
    t = i / SR
    env = math.exp(-16 * t)
    f = 620 - 400 * min(1.0, t * 6)
    crack.append(env * math.sin(2 * math.pi * f * t))
add(cannon, crack, int(0.012 * SR), 0.6)
write_wav("cannon.wav", cannon, peak=0.85)

print("done")
