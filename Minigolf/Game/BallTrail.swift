//
//  BallTrail.swift
//  Minigolf
//
//  A short streak of flat discs dropped behind the rolling ball. Ageing is done
//  with scale rather than opacity so the whole effect shares one material and
//  costs nothing but transform writes.
//

import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class BallTrail {

    private static let capacity = 26
    private static let lifetime: Float = 0.7
    /// Distance the ball has to cover before another disc is dropped.
    private static let stride: Float = 0.022

    private let root = Entity()
    private var discs: [ModelEntity] = []
    private var ages: [Float] = []
    private var next = 0
    private var lastDropPosition: SIMD3<Float>?

    init(color: UIColor) {
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.42))
        let mesh = MeshResource.generateCylinder(height: 0.002, radius: GamePhysics.ballRadius * 0.7)

        discs = (0..<Self.capacity).map { _ in
            let disc = ModelEntity(mesh: mesh, materials: [material])
            disc.isEnabled = false
            root.addChild(disc)
            return disc
        }
        ages = Array(repeating: Self.lifetime, count: Self.capacity)
    }

    func attach(to parent: Entity) {
        parent.addChild(root)
    }

    /// Drops a new disc when the ball has moved far enough, then shrinks the
    /// ones already on the ground.
    func update(dt: Float, ballPosition: SIMD3<Float>, speed: Float, floorY: Float) {
        if speed > 0.25 {
            let moved = lastDropPosition.map { simd_distance($0.xz, ballPosition.xz) } ?? .infinity
            if moved >= Self.stride {
                lastDropPosition = ballPosition
                let disc = discs[next]
                disc.position = SIMD3(ballPosition.x, floorY + 0.0015, ballPosition.z)
                disc.isEnabled = true
                ages[next] = 0
                next = (next + 1) % Self.capacity
            }
        }

        for index in discs.indices where ages[index] < Self.lifetime {
            ages[index] += dt
            let remaining = max(0, 1 - ages[index] / Self.lifetime)
            if remaining <= 0.001 {
                discs[index].isEnabled = false
            } else {
                discs[index].scale = SIMD3(remaining, 1, remaining)
            }
        }
    }

    /// Clears the streak instantly — used when the ball is teleported.
    func reset() {
        lastDropPosition = nil
        for index in discs.indices {
            discs[index].isEnabled = false
            ages[index] = Self.lifetime
        }
    }
}
