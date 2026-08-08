//
//  Spectators.swift
//  Minigolf
//
//  The gallery: the people who came to watch. A couple leaning in at the
//  boards, a family with children, somebody filming, a bench of onlookers, and
//  the group beside the tee waiting for the hole to come free.
//
//  They stand on the terrain outside the course and carry no collider, so
//  nothing here can ever touch the ball — the critters are the characters that
//  take part in a hole, and these are deliberately not them. What they do is
//  answer a question the scenery cannot: a hole dressed in trees and hills is a
//  landscape, and a hole with somebody standing beside it is a place where a
//  game is being played.
//
//  A figure is modelled once at a nominal height of one and scaled to the size
//  it actually stands, so every world's whole cast shares four meshes and the
//  handful of materials in its `Kit`. Placement runs off the hole's own
//  `SplitMix64` seed the way the decorations do, and the motion is a pure
//  function of the level clock like everything else that moves — apart from one
//  event, the ball dropping, which is the only state a spectator keeps.
//

import Foundation
import RealityKit
import UIKit
import simd

// MARK: - Runtime

/// One member of the gallery, walked by the coordinator every frame.
final class Spectator {

    enum Pose {
        case standing
        case seated
        /// Four legs and a tail: the dog somebody brought along.
        case pet
    }

    /// Placed and turned to face the course once, then left alone. Its scale is
    /// the figure's height, which is what lets everything underneath be
    /// modelled at a nominal height of one.
    let root = Entity()

    /// Everything above the ground: what rocks, sways and hops. Kept one level
    /// in from `root` so the bounce never disturbs where the figure stands.
    let body = Entity()

    private let pose: Pose
    private let phase: Float
    private let tempo: Float
    /// How large the motion is. Children fidget; grown-ups mostly stand still.
    private let zeal: Float

    private var head: Entity?
    private var tail: Entity?
    private var arms: [Arm] = []

    /// Seconds of applause still to come. The one thing about a spectator that
    /// is not a function of the clock: a putt going in is an event, and the
    /// crowd has to answer it.
    private var applause: Float = 0

    private struct Arm {
        var pivot: Entity
        /// How the arm hangs, and where it goes when the ball drops. Held as
        /// poses rather than angles because an arm may be doing something else
        /// entirely — holding a putter, or a phone up to somebody's face — and
        /// those arms cheer by not moving.
        var rest: simd_quatf
        var raised: simd_quatf
        /// An arm with its hands full does not wave.
        var free: Bool
    }

    init(pose: Pose, height: Float, phase: Float, tempo: Float, zeal: Float) {
        self.pose = pose
        self.phase = phase
        self.tempo = tempo
        self.zeal = zeal
        root.name = "spectator"
        root.scale = SIMD3(repeating: height)
        root.addChild(body)
    }

    func attachHead(_ entity: Entity) {
        head = entity
        body.addChild(entity)
    }

    func attachArm(_ pivot: Entity, rest: simd_quatf, raised: simd_quatf, free: Bool = true) {
        pivot.orientation = rest
        arms.append(Arm(pivot: pivot, rest: rest, raised: raised, free: free))
        body.addChild(pivot)
    }

    func attachTail(_ pivot: Entity) {
        tail = pivot
        body.addChild(pivot)
    }

    /// The ball went in. Everyone in sight of it has about a second and a half
    /// of noise in them, started a hair apart so the gallery reads as a crowd
    /// rather than as one animation played on a dozen models.
    func celebrate() {
        applause = 1.5 + phase * 0.06
    }

    func update(time: Float, dt: Float) {
        applause = max(0, applause - dt)
        let t = time * tempo + phase

        // Nought is standing about, one is arms in the air. Two things feed it:
        // the burst everybody has now and then off their own clock — somebody
        // on a course is always applauding somebody — and whatever the last
        // putt to drop left behind. The sine spends about a sixth of its cycle
        // over the threshold, so a burst is a couple of seconds in every twenty.
        let spontaneous = smoothstep((sin(t * 0.34) - 0.80) / 0.20)
        let cheer = max(spontaneous, min(1, applause * 2.5))

        switch pose {
        case .pet:
            body.position.y = abs(sin(t * 2.3)) * 0.02 * (1 + cheer)
            head?.orientation = simd_quatf(angle: sin(t * 0.8) * 0.3, axis: SIMD3(0, 1, 0))
            // A dog that has caught the mood wags harder and faster. At this
            // size the tail is the only part of it anyone reads.
            tail?.orientation = simd_quatf(
                angle: sin(time * (7 + 6 * cheer) + phase) * (0.35 + 0.4 * cheer),
                axis: SIMD3(0, 1, 0))

        case .standing, .seated:
            // Weight shifting from one foot to the other, and a hop for as long
            // as the cheering lasts. A seated spectator claps without leaving
            // the bench.
            let hop = pose == .seated ? 0 : max(0, sin(time * 8.4 + phase)) * 0.06 * cheer
            body.position.y = hop + sin(t * 1.7) * 0.005 * zeal
            let sway = sin(t * 1.05)
            body.orientation = simd_quatf(angle: sway * 0.045 * zeal, axis: SIMD3(0, 0, 1))
            // Looking about, and up when there is something to look up at.
            head?.orientation = simd_quatf(angle: sin(t * 0.61) * 0.3, axis: SIMD3(0, 1, 0)) *
                                simd_quatf(angle: -0.3 * cheer, axis: SIMD3(1, 0, 0))
            for arm in arms {
                var swing = simd_slerp(arm.rest, arm.raised, cheer)
                if arm.free {
                    swing = swing * simd_quatf(
                        angle: sway * 0.05 * zeal + sin(time * 11 + phase) * 0.22 * cheer,
                        axis: SIMD3(0, 0, 1))
                }
                arm.pivot.orientation = swing
            }
        }
    }
}

