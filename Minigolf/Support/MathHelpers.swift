//
//  MathHelpers.swift
//  Minigolf
//

import Foundation
import simd
import CoreGraphics

// MARK: - Deterministic random generator (stable decoration layouts per level)

/// Explicitly nonisolated: the texture factory draws whole worlds of speckle
/// on a background thread, and the layout it draws comes out of one of these.
nonisolated struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func float(in range: ClosedRange<Float>) -> Float {
        Float.random(in: range, using: &self)
    }

    mutating func chance(_ probability: Float) -> Bool {
        float(in: 0...1) < probability
    }
}

// MARK: - Small helpers

extension SIMD2<Float> {
    /// Interprets the 2D point as a position on the XZ ground plane.
    func onGround(y: Float = 0) -> SIMD3<Float> {
        SIMD3<Float>(x, y, self.y)
    }
}

extension SIMD3<Float> {
    var xz: SIMD2<Float> { SIMD2<Float>(x, z) }
}

func smoothstep(_ t: Float) -> Float {
    let x = simd_clamp(t, 0, 1)
    return x * x * (3 - 2 * x)
}

/// Frame-rate independent smoothing factor.
func expLerpFactor(rate: Float, dt: Float) -> Float {
    1 - exp(-rate * dt)
}

/// An axis-aligned rectangle on the XZ plane, defined by min/max corners.
struct GroundRect {
    var minX: Float
    var maxX: Float
    var minZ: Float
    var maxZ: Float

    init(x0: Float, x1: Float, z0: Float, z1: Float) {
        minX = Swift.min(x0, x1)
        maxX = Swift.max(x0, x1)
        minZ = Swift.min(z0, z1)
        maxZ = Swift.max(z0, z1)
    }

    var center: SIMD2<Float> { SIMD2((minX + maxX) / 2, (minZ + maxZ) / 2) }
    var size: SIMD2<Float> { SIMD2(maxX - minX, maxZ - minZ) }

    func contains(_ p: SIMD2<Float>, margin: Float = 0) -> Bool {
        p.x >= minX - margin && p.x <= maxX + margin &&
        p.y >= minZ - margin && p.y <= maxZ + margin
    }

    func expanded(by amount: Float) -> GroundRect {
        GroundRect(x0: minX - amount, x1: maxX + amount, z0: minZ - amount, z1: maxZ + amount)
    }

    func union(_ other: GroundRect) -> GroundRect {
        GroundRect(
            x0: Swift.min(minX, other.minX), x1: Swift.max(maxX, other.maxX),
            z0: Swift.min(minZ, other.minZ), z1: Swift.max(maxZ, other.maxZ)
        )
    }
}
