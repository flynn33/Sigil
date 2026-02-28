import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    @AppStorage("rf.settings.haptics.enabled") private var hapticsEnabled = true
    @AppStorage("rf.settings.privacy_mode") private var privacyMode = false
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    @State private var biometricLockEnabled = false
    @State private var activeHelp: SettingsHelpTopic?

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        NavigationStack {
            ZStack {
                MysticNebulaBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        MysticCard(palette: palette) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    MysticSectionHeader(title: "Security", palette: palette)
                                    infoButton(
                                        title: "Security",
                                        message: securityHelpText,
                                        palette: palette
                                    )
                                }

                                Toggle("Enable App Lock (Face ID / Passcode)", isOn: $biometricLockEnabled)
                                    .onChange(of: biometricLockEnabled) { _, newValue in
                                        coordinator.setBiometricLockEnabled(newValue)
                                    }
                                    .tint(palette.variantAccent)

                                Text("Default is off. Data remains encrypted at rest regardless of this setting.")
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .foregroundStyle(palette.textPrimary)
                        }

                        MysticCard(palette: palette) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    MysticSectionHeader(title: "Experience", palette: palette)
                                    infoButton(
                                        title: "Experience",
                                        message: experienceHelpText,
                                        palette: palette
                                    )
                                }
                                Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                                    .tint(palette.variantAccent)

                                Text("Sound controls are disabled in this phase. Sigil currently uses visual and haptic feedback only.")
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)

                                Picker("Theme Variation", selection: $themeVariantRaw) {
                                    ForEach(RFThemeVariant.allCases) { variant in
                                        Text(variant.displayName).tag(variant.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .foregroundStyle(palette.textPrimary)
                        }

                        MysticCard(palette: palette) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    MysticSectionHeader(title: "Privacy", palette: palette)
                                    infoButton(
                                        title: "Privacy",
                                        message: privacyHelpText,
                                        palette: palette
                                    )
                                }

                                Toggle("Privacy Mode", isOn: $privacyMode)
                                    .tint(palette.variantAccent)

                                Text("Sigil runs fully local except Apple Maps coordinate lookup for birthplace search.")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(palette.textSecondary)

                                Text("No external analytics SDKs are included in v1.")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .foregroundStyle(palette.textPrimary)
                        }

                        MysticCard(palette: palette) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    MysticSectionHeader(title: "Mythos",
                                                        palette: palette)
                                    infoButton(
                                        title: "Mythos",
                                        message: mythosHelpText,
                                        palette: palette
                                    )
                                }
                                Text(coordinator.dependencies.mythosCatalog.respectNotice)
                                    .font(.system(.body, design: .serif))
                                    .foregroundStyle(palette.textPrimary)

                                Divider().overlay(palette.variantAccent.opacity(0.22))

                                ForEach(coordinator.dependencies.mythosCatalog.packs()) { pack in
                                    HStack {
                                        Text(pack.title)
                                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                                            .foregroundStyle(palette.textPrimary)
                                        Spacer()
                                        Text("\(pack.symbols.count) symbols")
                                            .font(.caption)
                                            .foregroundStyle(palette.textSecondary)
                                    }
                                }
                            }
                        }

                        MysticCard(palette: palette) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    MysticSectionHeader(title: "Diagnostics", palette: palette)
                                    infoButton(
                                        title: "Diagnostics",
                                        message: diagnosticsHelpText,
                                        palette: palette
                                    )
                                }

                                NavigationLink {
                                    DiagnosticsCenterView()
                                } label: {
                                    Label("Open Diagnostics Center", systemImage: "stethoscope")
                                        .font(.system(.body, design: .serif, weight: .semibold))
                                }
                                .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))
                            }
                            .foregroundStyle(palette.textPrimary)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                biometricLockEnabled = coordinator.dependencies.lockStore.isBiometricLockEnabled
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

    private var securityHelpText: String {
        "App Lock is optional and off by default. Your sensitive profile data is still encrypted at rest even when lock is disabled."
    }

    private var experienceHelpText: String {
        "Experience controls haptics and theme appearance. Sound is intentionally not active in this version."
    }

    private var privacyHelpText: String {
        "Rune Forge processes data locally. Apple Maps geocoding is the only online service used when resolving birthplace coordinates."
    }

    private var mythosHelpText: String {
        "Mythos packs are decorative symbol libraries for editor overlays. They never alter canonical sigil geometry."
    }

    private var diagnosticsHelpText: String {
        "Diagnostics Center records persistent app logs for testing. Use Export ZIP to share logs and troubleshooting context."
    }

    private func infoButton(title: String, message: String, palette: RFThemePalette) -> some View {
        Button {
            activeHelp = SettingsHelpTopic(title: title, message: message)
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(palette.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Info about \(title)")
    }
}

private struct SettingsHelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct DiagnosticsCenterView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    @State private var entries: [AppDiagnostics.LogEntry] = []
    @State private var searchText = ""
    @State private var selectedLevel = "All"
    @State private var selectedCategory = "All"
    @State private var sharePayload: DiagnosticsSharePayload?

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        List {
            Section("Filters") {
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag("All")
                    ForEach(AppDiagnostics.Level.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag("All")
                    ForEach(categoryOptions, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Button("Refresh") {
                        reloadEntries()
                    }
                    Spacer()
                    Button("Clear Log", role: .destructive) {
                        coordinator.dependencies.diagnostics.clearLog()
                        reloadEntries()
                    }
                }
            }

            Section("Log File") {
                Text(coordinator.dependencies.diagnostics.logFilePath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            Section("Entries (\(filteredEntries.count))") {
                if filteredEntries.isEmpty {
                    Text("No log entries match current filters.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredEntries) { entry in
                        DiagnosticsEntryRow(entry: entry, palette: palette)
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .searchable(text: $searchText, prompt: "Search entries")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportBundle()
                } label: {
                    Label("Export ZIP", systemImage: "square.and.arrow.up")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            MysticNebulaBackground(palette: palette)
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            reloadEntries()
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(activityItems: [payload.bundleURL])
        }
    }

    private var filteredEntries: [AppDiagnostics.LogEntry] {
        entries.filter { entry in
            let levelMatch = selectedLevel == "All" || entry.level.rawValue == selectedLevel
            let categoryMatch = selectedCategory == "All" || entry.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatch = query.isEmpty
                || entry.message.localizedCaseInsensitiveContains(query)
                || entry.category.localizedCaseInsensitiveContains(query)
                || entry.rawLine.localizedCaseInsensitiveContains(query)
            return levelMatch && categoryMatch && searchMatch
        }
    }

    private var categoryOptions: [String] {
        Array(Set(entries.map(\.category))).sorted()
    }

    private func reloadEntries() {
        entries = coordinator.dependencies.diagnostics.loadEntries()
    }

    private func exportBundle() {
        do {
            let bundleURL = try coordinator.prepareDiagnosticsArchive()
            coordinator.dependencies.diagnostics.record(
                "Prepared diagnostics archive at \(bundleURL.lastPathComponent).",
                level: .info,
                category: "diagnostics"
            )
            reloadEntries()
            sharePayload = DiagnosticsSharePayload(bundleURL: bundleURL)
        } catch {
            coordinator.errorMessage = "Failed to prepare diagnostics archive: \(error.localizedDescription)"
        }
    }
}

private struct DiagnosticsEntryRow: View {
    let entry: AppDiagnostics.LogEntry
    let palette: RFThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(formattedTimestamp)
                    .font(.caption2.monospaced())
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                Text(entry.level.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelBackgroundColor.opacity(0.2))
                    .clipShape(Capsule())
                Text(entry.category)
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
            }

            Text(entry.message)
                .font(.caption)
                .foregroundStyle(palette.textPrimary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private var formattedTimestamp: String {
        if let timestamp = entry.timestamp {
            return DiagnosticsEntryRow.timestampFormatter.string(from: timestamp)
        }
        return entry.timestampText
    }

    private var levelBackgroundColor: Color {
        switch entry.level {
        case .info:
            return .blue
        case .warning:
            return .yellow
        case .error:
            return .orange
        case .fault:
            return .red
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

private struct DiagnosticsSharePayload: Identifiable {
    let id = UUID()
    let bundleURL: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
