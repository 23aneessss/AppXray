#!/usr/bin/env swift
//
// generate_banner.swift — renders the App X-Ray social-preview banner
// (1280×640 PNG) entirely from code using CoreGraphics. No assets, no deps.
//
//   swift Tools/generate_banner.swift          # writes docs/banner.png
//
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CoreText

let width = 1280, height = 640
let scale = 2
let W = width * scale, H = height * scale

guard let ctx = CGContext(
    data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Could not create context") }

ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))

// Dark vertical gradient background.
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let grad = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1),
    CGColor(red: 0.07, green: 0.10, blue: 0.18, alpha: 1)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: CGFloat(height)),
                       end: CGPoint(x: 0, y: 0), options: [])

// Faint "x-ray" concentric rings on the right — an app icon under the scanner.
let center = CGPoint(x: 1000, y: 320)
for i in stride(from: 220, through: 40, by: -36) {
    ctx.setStrokeColor(CGColor(red: 0.30, green: 0.75, blue: 0.95, alpha: 0.10))
    ctx.setLineWidth(2)
    ctx.addEllipse(in: CGRect(x: center.x - CGFloat(i), y: center.y - CGFloat(i),
                              width: CGFloat(i * 2), height: CGFloat(i * 2)))
    ctx.strokePath()
}
// A rounded-square "app icon" silhouette being scanned.
let iconRect = CGRect(x: center.x - 90, y: center.y - 90, width: 180, height: 180)
let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 40, cornerHeight: 40, transform: nil)
ctx.addPath(iconPath)
ctx.setFillColor(CGColor(red: 0.30, green: 0.75, blue: 0.95, alpha: 0.14))
ctx.fillPath()
// Horizontal scan line.
ctx.setStrokeColor(CGColor(red: 0.40, green: 0.90, blue: 1.0, alpha: 0.65))
ctx.setLineWidth(3)
ctx.move(to: CGPoint(x: center.x - 130, y: center.y + 10))
ctx.addLine(to: CGPoint(x: center.x + 130, y: center.y + 10))
ctx.strokePath()

func draw(_ text: String, font: CTFont, color: CGColor, x: CGFloat, y: CGFloat) {
    let attr = NSAttributedString(string: text, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ])
    let line = CTLineCreateWithAttributedString(attr)
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, ctx)
}

let white = CGColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1)
let accent = CGColor(red: 0.40, green: 0.85, blue: 1.0, alpha: 1)
let dim = CGColor(red: 0.62, green: 0.68, blue: 0.80, alpha: 1)

draw("App X-Ray", font: CTFontCreateWithName("Helvetica-Bold" as CFString, 96, nil),
     color: white, x: 90, y: 380)
draw("See what a Mac app can really do.", font: CTFontCreateWithName("Helvetica" as CFString, 40, nil),
     color: accent, x: 92, y: 312)
draw("Independent privacy & capability auditor · 100% offline",
     font: CTFontCreateWithName("Helvetica" as CFString, 28, nil),
     color: dim, x: 92, y: 250)

// Output
let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Docs")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let outURL = outDir.appendingPathComponent("banner.png")

guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("Could not create image") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Could not write PNG") }

print("Wrote \(outURL.path) (\(width)×\(height))")
