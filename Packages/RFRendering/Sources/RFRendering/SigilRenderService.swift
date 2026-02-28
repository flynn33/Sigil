import CoreGraphics
import Foundation
import RFCoreModels

#if canImport(UIKit)
import UIKit
public typealias RFImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias RFImage = NSImage
#endif

public protocol SigilRenderService: Sendable {
    func renderGeometry(_ geometry: SigilGeometry, canvasSize: CGSize) -> CGPath
    func renderComposite(geometry: SigilGeometry, layers: [DecorLayer], canvasSize: CGSize) -> RFImage
    func exportSVG(geometry: SigilGeometry, canvasSize: CGSize) -> String
}

public final class DefaultSigilRenderService: SigilRenderService, Sendable {
    public init() {}

    public func renderGeometry(_ geometry: SigilGeometry, canvasSize: CGSize) -> CGPath {
        let path = CGMutablePath()
        for line in geometry.lines {
            let start = CGPoint(x: line.startX * canvasSize.width, y: line.startY * canvasSize.height)
            let end = CGPoint(x: line.endX * canvasSize.width, y: line.endY * canvasSize.height)
            path.move(to: start)
            path.addLine(to: end)
        }
        return path
    }

    public func renderComposite(geometry: SigilGeometry, layers: [DecorLayer], canvasSize: CGSize) -> RFImage {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            drawComposite(geometry: geometry, layers: layers, context: context.cgContext, size: canvasSize)
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        drawComposite(geometry: geometry, layers: layers, context: context, size: canvasSize)
        image.unlockFocus()
        return image
        #endif
    }

    public func exportSVG(geometry: SigilGeometry, canvasSize: CGSize) -> String {
        let pathCommands = geometry.lines.map {
            let sx = $0.startX * canvasSize.width
            let sy = $0.startY * canvasSize.height
            let ex = $0.endX * canvasSize.width
            let ey = $0.endY * canvasSize.height
            return String(format: "M %.4f %.4f L %.4f %.4f", sx, sy, ex, ey)
        }.joined(separator: " ")

        var svgLines = [
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(Int(canvasSize.width))\" height=\"\(Int(canvasSize.height))\" viewBox=\"0 0 \(Int(canvasSize.width)) \(Int(canvasSize.height))\">",
            "  <rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>",
            "  <path d=\"\(pathCommands)\" stroke=\"#111111\" stroke-width=\"2\" fill=\"none\" stroke-linecap=\"round\"/>"
        ]

        svgLines.append("</svg>")
        return svgLines.joined(separator: "\n")
    }

    private func drawComposite(geometry: SigilGeometry, layers: [DecorLayer], context: CGContext, size: CGSize) {
        let hasBackgroundLayer = layers.contains { $0.kind == .background }
        if !hasBackgroundLayer {
            context.saveGState()
            context.setFillColor(CGColor(red: 0.9647, green: 0.9569, blue: 0.9373, alpha: 1.0))
            context.fill(CGRect(origin: .zero, size: size))
            context.restoreGState()
        }

        let hasGeometryLayer = layers.contains { $0.kind == .geometry }

        for layer in layers {
            switch layer.kind {
            case .background:
                drawBackgroundLayer(layer, in: context, size: size)
            case .geometry:
                drawGeometryLayer(layer, geometry: geometry, in: context, size: size)
            case .symbolOverlay:
                drawSymbolOverlayLayer(layer, in: context, size: size)
            }
        }

        if !hasGeometryLayer {
            drawGeometryDefault(geometry, in: context, size: size)
        }
    }

    private func drawGeometryDefault(_ geometry: SigilGeometry, in context: CGContext, size: CGSize) {
        let path = renderGeometry(geometry, canvasSize: size)
        let baseWidth = adaptiveStrokeWidth(segmentCount: geometry.lines.count, requested: 2.2)

        context.saveGState()
        context.setShouldAntialias(true)
        context.setLineJoin(.round)
        context.setLineCap(.round)

        context.setShadow(
            offset: .zero,
            blur: baseWidth * 3.4,
            color: CGColor(gray: 0.06, alpha: 0.30)
        )
        context.addPath(path)
        context.setStrokeColor(CGColor(gray: 0.08, alpha: 0.68))
        context.setLineWidth(baseWidth * 1.95)
        context.strokePath()

        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.addPath(path)
        context.setStrokeColor(CGColor(gray: 0.07, alpha: 0.98))
        context.setLineWidth(baseWidth)
        context.strokePath()

        context.addPath(path)
        context.setStrokeColor(CGColor(gray: 1.0, alpha: 0.24))
        context.setLineWidth(max(0.5, baseWidth * 0.42))
        context.strokePath()

        context.restoreGState()
    }

