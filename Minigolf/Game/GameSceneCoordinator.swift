//
//  GameSceneCoordinator.swift
//  Minigolf
//
//  Owns the live RealityKit scene for one hole: input (slingshot aiming),
//  ball physics bookkeeping, hole capture, hazards, obstacle animation and
//  the chase camera with its intro flyover.
//

import Foundation
import RealityKit
import SwiftUI
import UIKit
import simd

#if DEBUG
/// Reads the number following a debug launch flag, if there is one.
private func floatArgument(_ flag: String) -> Float? {
    let args = ProcessInfo.processInfo.arguments
    guard let index = args.firstIndex(of: flag), args.count > index + 1 else { return nil }
    return Float(args[index + 1])
}
#endif

@Observable
final class GameSceneCoordinator {

    enum State {
        case intro
        case waiting     // ball at rest, player may aim
        case aiming
        case ballMoving
        case sinking
    }

    let level: LevelDefinition
    private weak var controller: GameController?

    private(set) var state: State = .intro

    private var built: BuiltScene?
    private let camera = Entity()
    private var subscriptions: [EventSubscription] = []

    // Aiming
    private var aimDirection = SIMD3<Float>(0, 0, -1)
    private var aimPower: Float = 0
    private let arrowRoot = Entity()
    private let arrowShaft = ModelEntity()
    private let arrowHead = ModelEntity()
    private let aimRing = ModelEntity()
    private var arrowMaterials: [UnlitMaterial] = []
    private var arrowBucket = -1

    // Aim guide + roll trail
    private var guideGeometry = AimGuideGeometry()
    private var guideRenderer: AimGuideRenderer?
    private var trail: BallTrail?
    private let skin: BallSkin
    private let aimGuideLevel = GameSettings.shared.aimGuide
    private let trailEnabled = GameSettings.shared.ballTrail
    /// True while the current aim would drop the ball, so the "in the cup"
    /// tick only fires once per line.
    private var guideOnTarget = false

    // Motion tracking
    private var lastBallPosition = SIMD3<Float>(0, 0, 0)
    private var ballVelocity = SIMD3<Float>(0, 0, 0)
    private var previousBallVelocity = SIMD3<Float>(0, 0, 0)
    private var lastBounceTime: Float = -1
    private var restTimer: Float = 0
    private var motionTime: Float = 0
    /// Where the ball was when the zone under it last took stock, how long ago
    /// that was, and whether the zone has given up on shifting it — a belt
    /// running into a wall has to let the ball settle in the end.
    private var zoneAnchor: SIMD3<Float>?
    private var zoneStall: Float = 0
    private var zoneBlocked = false
    private var currentSpeed: Float = 0
    private var lastRestPosition = SIMD3<Float>(0, 0, 0)
    /// Damping currently written into the ball's body, so surface changes are
    /// only pushed when they actually change.
    private var appliedDamping = GamePhysics.ballLinearDamping
    private var lastBoostTime: Float = -1
    private var lastLaunchTime: Float = -1
    /// Speed a portal owes the ball, paid out on the frame after the jump.
    private var pendingWarpVelocity: SIMD3<Float>?

    // Obstacles that take the ball off the solver for a moment.
    private var loopRun: LoopRun?
    private var cannonRun: CannonRun?
    private var turntableRide: TurntableRide?
    /// Keeps a ball that has just been spat out from being swallowed again by
    /// the obstacle that let it go. Only that one is held off: a driver firing
    /// straight at a loop has to be able to hand the ball over at full speed,
    /// and half a metre of felt is covered long before a blanket wait is up.
    private var guidedCooldown: Float = 0
    /// Which obstacle the cooldown protects; nil holds off all of them.
    private var guidedCooldownSource: GuidedSource?

    /// One of the obstacles that drive the ball themselves, by index.
    private enum GuidedSource: Equatable {
        case loop(Int)
        case cannon(Int)
        case turntable(Int)
    }
    /// While this runs, a ball off the ground is airborne on purpose and the
    /// out-of-bounds net leaves it alone.
    private var flightGrace: Float = 0

    /// The ball's trip around a loop. It is integrated by hand along the track:
    /// speed is traded for height on the way up and handed back on the way
    /// down, so a putt that is short of the energy rolls back out of the
    /// entrance and one that is only just short drops off near the top — which
    /// is exactly what a loop is supposed to punish.
    private struct LoopRun {
        var index: Int
        /// Angle travelled from the entrance: 0 going in, 2π out the far end.
        var theta: Float
        /// Speed along the track; negative once the ball starts sliding back.
        var speed: Float
        /// Direction the ball entered in.
        var forward: SIMD3<Float>
        /// Attitude the ball came in with, and how far it has rolled since.
        var attitude: simd_quatf
        var rolled: Float = 0
    }

    /// The ball sitting in a cannon while it charges.
    private struct CannonRun {
        var index: Int
        var timer: Float
    }

    /// A ball riding a turning table around to its rim.
    private struct TurntableRide {
        var index: Int
        /// Where the ball sits around the hub, in radians.
        var angle: Float
        var radius: Float
        var time: Float
    }

    private let cannonCharge: Float = 0.55

    // Camera
    private var camPosition = SIMD3<Float>(0, 1.4, 1.4)
    private var camLookAt = SIMD3<Float>(0, 0, 0)
    private var pinchZoom: Float = 1
    private var pinchZoomAtStart: Float = 1
    private var aspectFactor: Float = 1
    private var introTime: Float = 0
    private let introDuration: Float = 1.9

    // Flyover: both ends are frozen when it starts, so nothing can move the
    // path while the camera is travelling along it.
    private var flyoverRunning = false
    private var flyoverStartPos = SIMD3<Float>(0, 1.4, 1.4)
    private var flyoverStartLook = SIMD3<Float>(0, 0, 0)
    private var flyoverEndPos = SIMD3<Float>(0, 1.4, 1.4)
    private var flyoverEndLook = SIMD3<Float>(0, 0, 0)
    private var warmupTime: Float = 0
    private var warmupOnTimeFrames = 0
    /// Longest frame the flyover steps over: a hitch may not teleport the camera.
    private let maxFlyoverStep: Float = 1.0 / 30
    /// Frame time that counts as the renderer having caught up.
    private let warmupFrameBudget: Float = 1.0 / 40
    private let warmupFramesNeeded = 3
    private let warmupTimeLimit: Float = 0.8

    private var elapsed: Float = 0
    private var lastBounceSound: Float = -1
    private var lastImpactHaptic: Float = -1
    /// Floor on the gap between impact haptics. Sound is posted to a background
    /// queue and can layer freely, but `impactOccurred` runs on the main thread
    /// in the middle of the frame, and the Taptic Engine cannot resolve taps this
    /// close together anyway.
    private let hapticInterval: Float = 0.09

    #if DEBUG
    private let autoshot = ProcessInfo.processInfo.arguments.contains("-autoshot")
    private let autowin = ProcessInfo.processInfo.arguments.contains("-autowin")
    /// `-aimdemo [0…1]`: holds a fixed aim at the hole so the guide can be
    /// inspected in a screenshot.
    private let aimdemo = ProcessInfo.processInfo.arguments.contains("-aimdemo")
    private let aimdemoPower = floatArgument("-aimdemo") ?? 0.62
    /// `-zoom <0.7…1.8>`: pins the chase camera at a fixed pinch zoom, so a
    /// screenshot can frame the whole hole instead of the default distance.
    private let zoomOverride = floatArgument("-zoom")
    private var autoshotTimer: Float = 0
    /// `-calibrate <0…1>`: fires every shot at this strength and logs how far
    /// the ball actually rolled, so the aim guide's length can be tuned.
    private let calibratePower = floatArgument("-calibrate")
    private var shotOrigin: SIMD3<Float>?
    #endif

