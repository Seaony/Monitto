import AppKit

func fill(_ rect: NSRect, _ color: NSColor) {
    color.setFill()
    rect.fill()
}

func text(_ value: String, _ x: CGFloat, _ y: CGFloat) {
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: NSColor(white: 0.18, alpha: 1)
    ])
}

func draw(_ image: NSImage, _ x: CGFloat, _ y: CGFloat, _ scale: CGFloat, dark: Bool = false) {
    let bounds = NSRect(x: x, y: y, width: image.size.width * scale, height: image.size.height * scale)
    let tinted = NSImage(size: bounds.size, flipped: false) { frame in
        fill(frame, dark ? .white : .black)
        image.draw(in: frame, from: .zero, operation: .destinationIn, fraction: 1)
        return true
    }
    tinted.draw(in: bounds)
}

let runner = CommandLine.arguments[1]
let input = URL(fileURLWithPath: "Monitto/Assets.xcassets/Runners/\(runner)")
let entries = try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil)
let frames = entries.filter { $0.pathExtension == "imageset" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    .map { NSImage(contentsOf: $0.appendingPathComponent("frame.svg"))! }
let frameWidth = frames[0].size.width
let cell = max(152, frameWidth * 8 + 16)
let width = cell * CGFloat(frames.count) + 32
let size = NSSize(width: width, height: 374)
let canvas = NSImage(size: size, flipped: false) { bounds in
    fill(bounds, .white)
    text("\(runner.capitalized)   ·   8×", 16, 345)
    for (index, image) in frames.enumerated() {
        let x = 16 + CGFloat(index) * cell
        fill(NSRect(x: x, y: 198, width: cell - 4, height: 134), NSColor(white: 0.95, alpha: 1))
        draw(image, x + 6, 201, 8)
        text(String(index + 1), x + 6, 177)
    }
    for (index, scale) in [1.0, 2.0].enumerated() {
        let y = CGFloat(108 - 62 * index)
        text("\(Int(scale))×", 16, y + 41)
        for (mode, dark) in [false, true].enumerated() {
            let start = 16 + CGFloat(mode) * (width / 2 - 12)
            let strip = NSRect(x: start, y: y, width: width / 2 - 20, height: 38)
            fill(strip, NSColor(white: dark ? 0.16 : 0.90, alpha: 1))
            for (frame, image) in frames.enumerated() {
                draw(image, start + 8 + CGFloat(frame) * (frameWidth * scale + 8),
                     y + floor((38 - 16 * scale) / 2), scale, dark: dark)
            }
        }
    }
    text("Loop", 16, 12)
    draw(frames.last!, 64, 8, 2)
    draw(frames.first!, 72 + frameWidth * 2, 8, 2)
    return true
}
let output = URL(fileURLWithPath: "/tmp/monitto-runner-preview")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let bitmap = NSBitmapImageRep(data: canvas.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(runner).png"))
