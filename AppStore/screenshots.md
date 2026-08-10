# Screenshots and App Preview

The media is **not made by hand and is not in git** — the scripts below produce
it. Uploading is manual: in App Store Connect drag the files into the *App Preview
and Screenshots* section (language switch at the top, one locale at a time).

## What the scripts produce

| What | Where | Resolution | Count |
|---|---|---|---|
| iPhone 6.9" screenshots | `screenshots/<locale>/iphone-6.9/` | 1320 × 2868 | 8 |
| iPad 13" screenshots | `screenshots/<locale>/ipad-13/` | 2064 × 2752 | 8 |
| The same with captions | `screenshots-captioned/<locale>/<device>/` | same | 8 + 8 |
| iPhone 6.9" App Preview | `preview/<locale>/iphone-6.9.mp4` | 1290 × 2796, 30 fps, 24.9 s | 1 |
| iPad 13" App Preview | `preview/<locale>/ipad-13.mp4` | 1200 × 1600, 30 fps, 24.7 s | 1 |

86 MB of screenshots, 80 MB for the captioned variant and 129 MB of video in total.

```bash
Tools/appstore_media.sh              # screenshots and videos (~20 min)
Tools/appstore_media.sh screenshots  # screenshots only (~8 min)
Tools/appstore_media.sh video        # videos only (~12 min)
Tools/appstore_captions.sh           # paints captions onto finished screenshots (~2 min)
```

The locales are `cs` and `en-US`, everything in portrait. **Upload either the
captioned set or the plain one** — both have the same file names and order, they
differ only in the band at the top. Captions are not compulsory, but they lift
conversion.

The screenshots are 8-bit PNGs with no alpha channel (the simulator writes one
even when it is fully opaque, and App Store Connect does not want transparency)
and have been through a lossless recompression — verified with
`magick compare -metric AE` = 0.

`appstore_media.sh` needs Xcode, the *iPhone 17 Pro Max* and
*iPad Pro 13-inch (M5)* simulators and ImageMagick (`brew install imagemagick`).
It builds Debug — every flag below sits under `#if DEBUG` and never reaches an
App Store build. `appstore_captions.sh` only repaints finished PNGs and needs no
simulator.

### Why it is not in git

Almost 300 MB of images and video are output, not source — the source is this
description and the scripts in `Tools/`. A PNG is already compressed, so git
cannot shrink it and it would stay in the history for good; and because the
windmills and pendulums keep turning, the set is not byte-reproducible — every
regeneration would add another 85 MB of new blobs, not a diff.

App Store Connect keeps the record of what was actually shipped with each version.
If you ever need the exact files locally as well, attach them as a ZIP to the
release on the matching tag — that keeps them out of the repository history.

## What Apple requires

The app targets iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), so **two sets**
of screenshots are mandatory. Apple derives the smaller sizes itself.

| Set | Resolution (portrait) | Resolution (landscape) | Count |
|---|---|---|---|
| iPhone 6.9" | 1290 × 2796 or 1320 × 2868 | 2796 × 1290 or 2868 × 1320 | 3–10 |
| iPad 13" | 2048 × 2732 or 2064 × 2752 | 2732 × 2048 or 2752 × 2064 | 3–10 |

PNG or JPEG, no transparency, no rounded corners, no device frame (a frame is
allowed, but it has to be part of the image and must not cover the content). They
are ordered the way you upload them — **the first two are all most people will
ever see** in search results.

The App Preview is optional, 15–30 s, H.264 or ProRes 422 HQ, 30 fps. Sound is not
required and the finished videos have none — the simulator does not record audio
and a voiceover would have to be localised anyway.

## The set (8 images)

The order is also the upload order. The arguments can be entered by hand in Xcode
too: **Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch**.