    private let maxShotSpeed: Float = 4.4
    private let minShotSpeed: Float = 0.5

    init(level: LevelDefinition, controller: GameController) {
        self.level = level
        self.controller = controller
        self.skin = controller.selectedSkin
    }

    // MARK: - Scene construction

    /// `floorShapes` are the welded floor colliders, built off the main actor
    /// before the scene is assembled (see `SceneBuilder.floorShapes`).
    func build(content: inout RealityViewCameraContent,
               floorShapes: [Float: ShapeResource] = [:]) {
        content.camera = .virtual

        let built = SceneBuilder.build(level: level, skin: skin, floorShapes: floorShapes)
        self.built = built
        content.add(built.root)

        camera.components.set(PerspectiveCameraComponent(
            near: 0.02, far: 90, fieldOfViewInDegrees: 55))
        content.add(camera)

        #if DEBUG
        if let zoomOverride {
            pinchZoom = simd_clamp(zoomOverride, CameraRig.minPinch, CameraRig.maxPinch)
            pinchZoomAtStart = pinchZoom
        }
        #endif

        buildAimIndicator(into: built.root)

        if aimGuideLevel != .off {
            guideGeometry = AimGuideGeometry.build(level: level)
            let renderer = AimGuideRenderer()
            renderer.attach(to: built.root)
            guideRenderer = renderer
        }
        if trailEnabled {
            let trail = BallTrail(color: skin.trailColor)
            trail.attach(to: built.root)
            self.trail = trail
        }

        lastBallPosition = built.ball.position
        lastRestPosition = built.ball.position

        // Prime the camera on the intro start pose.
        (camPosition, camLookAt) = introStartPose()
        camera.look(at: camLookAt, from: camPosition, relativeTo: nil)

        state = .intro
        introTime = 0
        controller?.introRunning = true

        subscriptions.append(content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(dt: Float(event.deltaTime))
        })
        subscriptions.append(content.subscribe(to: CollisionEvents.Began.self, on: built.ball) { [weak self] event in
            self?.handleCollision(event)
        })
    }

    private func buildAimIndicator(into root: Entity) {
        // Gradient of unlit materials from calm green to hot red.
        arrowMaterials = (0..<6).map { i in
            let t = CGFloat(i) / 5
            let color = UIColor(
                red: 0.15 + t * 0.83,
                green: 0.82 - t * 0.6,
                blue: 0.25 - t * 0.15,
                alpha: 1)
            return UnlitMaterial(color: color)
        }

        arrowShaft.model = ModelComponent(
            mesh: .generateBox(width: 0.028, height: 0.006, depth: 1),
            materials: [arrowMaterials[0]])
        arrowHead.model = ModelComponent(
            mesh: .generateCone(height: 0.09, radius: 0.045),
            materials: [arrowMaterials[0]])
        arrowHead.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
        arrowRoot.addChild(arrowShaft)
        arrowRoot.addChild(arrowHead)
        arrowRoot.isEnabled = false
        root.addChild(arrowRoot)

        var ringMaterial = UnlitMaterial(color: .white)
        ringMaterial.blending = .transparent(opacity: 0.45)
        aimRing.model = ModelComponent(
            mesh: .generateCylinder(height: 0.0025, radius: 0.06),
            materials: [ringMaterial])
        aimRing.isEnabled = false
        root.addChild(aimRing)
    }

    // MARK: - Per-frame update

    private func tick(dt: Float) {
        guard dt > 0, let controller, let built else { return }
        if controller.isPaused { return }

        elapsed += dt
        for obstacle in built.animated {
            obstacle.update(time: elapsed)
        }
        for critter in built.critters {
            critter.update(time: elapsed, dt: dt)
        }

        let ball = built.ball
        let travelled = ball.position - lastBallPosition
        currentSpeed = simd_length(travelled) / dt
        previousBallVelocity = ballVelocity
        ballVelocity = travelled / dt
        lastBallPosition = ball.position

        // A ball going round a loop or sitting in a barrel leaves no roll trail.
        trail?.update(dt: dt, ballPosition: ball.position,
                      speed: state == .ballMoving && loopRun == nil && cannonRun == nil
                             ? currentSpeed : 0,
                      floorY: ball.position.y - GamePhysics.ballRadius)

        switch state {
        case .intro:
            if !flyoverRunning {
                guard rendererWarmedUp(dt: dt) else { return }
                beginFlyover()
            }
            introTime += min(dt, maxFlyoverStep)
            let t = smoothstep(introTime / introDuration)
            let mix = SIMD3(repeating: t)
            camPosition = simd_mix(flyoverStartPos, flyoverEndPos, mix)
            camLookAt = simd_mix(flyoverStartLook, flyoverEndLook, mix)
            camera.look(at: camLookAt, from: camPosition, relativeTo: nil)
            if introTime >= introDuration {
                finishIntro()
            }
            return

        case .waiting:
            aimRing.position = ball.position + SIMD3(0, -GamePhysics.ballRadius + 0.004, 0)
            let pulse = 1 + 0.14 * sin(elapsed * 4.2)
            aimRing.scale = SIMD3(pulse, 1, pulse)
            #if DEBUG
            if aimdemo {
                let toHole = built.holePosition - ball.position
                aimDirection = simd_normalize(SIMD3(toHole.x, 0, toHole.z))
                aimPower = aimdemoPower
                state = .aiming
                controller.setAim(power: aimPower, aiming: true)
                updateArrow(ball: ball)
                return
            }
            if autoshot || autowin, case .none = controller.overlay {
                autoshotTimer += dt
                if autoshotTimer > 1.6 {
                    autoshotTimer = 0
                    if autowin {
                        captureBall()
                    } else {
                        let toHole = built.holePosition - ball.position
                        aimDirection = simd_normalize(SIMD3(toHole.x, 0, toHole.z))
                        aimPower = calibratePower ?? 0.55
                        state = .aiming
                        fire()
                    }
                }
            }
            #endif
            // The one force that still works on a ball at rest: a turning table
            // has to pick it up again, or the disc would slide round underneath
            // a ball standing perfectly still on it.
            // A ball parked on a turning table is taken for a ride instead.
            if beginTurntableRide() {
                state = .ballMoving
                hideAim()
                restTimer = 0
                motionTime = 0
            }
            // Same for a ball standing on a belt or a banked green: the arrows
            // under it are supposed to be taking it somewhere.
            if state == .waiting, liftFromForceZone() {
                state = .ballMoving
                hideAim()
                restTimer = 0
                motionTime = 0
            }
            // An obstacle may push a resting ball back into motion.
            if currentSpeed > 0.18 {
                state = .ballMoving
                hideAim()
                restTimer = 0
                motionTime = 0
            }
            checkHoleCapture()
            checkBonusStar()

        case .aiming:
            aimRing.position = ball.position + SIMD3(0, -GamePhysics.ballRadius + 0.004, 0)

        case .ballMoving:
            motionTime += dt
            guidedCooldown = max(0, guidedCooldown - dt)
            flightGrace = max(0, flightGrace - dt)
            // A loop or a cannon owns the ball outright while it runs, so the
            // usual bookkeeping — hazards, surfaces, coming to rest — is put on
            // hold for those frames.
            if updateGuidedRun(dt: dt) { break }

            if let warped = pendingWarpVelocity {
                pendingWarpVelocity = nil
                ball.applyLinearImpulse(warped * GamePhysics.ballMass, relativeTo: nil)
                lastBallPosition = ball.position
            }
            applyHoleMagnet(dt: dt)
            applyForceZones(dt: dt)
            applyWind()
            applyTurntables()
            applyMagnets()
            checkHoleCapture()
            checkBonusStar()
            checkPortals()
            checkBoostPads()
            checkLaunchPads()
            updateSurfaceDamping()
            checkOutOfBounds()

            if motionTime > 0.25 {
                // A belt still working on the ball holds off the settle: it is
                // about to move it, or it is about to give up and say so.
                if currentSpeed < 0.05, !zoneStillTrying {
                    restTimer += dt
                } else {
                    restTimer = 0
                }
                if restTimer > 0.4 || motionTime > 14 {
                    if motionTime > 14 { stopBallHard() }
                    ballCameToRest()
                }
            }

        case .sinking:
            break
        }

        updateCamera(dt: dt)
    }

    private func finishIntro() {
        state = .waiting
        controller?.introRunning = false
        showAimRing()
    }

    func skipIntro() {
        guard state == .intro else { return }
        finishIntro()
    }

    // MARK: - Camera

    private func followPose(ballPosition: SIMD3<Float>? = nil) -> (SIMD3<Float>, SIMD3<Float>) {
        guard let built else { return (SIMD3(0, 1.4, 1.4), .zero) }
        let anchor = ballPosition ?? built.ball.position
        let zoom = level.cameraZoom * pinchZoom * aspectFactor
        return (anchor + CameraRig.offset * zoom, anchor + CameraRig.lookAhead)
    }

    private func introStartPose() -> (SIMD3<Float>, SIMD3<Float>) {
        guard let built else { return (SIMD3(0, 1.4, 1.4), .zero) }
        return (built.holePosition + SIMD3(0, 0.85, 1.25), built.holePosition)
    }

    /// A freshly built scene spends its first frames uploading meshes and
    /// textures, compiling render pipelines and sizing the shadow map. A
    /// flyover laid on top of that judders, so the camera holds the opening
    /// pose until the renderer delivers a few frames on time — with a grace
    /// period so a slow device still gets going.
    private func rendererWarmedUp(dt: Float) -> Bool {
        warmupTime += dt
        warmupOnTimeFrames = dt <= warmupFrameBudget ? warmupOnTimeFrames + 1 : 0
        return warmupOnTimeFrames >= warmupFramesNeeded || warmupTime >= warmupTimeLimit
    }

    /// Freezes both ends of the flyover. The landing pose is sampled from the
    /// tee instead of the live ball, so the physics body settling onto the felt
    /// cannot shake the camera target, and a late layout pass changing
    /// `aspectFactor` cannot move the endpoint mid-flight.
    private func beginFlyover() {
        flyoverRunning = true
        introTime = 0
        (flyoverStartPos, flyoverStartLook) = introStartPose()
        (flyoverEndPos, flyoverEndLook) = followPose(ballPosition: lastRestPosition)
        camPosition = flyoverStartPos
        camLookAt = flyoverStartLook
    }

    /// While the ball is going round a loop the camera stays down on the felt.
    /// A chase camera that rides up and over with it turns the shot into a
    /// somersault and nobody can read where the ball will come out.
    private func loopCameraAnchor() -> SIMD3<Float>? {
        guard let built, let run = loopRun, built.loops.indices.contains(run.index) else {
            return nil
        }
        var anchor = built.ball.position
        anchor.y = built.loops[run.index].y + GamePhysics.ballRadius
        return anchor
    }

    private func updateCamera(dt: Float) {
        let (desiredPos, desiredLook) = followPose(ballPosition: loopCameraAnchor())
        let rate: Float = state == .ballMoving ? 5.0 : 3.2
        let factor = expLerpFactor(rate: rate, dt: dt)
        camPosition = simd_mix(camPosition, desiredPos, SIMD3(repeating: factor))
        camLookAt = simd_mix(camLookAt, desiredLook, SIMD3(repeating: factor))
        camera.look(at: camLookAt, from: camPosition, relativeTo: nil)
    }

    func pinchChanged(magnification: Float) {
        guard magnification > 0.01 else { return }
        pinchZoom = simd_clamp(pinchZoomAtStart / magnification,
                               CameraRig.minPinch, CameraRig.maxPinch)
    }

    func pinchEnded() {
        pinchZoomAtStart = pinchZoom
    }

    func viewSizeChanged(size: CGSize) {
        guard size.height > 0 else { return }
        let aspect = Float(size.width / size.height)
        aspectFactor = aspect > 1 ? CameraRig.landscapeAspect : 1.0
    }

    // MARK: - Aiming input

    func aimChanged(translation: CGSize) {
        if state == .intro {
            if introTime > 0.25 { skipIntro() }
            return
        }
        guard state == .waiting || state == .aiming, let controller, let built else { return }
        guard case .none = controller.overlay else { return }

        let dx = Float(translation.width)
        let dy = Float(translation.height)
        let length = sqrt(dx * dx + dy * dy)

        guard length > 12 else {
            aimPower = 0
            arrowRoot.isEnabled = false
            guideRenderer?.hide()
            guideOnTarget = false
            controller.setAim(power: 0, aiming: state == .aiming)
            return
        }

        if state != .aiming {
            state = .aiming
            // Lining up a shot is the cue that impacts are coming: the strike
            // itself, then whatever the ball finds. Warming the engine here is
            // what lets the first of those be felt on the frame it happens.
            Haptics.shared.prepare()
        }
        aimDirection = simd_normalize(SIMD3(-dx, 0, -dy))
        aimPower = min(1, (length - 12) / 230)

        controller.setAim(power: aimPower, aiming: true)

        updateArrow(ball: built.ball)
    }

    func aimEnded() {
        if state == .intro {
            skipIntro()
            return
        }
        guard state == .aiming else { return }
        if aimPower > 0.04 {
            fire()
        } else {
            cancelAim()
        }
    }

    private func cancelAim() {
        state = .waiting
        aimPower = 0
        arrowRoot.isEnabled = false
        guideRenderer?.hide()
        guideOnTarget = false
        controller?.setAim(power: 0, aiming: false)
    }

    private func updateArrow(ball: ModelEntity) {
        arrowRoot.isEnabled = true
        arrowRoot.position = SIMD3(ball.position.x, ball.position.y - 0.012, ball.position.z)
        arrowRoot.orientation = simd_quatf(angle: atan2(aimDirection.x, aimDirection.z),
                                           axis: SIMD3(0, 1, 0))
        // With the dotted guide on, the arrow shrinks to a stub at the ball: the
        // line already carries the direction, and two overlapping indicators of
        // the same thing just clutter the felt.
        let length = aimGuideLevel == .off ? 0.22 + aimPower * 0.6 : 0.16
        arrowShaft.scale = SIMD3(1, 1, length)
        arrowShaft.position = SIMD3(0, 0, 0.07 + length / 2)
        arrowHead.position = SIMD3(0, 0, 0.07 + length + 0.04)

        let bucket = min(5, Int(aimPower * 5.999))
        if bucket != arrowBucket {
            arrowBucket = bucket
            let material = arrowMaterials[bucket]
            arrowShaft.model?.materials = [material]
            arrowHead.model?.materials = [material]
        }

        updateGuide(ball: ball)
    }

    /// Traces the putt through the level's static geometry and lays the dotted
    /// line down on the felt. A line that reaches the cup turns gold and ticks
    /// once, which is the whole reason the guide is worth having.
    private func updateGuide(ball: ModelEntity) {
        guard let renderer = guideRenderer, let built else { return }
        let floorY = ball.position.y - GamePhysics.ballRadius
        let holeOnThisLevel = abs(built.holePosition.y - floorY) < 0.06

        let path = AimGuideTracer.trace(
            geometry: guideGeometry,
            from: ball.position.xz,
            direction: SIMD2(aimDirection.x, aimDirection.z),
            length: aimGuideLevel.length(power: aimPower),
            ballY: floorY,
            hole: built.holePosition.xz,
            holeRadius: holeOnThisLevel ? 0.052 : 0,
            maxBounces: aimGuideLevel.maxBounces)

        renderer.show(path: path, y: floorY + 0.004)

        if path.endsInHole != guideOnTarget {
            guideOnTarget = path.endsInHole
            if path.endsInHole { Haptics.shared.light() }
        }
    }

    private func fire() {
        guard let built, let controller else { return }
        let speed = minShotSpeed + pow(aimPower, 1.15) * (maxShotSpeed - minShotSpeed)
        let impulse = aimDirection * speed * GamePhysics.ballMass

        lastRestPosition = built.ball.position
        #if DEBUG
        shotOrigin = built.ball.position
        #endif
        built.ball.applyLinearImpulse(impulse, relativeTo: nil)

        controller.registerStroke()
        controller.setAim(power: 0, aiming: false)

        SoundManager.shared.play(.hit, volume: 0.35 + 0.65 * aimPower)
        Haptics.shared.impact(intensity: CGFloat(0.3 + 0.7 * aimPower))

        state = .ballMoving
        hideAim()
        restTimer = 0
        motionTime = 0
        releaseZone()
        aimPower = 0
    }

    private func hideAim() {
        arrowRoot.isEnabled = false
        aimRing.isEnabled = false
        guideRenderer?.hide()
        guideOnTarget = false
    }

    private func showAimRing() {
        aimRing.isEnabled = true
    }

    private func ballCameToRest() {
        state = .waiting
        restTimer = 0
        #if DEBUG
        if let power = calibratePower, let origin = shotOrigin, let built {
            let rolled = simd_distance(origin.xz, built.ball.position.xz)
            print("CALIBRATE power=\(power) rolled=\(String(format: "%.3f", rolled))m")
            shotOrigin = nil
        }
        #endif
        lastRestPosition = built?.ball.position ?? lastRestPosition
        showAimRing()
        controller?.ballRested()
    }

    // MARK: - Hole capture

    private func checkHoleCapture() {
        guard let built, state == .ballMoving || state == .waiting else { return }
        let ball = built.ball
        let toHole = built.holePosition.xz - ball.position.xz
        let distance = simd_length(toHole)
        let heightOK = abs(ball.position.y - (built.holePosition.y + GamePhysics.ballRadius)) < 0.055

        if distance < 0.05, heightOK, currentSpeed < 1.35 {
            captureBall()
        }
    }

    private func applyHoleMagnet(dt: Float) {
        guard let built else { return }
        let ball = built.ball
        let toHole = built.holePosition.xz - ball.position.xz
        let distance = simd_length(toHole)
        let heightOK = abs(ball.position.y - (built.holePosition.y + GamePhysics.ballRadius)) < 0.055
        if distance < 0.1, distance > 0.001, heightOK, currentSpeed < 0.7 {
            let direction = simd_normalize(SIMD3(toHole.x, 0, toHole.y))
            ball.addForce(direction * 0.05, relativeTo: nil)
        }
    }

    private func captureBall() {
        guard let built, state != .sinking else { return }
        state = .sinking
        hideAim()

        let ball = built.ball
        ball.components.remove(PhysicsBodyComponent.self)
        ball.components.remove(CollisionComponent.self)

        let target = Transform(
            scale: SIMD3(repeating: 0.62),
            rotation: ball.orientation,
            translation: built.holePosition + SIMD3(0, -0.045, 0))
        ball.move(to: target, relativeTo: built.root, duration: 0.38, timingFunction: .easeIn)

        SoundManager.shared.play(.hole)
        Haptics.shared.success()
        spawnConfetti(at: built.holePosition)

        // The drop plays out over the best part of a second, and the pause
        // button is live for all of it. Whichever hole was on screen when the
        // ball went in is the only one this may score, so the scene it belongs
        // to has to still be the current one when the wait is up.
        let token = controller?.sceneToken
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(950))
            guard let controller = self?.controller, controller.sceneToken == token else { return }
            controller.ballHoled()
        }
    }

    /// Every confetti piece is the same little box, on every hole of every world,
    /// so the mesh and the collision shape are built once for the whole app.
    /// Generating them per piece meant 24 mesh uploads and 24 hull builds inside
    /// the single frame that holed the ball — a hitch landing exactly on the
    /// reward.
    private enum Confetti {
        static let count = 24
        static let size = SIMD3<Float>(0.014, 0.003, 0.01)
        static let mesh = MeshResource.generateBox(size: size)
        static let shape = ShapeResource.generateBox(size: size)
    }

    /// Physical confetti: tiny colorful boxes popping out of the hole.
    private func spawnConfetti(at position: SIMD3<Float>) {
        guard let built else { return }
        let theme = level.course.theme
        let colors: [UIColor] = [
            .systemYellow, .systemPink, .systemTeal, .white, theme.accent,
        ]
        // Five materials rather than one per piece, and one body description
        // copied into all of them.
        let materials = colors.map { UnlitMaterial(color: $0) }
        var body = PhysicsBodyComponent(
            massProperties: .init(mass: 0.0015),
            material: GamePhysics.ballMaterial,
            mode: .dynamic)
        body.angularDamping = 0.4
        let collision = CollisionComponent(shapes: [Confetti.shape])

        var rng = SplitMix64(seed: UInt64(level.number) &* 7919 &+ 13)
        var pieces: [Entity] = []

        for i in 0..<Confetti.count {
            let piece = ModelEntity(mesh: Confetti.mesh,
                                    materials: [materials[i % materials.count]])
            piece.position = position + SIMD3(rng.float(in: -0.02...0.02), 0.03,
                                              rng.float(in: -0.02...0.02))
            piece.orientation = simd_quatf(angle: rng.float(in: 0...(2 * .pi)),
                                           axis: simd_normalize(SIMD3(rng.float(in: 0.2...1),
                                                                      rng.float(in: 0.2...1),
                                                                      rng.float(in: 0.2...1))))
            piece.components.set(body)
            piece.components.set(collision)
            built.root.addChild(piece)
            piece.applyLinearImpulse(
                SIMD3(rng.float(in: -0.0016...0.0016),
                      rng.float(in: 0.0028...0.0048),
                      rng.float(in: -0.0016...0.0016)),
                relativeTo: nil)
            pieces.append(piece)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            for piece in pieces {
                piece.removeFromParent()
            }
        }
    }

    // MARK: - Hazards

    /// Sand, mud and ice only change how fast the ball loses speed, so the
    /// surface is looked up per frame and written into the body when it changes.
    private func updateSurfaceDamping() {
        guard let built else { return }
        let ball = built.ball
        let surface = built.surfaceRegions.first { region in
            region.rect.contains(ball.position.xz) &&
            abs(ball.position.y - (region.y + GamePhysics.ballRadius)) < 0.035
        }
        let target = surface?.damping ?? GamePhysics.ballLinearDamping
        guard abs(target - appliedDamping) > 0.0001 else { return }
        appliedDamping = target
        if var body = ball.components[PhysicsBodyComponent.self] {
            body.linearDamping = target
            ball.components.set(body)
        }
    }

    /// Banked greens, belts and currents: a steady push while the ball rolls
    /// through the zone.
    ///
    /// The push alone cannot keep it going. A ball that runs out of pace on the
    /// arrows is held there by static friction — at putting scale that is worth
    /// several times anything a zone pushes with — and the solver then parks the
    /// body, after which it ignores force outright. So a ball slower than the
    /// surface under it is dragged up to that speed instead of pushed, and the
    /// belt carries it off the way its chevrons say it should.
    private func applyForceZones(dt: Float) {
        guard let built, !built.forceZones.isEmpty else { return }
        let ball = built.ball
        var carried = false

        for zone in built.forceZones where zoneHolds(zone, ball: ball) {
            carried = true
            ball.addForce(SIMD3(zone.force.x, 0, zone.force.y), relativeTo: nil)
            guard !zoneBlocked, let surface = zoneSurface(zone) else { continue }
            // How much the ball is slipping on the surface decides how much of
            // it the surface can hand over: a standing ball is taken up to the
            // full speed of the belt, one already going that fast is left alone,
            // and everything between is dragged in proportion — so a putt
            // crossing the arrows bends instead of snapping into line with them.
            let slip = 1 - simd_length(ballVelocity.xz) / surface.speed
            guard slip > 0 else { continue }
            let target = surface.speed * slip
            let along = simd_dot(ballVelocity.xz, surface.direction)
            guard along < target else { continue }
            let grab = surface.direction * ((target - along) * GamePhysics.ballMass)
            ball.applyLinearImpulse(SIMD3(grab.x, 0, grab.y), relativeTo: nil)
        }

        if carried {
            trackZoneHeadway(dt: dt, position: ball.position)
        } else {
            releaseZone()
        }
    }

    /// True while the ball is standing on this zone's patch of floor.
    private func zoneHolds(_ zone: ForceZone, ball: ModelEntity) -> Bool {
        zone.rect.contains(ball.position.xz)
            && abs(ball.position.y - (zone.y + GamePhysics.ballRadius)) < 0.05
    }

    /// How the surface itself is moving, or nil for a zone that only pushes.
    private func zoneSurface(_ zone: ForceZone) -> (direction: SIMD2<Float>, speed: Float)? {
        let speed = simd_length(zone.carry)
        guard speed > 0.001 else { return nil }
        return (zone.carry / speed, speed)
    }

    /// Watches whether the zone is actually getting the ball anywhere. A belt
    /// running into a wall has to give up and let the ball settle, or the stroke
    /// limit — judged only once it rests — would never come round. Once it does
    /// give up the ball is left alone until the next stroke frees it.
    private func trackZoneHeadway(dt: Float, position: SIMD3<Float>) {
        guard let anchor = zoneAnchor else {
            zoneAnchor = position
            zoneStall = 0
            return
        }
        zoneStall += dt
        guard zoneStall > GamePhysics.zoneStallWindow else { return }
        zoneBlocked = simd_distance(anchor, position) < GamePhysics.zoneStallHeadway
        zoneAnchor = position
        zoneStall = 0
    }

    /// True while a zone has hold of the ball and has not given up on it.
    private var zoneStillTrying: Bool { zoneAnchor != nil && !zoneBlocked }

    /// Forgets the zone the ball was on: it has left one, or a stroke has given
    /// a blocked ball a fresh chance to get away.
    private func releaseZone() {
        zoneAnchor = nil
        zoneStall = 0
        zoneBlocked = false
    }

    /// Picks up a ball that is already standing on a belt or a banked green —
    /// teed up on the arrows, or parked there when a shot ran out of patience.
    /// The solver has stopped listening to that body by then, so it is rebuilt
    /// with the surface's speed already in it, the way a portal hands the ball
    /// out of the far ring. A ball the belt has given up on is left where it is:
    /// picking it up again every time it settled would leave it twitching on the
    /// boards with no way to putt.
    private func liftFromForceZone() -> Bool {
        guard let built, !built.forceZones.isEmpty, !zoneBlocked else { return false }
        let ball = built.ball

        for zone in built.forceZones where zoneHolds(zone, ball: ball) {
            guard zoneSurface(zone) != nil else { continue }
            let velocity = SIMD3(zone.carry.x, 0, zone.carry.y)

            releaseZone()
            teleportBall(to: ball.position)
            pendingWarpVelocity = velocity
            ballVelocity = velocity
            previousBallVelocity = velocity
            return true
        }
        return false
    }

    /// Portals fire once and then stay dormant until the ball has left both
    /// rings, so a pair can never bounce the ball back and forth.
    private func checkPortals() {
        guard let built, !built.portals.isEmpty else { return }
        let position = built.ball.position

        for index in built.portals.indices {
            let portal = built.portals[index]
            guard abs(position.y - (portal.y + GamePhysics.ballRadius)) < 0.06 else { continue }
            let toA = simd_distance(position.xz, portal.a)
            let toB = simd_distance(position.xz, portal.b)
            let inside = min(toA, toB) < portal.radius

            guard portal.armed else {
                if !inside { self.built?.portals[index].armed = true }
                continue
            }
            guard inside else { continue }

            self.built?.portals[index].armed = false
            warp(to: toA < toB ? portal.b : portal.a, y: portal.y)
            return
        }
    }

    /// Drops the ball out of the far ring with its speed intact.
    private func warp(to target: SIMD2<Float>, y: Float) {
        guard let built else { return }
        let flat = SIMD3(ballVelocity.x, 0, ballVelocity.z)
        let speed = simd_length(flat)
        let direction = speed > 0.05 ? simd_normalize(flat) : SIMD3<Float>(0, 0, -1)
        // A hair past the ring centre so the exit does not re-trigger on itself.
        let exit = SIMD3(target.x, y + GamePhysics.ballRadius + 0.002, target.y) + direction * 0.03

        // Moving a dynamic body wipes its motion, and nothing written in the same
        // frame survives the step — so the exit speed is handed to the next tick
        // and applied there, otherwise the ball trickles out of the far ring at
        // a standstill.
        built.ball.position = exit
        lastBallPosition = exit
        pendingWarpVelocity = direction * speed
        ballVelocity = direction * speed
        previousBallVelocity = ballVelocity
        motionTime = 0
        restTimer = 0

        SoundManager.shared.play(.portal, volume: 0.85)
        Haptics.shared.impact(intensity: 0.55)
    }

    private func checkBoostPads() {
        guard let built, !built.boostPads.isEmpty,
              elapsed - lastBoostTime > 0.45 else { return }
        let position = built.ball.position

        for pad in built.boostPads {
            guard abs(position.y - (pad.y + GamePhysics.ballRadius)) < 0.05,
                  simd_distance(position.xz, pad.center) < 0.085
            else { continue }
            lastBoostTime = elapsed
            built.ball.applyLinearImpulse(
                SIMD3(pad.direction.x, 0, pad.direction.y) * pad.boost * GamePhysics.ballMass,
                relativeTo: nil)
            SoundManager.shared.play(.boost, volume: 0.8)
            Haptics.shared.impact(intensity: 0.5)
            return
        }
    }

    /// Kickers hand the ball a fixed speed and a fixed lift — the putt that got
    /// it here only decides whether the jump happens at all — so a gap that can
    /// be cleared can always be cleared, and the landing spot is the same every
    /// time.
    private func checkLaunchPads() {
        guard let built, !built.launchPads.isEmpty,
              elapsed - lastLaunchTime > 0.6 else { return }
        let ball = built.ball
        let position = ball.position

        for pad in built.launchPads {
            guard abs(position.y - (pad.y + GamePhysics.ballRadius)) < 0.05,
                  simd_distance(position.xz, pad.center) < 0.095
            else { continue }
            // A ball barely creeping onto the wedge just rolls over it.
            guard simd_dot(ballVelocity.xz, pad.direction) > pad.speed * 0.45 else { continue }

            lastLaunchTime = elapsed
            let target = SIMD3(pad.direction.x * pad.speed, pad.lift,
                               pad.direction.y * pad.speed)
            ball.applyLinearImpulse((target - ballVelocity) * GamePhysics.ballMass,
                                    relativeTo: nil)
            // The safety net has to let go while the ball is over the gap.
            flightGrace = 1.6
            SoundManager.shared.play(.boost, volume: 0.9)
            Haptics.shared.impact(intensity: 0.6)
            return
        }
    }

    /// Wind: the same push as a belt, but it swells and dies on a timer and the
    /// fan blades turn at the pace of the gust, so the player can see it coming.
    private func applyWind() {
        guard let built, !built.windZones.isEmpty else { return }
        let ball = built.ball
        for zone in built.windZones {
            // Unlike a belt, wind fills the whole column above the felt, so it
            // still shoves a ball that is in the air.
            guard zone.rect.contains(ball.position.xz),
                  ball.position.y > zone.y - 0.05, ball.position.y < zone.y + 0.4
            else { continue }
            let force = zone.direction * (zone.strength * zone.gust(at: elapsed)
                                          * GamePhysics.ballMass)
            ball.addForce(SIMD3(force.x, 0, force.y), relativeTo: nil)
        }
    }

    /// A turning disc bends the path of a ball rolling across it — the same
    /// reason a marble on a record player runs in circles.
    ///
    /// Dragging the ball toward the speed of the surface under it, which is the
    /// obvious way to write this, does almost nothing: the surface runs one way
    /// on the near side of the hub and the other way past it, so a ball crossing
    /// the middle is pushed both ways and comes off the far side on its original
    /// line, a little slower. The real coupling turns the ball instead — the
    /// acceleration is `ω × v`, square to however the ball happens to be
    /// travelling, so it never cancels itself out and the ball leaves the disc
    /// somewhere else entirely.
    private func applyTurntables() {
        guard let built, !built.turntables.isEmpty else { return }
        let ball = built.ball
        for disc in built.turntables {
            guard abs(ball.position.y - (disc.y + GamePhysics.ballRadius)) < 0.05 else { continue }
            guard simd_distance(ball.position.xz, disc.center) < disc.radius else { continue }
            // Turning radius comes out as |v| / (curve · ω), so a disc turning
            // at 2 rad/s bends the ball around a circle a little over half a
            // metre across — a quarter turn on a table this size.
            let velocity = ballVelocity.xz
            let curve = SIMD2(velocity.y, -velocity.x) * (disc.speed * GamePhysics.turntableCurve)
            ball.addForce(SIMD3(curve.x, 0, curve.y) * GamePhysics.ballMass, relativeTo: nil)
        }
    }

    /// Radial pull (or push), strongest at the core and gone at the rim.
    private func applyMagnets() {
        guard let built, !built.magnets.isEmpty else { return }
        let ball = built.ball
        for magnet in built.magnets {
            guard abs(ball.position.y - (magnet.y + GamePhysics.ballRadius)) < 0.05 else { continue }
            let toCenter = magnet.center - ball.position.xz
            let distance = simd_length(toCenter)
            guard distance > 0.005, distance < magnet.radius else { continue }
            let falloff = 1 - distance / magnet.radius
            let force = (toCenter / distance) * (magnet.strength * falloff * GamePhysics.ballMass)
            ball.addForce(SIMD3(force.x, 0, force.y), relativeTo: nil)
        }
    }

    // MARK: - Loop and cannon

    /// True while an obstacle has taken the ball off the solver.
    private func updateGuidedRun(dt: Float) -> Bool {
        if loopRun != nil {
            advanceLoop(dt: dt)
            return true
        }
        if cannonRun != nil {
            advanceCannon(dt: dt)
            return true
        }
        if turntableRide != nil {
            advanceTurntableRide(dt: dt)
            return true
        }
        return enterLoop(dt: dt) || enterCannon() || beginTurntableRide()
    }

    /// True while this obstacle is the one that just handed the ball back.
    private func heldOff(_ source: GuidedSource) -> Bool {
        guidedCooldown > 0 && (guidedCooldownSource == nil || guidedCooldownSource == source)
    }

    private func holdOff(_ source: GuidedSource?, seconds: Float) {
        guidedCooldown = seconds
        guidedCooldownSource = source
    }

    private func abortGuidedRun() {
        guard loopRun != nil || cannonRun != nil || turntableRide != nil else { return }
        loopRun = nil
        cannonRun = nil
        turntableRide = nil
        holdOff(nil, seconds: 0.4)
        pendingWarpVelocity = nil
    }

    // MARK: - Riding a turntable

    /// Takes over a ball that has run out of pace on a turning table.
    ///
    /// Pushing it with a force does not work, and neither does hitting it with
    /// an impulse: the solver parks a body that has come to rest and from then
    /// on ignores both, so the ball would sit there while the table turned
    /// underneath it. Waking it with a fresh body once per stall is no better —
    /// it parks again a moment later, and the ball creeps around the disc in
    /// little jerks. So the table carries the ball itself, the same way the
    /// loop and the cannon do, and hands it back at the rim.
    private func beginTurntableRide() -> Bool {
        guard let built, !built.turntables.isEmpty,
              simd_length(ballVelocity.xz) < GamePhysics.turntableCatchSpeed
        else { return false }
        let ball = built.ball

        for (index, disc) in built.turntables.enumerated() {
            guard !heldOff(.turntable(index)),
                  abs(ball.position.y - (disc.y + GamePhysics.ballRadius)) < 0.05
            else { continue }
            let offset = ball.position.xz - disc.center
            let radius = simd_length(offset)
            // Dead centre is the one spot on a turntable that does not move.
            guard radius > 0.03, radius < disc.radius else { continue }

            ball.components.remove(PhysicsBodyComponent.self)
            turntableRide = TurntableRide(index: index, angle: atan2(offset.y, offset.x),
                                          radius: radius, time: 0)
            return true
        }
        return false
    }

    private func advanceTurntableRide(dt: Float) {
        guard let built, var ride = turntableRide,
              built.turntables.indices.contains(ride.index)
        else {
            turntableRide = nil
            return
        }
        let disc = built.turntables[ride.index]
        ride.time += dt
        // Eased in over a moment, so the table picks the ball up rather than
        // snatching it.
        let grip = smoothstep(ride.time / 0.4)
        // The angle runs against the disc's sign: turning about +Y carries a
        // point at +Z toward +X, which is decreasing angle in this frame.
        ride.angle -= disc.speed * grip * dt
        ride.radius += GamePhysics.turntableSpill * grip * dt

        // Friction cannot hold a ball in a circle for long, so every ride works
        // its way out to the rim and ends there.
        guard ride.radius < disc.radius + 0.015 else {
            endTurntableRide(disc: disc, ride: ride)
            return
        }
        turntableRide = ride
        built.ball.position = ridePosition(disc: disc, ride: ride)
    }

    private func ridePosition(disc: Turntable, ride: TurntableRide) -> SIMD3<Float> {
        SIMD3(disc.center.x + cos(ride.angle) * ride.radius,
              disc.y + GamePhysics.ballRadius,
              disc.center.y + sin(ride.angle) * ride.radius)
    }

    private func endTurntableRide(disc: Turntable, ride: TurntableRide) {
        turntableRide = nil
        holdOff(.turntable(ride.index), seconds: 0.35)
        // Hand the ball back with the speed the ride gave it: round the hub,
        // plus the drift that carried it off the edge.
        let radial = SIMD2(cos(ride.angle), sin(ride.angle))
        let tangent = SIMD2(sin(ride.angle), -cos(ride.angle))
        let carried = tangent * (disc.speed * ride.radius)
                    + radial * GamePhysics.turntableSpill
        let velocity = SIMD3(carried.x, 0, carried.y)

        teleportBall(to: ridePosition(disc: disc, ride: ride))
        pendingWarpVelocity = velocity
        ballVelocity = velocity
        previousBallVelocity = velocity
        motionTime = 0
        restTimer = 0
    }

    /// Catches a ball rolling into the entrance of a loop — whichever of the two
    /// mouths lies ahead of it. The crossing is tested against the whole step,
    /// not just where the ball happens to be sampled: a fast putt covers most of
    /// the mouth in a single frame.
    private func enterLoop(dt: Float) -> Bool {
        guard let built, !built.loops.isEmpty else { return false }
        let position = built.ball.position
        let previous = position - ballVelocity * dt

        for (index, loop) in built.loops.enumerated() {
            guard !heldOff(.loop(index)),
                  abs(position.y - (loop.y + GamePhysics.ballRadius)) < 0.045
            else { continue }
            let entry = simd_dot(ballVelocity.xz, loop.axis)
            guard abs(entry) > 0.45 else { continue }
            let sign: Float = entry > 0 ? 1 : -1

            let delta = position.xz - loop.mouth(sign: sign)
            let across = simd_dot(delta, SIMD2(loop.axis.y, -loop.axis.x))
            guard abs(across) < loop.halfWidth else { continue }

            // Measured the way the ball is travelling: negative short of the
            // entrance, positive once it is through.
            let along = simd_dot(delta, loop.axis) * sign
            let alongBefore = simd_dot(previous.xz - loop.mouth(sign: sign), loop.axis) * sign
            guard abs(along) < 0.05 || (alongBefore < 0 && along > 0) else { continue }

            beginLoop(index: index, loop: loop, speed: abs(entry), sign: sign)
            return true
        }
        return false
    }

    private func beginLoop(index: Int, loop: LoopTrack, speed: Float, sign: Float) {
        guard let built else { return }
        built.ball.components.remove(PhysicsBodyComponent.self)
        let run = LoopRun(index: index, theta: 0, speed: speed,
                          forward: SIMD3(loop.axis.x, 0, loop.axis.y) * sign,
                          attitude: built.ball.orientation)
        loopRun = run
        place(ball: built.ball, on: loop, run: run)
        SoundManager.shared.play(.loop, volume: 0.75)
        Haptics.shared.light()
    }

    /// One frame of the ride. Only 5/7 of gravity slows a rolling sphere along
    /// the track — the rest of its energy is in the spin — which is the same
    /// reason a ball beats a sliding block down a ramp.
    private func advanceLoop(dt: Float) {
        guard let built, var run = loopRun, built.loops.indices.contains(run.index) else {
            loopRun = nil
            return
        }
        let loop = built.loops[run.index]
        let radius = loop.trackRadius
        let gravity: Float = 9.81
        let steps = 4
        let step = min(dt, 1.0 / 30) / Float(steps)

        for _ in 0..<steps {
            // The track runs forward as well as up, so what costs speed is the
            // rise of the piece under the ball, not the angle round the ring.
            let tangent = loop.ballTangent(theta: run.theta)
            let arc = max(0.001, simd_length(tangent))
            run.speed -= (5.0 / 7.0) * gravity * (tangent.y / arc) * step
            // A little rolling resistance, so the ride is never quite free.
            run.speed -= (run.speed < 0 ? -1 : 1) * 0.4 * step
            run.rolled += run.speed * step
            run.theta += run.speed / arc * step
            if run.theta <= 0 || run.theta >= 2 * .pi { break }
            // Past the horizontal the track can only push inwards: without
            // enough speed to be held there, the ball simply leaves it.
            if cos(run.theta) < 0,
               run.speed * run.speed < -cos(run.theta) * gravity * radius {
                leaveLoop(loop: loop, run: run, falling: true)
                return
            }
        }

        if run.theta <= 0 || run.theta >= 2 * .pi {
            leaveLoop(loop: loop, run: run, falling: false)
            return
        }
        loopRun = run
        place(ball: built.ball, on: loop, run: run)
    }

    /// The ball is off the solver for the whole ride, so its spin has to be
    /// turned by hand — otherwise it slides round the track like a bead on a
    /// wire and the loop reads as a shove forward.
    private func place(ball: ModelEntity, on loop: LoopTrack, run: LoopRun) {
        ball.position = loopPoint(loop: loop, theta: run.theta, forward: run.forward)
        let spinAxis = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), run.forward))
        ball.orientation = simd_quatf(angle: run.rolled / GamePhysics.ballRadius,
                                      axis: spinAxis) * run.attitude
    }

    private func loopPoint(loop: LoopTrack, theta: Float, forward: SIMD3<Float>) -> SIMD3<Float> {
        let point = loop.ballPoint(theta: theta)
        let base = SIMD3(loop.center.x, loop.y, loop.center.y)
        return base + forward * point.x + SIMD3(0, point.y, 0)
    }

    /// Hands the ball back to the solver: either off the top with whatever speed
    /// it had left, or on the felt again — out of the exit after a full lap,
    /// back out of the entrance after a failed climb.
    private func leaveLoop(loop: LoopTrack, run: LoopRun, falling: Bool) {
        loopRun = nil
        holdOff(.loop(run.index), seconds: 0.4)
        let theta = falling ? run.theta : (run.theta > .pi ? 2 * .pi : 0)
        let tangent = simd_normalize(loop.ballTangent(theta: theta))
        let velocity = (run.forward * tangent.x + SIMD3<Float>(0, tangent.y, 0)) * run.speed
        var position = loopPoint(loop: loop, theta: theta, forward: run.forward)

        if falling {
            flightGrace = max(flightGrace, 0.9)
            SoundManager.shared.play(.bounce, volume: 0.7)
        } else {
            // Step clear of the mouth, or the track catches the ball again on
            // the very next frame.
            position += run.forward * (run.speed < 0 ? -0.05 : 0.05)
            position.y = loop.y + GamePhysics.ballRadius
            SoundManager.shared.play(.boost, volume: 0.6)
            Haptics.shared.impact(intensity: 0.45)
        }

        teleportBall(to: position)
        pendingWarpVelocity = velocity
        ballVelocity = velocity
        previousBallVelocity = velocity
        motionTime = 0
        restTimer = 0
    }

    private func enterCannon() -> Bool {
        guard let built, !built.cannons.isEmpty else { return false }
        let position = built.ball.position

        for (index, cannon) in built.cannons.enumerated() {
            guard !heldOff(.cannon(index)),
                  abs(position.y - (cannon.y + GamePhysics.ballRadius)) < 0.05,
                  simd_distance(position.xz, cannon.center) < cannon.radius
            else { continue }
            built.ball.components.remove(PhysicsBodyComponent.self)
            cannonRun = CannonRun(index: index, timer: 0)
            SoundManager.shared.play(.portal, volume: 0.6)
            Haptics.shared.impact(intensity: 0.35)
            return true
        }
        return false
    }

    /// The ball climbs into the barrel while the cannon charges, then leaves it
    /// along the barrel's line at a fixed speed — whichever way it rolled in.
    private func advanceCannon(dt: Float) {
        guard let built, var run = cannonRun, built.cannons.indices.contains(run.index) else {
            cannonRun = nil
            return
        }
        let cannon = built.cannons[run.index]
        run.timer += dt

        guard run.timer >= cannonCharge else {
            cannonRun = run
            let breech = cannon.center + cannon.direction * (cannon.radius + 0.04)
            let from = SIMD3(cannon.center.x, cannon.y + GamePhysics.ballRadius, cannon.center.y)
            let to = SIMD3(breech.x, cannon.y + 0.05, breech.y)
            built.ball.position = simd_mix(from, to,
                                           SIMD3(repeating: smoothstep(run.timer / cannonCharge)))
            return
        }

        cannonRun = nil
        holdOff(.cannon(run.index), seconds: 0.4)
        let exit = cannon.exit
        teleportBall(to: SIMD3(exit.x, cannon.y + GamePhysics.ballRadius, exit.y))
        let velocity = SIMD3(cannon.direction.x, 0, cannon.direction.y) * cannon.speed
        pendingWarpVelocity = velocity
        ballVelocity = velocity
        previousBallVelocity = velocity
        motionTime = 0
        restTimer = 0
        SoundManager.shared.play(.cannon, volume: 0.95)
        Haptics.shared.impact(intensity: 0.8)
    }

    private func checkBonusStar() {
        guard let built, let star = built.bonusStar, !star.collected else { return }
        let position = built.ball.position
        guard simd_distance(position.xz, star.position.xz) < 0.078,
              abs(position.y - star.position.y) < 0.11
        else { return }

        self.built?.bonusStar?.collected = true
        star.entity.removeFromParent()
        SoundManager.shared.play(.star, volume: 0.9)
        Haptics.shared.success()
        controller?.collectBonusStar()
    }

    private func checkOutOfBounds() {
        guard let built else { return }
        let ball = built.ball
        let fellBelow = ball.position.y < built.minFloorY - 0.12
        // Safety net: the ball hopped a wall and left the course footprint. A
        // ball that was kicked into the air on purpose is allowed to be over
        // nothing for a moment — that is the whole point of a jump.
        let escaped = flightGrace <= 0 && !built.floorRects.contains {
            $0.contains(ball.position.xz, margin: 0.09)
        }
        if fellBelow || escaped {
            let hazard = built.hazardRegions.first {
                $0.rect.contains(ball.position.xz, margin: 0.08)
            }
            let kind = hazard?.kind ?? .outOfBounds
            switch kind {
            case .water: SoundManager.shared.play(.splash, volume: 0.8)
            case .lava: SoundManager.shared.play(.sizzle, volume: 0.85)
            case .outOfBounds: SoundManager.shared.play(.fail, volume: 0.8)
            }
            respawn(kind: kind)
        }
    }

    private func respawn(kind: OutOfBoundsKind) {
        guard built != nil, let controller else { return }
        abortGuidedRun()
        flightGrace = 0
        controller.registerPenalty(kind: kind)

        teleportBall(to: lastRestPosition + SIMD3(0, 0.004, 0))
        state = .ballMoving
        // Drop the ball back in most of the way through a settle, so the stroke
        // limit is judged a tenth of a second later rather than after another
        // full run-out.
        motionTime = 10
        restTimer = 0.3
        releaseZone()
    }

    /// Moves the ball and zeroes its velocity by rebuilding the physics body.
    private func teleportBall(to position: SIMD3<Float>) {
        guard let built else { return }
        let ball = built.ball
        ball.components.remove(PhysicsBodyComponent.self)
        ball.position = position
        var body = PhysicsBodyComponent(
            massProperties: .init(mass: GamePhysics.ballMass),
            material: GamePhysics.ballMaterial,
            mode: .dynamic)
        body.linearDamping = GamePhysics.ballLinearDamping
        body.angularDamping = GamePhysics.ballAngularDamping
        body.isContinuousCollisionDetectionEnabled = true
        ball.components.set(body)
        // The fresh body starts on plain felt; let the surface check re-apply.
        appliedDamping = GamePhysics.ballLinearDamping
        lastBallPosition = position
        ballVelocity = .zero
        previousBallVelocity = .zero
        trail?.reset()
    }

    private func stopBallHard() {
        guard let built else { return }
        teleportBall(to: built.ball.position)
    }

    // MARK: - Pause support

    func pauseStateChanged(paused: Bool) {
        if paused, state == .ballMoving {
            // Freeze the ball so nothing happens behind the pause menu. A ride
            // through a loop or a cannon ends here too — it is driven by hand,
            // and resuming it into a rebuilt physics body would fight itself.
            abortGuidedRun()
            stopBallHard()
        }
    }

    // MARK: - Collision feedback

    private func handleCollision(_ event: CollisionEvents.Began) {
        guard let built, state == .ballMoving else { return }
        let ball = built.ball
        let other = event.entityA == ball ? event.entityB : event.entityA
        let isBumper = built.bumperNames.contains(other.name)
        let critter = other.name == "critter" ? built.critters.first { $0.body === other } : nil

        let restitution = isBumper ? GamePhysics.bumperBounce
                                   : (critter?.kind.restitution ?? GamePhysics.wallBounce)
        rebound(ball: ball, event: event, restitution: restitution)

        if let critter {
            // The character is knocked the way the ball was going, so it rocks
            // away from the putt rather than into it.
            critter.hit(direction: critter.root.position(relativeTo: nil) - ball.position)
            let force = min(1, Float(event.impulse) * 55)
            SoundManager.shared.play(.bumper, volume: 0.3 + 0.45 * force)
            if force > 0.3 { throttledHaptic { Haptics.shared.impact(intensity: 0.45) } }
        } else if isBumper {
            var direction = ball.position - other.position(relativeTo: nil)
            direction.y = 0
            if simd_length(direction) > 0.001 {
                direction = simd_normalize(direction)
                ball.applyLinearImpulse(direction * 0.014, relativeTo: nil)
            }
            SoundManager.shared.play(.bumper, volume: 0.85)
            throttledHaptic { Haptics.shared.impact(intensity: 0.6) }
            flash(other)
        } else if event.impulse > 0.0035, elapsed - lastBounceSound > 0.09 {
            lastBounceSound = elapsed
            let volume = min(1, Float(event.impulse) * 55)
            SoundManager.shared.play(.bounce, volume: 0.2 + 0.8 * volume)
            if volume > 0.4 { throttledHaptic { Haptics.shared.light() } }
        }
    }

    /// One impact haptic per `hapticInterval`, whichever surface asked for it.
    ///
    /// The bumper kick and the felt rebound are gameplay and stay unconditional;
    /// only the feel is rationed. A ball rattling inside a cluster of bumpers
    /// raises a collision event per board it touches, and every one of those used
    /// to buy a synchronous trip to the haptic engine from inside the frame.
    private func throttledHaptic(_ fire: () -> Void) {
        guard elapsed - lastImpactHaptic > hapticInterval else { return }
        lastImpactHaptic = elapsed
        fire()
    }

    /// The solver ignores restitution below its own bounce threshold, which sits
    /// well above putting speed: left alone the ball loses every bit of its
    /// normal velocity and slides along the boards instead of banking off them.
    /// `impulseDirection` is the contact normal pointing back at the ball, so
    /// the missing rebound can simply be added on top.
    private func rebound(ball: ModelEntity, event: CollisionEvents.Began, restitution: Float) {
        guard lastBounceTime != elapsed else { return }   // one rebound per frame
        guard simd_length(ballVelocity) < GamePhysics.maxBallSpeed else { return }

        let direction = event.impulseDirection
        guard simd_length(direction) > 0.5 else { return }
        // Floors, ramps and bump crests are climbed, not bounced off — and so is
        // the lip where a ramp meets the green above it. A ball driving up a
        // ramp covers more ground per frame than the ramp stands above that
        // green, so it clips the leading edge and the solver answers with a
        // contact only ~25° off horizontal. Read as a board, that fires the
        // rebound and hurls the climbing ball back down the slope, so any
        // contact with a real upward push counts as ground.
        guard direction.y < 0.22, direction.y > -0.5 else { return }
        let flat = SIMD3(direction.x, 0, direction.z)
        guard simd_length(flat) > 0.0001 else { return }
        let normal = simd_normalize(flat)

        // The frame carrying the contact is already partly resolved, so take
        // whichever of the last two samples was still heading into the surface.
        let approach = min(simd_dot(previousBallVelocity, normal), simd_dot(ballVelocity, normal))
        guard approach < -GamePhysics.minBounceSpeed else { return }

        lastBounceTime = elapsed
        ball.applyLinearImpulse(normal * (-approach * restitution * GamePhysics.ballMass),
                                relativeTo: nil)
    }

    private func flash(_ entity: Entity) {
        let basePosition = entity.position
        let baseScale = entity.scale
        entity.move(
            to: Transform(scale: baseScale * SIMD3(1.16, 1.0, 1.16),
                          rotation: entity.orientation, translation: basePosition),
            relativeTo: entity.parent, duration: 0.06)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(70))
            entity.move(
                to: Transform(scale: baseScale, rotation: entity.orientation,
                              translation: basePosition),
                relativeTo: entity.parent, duration: 0.12)
        }
    }
}
