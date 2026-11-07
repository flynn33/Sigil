import SwiftUI
import RFSigilCoreModels
import RFSigilVisibleGlyph

// MARK: - Flare presentation (approved palettes / backgrounds)
//
// Flare is a *presentation-only* layer on top of the canonical glyph. The
// canonical identity, vector paths, and digests are never modified by Flare;
// only the style (palette, glow, background) changes. The approved scope is
// a small, fixed set of palettes and backgrounds — not an arbitrary color
// picker. This keeps Flare within the product's recorded design boundary.

public enum SigilFlarePalette: String, CaseIterable, Identifiable, Sendable {
    case canonical
    case aurora
    case ember
    case frost
    case midnight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .canonical: return "Canonical"
        case .aurora: return "Aurora"
        case .ember: return "Ember"
        case .frost: return "Frost"
        case .midnight: return "Midnight"
        }
    }

    /// The palette ID stored in the canonical `SigilFlareStyle`.
    public var paletteID: String { rawValue }

    /// A representative SwiftUI color for the palette (used in the editor UI).
    /// The actual SVG rendering uses the palette ID; this is for the editor.
    public var previewColor: Color {
        switch self {
        case .canonical: return .primary
        case .aurora: return .green
        case .ember: return .orange
        case .frost: return .cyan
        case .midnight: return .indigo
        }
    }
}

public enum SigilFlareBackground: String, CaseIterable, Identifiable, Sendable {
    case transparent
    case light
    case dark

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .transparent: return "Transparent"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    public var backgroundID: String { rawValue }

    public var previewColor: Color {
        switch self {
        case .transparent: return .clear
        case .light: return Color(white: 0.95)
        case .dark: return Color(white: 0.1)
        }
    }
}

// MARK: - Flare editor state

public struct SigilFlareEditorState: Equatable, Sendable {
    public var palette: SigilFlarePalette
    public var glowStrength: Double
    public var background: SigilFlareBackground
    /// True when the user has made edits that have not been saved.
    public var isDirty: Bool

    public init(
        palette: SigilFlarePalette = .canonical,
        glowStrength: Double = 0,
        background: SigilFlareBackground = .transparent,
        isDirty: Bool = false
    ) {
        self.palette = palette
        self.glowStrength = glowStrength
        self.background = background
        self.isDirty = isDirty
    }

    /// The canonical (unstyled) state.
    public static var canonical: SigilFlareEditorState {
        SigilFlareEditorState(
            palette: .canonical,
            glowStrength: 0,
            background: .transparent,
            isDirty: false
        )
    }
}

// MARK: - Flare editor view model

@MainActor
public final class SigilFlareEditorViewModel: ObservableObject {
    @Published public var state: SigilFlareEditorState
    /// The canonical presentation (always available, never modified by Flare).
    public let canonicalPresentation: SigilFlarePresentation
    /// The current styled presentation (recomputed on every state change).
    @Published public private(set) var styledPresentation: SigilFlarePresentation
    public let glyphService: SigilVisibleGlyphService
    public let visibleSigil: VisibleCanonicalSigil

    public init(
        visibleSigil: VisibleCanonicalSigil,
        glyphService: SigilVisibleGlyphService,
        initialStyle: SigilFlareStyle? = nil
    ) {
        self.visibleSigil = visibleSigil
        self.glyphService = glyphService
        let style = initialStyle ?? SigilFlareStyle(
            paletteID: SigilFlarePalette.canonical.paletteID,
            glowStrength: 0,
            backgroundID: SigilFlareBackground.transparent.backgroundID
        )
        self.canonicalPresentation = glyphService.makeFlarePresentation(
            for: visibleSigil,
            style: SigilFlareStyle(
                paletteID: SigilFlarePalette.canonical.paletteID,
                glowStrength: 0,
                backgroundID: SigilFlareBackground.transparent.backgroundID
            )
        )
        self.styledPresentation = glyphService.makeFlarePresentation(
            for: visibleSigil,
            style: style
        )
        self.state = SigilFlareEditorState(
            palette: SigilFlarePalette(rawValue: style.paletteID) ?? .canonical,
            glowStrength: style.glowStrength,
            background: SigilFlareBackground(rawValue: style.backgroundID) ?? .transparent,
            isDirty: false
        )
    }

    public func updatePalette(_ palette: SigilFlarePalette) {
        state.palette = palette
        state.isDirty = true
        rebuildStyled()
    }

    public func updateGlow(_ strength: Double) {
        state.glowStrength = strength
        state.isDirty = true
        rebuildStyled()
    }

    public func updateBackground(_ background: SigilFlareBackground) {
        state.background = background
        state.isDirty = true
        rebuildStyled()
    }

    public func returnToCanonical() {
        state = .canonical
        rebuildStyled()
    }

    public func discardChanges() {
        state = .canonical
        rebuildStyled()
    }

    /// Saves the current style. Returns the updated presentation.
    /// The canonical identity/vector/digest are preserved (Flare is
    /// presentation-only); only the style changes.
    @discardableResult
    public func save() -> SigilFlarePresentation {
        state.isDirty = false
        return styledPresentation
    }

