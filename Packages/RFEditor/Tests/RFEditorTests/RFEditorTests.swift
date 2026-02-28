import RFCoreModels
import Testing
@testable import RFEditor

@Test
func layerMoveReordersDocument() {
    let document = EditorDocument(initialLayers: [
        DecorLayer(name: "A", kind: .background),
        DecorLayer(name: "B", kind: .geometry)
    ])

    let firstID = document.layers[0].id
    document.moveLayer(id: firstID, to: 1)

    #expect(document.layers[1].id == firstID)
}

@Test
func mythosOverlayFactoryCreatesOverlayLayer() {
    let factory = MythosOverlayFactory()
    let layer = factory.overlay(for: "norse-1")

    #expect(layer != nil)
    #expect(layer?.kind == .symbolOverlay)
    #expect(layer?.opacity == 0.92)
    #expect(layer?.payload["blend_mode"] == "screen")
    #expect(layer?.payload["brush_style"] == "ember")
    #expect(layer?.payload["effect_glow"] == "0.72")
    #expect(layer?.payload["glow_color"] == "#ff6a2f")
}

@Test
func mythosOverlayFactoryLoadsMythicArcanaSymbol() {
    let factory = MythosOverlayFactory()
    let layer = factory.overlay(for: "mythic-1")

    #expect(layer != nil)
    #expect(layer?.name == "Twin Wings")
    #expect(layer?.kind == .symbolOverlay)
}

@Test
func defaultLayersIncludeStudioPayloadDefaults() {
    let layers = EditorDocument.defaultLayers()
    let background = layers.first(where: { $0.kind == .background })
    let geometry = layers.first(where: { $0.kind == .geometry })

    #expect(background?.payload["blend_mode"] == "normal")
    #expect(background?.payload["style"] == "solid")
    #expect(geometry?.payload["line_width"] == "2")
    #expect(geometry?.payload["brush_style"] == "clean")
}
