import AppKit

let outputDirectory = CommandLine.arguments[1]
let canvas: CGFloat = 1024
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let background = NSColor(srgbRed: 0.13, green: 0.12, blue: 0.11, alpha: 1)
let ink = NSColor(srgbRed: 0.96, green: 0.89, blue: 0.75, alpha: 1)

let art = [
    "................",
    "....#..#..#.....",
    "...#..#..#......",
    "....#..#..#.....",
    "...#..#..#......",
    "................",
    "..##########....",
    "..############..",
    "..##########..#.",
    "..##########..#.",
    "..##########..#.",
    "..############..",
    "..##########....",
    "...########.....",
    ".##############.",
    "................",
]

func renderIcon(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 20
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    background.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.current?.shouldAntialias = false
    let cell: CGFloat = 40
    let origin = NSPoint(x: tile.midX - cell * 8, y: tile.midY + cell * 8)
    ink.setFill()
    for (row, line) in art.enumerated() {
        for (column, pixel) in line.enumerated() where pixel == "#" {
            NSRect(x: origin.x + CGFloat(column) * cell, y: origin.y - CGFloat(row + 1) * cell, width: cell, height: cell).fill()
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try! renderIcon(pixels: points * scale).write(to: URL(fileURLWithPath: "\(outputDirectory)/\(name)"))
    }
}