    private func drawGeometryLayer(_ layer: DecorLayer, geometry: SigilGeometry, in context: CGContext, size: CGSize) {
        let lineWidth = (Double(layer.payload["line_width"] ?? "2") ?? 2).clamped(to: 0.5...24)
        let strokeColor = cgColor(fromHex: layer.payload["color"] ?? "#111111")
        let glowColor = cgColor(fromHex: layer.payload["glow_color"] ?? layer.payload["color"] ?? "#111111")
        var glowStrength = (Double(layer.payload["effect_glow"] ?? "0") ?? 0).clamped(to: 0...1)
        let brushStyle = layer.payload["brush_style", default: "clean"].lowercased()

        if brushStyle == "ember" {
            glowStrength = max(glowStrength, 0.35)
        }
        let adjustedLineWidth = adaptiveStrokeWidth(segmentCount: geometry.lines.count, requested: CGFloat(lineWidth))
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x + size.width * layer.offsetX, y: center.y + size.height * layer.offsetY)
        transform = transform.rotated(by: layer.rotationDegrees * .pi / 180)
        transform = transform.scaledBy(x: layer.scale.clamped(to: 0.1...10), y: layer.scale.clamped(to: 0.1...10))
        transform = transform.translatedBy(x: -center.x, y: -center.y)

