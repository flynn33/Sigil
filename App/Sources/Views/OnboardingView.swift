import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        ZStack {
            MysticNebulaBackground(palette: palette)

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Sigil")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundStyle(palette.textPrimary)

                    Text("Ancient language. Modern interface.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(palette.variantAccent)
                }

                MysticCard(palette: palette) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create your personal sigil fully on-device. Data is encrypted locally, and network access is used only for Apple Maps coordinate lookup.")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(palette.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Local-only generation", systemImage: "lock.shield")
                            Label("Optional biometric app lock", systemImage: "faceid")
                            Label("Mythos-aligned symbolic catalog", systemImage: "sparkles")
                        }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(palette.textSecondary)
                    }
                }

                Spacer()

                Button("Enter Sigil") {
                    onContinue()
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
                .padding(.bottom, 36)
            }
            .padding(20)
        }
    }
}
