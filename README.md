# ⛳️ Minigolf

A complete 3D minigolf game for iPhone and iPad built on **SwiftUI + RealityKit**.
No external dependencies, no downloaded assets — every bit of the graphics is
generated procedurally and the sounds are synthesised WAVs bundled with the app.

## The game

- **9 worlds × 12 holes = 108 holes** unlocked one after another (total par 456):
  - 🌿 **Green Garden** — a sunlit classic (beginner, par 36)
  - ☀️ **Desert Oasis** — sand traps, water, rotors (easy, par 42)
  - 🌳 **Jungle Temple** — mud, vines, portals, rivers (medium, par 45)
  - ❄️ **Frozen Fjord** — slick ice, floes, slopes (hard, par 48)
  - ✨ **Neon Nights** — Tron atmosphere, pinball, warps (very hard, par 51)
  - 🌋 **Volcano Forge** — lava, geysers, iron gates (expert, par 54)
  - ⚙️ **Clockwork Works** — turntables, pistons, cannons (master, par 57)
  - 🌊 **Storm Coast** — gusting wind, jumps over the surf (brutal, par 60)
  - 🌌 **Orbital Station** — loops, magnets, the void (legendary, par 63)
- **Every world has its own handwriting in plan.** The holes are not a rectangle
  with obstacles dropped into it but shapes — you can tell one world from
  another by the outline alone:
  - 🌿 **Garden** — the standard lane: a narrow 0.9 m corridor opening into
    a 1.4 m circular target green (the Eternit-system classic)
  - ☀️ **Desert** — basins pinched to a neck and opened out again, wadis,
    slanted boards
  - 🌳 **Jungle** — the plan of a building: halls, doors off the axis, a cross,
    a **labyrinth** with four mouths and the cup in the middle
  - ❄️ **Fjord** — channels between water, dykes, a crevasse with footbridges,
    a zigzag *lightning*
  - ✨ **Neon** — a printed circuit board: right angles throughout, a double
    gate, a rhombus, a screw thread
  - 🌋 **Volcano** — concentric shapes: a cone with the cup in its crater,
    a crater ring
  - ⚙️ **Clockwork** — a gearbox: circular chambers strung on short shafts
  - 🌊 **Coast** — a stepped shoreline, bays, dykes, breakwaters
  - 🌌 **Station** — modules and tubes: a junction with arms, a ring corridor

  They are modelled on the real WMF standard lanes (30 in miniature golf, 32 in
  felt golf) — pyramids, rods, right angle, lightning, labyrinth, passages,
  plateau, volcano, cross, herringbone, horseshoe, double gate, optical illusion
  and the rest.
- **Difficulty climbs with every hole and with every world.** It is measured as
  *travel* — the shortest path the ball takes from the tee to the cup around
  every rail and over the ramps, portals and jump ramps. It is not area: the
  labyrinth is two square metres and four putts, an open basin twice the area
  and one. The script below works it out, and four things hold in it:
  - travel per par stroke stays between **0.95 and 1.55 m** on all 108 holes
    (mean 1.17), so no hole is either too short or unplayably long for its par
  - **a world's finale is always its longest hole**
  - **a world's first hole is always gentler than the previous world's finale**
  - **median travel grows world by world**: 3.7 → 4.1 → 4.2 → 4.4 → 5.1 → 5.3 →
    5.5 → 5.5 → 5.7 m; the holes themselves run from 2.4 m (Green Garden 1) to
    7.0 m (Clockwork Works), par from 2 to 6, world par from 36 to 63.

  The later worlds are also built from several stretches in a row: a run-up,
  a banked turn along the rail, a hazard and finally a climb up a ramp to
  a raised green with obstacles of its own.
