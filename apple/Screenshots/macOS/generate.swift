#!/usr/bin/env swift
//
// generate.swift — macOS App Store screenshot generator for Listen To Wikipedia.
//
// Usage:   swift Screenshots/macOS/generate.swift
// Output:  Screenshots/macOS/*.png  (2560×1600, suitable for 16" MacBook Pro)
//
// Draws the app's visual elements programmatically so no screen-recording
// permission is needed.

import Cocoa

// MARK: - Palette (matches Color+App.swift)

let appBackground  = NSColor(red: 0x1B/255, green: 0x20/255, blue: 0x24/255, alpha: 1)
let dotGreen       = NSColor(red: 0x30/255, green: 0xDA/255, blue: 0x59/255, alpha: 1)
let dotPurple      = NSColor(red: 0xCC/255, green: 0x67/255, blue: 0xCB/255, alpha: 1)
let dotWhite       = NSColor(
    red:   0.80 + 0.20 * (0x1B/255.0),
    green: 0.80 + 0.20 * (0x20/255.0),
    blue:  0.80 + 0.20 * (0x24/255.0),
    alpha: 1
)
let dotGreenDark   = NSColor(red: 0x0E/255, green: 0x41/255, blue: 0x1B/255, alpha: 1)
let dotPurpleDark  = NSColor(red: 0x3D/255, green: 0x1F/255, blue: 0x3D/255, alpha: 1)
let dotWhiteDark   = NSColor(white: 0.38, alpha: 1)
let toastBg        = NSColor(white: 0.15, alpha: 1)
let bannerBlue     = NSColor(red: 100/255, green: 149/255, blue: 237/255, alpha: 1)

// MARK: - Screenshot dimensions (16" MacBook Pro App Store size)

let width  = 2560
let height = 1600
let size   = NSSize(width: width, height: height)

// MARK: - Helpers

func makeContext() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = size  // 1 point = 1 pixel
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    return rep
}

func save(_ rep: NSBitmapImageRep, as name: String) {
    NSGraphicsContext.current = nil
    guard let png = rep.representation(using: .png, properties: [:])
    else { fatalError("PNG conversion failed for \(name)") }
    let url = URL(fileURLWithPath: "Screenshots/macOS/\(name).png")
    try! png.write(to: url)
    print("  ✓ \(url.lastPathComponent)  (\(width)×\(height))")
}

/// Random CGFloat in range, seeded for reproducibility.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

var rng = SeededRNG(seed: 42)

func randomCG(_ range: ClosedRange<CGFloat>) -> CGFloat {
    CGFloat.random(in: range, using: &rng)
}

// MARK: - Bubble data

struct MockBubble {
    let x, y, radius: CGFloat
    let fill: NSColor
    let label: String
    let opacity: CGFloat // simulates age-based fade
}