// MARK: - Builder

enum Spectators {

    /// How far out from the boards the gallery stands.
    ///
    /// Both ends are set by the camera rather than by the ground. It sits a
    /// metre over the felt looking down a lane that is most of what it can see,
    /// so anybody closer than the near edge is somebody the player putts past
    /// rather than looks at, and anybody past the far edge is off the side of a
    /// portrait screen for the whole hole.
    private static let ring: ClosedRange<Float> = 0.85...1.70

    /// Ground a group may not stand on: the course, its paving, and a margin.
    private static let clearance = Scenery.apronWidth + 0.35

    /// A figure this close to the boards keeps its shadow and its eyes. Further
    /// out the eyes are under a pixel and the shadow falls on terrain nobody is
    /// looking at, which is exactly the bargain the outer decorations make.
    private static let detailRange: Float = 2.2

    /// Builds the gallery and hands back where everybody ended up, so the
    /// decorations planted afterwards do not put a fir tree through somebody.
    ///
    /// Four groups: one waiting at the tee, one on a flank, and one either side
    /// of the green. That is eight or nine people — enough that a hole is never
    /// deserted, few enough that the crowd never becomes the thing the player is
    /// looking at, and about a millisecond of entity building per hole once the
    /// meshes and materials are warm.
    @discardableResult
    static func build(level: LevelDefinition, terrain: Scenery.Terrain, theme: CourseTheme,
                      into root: Entity, spectators: inout [Spectator]) -> [SIMD2<Float>] {
        var rng = SplitMix64(seed: UInt64(level.course.order * 977 + level.number * 43 + 11))
        let kit = kit(for: level.course, theme: theme)
        let bounds = level.bounds
        let lane = laneAxis(of: level)
        let across = SIMD2(lane.y, -lane.x)
        var taken: [SIMD2<Float>] = []

        // Everyone is strung along the two flanks of the lane rather than
        // scattered round the hole. A hole is a long thin thing seen end-on: the
        // ground beyond the far boards is a dozen pixels of skyline, while the
        // strip either side of the lane is what the player looks past on every
        // frame of every putt. A crowd spread evenly around the outside would
        // spend most of its life off screen.
        var side: Float = rng.chance(0.5) ? 1 : -1
        let length = max(0.8, simd_length(level.hole - level.tee))

        /// Puts a group down where it is asked to stand, or — if that is on the
        /// course itself, which anything taken off the line of play is — on the
        /// first clear ground sideways of it.
        func place(_ kind: Party, at anchor: SIMD2<Float>, facing: SIMD2<Float>? = nil) {
            var point = anchor
            if bounds.expanded(by: clearance).contains(anchor) {
                guard let edge = firstClear(from: anchor, along: across * side, bounds: bounds,
                                            rng: &rng) else { return }
                point = edge + across * side * (rng.float(in: ring) - clearance)
            }
            if blocksTheFlag(point, hole: level.hole, lane: lane) { return }
            if blocksTheCamera(point, tee: level.tee, lane: lane) { return }
            if taken.contains(where: { simd_distance($0, point) < 0.95 }) { return }
            // Turned toward the tee unless told otherwise. A gallery watches
            // whoever is playing, and whoever is playing is where the camera is
            // — so facing the player is also the only way anybody ever gets to
            // be seen from the front.
            taken += party(kind, at: point,
                           facing: facing ?? safeDirection(from: point, to: level.tee),
                           near: bounds.distance(to: point) < detailRange,
                           terrain: terrain, kit: kit, rng: &rng,
                           into: root, spectators: &spectators)
        }

        // The group waiting for the hole to come free belongs at the tee — that
        // is the whole point of it — off to the side of it rather than behind,
        // and a pace up the lane so it is in shot on the opening putt instead of
        // level with the camera.
        place(.queue, at: level.tee + lane * (0.18 * length))

        var pool = kit.pets ? Party.everyday : Party.everyday.filter { $0 != .walker }
        func next() -> Party { pool.remove(at: Int(rng.next() % UInt64(pool.count))) }

        // Two more along the flanks, swapping sides as they go so one side of a
        // hole is never the empty one, and weighted toward the green: a lane
        // seen end-on is a wedge, and the ground beside the far end of it is
        // the first ground outside the boards a portrait screen has room for.
        for stretch in Party.stretches where !pool.isEmpty {
            side = -side
            place(next(), at: level.tee + lane * ((stretch + rng.float(in: -0.08...0.08)) * length))
        }

        // And the best seats in the house: past the cup, one either side,
        // looking back down the lane the ball is coming up. This is the one
        // piece of ground the player is guaranteed to be looking at — it is
        // straight ahead for the whole hole — so these two are put on the line
        // of play rather than walked out to the fringe, far enough off it to
        // leave the pin its own sky and near enough to frame the green.
        for flank: Float in [-1, 1] where !pool.isEmpty {
            let stand = level.hole + lane * rng.float(in: 1.4...2.4)
                                   + across * flank * rng.float(in: 0.75...1.20)
            place(next(), at: stand, facing: safeDirection(from: stand, to: level.hole))
        }
        return taken
    }

