import ForsettiCore
import ForsettiHostTemplate
import ForsettiPlatform
import RFSigilForsettiModules
import SwiftUI

@MainActor
struct SigilForsettiHostArtifacts {
    let controller: ForsettiHostController
    let injectionRegistry: ForsettiViewInjectionRegistry
    let primaryModuleID: String
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
        injectionRegistry.register(viewID: SigilCoreModule.rootShellViewID) {
            RootView()
                .environmentObject(coordinator)
        }

        return SigilForsettiHostArtifacts(
            controller: hostController,
            injectionRegistry: injectionRegistry,
            primaryModuleID: SigilCoreModule.moduleID
        )
    }
}
