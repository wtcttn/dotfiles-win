import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

func parseHex(_ raw: String) -> CGColor {
    var hex = raw
    if hex.hasPrefix("0x") { hex.removeFirst(2) }
    let value = UInt32(hex, radix: 16) ?? 0
    let a, r, g, b: CGFloat
    if hex.count > 6 {
        a = CGFloat((value >> 24) & 0xff) / 255
        r = CGFloat((value >> 16) & 0xff) / 255
        g = CGFloat((value >> 8) & 0xff) / 255
        b = CGFloat(value & 0xff) / 255
    } else {
        a = 1
        r = CGFloat((value >> 16) & 0xff) / 255
        g = CGFloat((value >> 8) & 0xff) / 255
        b = CGFloat(value & 0xff) / 255
    }
    return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func font(named name: String, size: CGFloat, bold: Bool) -> CTFont {
    let base = CTFontCreateWithName(name as CFString, size, nil)
    guard bold else { return base }
    return CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitBold, .traitBold) ?? base
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("usage: gradient render|measure|has ...\n", stderr)
    exit(1)
}

switch args[1] {
case "measure":
    guard args.count >= 5 else { exit(1) }
    let face = font(named: args[2], size: CGFloat(Double(args[3]) ?? 12), bold: args[4] == "bold")
    let data = FileHandle.standardInput.readDataToEndOfFile()
    let text = String(data: data, encoding: .utf8) ?? ""
    let attrs = [kCTFontAttributeName: face] as CFDictionary
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attrs)!)
    var width = CTLineGetTypographicBounds(line, nil, nil, nil)
    if width < 0 { width = 0 }
    print(Int(ceil(width)))

case "has":
    guard args.count >= 4 else { exit(1) }
    let face = font(named: args[2], size: 13, bold: false)
    guard let scalar = UnicodeScalar(UInt32(args[3], radix: 16) ?? 0) else {
        print("no")
        exit(0)
    }
    var utf16 = Array(String(Character(scalar)).utf16)
    var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
    let ok = CTFontGetGlyphsForCharacters(face, &utf16, &glyphs, utf16.count)
    print(ok && glyphs.contains { $0 != 0 } ? "yes" : "no")

case "render":
    guard args.count >= 8 else { exit(1) }
    let width = CGFloat(Double(args[2]) ?? 1)
    let height = CGFloat(Double(args[3]) ?? 1)
    var radius = CGFloat(Double(args[4]) ?? 0)
    let start = parseHex(args[5])
    let end = parseHex(args[6])
    let out = URL(fileURLWithPath: args[7])
    let scale: CGFloat = 2
    let pixelsW = max(Int(width * scale), 1)
    let pixelsH = max(Int(height * scale), 1)
    guard let ctx = CGContext(
        data: nil,
        width: pixelsW,
        height: pixelsH,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { exit(1) }
    ctx.scaleBy(x: scale, y: scale)
    ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    let limit = min(width, height) / 2
    if radius > limit { radius = limit }
    ctx.addPath(CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: width, height: height),
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    ))
    ctx.clip()
    let colors = [start, end] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1]) else {
        exit(1)
    }
    // CSS の 135deg。左上から右下。
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: height),
        end: CGPoint(x: width, y: 0),
        options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
    )
    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { exit(1) }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { exit(1) }

default:
    fputs("unknown command\n", stderr)
    exit(1)
}
