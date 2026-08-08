#!/usr/bin/env python3
"""Turn downloaded music into the playlists the game plays.

Every world is a playlist of three or four tracks. The game plays them once
each, shuffled, crossfading one into the next, and only comes back round after
all of them — because a single loop, however good, is heard six times while
somebody lines up one putt, and by the fourth it has stopped being music.

Downloaded tracks are not ready for that. They are the wrong sample rate, they
are three minutes long where the player can only hold one, and ten of them from
four composers are mastered several dB apart. Per track this:

  * decodes whatever you downloaded to 44.1 kHz stereo, which is what
    `MusicPlayer` insists on before it will play a file at all,
  * takes the section you picked, within a hard ceiling on length,
  * matches the level to every other track through a loudness weighting,
  * encodes to AAC as `<world>-<n>.m4a`, the names the game looks for,
  * and rewrites the attribution — both the markdown record and the Swift the
    credits screen reads — from the same manifest.

There is also a loop finder, for a world you would rather run as one repeating
track: set `search` on its entry and it will pick the length whose end best
resembles its own beginning and crossfade the two. Nothing uses it at present;
`--probe` uses it to report whether a candidate has a good loop in it at all.

Usage:
    python3 Tools/import_music.py --probe ~/Downloads/track.wav
    python3 Tools/import_music.py garden        # one world
    python3 Tools/import_music.py               # everything with a source
    python3 Tools/import_music.py --wav         # keep WAVs to listen to
    python3 Tools/import_music.py --credits     # rewrite the attribution only

The manifest lives in `Tools/music_sources.json`. Nothing here is synthesised —
if a world has no source yet it is skipped and reported, so the soundtrack can
be brought in one world at a time.
"""

import array
import glob
import json
import math
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import wave

SR = 44100
TAU = math.tau

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "music_sources.json")
OUT = os.path.join(HERE, "..", "Minigolf", "Resources", "Music")
CREDITS = os.path.join(OUT, "CREDITS.md")

# The names `MusicTrack` looks for. A world with no entry here would never be
# asked for, and an entry with no world would never be played.
WORLDS = ["menu", "garden", "desert", "jungle", "ice", "neon", "volcano",
          "clockwork", "storm", "cosmos"]

AAC_BITRATE = "96000"

# A hard ceiling on how long any one track may be, because it is a constraint
# of the player rather than a matter of taste: `MusicPlayer` decodes a whole
# track to PCM so it can crossfade sample-accurately, at ~350 kB per second,
# and holds two at a time across a change. A three-minute track would be 60 MB
# on its own. Anything longer is cut here and said so, rather than quietly
# shipping and being found on an old phone.
MAX_SECONDS = 60.0

# Everything is matched to this, measured through `weighted_rms`. It matters
# more here than it would for one composer: the soundtrack comes from four, and
# a track four dB louder than the one before it reads as a bug rather than as a
# choice. The level sits under the effects, because music is background and the
# sounds that tell you what the ball did are not.
TARGET_DB = -24.0

# Licences that may ship, refused here rather than discovered later.
#
# CC-BY-SA is deliberately absent even though it is a perfectly good licence.
# This tool trims a track and folds its tail over its head, which makes the
# result an adaptation, and ShareAlike then reaches the audio that ships. That
# is survivable but it is paperwork, and there is enough CC0 around not to take
# it on. NonCommercial is absent for a different reason: the game being free
# does not make it non-commercial — Creative Commons draws that line at
# commercial advantage, and one ad or in-app purchase moves it.
#
# These are prefixes, not whole licence names, because the version is part of
# the licence and belongs in the credit. CC-BY 3.0 and CC-BY 4.0 are different
# documents, and a notice naming the wrong one is a wrong notice; the manifest
# carries the exact string and this only decides whether it may ship.
OK_LICENCES = ("CC0", "PD", "CC-BY", "OGA-BY", "purchased", "commissioned")
NEEDS_CREDIT = ("CC-BY", "OGA-BY")


