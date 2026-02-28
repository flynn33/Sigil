import RFCoreModels
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private struct LoreFragment: Identifiable {
    let id: Int
    let title: String
    let body: String
}

struct LoreView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue
    @State private var searchText = ""
    @State private var copiedFragmentTitle: String?
    @State private var activeHelp: LoreHelpTopic?

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        NavigationStack {
            ZStack {
                MysticNebulaBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            MysticSectionHeader(title: "Lore", palette: palette)
                            infoButton(
                                title: "Lore",
                                message: loreHelpText,
                                palette: palette
                            )
                        }

                        if let meaning = coordinator.activeMeaning {
                            MysticCard(palette: palette) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(meaning.title)
                                        .font(.system(.title2, design: .serif, weight: .bold))
                                        .foregroundStyle(palette.textPrimary)

                                    if let name = coordinator.activeSigil?.celestialName {
                                        Text(name)
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(palette.variantAccent)
                                    }

                                    Text(meaning.summary)
                                        .font(.system(.body, design: .serif))
                                        .lineSpacing(4)
                                        .foregroundStyle(palette.textPrimary)
                                }
                            }

                            MysticCard(palette: palette) {
                                VStack(alignment: .leading, spacing: 12) {
                                    let fragments = filteredFragments(for: meaning)

                                    HStack(spacing: 8) {
                                        Text("Codex Fragments (\(fragments.count))")
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(palette.textPrimary)
                                        infoButton(
                                            title: "Codex Fragments",
                                            message: fragmentsHelpText,
                                            palette: palette
                                        )
                                    }

                                    Text("Each fragment includes `Idiom Meaning` and `Your Sigil Application` to explain what it means and why it applies to your sigil.")
                                        .font(.caption)
                                        .foregroundStyle(palette.textSecondary)

                                    if let copiedFragmentTitle {
                                        Text("Copied: \(copiedFragmentTitle)")
                                            .font(.caption)
                                            .foregroundStyle(palette.textSecondary)
                                    }

                                    if fragments.isEmpty {
                                        Text("No lore fragments match your search.")
                                            .font(.system(.body, design: .serif))
                                            .foregroundStyle(palette.textSecondary)
                                    } else {
                                        ForEach(Array(fragments.enumerated()), id: \.element.id) { index, fragment in
                                            loreFragmentCard(fragment: fragment, index: index + 1, palette: palette)
                                                .transition(.opacity)
                                        }
                                    }
                                }
                            }
                        } else {
                            MysticCard(palette: palette) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No narrative yet.")
                                        .font(.system(.headline, design: .serif, weight: .semibold))
                                        .foregroundStyle(palette.textPrimary)

                                    Text("Generate a sigil in Sigil Lab to reveal your codex meaning and celestial narrative.")
                                        .font(.system(.body, design: .serif))
                                        .foregroundStyle(palette.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Lore")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search lore fragments")
            .alert(item: $activeHelp) { topic in
                Alert(
                    title: Text(topic.title),
                    message: Text(topic.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func loreFragmentCard(fragment: LoreFragment, index: Int, palette: RFThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(index). \(fragment.title)")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Button {
                    copy(fragment: fragment)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy \(fragment.title)")
            }

            Text(fragment.body)
                .font(.system(.body, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.secondaryBackground.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(palette.variantAccent.opacity(0.22), lineWidth: 1)
        )
    }

    private func fragments(for meaning: MeaningNarrative) -> [LoreFragment] {
        meaning.sections.enumerated().map { index, section in
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let colonIndex = trimmed.firstIndex(of: ":") else {
                return LoreFragment(
                    id: index,
                    title: "Fragment \(index + 1)",
                    body: trimmed
                )
            }

            let title = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)

            if title.isEmpty || body.isEmpty {
                return LoreFragment(
                    id: index,
                    title: "Fragment \(index + 1)",
                    body: trimmed
                )
            }

            return LoreFragment(id: index, title: title, body: body)
        }
    }

    private func filteredFragments(for meaning: MeaningNarrative) -> [LoreFragment] {
        let all = fragments(for: meaning)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return all }
        return all.filter { fragment in
            fragment.title.localizedCaseInsensitiveContains(query)
                || fragment.body.localizedCaseInsensitiveContains(query)
        }
    }

    private func copy(fragment: LoreFragment) {
        #if canImport(UIKit)
        UIPasteboard.general.string = "\(fragment.title): \(fragment.body)"
        #endif
        copiedFragmentTitle = fragment.title
    }

    private var loreHelpText: String {
        "Lore translates your generated sigil into personal codex narrative. It explains idioms, meanings, and how they map to your sigil."
    }

    private var fragmentsHelpText: String {
        "Each fragment includes idiom context and your personal application. Use search to filter by keywords and copy to share."
    }

    private func infoButton(title: String, message: String, palette: RFThemePalette) -> some View {
        Button {
            activeHelp = LoreHelpTopic(title: title, message: message)
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(palette.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Info about \(title)")
    }
}

private struct LoreHelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
