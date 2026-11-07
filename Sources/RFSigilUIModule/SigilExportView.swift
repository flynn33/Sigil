import SwiftUI
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilVisibleGlyph
import UniformTypeIdentifiers

// MARK: - Export format options
//
// The user selects *what* to export. Each option is a distinct, bounded
// artifact. There is no automatic attachment of diagnostics or profile data;
// the user chooses exactly what is included.

public enum SigilExportOption: String, CaseIterable, Identifiable, Sendable {
    /// The canonical glyph as an SVG document.
    case canonicalSVG
    /// The styled (Flare) glyph as an SVG document.
    case styledSVG
    /// The PersonalCodex record as a JSON document.
    case personalCodexJSON
    /// The PersonalCodex record as a readable Markdown report.
    case personalCodexMarkdown
    /// A redacted diagnostic capture (JSON). Separate deliberate support action.
    case diagnosticJSON

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .canonicalSVG: return "Canonical glyph (SVG)"
        case .styledSVG: return "Styled glyph (SVG)"
        case .personalCodexJSON: return "PersonalCodex (JSON)"
        case .personalCodexMarkdown: return "PersonalCodex (Markdown)"
        case .diagnosticJSON: return "Diagnostics (JSON, redacted)"
        }
    }

    public var fileExtension: String {
        switch self {
        case .canonicalSVG, .styledSVG: return "svg"
        case .personalCodexJSON, .diagnosticJSON: return "json"
        case .personalCodexMarkdown: return "md"
        }
    }

    public var uniformTypeIdentifier: UTType {
        switch self {
        case .canonicalSVG, .styledSVG: return .svg
        case .personalCodexJSON, .diagnosticJSON: return .json
        case .personalCodexMarkdown: return .plainText
        }
    }
}

// MARK: - Export state

public enum SigilExportState: Equatable, Sendable {
    case idle
    case preparing
    case success(URL)
    case failure(String)
}

// MARK: - Export view model

@MainActor
public final class SigilExportViewModel: ObservableObject {
    @Published public var state: SigilExportState = .idle
    @Published public var selectedOption: SigilExportOption = .canonicalSVG
    @Published public var filename: String = "sigil"

    public let artifact: SigilVisibleGlyphArtifact
    public let record: SigilPersonalCodex
    public let glyphService: SigilVisibleGlyphService
    public let flareStyle: SigilFlareStyle?

    public init(
        artifact: SigilVisibleGlyphArtifact,
        record: SigilPersonalCodex,
        glyphService: SigilVisibleGlyphService,
        flareStyle: SigilFlareStyle? = nil
    ) {
        self.artifact = artifact
        self.record = record
        self.glyphService = glyphService
        self.flareStyle = flareStyle
        self.filename = "sigil-\(artifact.visibleSigil.visibleSignatureHash.prefix(8))"
    }

    /// Resolves the export option to a data payload. Returns nil when the
    /// option is not available for the current artifact (e.g. no Flare style
    /// for the styled SVG).
    func resolvePayload() -> Data? {
        switch selectedOption {
        case .canonicalSVG:
            return Data(artifact.svgDocument.utf8)
        case .styledSVG:
            guard let style = flareStyle else { return nil }
            let presentation = glyphService.makeFlarePresentation(
                for: artifact.visibleSigil,
                style: style
            )
            return Data(renderStyledSVG(presentation).utf8)
        case .personalCodexJSON:
            return (try? JSONEncoder().encode(record)) ?? nil
        case .personalCodexMarkdown:
            return Data(renderMarkdown(record).utf8)
        case .diagnosticJSON:
            // Redacted diagnostic: only coarse, non-sensitive facts.
            let diagnostic: [String: String] = [
                "recordType": "personal_codex",
                "outcome": "success",
                "schemaVersion": record.schemaVersion,
                "algorithmIdentity": record.algorithmIdentity,
                "digest": record.digest
            ]
            return (try? JSONEncoder().encode(diagnostic)) ?? nil
        }
    }