/// Build a set of realistic bubbles spread across the canvas.
func makeBubbles() -> [MockBubble] {
    struct Template {
        let title: String
        let fill: NSColor
        let radiusRange: ClosedRange<CGFloat>
    }

    let templates: [Template] = [
        // Registered user edits (white)
        .init(title: "Solar eclipse",       fill: dotWhite,      radiusRange: 50...90),
        .init(title: "Albert Einstein",     fill: dotWhite,      radiusRange: 35...65),
        .init(title: "Taylor Swift",        fill: dotWhite,      radiusRange: 70...120),
        .init(title: "Photosynthesis",      fill: dotWhite,      radiusRange: 30...55),
        .init(title: "Rust (programming)",  fill: dotWhite,      radiusRange: 25...45),
        .init(title: "Mount Everest",       fill: dotWhite,      radiusRange: 40...70),
        .init(title: "Tidal locking",       fill: dotWhite,      radiusRange: 30...55),
        .init(title: "Chess",               fill: dotWhite,      radiusRange: 50...85),

        // Anonymous edits (green)
        .init(title: "Oppenheimer",         fill: dotGreen,      radiusRange: 55...90),
        .init(title: "Fibonacci number",    fill: dotGreen,      radiusRange: 25...50),
        .init(title: "Bossa nova",          fill: dotGreen,      radiusRange: 40...65),
        .init(title: "Pacific Ocean",       fill: dotGreen,      radiusRange: 30...55),

        // Bot edits (purple)
        .init(title: "2024 Olympics",       fill: dotPurple,     radiusRange: 30...55),
        .init(title: "Pluto",               fill: dotPurple,     radiusRange: 22...40),
        .init(title: "Hyperloop",           fill: dotPurple,     radiusRange: 25...45),

        // Deletion variants (dark fills)
        .init(title: "Blockchain",          fill: dotWhiteDark,  radiusRange: 35...60),
        .init(title: "Coral reef",          fill: dotGreenDark,  radiusRange: 28...50),
        .init(title: "Esperanto",           fill: dotPurpleDark, radiusRange: 22...38),

        // More registered edits for density
        .init(title: "Renaissance",         fill: dotWhite,      radiusRange: 45...80),
        .init(title: "Kubernetes",          fill: dotWhite,      radiusRange: 25...45),
        .init(title: "Marie Curie",         fill: dotWhite,      radiusRange: 40...65),
        .init(title: "Aurora borealis",     fill: dotWhite,      radiusRange: 45...75),
        .init(title: "The Beatles",         fill: dotWhite,      radiusRange: 55...95),
        .init(title: "Quantum computing",   fill: dotWhite,      radiusRange: 30...55),
        .init(title: "Sahara",              fill: dotGreen,      radiusRange: 35...60),
        .init(title: "Nikola Tesla",        fill: dotWhite,      radiusRange: 40...75),
    ]

    let W = CGFloat(width)
    let H = CGFloat(height)

    return templates.map { t in
        let r = randomCG(t.radiusRange)
        let x = randomCG((r + 40)...(W - r - 40))
        let y = randomCG((r + 40)...(H - r - 40))
        let opacity = randomCG(0.55...1.0)
        return MockBubble(x: x, y: y, radius: r, fill: t.fill, label: t.title, opacity: opacity)
    }
}

// MARK: - Drawing primitives

func fillBackground() {
    appBackground.setFill()
    NSRect(origin: .zero, size: size).fill()
}

func drawBubble(_ b: MockBubble, showLabel: Bool = true) {
    let rect = NSRect(x: b.x - b.radius, y: b.y - b.radius,
                      width: b.radius * 2, height: b.radius * 2)

    // Fill
    let fill = b.fill.withAlphaComponent(b.opacity)
    fill.setFill()
    let path = NSBezierPath(ovalIn: rect)
    path.fill()

    // Subtle stroke
    b.fill.withAlphaComponent(0.15).setStroke()
    path.lineWidth = 1
    path.stroke()

    // Label (only if bubble is large enough)
    if showLabel && b.radius >= 28 {
        let fontSize = min(max(b.radius * 0.24, 11), 20)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingTail

        let labelColor: NSColor
        let darkFills: [NSColor] = [dotWhiteDark, dotGreenDark, dotPurpleDark]
        if darkFills.contains(where: { $0 == b.fill }) {
            // Dark bubble — use the light variant
            if b.fill == dotGreenDark  { labelColor = dotGreen }
            else if b.fill == dotPurpleDark { labelColor = dotPurple }
            else { labelColor = dotWhite }
        } else {
            labelColor = .white
        }

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: labelColor.withAlphaComponent(b.opacity),
            .paragraphStyle: style,
            .shadow: shadow,
        ]
        let str = b.label as NSString
        let textSize = str.size(withAttributes: attrs)
        let maxWidth = b.radius * 1.8
        let textRect = NSRect(
            x: b.x - maxWidth / 2,
            y: b.y - textSize.height / 2,
            width: maxWidth,
            height: textSize.height
        )
        str.draw(in: textRect, withAttributes: attrs)
    }
}

func drawRipple(around b: MockBubble, expansion: CGFloat, opacity: CGFloat, lineWidth: CGFloat) {
    let r = b.radius + expansion
    let rect = NSRect(x: b.x - r, y: b.y - r, width: r * 2, height: r * 2)
    let path = NSBezierPath(ovalIn: rect)
    b.fill.withAlphaComponent(opacity * b.opacity).setStroke()
    path.lineWidth = lineWidth
    path.stroke()
}