- **Obstacles:** windmill, rotors, sliding blocks, bumpers, skittles, speed
  bumps, ramps up to raised greens, tunnels, **tilted greens**, **belts/rivers**,
  **portals**, **timed gates**, **pendulums**, **a geyser tee** and the advanced
  set: **loop**, **jump ramp** (a ballistic hop across a chasm), **cannon**,
  **turntable**, **magnet / repulsor** and **a pulsing fan**.
  Rails can be curved (`arcWall`) into arcs and banks, and a circular target
  green is built from a `roundedFloor` / `roundedKerb` pair — a floor of strips
  and a rail laid over them, three boards to a corner (more than 0.15 m of
  radius per board already lets the felt peek out past the kerb).
- **The locals** — every world has a pair of critters going about the green on
  their own business: a hedgehog and a mole, a tumbleweed and a meerkat, a frog
  and a turtle, a **snowman** and a penguin, a drone and a watchtower, a sprite
  and a magma blob, a wind-up robot and a cuckoo, a crab and a seagull, an alien
  and a rover. They are not scenery — each has a kinematic body, so the ball
  bounces off them, a moving critter will nudge even a ball at rest, and a hit
  sets it rocking. They pace back and forth, circle, hop (you can putt underneath
  one mid-hop) or surface out of a hole in the turf. Their path is a function of
  the game clock, so a timed shot comes out the same the second time — and the
  aim line ignores them on purpose, just as it does the windmills and gates.
- **Surfaces:** grass, sand, **mud/ash** (extreme damping), **ice** (almost no
  resistance), and **water** and **lava** as penalty hazards.
- **The setting around the hole** — every hole stands on its own **paved apron**
  with a kerb (glowing in the neon world), the surrounding terrain rises into
  **waves**, scenery matching the world stands on the horizon (wooded hills,
  mesas, a temple pyramid, snowy peaks, skyscrapers, smoking volcanoes, factory
  chimneys, a lighthouse, a ringed gas giant) and **weather** moves through the
  air: pollen, sand on the gust, fireflies, snow, sparks, embers, steam, rain and
  dust in vacuum.
- **A bonus star on every hole** — hidden off the main line, collected by rolling
  the ball through it and credited once the hole is finished (108 in total).
- **Practice:** every world opens into a grid of holes you can play one at
  a time, without lives, with a personal best and stars (1–3 against par) per
  hole.
- **Daily Challenge** — one hole a day, the same for everyone, drawn from all
  nine worlds (the locked ones included, so it doubles as a taste of what is
  ahead). It keeps a **daily streak**, awards a medal against par and can be
  replayed.
- **Clubhouse** — 14 unlockable balls (colour, metal, glow and trail colour),
  career statistics and **18 trophies** with running progress.
- **Slingshot controls:** drag your finger away from the target, drag length =
  power, release = putt. Pinch to zoom the camera. The camera follows the ball
  smoothly and every hole opens with a fly-over.
- **Aim line** — a dotted prediction of the path, bank shots off the rails
  included; when the shot would drop, the line turns gold and the phone clicks.
  Switchable in settings (off / short / full).
- **Real minigolf rules:** the stroke limit is par + 3; water, lava or out of
  bounds costs +1 stroke and puts the ball back. Running out of strokes costs
  a life (♥×4 per course). Out of lives is **Game Over** (with the option to go
  and practise the hole), a finished course is **Success** with a scorecard,
  stars and a personal best.
- **Golf scoring:** Hole-in-one, Eagle, Birdie, Par, Bogey… Once all 108 holes
  are done, an **overall golf rating** appears (from Weekend Golfer to Golf
  Legend).
- Persistent progress (UserDefaults), sound effects, music, haptics, confetti on
  a sunk putt, a trail behind the rolling ball, localised in
  **Czech + English**.

## Code layout

