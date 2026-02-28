import RFCoreModels
import SwiftUI

struct SigilGeometryView: View {
    let geometry: SigilGeometry
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))
        let complexity = max(1, geometry.lines.count)
        let baseWidth = CGFloat((3.25 - log(Double(complexity) + 1.0) * 0.30).clamped(to: 1.25...2.8))

        GeometryReader { _ in
            Canvas { context, size in
                var path = Path()
                for line in geometry.lines {
                    let start = CGPoint(x: line.startX * size.width, y: line.startY * size.height)
                    let end = CGPoint(x: line.endX * size.width, y: line.endY * size.height)
                    path.move(to: start)
                    path.addLine(to: end)
                }

                context.addFilter(.shadow(color: palette.glowHighlight.opacity(0.35), radius: baseWidth * 3.8, x: 0, y: 0))
                context.stroke(path, with: .color(palette.glowHighlight.opacity(0.32)), lineWidth: baseWidth * 2.35)
                context.stroke(path, with: .color(palette.glowHighlight.opacity(0.96)), lineWidth: baseWidth)
                context.stroke(path, with: .color(.white.opacity(0.24)), lineWidth: max(0.45, baseWidth * 0.42))
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [palette.secondaryBackground.opacity(0.98), palette.primaryBackground.opacity(0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [palette.glowHighlight.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 12,
                        endRadius: 220
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(palette.variantAccent.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
