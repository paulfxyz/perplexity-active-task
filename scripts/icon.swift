import AppKit

// Original vector icon: an activity signal, connected neural nodes, and an AI spark.
// macOS's standard 1024 canvas includes a transparent optical margin.
let output = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor.clear.setFill()
NSRect(origin: .zero, size: size).fill()

let tile = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880),
                        xRadius: 196, yRadius: 196)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
shadow.shadowBlurRadius = 22
shadow.shadowOffset = NSSize(width: 0, height: -12)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.15, alpha: 1).setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.27, blue: 0.30, alpha: 1),
           ending: NSColor(calibratedRed: 0.025, green: 0.09, blue: 0.13, alpha: 1))!.draw(in: tile, angle: -65)
NSColor.white.withAlphaComponent(0.13).setStroke()
tile.lineWidth = 3
tile.stroke()

func stroke(_ points: [NSPoint], color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: points[0])
    for point in points.dropFirst() { path.line(to: point) }
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.setStroke()
    path.stroke()
}
let mint = NSColor(calibratedRed: 0.42, green: 0.96, blue: 0.81, alpha: 1)
let white = NSColor(calibratedRed: 0.88, green: 1, blue: 0.97, alpha: 1)
let signal = [NSPoint(x: 210,y: 470), NSPoint(x: 340,y: 470), NSPoint(x: 404,y: 604),
              NSPoint(x: 493,y: 334), NSPoint(x: 575,y: 532), NSPoint(x: 636,y: 470),
              NSPoint(x: 792,y: 470)]
stroke(signal, color: mint.withAlphaComponent(0.12), width: 74)
stroke(signal, color: mint, width: 36)
stroke([NSPoint(x: 282,y: 685), NSPoint(x: 386,y: 744), NSPoint(x: 490,y: 685)],
       color: mint.withAlphaComponent(0.4), width: 9)
for (x, y) in [(282.0,685.0), (386.0,744.0), (490.0,685.0)] {
    mint.setFill()
    NSBezierPath(ovalIn: NSRect(x: x - 15, y: y - 15, width: 30, height: 30)).fill()
}
let spark = NSBezierPath()
spark.move(to: NSPoint(x: 714, y: 802))
spark.curve(to: NSPoint(x: 798, y: 700), controlPoint1: NSPoint(x: 726,y: 727), controlPoint2: NSPoint(x: 738,y: 714))
spark.curve(to: NSPoint(x: 714, y: 598), controlPoint1: NSPoint(x: 738,y: 686), controlPoint2: NSPoint(x: 726,y: 673))
spark.curve(to: NSPoint(x: 630, y: 700), controlPoint1: NSPoint(x: 702,y: 673), controlPoint2: NSPoint(x: 690,y: 686))
spark.curve(to: NSPoint(x: 714, y: 802), controlPoint1: NSPoint(x: 690,y: 714), controlPoint2: NSPoint(x: 702,y: 727))
spark.close()
white.setFill()
spark.fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Icon rendering failed") }
try data.write(to: URL(fileURLWithPath: output))
