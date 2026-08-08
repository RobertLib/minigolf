//
//  Primitives.swift
//  Minigolf
//
//  Shared meshes for the props a hole is dressed with.
//
//  `MeshResource.generate…` builds vertex data every time it is called, and it
//  is not cheap: a sphere runs about three quarters of a millisecond, a box or
//  a cone about a third, and asking twice for the same size costs the same
//  again. A hole plants a couple of hundred props — hills, trees, chimneys,
//  rocks, mounds, drifts — and paying that per prop is most of the freeze the
//  player sees when a hole opens.
//
//  A sphere of radius 2 is a sphere of radius 1 scaled by two, so none of it
//  needs generating twice: one mesh per shape is built the first time a hole
//  asks for it, and every prop after that is that mesh with a scale on the
//  entity. Scale is free — it rides in the transform the renderer already
//  sends — and props that share a mesh and a material are what the renderer
//  needs to batch their draws.
//
//  Only scenery uses this. Anything the ball can touch keeps its own mesh: a
//  collider is generated from the shape it is given, and scaling an entity
//  scales its collider with it.
//

import Foundation
import RealityKit

enum Prim {

    // One of each, in the size that makes the scale factor read naturally:
    // spheres and cylinders a unit across, boxes a unit on a side.
    private static let unitSphere = MeshResource.generateSphere(radius: 0.5)
    private static let unitBox = MeshResource.generateBox(size: 1)
    private static let unitCone = MeshResource.generateCone(height: 1, radius: 0.5)
    private static let unitCylinder = MeshResource.generateCylinder(height: 1, radius: 0.5)

    static func sphere(radius: Float, material: any RealityKit.Material) -> ModelEntity {
        let entity = ModelEntity(mesh: unitSphere, materials: [material])
        entity.scale = SIMD3(repeating: radius * 2)
        return entity
    }

    static func box(width: Float, height: Float, depth: Float,
                    material: any RealityKit.Material) -> ModelEntity {
        let entity = ModelEntity(mesh: unitBox, materials: [material])
        entity.scale = SIMD3(width, height, depth)
        return entity
    }

    static func cone(height: Float, radius: Float,
                     material: any RealityKit.Material) -> ModelEntity {
        let entity = ModelEntity(mesh: unitCone, materials: [material])
        entity.scale = SIMD3(radius * 2, height, radius * 2)
        return entity
    }

    static func cylinder(height: Float, radius: Float,
                         material: any RealityKit.Material) -> ModelEntity {
        let entity = ModelEntity(mesh: unitCylinder, materials: [material])
        entity.scale = SIMD3(radius * 2, height, radius * 2)
        return entity
    }

    /// A softened box, from a cache keyed on its size.
    ///
    /// This is the one shape the unit-mesh trick cannot do. A corner radius is
    /// a length, not a proportion, so a unit cube scaled into a fern leaf would
    /// come out with a different radius on each of its three sides — square
    /// where the leaf should be a blade. So it is generated at its real size
    /// and kept: the props that want one ask for a handful of fixed sizes,
    /// dozens of times each, and the millimetre the key is rounded to is finer
    /// than anything on screen.
    static func roundedBox(width: Float, height: Float, depth: Float, cornerRadius: Float,
                           material: any RealityKit.Material) -> ModelEntity {
        let key = RoundedBoxKey(width: width, height: height, depth: depth,
                                cornerRadius: cornerRadius)
        let mesh: MeshResource
        if let cached = roundedBoxes[key] {
            mesh = cached
        } else {
            mesh = .generateBox(width: key.width, height: key.height, depth: key.depth,
                                cornerRadius: key.cornerRadius)
            roundedBoxes[key] = mesh
        }
        return ModelEntity(mesh: mesh, materials: [material])
    }

    /// Forces the shared meshes into existence.
    ///
    /// They are `static let`, so each is built the first time something asks for
    /// it — which, left alone, is inside the first hole of a session, on the
    /// very frame that hole is assembled. Touching them from a menu moves that
    /// work to a screen where a long frame costs nothing, the same bargain
    /// `TextureFactory.prewarm` makes. Cheap to call twice: after the first
    /// time it is four pointer reads.
    static func prewarm() {
        _ = unitSphere
        _ = unitBox
        _ = unitCone
        _ = unitCylinder
    }

    private static var roundedBoxes: [RoundedBoxKey: MeshResource] = [:]

    /// Drops the generated corner-radius meshes. The four unit meshes stay:
    /// they are `static let`, they are shared by everything, and between them
    /// they come to a few kilobytes. See `AssetCaches`.
    static func purge() {
        roundedBoxes.removeAll()
    }

    private struct RoundedBoxKey: Hashable {
        var width: Float, height: Float, depth: Float, cornerRadius: Float

        init(width: Float, height: Float, depth: Float, cornerRadius: Float) {
            func mm(_ value: Float) -> Float { (value * 1000).rounded() / 1000 }
            self.width = mm(width)
            self.height = mm(height)
            self.depth = mm(depth)
            self.cornerRadius = mm(cornerRadius)
        }
    }
}