func drawGearIcon() {
    // Top-left gear button (macOS: top is high Y in flipped coords, but NSImage is
    // not flipped so top-left = (padding, height - padding - iconSize))
    let iconSize: CGFloat = 36
    let padding: CGFloat = 24
    let cx = padding + iconSize / 2
    let cy = CGFloat(height) - padding - iconSize / 2

    // Dark circle background
    let bgRect = NSRect(x: cx - iconSize/2 - 8, y: cy - iconSize/2 - 8,
                        width: iconSize + 16, height: iconSize + 16)
    NSColor.black.withAlphaComponent(0.5).setFill()
    NSBezierPath(ovalIn: bgRect).fill()

    // Gear symbol using SF Symbols, tinted white
    if let gearImage = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil) {
        let sizeConfig = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
        let combined = sizeConfig.applying(colorConfig)
        let configured = gearImage.withSymbolConfiguration(combined)!
        let imgSize = configured.size
        let drawRect = NSRect(x: cx - imgSize.width/2, y: cy - imgSize.height/2,
                              width: imgSize.width, height: imgSize.height)
        configured.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 0.9)
    }
}

func drawToast(_ title: String) {
    let font = NSFont.systemFont(ofSize: 20, weight: .bold)
    let arrowFont = NSFont.systemFont(ofSize: 18, weight: .bold)
    let style = NSMutableParagraphStyle()
    style.alignment = .center

    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: style,
    ]
    let arrowAttrs: [NSAttributedString.Key: Any] = [
        .font: arrowFont,
        .foregroundColor: NSColor.white.withAlphaComponent(0.7),
    ]

    let titleSize = (title as NSString).size(withAttributes: titleAttrs)
    let arrowStr = " ↗"
    let arrowSize = (arrowStr as NSString).size(withAttributes: arrowAttrs)

    let totalW = titleSize.width + arrowSize.width
    let padH: CGFloat = 32
    let padV: CGFloat = 20
    let toastW = totalW + padH * 2
    let toastH = titleSize.height + padV * 2
    let cornerRadius: CGFloat = 12

    let toastX = (CGFloat(width) - toastW) / 2
    let toastY: CGFloat = 32  // bottom

    // Shadow
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
    shadow.shadowOffset = NSSize(width: 0, height: -3)
    shadow.shadowBlurRadius = 5
    NSGraphicsContext.current?.saveGraphicsState()
    shadow.set()
    let toastRect = NSRect(x: toastX, y: toastY, width: toastW, height: toastH)
    let toastPath = NSBezierPath(roundedRect: toastRect, xRadius: cornerRadius, yRadius: cornerRadius)
    toastBg.setFill()
    toastPath.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Re-fill without shadow on top
    toastBg.setFill()
    toastPath.fill()

    // Text
    let textX = toastX + padH
    let textY = toastY + padV
    (title as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: titleAttrs)
    (arrowStr as NSString).draw(at: NSPoint(x: textX + titleSize.width, y: textY + 1), withAttributes: arrowAttrs)
}