    /// Builds a world's gallery ahead of the hole that wants it: the four limb
    /// meshes every figure of every world shares, and the couple of dozen
    /// materials this one is dressed in.
    ///
    /// Worth doing for the same reason `Prim.prewarm` is. Cold, a gallery costs
    /// some 23 ms to assemble and warm it costs one — the difference is all
    /// mesh and material construction, which is a one-off the first hole of a
    /// session would otherwise pay in full, on the frame it opens.
    static func prewarm(course: CourseType) {
        let material = SceneBuilder.simpleMaterial(.white, roughness: 1)
        for size in [Limb.leg, Limb.thigh, Limb.arm, Limb.torso] {
            _ = Prim.roundedBox(width: size.x, height: size.y, depth: size.z,
                                cornerRadius: size.x * 0.45, material: material)
        }
        _ = kit(for: course, theme: course.theme)
    }

    // MARK: Placement helpers

    /// Which way the hole is played, for the corridor behind the cup and for the
    /// side the tee queue stands on.
    private static func laneAxis(of level: LevelDefinition) -> SIMD2<Float> {
        let delta = level.hole - level.tee
        return simd_length(delta) > 0.001 ? simd_normalize(delta) : SIMD2(0, -1)
    }

    private static func safeDirection(from: SIMD2<Float>, to: SIMD2<Float>) -> SIMD2<Float> {
        let delta = to - from
        return simd_length(delta) > 0.001 ? simd_normalize(delta) : SIMD2(0, -1)
    }

    /// The strip of ground directly behind the cup, which stays empty.
    ///
    /// The flag is the one landmark a player lines a putt up on, and from a
    /// camera down the lane it has to read against the sky or the terrain
    /// rather than against somebody's coat. Everyone is welcome to stand
    /// alongside the green end of the hole; nobody stands right behind the pin.
    private static func blocksTheFlag(_ point: SIMD2<Float>, hole: SIMD2<Float>,
                                      lane: SIMD2<Float>) -> Bool {
        let offset = point - hole
        let along = simd_dot(offset, lane)
        let sideways = abs(offset.x * lane.y - offset.y * lane.x)
        return along > -0.2 && along < 2.8 && sideways < 0.7
    }

    /// The strip behind the tee, which stays empty for a different reason.
    ///
    /// The chase camera is a fixed offset back from the ball, so the ground
    /// two or three metres behind a ball at the tee is not scenery — it is
    /// where the camera itself stands, and pulled all the way out it stands
    /// there looking straight through whatever is in the way. The group that is
    /// waiting to play still gets to wait at the tee; it waits off to the side.
    private static func blocksTheCamera(_ point: SIMD2<Float>, tee: SIMD2<Float>,
                                        lane: SIMD2<Float>) -> Bool {
        let offset = point - tee
        let along = simd_dot(offset, lane)
        let sideways = abs(offset.x * lane.y - offset.y * lane.x)
        return along < 0.2 && along > -3.4 && sideways < 0.9
    }

    /// The first spot along `direction` that is clear of the course and its
    /// paving: walks a group out sideways off the line of play, however wide
    /// the hole happens to be where it started.
    private static func firstClear(from origin: SIMD2<Float>, along direction: SIMD2<Float>,
                                   bounds: GroundRect, rng: inout SplitMix64) -> SIMD2<Float>? {
        let keepOut = bounds.expanded(by: clearance)
        var distance: Float = 0
        while distance < 8 {
            distance += 0.1
            let point = origin + direction * distance
            if !keepOut.contains(point) { return point }
        }
        return nil
    }

    // MARK: Groups

    private enum Party {
        case single
        case couple
        case family
        /// Waiting their turn, putters in hand.
        case queue
        case bench
        /// Somebody out with the dog.
        case walker

        /// What a hole draws from, weighted by repeating the kinds that carry
        /// the place best: a course is mostly families and couples.
        static let everyday: [Party] = [.family, .couple, .single, .family, .bench, .walker]

        /// Where along the line of play the flanking group stands, as a
        /// fraction of it.
        static let stretches: [Float] = [0.62]
    }

    private enum Role {
        case adult
        case kid
        /// Holds a putter, and cheers with the hand that is free.
        case player
        /// Filming the hole, and far too busy to clap.
        case photographer
        case seated
    }

