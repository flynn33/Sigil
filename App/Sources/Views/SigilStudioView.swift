import RFCoreModels
import RFEditor
import RFSigilPipeline
import RFStorage
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct SigilStudioView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue
    @AppStorage("rf.generation.include_extensions") private var includeExtensions = true

    @State private var exportMessage: String?
    @State private var activeHelp: StudioHelpTopic?

    @State private var layers: [DecorLayer] = []
    @State private var loadedProfileID: UUID?
    @State private var presetName = ""
    @State private var selectedPresetID: UUID?
    @State private var presetPreviewLayers: [UUID: [DecorLayer]] = [:]
    @State private var selectedPackID: String = ""
    @State private var selectedSymbolID: String = ""
    @State private var highlightedLayerID: UUID?

    @State private var exportFormat: ImageExportFormat = .png
    @State private var exportPreset: ExportProfilePreset = .standard
    @State private var exportWidth: String = "2048"
    @State private var exportHeight: String = "2048"
    @State private var jpegQuality: Double = 0.95
    @State private var includeMetadataSidecar = false
    @State private var exportBackgroundOverrideEnabled = false
    @State private var exportBackgroundColor = Color(hex: "#0B0C10")
    @State private var exportBackgroundIntensity: Double = 1
    @State private var sectionCheckpoints: [UUID: [LayerEditSection: DecorLayer]] = [:]
    @State private var selectedMaskPresetByLayer: [UUID: String] = [:]
    @State private var selectedEffectPresetByLayer: [UUID: String] = [:]
    #if canImport(UIKit)
    @State private var studioPreviewImage: UIImage?
    @State private var presetThumbnailImages: [UUID: UIImage] = [:]
    @State private var studioPreviewRenderTask: Task<Void, Never>?
    @State private var presetThumbnailRenderTask: Task<Void, Never>?
    @State private var studioPreviewSignature = ""
    @State private var presetThumbnailSignature = ""
    #endif

    private var themePalette: RFThemePalette {
        RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))
    }

    var body: some View {
        let palette = themePalette

        NavigationStack {
            ZStack {
                MysticNebulaBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let profile = coordinator.selectedProfile {
                            Text(profile.displayName)
                                .font(.system(.title2, design: .serif, weight: .bold))
                                .foregroundStyle(palette.textPrimary)

                            Text("Birth weekday: \(profile.derivedBirthWeekday())")
                                .foregroundStyle(palette.textSecondary)

                            HStack(alignment: .center, spacing: 8) {
                                Toggle("Use Sigil extension mapping (non-canonical)", isOn: $includeExtensions)
                                    .tint(palette.variantAccent)
                                    .foregroundStyle(palette.textPrimary)
                                studioInfoButton(
                                    title: "Sigil Extension Mapping",
                                    message: extensionMappingHelpText
                                )
                            }

                            Text(extensionMappingStatusText)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)

                            Button("Generate Personal Sigil") {
                                Task {
                                    await coordinator.generateSigil(options: SigilOptions(includeTraitExtensions: includeExtensions))
                                }
                            }
                            .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))
                        } else {
                            Text("Select or create a profile in the Codex tab.")
                                .foregroundStyle(palette.textSecondary)
                        }

                        if coordinator.activeSigil != nil {
                            presetStudioSection()

                            layerStudioSection

                            MysticCard(palette: palette) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Text("Export")
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(palette.textPrimary)
                                        studioInfoButton(
                                            title: "Export",
                                            message: exportHelpText
                                        )
                                    }

                                    Picker("Format", selection: $exportFormat) {
                                        Text("PNG").tag(ImageExportFormat.png)
                                        Text("JPEG").tag(ImageExportFormat.jpeg)
                                    }
                                    .pickerStyle(.segmented)

                                    Picker("Profile", selection: $exportPreset) {
                                        ForEach(ExportProfilePreset.allCases, id: \.rawValue) { preset in
                                            Text(preset.displayName).tag(preset)
                                        }
                                    }
                                    .pickerStyle(.menu)

                                    HStack {
                                        TextField("Width", text: $exportWidth)
                                            .keyboardType(.numberPad)
                                        TextField("Height", text: $exportHeight)
                                            .keyboardType(.numberPad)
                                    }

                                    if exportFormat == .jpeg {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("JPEG Quality: \(jpegQuality, format: .number.precision(.fractionLength(2)))")
                                                .foregroundStyle(palette.textSecondary)
                                            Slider(value: $jpegQuality, in: 0.1...1.0)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Toggle("Override background color", isOn: $exportBackgroundOverrideEnabled)
                                                .tint(palette.variantAccent)
                                                .foregroundStyle(palette.textPrimary)
                                            studioInfoButton(
                                                title: "Background Override",
                                                message: exportBackgroundHelpText
                                            )
                                        }

                                        if exportBackgroundOverrideEnabled {
                                            ColorPicker("Background Color", selection: $exportBackgroundColor, supportsOpacity: false)
                                                .foregroundStyle(palette.textPrimary)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Intensity: \(exportBackgroundIntensity, format: .number.precision(.fractionLength(2)))")
                                                    .foregroundStyle(palette.textSecondary)
                                                Slider(value: $exportBackgroundIntensity, in: 0.1...1)
                                                    .onChange(of: exportBackgroundIntensity) { _, newValue in
                                                        exportBackgroundColor = color(byApplyingIntensity: newValue, to: exportBackgroundColor)
                                                    }
                                            }
                                        }
                                    }

                                    Toggle("Write metadata sidecar JSON", isOn: $includeMetadataSidecar)
                                        .tint(palette.variantAccent)
                                        .foregroundStyle(palette.textPrimary)

                                    HStack {
                                        Button("Export Image") {
                                            exportImage()
                                        }
                                        Button("Geometry JSON") {
                                            exportGeometryJSON()
                                        }
                                        Button("SVG") {
                                            exportSVG()
                                        }
                                    }
                                    .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))

                                    if let exportMessage {
                                        Text(exportMessage)
                                            .font(.caption)
                                            .foregroundStyle(palette.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Sigil Studio")
            .safeAreaInset(edge: .top) {
                if let sigil = coordinator.activeSigil {
                    VStack(spacing: 0) {
                        studioPreview(geometry: sigil.geometry)
                            .frame(height: 220)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                    }
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .bottom) {
                        Divider().overlay(palette.variantAccent.opacity(0.2))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task(id: coordinator.selectedProfile?.id) {
                await initializeForSelectedProfile()
                scheduleStudioPreviewRender()
                schedulePresetThumbnailRender()
            }
            .onDisappear {
                cancelRenderingTasks()
            }
            .onChange(of: exportPreset) { _, newPreset in
                if newPreset != .custom {
                    let settings = ImageExportSettings.settings(for: newPreset)
                    exportWidth = String(settings.width)
                    exportHeight = String(settings.height)
                    jpegQuality = settings.jpegQuality
                }
            }
            .onChange(of: selectedPackID) { _, _ in
                if !selectedPackSymbols.contains(where: { $0.id == selectedSymbolID }) {
                    selectedSymbolID = selectedPackSymbols.first?.id ?? ""
                }
            }
            .onChange(of: exportBackgroundColor) { _, newColor in
                exportBackgroundIntensity = max(0.1, intensity(fromHex: hexString(from: newColor, includeAlpha: false)))
            }
            .onChange(of: coordinator.activeSigil?.geometryHash) { _, _ in
                scheduleStudioPreviewRender()
                schedulePresetThumbnailRender()
            }
            .onChange(of: coordinator.studioPresets.map(\.id)) { _, ids in
                if let selectedPresetID, !ids.contains(selectedPresetID) {
                    self.selectedPresetID = nil
                }

                Task {
                    await refreshPresetPreviewLayers()
                }
            }
            .onChange(of: presetPreviewLayers) { _, _ in
                schedulePresetThumbnailRender()
            }
            .onChange(of: selectedPresetID) { _, newValue in
                guard let newValue,
                      let summary = coordinator.studioPresets.first(where: { $0.id == newValue })
                else {
                    return
                }
                presetName = summary.name
            }
            .onChange(of: layers) { _, newLayers in
                coordinator.dependencies.editorDocument.reset(with: newLayers)
                syncEditingState(with: newLayers)
                scheduleStudioPreviewRender()
            }
            .alert(item: $activeHelp) { topic in
                Alert(
                    title: Text(topic.title),
                    message: Text(topic.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func presetStudioSection() -> some View {
        let palette = themePalette
        return VStack(alignment: .leading, spacing: 10) {
            Text("Studio Presets")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(palette.textPrimary)

            Text("Save and reuse decorative layer stacks per profile. Presets never change canonical geometry hash.")
                .font(.caption)
                .foregroundStyle(palette.textSecondary)

            if coordinator.studioPresets.isEmpty {
                Text("No presets yet. Save your current layer stack, then use one-tap Apply from cards below.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(coordinator.studioPresets) { preset in
                            presetCard(summary: preset)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            TextField("Preset Name", text: $presetName)

            Picker("Saved Presets", selection: $selectedPresetID) {
                Text("None").tag(UUID?.none)
                ForEach(coordinator.studioPresets) { preset in
                    Text(preset.isFavorite ? "[Pinned] \(preset.name)" : preset.name).tag(Optional(preset.id))
                }
            }
            .pickerStyle(.menu)

            HStack {
                Button("Save New") {
                    Task { await savePresetAsNew() }
                }

                Button("Save Overwrite") {
                    Task { await savePresetOverwrite() }
                }
                .disabled(selectedPresetID == nil)
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))

            HStack {
                Button("Rename Selected") {
                    Task { await renameSelectedPreset() }
                }
                .disabled(selectedPresetID == nil)

                Button("Duplicate Selected") {
                    Task { await duplicateSelectedPreset() }
                }
                .disabled(selectedPresetID == nil)
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))

            HStack {
                Button(selectedPresetSummary?.isFavorite == true ? "Unpin Selected" : "Pin Selected") {
                    Task { await toggleSelectedPresetFavorite() }
                }
                .disabled(selectedPresetID == nil)

                Button("Load Selected") {
                    Task { await loadSelectedPreset() }
                }
                .disabled(selectedPresetID == nil)

                Button("Delete Selected", role: .destructive) {
                    Task { await deleteSelectedPreset() }
                }
                .disabled(selectedPresetID == nil)
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))
        }
    }

    private var layerStudioSection: some View {
        let palette = themePalette
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Layer Studio")
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                studioInfoButton(
                    title: "Layer Studio",
                    message: layerStudioHelpText
                )
            }

            Text("Decorative layers never change the canonical geometry hash used for game import.")
                .font(.caption)
                .foregroundStyle(palette.textSecondary)

            HStack {
                if canApplySeventhGateLook {
                    Button("Apply 7th Gate Look") {
                        applySeventhGateLook()
                    }
                    .buttonStyle(GlowActionButtonStyle(accent: palette.accentCrimson))
                }

                Button("Reset To Default") {
                    layers = EditorDocument.defaultLayers()
                    exportMessage = "Reset layers to default."
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
            }

            if let canonicalPlane = canonicalPlane, canApplySeventhGateLook {
                Text(seventhGateEligibilityMessage(for: canonicalPlane))
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Mythos Pack")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                    studioInfoButton(
                        title: "Mythos Packs",
                        message: mythosPackHelpText
                    )
                }
                Picker("Mythos Pack", selection: $selectedPackID) {
                    ForEach(mythosPacks) { pack in
                        Text(pack.title).tag(pack.id)
                    }
                }
                .pickerStyle(.menu)

                Text("Pack symbols available: \(selectedPackSymbols.count)")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                HStack(spacing: 8) {
                    Text("Symbol")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                    studioInfoButton(
                        title: "Symbol Layer",
                        message: symbolLayerHelpText
                    )
                }
                Picker("Symbol", selection: $selectedSymbolID) {
                    ForEach(selectedPackSymbols) { symbol in
                        Text(symbol.name).tag(symbol.id)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Button {
                        addSelectedSymbolLayer()
                    } label: {
                        Label("Add Symbol Layer", systemImage: "plus")
                    }
                    studioInfoButton(
                        title: "Add Symbol Layer",
                        message: symbolLayerHelpText
                    )
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))

                Text("Mythos packs apply decorative overlays only. They do not change canonical geometry or export hash.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            if layers.isEmpty {
                Text("No layers available.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            ForEach(Array(layers.enumerated()), id: \.element.id) { index, _ in
                layerCard(index: index)
            }
        }
    }

    @ViewBuilder
    private func studioPreview(geometry: SigilGeometry) -> some View {
        let palette = themePalette
        #if canImport(UIKit)
        if let image = studioPreviewImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(palette.variantAccent.opacity(0.3), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.secondaryBackground.opacity(0.92))
                .overlay {
                    ProgressView()
                        .tint(palette.variantAccent)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(palette.variantAccent.opacity(0.3), lineWidth: 1)
                )
        }
        #else
        SigilGeometryView(geometry: geometry)
        #endif
    }

    private func layerCard(index: Int) -> some View {
        let palette = themePalette
        let layerID = layers[index].id
        let isHighlighted = layerID == highlightedLayerID
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1). \(layers[index].name)")
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Button {
                    moveLayer(from: index, to: index - 1)
                } label: {
                    Image(systemName: "arrow.up")
                }
                .disabled(index == 0)

                Button {
                    moveLayer(from: index, to: index + 1)
                } label: {
                    Image(systemName: "arrow.down")
                }
                .disabled(index == layers.count - 1)

                Button(role: .destructive) {
                    removeLayer(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(layers[index].kind == .geometry)
            }

            layerEditorSectionHeader(
                title: "Color & Blend",
                infoTitle: "Color & Blend",
                infoMessage: colorBlendHelpText,
                section: .appearance,
                index: index
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity: \(layers[index].opacity, format: .number.precision(.fractionLength(2)))")
                Slider(value: binding(for: index, keyPath: \.opacity), in: 0...1)
            }

            Picker("Blend", selection: payloadBinding(index: index, key: "blend_mode", fallback: "normal")) {
                Text("Normal").tag("normal")
                Text("Multiply").tag("multiply")
                Text("Screen").tag("screen")
                Text("Overlay").tag("overlay")
                Text("Lighten").tag("lighten")
                Text("Plus").tag("plus")
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 4) {
                ColorPicker(
                    "Primary Color",
                    selection: payloadColorBinding(
                        index: index,
                        key: "color",
                        fallback: layers[index].kind == .background ? "#0B0C10" : "#111111"
                    ),
                    supportsOpacity: false
                )
                .foregroundStyle(palette.textPrimary)

                Text("Color Intensity: \(payloadColorIntensityBinding(index: index, key: "color", fallback: layers[index].kind == .background ? "#0B0C10" : "#111111").wrappedValue, format: .number.precision(.fractionLength(2)))")
                Slider(
                    value: payloadColorIntensityBinding(
                        index: index,
                        key: "color",
                        fallback: layers[index].kind == .background ? "#0B0C10" : "#111111"
                    ),
                    in: 0.1...1
                )
            }

            if layers[index].kind == .background {
                layerEditorSectionHeader(
                    title: "Background Style",
                    infoTitle: "Background Style",
                    infoMessage: backgroundStyleHelpText,
                    section: .background,
                    index: index
                )

                Picker("Style", selection: payloadBinding(index: index, key: "style", fallback: "solid")) {
                    Text("Solid").tag("solid")
                    Text("Infernal").tag("infernal")
                    Text("Fire").tag("fire")
                    Text("Aurora").tag("aurora")
                    Text("Mist").tag("mist")
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vignette: \(payloadDoubleBinding(index: index, key: "effect_vignette", fallback: 0).wrappedValue, format: .number.precision(.fractionLength(2)))")
                    Slider(value: payloadDoubleBinding(index: index, key: "effect_vignette", fallback: 0), in: 0...1)
                }
            } else {
                layerEditorSectionHeader(
                    title: "Stroke",
                    infoTitle: "Stroke",
                    infoMessage: strokeHelpText,
                    section: .stroke,
                    index: index
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Line Width: \(payloadDoubleBinding(index: index, key: "line_width", fallback: 2).wrappedValue, format: .number.precision(.fractionLength(2)))")
                    Slider(value: payloadDoubleBinding(index: index, key: "line_width", fallback: 2), in: 0.5...16)
                }

                Picker("Brush", selection: payloadBinding(index: index, key: "brush_style", fallback: "clean")) {
                    Text("Clean").tag("clean")
                    Text("Rune").tag("rune")
                    Text("Etched").tag("etched")
                    Text("Ember").tag("ember")
                }
                .pickerStyle(.segmented)

                layerEditorSectionHeader(
                    title: "Effects",
                    infoTitle: "Effects",
                    infoMessage: effectHelpText,
                    section: .effects,
                    index: index
                )

                Picker(
                    "Effect Preset",
                    selection: effectPresetBinding(for: layerID)
                ) {
                    ForEach(Self.effectPresets, id: \.id) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)

                if let selectedPreset = Self.effectPresets.first(where: { $0.id == selectedEffectPresetByLayer[layerID, default: "neutral"] }) {
                    Text(selectedPreset.description)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Button("Apply Effect Preset") {
                    applyEffectPreset(index: index)
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
                .controlSize(.small)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow: \(payloadDoubleBinding(index: index, key: "effect_glow", fallback: 0).wrappedValue, format: .number.precision(.fractionLength(2)))")
                    Slider(value: payloadDoubleBinding(index: index, key: "effect_glow", fallback: 0), in: 0...1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ColorPicker(
                        "Glow Color",
                        selection: payloadColorBinding(index: index, key: "glow_color", fallback: "#FFD166"),
                        supportsOpacity: false
                    )
                    .foregroundStyle(palette.textPrimary)

                    Text("Glow Intensity: \(payloadColorIntensityBinding(index: index, key: "glow_color", fallback: "#FFD166").wrappedValue, format: .number.precision(.fractionLength(2)))")
                    Slider(value: payloadColorIntensityBinding(index: index, key: "glow_color", fallback: "#FFD166"), in: 0.1...1)
                }

                if layers[index].kind == .symbolOverlay {
                    VStack(alignment: .leading, spacing: 4) {
                        ColorPicker(
                            "Fill Color",
                            selection: payloadColorBinding(index: index, key: "fill_color", fallback: "#00000000", includeAlpha: true),
                            supportsOpacity: true
                        )
                        .foregroundStyle(palette.textPrimary)

                        Text("Fill Intensity: \(payloadColorIntensityBinding(index: index, key: "fill_color", fallback: "#00000000", includeAlpha: true).wrappedValue, format: .number.precision(.fractionLength(2)))")
                        Slider(value: payloadColorIntensityBinding(index: index, key: "fill_color", fallback: "#00000000", includeAlpha: true), in: 0...1)
                    }
                }

                layerEditorSectionHeader(
                    title: "Mask",
                    infoTitle: "Mask",
                    infoMessage: maskHelpText,
                    section: .mask,
                    index: index
                )

                Picker(
                    "Mask Preset",
                    selection: maskPresetBinding(for: layerID)
                ) {
                    ForEach(Self.maskPresets, id: \.id) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)

                if let selectedPreset = Self.maskPresets.first(where: { $0.id == selectedMaskPresetByLayer[layerID, default: "none"] }) {
                    Text(selectedPreset.description)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Button("Apply Mask Preset") {
                    applyMaskPreset(index: index)
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
                .controlSize(.small)

                Picker("Mask", selection: payloadBinding(index: index, key: "mask_mode", fallback: "none")) {
                    Text("None").tag("none")
                    Text("Circle").tag("circle")
                    Text("Ring").tag("ring")
                    Text("Diamond").tag("diamond")
                    Text("Vertical").tag("vertical")
                }
                .pickerStyle(.menu)

                if layers[index].payload["mask_mode", default: "none"] != "none" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mask Scale: \(payloadDoubleBinding(index: index, key: "mask_scale", fallback: 1).wrappedValue, format: .number.precision(.fractionLength(2)))")
                        Slider(value: payloadDoubleBinding(index: index, key: "mask_scale", fallback: 1), in: 0.2...1.8)
                    }

                    if layers[index].payload["mask_mode", default: "none"] == "ring" {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mask Inset: \(payloadDoubleBinding(index: index, key: "mask_inset", fallback: 0.24).wrappedValue, format: .number.precision(.fractionLength(2)))")
                            Slider(value: payloadDoubleBinding(index: index, key: "mask_inset", fallback: 0.24), in: 0...0.48)
                        }
                    }

                    Toggle("Invert Mask", isOn: payloadBoolBinding(index: index, key: "mask_invert", fallback: false))
                }

                layerEditorSectionHeader(
                    title: "Transform",
                    infoTitle: "Transform",
                    infoMessage: transformHelpText,
                    section: .transform,
                    index: index
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rotation: \(layers[index].rotationDegrees, format: .number.precision(.fractionLength(1)))°")
                    Slider(value: binding(for: index, keyPath: \.rotationDegrees), in: -180...180)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scale: \(layers[index].scale, format: .number.precision(.fractionLength(2)))")
                    Slider(value: binding(for: index, keyPath: \.scale), in: 0.1...3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Offset X: \(layers[index].offsetX, format: .number.precision(.fractionLength(2)))")
                    Slider(value: binding(for: index, keyPath: \.offsetX), in: -0.5...0.5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Offset Y: \(layers[index].offsetY, format: .number.precision(.fractionLength(2)))")
                    Slider(value: binding(for: index, keyPath: \.offsetY), in: -0.5...0.5)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHighlighted ? palette.variantAccent.opacity(0.16) : palette.secondaryBackground.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isHighlighted ? palette.glowHighlight.opacity(0.86) : palette.variantAccent.opacity(0.24),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: highlightedLayerID)
        .onAppear {
            syncEditingState(with: layers)
        }
    }

    private func layerEditorSectionHeader(
        title: String,
        infoTitle: String,
        infoMessage: String,
        section: LayerEditSection,
        index: Int
    ) -> some View {
        let palette = themePalette
        return HStack(spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
            studioInfoButton(title: infoTitle, message: infoMessage)
            Spacer()
            Button("Apply") {
                applySection(section, for: index)
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
            .controlSize(.small)
            Button("Undo") {
                undoSection(section, for: index)
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))
            .controlSize(.small)
        }
    }

    private func syncEditingState(with newLayers: [DecorLayer]) {
        let activeIDs = Set(newLayers.map(\.id))

        sectionCheckpoints = sectionCheckpoints.filter { activeIDs.contains($0.key) }
        selectedMaskPresetByLayer = selectedMaskPresetByLayer.filter { activeIDs.contains($0.key) }
        selectedEffectPresetByLayer = selectedEffectPresetByLayer.filter { activeIDs.contains($0.key) }

        for layer in newLayers {
            if sectionCheckpoints[layer.id] == nil {
                var checkpoints: [LayerEditSection: DecorLayer] = [:]
                for section in LayerEditSection.allCases {
                    checkpoints[section] = layer
                }
                sectionCheckpoints[layer.id] = checkpoints
            }

            if selectedMaskPresetByLayer[layer.id] == nil {
                selectedMaskPresetByLayer[layer.id] = inferredMaskPresetID(for: layer)
            }

            if selectedEffectPresetByLayer[layer.id] == nil {
                selectedEffectPresetByLayer[layer.id] = inferredEffectPresetID(for: layer)
            }
        }
    }

    private func applySection(_ section: LayerEditSection, for index: Int) {
        guard layers.indices.contains(index) else { return }
        let layer = layers[index]
        var checkpoints = sectionCheckpoints[layer.id] ?? [:]
        checkpoints[section] = layer
        sectionCheckpoints[layer.id] = checkpoints
    }

    private func undoSection(_ section: LayerEditSection, for index: Int) {
        guard layers.indices.contains(index) else { return }
        let layer = layers[index]
        guard let checkpoint = sectionCheckpoints[layer.id]?[section] else { return }
        layers[index] = checkpoint
    }

    private func maskPresetBinding(for layerID: UUID) -> Binding<String> {
        Binding {
            selectedMaskPresetByLayer[layerID, default: "none"]
        } set: { newValue in
            selectedMaskPresetByLayer[layerID] = newValue
        }
    }

    private func effectPresetBinding(for layerID: UUID) -> Binding<String> {
        Binding {
            selectedEffectPresetByLayer[layerID, default: "neutral"]
        } set: { newValue in
            selectedEffectPresetByLayer[layerID] = newValue
        }
    }

    private func inferredMaskPresetID(for layer: DecorLayer) -> String {
        let mode = layer.payload["mask_mode", default: "none"]
        switch mode {
        case "circle":
            return "focus"
        case "ring":
            return "halo"
        case "diamond":
            return "seal"
        case "vertical":
            return "gate"
        default:
            return "none"
        }
    }

    private func inferredEffectPresetID(for layer: DecorLayer) -> String {
        let glow = (Double(layer.payload["effect_glow"] ?? "0") ?? 0)
        let brush = layer.payload["brush_style", default: "clean"]
        if glow > 0.85 && brush == "ember" {
            return "infernal"
        }
        if glow > 0.5 && brush == "rune" {
            return "etched"
        }
        if brush == "clean" && glow <= 0.12 {
            return "neutral"
        }
        return "soft"
    }

    private func applyMaskPreset(index: Int) {
        guard layers.indices.contains(index) else { return }
        let layerID = layers[index].id
        let presetID = selectedMaskPresetByLayer[layerID, default: "none"]

        switch presetID {
        case "focus":
            layers[index].payload["mask_mode"] = "circle"
            layers[index].payload["mask_scale"] = "1.12"
            layers[index].payload["mask_inset"] = "0.24"
            layers[index].payload["mask_invert"] = "0"
        case "halo":
            layers[index].payload["mask_mode"] = "ring"
            layers[index].payload["mask_scale"] = "1.08"
            layers[index].payload["mask_inset"] = "0.18"
            layers[index].payload["mask_invert"] = "0"
        case "seal":
            layers[index].payload["mask_mode"] = "diamond"
            layers[index].payload["mask_scale"] = "1.0"
            layers[index].payload["mask_inset"] = "0.24"
            layers[index].payload["mask_invert"] = "0"
        case "gate":
            layers[index].payload["mask_mode"] = "vertical"
            layers[index].payload["mask_scale"] = "1.0"
            layers[index].payload["mask_inset"] = "0.24"
            layers[index].payload["mask_invert"] = "0"
        default:
            layers[index].payload["mask_mode"] = "none"
            layers[index].payload["mask_scale"] = "1.0"
            layers[index].payload["mask_inset"] = "0.24"
            layers[index].payload["mask_invert"] = "0"
        }
    }

    private func applyEffectPreset(index: Int) {
        guard layers.indices.contains(index) else { return }
        let layerID = layers[index].id
        let presetID = selectedEffectPresetByLayer[layerID, default: "neutral"]

        switch presetID {
        case "soft":
            layers[index].payload["blend_mode"] = "screen"
            layers[index].payload["brush_style"] = "clean"
            layers[index].payload["effect_glow"] = "0.35"
            layers[index].payload["glow_color"] = "#FFDFA8"
            layers[index].payload["line_width"] = "2.1"
        case "infernal":
            layers[index].payload["blend_mode"] = "plus"
            layers[index].payload["brush_style"] = "ember"
            layers[index].payload["effect_glow"] = "0.86"
            layers[index].payload["glow_color"] = "#FF5A1F"
            layers[index].payload["line_width"] = "3.2"
        case "etched":
            layers[index].payload["blend_mode"] = "overlay"
            layers[index].payload["brush_style"] = "etched"
            layers[index].payload["effect_glow"] = "0.56"
            layers[index].payload["glow_color"] = "#FFE0B5"
            layers[index].payload["line_width"] = "2.4"
        case "high_contrast":
            layers[index].payload["blend_mode"] = "multiply"
            layers[index].payload["brush_style"] = "rune"
            layers[index].payload["effect_glow"] = "0.42"
            layers[index].payload["glow_color"] = "#FFFFFF"
            layers[index].payload["line_width"] = "2.8"
        default:
            layers[index].payload["blend_mode"] = "normal"
            layers[index].payload["brush_style"] = "clean"
            layers[index].payload["effect_glow"] = "0.0"
            layers[index].payload["glow_color"] = layers[index].payload["color"] ?? "#111111"
            layers[index].payload["line_width"] = "2.0"
        }
    }

    private func payloadColorBinding(
        index: Int,
        key: String,
        fallback: String,
        includeAlpha: Bool = false
    ) -> Binding<Color> {
        Binding {
            guard layers.indices.contains(index) else { return color(from: fallback) }
            return color(from: layers[index].payload[key] ?? fallback)
        } set: { newColor in
            guard layers.indices.contains(index) else { return }
            layers[index].payload[key] = hexString(from: newColor, includeAlpha: includeAlpha)
        }
    }

    private func payloadColorIntensityBinding(
        index: Int,
        key: String,
        fallback: String,
        includeAlpha: Bool = false
    ) -> Binding<Double> {
        Binding {
            guard layers.indices.contains(index) else { return 1 }
            let hex = layers[index].payload[key] ?? fallback
            return intensity(fromHex: hex)
        } set: { newIntensity in
            guard layers.indices.contains(index) else { return }
            let hex = layers[index].payload[key] ?? fallback
            let updated = colorByApplyingIntensity(newIntensity, toHex: hex, includeAlpha: includeAlpha)
            layers[index].payload[key] = updated
        }
    }

    private func color(byApplyingIntensity intensity: Double, to color: Color) -> Color {
        let clamped = max(0, min(intensity, 1))
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(
                UIColor(
                    hue: hue,
                    saturation: saturation,
                    brightness: CGFloat(clamped),
                    alpha: alpha
                )
            )
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let scaledRed = max(0, min(red * CGFloat(clamped), 1))
            let scaledGreen = max(0, min(green * CGFloat(clamped), 1))
            let scaledBlue = max(0, min(blue * CGFloat(clamped), 1))
            return Color(UIColor(red: scaledRed, green: scaledGreen, blue: scaledBlue, alpha: alpha))
        }
        #endif
        return color
    }

    private func colorByApplyingIntensity(_ intensity: Double, toHex hex: String, includeAlpha: Bool) -> String {
        let clamped = max(0, min(intensity, 1))
        #if canImport(UIKit)
        guard let uiColor = uiColor(fromHex: hex) else { return includeAlpha ? "#000000FF" : "#000000" }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let adjusted = UIColor(hue: hue, saturation: saturation, brightness: CGFloat(clamped), alpha: alpha)
            return hexString(from: Color(adjusted), includeAlpha: includeAlpha)
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let adjusted = UIColor(
                red: max(0, min(red * CGFloat(clamped), 1)),
                green: max(0, min(green * CGFloat(clamped), 1)),
                blue: max(0, min(blue * CGFloat(clamped), 1)),
                alpha: alpha
            )
            return hexString(from: Color(adjusted), includeAlpha: includeAlpha)
        }
        #endif
        return includeAlpha ? "#000000FF" : "#000000"
    }

    private func intensity(fromHex hex: String) -> Double {
        #if canImport(UIKit)
        guard let uiColor = uiColor(fromHex: hex) else { return 1 }
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Double(brightness)
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return Double(max(red, max(green, blue)))
        }
        #endif
        return 1
    }

    private func color(from hex: String) -> Color {
        #if canImport(UIKit)
        if let uiColor = uiColor(fromHex: hex) {
            return Color(uiColor)
        }
        #endif
        return Color(hex: hex)
    }

    private func hexString(from color: Color, includeAlpha: Bool) -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return includeAlpha ? "#000000FF" : "#000000"
        }
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        let a = Int((alpha * 255).rounded())
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return includeAlpha ? "#000000FF" : "#000000"
        #endif
    }

    #if canImport(UIKit)
    private func uiColor(fromHex hex: String) -> UIColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard let int = UInt64(cleaned, radix: 16) else { return nil }

        switch cleaned.count {
        case 6:
            let red = CGFloat((int >> 16) & 0xFF) / 255
            let green = CGFloat((int >> 8) & 0xFF) / 255
            let blue = CGFloat(int & 0xFF) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        case 8:
            let red = CGFloat((int >> 24) & 0xFF) / 255
            let green = CGFloat((int >> 16) & 0xFF) / 255
            let blue = CGFloat((int >> 8) & 0xFF) / 255
            let alpha = CGFloat(int & 0xFF) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        default:
            return nil
        }
    }
    #endif

    private var mythosPacks: [MythosPack] {
        coordinator.dependencies.mythosCatalog.packs().sorted { $0.title < $1.title }
    }

    private var selectedPackSymbols: [MythosSymbol] {
        mythosPacks.first(where: { $0.id == selectedPackID })?.symbols ?? []
    }

    private var selectedPresetSummary: StoredStudioPresetSummary? {
        guard let selectedPresetID else { return nil }
        return coordinator.studioPresets.first(where: { $0.id == selectedPresetID })
    }

    private static let maskPresets: [LayerMaskPreset] = [
        LayerMaskPreset(id: "none", title: "None", description: "No masking"),
        LayerMaskPreset(id: "focus", title: "Circle Focus", description: "Soft circular focus"),
        LayerMaskPreset(id: "halo", title: "Ring Halo", description: "Ring-shaped mask"),
        LayerMaskPreset(id: "seal", title: "Diamond Seal", description: "Diamond framing"),
        LayerMaskPreset(id: "gate", title: "Vertical Gate", description: "Vertical gate slice")
    ]

    private static let effectPresets: [LayerEffectPreset] = [
        LayerEffectPreset(id: "neutral", title: "Clean", description: "Balanced, no extra glow"),
        LayerEffectPreset(id: "soft", title: "Soft Glow", description: "Subtle luminous edge"),
        LayerEffectPreset(id: "infernal", title: "Infernal", description: "Strong ember glow and additive blend"),
        LayerEffectPreset(id: "etched", title: "Etched Rune", description: "Carved rune look"),
        LayerEffectPreset(id: "high_contrast", title: "High Contrast", description: "Sharper, darker contrast")
    ]

    private func presetCard(summary: StoredStudioPresetSummary) -> some View {
        let palette = themePalette
        return VStack(alignment: .leading, spacing: 8) {
            presetThumbnail(summary: summary)
                .frame(width: 150, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedPresetID == summary.id ? palette.variantAccent : palette.textSecondary.opacity(0.25), lineWidth: selectedPresetID == summary.id ? 2 : 1)
                )

            HStack(spacing: 6) {
                if summary.isFavorite {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(summary.name)
                    .font(.caption)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
            }

            Button("Apply") {
                Task { await applyPreset(id: summary.id) }
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
            .controlSize(.small)
        }
        .frame(width: 160)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.secondaryBackground.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.variantAccent.opacity(0.24), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func presetThumbnail(summary: StoredStudioPresetSummary) -> some View {
        #if canImport(UIKit)
        if let image = presetThumbnailImages[summary.id] {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(themePalette.secondaryBackground.opacity(0.8))
                .overlay {
                    ProgressView()
                        .controlSize(.small)
                        .tint(themePalette.variantAccent)
                }
        }
        #else
        Rectangle().fill(.gray.opacity(0.25))
        #endif
    }

    private func initializeForSelectedProfile() async {
        if selectedPackID.isEmpty {
            selectedPackID = mythosPacks.first?.id ?? ""
        }

        if selectedSymbolID.isEmpty {
            selectedSymbolID = selectedPackSymbols.first?.id ?? ""
        }

        let defaults = ImageExportSettings.settings(for: exportPreset)
        if Int(exportWidth) == nil { exportWidth = String(defaults.width) }
        if Int(exportHeight) == nil { exportHeight = String(defaults.height) }

        guard let profile = coordinator.selectedProfile else {
            loadedProfileID = nil
            selectedPresetID = nil
            presetName = ""
            return
        }

        let isProfileChanged = loadedProfileID != profile.id
        if isProfileChanged {
            loadedProfileID = profile.id
            layers = EditorDocument.defaultLayers()
            coordinator.dependencies.editorDocument.reset(with: layers)
            selectedPresetID = nil
            presetName = ""
            presetPreviewLayers = [:]
        } else if layers.isEmpty {
            layers = coordinator.dependencies.editorDocument.layers
        }

        await coordinator.loadStudioPresets()
        await refreshPresetPreviewLayers()
    }

    private func refreshPresetPreviewLayers() async {
        var loaded: [UUID: [DecorLayer]] = [:]
        for summary in coordinator.studioPresets {
            if let preset = await coordinator.loadStudioPreset(id: summary.id) {
                loaded[summary.id] = preset.layers
            }
        }
        presetPreviewLayers = loaded
    }

    private func layerSignature(_ layers: [DecorLayer]) -> String {
        layers
            .map { layer in
                let payload = layer.payload
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: ",")
                return [
                    layer.id.uuidString,
                    layer.name,
                    layer.kind.rawValue,
                    String(format: "%.5f", layer.opacity),
                    String(format: "%.5f", layer.rotationDegrees),
                    String(format: "%.5f", layer.scale),
                    String(format: "%.5f", layer.offsetX),
                    String(format: "%.5f", layer.offsetY),
                    payload
                ]
                .joined(separator: "|")
            }
            .joined(separator: "||")
    }

    #if canImport(UIKit)
    private func cancelRenderingTasks() {
        studioPreviewRenderTask?.cancel()
        studioPreviewRenderTask = nil
        presetThumbnailRenderTask?.cancel()
        presetThumbnailRenderTask = nil
    }

    private func scheduleStudioPreviewRender() {
        guard let activeSigil = coordinator.activeSigil
        else {
            studioPreviewRenderTask?.cancel()
            studioPreviewImage = nil
            studioPreviewSignature = ""
            return
        }

        let geometry = activeSigil.geometry
        let renderService = coordinator.dependencies.renderService
        let layersSnapshot = layers
        let signature = activeSigil.geometryHash + "|" + layerSignature(layersSnapshot)

        guard signature != studioPreviewSignature else {
            return
        }

        studioPreviewRenderTask?.cancel()
        studioPreviewRenderTask = Task { [layersSnapshot] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            if Task.isCancelled { return }

            let image = renderService.renderComposite(
                geometry: geometry,
                layers: layersSnapshot,
                canvasSize: CGSize(width: 768, height: 768)
            )
            if Task.isCancelled { return }

            await MainActor.run {
                studioPreviewImage = image
                studioPreviewSignature = signature
            }
        }
    }

    private func schedulePresetThumbnailRender() {
        guard let activeSigil = coordinator.activeSigil,
              !coordinator.studioPresets.isEmpty
        else {
            presetThumbnailRenderTask?.cancel()
            presetThumbnailImages = [:]
            presetThumbnailSignature = ""
            return
        }

        let geometry = activeSigil.geometry
        let summaries = coordinator.studioPresets
        let previewLayers = presetPreviewLayers
        let renderService = coordinator.dependencies.renderService
        let signature = activeSigil.geometryHash
            + "|"
            + summaries
                .map { summary in
                    let layerSet = previewLayers[summary.id] ?? EditorDocument.defaultLayers()
                    return summary.id.uuidString + ":" + layerSignature(layerSet)
                }
                .joined(separator: "||")

        guard signature != presetThumbnailSignature else {
            return
        }

        presetThumbnailRenderTask?.cancel()
        presetThumbnailRenderTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled { return }

            var rendered: [UUID: UIImage] = [:]
            for summary in summaries {
                if Task.isCancelled { return }
                let layers = previewLayers[summary.id] ?? EditorDocument.defaultLayers()
                let image = renderService.renderComposite(
                    geometry: geometry,
                    layers: layers,
                    canvasSize: CGSize(width: 240, height: 240)
                )
                rendered[summary.id] = image
            }
            if Task.isCancelled { return }

            await MainActor.run {
                presetThumbnailImages = rendered
                presetThumbnailSignature = signature
            }
        }
    }
    #else
    private func cancelRenderingTasks() {}
    private func scheduleStudioPreviewRender() {}
    private func schedulePresetThumbnailRender() {}
    #endif

    private func savePresetAsNew() async {
        let name = resolvedPresetNameForSave()
        guard !name.isEmpty else {
            coordinator.errorMessage = "Preset name is required."
            return
        }

        if let presetID = await coordinator.saveStudioPreset(name: name, layers: layers, existingPresetID: nil) {
            selectedPresetID = presetID
            presetName = name
            await refreshPresetPreviewLayers()
            exportMessage = "Saved new preset '\(name)'."
        }
    }

    private func savePresetOverwrite() async {
        guard let selectedPresetID else {
            coordinator.errorMessage = "Select a preset to overwrite."
            return
        }

        let name = resolvedPresetNameForSave(fallback: selectedPresetSummary?.name ?? "Preset")
        if let presetID = await coordinator.saveStudioPreset(name: name, layers: layers, existingPresetID: selectedPresetID) {
            self.selectedPresetID = presetID
            presetName = name
            await refreshPresetPreviewLayers()
            exportMessage = "Updated preset '\(name)'."
        }
    }

    private func renameSelectedPreset() async {
        guard let selectedPresetID else {
            coordinator.errorMessage = "Select a preset to rename."
            return
        }

        let newName = resolvedPresetNameForSave(fallback: selectedPresetSummary?.name ?? "")
        guard !newName.isEmpty else {
            coordinator.errorMessage = "Preset name is required."
            return
        }

        if await coordinator.renameStudioPreset(id: selectedPresetID, newName: newName) {
            presetName = newName
            await refreshPresetPreviewLayers()
            exportMessage = "Renamed preset to '\(newName)'."
        }
    }

    private func duplicateSelectedPreset() async {
        guard let selectedPresetID else {
            coordinator.errorMessage = "Select a preset to duplicate."
            return
        }

        let fallback = defaultDuplicateName()
        let newName = resolvedPresetNameForSave(fallback: fallback)
        guard !newName.isEmpty else {
            coordinator.errorMessage = "Preset name is required."
            return
        }

        if let duplicatedID = await coordinator.duplicateStudioPreset(id: selectedPresetID, newName: newName) {
            self.selectedPresetID = duplicatedID
            presetName = newName
            await refreshPresetPreviewLayers()
            exportMessage = "Duplicated preset as '\(newName)'."
        }
    }

    private func toggleSelectedPresetFavorite() async {
        guard let selectedPresetID else { return }
        let wasFavorite = selectedPresetSummary?.isFavorite ?? false
        await coordinator.toggleStudioPresetFavorite(id: selectedPresetID)
        await refreshPresetPreviewLayers()
        let message = wasFavorite ? "Unpinned preset." : "Pinned preset."
        exportMessage = message
    }

    private func loadSelectedPreset() async {
        guard let selectedPresetID else { return }
        await applyPreset(id: selectedPresetID)
    }

    private func applyPreset(id: UUID) async {
        guard let preset = await coordinator.loadStudioPreset(id: id) else { return }

        selectedPresetID = id
        layers = preset.layers
        presetName = preset.name
        exportMessage = "Applied preset '\(preset.name)'."
    }

    private func deleteSelectedPreset() async {
        guard let selectedPresetID else { return }
        let removedName = selectedPresetSummary?.name ?? "Preset"
        await coordinator.deleteStudioPreset(id: selectedPresetID)
        self.selectedPresetID = nil
        presetName = ""
        await refreshPresetPreviewLayers()
        exportMessage = "Deleted preset '\(removedName)'."
    }

    private func resolvedPresetNameForSave(fallback: String = "") -> String {
        let trimmed = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func defaultDuplicateName() -> String {
        guard let selectedPresetSummary else { return "Preset Copy" }
        return "\(selectedPresetSummary.name) Copy"
    }

    private func removeLayer(at index: Int) {
        guard layers.indices.contains(index) else { return }
        let removedID = layers[index].id
        layers.remove(at: index)
        if highlightedLayerID == removedID {
            highlightedLayerID = nil
        }
    }

    private func moveLayer(from index: Int, to destination: Int) {
        guard layers.indices.contains(index) else { return }
        let clampedDestination = max(0, min(destination, layers.count - 1))
        guard clampedDestination != index else { return }

        let layer = layers.remove(at: index)
        layers.insert(layer, at: clampedDestination)
    }

    private func binding(for index: Int, keyPath: WritableKeyPath<DecorLayer, Double>) -> Binding<Double> {
        Binding {
            guard layers.indices.contains(index) else { return 0 }
            return layers[index][keyPath: keyPath]
        } set: { value in
            guard layers.indices.contains(index) else { return }
            layers[index][keyPath: keyPath] = value
        }
    }

    private func payloadBinding(index: Int, key: String, fallback: String = "") -> Binding<String> {
        Binding {
            guard layers.indices.contains(index) else { return fallback }
            return layers[index].payload[key, default: fallback]
        } set: { newValue in
            guard layers.indices.contains(index) else { return }
            layers[index].payload[key] = newValue
        }
    }

    private func payloadDoubleBinding(index: Int, key: String, fallback: Double) -> Binding<Double> {
        Binding {
            guard layers.indices.contains(index) else { return fallback }
            if let value = Double(layers[index].payload[key] ?? "") {
                return value
            }
            return fallback
        } set: { newValue in
            guard layers.indices.contains(index) else { return }
            layers[index].payload[key] = String(newValue)
        }
    }

    private func payloadBoolBinding(index: Int, key: String, fallback: Bool) -> Binding<Bool> {
        Binding {
            guard layers.indices.contains(index) else { return fallback }
            return layers[index].payload[key, default: fallback ? "1" : "0"] == "1"
        } set: { newValue in
            guard layers.indices.contains(index) else { return }
            layers[index].payload[key] = newValue ? "1" : "0"
        }
    }

    private func addSelectedSymbolLayer() {
        guard !selectedSymbolID.isEmpty else {
            coordinator.errorMessage = "Select a Mythos pack and symbol first."
            return
        }

        let factory = MythosOverlayFactory(catalog: coordinator.dependencies.mythosCatalog)
        guard let layer = factory.overlay(for: selectedSymbolID) else {
            coordinator.errorMessage = "Unable to create symbol layer for the selected symbol."
            return
        }

        layers.append(layer)
        let newLayerID = layer.id
        highlightedLayerID = newLayerID
        exportMessage = "Added \(layer.name) layer. Adjust style and position in Layer Studio below."

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if highlightedLayerID == newLayerID {
                highlightedLayerID = nil
            }
        }
    }

    private var canonicalPlane: Int? {
        guard let sigil = coordinator.activeSigil else { return nil }
        return coordinator.dependencies.sigilPipeline.estimatePlane(for: sigil.vector)
    }

    private var canApplySeventhGateLook: Bool {
        guard let canonicalPlane else { return false }
        return canonicalPlane == 7 && !coordinator.activeSigilUsesExtensions
    }

    private var codexLuciferianFlag: Bool {
        coordinator.activeSigil?.codexInsights?.luciferianPrivateFlag ?? false
    }

    private var extensionTraitSignalCount: Int {
        guard let profile = coordinator.selectedProfile else { return 0 }

        var count = 0
        if profile.birthOrderTotal != nil { count += 1 }
        if profile.mother.birthOrderTotal != nil { count += 1 }
        if profile.father.birthOrderTotal != nil { count += 1 }
        if !profile.birthplaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !profile.userHairColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !profile.userEyeColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if profile.userHeightCentimeters != nil { count += 1 }
        if !profile.mother.hairColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !profile.mother.eyeColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !profile.father.hairColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !profile.father.eyeColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }

        count += profile.traits.familyNames.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        count += profile.traits.heritage.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        count += profile.traits.hobbiesInterests.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        for profession in profile.traits.professions {
            if !profession.profession.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
            if !profession.titleOrPosition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
            if profession.yearsInProfession > 0 { count += 1 }
            if !profession.customItemLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
            if !profession.customItemValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        }

        count += profile.traits.additionalTraits.values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        count += profile.traits.dynamicFieldValues.values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        return count
    }

    private var exportHelpText: String {
        """
        Export your final sigil as PNG/JPEG for sharing, plus geometry JSON/SVG for canonical import workflows.
        Exporting never changes your saved profile or canonical geometry.
        """
    }

    private var exportBackgroundHelpText: String {
        """
        Optional: force a custom background color only for exported images.
        Turn it off to keep the current layer stack background exactly as rendered in Studio.
        """
    }

    private var colorBlendHelpText: String {
        """
        Set each layer's base color, brightness, opacity, and blend mode.
        Preview updates immediately; use Apply to commit this section and Undo to return to last applied state.
        """
    }

    private var backgroundStyleHelpText: String {
        """
        Background style controls ambience (solid, infernal, fire, aurora, mist) and vignette intensity.
        Use Apply after a look is finalized.
        """
    }

    private var strokeHelpText: String {
        """
        Stroke controls define line width, brush style, and color behavior for geometry/symbol layers.
        For symbol layers, fill color controls interior color/opacity.
        """
    }

    private var effectHelpText: String {
        """
        Effects tune glow behavior and visual energy.
        Start with an Effect Preset, then fine-tune glow strength and color.
        """
    }

    private var maskHelpText: String {
        """
        Masks crop a layer into canonical-friendly visual shapes.
        Choose a Mask Preset for quick setup, then adjust scale/inset/invert as needed.
        """
    }

    private var transformHelpText: String {
        """
        Transform controls rotate, scale, and offset a layer on the canvas.
        Use small increments for cleaner sigil alignment.
        """
    }

    private var extensionMappingHelpText: String {
        """
        Extension mapping is generation math only; it is not related to Mythos packs.

        OFF: canonical baseline vector only.
        ON: deterministic extension blend from optional profile traits (family/heritage/hobbies, profession details, custom fields, and related optional metadata).

        Mythos packs affect decorative overlays only and never change canonical geometry hash.
        """
    }

    private var mythosPackHelpText: String {
        """
        Mythos packs are decorative overlay libraries.

        Steps:
        1. Choose a Mythos Pack.
        2. Choose a Symbol.
        3. Tap Add Symbol Layer.
        4. Edit that symbol layer below (opacity, color, glow, blend, mask, position).

        Mythos layers never change canonical sigil geometry or game-import hash.
        """
    }

    private var symbolLayerHelpText: String {
        """
        Add Symbol Layer creates a new overlay layer on top of your geometry.
        If it looks subtle, increase layer Opacity/Glow, change Color, or move the layer above others.
        """
    }

    private var layerStudioHelpText: String {
        """
        Layer order controls what appears on top.

        Upper layers in the list render first; layers lower in the list draw later and appear on top.
        Use up/down arrows to reorder, then tune each layer's opacity, blend mode, glow, and mask.
        New symbol layers are briefly highlighted so you can find them quickly.
        """
    }

    private var extensionMappingStatusText: String {
        if includeExtensions {
            if extensionTraitSignalCount == 0 {
                return "Extension mapping is ON, but no extension trait signals are filled; output will match canonical mode."
            }
            return "Extension mapping is ON using \(extensionTraitSignalCount) trait signals. Mythos packs are visual only."
        }
        return "Extension mapping is OFF (canonical mode). Mythos packs are visual only."
    }

    private func seventhGateEligibilityMessage(for canonicalPlane: Int) -> String {
        if canApplySeventhGateLook {
            if codexLuciferianFlag {
                return "Canonical alignment confirmed: Gate 7 (Shadow Dimension). Codex threshold marker detected."
            }
            return "Canonical alignment confirmed: Gate 7 (Shadow Dimension)."
        }
        return "Current canonical plane is \(canonicalPlane)."
    }

    private func applySeventhGateLook() {
        guard canApplySeventhGateLook else {
            coordinator.errorMessage = "7th Gate look requires canonical Gate 7 alignment (Shadow Dimension)."
            return
        }

        let wingsPath = symbolPath(
            for: "mythic-1",
            fallback: "M 6 50 L 15 44 L 28 40 L 40 43 L 46 50 L 39 56 L 27 59 L 15 57 L 8 53 Z M 94 50 L 85 44 L 72 40 L 60 43 L 54 50 L 61 56 L 73 59 L 85 57 L 92 53 Z M 46 50 L 50 46 L 54 50 L 50 58 Z"
        )
        let gatePath = symbolPath(
            for: "mythic-2",
            fallback: "M 50 8 L 47 13 L 47 18 L 50 23 L 53 18 L 53 13 Z M 20 24 L 80 24 M 20 24 L 50 54 L 80 24 M 50 24 L 50 92 M 36 44 L 64 64 M 64 44 L 36 64 M 32 70 L 50 86 L 68 70 M 34 86 L 50 70 L 66 86 M 50 86 L 50 96 M 26 78 L 22 78 L 19 81 L 19 84 L 22 86 L 26 85 M 74 78 L 78 78 L 81 81 L 81 84 L 78 86 L 74 85"
        )
        let flourishPath = symbolPath(
            for: "mythic-4",
            fallback: "M 36 70 L 31 75 L 25 75 L 21 71 L 21 66 L 25 62 L 30 62 L 35 66 L 40 70 M 64 70 L 69 75 L 75 75 L 79 71 L 79 66 L 75 62 L 70 62 L 65 66 L 60 70 M 42 66 L 58 66"
        )

        layers = [
            DecorLayer(
                name: "Infernal Background",
                kind: .background,
                payload: [
                    "style": "infernal",
                    "color": "#080406",
                    "blend_mode": "normal",
                    "effect_vignette": "0.82"
                ]
            ),
            DecorLayer(
                name: "Twin Wings",
                kind: .symbolOverlay,
                opacity: 0.66,
                scale: 2.15,
                offsetY: -0.06,
                payload: [
                    "symbol_path": wingsPath,
                    "color": "#f3dcc9",
                    "fill_color": "#f3dcc933",
                    "line_width": "1.8",
                    "blend_mode": "screen",
                    "brush_style": "clean",
                    "effect_glow": "0.18",
                    "glow_color": "#ffd5b0"
                ]
            ),
            DecorLayer(
                name: "Sigil Geometry",
                kind: .geometry,
                payload: [
                    "color": "#fff7d6",
                    "line_width": "3.6",
                    "blend_mode": "screen",
                    "brush_style": "ember",
                    "effect_glow": "0.94",
                    "glow_color": "#ff5a1f"
                ]
            ),
            DecorLayer(
                name: "Gate Crest",
                kind: .symbolOverlay,
                opacity: 0.94,
                scale: 1.42,
                offsetY: -0.02,
                payload: [
                    "symbol_path": gatePath,
                    "color": "#ffcf73",
                    "fill_color": "#00000000",
                    "line_width": "2.8",
                    "blend_mode": "screen",
                    "brush_style": "ember",
                    "effect_glow": "0.82",
                    "glow_color": "#ff6a2f"
                ]
            ),
            DecorLayer(
                name: "Ember Flourish",
                kind: .symbolOverlay,
                opacity: 0.92,
                scale: 1.06,
                offsetY: 0.23,
                payload: [
                    "symbol_path": flourishPath,
                    "color": "#ffc36a",
                    "fill_color": "#00000000",
                    "line_width": "2.3",
                    "blend_mode": "plus",
                    "brush_style": "ember",
                    "effect_glow": "0.74",
                    "glow_color": "#ff4d1f"
                ]
            )
        ]

        if mythosPacks.contains(where: { $0.id == "mythic" }) {
            selectedPackID = "mythic"
            selectedSymbolID = "mythic-2"
        }

        exportMessage = "Applied studio look: 7th Gate."
    }

    private func studioInfoButton(title: String, message: String) -> some View {
        Button {
            activeHelp = StudioHelpTopic(title: title, message: message)
        } label: {
            Image(systemName: "info.circle")
                .font(.callout)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Info about \(title)")
    }

    private func symbolPath(for symbolID: String, fallback: String) -> String {
        for pack in mythosPacks {
            if let symbol = pack.symbols.first(where: { $0.id == symbolID }) {
                return symbol.svgPath
            }
        }
        return fallback
    }

    private func currentExportSettings() -> ImageExportSettings {
        let fallback = ImageExportSettings.settings(for: exportPreset == .custom ? .standard : exportPreset)

        let settings = ImageExportSettings(
            width: Int(exportWidth) ?? fallback.width,
            height: Int(exportHeight) ?? fallback.height,
            jpegQuality: jpegQuality,
            preset: exportPreset,
            metadataMode: includeMetadataSidecar ? .sidecarJSON : .none,
            backgroundHexOverride: exportBackgroundOverrideEnabled
                ? hexString(from: color(byApplyingIntensity: exportBackgroundIntensity, to: exportBackgroundColor), includeAlpha: false)
                : nil
        )

        return settings.normalized()
    }

    private func exportImage() {
        guard let sigil = coordinator.activeSigil else { return }
        let settings = currentExportSettings()

        do {
            let data = try coordinator.dependencies.exportService.exportImage(
                format: exportFormat,
                settings: settings,
                geometry: sigil.geometry,
                layers: layers
            )

            let fileExtension = exportFormat == .png ? "png" : "jpg"
            let filename = "sigil-\(sigil.profileID.uuidString)-\(settings.preset.rawValue).\(fileExtension)"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)

            var messageParts = ["Exported image to \(url.path)"]

            if settings.metadataMode == .sidecarJSON {
                let metadata = try coordinator.dependencies.exportService.exportMetadataManifest(
                    from: sigil,
                    format: exportFormat,
                    settings: settings,
                    exportedAt: .now
                )
                let metadataURL = url.deletingPathExtension().appendingPathExtension("metadata.json")
                try metadata.write(to: metadataURL, options: .atomic)
                messageParts.append("metadata \(metadataURL.lastPathComponent)")
            }

            exportMessage = messageParts.joined(separator: " + ")
        } catch {
            coordinator.errorMessage = "Failed to export image: \(error.localizedDescription)"
        }
    }

    private func exportGeometryJSON() {
        guard let sigil = coordinator.activeSigil else { return }

        do {
            let data = try coordinator.dependencies.exportService.exportGeometryJSON(from: sigil)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("sigil-\(sigil.profileID.uuidString).json")
            try data.write(to: url, options: .atomic)
            exportMessage = "Exported to \(url.path)"
        } catch {
            coordinator.errorMessage = "Failed to export JSON: \(error.localizedDescription)"
        }
    }

    private func exportSVG() {
        guard let sigil = coordinator.activeSigil else { return }

        let settings = currentExportSettings()
        let svg = coordinator.dependencies.exportService.exportGeometrySVG(
            geometry: sigil.geometry,
            settings: settings
        )

        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("sigil-\(sigil.profileID.uuidString).svg")
            try Data(svg.utf8).write(to: url, options: .atomic)
            exportMessage = "Exported to \(url.path)"
        } catch {
            coordinator.errorMessage = "Failed to export SVG: \(error.localizedDescription)"
        }
    }
}

private struct StudioHelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum LayerEditSection: CaseIterable, Hashable {
    case appearance
    case background
    case stroke
    case effects
    case mask
    case transform
}

private struct LayerMaskPreset: Hashable {
    let id: String
    let title: String
    let description: String
}

private struct LayerEffectPreset: Hashable {
    let id: String
    let title: String
    let description: String
}
