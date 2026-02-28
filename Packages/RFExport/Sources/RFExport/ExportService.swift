import Foundation
import RFCoreModels
import RFRendering

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public protocol ExportService: Sendable {
    func exportImage(
        format: ImageExportFormat,
        settings: ImageExportSettings,
        geometry: SigilGeometry,
        layers: [DecorLayer]
    ) throws -> Data

    func exportGeometryJSON(from result: SigilResult) throws -> Data
    func exportGeometrySVG(geometry: SigilGeometry, settings: ImageExportSettings) -> String
    func exportMetadataManifest(
        from result: SigilResult,
        format: ImageExportFormat,
        settings: ImageExportSettings,
        exportedAt: Date
    ) throws -> Data
}

public enum ExportError: Error {
    case imageEncodingFailed
}

public final class DefaultExportService: ExportService, Sendable {
    private let renderer: SigilRenderService

    public init(renderer: SigilRenderService = DefaultSigilRenderService()) {
        self.renderer = renderer
    }

    public func exportImage(
        format: ImageExportFormat,
        settings: ImageExportSettings,
        geometry: SigilGeometry,
        layers: [DecorLayer]
    ) throws -> Data {
        let normalized = settings.normalized()
        let size = CGSize(width: normalized.width, height: normalized.height)
        let effectiveLayers = applyBackgroundOverrideIfNeeded(layers: layers, settings: normalized)
        let image = renderer.renderComposite(geometry: geometry, layers: effectiveLayers, canvasSize: size)

        switch format {
        case .png:
            guard let data = encodePNG(image) else { throw ExportError.imageEncodingFailed }
            return data
        case .jpeg:
            guard let data = encodeJPEG(image, quality: normalized.jpegQuality) else { throw ExportError.imageEncodingFailed }
            return data
        }
    }

    public func exportGeometryJSON(from result: SigilResult) throws -> Data {
        let envelope = GeometryExportEnvelope(
            schemaVersion: RFConstants.geometrySchemaVersion,
            engineDataVersion: result.engineDataVersion,
            pipelineVersion: result.pipelineVersion,
            vector: result.vector,
            bits9: result.bits9,
            parity: result.bits9.parity,
            lsystem: result.lsystem,
            geometry: result.geometry
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    public func exportGeometrySVG(geometry: SigilGeometry, settings: ImageExportSettings) -> String {
        let normalized = settings.normalized()
        return renderer.exportSVG(geometry: geometry, canvasSize: CGSize(width: normalized.width, height: normalized.height))
    }

    public func exportMetadataManifest(
        from result: SigilResult,
        format: ImageExportFormat,
        settings: ImageExportSettings,
        exportedAt: Date = .now
    ) throws -> Data {
        let manifest = ExportMetadataManifest(
            profileID: result.profileID,
            geometryHash: result.geometryHash,
            pipelineVersion: result.pipelineVersion,
            engineDataVersion: result.engineDataVersion,
            exportFormat: format,
            settings: settings.normalized(),
            exportedAt: exportedAt
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(manifest)
    }

    private func applyBackgroundOverrideIfNeeded(
        layers: [DecorLayer],
        settings: ImageExportSettings
    ) -> [DecorLayer] {
        guard
            let override = settings.backgroundHexOverride?.trimmingCharacters(in: .whitespacesAndNewlines),
            !override.isEmpty
        else {
            return layers
        }

        var copied = layers
        if let index = copied.firstIndex(where: { $0.kind == .background }) {
            copied[index].payload["color"] = override
        } else {
            copied.insert(DecorLayer(name: "Background", kind: .background, payload: ["color": override]), at: 0)
        }
        return copied
    }

    private func encodePNG(_ image: RFImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    private func encodeJPEG(_ image: RFImage, quality: Double) -> Data? {
        #if canImport(UIKit)
        return image.jpegData(compressionQuality: quality)
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #endif
    }
}