    private static func party(_ kind: Party, at point: SIMD2<Float>, facing: SIMD2<Float>,
                              near: Bool, terrain: Scenery.Terrain, kit: Kit,
                              rng: inout SplitMix64, into root: Entity,
                              spectators: inout [Spectator]) -> [SIMD2<Float>] {
        let base = terrain.height(at: point)
        let group = Entity()
        group.name = "gallery"
        group.position = SIMD3(point.x, base, point.y)
        group.orientation = simd_quatf(angle: atan2(facing.x, facing.y) + rng.float(in: -0.2...0.2),
                                       axis: SIMD3(0, 1, 0))

        // Local X runs along the group's shoulders, local Z toward the course.
        let sideways = SIMD2(facing.y, -facing.x)
        var spots = [point]

        /// Where in the group somebody's feet go, sunk a whisker so the sole
        /// never shows daylight under it.
        ///
        /// Everyone is put on the ground under their own feet rather than on
        /// the group's: the swells are kept well clear of the course, but a
        /// group standing across the skirt of one is a metre wide on ground
        /// that is not level, and a single height for all of it is somebody
        /// buried to the knee at one end of the row and hovering at the other.
        func ground(x: Float, z: Float) -> SIMD3<Float> {
            SIMD3(x, terrain.height(at: point + sideways * x + facing * z) - base - 0.006, z)
        }

        /// `on` overrides the ground for somebody whose feet are not on it: a
        /// figure sitting on a bench takes its height from the bench rather
        /// than from the earth under that end of it.
        func stand(_ role: Role, x: Float, z: Float = 0, on seat: Float? = nil) {
            let figure = figure(role: role, kit: kit, detailed: near,
                                outward: x < 0 ? -1 : 1, rng: &rng)
            figure.root.position = SIMD3(x, seat ?? ground(x: x, z: z).y, z)
            figure.root.orientation = simd_quatf(angle: rng.float(in: -0.28...0.28),
                                                 axis: SIMD3(0, 1, 0))
            group.addChild(figure.root)
            spectators.append(figure)
            spots.append(point + sideways * x + facing * z)
        }

        switch kind {
        case .single:
            stand(rng.chance(0.4) ? .photographer : .adult, x: 0)

        case .couple:
            stand(.adult, x: -0.19, z: rng.float(in: -0.04...0.04))
            stand(.adult, x: 0.19, z: rng.float(in: -0.04...0.04))

        case .family:
            stand(.adult, x: -0.27)
            stand(.adult, x: 0.25, z: -0.05)
            stand(.kid, x: -0.02, z: 0.08)
            if rng.chance(0.55) {
                stand(.kid, x: 0.50, z: rng.float(in: 0...0.08))
            }

        case .queue:
            stand(.player, x: -0.22, z: rng.float(in: -0.05...0.05))
            stand(.player, x: 0.18, z: rng.float(in: -0.05...0.05))
            if rng.chance(0.5) { stand(.adult, x: 0.54, z: -0.06) }
            group.addChild(golfBag(at: ground(x: rng.chance(0.5) ? -0.52 : 0.72, z: -0.10),
                                   kit: kit))

        case .bench:
            // The bench stands as one piece, and the pair on it sit at the
            // height of the seat: two people each taking their own patch of
            // ground would be two people sitting through it.
            let seat = bench(kit: kit)
            seat.position = ground(x: 0, z: -0.02)
            group.addChild(seat)
            stand(.seated, x: -0.17, z: -0.02, on: seat.position.y)
            stand(.seated, x: 0.17, z: -0.02, on: seat.position.y)

        case .walker:
            stand(.adult, x: -0.12)
            let dog = dog(kit: kit, detailed: near, rng: &rng)
            dog.root.position = ground(x: 0.26, z: 0.10)
            dog.root.orientation = simd_quatf(angle: rng.float(in: -0.5...(-0.1)),
                                              axis: SIMD3(0, 1, 0))
            group.addChild(dog.root)
            spectators.append(dog)
        }

        // The near band keeps its shadows: a figure standing on the fringe is in
        // shot on every frame, and a contact shadow is what puts it on the
        // ground rather than over it. Further out the shadow falls behind the
        // player's line of sight and is a second draw of a dozen models for
        // nothing.
        if !near { SceneBuilder.castsNoShadow(group) }
        root.addChild(group)
        return spots
    }

    // MARK: A person

    /// The nominal figure, one unit tall. Legs to the hip at 0.40, torso to the
    /// shoulders at 0.74, head on top of that — about four and a half heads
    /// tall, which is the proportion that reads as a person at the size these
    /// are actually drawn rather than as a scaled-down mannequin.
    private enum Limb {
        static let leg = SIMD3<Float>(0.105, 0.40, 0.105)
        static let thigh = SIMD3<Float>(0.105, 0.21, 0.105)
        static let arm = SIMD3<Float>(0.085, 0.34, 0.085)
        static let torso = SIMD3<Float>(0.30, 0.38, 0.21)

        static let hip: Float = 0.38
        static let shoulder: Float = 0.69
        static let headY: Float = 0.855
        static let seat: Float = 0.2825
    }

    private static func limb(_ size: SIMD3<Float>, _ material: PhysicallyBasedMaterial)
    -> ModelEntity {
        Prim.roundedBox(width: size.x, height: size.y, depth: size.z,
                        cornerRadius: size.x * 0.45, material: material)
    }

