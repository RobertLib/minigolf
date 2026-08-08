//
//  TextureFactory.swift
//  Minigolf
//
//  Procedurally generated textures (mowing stripes, sand speckle, neon grid,
//  sky gradients) so the app needs no bundled image assets.
//
//  Each texture is described as a `Recipe` before it is drawn. That split is
//  what lets `prewarm` do the expensive half — hundreds of CoreGraphics fills
//  and ellipses per texture — on a background thread while a menu is on screen,
//  and hand the finished bitmap to the main actor for upload. `TextureResource`
//  is main-actor only, so the upload itself cannot move; without the split the
//  first hole of a world paid for the whole set inside the frame that built the
//  scene.
//

import Foundation
import CoreGraphics
import UIKit
import RealityKit

enum TextureFactory {

    private static var cache: [String: TextureResource] = [:]

    /// A texture that has been described but not drawn yet.
    private nonisolated struct Recipe {
        let key: String
        let size: Int
        let draw: (CGContext, Int) -> Void
    }

    // MARK: - Drawing and upload

    private nonisolated static func makeContext(size: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    /// Plain CoreGraphics, so this half is safe to run anywhere.
    private nonisolated static func render(_ recipe: Recipe) -> CGImage? {
        guard let ctx = makeContext(size: recipe.size) else { return nil }
        recipe.draw(ctx, recipe.size)
        return ctx.makeImage()
    }

    private static func upload(_ image: CGImage, key: String) -> TextureResource? {
        let resource = try? TextureResource(
            image: image,
            options: .init(semantic: .color)
        )
        if let resource { cache[key] = resource }
        return resource
    }

    private static func resource(_ recipe: Recipe) -> TextureResource? {
        if let cached = cache[recipe.key] { return cached }
        guard let image = render(recipe) else { return nil }
        return upload(image, key: recipe.key)
    }

    // MARK: - Prewarming

    /// Draws and uploads every texture a world needs, ahead of the hole that
    /// wants them. Call it from a screen where a dropped frame costs nothing.
    ///
    /// Already-cached textures are skipped, so calling this twice is free, and a
    /// hole built before the warm-up finishes simply generates what it is
    /// missing the way it always did.
    static func prewarm(course: CourseType) async {
        for recipe in recipes(course: course) {
            guard cache[recipe.key] == nil else { continue }
            let drawn = await Task.detached(priority: .utility) { render(recipe) }.value
            guard let drawn else { continue }
            _ = upload(drawn, key: recipe.key)
            // One upload per turn, so warming a whole world never holds the main
            // thread for longer than a single texture.
            await Task.yield()
        }
    }

    /// Every texture a world needs, in one place. `ThemeMaterials.init` asks for
    /// exactly this set; should the two ever drift apart, the only consequence is
    /// that the odd one out is drawn inline as before.
    private static func recipes(course: CourseType) -> [Recipe] {
        let theme = course.theme
        var list = [
            stripesRecipe(theme.feltTop, theme.feltStripe, key: course.rawValue),
            speckleRecipe(theme.sandColor, theme.sandDetail, key: "sand-\(course.rawValue)"),
            speckleRecipe(theme.mudColor, theme.mudColor.darkened(),
                          key: "mud-\(course.rawValue)", seed: 11, dots: 700),
            cracksRecipe(theme.iceColor, .white, key: course.rawValue),
            cracksRecipe(theme.lavaColor, UIColor(white: 0.06, alpha: 1),
                         key: "lava-\(course.rawValue)"),
            skyRecipe(theme: theme, key: course.rawValue),
        ]
        if theme.emissiveWalls {
            list.append(gridRecipe(theme.groundColor, theme.groundDetail, key: course.rawValue))
        } else {
            list.append(speckleRecipe(theme.groundColor, theme.groundDetail,
                                      key: "ground-\(course.rawValue)", seed: 5, dots: 1400))
        }
        return list
    }

    // MARK: - Course surfaces

    /// Two-tone mowing stripes used for the felt.
    static func stripes(_ a: UIColor, _ b: UIColor, key: String) -> TextureResource? {
        resource(stripesRecipe(a, b, key: key))
    }

    private static func stripesRecipe(_ a: UIColor, _ b: UIColor, key: String) -> Recipe {
        Recipe(key: "stripes-\(key)", size: 256) { ctx, size in
            let bands = 8
            let bandH = CGFloat(size) / CGFloat(bands)
            for i in 0..<bands {
                ctx.setFillColor(((i % 2 == 0) ? a : b).cgColor)
                ctx.fill(CGRect(x: 0, y: CGFloat(i) * bandH, width: CGFloat(size), height: bandH))
            }
            // Soft cross weave for texture interest.
            var rng = SplitMix64(seed: 7)
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.05).cgColor)
            for _ in 0..<220 {
                let x = CGFloat(rng.float(in: 0...1)) * CGFloat(size)
                let y = CGFloat(rng.float(in: 0...1)) * CGFloat(size)
                ctx.fill(CGRect(x: x, y: y, width: 2, height: 2))
            }
        }
    }

    /// Random speckle used for sand and terrain.
    static func speckle(_ base: UIColor, _ detail: UIColor, key: String,
                        seed: UInt64 = 42, dots: Int = 900) -> TextureResource? {
        resource(speckleRecipe(base, detail, key: key, seed: seed, dots: dots))
    }

    private static func speckleRecipe(_ base: UIColor, _ detail: UIColor, key: String,
                                      seed: UInt64 = 42, dots: Int = 900) -> Recipe {
        Recipe(key: "speckle-\(key)", size: 256) { ctx, size in
            ctx.setFillColor(base.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            var rng = SplitMix64(seed: seed)
            for _ in 0..<dots {
                let x = CGFloat(rng.float(in: 0...1)) * CGFloat(size)
                let y = CGFloat(rng.float(in: 0...1)) * CGFloat(size)
                let r = CGFloat(rng.float(in: 0.7...2.4))
                let alpha = CGFloat(rng.float(in: 0.15...0.5))
                ctx.setFillColor(detail.withAlphaComponent(alpha).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
            }
        }
    }

    /// Pale surface veined with cracks — used for ice patches.
    static func cracks(_ base: UIColor, _ line: UIColor, key: String) -> TextureResource? {
        resource(cracksRecipe(base, line, key: key))
    }

    private static func cracksRecipe(_ base: UIColor, _ line: UIColor, key: String) -> Recipe {
        Recipe(key: "cracks-\(key)", size: 256) { ctx, size in
            let s = CGFloat(size)
            ctx.setFillColor(base.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
            var rng = SplitMix64(seed: 21)
            ctx.setLineCap(.round)
            for _ in 0..<14 {
                var x = CGFloat(rng.float(in: 0...1)) * s
                var y = CGFloat(rng.float(in: 0...1)) * s
                var angle = CGFloat(rng.float(in: 0...(2 * .pi)))
                ctx.setStrokeColor(line.withAlphaComponent(CGFloat(rng.float(in: 0.2...0.5))).cgColor)
                ctx.setLineWidth(CGFloat(rng.float(in: 0.8...2.0)))
                ctx.move(to: CGPoint(x: x, y: y))
                for _ in 0..<5 {
                    angle += CGFloat(rng.float(in: -0.9...0.9))
                    let step = CGFloat(rng.float(in: 10...34))
                    x += cos(angle) * step
                    y += sin(angle) * step
                    ctx.addLine(to: CGPoint(x: x, y: y))
                }
                ctx.strokePath()
            }
            // A few frosty highlights so the ice is not flat.
            for _ in 0..<60 {
                let x = CGFloat(rng.float(in: 0...1)) * s
                let y = CGFloat(rng.float(in: 0...1)) * s
                ctx.setFillColor(UIColor.white.withAlphaComponent(0.12).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: 6, height: 6))
            }
        }
    }

    /// Glowing grid lines for the neon world.
    static func grid(_ background: UIColor, _ line: UIColor, key: String) -> TextureResource? {
        resource(gridRecipe(background, line, key: key))
    }

    private static func gridRecipe(_ background: UIColor, _ line: UIColor, key: String) -> Recipe {
        Recipe(key: "grid-\(key)", size: 256) { ctx, size in
            ctx.setFillColor(background.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            let cells = 4
            let step = CGFloat(size) / CGFloat(cells)
            ctx.setStrokeColor(line.cgColor)
            ctx.setLineWidth(2.5)
            for i in 0...cells {
                let p = CGFloat(i) * step
                ctx.move(to: CGPoint(x: p, y: 0))
                ctx.addLine(to: CGPoint(x: p, y: CGFloat(size)))
                ctx.move(to: CGPoint(x: 0, y: p))
                ctx.addLine(to: CGPoint(x: CGFloat(size), y: p))
            }
            ctx.strokePath()
        }
    }

    // MARK: - Sky

    /// Vertical sky gradient (equirect-mapped onto a large sphere), with an
    /// optional sun disc and star field.
    static func sky(theme: CourseTheme, key: String) -> TextureResource? {
        resource(skyRecipe(theme: theme, key: key))
    }

    private static func skyRecipe(theme: CourseTheme, key: String) -> Recipe {
        Recipe(key: "sky-\(key)", size: 512) { ctx, size in
            let s = CGFloat(size)
            let colors = [theme.skyBottom.cgColor, theme.skyHorizon.cgColor, theme.skyTop.cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                colors: colors as CFArray,
                locations: [0.0, 0.45, 1.0]
            )!
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: s),
                options: []
            )
            if theme.starrySky {
                var rng = SplitMix64(seed: 99)
                for _ in 0..<240 {
                    let x = CGFloat(rng.float(in: 0...1)) * s
                    let y = CGFloat(rng.float(in: 0.35...1)) * s
                    let r = CGFloat(rng.float(in: 0.5...1.8))
                    let alpha = CGFloat(rng.float(in: 0.3...0.95))
                    ctx.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                    ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
                }
            } else {
                // Soft sun glow high in the sky.
                let sunCenter = CGPoint(x: s * 0.7, y: s * 0.78)
                let glow = CGGradient(
                    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    colors: [
                        theme.sunColor.withAlphaComponent(0.95).cgColor,
                        theme.sunColor.withAlphaComponent(0.0).cgColor,
                    ] as CFArray,
                    locations: [0, 1]
                )!
                ctx.drawRadialGradient(
                    glow,
                    startCenter: sunCenter, startRadius: 6,
                    endCenter: sunCenter, endRadius: s * 0.16,
                    options: []
                )
                drawClouds(in: ctx, size: s, theme: theme)
            }
        }
    }

    /// Banks of cloud in the band just above the horizon.
    ///
    /// Only the daylit worlds get them — a starfield wants an empty sky. The
    /// tint is mixed from the world's own high sky rather than being white, so
    /// the storm gets slate, the volcano gets ash and the garden gets cumulus
    /// without any of them needing a setting of their own. They are kept to the
    /// lower half of the sphere, where the equirect mapping still stretches
    /// them gently instead of smearing them round the pole.
    private nonisolated static func drawClouds(in ctx: CGContext, size s: CGFloat,
                                               theme: CourseTheme) {
        var top: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (1, 1, 1, 1)
        guard theme.skyTop.getRed(&top.r, green: &top.g, blue: &top.b, alpha: &top.a) else { return }
        let tint = UIColor(red: top.r + (1 - top.r) * 0.72,
                           green: top.g + (1 - top.g) * 0.72,
                           blue: top.b + (1 - top.b) * 0.72, alpha: 1)

        var rng = SplitMix64(seed: 1301)
        for _ in 0..<14 {
            let cx = CGFloat(rng.float(in: 0...1)) * s
            let cy = CGFloat(rng.float(in: 0.52...0.80)) * s
            let scale = CGFloat(rng.float(in: 0.55...1.4))
            let alpha = CGFloat(rng.float(in: 0.18...0.42))
            // A bank is a handful of overlapping puffs; each puff is a radial
            // fade, so the bank has no outline to give away how it was drawn.
            for _ in 0..<6 {
                let px = cx + CGFloat(rng.float(in: -34...34)) * scale
                let py = cy + CGFloat(rng.float(in: -9...9)) * scale
                let radius = CGFloat(rng.float(in: 14...34)) * scale
                let puff = CGGradient(
                    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    colors: [tint.withAlphaComponent(alpha).cgColor,
                             tint.withAlphaComponent(0).cgColor] as CFArray,
                    locations: [0, 1]
                )!
                ctx.drawRadialGradient(puff,
                                       startCenter: CGPoint(x: px, y: py), startRadius: radius * 0.2,
                                       endCenter: CGPoint(x: px, y: py), endRadius: radius,
                                       options: [])
            }
        }
    }
}