```
Minigolf/
├── MinigolfApp.swift            entry point
├── ContentView.swift            root screen switcher
├── Models/
│   ├── CourseType.swift         9 worlds + unlock order (no UIKit)
│   ├── CourseTheme.swift        9 visual themes (colours, lights)
│   ├── LevelDefinition.swift    a hole described as data (floors, walls, obstacles)
│   ├── LevelLibrary.swift       index over the worlds
│   ├── Levels/*.swift           the 108 hand-designed holes (1 file = 1 world)
│   ├── Scoring.swift            golf ratings, stars per hole and per course
│   ├── GameProgress.swift       persistent progress (hole records, bonuses)
│   ├── PlayerStats.swift        career numbers, daily streak, unlocked rewards
│   ├── Achievements.swift       18 trophies with a progress measure
│   ├── BallSkin.swift           14 balls + the conditions that unlock them
│   └── DailyChallenge.swift     deterministic pick of the hole of the day
├── Game/
│   ├── GameController.swift     the game state machine (lives, score, practice,
│   │                            daily challenge, statistics, trophies)
│   ├── GameSceneCoordinator.swift  the live scene: aiming, physics, camera, cup,
│   │                               surfaces, force fields, portals, loops, cannons
│   ├── SceneBuilder.swift       builds the RealityKit scene from a level
│   ├── Scenery.swift            everything outside the green: sky, waved terrain,
│   │                            the paved apron, horizon and airborne weather
│   ├── Obstacles.swift          obstacle builders + kinematic animation
│   ├── Primitives.swift         shared scenery meshes (one shape, scaled)
│   ├── Critters.swift           world critters: models + walking the green
│   ├── AimGuide.swift           putt path prediction from static geometry
│   ├── AimGuideRenderer.swift   the dotted line + impact marker
│   ├── BallTrail.swift          the fading trail behind the ball
│   ├── GameSettings.swift       aim line and trail (user options)
│   ├── TextureFactory.swift     procedural textures (stripes, sand, ice, grid)
│   ├── SoundManager.swift       AVAudioPlayer effects + music
│   └── Haptics.swift
├── Views/                       menu, course select, hole select, HUD, overlays
└── Resources/
    ├── Sounds/*.wav             generated sounds (see below)
    ├── Localizable.xcstrings    en + cs
    └── PrivacyInfo.xcprivacy    privacy manifest (UserDefaults CA92.1)

MinigolfTests/                   unit tests over the pure logic (see below)
```

## Build & run

Open `Minigolf.xcodeproj` in Xcode 26+ and run it on an iPhone/iPad (iOS 18.0+),
or from the terminal:

```bash
xcodebuild -project Minigolf.xcodeproj -scheme Minigolf \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

The deployment target is 18.0 because that is exactly where the floor lies:
`RealityViewCameraContent`, `EventSubscription` and
`MeshResource.generateCone`/`generateCylinder` are iOS 18 APIs. A higher number
would only cut away devices the game runs on.

The language mode is **Swift 6** with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`:
the game is overwhelmingly main-actor code and it is right for the compiler to
assume so. There are three exceptions and all of them are audio — `SoundManager`,
`MusicPlayer` and the data enums they reach for. Those are `nonisolated` and
`@unchecked Sendable`, because what protects them is not an actor but a serial
queue: running them on the main thread is precisely what the whole design avoids.
Under Swift 5 the contradiction never showed anywhere; Swift 6 checks it at
runtime, and `preload()` called from the queue crashed on it.

### Debug arguments (DEBUG builds only)

For quickly testing particular holes and screens:

- `-autostart <garden|desert|jungle|ice|neon|volcano|clockwork|storm|cosmos> <1–12>` —
  jumps straight into the hole
