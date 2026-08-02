//
//  AimGuideRenderer.swift
//  Minigolf
//
//  Draws the predicted putt as a row of fading dots on the felt, with a ring
//  at the end. The dots are a fixed-size pool: dot *i* always sits the same
//  distance along the line, so its opacity never has to change and the whole
//  guide costs a handful of transform writes per frame.
//

import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class AimGuideRenderer {

    /// Spacing between dots. Fixed rather than stretched, so a longer line
    /// simply means more dots and the player can read strength off the length.
    private static let spacing: Float = 0.09
    private static let dotCount = 40

    private let root = Entity()
    private var dots: [ModelEntity] = []
    private let endMarker = ModelEntity()
    private var normalMaterials: [UnlitMaterial] = []
    private var dropMaterials: [UnlitMaterial] = []
    private var markerNormal = UnlitMaterial(color: .white)
    private var markerDrop = UnlitMaterial(color: .white)
    private var showingDrop: Bool?

    init() {
        let mesh = MeshResource.generateCylinder(height: 0.0022, radius: 0.012)

        normalMaterials = (0..<Self.dotCount).map { index in
            let fade = 1 - Float(index) / Float(Self.dotCount)
            var material = UnlitMaterial(color: .white)
            material.blending = .transparent(opacity: .init(floatLiteral: 0.3 + 0.55 * fade))
            return material
        }
        dropMaterials = (0..<Self.dotCount).map { index in
            let fade = 1 - Float(index) / Float(Self.dotCount)
            var material = UnlitMaterial(color: UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1))
            material.blending = .transparent(opacity: .init(floatLiteral: 0.3 + 0.65 * fade))
            return material
        }

        dots = (0..<Self.dotCount).map { index in
            let dot = ModelEntity(mesh: mesh, materials: [normalMaterials[index]])
            dot.isEnabled = false
            root.addChild(dot)
            return dot
        }

        markerNormal = UnlitMaterial(color: .white)
        markerNormal.blending = .transparent(opacity: .init(floatLiteral: 0.32))
        markerDrop = UnlitMaterial(color: UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1))
        markerDrop.blending = .transparent(opacity: .init(floatLiteral: 0.7))
        endMarker.model = ModelComponent(
            mesh: .generateCylinder(height: 0.0022, radius: 0.05),
            materials: [markerNormal])
        endMarker.isEnabled = false
        root.addChild(endMarker)

        root.isEnabled = false
    }

    func attach(to parent: Entity) {
        parent.addChild(root)
    }

    func hide() {
        root.isEnabled = false
    }

    /// Lays the pool out along `path`, at the height of the felt under the ball.
    func show(path: AimGuidePath, y: Float) {
        guard path.points.count > 1 else {
            hide()
            return
        }
        root.isEnabled = true
        applyStyle(drop: path.endsInHole)

        let total = path.totalLength
        var placed = 0
        var distance = Self.spacing
        while distance < total, placed < dots.count {
            if let point = path.point(at: distance) {
                let dot = dots[placed]
                dot.isEnabled = true
                dot.position = SIMD3(point.x, y, point.y)
                // Dots taper off toward the end of the line.
                let shrink = 1 - 0.45 * (distance / max(total, 0.001))
                dot.scale = SIMD3(repeating: shrink)
            }
            placed += 1
            distance += Self.spacing
        }
        for index in placed..<dots.count {
            dots[index].isEnabled = false
        }

        if let last = path.points.last {
            endMarker.isEnabled = true
            endMarker.position = SIMD3(last.x, y - 0.0003, last.y)
            endMarker.scale = SIMD3(repeating: path.endsInHole ? 1.1 : 0.62)
        } else {
            endMarker.isEnabled = false
        }
    }

    /// Swaps the whole pool between the neutral and the "this one drops" look.
    private func applyStyle(drop: Bool) {
        guard showingDrop != drop else { return }
        showingDrop = drop
        let materials = drop ? dropMaterials : normalMaterials
        for (index, dot) in dots.enumerated() {
            dot.model?.materials = [materials[index]]
        }
        endMarker.model?.materials = [drop ? markerDrop : markerNormal]
    }
}
