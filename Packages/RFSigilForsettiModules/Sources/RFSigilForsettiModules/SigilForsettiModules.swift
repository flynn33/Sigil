import Foundation
import ForsettiCore

public final class SigilCoreServiceModule: ForsettiModule {
    public static let moduleID = "com.sigil.module.core-service"
    public static let entryPoint = "SigilCoreServiceModule"

    public let descriptor = ModuleDescriptor(
        moduleID: SigilCoreServiceModule.moduleID,
        displayName: "Sigil Core Service",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .service
    )

    public let manifest = ModuleManifest(
        schemaVersion: ModuleManifest.supportedSchemaVersion,
        moduleID: SigilCoreServiceModule.moduleID,
        displayName: "Sigil Core Service",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .service,
        supportedPlatforms: [.iOS, .macOS],
        minForsettiVersion: SemVer(major: 0, minor: 1, patch: 0),
        capabilitiesRequested: [.storage, .secureStorage, .telemetry],
        iapProductID: nil,
        entryPoint: SigilCoreServiceModule.entryPoint
    )

    private var isStarted = false

    public init() {}

    public func start(context: ForsettiContext) throws {
        guard !isStarted else { return }
        isStarted = true
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCoreServiceModule started")
    }

    public func stop(context: ForsettiContext) {
        guard isStarted else { return }
        isStarted = false
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCoreServiceModule stopped")
    }
}

public final class SigilCodexUIModule: ForsettiUIModule {
    public static let moduleID = "com.sigil.module.codex-ui"
    public static let entryPoint = "SigilCodexUIModule"
    public static let rootShellViewID = "sigil-root-shell"
    public static let homeBannerViewID = "sigil-home-banner"

    public let descriptor = ModuleDescriptor(
        moduleID: SigilCodexUIModule.moduleID,
        displayName: "Sigil Codex Workspace",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .ui
    )

    public let manifest = ModuleManifest(
        schemaVersion: ModuleManifest.supportedSchemaVersion,
        moduleID: SigilCodexUIModule.moduleID,
        displayName: "Sigil Codex Workspace",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .ui,
        supportedPlatforms: [.iOS, .macOS],
        minForsettiVersion: SemVer(major: 0, minor: 1, patch: 0),
        capabilitiesRequested: [.routingOverlay, .toolbarItems, .viewInjection, .uiThemeMask],
        iapProductID: nil,
        entryPoint: SigilCodexUIModule.entryPoint
    )

    public let uiContributions = UIContributions(
        toolbarItems: [
            ToolbarItemDescriptor(
                itemID: "sigil-home",
                title: "Codex Home",
                systemImageName: "house.fill",
                action: .navigate(pointerID: "sigil-home-pointer")
            )
        ],
        viewInjections: [
            ViewInjectionDescriptor(
                injectionID: "sigil-home-banner",
                slot: "home.banner",
                viewID: SigilCodexUIModule.homeBannerViewID,
                priority: 200
            ),
            ViewInjectionDescriptor(
                injectionID: "sigil-root-shell",
                slot: "module.workspace",
                viewID: SigilCodexUIModule.rootShellViewID,
                priority: 1000
            )
        ],
        overlaySchema: OverlaySchema(
            schemaID: "sigil.codex.overlay-schema.v1",
            pointers: [
                NavigationPointer(
                    pointerID: "sigil-home-pointer",
                    label: "Home",
                    target: BaseDestinationRef(destinationID: "home"),
                    presentation: .inline
                )
            ],
            routes: [
                OverlayRoute(
                    routeID: "sigil-workspace-route",
                    path: "/sigil/workspace",
                    destination: .moduleOverlay(viewID: SigilCodexUIModule.rootShellViewID, slot: "module.workspace")
                )
            ]
        )
    )

    private var isStarted = false

    public init() {}

    public func start(context: ForsettiContext) throws {
        guard !isStarted else { return }
        isStarted = true
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCodexUIModule started")
    }

    public func stop(context: ForsettiContext) {
        guard isStarted else { return }
        isStarted = false
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCodexUIModule stopped")
    }
}

public enum SigilForsettiModuleRegistry {
    public static func registerAll(into registry: ModuleRegistry) {
        registry.register(entryPoint: SigilCoreServiceModule.entryPoint) {
            SigilCoreServiceModule()
        }
        registry.register(entryPoint: SigilCodexUIModule.entryPoint) {
            SigilCodexUIModule()
        }
    }
}
