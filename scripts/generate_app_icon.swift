#!/usr/bin/swift

import AppKit
import Foundation

struct Palette {
    static let backgroundTop = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.14, alpha: 1.0)
    static let backgroundBottom = NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 1.0)
    static let accent = NSColor(calibratedRed: 0.34, green: 0.86, blue: 0.76, alpha: 1.0)
    static let accentSoft = NSColor(calibratedRed: 0.44, green: 0.93, blue: 0.84, alpha: 0.30)
    static let line = NSColor(calibratedWhite: 0.97, alpha: 1.0)
    static let shadow = NSColor(calibratedWhite: 0.0, alpha: 0.28)
}

let iconsetDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default

try? fileManager.removeItem(at: iconsetDirectory)
try fileManager.createDirectory(at: iconsetDirectory, withIntermediateDirectories: true)

let outputSizes: [(filename: String, size: CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for output in outputSizes {
    let image = NSImage(size: NSSize(width: output.size, height: output.size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: output.size, height: output.size)
    let cornerRadius = output.size * 0.23

    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(colors: [Palette.backgroundTop, Palette.backgroundBottom])!
    gradient.draw(in: backgroundPath, angle: -90)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = Palette.shadow
    shadow.shadowBlurRadius = output.size * 0.04
    shadow.shadowOffset = NSSize(width: 0, height: -output.size * 0.012)
    shadow.set()

    let glowRect = rect.insetBy(dx: output.size * 0.18, dy: output.size * 0.18)
    let glow = NSBezierPath(ovalIn: glowRect.offsetBy(dx: 0, dy: output.size * 0.04))
    Palette.accentSoft.setFill()
    glow.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    let strokeWidth = max(2, output.size * 0.058)
    let mouseRect = NSRect(
        x: output.size * 0.26,
        y: output.size * 0.18,
        width: output.size * 0.48,
        height: output.size * 0.62
    )
    let mousePath = NSBezierPath(roundedRect: mouseRect, xRadius: mouseRect.width * 0.34, yRadius: mouseRect.width * 0.34)
    mousePath.lineWidth = strokeWidth
    Palette.line.setStroke()
    mousePath.stroke()

    let wheelPath = NSBezierPath()
    wheelPath.move(to: CGPoint(x: mouseRect.midX, y: mouseRect.maxY - mouseRect.height * 0.16))
    wheelPath.line(to: CGPoint(x: mouseRect.midX, y: mouseRect.maxY - mouseRect.height * 0.36))
    wheelPath.lineWidth = strokeWidth * 0.68
    wheelPath.lineCapStyle = .round
    Palette.accent.setStroke()
    wheelPath.stroke()

    let splitPath = NSBezierPath()
    splitPath.move(to: CGPoint(x: mouseRect.midX, y: mouseRect.maxY))
    splitPath.line(to: CGPoint(x: mouseRect.midX, y: mouseRect.maxY - mouseRect.height * 0.12))
    splitPath.lineWidth = strokeWidth * 0.42
    splitPath.lineCapStyle = .round
    Palette.line.withAlphaComponent(0.85).setStroke()
    splitPath.stroke()

    func curvedArrow(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool, arrowDirection: CGFloat) {
        let path = NSBezierPath()
        path.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        path.lineWidth = strokeWidth * 0.42
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        Palette.accent.setStroke()
        path.stroke()

        let tip = CGPoint(
            x: center.x + cos(arrowDirection) * radius,
            y: center.y + sin(arrowDirection) * radius
        )
        let wing = strokeWidth * 0.9
        let arrow = NSBezierPath()
        arrow.move(to: CGPoint(x: tip.x - cos(arrowDirection - 0.68) * wing, y: tip.y - sin(arrowDirection - 0.68) * wing))
        arrow.line(to: tip)
        arrow.line(to: CGPoint(x: tip.x - cos(arrowDirection + 0.68) * wing, y: tip.y - sin(arrowDirection + 0.68) * wing))
        arrow.lineWidth = strokeWidth * 0.42
        Palette.accent.setStroke()
        arrow.stroke()
    }

    curvedArrow(
        center: CGPoint(x: output.size * 0.36, y: output.size * 0.56),
        radius: output.size * 0.12,
        startAngle: 250,
        endAngle: 110,
        clockwise: false,
        arrowDirection: .pi * 0.66
    )
    curvedArrow(
        center: CGPoint(x: output.size * 0.64, y: output.size * 0.44),
        radius: output.size * 0.12,
        startAngle: 70,
        endAngle: -70,
        clockwise: true,
        arrowDirection: -.pi * 0.18
    )

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode icon PNG"])
    }

    try pngData.write(to: iconsetDirectory.appendingPathComponent(output.filename))
}