    private static func figure(role: Role, kit: Kit, detailed: Bool, outward: Float,
                               rng: inout SplitMix64) -> Spectator {
        let child = role == .kid
        let seated = role == .seated
        // Deliberately under life size. A grown-up beside a real minigolf lane
        // stands twice as tall as the lane is wide, and at the distance this
        // camera plays from that is a coat filling a third of the screen. Two
        // thirds of that reads as a person and sits in the same size bracket as
        // the trees along the same fringe.
        let spectator = Spectator(
            pose: seated ? .seated : .standing,
            height: child ? rng.float(in: 0.40...0.48) : rng.float(in: 0.66...0.76),
            phase: rng.float(in: 0...(2 * .pi)),
            tempo: child ? rng.float(in: 1.3...1.7) : rng.float(in: 0.85...1.15),
            zeal: child ? 1.9 : rng.float(in: 0.7...1.2))
        let body = spectator.body

        let skin = pick(kit.skins, &rng)
        let top = pick(kit.tops, &rng)
        let bottom = pick(kit.bottoms, &rng)
        let hat = pick(kit.hats, &rng)

        // Legs. A seated figure folds them forward over the front of the bench,
        // which is the one place the knee has to exist.
        if seated {
            for side: Float in [-1, 1] {
                let hip = Entity()
                hip.position = SIMD3(side * 0.075, Limb.hip, 0)
                hip.orientation = simd_quatf(angle: -1.5, axis: SIMD3(1, 0, 0))
                let thigh = limb(Limb.thigh, bottom)
                thigh.position.y = -Limb.thigh.y / 2
                hip.addChild(thigh)
                let knee = Entity()
                knee.position.y = -Limb.thigh.y
                knee.orientation = simd_quatf(angle: 1.45, axis: SIMD3(1, 0, 0))
                let shin = limb(Limb.thigh, bottom)
                shin.position.y = -Limb.thigh.y / 2
                knee.addChild(shin)
                hip.addChild(knee)
                body.addChild(hip)
            }
        } else {
            for side: Float in [-1, 1] {
                let leg = limb(Limb.leg, bottom)
                leg.position = SIMD3(side * 0.075, Limb.leg.y / 2, 0)
                body.addChild(leg)
            }
        }

        let torso = limb(Limb.torso, top)
        torso.position.y = Limb.hip + Limb.torso.y / 2 - 0.02
        torso.scale = SIMD3(kit.bulk, 1, kit.bulk)
        body.addChild(torso)

        // The dark worlds hand out almost no light, so what makes a figure read
        // there is a strip of its own.
        if let glow = kit.glow {
            let strip = Prim.box(width: 0.19, height: 0.022, depth: 0.014, material: glow)
            strip.position = SIMD3(0, Limb.hip + 0.22, Limb.torso.z / 2 * kit.bulk)
            body.addChild(strip)
        }

        // Arms. Rotating a shoulder about Z swings the arm out and over: nought
        // hangs it straight down, and a couple of radians puts the hand in the
        // air on the same side it started.
        for side: Float in [-1, 1] {
            let pivot = Entity()
            pivot.position = SIMD3(side * 0.165 * kit.bulk, Limb.shoulder, 0)
            let arm = limb(Limb.arm, top)
            arm.position.y = -Limb.arm.y / 2
            arm.scale = SIMD3(kit.bulk, 1, kit.bulk)
            pivot.addChild(arm)
            if detailed {
                let hand = Prim.sphere(radius: 0.048, material: skin)
                hand.position.y = -Limb.arm.y - 0.01
                pivot.addChild(hand)
            }

            switch role {
            case .photographer:
                // Both hands up holding something worth pointing at the hole.
                let held = simd_quatf(angle: -1.5, axis: SIMD3(1, 0, 0)) *
                           simd_quatf(angle: side * 0.34, axis: SIMD3(0, 0, 1))
                spectator.attachArm(pivot, rest: held, raised: held, free: false)

            case .player where side == outward:
                // The club hand hangs still: a putter swung overhead on a hole
                // this crowded would go straight through the neighbour.
                let holding = simd_quatf(angle: side * 0.07, axis: SIMD3(0, 0, 1))
                addPutter(to: pivot, kit: kit)
                spectator.attachArm(pivot, rest: holding, raised: holding, free: false)

            case .seated:
                spectator.attachArm(pivot,
                                    rest: simd_quatf(angle: side * 0.22, axis: SIMD3(0, 0, 1)),
                                    raised: simd_quatf(angle: side * 1.7, axis: SIMD3(0, 0, 1)))

            default:
                spectator.attachArm(pivot,
                                    rest: simd_quatf(angle: side * 0.14, axis: SIMD3(0, 0, 1)),
                                    raised: simd_quatf(angle: side * 2.35, axis: SIMD3(0, 0, 1)))
            }
        }

        if role == .photographer {
            let phone = Prim.box(width: 0.10, height: 0.14, depth: 0.03, material: kit.gear)
            phone.position = SIMD3(0, Limb.shoulder - 0.02, 0.34)
            body.addChild(phone)
        }
        if child, rng.chance(0.5) {
            body.addChild(balloon(at: SIMD3(outward * 0.20, Limb.hip - 0.03, 0.02),
                                  tilt: outward * 0.3, kit: kit, rng: &rng))
        }

        // Head. Children get the same one a size up, which is the whole of the
        // difference between a small grown-up and a child.
        let head = Entity()
        head.position = SIMD3(0, Limb.headY, 0)
        head.scale = SIMD3(repeating: child ? 1.28 : 1)
        let skull = Prim.sphere(radius: 0.125, material: skin)
        skull.scale *= SIMD3(1, 1.05, 0.98)
        head.addChild(skull)
        // Eyes: the one thing that turns a lump of primitives into somebody, and
        // the first thing to go on a figure too far out to read them on.
        if detailed, hat != .visor {
            for side: Float in [-1, 1] {
                let eye = Prim.sphere(radius: 0.023, material: kit.eye)
                eye.position = SIMD3(side * 0.048, 0.02, 0.106)
                eye.scale *= SIMD3(0.9, 1.2, 0.6)
                head.addChild(eye)
            }
        }
        addHeadwear(hat, to: head, kit: kit, top: top, hair: pick(kit.hair, &rng))
        spectator.attachHead(head)

        return spectator
    }

    // MARK: Headwear

    /// What a world puts on its heads. Half of a figure's silhouette is here:
    /// the same body under a bobble hat, a top hat or a bubble helmet is three
    /// different people in three different places.
    private enum Hat {
        case bare
        case cap
        case sunhat
        case bobble
        case topHat
        case hood
        case hardHat
        /// Sealed bubble, for the world with no air in it.
        case helmet
        /// A band of light where the eyes would be.
        case visor
    }

