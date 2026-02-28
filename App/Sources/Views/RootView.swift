import SwiftUI

struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        return TabView {
            ProfilesView()
                .tabItem {
                    Label("Codex", systemImage: "book.closed")
                }

            SigilStudioView()
                .tabItem {
                    Label("Sigil Lab", systemImage: "sparkles")
                }

            LoreView()
                .tabItem {
                    Label("Lore", systemImage: "moon.stars")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(palette.glowHighlight)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(palette.secondaryBackground.opacity(0.94), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background {
            MysticNebulaBackground(palette: palette)
                .ignoresSafeArea()
        }
        .overlay {
            if coordinator.isAppLocked {
                AppLockOverlayView(
                    isUnlocking: coordinator.isAppUnlockInProgress,
                    palette: palette,
                    unlockAction: {
                        Task { await coordinator.unlockApp() }
                    }
                )
            }
        }
        .task {
            coordinator.bootstrapDiagnosticsIfNeeded()
            coordinator.initializeAppLockState()
            if coordinator.isAppLocked {
                await coordinator.unlockApp()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                coordinator.dependencies.diagnostics.recordAppDidBecomeActive()
                coordinator.handleAppBecameActive()
                if coordinator.isAppLocked {
                    Task { await coordinator.unlockApp() }
                }
            case .background:
                coordinator.dependencies.diagnostics.recordAppDidEnterBackground()
                coordinator.lockAppForBackground()
            case .inactive:
                coordinator.lockAppForBackground()
            @unknown default:
                break
            }
        }
        .alert("Sigil", isPresented: Binding(get: {
            coordinator.errorMessage != nil
        }, set: { newValue in
            if !newValue {
                coordinator.clearError()
            }
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(coordinator.errorMessage ?? "")
        }
    }
}

private struct AppLockOverlayView: View {
    let isUnlocking: Bool
    let palette: RFThemePalette
    let unlockAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(palette.variantAccent)

                Text("Sigil is Locked")
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)

                Text("Authenticate with Face ID or device passcode to continue.")
                    .font(.system(.subheadline, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.textSecondary)

                Button(action: unlockAction) {
                    if isUnlocking {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Unlock")
                    }
                }
                .buttonStyle(GlowActionButtonStyle(accent: palette.variantAccent))
                .disabled(isUnlocking)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(palette.secondaryBackground.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(palette.variantAccent.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }
}
