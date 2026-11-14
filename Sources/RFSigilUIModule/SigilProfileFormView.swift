import SwiftUI
import RFSigilCoreModels
import RFSigilVisibleGlyph

// MARK: - Profile form (draft editor)
//
// A SwiftUI Form that binds directly to a `SigilProfileDraft`. Field-level
// errors are displayed inline when a draft has been submitted and validation
// produced them. The draft is the single source of truth for what the user has
// typed; the form does not attempt to validate on every keystroke.

public struct SigilProfileFormView: View {
    @Binding var draft: SigilProfileDraft
    /// Field errors from the last validation attempt. Empty when the draft has
    /// not been submitted or when the last submission succeeded.
    var fieldErrors: [SigilDraftValidationError] = []
    /// Called when the user taps "Generate".
    var onGenerate: () -> Void
    /// Called when the user taps "Cancel" (during a loading state).
    var onCancel: (() -> Void)? = nil

    public init(
        draft: Binding<SigilProfileDraft>,
        fieldErrors: [SigilDraftValidationError] = [],
        onGenerate: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._draft = draft
        self.fieldErrors = fieldErrors
        self.onGenerate = onGenerate
        self.onCancel = onCancel
    }

    public var body: some View {
        Form {
            Section {
                TextField("First name", text: $draft.firstName)
                TextField("Last name", text: $draft.lastName)
                errorRow(for: "name")
            } header: {
                Text("Identity")
            } footer: {
                Text("Required: given and family name used for identity resolution.")
            }

            Section {
                TextField("Birth date (YYYY-MM-DD)", text: $draft.birthDate)
                TextField("Birth time (HH:mm)", text: $draft.birthTime)
                TextField("Birth city / place", text: $draft.birthCity)
                errorRow(for: "birthDate")
                errorRow(for: "birthCity")

                TextField("Birth order (e.g. 2 of 3)", text: $draft.birthOrder)
                errorRow(for: "birthOrder")
            } header: {
                Text("Birth")
            } footer: {
                Text("Birth date and city are required. Time and birth order are optional; unknown is allowed.")
            }

            Section {
                TextField("Eyes (e.g. blue, brown, hazel)", text: $draft.eyes)
                TextField("Hair (e.g. black, blond, red)", text: $draft.hair)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Optional. Leave blank when unknown.")
            }

            Section {
                ForEach(draft.heritage.indices, id: \.self) { i in
                    TextField("Heritage \(i + 1)", text: $draft.heritage[i])
                }
                .onDelete { draft.heritage.remove(atOffsets: $0) }
                Button {
                    draft.heritage.append("")
                } label: {
                    Label("Add heritage", systemImage: "plus")
                }
            } header: {
                Text("Heritage")
            } footer: {
                Text("Optional ancestral heritage labels.")
            }

            Section {
                ForEach(draft.ancestralSurnames.indices, id: \.self) { i in
                    TextField("Surname \(i + 1)", text: $draft.ancestralSurnames[i])
                }
                .onDelete { draft.ancestralSurnames.remove(atOffsets: $0) }
                Button {
                    draft.ancestralSurnames.append("")
                } label: {
                    Label("Add surname", systemImage: "plus")
                }
            } header: {
                Text("Ancestral surnames")
            }

            Section {
                ForEach(draft.parentalOrder.indices, id: \.self) { i in
                    TextField("Side: 2 of 3", text: $draft.parentalOrder[i])
                }
                .onDelete { draft.parentalOrder.remove(atOffsets: $0) }
                Button {
                    draft.parentalOrder.append("")
                } label: {
                    Label("Add parental order", systemImage: "plus")
                }
            } header: {
                Text("Parental birth order")
            } footer: {
                Text("Optional. One entry per parental side when known.")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                if let onCancel {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button("Generate", action: onGenerate)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.bar)
        }
    }

    @ViewBuilder
    private func errorRow(for field: String) -> some View {
        if let error = fieldErrors.first(where: { $0.field == field }) {
            Label(error.reason, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Result view (canonical glyph + PersonalCodex)
//
// Displays the generated artifact (canonical glyph SVG) and the readable
// PersonalCodex sections. Raw geometry and diagnostics are kept under an
// "Advanced" disclosure. Unavailable data is shown honestly, not hidden.

public struct SigilResultView: View {
    let artifact: SigilVisibleGlyphArtifact
    let record: SigilPersonalRecordDisplay
    var onSave: (() -> Void)? = nil
    var onExport: (() -> Void)? = nil
    var onFlare: (() -> Void)? = nil

    public init(
        artifact: SigilVisibleGlyphArtifact,
        record: SigilPersonalRecordDisplay,
        onSave: (() -> Void)? = nil,
        onExport: (() -> Void)? = nil,
        onFlare: (() -> Void)? = nil
    ) {
        self.artifact = artifact
        self.record = record
        self.onSave = onSave
        self.onExport = onExport
        self.onFlare = onFlare
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Glyph preview (SVG rendered to a view).
                SigilGlyphSVGView(svg: artifact.svgDocument)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: SigilVisualTheme.cornerRadius, style: .continuous))
                    .accessibilityLabel("Canonical Sigil glyph")

                // Celestial name (the most user-facing result).
                if let name = record.celestialName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Celestial name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }

                // Provenance (concise).
                if let provenance = record.provenanceSummary {
                    Text(provenance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // PersonalCodex sections (readable prose).
                ForEach(record.sections) { section in
                    SigilRecordSectionView(section: section)
                }

                // Advanced detail (raw geometry / diagnostics).
                DisclosureGroup("Advanced detail") {
                    SigilAdvancedDetailView(artifact: artifact)
                }
                .font(.footnote)
            }
            .padding()
        }
        .background { SigilVisualTheme.atmosphere.opacity(0.5) }
        .navigationTitle("Result")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                if let onSave {
                    Button("Save", action: onSave)
                        .buttonStyle(.bordered)
                }
                Spacer()
                if let onFlare {
                    Button("Flare", action: onFlare)
                        .buttonStyle(.bordered)
                }
                if let onExport {
                    Button("Export", action: onExport)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.bar)
        }
    }
}

// MARK: - Record section display model
//
// A lightweight, display-only projection of the PersonalCodex record. The
// view does not import RFSigilPersonalCodex directly; the adapter at the
// app boundary (SigilResultAdapter) maps the real record to this model.

public struct SigilPersonalRecordDisplay: Equatable, Sendable {
    public let celestialName: String?
    public let provenanceSummary: String?
    public let sections: [SigilRecordSection]

