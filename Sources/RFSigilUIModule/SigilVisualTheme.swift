import SwiftUI

/// Shared visual tokens for branded surfaces (Home, Result glyph frame).
/// Forms and Settings keep system materials; these tokens stay restrained.
public enum SigilVisualTheme {
    public static let brandName = "Sigil"

    public static let supportingLine =
        "Generate a deterministic, local-only identity glyph from retained inputs."

    public static var atmosphere: some View {
        LinearGradient(
            colors: [
                Color.primary.opacity(0.06),
                Color.clear,
                Color.primary.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    public static let heroSymbolName = "seal"
    public static let spacingSection: CGFloat = 28
    public static let spacingStack: CGFloat = 16
    public static let cornerRadius: CGFloat = 16
}

extension View {
    /// `navigationBarTitleDisplayMode` is iOS-only; no-op on macOS package builds.
    @ViewBuilder
    func sigilInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Full-screen Create task on iOS; sheet on macOS (where fullScreenCover is unavailable).
    @ViewBuilder
    func sigilTaskCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, content: content)
        #else
        self.sheet(isPresented: isPresented, content: content)
        #endif
    }
}