    private static func addHeadwear(_ hat: Hat, to head: Entity, kit: Kit,
                                    top: PhysicallyBasedMaterial,
                                    hair: PhysicallyBasedMaterial) {
        /// A cap of hair over the crown and the back, cut away in front of the
        /// eyes. `under` flattens it to sit below a hat brim: a head of hair
        /// modelled to its full height comes out through the crown of anything
        /// worn over it, which on a top hat reads as a hole in the hat.
        func addHair(under brim: Bool = false) {
            let cap = Prim.sphere(radius: brim ? 0.128 : 0.132, material: hair)
            cap.scale *= SIMD3(1, brim ? 0.58 : 0.76, 1.02)
            cap.position = SIMD3(0, brim ? -0.01 : 0.035, -0.03)
            head.addChild(cap)
        }

        switch hat {
        case .bare:
            addHair()

        case .cap:
            addHair(under: true)
            let crown = Prim.cylinder(height: 0.07, radius: 0.128, material: top)
            crown.position.y = 0.085
            head.addChild(crown)
            let peak = Prim.box(width: 0.20, height: 0.022, depth: 0.12, material: top)
            peak.position = SIMD3(0, 0.055, 0.125)
            head.addChild(peak)

        case .sunhat:
            addHair(under: true)
            // Wide enough to shade somebody, narrow enough that seen from above
            // — which is most of the time — there is still a person under it.
            let brim = Prim.cylinder(height: 0.022, radius: 0.21, material: top)
            brim.position.y = 0.075
            head.addChild(brim)
            let crown = Prim.cylinder(height: 0.09, radius: 0.115, material: top)
            crown.position.y = 0.115
            head.addChild(crown)

        case .bobble:
            // Knitted, pulled down to the eyebrows, with the pompom that is the
            // whole reason anyone wears one.
            let brim = Prim.cylinder(height: 0.035, radius: 0.142, material: top)
            brim.position.y = 0.065
            head.addChild(brim)
            let knit = Prim.cylinder(height: 0.10, radius: 0.132, material: top)
            knit.position.y = 0.105
            head.addChild(knit)
            let pompom = Prim.sphere(radius: 0.045, material: hair)
            pompom.position.y = 0.17
            head.addChild(pompom)

        case .topHat:
            addHair(under: true)
            let brim = Prim.cylinder(height: 0.02, radius: 0.20, material: top)
            brim.position.y = 0.085
            head.addChild(brim)
            let stack = Prim.cylinder(height: 0.20, radius: 0.115, material: top)
            stack.position.y = 0.185
            head.addChild(stack)

        case .hood:
            let hood = Prim.sphere(radius: 0.155, material: top)
            hood.scale *= SIMD3(1.02, 1.02, 0.96)
            hood.position = SIMD3(0, 0.02, -0.05)
            head.addChild(hood)

        case .hardHat:
            let dome = Prim.sphere(radius: 0.135, material: top)
            dome.scale *= SIMD3(1, 0.7, 1)
            dome.position.y = 0.08
            head.addChild(dome)
            let brim = Prim.cylinder(height: 0.016, radius: 0.16, material: top)
            brim.position.y = 0.062
            head.addChild(brim)

        case .helmet:
            let collar = Prim.cylinder(height: 0.06, radius: 0.15, material: top)
            collar.position.y = -0.10
            head.addChild(collar)
            if let glass = kit.glass {
                let bubble = Prim.sphere(radius: 0.18, material: glass)
                bubble.position.y = 0.02
                head.addChild(bubble)
            }

        case .visor:
            addHair()
            if let glow = kit.glow {
                let band = Prim.box(width: 0.235, height: 0.05, depth: 0.03, material: glow)
                band.position = SIMD3(0, 0.022, 0.10)
                head.addChild(band)
            }
        }
    }

    // MARK: Props

    /// Hangs a putter off a hand, head down on the ground beside the figure.
    private static func addPutter(to hand: Entity, kit: Kit) {
        let shaft = Prim.cylinder(height: 0.36, radius: 0.010, material: kit.gear)
        shaft.position = SIMD3(0, -0.50, 0.025)
        hand.addChild(shaft)
        let head = Prim.box(width: 0.10, height: 0.035, depth: 0.05, material: kit.gear)
        head.position = SIMD3(0, -0.665, 0.05)
        hand.addChild(head)
    }

    private static func golfBag(at position: SIMD3<Float>, kit: Kit) -> Entity {
        let stand = Entity()
        stand.position = position
        stand.orientation = simd_quatf(angle: 0.22, axis: SIMD3(0, 0, 1))
        let bag = Prim.cylinder(height: 0.34, radius: 0.072, material: kit.wood)
        bag.position.y = 0.17
        stand.addChild(bag)
        for i in 0..<3 {
            let club = Prim.cylinder(height: 0.22, radius: 0.008, material: kit.gear)
            club.position = SIMD3(Float(i - 1) * 0.028, 0.44, Float(i % 2) * 0.02 - 0.01)
            stand.addChild(club)
        }
        return stand
    }

    private static func bench(kit: Kit) -> Entity {
        let bench = Entity()
        let seat = Prim.box(width: 0.68, height: 0.045, depth: 0.24, material: kit.wood)
        seat.position = SIMD3(0, Limb.seat - 0.022, 0)
        bench.addChild(seat)
        let back = Prim.box(width: 0.68, height: 0.20, depth: 0.04, material: kit.wood)
        back.position = SIMD3(0, Limb.seat + 0.13, -0.10)
        bench.addChild(back)
        for side: Float in [-1, 1] {
            for front: Float in [-1, 1] {
                let leg = Prim.box(width: 0.045, height: Limb.seat - 0.045,
                                   depth: 0.045, material: kit.wood)
                leg.position = SIMD3(side * 0.30, (Limb.seat - 0.045) / 2, front * 0.09)
                bench.addChild(leg)
            }
        }
        return bench
    }