    /// Writes the selected payload to a temporary file and returns the URL.
    /// The file is created in the app's temporary directory; the caller is
    /// responsible for presenting it to the user (share sheet / file picker)
    /// and for cleanup after the share completes.
    func export() async -> URL? {
        state = .preparing
        guard let payload = resolvePayload() else {
            state = .failure("The selected export is not available for this artifact.")
            return nil
        }
        let ext = selectedOption.fileExtension
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename).\(ext)")
        do {
            try payload.write(to: url, options: .atomic)
            state = .success(url)
            return url
        } catch {
            state = .failure("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Cleans up a previously exported temporary file.
    func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Renderers

    private func renderStyledSVG(_ presentation: SigilFlarePresentation) -> String {
        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" width=\"400\" height=\"400\">"
        let bg = presentation.style.backgroundID
        if bg != "transparent" {
            let color = bg == "dark" ? "#1a1a2e" : "#f5f5f5"
            svg += "<rect width=\"100\" height=\"100\" fill=\"\(color)\"/>"
        }
        let palette = paletteColor(presentation.style.paletteID)
        let glow = presentation.style.glowStrength
        if glow > 0 {
            svg += "<defs><filter id=\"glow\"><feGaussianBlur stdDeviation=\"\(glow * 2)\"/></filter></defs>"
        }
        for path in presentation.vectorPaths {
            if glow > 0 {
                svg += "<path d=\"\(path.pathData)\" fill=\"none\" stroke=\"\(palette)\" stroke-width=\"2\" opacity=\"\(glow * 0.5)\" filter=\"url(#glow)\"/>"
            }
            svg += "<path d=\"\(path.pathData)\" fill=\"none\" stroke=\"\(palette)\" stroke-width=\"2\"/>"
        }
        svg += "</svg>"
        return svg
    }

    private func paletteColor(_ paletteID: String) -> String {
        switch paletteID {
        case "aurora": return "#2d6a4f"
        case "ember": return "#e76f51"
        case "frost": return "#48cae4"
        case "midnight": return "#4361ee"
        default: return "#1a1a2e"
        }
    }

    private func renderMarkdown(_ record: SigilPersonalCodex) -> String {
        var md = "# Sigil PersonalCodex\n\n"
        md += "**Profile:** \(record.mortalIncarnation.name)\n\n"
        md += "**Celestial name:** \(record.celestialName.celestialName) \(record.celestialName.epithet)\n\n"
        md += "**Digest:** \(record.digest)\n\n"
        md += "---\n\n"
        md += "## Mortal incarnation\n\n\(record.mortalIncarnation.prose)\n\n"
        md += "## Numerology\n\n\(record.numerologyProfile.prose)\n\n"
        md += "## ASH identity\n\n\(record.ashIdentity.prose)\n\n"
        md += "## Plane attunement\n\n\(record.planeAttunement.prose)\n\n"
        md += "## Wolf balance\n\n\(record.wolfBalance.prose)\n\n"
        md += "## Sigil reading\n\n\(record.sigilReading.prose)\n\n"
        md += "---\n\n"
        md += "*Sigil \(record.schemaVersion) / \(record.algorithmIdentity)*\n"
        return md
    }
}

// MARK: - Export view

public struct SigilExportView: View {
    @StateObject var viewModel: SigilExportViewModel
    var onDismiss: () -> Void = {}

    public init(
        viewModel: SigilExportViewModel,
        onDismiss: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("What to export") {
                    Picker("Format", selection: $viewModel.selectedOption) {
                        ForEach(SigilExportOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Filename") {
                    TextField("Filename", text: $viewModel.filename)
                }

                // Preview.
                Section("Preview") {
                    exportPreview
                }

                // Result.
                if case .success(let url) = viewModel.state {
                    Section("Exported") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("File ready", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ShareLink(
                                item: url,
                                preview: SharePreview(viewModel.filename, image: Image(systemName: "doc"))
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                if case .failure(let message) = viewModel.state {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        if case .success(let url) = viewModel.state {
                            viewModel.cleanup(url)
                        }
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        Task { _ = await viewModel.export() }
                    }
                    .disabled(viewModel.state == .preparing)
                }
            }
        }
    }

    @ViewBuilder
    private var exportPreview: some View {
        switch viewModel.selectedOption {
        case .canonicalSVG, .styledSVG:
            Text("The glyph will be exported as an SVG document (\(viewModel.selectedOption.fileExtension)).")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .personalCodexJSON:
            Text("The PersonalCodex record will be exported as a JSON document. This is the full, deterministic record with all sections and provenance.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .personalCodexMarkdown:
            Text("A readable Markdown report of the PersonalCodex sections will be exported.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .diagnosticJSON:
            Text("A redacted diagnostic capture (record type, outcome, schema, digest). No personal data, no profile content, no raw geometry.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
