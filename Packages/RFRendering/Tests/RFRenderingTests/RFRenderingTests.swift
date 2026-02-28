import CoreGraphics
import RFCoreModels
import Testing
@testable import RFRendering

@Test
func svgExportContainsPathCommands() {
    let geometry = SigilGeometry(lines: [SigilLine(startX: 0, startY: 0, endX: 1, endY: 1)])
    let renderer = DefaultSigilRenderService()
    let svg = renderer.exportSVG(geometry: geometry, canvasSize: CGSize(width: 512, height: 512))

    #expect(svg.contains("<svg"))
    #expect(svg.contains("path"))
    #expect(svg.contains("M"))
}

@Test
func compositeRenderSupportsBlendMaskAndEffects() {
    let geometry = SigilGeometry(lines: [
        SigilLine(startX: 0.1, startY: 0.1, endX: 0.9, endY: 0.9),
        SigilLine(startX: 0.9, startY: 0.1, endX: 0.1, endY: 0.9)
    ])

    let layers = [
        DecorLayer(
            name: "Background",
            kind: .background,
            payload: [
                "style": "aurora",
                "blend_mode": "normal",
                "effect_vignette": "0.35"
            ]
        ),
        DecorLayer(
            name: "Geometry",
            kind: .geometry,
            opacity: 0.95,
            payload: [
                "color": "#111111",
                "line_width": "3",
                "brush_style": "ember",
                "effect_glow": "0.6",
                "blend_mode": "overlay",
                "mask_mode": "ring",
                "mask_scale": "0.9",
                "mask_inset": "0.3"
            ]
        ),
        DecorLayer(
            name: "Symbol",
            kind: .symbolOverlay,
            opacity: 0.8,
            payload: [
                "symbol_path": "M 20 20 L 80 20 L 80 80 L 20 80 Z",
                "color": "#9a3412",
                "fill_color": "#f59e0b66",
                "line_width": "2.4",
                "mask_mode": "circle",
                "mask_scale": "0.7",
                "blend_mode": "screen"
            ]
        )
    ]

    let renderer = DefaultSigilRenderService()
    let image = renderer.renderComposite(geometry: geometry, layers: layers, canvasSize: CGSize(width: 512, height: 512))

    #if canImport(UIKit)
    #expect(image.pngData() != nil)
    #elseif canImport(AppKit)
    #expect(image.tiffRepresentation != nil)
    #endif
}

@Test
func compositeRenderSupportsInfernalBackgroundStyle() {
    let geometry = SigilGeometry(lines: [SigilLine(startX: 0.2, startY: 0.8, endX: 0.8, endY: 0.2)])
    let layers = [
        DecorLayer(
            name: "Infernal",
            kind: .background,
            payload: [
                "style": "infernal",
                "effect_vignette": "0.8"
            ]
        ),
        DecorLayer(
            name: "Geometry",
            kind: .geometry,
            payload: [
                "color": "#fff4cc",
                "glow_color": "#ff5a1f",
                "line_width": "3",
                "brush_style": "ember",
                "effect_glow": "0.9"
            ]
        )
    ]

    let renderer = DefaultSigilRenderService()
    let image = renderer.renderComposite(geometry: geometry, layers: layers, canvasSize: CGSize(width: 512, height: 512))

    #if canImport(UIKit)
    #expect(image.pngData() != nil)
    #elseif canImport(AppKit)
    #expect(image.tiffRepresentation != nil)
    #endif
}