    public init(
        celestialName: String? = nil,
        provenanceSummary: String? = nil,
        sections: [SigilRecordSection] = []
    ) {
        self.celestialName = celestialName
        self.provenanceSummary = provenanceSummary
        self.sections = sections
    }
}

public struct SigilRecordSection: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let body: String
    public let isUnavailable: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        isUnavailable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.isUnavailable = isUnavailable
    }
}

private struct SigilRecordSectionView: View {
    let section: SigilRecordSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.headline)
            if section.isUnavailable {
                Text("This section is unavailable for this identity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(section.body)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SigilAdvancedDetailView: View {
    let artifact: SigilVisibleGlyphArtifact

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Candidate index", value: "\(artifact.visibleSigil.styleMetadata.candidateIndex)")
            LabeledContent("Stroke count", value: "\(artifact.visibleSigil.styleMetadata.strokeCount)")
            LabeledContent("Major crossings", value: "\(artifact.visibleSigil.styleMetadata.majorCrossingCount)")
            LabeledContent("Visible signature", value: String(artifact.visibleSigil.visibleSignatureHash.prefix(12)) + "…")
            LabeledContent("Validation", value: artifact.validationDecision.status.rawValue)
        }
    }
}

// MARK: - SVG glyph view
//
// Renders an SVG document as a SwiftUI view. For the MVP, this decodes the
// SVG's path elements and draws them with Canvas. A full SVG renderer is out
// of scope; the canonical glyph uses only `<path>` elements with `d`
// attributes (see SigilVisibleGlyphService.renderSVG).