- `-autoshot` — a bot putts towards the cup by itself
- `-autowin` — sinks the ball immediately (tests the overlays, walks a whole world)
- `-autoadvance` — moves on to the next hole automatically
- `-courseselect` / `-holeselect <course>` / `-clubhouse` — opens that screen
- `-daily` — starts today's Daily Challenge
- `-unlockall` — fills in progress temporarily (in memory only) for menu screenshots
- `-finalrating` — shows the overall rating screen
- `-aimdemo [0–1]` — holds the aim on the cup so the aim line can be photographed
- `-zoom <0.7–1.8>` — pins the camera zoom (multiplies the hole's `cameraZoom`)
  so the whole course fits into the screenshot
- `-calibrate <0–1>` — putts every shot at the given power and prints how far the
  ball actually rolled; the aim line length in `AimGuideLevel.length(power:)` is
  set from it

### Tests

```bash
xcodebuild test -project Minigolf.xcodeproj -scheme Minigolf \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`MinigolfTests/` covers what can break quietly with nobody noticing: the golf
thresholds (`Scoring`), streaks and daily history (`PlayerStats`), world
unlocking and hole records (`GameProgress`), the determinism of the Daily
Challenge (`DailyChallenge`), whether every trophy and ball is reachable at all,
and the **aim line** (`AimGuide`) — where it stops, how it bounces, when it turns
gold and everything it ignores on purpose. They are pure values — nothing touches
`UserDefaults` or RealityKit, so the suite finishes in under a second. The physics
itself has no tests: it runs inside RealityKit's solver and makes no sense outside
it. It is checked by `validate_levels` below (geometry) and by playing (behaviour).

### Checking the holes

The geometry of all 108 holes can be checked offline — the level data is plain
Foundation + simd, so it compiles for macOS too:

```bash
swiftc -O -o /tmp/validate Tools/validate_levels.swift Tools/LevelGeometry.swift \
    Minigolf/Support/MathHelpers.swift Minigolf/Models/CourseType.swift \
    Minigolf/Models/LevelDefinition.swift Minigolf/Models/LevelLibrary.swift \
    Minigolf/Models/Levels/*.swift && /tmp/validate
```

It reports a cup inside a rail, a green with an open edge, a surface not connected
to the tee, an obstacle off the course, an unreachable bonus star, a ramp with no
green to land on, a jump ramp pointing into nothing and the like. Finally it walks
the playable surface cell by cell (2 cm), rails, posts and solid blocks included,
and proves the ball really does roll from the tee to the cup and to the bonus star
— which also uncovers pockets sealed off by boards inside a single green.

### Hole plans and travel

The shape of the holes can be inspected without launching the game —
`Tools/map_levels.swift` draws every hole from above as an ASCII map (5 cm per
character) and prints a table:

```bash
swiftc -O -o /tmp/maps Tools/map_levels.swift Tools/LevelGeometry.swift \
    Minigolf/Support/MathHelpers.swift Minigolf/Models/CourseType.swift \
    Minigolf/Models/LevelDefinition.swift Minigolf/Models/LevelLibrary.swift \
    Minigolf/Models/Levels/*.swift && /tmp/maps garden      # one world
/tmp/maps stats                                             # the table only
```

The `travel` column is the shortest roll from the tee to the cup (Dijkstra over
3 cm cells around rails, posts and blocks, with ramps, portals, jump ramps and
cannons as shortcuts) and `m/par` is that same distance per par stroke — that is
the difficulty curve. The `fill` column is the ratio of playable area to its
bounding rectangle: 1.00 means a bare rectangle, and the lower it goes the more
worked the plan. The mean across all 108 holes is 0.71 — six are rectangular and
all of them deliberately (there the obstacles come from a wall inside the area,
not from its outline).

The geometry both tools share — what is solid and how far the ball rolls from
where to where — lives in `Tools/LevelGeometry.swift`, so that `validate_levels`
and `map_levels` cannot drift apart on a hole.

### Localisation

During a build Xcode writes the extracted keys into `*.stringsdata`. The script
compares them with the catalog, adds what is missing (the Czech translation
included) and deletes what nothing uses any more:

```bash
python3 Tools/sync_strings.py <path to derivedDataPath>
```

## App Store checklist

Done in the project:

- [x] 1024×1024 icon (single-size, `AppIcon.appiconset`)
- [x] `ITSAppUsesNonExemptEncryption = NO` (no export compliance questions)
- [x] `PrivacyInfo.xcprivacy` — no data collection, UserDefaults declared (CA92.1)
- [x] Category `public.app-category.sports-games`
- [x] Localised en + cs, no unused permissions (camera removed)
- [x] iPhone and iPad support, portrait and landscape
- [x] Accessibility — VoiceOver labels on icon-only buttons, star rows, lives
      and number chips; Dynamic Type through `scaledFont` (capped at
      `.accessibility1` in the HUD so the text does not cover the course)
- [x] App Store texts (cs + en) in `AppStore/` — see [AppStore/README.md](AppStore/README.md)

Still to be done by hand in App Store Connect:

1. **Apple Developer account** — the project is set to team `K6GM85X5D7`, automatic signing.
2. Create the App ID / app record for `cz.rob.Minigolf`.
3. **Archive:** Xcode → Product → Archive → Distribute App → App Store Connect.
4. **Screenshots** (6.9" iPhone + 13" iPad) — the plan, the resolutions and the
   captions are in [AppStore/screenshots.md](AppStore/screenshots.md).
5. Texts: copy from `AppStore/cs/` and `AppStore/en-US/` into the matching fields.
6. Privacy in App Store Connect: "Data Not Collected" + a policy URL (the text is
   ready in `AppStore/privacy-policy/`, it only needs hosting).
7. Age rating: 4+.

## Design notes

- Physics: a RealityKit dynamic body (sphere r 3.4 cm, m 45 g), linear damping
  0.14, CCD on; sand = damping 3.2, mud 6.5, ice 0.02; the cup has a "magnet"
  that catches slow balls.
- Tilted greens, belts, magnets, turntables and wind are not real geometry: they
  are force fields pushing on a rolling ball. They only push while it moves —
  a ball standing on a belt would never settle, and the stroke limit is evaluated
  only at rest. The magnet attracts or repels with a force that fades towards the
  edge, and the wind pulses sinusoidally — the blades turn on exactly that curve,
  so what the player sees is what the ball feels. Wind is the only one that also
  acts on a ball in the air.
- **The loop** is not left to the solver: a 3 cm ball at putting speed would
  either catch on a seam between track segments and fire off into the sky, or
  glue itself to the felt. So the ball goes round the circle by hand, on the
  energy budget of a rolling sphere (along the track only 5/7 of gravity brakes
  it). Without the speed it climbs part way and rolls back down; short by
  a little and it loses contact with the track near the top and drops inside the
  circle. The camera stays down at felt level throughout.
- **The turntable** has two contact modes and they do not add up:
  - *rolling* (a fast ball) **curves** the path — the acceleration is `ω × v`,
    perpendicular to the direction of travel, and the turn radius works out at
    `|v| / (0.9·ω)`. Pushing the ball along at the surface speed is the obvious
    thing to do, but it does not work: ahead of the hub the surface runs one way
    and behind it the other, so the two shoves cancel and all that is left is
    braking.
  - *slipping* (a ball slower than 0.18 m/s) is not about force at all any more:
    the table takes the ball over and **carries** it out along a spiral until it
    lets go at the rim, with whatever speed the ride gave it. The same principle
    as the loop and the cannon.
  The two cannot be mixed: on a ball already going round with the table the
  curving term points straight at the hub (it is a centripetal force) and would
  slowly wind it into the middle.
- A ball that has **really stopped** is parked by the solver, and from that moment
  it ignores both `addForce` and `applyLinearImpulse` — which is why the force
  fields in the game only act while the ball is moving. Waking it with a fresh
  body on every detection of rest is not enough: the solver puts it back to sleep
  a moment later and the ball crawls across the turntable in half-second hops.
  Anything meant to move a stationary ball therefore has to take it out of the
  solver entirely and steer it itself.
- **The jump ramp** gives the ball a fixed speed and a fixed lift however it
  arrived, so the jump is always the same length (≈ 2·speed·lift/g) and a chasm
  can be designed to the centimetre; a ball that is too slow simply rolls over
  the wedge. **The cannon** swallows the ball, spends a moment loading and fires
  it in a fixed direction regardless of where it came from.
- Portals shoot the ball out of the far ring with its speed preserved and then go
  "safe" until the ball has left both rings, so it cannot ping-pong.
- A ball that hops the rail or falls into water or lava is caught by a safety net
  (a check against the course plan plus height) → a penalty and a return to the
  spot of the last stroke.
- The aim line is computed purely geometrically from the **static** part of the
  level (rails, blocks, posts, bumpers, tunnels) and bounces with the same
  restitution as a real ball. Windmills, gates, rotors and pendulums are left out
  on purpose — a line claiming where they will be a second from now would be
  lying, and the timing puzzles would lose their point.
- The daily hole is derived from the date alone (an FNV-1a hash of the day →
  SplitMix64), so it is the same on every device without any server, and never
  repeats two days running. That second part costs more work than it looks:
  comparing today's draw against yesterday's *draw* is not enough, because
  yesterday may itself have been redrawn, and then today falls back to what
  yesterday really produced. So the decision is made against what yesterday
  actually yielded — which means solving the day before that too. The chain is
  unwound four days back; going deeper would only matter if every day in between
  collided.
- The scene is rebuilt for every hole (`sceneToken`), so a restart is always
  clean. To keep that from stalling the picture it is built from shared parts:
  the scenery (hills, trees, chimneys, loop rails) has one mesh per shape and
  differs only in scale (`Prim`), materials are cached by colour, and a world's
  material set is kept from its first hole onwards. A hole then goes up in
  a fraction of the time it cost to generate a few hundred meshes and materials
  again.
- Every world has its own playlist (`Resources/Music/*.m4a`) and the menu has
  one of its own; `ContentView` picks the playlist from the game phase and the
  current world and `MusicPlayer` crossfades between them. A world is not one
  loop but three or four whole tracks — played one at a time, shuffled, the next
  starting before the previous has finished, because a single loop is heard six
  times while somebody lines up one putt and stops being music. Two
  `AVAudioPlayerNode`s fed a decoded PCM buffer do the crossfade:
  `AVAudioPlayer` cannot overlap two tracks, and with AAC it would leave an
  audible hole at every join, because the encoder's priming and padding frames
  count into it.
- The assets can be regenerated with the scripts in `Tools/`:
  `python3 Tools/gen_sounds.py` (sound effects, plain sine synthesis),
  `python3 Tools/import_music.py` (music — nothing is synthesised: downloaded
  CC0/CC-BY tracks are cut to length, matched in loudness, encoded to AAC through
  `afconvert` according to `Tools/music_sources.json`, and the attribution the
  game shows in Settings is rewritten from the same manifest),
  `swift Tools/gen_icon.swift <path to PNG>` (the app icon),
  `Tools/appstore_media.sh` (screenshots and App Preview into `AppStore/`, played
  by the game itself in the simulator through the DEBUG flags) and
  `Tools/appstore_captions.sh` (the captioned variant of the screenshots) — see
  `AppStore/screenshots.md`.

## Licence

The code is MIT — see `LICENSE`.

The soundtrack is not. The 32 tracks under `Minigolf/Resources/Music/` were
written by other people and came in under CC0 or CC-BY 3.0; they are only
redistributed here, so they keep their own licence and MIT has nothing to say
about them. Sixteen of them are CC-BY, which asks for the title, the author and
a link wherever the work goes — the game carries that in Settings → Music
Credits, generated from `Tools/music_sources.json` alongside
`Minigolf/Resources/Music/CREDITS.md`. Anyone reusing this code with the audio
in place inherits that obligation; anyone swapping the audio out is free of it.