| # | File | Screen | Arguments |
|---|---|---|---|
| 1 | `01-aim` | Green Garden, hole 5 "The Windmill" — turning sails and the aim line | `-autostart garden 5 -aimdemo 0.7 -zoom 1.3` |
| 2 | `02-neon` | Neon Nights, hole 12 — the world finale, two levels and bumpers | `-autostart neon 12 -aimdemo 0.6 -zoom 1.35` |
| 3 | `03-worlds` | Course select with all nine worlds | `-courseselect -unlockall` |
| 4 | `04-volcano` | Volcano Forge, hole 9 "Lava Flow" — two lava rivers along the lane | `-autostart volcano 9 -aimdemo 0.55 -zoom 1.5` |
| 5 | `05-cosmos` | Orbital Station, hole 2 "First Loop" — the loop-the-loop | `-autostart cosmos 2 -aimdemo 0.6 -zoom 1.4` |
| 6 | `06-rating` | Final rating and scorecard | `-finalrating -unlockall` |
| 7 | `07-clubhouse` | Clubhouse — balls, career, trophies | `-clubhouse -unlockall` |
| 8 | `08-daily` | Daily Challenge | `-daily -aimdemo 0.6 -zoom 1.5` |

### Debug flags

| Flag | What it does |
|---|---|
| `-autostart <world> <hole>` | jumps straight into the hole |
| `-aimdemo [0…1]` | holds the aim on the cup so the aim line can be photographed |
| `-zoom <0.7…1.8>` | pins the camera pinch zoom so the whole lane fits into the frame |
| `-unlockall` | fills in believable progress and career statistics for menu shots (nothing is written to disk) |
| `-courseselect`, `-clubhouse`, `-daily`, `-finalrating`, `-holeselect <world>` | opens that screen |
| `-autoshot`, `-autowin`, `-autoadvance` | plays by itself — used for the video |

`-zoom` multiplies the given hole's `cameraZoom` and a larger value pulls the camera
further back, so the values in the table differ from hole to hole; the goal is always
to get both the ball and the cup into frame. The product lands between roughly 1.8
(garden 5) and 3.1 (volcano 9) — do not push it much past that, because the shadows
start dropping away once the camera is further out than the shadow map cascade
reaches.

The whole set is tied to the level library: when a hole is redesigned or renumbered
the shot may quietly stop showing what its row claims. After any level rework, look
at the eight images before uploading — that is how holes 1, 4 and 5 came to be
re-picked when the geometry pass moved the windmill and left the lava out of frame.

Regenerating does not give pixel-identical files: the windmills, rotors and
pendulums keep turning and the aiming ring pulses, so you catch them in a different
phase every time. The composition and the resolutions do match, though — the static
screens (`03-worlds`, `06-rating`) come out identical.

## Captions on the images

[`Tools/appstore_captions.sh`](../Tools/appstore_captions.sh) makes them from the
plain set into `screenshots-captioned/`.

Layout: a band of text at the top, below it the shrunken screenshot on dark green
(derived from the main menu gradient) with a thin border and a soft shadow. The
game shot is never cropped, only scaled down — so neither the HUD at the top nor
the power gauge at the bottom loses anything. The text is Arial Bold; it is the
only bold face in the system with complete Czech diacritics (Arial Rounded Bold has
neither `ť` nor `ě`, and SF only renders in regular through ImageMagick).

| # | Czech | English |
|---|---|---|
| 1 | Táhni, pusť, trefa. | Drag, release, sink it. |
| 2 | 9 světů, 108 jamek | 9 worlds, 108 holes |
| 3 | Od zahrady po orbit | From garden to orbit |
| 4 | Láva, led, vítr i magnety | Lava, ice, wind and magnets |
| 5 | Loopingy a děla | Loops and cannons |
| 6 | Par, Birdie, Eagle… nebo Bogey | Par, Birdie, Eagle… or Bogey |
| 7 | 14 míčků, 18 trofejí | 14 balls, 18 trophies |
| 8 | Nová jamka každý den | A new hole every day |

Number six uses the longer variant from the table below — the original "Hole-in-one?
Zkus to." aimed at the message shown after a finished hole, but the shot ended up
being the final scorecard, which suits a list of scores better. The texts are edited
in both the `cs_caption` / `en_caption` functions in the script; the line breaks in
the longer captions are written by hand there, so that no single word is left
hanging on the second line.