struct SigilGlyphSVGView: View {
    let svg: String

    var body: some View {
        Canvas { context, size in
            let paths = Self.parsePaths(from: svg)
            let bounds = Self.parseViewBox(from: svg)
            let scale = min(size.width / bounds.width, size.height / bounds.height)
            let offset = CGSize(
                width: (size.width - bounds.width * scale) / 2,
                height: (size.height - bounds.height * scale) / 2
            )
            for path in paths {
                var swiftPath = Path()
                let parsed = Self.parseSVGPathData(path.d)
                for cmd in parsed {
                    switch cmd {
                    case .move(let x, let y):
                        swiftPath.move(to: CGPoint(x: x * scale + offset.width, y: y * scale + offset.height))
                    case .line(let x, let y):
                        swiftPath.addLine(to: CGPoint(x: x * scale + offset.width, y: y * scale + offset.height))
                    case .close:
                        swiftPath.closeSubpath()
                    }
                }
                context.stroke(
                    swiftPath,
                    with: .color(.primary),
                    lineWidth: 2
                )
            }
        }
    }

    private struct SVGPath {
        let d: String
    }

    private enum PathCommand {
        case move(CGFloat, CGFloat)
        case line(CGFloat, CGFloat)
        case close
    }

    private static func parsePaths(from svg: String) -> [SVGPath] {
        var result: [SVGPath] = []
        // Simple regex-free extraction of d="..." attributes.
        let pattern = "d=\""
        var searchRange = svg.startIndex..<svg.endIndex
        while let range = svg.range(of: pattern, range: searchRange) {
            let start = svg.index(range.upperBound, offsetBy: 0)
            guard let end = svg[start...].firstIndex(of: "\"") else { break }
            let d = String(svg[start..<end])
            result.append(SVGPath(d: d))
            searchRange = end..<svg.endIndex
        }
        return result
    }

    private static func parseViewBox(from svg: String) -> CGRect {
        let pattern = "viewBox=\""
        guard let range = svg.range(of: pattern) else {
            return CGRect(x: 0, y: 0, width: 100, height: 100)
        }
        let start = range.upperBound
        guard let end = svg[start...].firstIndex(of: "\"") else {
            return CGRect(x: 0, y: 0, width: 100, height: 100)
        }
        let raw = String(svg[start..<end])
        let parts = raw.split(separator: " ").compactMap { Double($0).map { CGFloat($0) } }
        guard parts.count == 4 else {
            return CGRect(x: 0, y: 0, width: 100, height: 100)
        }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    /// Parses a simple SVG path `d` attribute. Supports M, L, and Z commands
    /// (the subset used by the canonical glyph renderer).
    private static func parseSVGPathData(_ d: String) -> [PathCommand] {
        var result: [PathCommand] = []
        var currentChar: Character = " "
        var currentNumber: String = ""
        var numberBuffer: [CGFloat] = []

        func flushNumber() {
            if let n = Double(currentNumber) {
                numberBuffer.append(CGFloat(n))
            }
            currentNumber = ""
        }

        func flushCommand() {
            switch currentChar {
            case "M", "m":
                if numberBuffer.count >= 2 {
                    result.append(.move(numberBuffer[0], numberBuffer[1]))
                }
            case "L", "l":
                if numberBuffer.count >= 2 {
                    result.append(.line(numberBuffer[0], numberBuffer[1]))
                }
            case "Z", "z":
                result.append(.close)
            default:
                break
            }
            numberBuffer = []
        }

        for char in d {
            if char.isNumber || char == "." || char == "-" {
                currentNumber.append(char)
            } else if char.isLetter {
                flushNumber()
                flushCommand()
                currentChar = char
            } else {
                // Whitespace or delimiter: try to flush a pending number.
                flushNumber()
                // If we have exactly 2 numbers and the current command is M/L,
                // the command applies to each coordinate pair.
                if numberBuffer.count >= 2 {
                    flushCommand()
                }
            }
        }
        flushNumber()
        flushCommand()
        return result
    }
}