func drawNewUserBanner(_ username: String) {
    let font = NSFont.systemFont(ofSize: 18, weight: .regular)
    let boldFont = NSFont.systemFont(ofSize: 18, weight: .bold)
    let iconFont = NSFont.systemFont(ofSize: 18, weight: .bold)

    let personStr = "👤 "
    let prefix = "Welcome, "
    let arrowStr = " ↗"

    let personAttrs: [NSAttributedString.Key: Any] = [.font: iconFont, .foregroundColor: NSColor.white]
    let prefixAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let nameAttrs: [NSAttributedString.Key: Any] = [.font: boldFont, .foregroundColor: NSColor.white]
    let arrowAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 14, weight: .bold),
                                                      .foregroundColor: NSColor.white.withAlphaComponent(0.7)]

    // Use person SF Symbol
    let personSize = (personStr as NSString).size(withAttributes: personAttrs)
    let prefixSize = (prefix as NSString).size(withAttributes: prefixAttrs)
    let nameSize = (username as NSString).size(withAttributes: nameAttrs)
    let arrowSize = (arrowStr as NSString).size(withAttributes: arrowAttrs)

    let totalW = personSize.width + prefixSize.width + nameSize.width + arrowSize.width
    let padH: CGFloat = 24
    let padV: CGFloat = 16
    let bannerW = totalW + padH * 2
    let bannerH = max(personSize.height, prefixSize.height) + padV * 2

    let bannerX = (CGFloat(width) - bannerW) / 2
    let bannerY = CGFloat(height) - 60 - bannerH  // near top

    // Shadow + fill
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    shadow.shadowOffset = NSSize(width: 0, height: -3)
    shadow.shadowBlurRadius = 5
    NSGraphicsContext.current?.saveGraphicsState()
    shadow.set()
    let rect = NSRect(x: bannerX, y: bannerY, width: bannerW, height: bannerH)
    let path = NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20)
    bannerBlue.setFill()
    path.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    bannerBlue.setFill()
    path.fill()

    // Draw text parts
    var curX = bannerX + padH
    let textY = bannerY + padV

    // Person icon via SF Symbols
    if let personImage = NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil) {
        let sizeConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.white])
        let configured = personImage.withSymbolConfiguration(sizeConfig.applying(colorConfig))!
        let imgSize = configured.size
        let imgRect = NSRect(x: curX, y: textY + (prefixSize.height - imgSize.height) / 2 + 1,
                             width: imgSize.width, height: imgSize.height)
        configured.draw(in: imgRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        curX += imgSize.width + 8
    }

    (prefix as NSString).draw(at: NSPoint(x: curX, y: textY), withAttributes: prefixAttrs)
    curX += prefixSize.width
    (username as NSString).draw(at: NSPoint(x: curX, y: textY), withAttributes: nameAttrs)
    curX += nameSize.width
    (arrowStr as NSString).draw(at: NSPoint(x: curX, y: textY + 2), withAttributes: arrowAttrs)
}

// MARK: - Screenshot 1: Main bubbles view

func generateMainView() {
    let rep = makeContext()
    fillBackground()

    let bubbles = makeBubbles()

    // Draw ripples first (behind bubbles)
    for b in bubbles where b.opacity > 0.7 {
        drawRipple(around: b, expansion: b.radius * 0.15, opacity: 0.25, lineWidth: 1.5)
        drawRipple(around: b, expansion: b.radius * 0.30, opacity: 0.12, lineWidth: 1.0)
    }

    // Draw bubbles
    for b in bubbles {
        drawBubble(b)
    }

    // Gear icon top-left
    drawGearIcon()

    save(rep, as: "01_main")
}

// MARK: - Screenshot 2: Main view with article toast

func generateMainWithToast() {
    rng = SeededRNG(seed: 42) // same bubbles as screenshot 1
    let rep = makeContext()
    fillBackground()

    let bubbles = makeBubbles()

    for b in bubbles where b.opacity > 0.7 {
        drawRipple(around: b, expansion: b.radius * 0.15, opacity: 0.25, lineWidth: 1.5)
        drawRipple(around: b, expansion: b.radius * 0.30, opacity: 0.12, lineWidth: 1.0)
    }

    for b in bubbles {
        drawBubble(b)
    }

    drawGearIcon()
    drawToast("Taylor Swift")

    save(rep, as: "02_toast")
}

// MARK: - Screenshot 3: Main view with new-user banner

func generateMainWithBanner() {
    rng = SeededRNG(seed: 42) // same bubbles
    let rep = makeContext()
    fillBackground()

    let bubbles = makeBubbles()

    for b in bubbles where b.opacity > 0.7 {
        drawRipple(around: b, expansion: b.radius * 0.15, opacity: 0.25, lineWidth: 1.5)
        drawRipple(around: b, expansion: b.radius * 0.30, opacity: 0.12, lineWidth: 1.0)
    }

    for b in bubbles {
        drawBubble(b)
    }

    drawGearIcon()
    drawNewUserBanner("WikiNovice2025")

    save(rep, as: "03_new_user")
}

// MARK: - Main

print("Generating Mac App Store screenshots (\(width)×\(height))…")
generateMainView()
generateMainWithToast()
generateMainWithBanner()
print("Done. Screenshots saved to Screenshots/macOS/")