Longer variants, if there is room for two lines on the image:

| # | Czech | English |
|---|---|---|
| 1 | Naváděcí čára ukáže i odrazy od mantinelů | The aim line shows your bank shots |
| 2 | 108 ručně navržených jamek v devíti světech | 108 hand-designed holes, nine worlds |
| 3 | Každý svět má vlastní pravidla | Every world plays by its own rules |
| 4 | Voda a láva stojí trestný úder | Water and lava cost you a stroke |
| 5 | Fyzika, která se chová, jak čekáš | Physics that behaves the way you expect |
| 6 | Par, Birdie, Eagle… nebo Bogey | Par, Birdie, Eagle… or Bogey |
| 7 | Odemykej míčky, sbírej trofeje | Unlock balls, collect trophies |
| 8 | Jedna jamka denně, stejná pro všechny | One hole a day, same for everyone |

## App Preview (video)

The video is pure gameplay, no logo and no titles — it opens on a putt, because the
first few seconds are what decide. It is made of six cuts:

| # | Shot | What is on screen |
|---|---|---|
| 1 | Green Garden, hole 1 | the opening putt and the long roll up to the cup |
| 2 | Neon Nights, hole 3 | past the pinball bumpers |
| 3 | Frozen Fjord, hole 10 | across the ice terraces |
| 4 | Volcano Forge, hole 9 | a run between the two lava rivers |
| 5 | Orbital Station, hole 2 | the ball driven up and through the loop |
| 6 | Final rating | "Pro Golfer" and the results |

It plays itself (`-autoshot -autoadvance`) and the physics is deterministic, so the
same arguments give the same recording every time — which is why the cut points in
`Tools/appstore_media.sh` (`IPHONE_CUTS`, `IPAD_CUTS`) still line up after
a regeneration. The iPad has its own points, because it reaches each hole a little
sooner than the iPhone.

What the cut points are worth is a different question from whether they still line
up. The bot aims at the cup and fires every 1.6 s at a fixed strength, so it is
a poor golfer on the reworked holes: it parks the ball beside the cup and taps at
it, and none of the five gameplay clips ends on a ball dropping in. Each window is
therefore chosen to hold a ball that is *moving* — a strike and the roll that
follows — and to end before the ball stops. Two things bound them at the front:
the loading veil is still fading over the first second or so (longest on ice), and
the opening flyover has to be over. Clip five is the exception that needed more
than a re-cut: the loop rejects the bot's default strength outright, so that clip
is recorded with `-calibrate 0.85` to give the ball enough speed to get round.

After any physics or level change, look at the finished video before uploading.
Nothing here fails loudly — a stale window just goes quiet, and a hole that has
been renumbered simply shows something else.

The simulator records at ~72 fps, which App Store Connect rejects;
[`Tools/appstore_video.swift`](../Tools/appstore_video.swift) recuts the recording,
scales it to the target resolution and exports H.264 at 30 fps.

One trap lives in that step, and it costs an hour to find because the export
reports success. The rating clip is the only recording that never moves, so the
encoder gives it a very long GOP; asking for a range that starts mid-GOP is fine
on its own, but once that segment sits at a non-zero offset in the composition the
export silently drops its media and holds the last frame of the *preceding* clip
for those seconds instead. The composition itself is correct — `AVComposition`
reports both segments, non-empty, at the right times — so only looking at the
finished file catches it. Hence `r6-rating:0.0:…`: starting on the keyframe is
what makes it render, and the screen is identical throughout anyway. Any future
clip of a still screen needs the same treatment.

The iPhone video is 1290 × 2796 — the simulator recording (1320 × 2868) has
a marginally different aspect ratio, so it is scaled to width and a few rows are
cropped top and bottom to keep the image undistorted. Should App Store Connect
insist on something else at this resolution, force a regeneration:

```bash
swift Tools/appstore_video.swift out.mp4 1320 2868 <clip>:<from>:<to> …
```
