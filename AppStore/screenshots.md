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
| iPhone 6.9" App Preview | `preview/<locale>/iphone-6.9.mp4` | 1290 × 2796, 30 fps, 26.5 s | 1 |
| iPad 13" App Preview | `preview/<locale>/ipad-13.mp4` | 1200 × 1600, 30 fps, 26.6 s | 1 |

79 MB of screenshots, 80 MB for the captioned variant and 136 MB of video in total.

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
| 1 | `01-aim` | Green Garden, hole 6 — windmill and aim line | `-autostart garden 6 -aimdemo 0.7 -zoom 1.8` |
| 2 | `02-neon` | Neon Nights, hole 12 — rotor | `-autostart neon 12 -aimdemo 0.6 -zoom 1.35` |
| 3 | `03-worlds` | Course select with all nine worlds | `-courseselect -unlockall` |
| 4 | `04-volcano` | Volcano Forge, hole 10 — lava and belts | `-autostart volcano 10 -aimdemo 0.55 -zoom 1.3` |
| 5 | `05-cosmos` | Orbital Station, hole 6 — centrifuge and loop | `-autostart cosmos 6 -aimdemo 0.6 -zoom 1.35` |
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

`-zoom` multiplies the given hole's `cameraZoom`, so the values in the table differ
from hole to hole; the goal is always to get both the ball and the cup into frame.
They are chosen so that the resulting zoom lands around 1.8 — the shadows are still
fine there. With the camera zoomed far out they start dropping away, because the
shadow map cascade is shorter than the camera's view distance.

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
| 1 | Green Garden, hole 1 | the putt, the ball dropping in, the PAR message |
| 2 | Neon Nights, hole 3 | bouncing between the pinball bumpers |
| 3 | Frozen Fjord, hole 10 | ice belts, turning into a BIRDIE |
| 4 | Volcano Forge, hole 10 | a run past the lava |
| 5 | Orbital Station, hole 6 | the centrifuge spun up |
| 6 | Final rating | "Pro Golfer" and the results |

It plays itself (`-autoshot -autoadvance`) and the physics is deterministic, so the
same arguments give the same recording every time — which is why the cut points in
`Tools/appstore_media.sh` (`IPHONE_CUTS`, `IPAD_CUTS`) still line up after
a regeneration. The iPad has its own points, because it reaches each hole a little
sooner than the iPhone.

The simulator records at ~72 fps, which App Store Connect rejects;
[`Tools/appstore_video.swift`](../Tools/appstore_video.swift) recuts the recording,
scales it to the target resolution and exports H.264 at 30 fps.

The iPhone video is 1290 × 2796 — the simulator recording (1320 × 2868) has
a marginally different aspect ratio, so it is scaled to width and a few rows are
cropped top and bottom to keep the image undistorted. Should App Store Connect
insist on something else at this resolution, force a regeneration:

```bash
swift Tools/appstore_video.swift out.mp4 1320 2868 <clip>:<from>:<to> …
```