    private func rebuildStyled() {
        let style = SigilFlareStyle(
            paletteID: state.palette.paletteID,
            glowStrength: state.glowStrength,
            backgroundID: state.background.backgroundID
        )
        styledPresentation = glyphService.makeFlarePresentation(
            for: visibleSigil,
            style: style
        )
    }
}

// MARK: - Flare editor view
//
// A side-by-side comparison: canonical (left) vs. styled (right), with
// controls for palette, glow, and background. "Return to canonical" resets
// the style. "Save" commits the style (the canonical data is never touched).

public struct SigilFlareEditorView: View {
    @StateObject var viewModel: SigilFlareEditorViewModel
    var onSave: ((SigilFlarePresentation) -> Void)? = nil
    var onDismiss: () -> Void = {}

    public init(
        viewModel: SigilFlareEditorViewModel,
        onSave: ((SigilFlarePresentation) -> Void)? = nil,
        onDismiss: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Side-by-side preview.
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text("Canonical")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SigilFlareGlyphView(presentation: viewModel.canonicalPresentation)
                        .frame(height: 160)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(spacing: 6) {
                    Text("Styled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SigilFlareGlyphView(presentation: viewModel.styledPresentation)
                        .frame(height: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.state.background.previewColor)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)

            // Controls.
            Form {
                Section("Palette") {
                    Picker("Palette", selection: Binding(
                        get: { viewModel.state.palette },
                        set: { viewModel.updatePalette($0) }
                    )) {
                        ForEach(SigilFlarePalette.allCases) { palette in
                            Text(palette.displayName).tag(palette)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Glow") {
                    Slider(
                        value: Binding(
                            get: { viewModel.state.glowStrength },
                            set: { viewModel.updateGlow($0) }
                        ),
                        in: 0...1,
                        step: 0.05
                    ) {
                        Text("Glow strength")
                    }
                }

                Section("Background") {
                    Picker("Background", selection: Binding(
                        get: { viewModel.state.background },
                        set: { viewModel.updateBackground($0) }
                    )) {
                        ForEach(SigilFlareBackground.allCases) { bg in
                            Text(bg.displayName).tag(bg)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            // Actions.
            HStack(spacing: 12) {
                Button("Return to canonical") {
                    viewModel.returnToCanonical()
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.state.isDirty && viewModel.state == .canonical)

                Spacer()

                if viewModel.state.isDirty {
                    Button("Discard") {
                        viewModel.discardChanges()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Save") {
                    let presentation = viewModel.save()
                    onSave?(presentation)
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.state.isDirty)
            }
            .padding()
        }
        .navigationTitle("Flare")
    }
}

// MARK: - Flare glyph view
//
// Renders a `SigilFlarePresentation` using the same Canvas approach as the
// canonical glyph, but with the palette color and glow applied.

public struct SigilFlareGlyphView: View {
    let presentation: SigilFlarePresentation

    public init(presentation: SigilFlarePresentation) {
        self.presentation = presentation
    }

    public var body: some View {
        Canvas { context, size in
            let paths = parsePaths(from: presentation)
            let bounds = parseViewBox(for: presentation)
            let scale = min(size.width / bounds.width, size.height / bounds.height)
            let offset = CGSize(
                width: (size.width - bounds.width * scale) / 2,
                height: (size.height - bounds.height * scale) / 2
            )
            let color = colorFor(presentation.style.paletteID)
            let glow = presentation.style.glowStrength

            for path in paths {
                var swiftPath = Path()
                let parsed = parseSVGPathData(path.d)
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
                if glow > 0 {
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: glow * 8))
                        layer.stroke(swiftPath, with: .color(color.opacity(glow)), lineWidth: 4)
                    }
                }
                context.stroke(swiftPath, with: .color(color), lineWidth: 2)
            }
        }
    }

    private func colorFor(_ paletteID: String) -> Color {
        switch SigilFlarePalette(rawValue: paletteID) ?? .canonical {
        case .canonical: return .primary
        case .aurora: return .green
        case .ember: return .orange
        case .frost: return .cyan
        case .midnight: return .indigo
        }
    }

    private struct SVGPath { let d: String }
    private enum PathCommand {
        case move(CGFloat, CGFloat)
        case line(CGFloat, CGFloat)
        case close
    }

    private func parsePaths(from presentation: SigilFlarePresentation) -> [SVGPath] {
        // The presentation carries vectorPaths with canonical pathData (the SVG
        // `d` attribute). We use that directly.
        return presentation.vectorPaths.map { SVGPath(d: $0.pathData) }
    }

    private func parseViewBox(for presentation: SigilFlarePresentation) -> CGRect {
        // Use a standard viewBox matching the canonical renderer.
        return CGRect(x: 0, y: 0, width: 100, height: 100)
    }

    private func parseSVGPathData(_ d: String) -> [PathCommand] {
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
                flushNumber()
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
