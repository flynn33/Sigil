import RFCoreModels
import RFStorage
import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue
    @AppStorage("rf.generation.include_extensions") private var includeExtensions = true

    @State private var editorModel = ProfileFormModel()
    @State private var isEditorPresented = false
    @State private var isBreathing = false
    @State private var activeHelp: ProfilesHelpTopic?

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        NavigationStack {
            ZStack {
                MysticNebulaBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            MysticSectionHeader(title: "Home Dashboard", palette: palette)
                            infoButton(
                                title: "Codex Home",
                                message: codexHomeHelpText,
                                palette: palette
                            )
                        }
                        dashboardCard(palette: palette)
                        quickActions(palette: palette)
                        profilesCard(palette: palette)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Codex")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isEditorPresented) {
                NavigationStack {
                    ProfileEditorView(model: editorModel) { profile in
                        Task {
                            await coordinator.createOrUpdateProfile(profile)
                            isEditorPresented = false
                        }
                    }
                }
            }
            .alert(item: $activeHelp) { topic in
                Alert(
                    title: Text(topic.title),
                    message: Text(topic.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
        }
    }

    private func dashboardCard(palette: RFThemePalette) -> some View {
        MysticCard(palette: palette) {
            VStack(alignment: .leading, spacing: 12) {
                if let sigil = coordinator.activeSigil {
                    Text(sigil.celestialName)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(palette.textPrimary)

                    ZStack {
                        Circle()
                            .fill(palette.variantAccent.opacity(0.12))
                            .frame(width: 250, height: 250)
                            .blur(radius: isBreathing ? 20 : 14)

                        SigilGeometryView(geometry: sigil.geometry)
                            .frame(width: 230, height: 230)
                            .scaleEffect(isBreathing ? 1.02 : 0.98)
                            .shadow(color: palette.glowHighlight.opacity(isBreathing ? 0.45 : 0.22), radius: isBreathing ? 16 : 8)
                    }
                    .frame(maxWidth: .infinity)

                    Text(coordinator.activeMeaning?.summary ?? "The codex is listening.")
                        .font(.system(.body, design: .serif))
                        .lineSpacing(4)
                        .foregroundStyle(palette.textSecondary)
                } else if let profile = coordinator.selectedProfile {
                    Text(profile.displayName)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text("Profile selected. Generate a sigil in Sigil Lab to reveal celestial name and lore.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(palette.textSecondary)
                } else {
                    Text("No active codex yet.")
                        .font(.system(.headline, design: .serif, weight: .semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text("Create or select a profile below. Then generate your sigil to awaken your celestial narrative.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    private func quickActions(palette: RFThemePalette) -> some View {
        MysticCard(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    MysticSectionHeader(title: "Actions", palette: palette)
                    infoButton(
                        title: "Actions",
                        message: actionsHelpText,
                        palette: palette
                    )
                }
                HStack(spacing: 10) {
                    Button {
                        editorModel = ProfileFormModel()
                        isEditorPresented = true
                    } label: {
                        Label("New Profile", systemImage: "plus")
                    }
                    .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))

                    Button {
                        Task { await coordinator.generateSigil(options: .init(includeTraitExtensions: includeExtensions)) }
                    } label: {
                        Label("Generate Sigil", systemImage: "sparkles")
                    }
                    .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))
                    .disabled(coordinator.selectedProfile == nil)
                }
            }
        }
    }

    private func profilesCard(palette: RFThemePalette) -> some View {
        MysticCard(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    MysticSectionHeader(title: "Profiles", palette: palette)
                    infoButton(
                        title: "Profiles",
                        message: profilesListHelpText,
                        palette: palette
                    )
                }

                if coordinator.profiles.isEmpty {
                    Text("No profiles yet. Start by creating one.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(palette.textSecondary)
                } else {
                    ForEach(Array(coordinator.profiles.enumerated()), id: \.element.id) { index, summary in
                        if index > 0 {
                            Divider().overlay(palette.variantAccent.opacity(0.25))
                        }

                        profileRow(summary: summary, palette: palette)
                    }
                }
            }
        }
    }

    private func profileRow(summary: StoredProfileSummary, palette: RFThemePalette) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.displayName)
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(summary.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            if coordinator.selectedProfile?.id == summary.id {
                Text("ACTIVE")
                    .font(.system(.caption2, design: .serif, weight: .bold))
                    .tracking(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(palette.variantAccent.opacity(0.22), in: Capsule())
                    .foregroundStyle(palette.variantAccent)
            }

            Button("Select") {
                Task { await coordinator.openProfile(summary) }
            }
            .buttonStyle(GlowActionButtonStyle(accent: palette.glowHighlight))

            Menu {
                Button("Edit") {
                    Task { await openEditor(for: summary) }
                }
                Button("Delete", role: .destructive) {
                    Task { await coordinator.deleteProfile(summary) }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func openEditor(for summary: StoredProfileSummary) async {
        await coordinator.openProfile(summary)
        guard let selected = coordinator.selectedProfile else { return }
        editorModel = ProfileFormModel(profile: selected)
        isEditorPresented = true
    }

    private var codexHomeHelpText: String {
        "Codex is your local profile and narrative hub. Create/select a profile, generate your sigil, then review lore and export from Sigil Lab."
    }

    private var actionsHelpText: String {
        "Use New Profile to enter personal data. Generate Sigil runs deterministic local creation using your active profile."
    }

    private var profilesListHelpText: String {
        "Select sets the active profile used by Sigil Lab and Lore. Edit updates profile fields; Delete removes that profile from local storage."
    }

    private func infoButton(title: String, message: String, palette: RFThemePalette) -> some View {
        Button {
            activeHelp = ProfilesHelpTopic(title: title, message: message)
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(palette.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Info about \(title)")
    }
}

private struct ProfilesHelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
