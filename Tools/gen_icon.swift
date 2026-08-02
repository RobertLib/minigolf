// Renders the 1024x1024 app icon: a stylized minigolf green with ball,
// hole and flag. Run with: swift gen_icon.swift <output.png>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
let S = CGFloat(size)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

// Background: fresh green gradient
let bg = CGGradient(
    colorsSpace: space,
    colors: [color(0.45, 0.80, 0.35), color(0.13, 0.48, 0.22)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

// Diagonal mowing stripes
ctx.saveGState()
ctx.translateBy(x: S / 2, y: S / 2)
ctx.rotate(by: -.pi / 7)
ctx.setFillColor(color(1, 1, 1, 0.06))
var x: CGFloat = -S
var stripe = 0
while x < S {
    if stripe % 2 == 0 {
        ctx.fill(CGRect(x: x, y: -S, width: 130, height: 2 * S))
    }
    x += 130
    stripe += 1
}
ctx.restoreGState()

// Soft vignette
let vignette = CGGradient(
    colorsSpace: space,
    colors: [color(0, 0, 0, 0), color(0, 0, 0, 0.18)] as CFArray,
    locations: [0.62, 1]
)!
ctx.drawRadialGradient(
    vignette,
    startCenter: CGPoint(x: S / 2, y: S / 2), startRadius: 0,
    endCenter: CGPoint(x: S / 2, y: S / 2), endRadius: S * 0.75,
    options: []
)

// Hole (dark ellipse, right-center)
let holeCenter = CGPoint(x: 660, y: 360)
let holeRect = CGRect(x: holeCenter.x - 150, y: holeCenter.y - 62,
                      width: 300, height: 124)
// rim highlight
ctx.setFillColor(color(0.92, 0.97, 0.9, 0.85))
ctx.fillEllipse(in: holeRect.insetBy(dx: -14, dy: -10))
let holeGrad = CGGradient(
    colorsSpace: space,
    colors: [color(0.10, 0.12, 0.10), color(0.02, 0.03, 0.02)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.addEllipse(in: holeRect)
ctx.clip()
ctx.drawLinearGradient(holeGrad,
                       start: CGPoint(x: holeRect.midX, y: holeRect.maxY),
                       end: CGPoint(x: holeRect.midX, y: holeRect.minY), options: [])
ctx.restoreGState()

// Flag pole
let poleX: CGFloat = 660
ctx.setFillColor(color(0.93, 0.93, 0.95))
ctx.fill(CGRect(x: poleX - 11, y: 360, width: 22, height: 470))
ctx.setFillColor(color(0.75, 0.75, 0.8, 0.6))
ctx.fill(CGRect(x: poleX + 3, y: 360, width: 8, height: 470))
// pole cap
ctx.setFillColor(color(0.95, 0.85, 0.3))
ctx.fillEllipse(in: CGRect(x: poleX - 20, y: 812, width: 40, height: 40))

// Flag (red pennant)
let flagGrad = CGGradient(
    colorsSpace: space,
    colors: [color(0.96, 0.30, 0.24), color(0.80, 0.12, 0.12)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.move(to: CGPoint(x: poleX + 11, y: 820))
ctx.addLine(to: CGPoint(x: poleX + 300, y: 737))
ctx.addLine(to: CGPoint(x: poleX + 11, y: 654))
ctx.closePath()
ctx.clip()
ctx.drawLinearGradient(flagGrad,
                       start: CGPoint(x: poleX, y: 820),
                       end: CGPoint(x: poleX + 300, y: 654), options: [])
ctx.restoreGState()

// Ball shadow
ctx.setFillColor(color(0, 0, 0, 0.22))
ctx.fillEllipse(in: CGRect(x: 175, y: 205, width: 330, height: 110))

// Ball
let ballCenter = CGPoint(x: 330, y: 400)
let ballR: CGFloat = 175
let ballGrad = CGGradient(
    colorsSpace: space,
    colors: [color(1, 1, 1), color(0.78, 0.82, 0.85)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: ballCenter.x - ballR, y: ballCenter.y - ballR,
                          width: ballR * 2, height: ballR * 2))
ctx.clip()
ctx.drawRadialGradient(
    ballGrad,
    startCenter: CGPoint(x: ballCenter.x - 60, y: ballCenter.y + 70), startRadius: 0,
    endCenter: ballCenter, endRadius: ballR * 1.15, options: [.drawsBeforeStartLocation]
)
// dimples
ctx.setFillColor(color(0.55, 0.6, 0.65, 0.35))
for row in 0..<7 {
    for col in 0..<7 {
        let dx = CGFloat(col - 3) * 52 + CGFloat(row % 2) * 26
        let dy = CGFloat(row - 3) * 52
        let d = sqrt(dx * dx + dy * dy)
        if d < ballR - 30 {
            let shrink = 1 - d / (ballR * 1.6)
            let r = 11 * shrink
            ctx.fillEllipse(in: CGRect(x: ballCenter.x + dx - r, y: ballCenter.y + dy - r,
                                       width: r * 2, height: r * 2))
        }
    }
}
ctx.restoreGState()

// Save PNG
let image = ctx.makeImage()!
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"
let url = URL(fileURLWithPath: outPath) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("icon written to \(outPath)")