def _named(licence, name):
    """Whether `licence` is `name`, with nothing but a version after it.

    A plain `startswith` is what this was, and it admitted precisely the two
    licences the list above is written to keep out: CC-BY-SA and CC-BY-NC both
    begin with CC-BY. The name has to be the whole licence — what follows may
    be a version, but it may not be another clause.
    """
    if not licence.startswith(name):
        return False
    rest = licence[len(name):]
    return not rest or not (rest[0] == "-" or rest[0].isalnum())


def licence_ok(licence):
    return any(_named(licence, n) for n in OK_LICENCES)


def needs_credit(licence):
    return any(_named(licence, n) for n in NEEDS_CREDIT)


# ---------------------------------------------------------------------------
# Audio in and out
# ---------------------------------------------------------------------------

def decode(path):
    """Anything afconvert can read -> 44.1 kHz stereo samples.

    Forcing the rate and the channel count here rather than trusting the
    download is the difference between a track that plays and one that
    `MusicPlayer` silently refuses: it checks both before it will build a
    buffer, and a 48 kHz or mono file just never makes a sound.
    """
    if not os.path.exists(path):
        raise SystemExit("no such file: " + path)
    tmp = tempfile.mktemp(suffix=".wav")
    try:
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100",
                        "-c", "2", path, tmp],
                       check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        raise SystemExit("afconvert could not read %s\n%s"
                         % (path, e.stderr.decode("utf-8", "replace").strip()))
    try:
        return read_wav(tmp)
    finally:
        os.remove(tmp)


def read_wav(path):
    with wave.open(path) as w:
        n = w.getnframes()
        ch = w.getnchannels()
        raw = array.array("h")
        raw.frombytes(w.readframes(n))
    if sys.byteorder != "little":
        raw.byteswap()
    left = array.array("d", [raw[i * ch] / 32768.0 for i in range(n)])
    right = array.array("d", [raw[i * ch + (1 if ch > 1 else 0)] / 32768.0
                              for i in range(n)])
    return left, right


def write_wav(path, left, right):
    n = len(left)
    flat = array.array("h", bytes(4 * n))
    for i in range(n):
        flat[2 * i] = int(max(-1.0, min(1.0, left[i])) * 32767)
        flat[2 * i + 1] = int(max(-1.0, min(1.0, right[i])) * 32767)
    if sys.byteorder != "little":
        flat.byteswap()
    with wave.open(path, "w") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(flat.tobytes())


def decoded_peak(m4a_path):
    """The loudest sample the encoded file actually decodes back to.

    AAC does not return the samples it was given. It overshoots, and the amount
    depends on the material: thirty-one of these tracks come back within a
    whisker of where they went in, and one comes back at 1.11 — eleven samples
    past full scale, which is clipping that was not in the audio before it was
    encoded. Predicting that is guesswork; measuring it is not.
    """
    tmp = tempfile.mktemp(suffix=".wav")
    try:
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEF32@44100",
                        "-c", "2", m4a_path, tmp], check=True, capture_output=True)
        with open(tmp, "rb") as f:
            raw = f.read()
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)
    i = raw.find(b"data")
    n = struct.unpack("<I", raw[i + 4:i + 8])[0]
    a = array.array("f")
    a.frombytes(raw[i + 8:i + 8 + n - (n % 4)])
    return max((abs(v) for v in a), default=0.0)


def encode(wav_path, m4a_path):
    if os.path.exists(m4a_path):
        os.remove(m4a_path)
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", AAC_BITRATE,
                    "-q", "127", "-s", "2", wav_path, m4a_path], check=True)


# ---------------------------------------------------------------------------
# Measurement
# ---------------------------------------------------------------------------

def onepole_hp(buf, cutoff):
    c = 1.0 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    for i in range(len(buf)):
        x = buf[i]
        y += c * (x - y)
        buf[i] = x - y
    return buf


