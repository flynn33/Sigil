import Foundation
import RFCoreModels
import RFMythosCatalog

public protocol EditorDocumenting: AnyObject, Sendable {
    var layers: [DecorLayer] { get }
    func reset(with layers: [DecorLayer])
    func addLayer(_ layer: DecorLayer)
    func updateLayer(id: UUID, transform: (inout DecorLayer) -> Void)
    func removeLayer(id: UUID)
    func moveLayer(id: UUID, to index: Int)
}

public final class EditorDocument: EditorDocumenting, @unchecked Sendable {
    public private(set) var layers: [DecorLayer]

    public init(initialLayers: [DecorLayer] = EditorDocument.defaultLayers()) {
        self.layers = initialLayers
    }

    public func reset(with layers: [DecorLayer]) {
        self.layers = layers
    }

    public func addLayer(_ layer: DecorLayer) {
        layers.append(layer)
    }

    public func updateLayer(id: UUID, transform: (inout DecorLayer) -> Void) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }
        transform(&layers[index])
    }

    public func removeLayer(id: UUID) {
        layers.removeAll { $0.id == id }
    }

    public func moveLayer(id: UUID, to index: Int) {
        guard let sourceIndex = layers.firstIndex(where: { $0.id == id }) else { return }
        let layer = layers.remove(at: sourceIndex)
        let destination = max(0, min(index, layers.count))
        layers.insert(layer, at: destination)
    }

    public static func defaultLayers() -> [DecorLayer] {
        [
            DecorLayer(
                name: "Background",
                kind: .background,
                payload: [
                    "color": "#f6f4ef",
                    "style": "solid",
                    "blend_mode": "normal",
                    "effect_vignette": "0"
                ]
            ),
            DecorLayer(
                name: "Geometry",
                kind: .geometry,
                payload: [
                    "color": "#111111",
                    "line_width": "2",
                    "blend_mode": "normal",
                    "brush_style": "clean",
                    "effect_glow": "0"
                ]
            )
        ]
    }
}

public struct MythosOverlayFactory: Sendable {
    private let catalog: MythosCatalogProviding

    public init(catalog: MythosCatalogProviding = DefaultMythosCatalogService()) {
        self.catalog = catalog
    }

    public func overlay(for symbolID: String) -> DecorLayer? {
        for pack in catalog.packs() {
            if let symbol = pack.symbols.first(where: { $0.id == symbolID }) {
                return DecorLayer(
                    name: symbol.name,
                    kind: .symbolOverlay,
                    opacity: 0.92,
                    rotationDegrees: 0,
                    scale: 1,
                    payload: [
                        "symbol_id": symbol.id,
                        "symbol_path": symbol.svgPath,
                        "color": "#ffd58f",
                        "fill_color": "#00000000",
                        "line_width": "2.8",
                        "blend_mode": "screen",
                        "brush_style": "ember",
                        "effect_glow": "0.72",
                        "glow_color": "#ff6a2f"
                    ]
                )
            }
        }
        return nil
    }
}
