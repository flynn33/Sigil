import SwiftUI

enum RFThemeVariant: String, CaseIterable, Identifiable {
    case deepVoid = "deep_void"
    case twilightScroll = "twilight_scroll"
    case celestialLight = "celestial_light"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deepVoid:
            "Deep Void"
        case .twilightScroll:
            "Twilight Scroll"
        case .celestialLight:
            "Celestial Light"
        }
    }
}

struct RFThemePalette {
    let primaryBackground: Color
    let secondaryBackground: Color
    let accentBronze: Color
    let accentCrimson: Color
    let accentViolet: Color
    let textPrimary: Color
    let textSecondary: Color
    let glowHighlight: Color
    let variantAccent: Color
}

enum RFMysticTheme {
    static let defaultVariant: RFThemeVariant = .twilightScroll

    static func variant(from rawValue: String) -> RFThemeVariant {
        RFThemeVariant(rawValue: rawValue) ?? defaultVariant
    }

    static func palette(for variant: RFThemeVariant) -> RFThemePalette {
        let basePrimary = Color(hex: "#0B0C10")
        let baseSecondary = Color(hex: "#14151A")
        let bronze = Color(hex: "#A67C52")
        let crimson = Color(hex: "#8C1C13")
        let violet = Color(hex: "#4B3F72")
        let textPrimary = Color(hex: "#EAE7DC")
        let textSecondary = Color(hex: "#B8B8C0")
        let glow = Color(hex: "#C8A2FF")

        let variantAccent: Color
        let primaryBackground: Color

        switch variant {
        case .deepVoid:
            variantAccent = Color(hex: "#6A0DAD")
            primaryBackground = Color(hex: "#050508")
        case .twilightScroll:
            variantAccent = bronze
            primaryBackground = Color(hex: "#1C1B22")
        case .celestialLight:
            variantAccent = glow
            primaryBackground = Color(hex: "#20232A")
        }

        return RFThemePalette(
            primaryBackground: primaryBackground,
            secondaryBackground: baseSecondary,
            accentBronze: bronze,
            accentCrimson: crimson,
            accentViolet: violet,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            glowHighlight: glow,
            variantAccent: variantAccent
        )
    }
}

struct MysticNebulaBackground: View {
    let palette: RFThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.primaryBackground, palette.secondaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    palette.accentViolet.opacity(0.28),
                    palette.accentCrimson.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 560
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    palette.variantAccent.opacity(0.22),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 420
            )
            .ignoresSafeArea()

            ParchmentGrainOverlay()
                .opacity(0.08)
                .ignoresSafeArea()
        }
    }
}

private struct ParchmentGrainOverlay: View {
    private static let points: [CGPoint] = {
        (0..<220).map { index in
            let x = CGFloat((index * 73) % 1000) / 1000
            let y = CGFloat((index * 197) % 1000) / 1000
            return CGPoint(x: x, y: y)
        }
    }()

    var body: some View {
        Canvas { context, size in
            for point in Self.points {
                let rect = CGRect(
                    x: point.x * size.width,
                    y: point.y * size.height,
                    width: 1.4,
                    height: 1.4
                )
                context.fill(Path(rect), with: .color(.white.opacity(0.22)))
            }
        }
    }
}

struct MysticCard<Content: View>: View {
    let palette: RFThemePalette
    let content: Content

    init(
        palette: RFThemePalette,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.secondaryBackground.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.variantAccent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: palette.glowHighlight.opacity(0.12), radius: 14, x: 0, y: 4)
    }
}

struct MysticSectionHeader: View {
    let title: String
    let palette: RFThemePalette

    var body: some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .serif, weight: .semibold))
            .tracking(1.3)
            .foregroundStyle(palette.variantAccent)
    }
}

struct GlowActionButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(configuration.isPressed ? 0.2 : 0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: accent.opacity(configuration.isPressed ? 0.2 : 0.32), radius: configuration.isPressed ? 6 : 10, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.28), value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        case 6:
            a = 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 0xFF
            r = 0xFF
            g = 0x00
            b = 0xFF
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