    /// String and balloon, hung off the body rather than off the hand: a child
    /// cheering swings an arm through most of a right angle, and a balloon on
    /// the end of it would sweep through whoever is standing alongside.
    private static func balloon(at position: SIMD3<Float>, tilt: Float, kit: Kit,
                                rng: inout SplitMix64) -> Entity {
        let group = Entity()
        group.position = position
        group.orientation = simd_quatf(angle: tilt, axis: SIMD3(0, 0, 1))
        let string = Prim.cylinder(height: 0.42, radius: 0.004, material: kit.eye)
        string.position.y = 0.21
        group.addChild(string)
        let skin = pick(kit.balloons, &rng)
        let bulb = Prim.sphere(radius: 0.075, material: skin)
        bulb.scale *= SIMD3(1, 1.15, 1)
        bulb.position.y = 0.49
        group.addChild(bulb)
        return group
    }

    /// The dog. Built at its real size rather than at a nominal one — it is the
    /// only member of the cast that is never scaled.
    private static func dog(kit: Kit, detailed: Bool, rng: inout SplitMix64) -> Spectator {
        let dog = Spectator(pose: .pet, height: 1, phase: rng.float(in: 0...(2 * .pi)),
                            tempo: rng.float(in: 1.1...1.5), zeal: 1)
        let coat = pick(kit.hair, &rng)
        let body = dog.body

        let trunk = Prim.sphere(radius: 0.072, material: coat)
        trunk.scale *= SIMD3(1, 0.85, 1.5)
        trunk.position.y = 0.135
        body.addChild(trunk)
        for side: Float in [-1, 1] {
            for front: Float in [-1, 1] {
                let leg = Prim.cylinder(height: 0.10, radius: 0.017, material: coat)
                leg.position = SIMD3(side * 0.042, 0.05, front * 0.06)
                body.addChild(leg)
            }
        }

        let head = Entity()
        head.position = SIMD3(0, 0.195, 0.10)
        let skull = Prim.sphere(radius: 0.052, material: coat)
        head.addChild(skull)
        let snout = Prim.sphere(radius: 0.028, material: coat)
        snout.scale *= SIMD3(0.9, 0.8, 1.4)
        snout.position = SIMD3(0, -0.012, 0.05)
        head.addChild(snout)
        for side: Float in [-1, 1] {
            let ear = Prim.sphere(radius: 0.022, material: coat)
            ear.scale *= SIMD3(0.5, 1.3, 0.9)
            ear.position = SIMD3(side * 0.04, 0.032, -0.008)
            head.addChild(ear)
            if detailed {
                let eye = Prim.sphere(radius: 0.010, material: kit.eye)
                eye.position = SIMD3(side * 0.024, 0.012, 0.04)
                head.addChild(eye)
            }
        }
        dog.attachHead(head)

        let tail = Entity()
        tail.position = SIMD3(0, 0.16, -0.09)
        let brush = Prim.cylinder(height: 0.09, radius: 0.011, material: coat)
        brush.position = SIMD3(0, 0.03, -0.02)
        brush.orientation = simd_quatf(angle: 0.5, axis: SIMD3(1, 0, 0))
        tail.addChild(brush)
        dog.attachTail(tail)

        return dog
    }

    // MARK: Wardrobe

    /// Everything a world's gallery is painted out of, built once per hole.
    ///
    /// Materials, not colours: a `PhysicallyBasedMaterial` is the dearest thing
    /// about a prop after its mesh, and a dozen figures asking for their own
    /// would cost more than the models they hang on. These come from the shared
    /// cache, so the second hole of a world pays nothing at all.
    private struct Kit {
        var skins: [PhysicallyBasedMaterial]
        var hair: [PhysicallyBasedMaterial]
        var tops: [PhysicallyBasedMaterial]
        var bottoms: [PhysicallyBasedMaterial]
        var balloons: [PhysicallyBasedMaterial]
        var hats: [Hat]
        var eye: PhysicallyBasedMaterial
        /// Putters, clubs, the phone: one machined grey for all of it.
        var gear: PhysicallyBasedMaterial
        /// Bench and bag, in whatever the world builds its boards out of.
        var wood: PhysicallyBasedMaterial
        var glow: UnlitMaterial?
        var glass: PhysicallyBasedMaterial?
        /// How much a coat fills out a figure.
        var bulk: Float = 1
        /// Whether anyone would bring a dog here.
        var pets: Bool = true
    }

    private static func pick<T>(_ items: [T], _ rng: inout SplitMix64) -> T {
        items[Int(rng.next() % UInt64(items.count))]
    }

    private static func shade(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat,
                              _ roughness: Float = 0.9) -> PhysicallyBasedMaterial {
        SceneBuilder.simpleMaterial(UIColor(red: red, green: green, blue: blue, alpha: 1),
                                    roughness: roughness)
    }