def onepole_lp(buf, cutoff):
    c = 1.0 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    for i in range(len(buf)):
        y += c * (buf[i] - y)
        buf[i] = y
    return buf


def weighted_rms(left, right):
    """RMS through a rough loudness weighting.

    Plain RMS is the wrong yardstick when the tracks come from ten different
    sources: one with a deep drone under it would be turned down until the half
    of it you can hear was several dB quieter than everything else. Two poles at
    130 Hz and one at 6 kHz are nowhere near a real K-weighting curve, but they
    put the measurement in the band that decides how loud something seems.
    """
    n = len(left)
    mono = array.array("d", [(left[i] + right[i]) * 0.5 for i in range(n)])
    onepole_hp(mono, 130.0)
    onepole_hp(mono, 130.0)
    onepole_lp(mono, 6000.0)
    return math.sqrt(sum(v * v for v in mono) / max(1, n))


def db(x):
    return 20.0 * math.log10(max(1e-12, x))


def seam_ratio(left, right):
    """The step across the loop join, against the biggest step inside it.

    Under 1.0 the join is no more abrupt than something the track already does
    on its own, which is the practical definition of inaudible.
    """
    worst = 0.0
    for buf in (left, right):
        n = len(buf)
        steps = sorted(abs(buf[i + 1] - buf[i]) for i in range(0, n - 1, 7))
        worst = max(worst, abs(buf[0] - buf[-1]) / max(1e-9, steps[-1]))
    return worst


# ---------------------------------------------------------------------------
# Looping
# ---------------------------------------------------------------------------

def _search_copy(left, right, decim=16):
    """Mono, lowpassed and decimated, for the loop search.

    The search only needs to know where the music repeats itself, which is a
    question about chords and swells, not about cymbals. Throwing away the top
    of the band and fifteen samples in sixteen makes it two orders of magnitude
    cheaper and does not change the answer.
    """
    n = len(left)
    mono = array.array("d", [(left[i] + right[i]) * 0.5 for i in range(n)])
    onepole_lp(mono, 1200.0)
    onepole_lp(mono, 1200.0)
    return array.array("d", [mono[i] for i in range(0, n, decim)]), decim


def find_loop(left, right, lo, hi, xf):
    """Pick the loop length in [lo, hi] whose end best matches its beginning.

    A crossfade hides a small mismatch. What it cannot hide is a chord change
    landing on top of a different chord, so the length is worth choosing rather
    than assuming: a track that turns around every eight bars has good loop
    points every eight bars and bad ones in between, and the difference between
    the two is the difference between a loop and a lurch.

    Coarse then fine, because the range can be tens of seconds wide and scoring
    every candidate position at full resolution is minutes of work for an answer
    that only needs to be right to within a few milliseconds — the crossfade
    covers the rest.

    Returns `(length_samples, score)`, score in -1..1 — above about 0.5 the
    crossfade is inaudible, below about 0.2 there is no good loop in the range
    and the section wants moving.
    """
    src, decim = _search_copy(left, right)
    n = len(src)
    win = max(1, int(xf * SR / decim))
    lo_i = max(win, int(lo * SR / decim))
    hi_i = min(n - win - 1, int(hi * SR / decim))
    if hi_i <= lo_i:
        raise SystemExit("source is too short for a %.1f-%.1f s loop" % (lo, hi))

    head = src[:win]
    head_energy = math.sqrt(sum(v * v for v in head)) + 1e-12

    def score_at(length):
        dot = 0.0
        energy = 0.0
        for i in range(win):
            t = src[length + i]
            dot += head[i] * t
            energy += t * t
        tail_energy = math.sqrt(energy) + 1e-12
        shape = dot / (head_energy * tail_energy)
        # Correlation divides the level out, so on its own it will happily pick
        # a join where the music has the right contour at half the volume —
        # which plays as the track dropping several dB every time it comes
        # round. The square root keeps this a preference rather than a veto: a
        # much better match a little quieter is still the better loop.
        level = min(head_energy, tail_energy) / max(head_energy, tail_energy)
        return shape * math.sqrt(level)

    coarse = max(1, int(0.05 * SR / decim))
    best = max(((p, score_at(p)) for p in range(lo_i, hi_i + 1, coarse)),
               key=lambda x: x[1])
    near_lo = max(lo_i, best[0] - coarse)
    near_hi = min(hi_i, best[0] + coarse)
    best = max(((p, score_at(p)) for p in range(near_lo, near_hi + 1)),
               key=lambda x: x[1])
    return best[0] * decim, best[1]