        withLayerComposition(layer: layer, context: context, size: size) {
            context.saveGState()
            context.concatenate(transform)

            let path = renderGeometry(geometry, canvasSize: size)

            if glowStrength > 0 {
                context.saveGState()
                context.setShadow(
                    offset: .zero,
                    blur: CGFloat(6 + glowStrength * 22),
                    color: glowColor.copy(alpha: CGFloat(0.75 * glowStrength))
                )
                strokePath(
                    path,
                    in: context,
                    color: glowColor,
                    lineWidth: adjustedLineWidth * CGFloat(1.4 + glowStrength * 2.5),
                    brushStyle: "clean"
                )
                context.restoreGState()
            }

            strokePath(path, in: context, color: strokeColor, lineWidth: adjustedLineWidth, brushStyle: brushStyle)
            context.restoreGState()
        }
    }

    private func drawBackgroundLayer(_ layer: DecorLayer, in context: CGContext, size: CGSize) {
        let style = layer.payload["style", default: "solid"].lowercased()
        let colorHex = layer.payload["color"] ?? "#f6f4ef"
        let baseColor = cgColor(fromHex: colorHex)
        let vignette = (Double(layer.payload["effect_vignette"] ?? "0") ?? 0).clamped(to: 0...1)

        withLayerComposition(layer: layer, context: context, size: size) {
            switch style {
            case "infernal":
                drawLinearGradient(
                    context: context,
                    rect: CGRect(origin: .zero, size: size),
                    colors: [
                        cgColor(fromHex: "#060304"),
                        cgColor(fromHex: "#120507"),
                        cgColor(fromHex: "#2a0708"),
                        cgColor(fromHex: "#0a0405")
                    ]
                )
                drawRadialGlow(
                    context: context,
                    center: CGPoint(x: size.width * 0.5, y: size.height * 0.58),
                    radius: min(size.width, size.height) * 0.7,
                    innerColor: cgColor(fromHex: "#ff7a1f99"),
                    outerColor: cgColor(fromHex: "#00000000")
                )
                drawEmberField(context: context, size: size, count: 260)
            case "fire":
                drawLinearGradient(
                    context: context,
                    rect: CGRect(origin: .zero, size: size),
                    colors: [
                        cgColor(fromHex: "#1c1917"),
                        cgColor(fromHex: "#b91c1c"),
                        cgColor(fromHex: "#f97316"),
                        cgColor(fromHex: "#facc15")
                    ]
                )
            case "aurora":
                drawLinearGradient(
                    context: context,
                    rect: CGRect(origin: .zero, size: size),
                    colors: [
                        cgColor(fromHex: "#081c15"),
                        cgColor(fromHex: "#1b4332"),
                        cgColor(fromHex: "#2d6a4f"),
                        cgColor(fromHex: "#95d5b2")
                    ]
                )
            case "mist":
                drawLinearGradient(
                    context: context,
                    rect: CGRect(origin: .zero, size: size),
                    colors: [
                        cgColor(fromHex: "#e5e7eb"),
                        cgColor(fromHex: "#dbeafe"),
                        cgColor(fromHex: "#e0f2fe")
                    ]
                )
            default:
                context.setFillColor(baseColor)
                context.fill(CGRect(origin: .zero, size: size))
            }

            if vignette > 0 {
                drawVignette(context: context, size: size, strength: vignette)
            }
        }
    }

    private func drawSymbolOverlayLayer(_ layer: DecorLayer, in context: CGContext, size: CGSize) {
        let strokeColor = cgColor(fromHex: layer.payload["color"] ?? "#9a3412")
        let fillColor = cgColor(fromHex: layer.payload["fill_color"] ?? "#00000000")
        let glowColor = cgColor(fromHex: layer.payload["glow_color"] ?? layer.payload["color"] ?? "#9a3412")
        var glowStrength = (Double(layer.payload["effect_glow"] ?? "0") ?? 0).clamped(to: 0...1)
        let lineWidth = CGFloat((Double(layer.payload["line_width"] ?? "2") ?? 2).clamped(to: 0.5...24))
        let brushStyle = layer.payload["brush_style", default: "clean"].lowercased()

        if brushStyle == "ember" {
            glowStrength = max(glowStrength, 0.35)
        }

        let origin = CGPoint(
            x: size.width * (0.5 + layer.offsetX),
            y: size.height * (0.5 + layer.offsetY)
        )
        let sizeMultiplier = min(size.width, size.height) * 0.35 * layer.scale.clamped(to: 0.1...8)

        withLayerComposition(layer: layer, context: context, size: size) {
            context.saveGState()
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: layer.rotationDegrees * .pi / 180)
            context.scaleBy(x: sizeMultiplier / 100, y: sizeMultiplier / 100)
            context.translateBy(x: -50, y: -50)

            if let symbolPath = makePath(fromSVGPath: layer.payload["symbol_path"] ?? "") {
                context.addPath(symbolPath)
                context.setFillColor(fillColor)
                context.fillPath()

                if glowStrength > 0 {
                    context.saveGState()
                    context.setShadow(
                        offset: .zero,
                        blur: CGFloat(4 + glowStrength * 18),
                        color: glowColor.copy(alpha: CGFloat(0.7 * glowStrength))
                    )
                    strokePath(
                        symbolPath,
                        in: context,
                        color: glowColor,
                        lineWidth: lineWidth * CGFloat(100 / sizeMultiplier) * CGFloat(1.4 + glowStrength * 2),
                        brushStyle: "clean"
                    )
                    context.restoreGState()
                }

                strokePath(
                    symbolPath,
                    in: context,
                    color: strokeColor,
                    lineWidth: lineWidth * CGFloat(100 / sizeMultiplier),
                    brushStyle: brushStyle
                )
            } else {
                context.setStrokeColor(strokeColor)
                context.setLineWidth(lineWidth * CGFloat(100 / sizeMultiplier))
                context.strokeEllipse(in: CGRect(x: 10, y: 10, width: 80, height: 80))
            }

            context.restoreGState()
        }
    }

    private func withLayerComposition(layer: DecorLayer, context: CGContext, size: CGSize, draw: () -> Void) {
        context.saveGState()
        context.setAlpha(layer.opacity.clamped(to: 0...1))
        context.setBlendMode(blendMode(from: layer.payload["blend_mode", default: "normal"]))
        applyMaskIfNeeded(layer: layer, context: context, size: size)
        draw()
        context.restoreGState()
    }

    private func blendMode(from value: String) -> CGBlendMode {
        switch value.lowercased() {
        case "multiply":
            .multiply
        case "screen":
            .screen
        case "overlay":
            .overlay
        case "lighten":
            .lighten
        case "plus":
            .plusLighter
        default:
            .normal
        }
    }

    private struct MaskPathSpec {
        var path: CGPath
        var usesEvenOdd: Bool
    }

    private func applyMaskIfNeeded(layer: DecorLayer, context: CGContext, size: CGSize) {
        let mode = layer.payload["mask_mode", default: "none"].lowercased()
        guard mode != "none" else { return }

        guard let mask = makeMaskPath(mode: mode, layer: layer, size: size) else { return }

        let invert = layer.payload["mask_invert", default: "0"] == "1"
        if invert {
            let inverse = CGMutablePath()
            inverse.addRect(CGRect(origin: .zero, size: size))
            inverse.addPath(mask.path)
            context.addPath(inverse)
            context.clip(using: .evenOdd)
            return
        }

        context.addPath(mask.path)
        context.clip(using: mask.usesEvenOdd ? .evenOdd : .winding)
    }

    private func makeMaskPath(mode: String, layer: DecorLayer, size: CGSize) -> MaskPathSpec? {
        let maskScale = (Double(layer.payload["mask_scale"] ?? "1") ?? 1).clamped(to: 0.1...2.0)
        let inset = (Double(layer.payload["mask_inset"] ?? "0.24") ?? 0.24).clamped(to: 0...0.48)

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let baseWidth = size.width * 0.88 * maskScale
        let baseHeight = size.height * 0.88 * maskScale
        let rect = CGRect(
            x: center.x - baseWidth / 2,
            y: center.y - baseHeight / 2,
            width: baseWidth,
            height: baseHeight
        )

        switch mode {
        case "circle":
            let path = CGMutablePath()
            path.addEllipse(in: rect)
            return MaskPathSpec(path: path, usesEvenOdd: false)
        case "diamond":
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: center.y))
            path.closeSubpath()
            return MaskPathSpec(path: path, usesEvenOdd: false)
        case "ring":
            let path = CGMutablePath()
            path.addEllipse(in: rect)

            let innerRect = rect.insetBy(dx: rect.width * inset, dy: rect.height * inset)
            path.addEllipse(in: innerRect)
            return MaskPathSpec(path: path, usesEvenOdd: true)
        case "vertical":
            let path = CGMutablePath()
            let stripeWidth = max(8.0, rect.width / 9)
            let gapWidth = max(6.0, stripeWidth * 0.5)

            var x = rect.minX
            while x < rect.maxX {
                path.addRect(CGRect(x: x, y: rect.minY, width: stripeWidth, height: rect.height))
                x += stripeWidth + gapWidth
            }
            return MaskPathSpec(path: path, usesEvenOdd: false)
        default:
            return nil
        }
    }

    private func strokePath(
        _ path: CGPath,
        in context: CGContext,
        color: CGColor,
        lineWidth: CGFloat,
        brushStyle: String
    ) {
        context.saveGState()

        switch brushStyle {
        case "etched":
            context.addPath(path)
            context.setStrokeColor(color)
            context.setLineDash(phase: 0, lengths: [8, 4])
            context.setLineWidth(max(0.5, lineWidth * 0.9))
            context.setLineJoin(.bevel)
            context.setLineCap(.butt)
            context.strokePath()
        case "rune":
            context.addPath(path)
            context.setStrokeColor(color.copy(alpha: 0.85) ?? color)
            context.setLineWidth(lineWidth * 1.3)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.strokePath()

            context.addPath(path)
            context.setStrokeColor(color)
            context.setLineWidth(max(0.45, lineWidth * 0.72))
            context.strokePath()

            context.addPath(path)
            context.setStrokeColor(color.copy(alpha: 0.35) ?? color)
            context.setLineWidth(max(0.4, lineWidth * 0.36))
            context.strokePath()
        default:
            context.addPath(path)
            context.setStrokeColor(color)
            context.setLineWidth(lineWidth)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.strokePath()

            context.addPath(path)
            context.setStrokeColor(color.copy(alpha: 0.30) ?? color)
            context.setLineWidth(max(0.4, lineWidth * 0.4))
            context.strokePath()
        }
        context.restoreGState()
    }

    private func adaptiveStrokeWidth(segmentCount: Int, requested: CGFloat) -> CGFloat {
        let safeCount = max(1, segmentCount)
        let complexity = log(Double(safeCount) + 1.0)
        let multiplier = (1.36 - complexity * 0.08).clamped(to: 0.74...1.34)
        let tuned = requested * CGFloat(multiplier)
        return min(max(tuned, 0.7), 24.0)
    }

    private func drawLinearGradient(context: CGContext, rect: CGRect, colors: [CGColor]) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: stride(from: 0.0, through: 1.0, by: 1.0 / Double(max(colors.count - 1, 1))).map { CGFloat($0) }
        )

        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                options: []
            )
        } else {
            context.setFillColor(CGColor(gray: 0.95, alpha: 1.0))
            context.fill(rect)
        }
    }

    private func drawRadialGlow(
        context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        innerColor: CGColor,
        outerColor: CGColor
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [innerColor, outerColor]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) else {
            return
        }

        context.saveGState()
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )
        context.restoreGState()
    }

    private func drawEmberField(context: CGContext, size: CGSize, count: Int) {
        context.saveGState()
        context.setBlendMode(.plusLighter)

        let width = max(size.width, 1)
        let height = max(size.height, 1)

        for index in 0..<count {
            let seed = Double(index)
            let xNorm = pseudoRandom(seed * 1.23 + 11.0)
            let yNorm = pseudoRandom(seed * 2.17 + 53.0)
            let intensityNoise = pseudoRandom(seed * 3.11 + 89.0)

            let centerFalloff = max(0, 1 - abs(yNorm - 0.58) * 1.75)
            let alpha = (0.03 + intensityNoise * 0.32) * centerFalloff
            if alpha < 0.02 {
                continue
            }

            let emberSize = 0.7 + pseudoRandom(seed * 4.01 + 21.0) * 2.8
            let x = xNorm * width
            let y = yNorm * height

            let warm = 0.75 + pseudoRandom(seed * 5.07 + 8.0) * 0.25
            let color = CGColor(
                red: CGFloat(warm),
                green: CGFloat(0.26 + warm * 0.42),
                blue: CGFloat(0.05 + warm * 0.08),
                alpha: CGFloat(alpha)
            )

            context.setFillColor(color)
            context.fillEllipse(in: CGRect(x: x, y: y, width: emberSize, height: emberSize))

            if pseudoRandom(seed * 7.91 + 144.0) > 0.8 {
                context.setStrokeColor(color)
                context.setLineWidth(max(0.35, emberSize * 0.35))
                context.move(to: CGPoint(x: x + emberSize * 0.5, y: y))
                context.addLine(to: CGPoint(x: x + emberSize * 0.5, y: y + emberSize * (2.2 + pseudoRandom(seed * 9.17 + 34.0))))
                context.strokePath()
            }
        }

        context.restoreGState()
    }

    private func pseudoRandom(_ input: Double) -> Double {
        let value = sin(input * 12.9898 + 78.233) * 43758.5453
        return value - floor(value)
    }

    private func drawVignette(context: CGContext, size: CGSize, strength: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = max(size.width, size.height) * 0.78

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.0),
            CGColor(red: 0, green: 0, blue: 0, alpha: CGFloat(strength * 0.55))
        ]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.55, 1.0]) {
            context.saveGState()
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: radius * 0.15,
                endCenter: center,
                endRadius: radius,
                options: []
            )
            context.restoreGState()
        }
    }

    private func makePath(fromSVGPath path: String) -> CGPath? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tokens = trimmed
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        let mutablePath = CGMutablePath()
        var index = 0
        var currentCommand = ""
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero

        func readDouble() -> Double? {
            guard index < tokens.count else { return nil }
            let token = tokens[index]
            index += 1
            return Double(token)
        }

        while index < tokens.count {
            let token = tokens[index]
            if token.count == 1, let scalar = token.unicodeScalars.first, CharacterSet.letters.contains(scalar) {
                currentCommand = token
                index += 1
            }

            switch currentCommand {
            case "M", "m":
                guard let x = readDouble(), let y = readDouble() else {
                    return mutablePath.isEmpty ? nil : mutablePath.copy()
                }
                currentPoint = CGPoint(x: x, y: y)
                startPoint = currentPoint
                mutablePath.move(to: currentPoint)
                currentCommand = currentCommand == "M" ? "L" : "l"
            case "L", "l":
                guard let x = readDouble(), let y = readDouble() else {
                    return mutablePath.isEmpty ? nil : mutablePath.copy()
                }
                currentPoint = CGPoint(x: x, y: y)
                mutablePath.addLine(to: currentPoint)
            case "H", "h":
                guard let x = readDouble() else {
                    return mutablePath.isEmpty ? nil : mutablePath.copy()
                }
                currentPoint = CGPoint(x: x, y: currentPoint.y)
                mutablePath.addLine(to: currentPoint)
            case "V", "v":
                guard let y = readDouble() else {
                    return mutablePath.isEmpty ? nil : mutablePath.copy()
                }
                currentPoint = CGPoint(x: currentPoint.x, y: y)
                mutablePath.addLine(to: currentPoint)
            case "Z", "z":
                mutablePath.addLine(to: startPoint)
                mutablePath.closeSubpath()
            default:
                index += 1
            }
        }

        return mutablePath.copy()
    }

    private func cgColor(fromHex hex: String) -> CGColor {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        if raw.count == 8, let int = Int(raw, radix: 16) {
            let red = CGFloat((int >> 24) & 0xFF) / 255
            let green = CGFloat((int >> 16) & 0xFF) / 255
            let blue = CGFloat((int >> 8) & 0xFF) / 255
            let alpha = CGFloat(int & 0xFF) / 255
            return CGColor(red: red, green: green, blue: blue, alpha: alpha)
        }

        if raw.count == 6, let int = Int(raw, radix: 16) {
            let red = CGFloat((int >> 16) & 0xFF) / 255
            let green = CGFloat((int >> 8) & 0xFF) / 255
            let blue = CGFloat(int & 0xFF) / 255
            return CGColor(red: red, green: green, blue: blue, alpha: 1)
        }

        return CGColor(gray: 0.9, alpha: 1)
    }
}
