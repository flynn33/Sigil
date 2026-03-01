import ForsettiCore
import ForsettiHostTemplate
import ForsettiPlatform
import RFSigilForsettiModules
import SwiftUI

@MainActor
struct SigilForsettiHostArtifacts {
    let controller: ForsettiHostController
    let injectionRegistry: ForsettiViewInjectionRegistry
}

@MainActor
enum SigilForsettiBootstrap {
    static func makeHostArtifacts(coordinator: AppCoordinator) -> SigilForsettiHostArtifacts {
        let moduleRegistry = ModuleRegistry()
        SigilForsettiModuleRegistry.registerAll(into: moduleRegistry)

        let entitlementProvider = AllowAllEntitlementProvider()
        let platformServices = DefaultForsettiPlatformServices()
        platformServices.container.register(AppCoordinator.self, service: coordinator)

        let uiSurfaceManager = UISurfaceManager()
        let router = ForsettiHostOverlayRouter(
            uiSurfaceManager: uiSurfaceManager,
            baseDestinationIDs: BaseDestinationCatalog.all,
            slotIDs: SlotCatalog.all
        )

        let runtime = ForsettiRuntime(
            services: platformServices.container,
            entitlementProvider: entitlementProvider,
            capabilityPolicy: AllowAllCapabilityPolicy(),
            activationStore: UserDefaultsActivationStore(key: "com.sigil.forsetti.activation.state"),
            router: router,
            moduleRegistry: moduleRegistry,
            uiSurfaceManager: uiSurfaceManager
        )

        let hostController = ForsettiHostController(
            runtime: runtime,
            entitlementProvider: entitlementProvider,
            manifestsBundle: SigilForsettiModuleResources.bundle,
            manifestsSubdirectory: "ForsettiManifests",
            slotCatalog: SlotCatalog.all
        )

        let injectionRegistry = ForsettiViewInjectionRegistry()
        injectionRegistry.register(viewID: SigilCodexUIModule.rootShellViewID) {
            RootView()
                .environmentObject(coordinator)
        }
        injectionRegistry.register(viewID: SigilCodexUIModule.homeBannerViewID) {
            SigilForsettiHomeBannerView(coordinator: coordinator)
        }

        return SigilForsettiHostArtifacts(
            controller: hostController,
            injectionRegistry: injectionRegistry
        )
    }
}

private struct SigilForsettiHomeBannerView: View {
    @ObservedObject var coordinator: AppCoordinator
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        VStack(alignment: .leading, spacing: 8) {
            Text("Sigil Framework Workspace")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(palette.textPrimary)

            if let profile = coordinator.selectedProfile {
                Text("Active profile: \(profile.displayName)")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            } else {
                Text("Select a profile in Codex, then generate in Sigil Lab.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.secondaryBackground.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.variantAccent.opacity(0.25), lineWidth: 1)
        )
    }
}