def make_loop(left, right, length, xf):
    """Fold the tail back over the head so the loop closes on itself.

    Output sample `length - 1` is followed, on repeat, by output sample 0 —
    which is the source's own sample `length`. The two were adjacent in the
    recording, so nothing about the join is a discontinuity; all the crossfade
    has to do is get the music that was arriving to agree with the music that
    was already there.
    """
    k = int(xf * SR)
    out = []
    for buf in (left, right):
        loop = array.array("d", buf[:length])
        for i in range(k):
            # Equal-power: two different moments of a piece are only partly
            # correlated, and a pair of linear ramps would dip in the middle.
            w = math.sin((i / k) * math.pi * 0.5)
            loop[i] = buf[length + i] * math.cos((i / k) * math.pi * 0.5) \
                + buf[i] * w
        out.append(loop)
    return out[0], out[1]


def soft_limit(left, right, knee=0.65, ceiling=0.89):
    """Round the peaks off instead of turning the whole track down.

    Scaling a track back because a few transients poked through the ceiling
    undoes the loudness match for every second of it that did not. Six of these
    tracks came out up to 3.4 dB under everyone else that way, which is heard as
    one of them being quiet rather than as one of them being careful.

    A tanh knee above `knee` approaches `ceiling` and never crosses it, so no
    clamp is needed afterwards. It is a waveshaper and it does add harmonics,
    but only to the handful of samples above the knee.

    The ceiling is a decibel under full scale on purpose. AAC does not decode
    back to the samples it was given: it overshoots, and a file mastered to 0.95
    came back at 1.000 with two dozen samples pinned at full scale — clipping
    that was not in the audio before it was encoded.
    """
    span = ceiling - knee
    for buf in (left, right):
        for i in range(len(buf)):
            x = buf[i]
            a = abs(x)
            if a > knee:
                buf[i] = math.copysign(knee + span * math.tanh((a - knee) / span), x)
    return left, right


def shaped_fraction(left, right, knee=0.70):
    """How much of the track the limiter actually touches."""
    n = len(left) * 2
    hit = sum(1 for buf in (left, right) for v in buf if abs(v) > knee)
    return hit / max(1, n)


def apply_gain(left, right, gain):
    for buf in (left, right):
        for i in range(len(buf)):
            buf[i] *= gain


def peak_of(left, right):
    return max(max(abs(v) for v in left), max(abs(v) for v in right))


# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------

TEMPLATE = {
    "_readme": [
        "One entry per file, grouped by world. Each world is a playlist: the game",
        "plays its entries once each, shuffled, crossfading one into the next, and",
        "only comes back round after all of them. That is what stops a melody from",
        "being heard six times while somebody lines up one putt.",
        "",
        "Because nothing here is looped on its own, playlist entries do not need a",
        "loop point — the crossfade between two different tracks does that job. Set",
        "`search` only for a world you want to run as a single repeating loop.",
        "",
        "  file      path to the source, absolute or relative to this file",
        "  download  where `file` came from, so Assets/music-src/ can be rebuilt",
        "  start     seconds into the source to begin (default 0)",
        "  length    seconds to keep (default: all of it) — used to keep the long",
        "            tracks from costing 60 MB of decoded audio each",
        "  search    [min, max] loop length, for a single-loop world; null otherwise",
        "  crossfade seconds folded from tail over head, when search is set",
        "  gain_db   your ears overruling the loudness match, per entry",
        "",
        "title/author/url/licence are the attribution record. `licence` must be one",
        "of CC0, PD, CC-BY, OGA-BY, purchased, commissioned — anything else is",
        "refused, and that list means what it says: CC-BY-SA and CC-BY-NC are not",
        "CC-BY. `url` is where the credit points; `download` is where the audio",
        "itself came from.",
    ],
    "tracks": {},
}

