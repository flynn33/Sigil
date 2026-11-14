import SwiftUI

/// About destination: product identity, version, privacy posture, license.
public struct SigilAboutView: View {
    public init() {}

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SigilVisualTheme.brandName)
                        .font(.title2.weight(.semibold))
                    Text("A local-first iOS app for deterministic ASH/WRW identity interpretation and Sigil generation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            Section("Version") {
                LabeledContent("Marketing version", value: marketingVersion)
                LabeledContent("Build", value: buildNumber)
            }

            Section("Privacy") {
                Text("Sigil keeps personal input, PersonalCodex records, and glyphs on this device. There is no analytics SDK and no application backend upload.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("License") {
                Text("Personal-use and research source license. See LICENSE in the project repository.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle("About")
        .sigilInlineNavigationTitle()
    }

    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "—"
    }
}
