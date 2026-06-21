#!/usr/bin/env swift
//
// generate_icon.swift — renders the App X-Ray app icon (1024×1024 PNG) from
// code with CoreGraphics, then `sips` slices it into the AppIcon.appiconset.
// No assets, no dependencies.
//
//   swift Tools/generate_icon.swift            # writes /tmp/appxray-icon-1024.png
//
// The accompanying shell step (see README/Makefile) resizes it into all the
// macOS icon sizes. Run via Tools/make_appicon.sh to do both at once.
//
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let S = 1024
guard let ctx = CGContext(
    data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Could not create context") }

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

// Rounded-square ("squircle") app-icon shape with macOS-style margins.
let inset: CGFloat = 96
let rect = CGRect(x: inset, y: inset, width: CGFloat(S) - inset * 2, height: CGFloat(S) - inset * 2)
let corner: CGFloat = 200
let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

// Soft drop shadow under the icon body.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: color(0, 0, 0, 0.45))
ctx.addPath(squircle)
ctx.setFillColor(color(0.05, 0.06, 0.10))
ctx.fillPath()
ctx.restoreGState()

// Clip to the squircle, then paint a dark blue gradient body.
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [
    color(0.05, 0.07, 0.13), color(0.08, 0.13, 0.24)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: CGFloat(S)),
                       end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: CGFloat(S) / 2, y: CGFloat(S) / 2)

// Concentric x-ray "scanner" rings.
for (i, radius) in stride(from: 330, through: 150, by: -90).enumerated() {
    ctx.setStrokeColor(color(0.30, 0.78, 0.98, 0.14 + Double(i) * 0.05))
    ctx.setLineWidth(6)
    ctx.addEllipse(in: CGRect(x: center.x - CGFloat(radius), y: center.y - CGFloat(radius),
                              width: CGFloat(radius * 2), height: CGFloat(radius * 2)))
    ctx.strokePath()
}

// The "app under the scanner": a rounded square outline.
let appRect = CGRect(x: center.x - 150, y: center.y - 150, width: 300, height: 300)
let appPath = CGPath(roundedRect: appRect, cornerWidth: 68, cornerHeight: 68, transform: nil)
ctx.addPath(appPath)
ctx.setFillColor(color(0.30, 0.78, 0.98, 0.16))
ctx.fillPath()
ctx.addPath(appPath)
ctx.setStrokeColor(color(0.45, 0.88, 1.0, 0.55))
ctx.setLineWidth(8)
ctx.strokePath()

// Bright horizontal scan line with a soft glow.
ctx.setShadow(offset: .zero, blur: 26, color: color(0.45, 0.90, 1.0, 0.9))
ctx.setStrokeColor(color(0.70, 0.96, 1.0, 1.0))
ctx.setLineWidth(12)
ctx.move(to: CGPoint(x: center.x - 230, y: center.y + 18))
ctx.addLine(to: CGPoint(x: center.x + 230, y: center.y + 18))
ctx.strokePath()
ctx.restoreGState()

// Subtle top highlight for a glassy finish.
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let gloss = CGGradient(colorsSpace: cs, colors: [
    color(1, 1, 1, 0.10), color(1, 1, 1, 0.0)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gloss, start: CGPoint(x: 0, y: CGFloat(S)),
                       end: CGPoint(x: 0, y: CGFloat(S) * 0.6), options: [])
ctx.restoreGState()

let outURL = URL(fileURLWithPath: "/tmp/appxray-icon-1024.png")
guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("Could not create image") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Could not write PNG") }
print("Wrote \(outURL.path) (\(S)×\(S))")