DEFAULTS = {
    "file": None,
    "download": None,   # where `file` was fetched from, for a clean checkout
    "start": 0.0,
    "search": None,
    "length": None,
    "crossfade": 4.0,
    "gain_db": 0.0,
    "title": "",
    "author": "",
    "url": "",
    "licence": "",
}

# What each world is asking for, so picking a track is a search rather than a
# guess. These are descriptions, not requirements.
# What each world is asking for. The register comes first and the theme second,
# which is the lesson of getting it wrong twice: a volcano hole in a minigolf
# game is a cartoon volcano, and epic orchestral music fits the theme perfectly
# while fitting the game not at all. Everything here should sound like it
# belongs under somebody lining up a putt.
WANTED = {
    "menu": "light jazz, clubhouse, inviting; a place to wait, not to fight",
    "garden": "bright, sunny, easy-going; acoustic rather than synthetic",
    "desert": "playful and dusty; a cartoon frontier, not a real wasteland",
    "jungle": "curious, bouncy, a bit silly; adventure at toy scale",
    "ice": "calm, sparkling, cool; peaceful rather than bleak",
    "neon": "retro synth, cruising, unhurried; eighties as decor",
    "volcano": "energetic and grooving; heat as fun, never as menace",
    "clockwork": "quirky, toy-like, mechanical; music-box register",
    "storm": "breezy and coastal; weather with a tune in it",
    "cosmos": "twinkly, weightless, wide-eyed; wonder rather than solemnity",
}