    private static func kit(for course: CourseType, theme: CourseTheme) -> Kit {
        // One set of faces for every world: the crowd changes what it is wearing
        // from place to place, not who it is.
        let skins = [
            shade(0.96, 0.80, 0.66, 0.75), shade(0.86, 0.66, 0.50, 0.75),
            shade(0.70, 0.50, 0.36, 0.75), shade(0.48, 0.33, 0.23, 0.75),
            shade(0.33, 0.22, 0.16, 0.75),
        ]
        let hair = [
            shade(0.10, 0.08, 0.07), shade(0.28, 0.18, 0.10), shade(0.56, 0.43, 0.20),
            shade(0.45, 0.22, 0.12), shade(0.74, 0.73, 0.70),
        ]
        let balloons = [
            shade(0.92, 0.24, 0.26, 0.5), shade(0.97, 0.78, 0.20, 0.5),
            shade(0.30, 0.58, 0.92, 0.5), shade(0.55, 0.35, 0.80, 0.5),
        ]
        let eye = shade(0.06, 0.06, 0.07, 0.3)
        let gear = SceneBuilder.simpleMaterial(UIColor(white: 0.68, alpha: 1),
                                               roughness: 0.35, metallic: 0.7)
        let wood = SceneBuilder.simpleMaterial(theme.wallColor.darkened(by: 0.1), roughness: 0.9)

        var kit = Kit(skins: skins, hair: hair, tops: [], bottoms: [], balloons: balloons,
                      hats: [.bare], eye: eye, gear: gear, wood: wood, glow: nil, glass: nil)

        switch course {
        case .garden:
            // A summer afternoon: shirt sleeves and sun hats.
            kit.tops = [shade(0.86, 0.28, 0.24), shade(0.96, 0.78, 0.25),
                        shade(0.35, 0.62, 0.86), shade(0.93, 0.93, 0.90),
                        shade(0.45, 0.76, 0.58), shade(0.60, 0.36, 0.62)]
            kit.bottoms = [shade(0.28, 0.34, 0.50), shade(0.72, 0.66, 0.48),
                           shade(0.35, 0.35, 0.37), shade(0.42, 0.31, 0.22)]
            kit.hats = [.bare, .bare, .cap, .sunhat]

        case .desert:
            // Covered up against the sun, in everything the sand has bleached.
            kit.tops = [shade(0.90, 0.82, 0.62), shade(0.80, 0.42, 0.28),
                        shade(0.93, 0.91, 0.86), shade(0.25, 0.58, 0.56)]
            kit.bottoms = [shade(0.72, 0.62, 0.42), shade(0.55, 0.46, 0.32),
                           shade(0.40, 0.32, 0.24)]
            kit.hats = [.sunhat, .sunhat, .cap, .bare]

        case .jungle:
            kit.tops = [shade(0.45, 0.52, 0.30), shade(0.86, 0.83, 0.70),
                        shade(0.88, 0.55, 0.20), shade(0.62, 0.58, 0.40)]
            kit.bottoms = [shade(0.36, 0.38, 0.26), shade(0.50, 0.44, 0.30)]
            kit.hats = [.sunhat, .cap, .bare, .sunhat]

        case .ice:
            // Padded out, hoods down, one bright coat each so the crowd does not
            // disappear into the snow behind it.
            kit.tops = [shade(0.85, 0.24, 0.22), shade(0.22, 0.42, 0.78),
                        shade(0.52, 0.32, 0.68), shade(0.16, 0.60, 0.58),
                        shade(0.94, 0.94, 0.96)]
            kit.bottoms = [shade(0.20, 0.22, 0.30), shade(0.30, 0.30, 0.33),
                           shade(0.22, 0.30, 0.26)]
            kit.hats = [.bobble]
            kit.bulk = 1.18

        case .neon:
            // Almost no sun to be lit by, so everyone carries their own light.
            kit.tops = [shade(0.12, 0.10, 0.20, 0.6), shade(0.17, 0.12, 0.28, 0.6),
                        shade(0.20, 0.10, 0.24, 0.6)]
            kit.bottoms = [shade(0.08, 0.07, 0.14, 0.6), shade(0.11, 0.09, 0.18, 0.6)]
            kit.hats = [.visor, .visor, .bare]
            kit.glow = UnlitMaterial(color: theme.accent)

        case .volcano:
            // Nobody stands beside a lava field in a shirt: hard hats and the
            // high-visibility orange of somebody who works here.
            kit.tops = [shade(0.90, 0.50, 0.12), shade(0.76, 0.72, 0.20),
                        shade(0.38, 0.36, 0.36)]
            kit.bottoms = [shade(0.24, 0.22, 0.22), shade(0.30, 0.27, 0.25)]
            kit.hats = [.hardHat, .hardHat, .cap]
            kit.pets = false

        case .clockwork:
            // Sunday best, a century out of date.
            kit.tops = [shade(0.42, 0.24, 0.18), shade(0.22, 0.30, 0.24),
                        shade(0.20, 0.22, 0.34), shade(0.48, 0.40, 0.26)]
            kit.bottoms = [shade(0.22, 0.18, 0.15), shade(0.30, 0.26, 0.20)]
            kit.hats = [.topHat, .topHat, .cap, .bare]

        case .storm:
            // Hoods up, in the yellow that carries through rain.
            kit.tops = [shade(0.94, 0.76, 0.18), shade(0.18, 0.26, 0.42),
                        shade(0.36, 0.42, 0.30), shade(0.72, 0.22, 0.20)]
            kit.bottoms = [shade(0.22, 0.24, 0.28), shade(0.30, 0.32, 0.30)]
            kit.hats = [.hood, .hood, .cap]
            kit.bulk = 1.12

        case .cosmos:
            // Suited and sealed, with a bubble to breathe out of.
            kit.tops = [shade(0.92, 0.92, 0.94, 0.6), shade(0.80, 0.81, 0.84, 0.6)]
            kit.bottoms = [shade(0.86, 0.86, 0.89, 0.6), shade(0.74, 0.75, 0.79, 0.6)]
            kit.hats = [.helmet]
            kit.bulk = 1.16
            kit.pets = false
            kit.glow = UnlitMaterial(color: theme.accent)
            var glass = PhysicallyBasedMaterial()
            glass.baseColor = .init(tint: theme.wallTopColor)
            glass.roughness = 0.1
            glass.metallic = 0.2
            glass.blending = .transparent(opacity: 0.32)
            kit.glass = glass
        }
        return kit
    }
}
