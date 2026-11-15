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
    let cell: CGFloat = 30
    let pixels = art.enumerated().flatMap { row, line in
        line.enumerated().filter { $0.element == "#" }.map { (row: row, column: $0.offset) }
    }
    let rows = pixels.map(\.row), columns = pixels.map(\.column)
    let artWidth = CGFloat(columns.max()! - columns.min()! + 1) * cell
    let artHeight = CGFloat(rows.max()! - rows.min()! + 1) * cell
    let left = tile.midX - artWidth / 2, top = tile.midY + artHeight / 2
    ink.setFill()
    for pixel in pixels {
        NSRect(
            x: left + CGFloat(pixel.column - columns.min()!) * cell,
            y: top - CGFloat(pixel.row - rows.min()! + 1) * cell,
            width: cell, height: cell
        ).fill()
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