def load_manifest():
    if not os.path.exists(MANIFEST):
        data = dict(TEMPLATE)
        data["tracks"] = {w: [dict(DEFAULTS)] for w in WORLDS}
        with open(MANIFEST, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print("created", os.path.relpath(MANIFEST))
    with open(MANIFEST) as f:
        data = json.load(f)
    tracks = data.get("tracks", {})
    for w in WORLDS:
        # A world is a playlist. A bare object is still accepted and read as a
        # playlist of one, so a manifest written before this was a list keeps
        # working rather than failing on a type it cannot explain.
        entries = tracks.get(w) or [{}]
        if isinstance(entries, dict):
            entries = [entries]
        merged = []
        for raw in entries:
            entry = dict(DEFAULTS)
            entry.update(raw)
            merged.append(entry)
        tracks[w] = merged
    unknown = [k for k in tracks if k not in WORLDS]
    if unknown:
        raise SystemExit("manifest has worlds the game never asks for: %s"
                         % ", ".join(sorted(unknown)))
    return data, tracks


def resolve(path):
    if os.path.isabs(path):
        return path
    return os.path.normpath(os.path.join(HERE, os.path.expanduser(path)))


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def probe(path):
    """Report on a candidate before you commit it to the manifest."""
    left, right = decode(resolve(path))
    n = len(left)
    print("%s\n  %.1f s, peak %.2f, weighted level %.1f dB"
          % (path, n / SR, peak_of(left, right), db(weighted_rms(left, right))))
    for lo, hi in ((30.0, 50.0), (50.0, 80.0)):
        if n / SR < hi:
            continue
        length, score = find_loop(left, right, lo, hi, 4.0)
        print("  best loop in %.0f-%.0f s: %.2f s, match %.2f  (%s)"
              % (lo, hi, length / SR, score,
                 "good" if score > 0.5 else
                 "usable" if score > 0.2 else "poor — try another section"))


def build(name, entry, keep_wav, index):
    src = entry.get("file")
    if not src:
        return None
    licence = entry.get("licence", "")
    if not licence_ok(licence):
        raise SystemExit("%s: licence %r is not one of %s — a track that "
                         "cannot ship should not be built into the app"
                         % (name, licence, ", ".join(sorted(OK_LICENCES))))

    left, right = decode(resolve(src))
    start = int(float(entry["start"]) * SR)
    if start:
        left = array.array("d", left[start:])
        right = array.array("d", right[start:])

    if entry.get("search"):
        lo, hi = entry["search"]
        xf = float(entry["crossfade"])
        length, score = find_loop(left, right, float(lo), float(hi), xf)
        left, right = make_loop(left, right, length, xf)
    else:
        # The source is already a seamless loop, so leave it alone. Running the
        # crossfade over a track that already meets itself would fold the end of
        # the music over the beginning for no reason and audibly double it.
        # `seam` in the report is what checks the claim.
        length = int(float(entry["length"]) * SR) if entry.get("length") else len(left)
        length = min(length, len(left), int(MAX_SECONDS * SR))
        left = array.array("d", left[:length])
        right = array.array("d", right[:length])
        score = None

    # Match, limit, then correct for what the limiter took off and match again.
    # Two or three passes is enough; the limiter only removes energy from the
    # peaks, so the correction shrinks fast.
    target = 10.0 ** ((TARGET_DB + float(entry["gain_db"])) / 20.0)
    master = list(left), list(right)

    def render(ceiling):
        l = array.array("d", master[0])
        r = array.array("d", master[1])
        for _ in range(4):
            level = weighted_rms(l, r)
            if level < 1e-9:
                break
            apply_gain(l, r, target / level)
            soft_limit(l, r, knee=ceiling * 0.73, ceiling=ceiling)
            if abs(db(weighted_rms(l, r)) - db(target)) < 0.1:
                break
        return l, r

    stem = "%s-%d" % (name, index)
    out_m4a = os.path.join(OUT, stem + ".m4a")
    ceiling = 0.89
    for attempt in range(4):
        left, right = render(ceiling)
        with tempfile.TemporaryDirectory() as tmp:
            wav_path = os.path.join(tmp, stem + ".wav")
            write_wav(wav_path, left, right)
            if keep_wav:
                preview = os.path.join(tempfile.gettempdir(), "minigolf-music")
                os.makedirs(preview, exist_ok=True)
                shutil.copy(wav_path, os.path.join(preview, stem + ".wav"))
            encode(wav_path, out_m4a)
        # Encoding is the last thing that can push a track over, so it is the
        # last thing that gets checked. Only a track that actually overshoots
        # pays for the extra pass.
        # The requirement is only that nothing lands past full scale; a hair
        # under is done. Aiming lower than that on the retry costs nothing and
        # stops the loop chasing a relationship that is not linear.
        back = decoded_peak(out_m4a)
        if back <= 0.995:
            break
        ceiling *= 0.97 / back
        print("      %s decodes back at %.3f — remastering to %.2f"
              % (stem, back, ceiling), flush=True)

    peak = peak_of(left, right)
    shaped = shaped_fraction(left, right)

    return {
        "seconds": len(left) / SR,
        "match": score,   # None when the source was taken as an existing loop

        "seam": seam_ratio(left, right),
        "peak": peak,
        "kb": os.path.getsize(out_m4a) / 1024.0,
        "shaped": shaped,
        "stem": stem,
        "title": entry.get("title", ""),
    }


def write_credits(tracks):
    """The attribution file.

    CC-BY is free the way a contract is free: you may ship it, and you owe the
    credit. Generating this from the same manifest the audio is built from is
    the only way it stays true — a hand-kept credits list drifts the first time
    a track is swapped.
    """
    lines = [
        "# Music credits",
        "",
        "Generated by `Tools/import_music.py --credits`. Do not edit by hand;",
        "edit `Tools/music_sources.json` and run it again.",
        "",
    ]
    if not any(e.get("file") for v in tracks.values() for e in v):
        lines += ["No tracks imported yet.", ""]
    for world in WORLDS:
        entries = [e for e in tracks[world] if e.get("file")]
        if not entries:
            continue
        lines += ["## %s" % world, ""]
        for i, entry in enumerate(entries, 1):
            title = entry.get("title") or os.path.basename(entry["file"])
            by = " — %s" % entry["author"] if entry.get("author") else ""
            note = ("  (attribution required)"
                    if needs_credit(entry.get("licence", "")) else "")
            lines.append("%d. **%s**%s — %s%s"
                         % (i, title, by, entry.get("licence", "?"), note))
            if entry.get("url"):
                lines.append("   %s" % entry["url"])
        lines.append("")

    needs = sorted({e.get("author", "?") for v in tracks.values() for e in v
                    if e.get("file") and needs_credit(e.get("licence", ""))})
    if needs:
        lines += [
            "---",
            "",
            "Attribution is a condition of the licence, not a courtesy, and it",
            "has to be somewhere a player can reach — an in-app credits screen;",
            "the store description is not sufficient on its own. The app shows",
            "these under Settings > Audio, generated from this same manifest.",
            "",
            "Authors owed a credit: %s." % ", ".join(needs),
            "",
        ]
    with open(CREDITS, "w") as f:
        f.write("\n".join(lines))
    print("wrote", os.path.relpath(CREDITS))
    write_library_swift(tracks)


def write_library_swift(tracks):
    """The playlists and the attribution, as something the app can use.

    Both are facts about what is actually in the bundle, so both are generated
    from the manifest rather than typed out twice. Swap a track and the
    playlist and the credit move with it; there is no second place to forget.
    """
    def swift_str(s):
        return '"%s"' % s.replace("\\", "\\\\").replace('"', '\\"')

    # Everyone whose music is in the game, not only those the licence obliges
    # us to name. CC0 asks for nothing; putting the author in anyway costs a
    # line and is the difference between a credits screen and a disclaimer.
    names = sorted({e.get("author", "?") for world in WORLDS
                    for e in tracks[world] if e.get("file")})
    rows = ",\n".join("        %s" % swift_str(n) for n in names)

    lists = []
    for world in WORLDS:
        # Numbered among the entries that have a source, which is how `main`
        # numbers the files it writes. Counting the ones without would name a
        # track the encoder never produced.
        played = [e for e in tracks[world] if e.get("file")]
        stems = ["%s-%d" % (world, i) for i in range(1, len(played) + 1)]
        lists.append("        .%s: [%s]"
                     % (world, ", ".join(swift_str(x) for x in stems)))

    # Every track by name. CC-BY asks for the title of the work as well as the
    # author, and the markdown file next to the audio is not something a player
    # can open — so the list the credits screen shows has to be the whole thing.
    works = ",\n".join(
        "        MusicWork(title: %s, author: %s, licence: %s, link: %s)"
        % (swift_str(e.get("title", "?")), swift_str(e.get("author", "?")),
           swift_str(e.get("licence", "?")), swift_str(e.get("url", "")))
        for world in WORLDS for e in tracks[world] if e.get("file"))

    body = '''//
//  MusicLibrary.swift
//  Minigolf
//
//  Generated by Tools/import_music.py from Tools/music_sources.json.
//  Do not edit by hand — edit the manifest and re-run the importer.
//

import Foundation

/// Everyone whose music is in the game — not only those the licence obliges us
/// to name. CC0 asks for nothing; putting the author in anyway costs a line and
/// is the difference between a credits screen and a disclaimer.
enum MusicCredit {
    static let authors = [
%s
    ]

    /// The authors as one phrase, for a sentence rather than a list. Joined
    /// here rather than in the generator because the conjunction is a different
    /// word in each language the game speaks, and a generated string would be
    /// English inside a Czech sentence.
    static var authorList: String { authors.formatted(.list(type: .and)) }
}

/// One track, named. CC-BY wants the title of the work and not only who wrote
/// it, so the credits screen lists these rather than summarising them.
struct MusicWork: Identifiable, Hashable {
    let title: String
    let author: String
    let licence: String
    let link: String

    var id: String { title + author }
    var url: URL { URL(string: link) ?? URL(string: "https://opengameart.org/")! }

    static let all: [MusicWork] = [
%s
    ]

    /// Grouped by author, each group in the order the manifest lists them.
    static var byAuthor: [(author: String, works: [MusicWork])] {
        var order: [String] = []
        var groups: [String: [MusicWork]] = [:]
        for work in all {
            if groups[work.author] == nil { order.append(work.author) }
            groups[work.author, default: []].append(work)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }
}

extension MusicTrack {
    /// The resource names for this world, in manifest order.
    ///
    /// A world is a playlist rather than a single loop: one track of forty
    /// seconds gets heard six times while somebody lines up a putt, and by the
    /// fourth the melody is an irritation. `MusicPlayer` plays these once each
    /// in a shuffled order, crossfading one into the next.
    static let playlists: [MusicTrack: [String]] = [
%s
    ]

    var resources: [String] { Self.playlists[self] ?? [] }
}
''' % (rows, works, ",\n".join(lists))
    path = os.path.join(HERE, "..", "Minigolf", "Game", "MusicLibrary.swift")
    with open(path, "w") as f:
        f.write(body)
    print("wrote", os.path.relpath(path))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    flags = {a for a in sys.argv[1:] if a.startswith("-")}

    if "--probe" in flags:
        if not args:
            raise SystemExit("--probe needs a file")
        for path in args:
            probe(path)
        return

    data, tracks = load_manifest()

    if "--credits" in flags:
        write_credits(tracks)
        return

    names = args or WORLDS
    unknown = [n for n in names if n not in WORLDS]
    if unknown:
        raise SystemExit("unknown world(s): " + ", ".join(unknown))

    os.makedirs(OUT, exist_ok=True)
    keep_wav = "--wav" in flags
    done, missing = [], []
    # Anything left over from an earlier, shorter playlist would still be in the
    # bundle and never played. Clearing the world's files first keeps what ships
    # equal to what the manifest says.
    for name in names:
        for stale in glob.glob(os.path.join(OUT, "%s-*.m4a" % name)):
            os.remove(stale)
    for name in names:
        entries = [e for e in tracks[name] if e.get("file")]
        if not entries:
            missing.append(name)
            continue
        print("importing %s (%d tracks) ..." % (name, len(entries)), flush=True)
        for i, entry in enumerate(entries, 1):
            done.append((name, build(name, entry, keep_wav, i)))

    if done:
        print("\n%-11s %-22s %7s %7s %6s %6s %7s %8s" %
              ("world", "track", "length", "match", "seam", "peak", "limit", "size"))
        total = 0.0
        for name, r in done:
            ok = r["match"] is None or (r["seam"] <= 1.0 and r["match"] > 0.2)
            total += r["kb"]
            print("%-11s %-22s %6.1fs %7s %6s %6.2f %6.2f%% %7.0fkB%s" % (
                name, r["title"][:22], r["seconds"],
                "once" if r["match"] is None else "%.2f" % r["match"],
                "-" if r["match"] is None else "%.2f" % r["seam"],
                r["peak"], r["shaped"] * 100.0, r["kb"],
                "" if ok else "   <-- check"))
        print("%-11s %-22s %6.1fs %7s %6s %6s %7s %7.1fMB" %
              ("", "%d tracks" % len(done), sum(r["seconds"] for _, r in done),
               "", "", "", "", total / 1024.0))
        write_credits(tracks)

    if missing:
        print("\nno source yet (this world will be silent):")
        for name in missing:
            print("  %-10s %s" % (name, WANTED[name]))
        print("\nadd a file to %s and run again."
              % os.path.relpath(MANIFEST))

    if keep_wav and done:
        print("\nWAVs to listen to in %s"
              % os.path.join(tempfile.gettempdir(), "minigolf-music"))


if __name__ == "__main__":
    main()
