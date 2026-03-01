import Foundation
import ForsettiCore

public final class SigilCoreModule: ForsettiUIModule {
    public static let moduleID = "com.sigil.module.core"
    public static let entryPoint = "SigilCoreModule"
    public static let rootShellViewID = "sigil-root-shell"

    public let descriptor = ModuleDescriptor(
        moduleID: SigilCoreModule.moduleID,
        displayName: "Sigil Core",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .ui
    )

    public let manifest = ModuleManifest(
        schemaVersion: ModuleManifest.supportedSchemaVersion,
        moduleID: SigilCoreModule.moduleID,
        displayName: "Sigil Core",
        moduleVersion: SemVer(major: 1, minor: 0, patch: 0),
        moduleType: .ui,
        supportedPlatforms: [.iOS, .macOS],
        minForsettiVersion: SemVer(major: 0, minor: 1, patch: 0),
        capabilitiesRequested: [.storage, .secureStorage, .telemetry, .viewInjection, .uiThemeMask],
        iapProductID: nil,
        entryPoint: SigilCoreModule.entryPoint
    )

    public let uiContributions = UIContributions(
        themeMask: ThemeMask(
            themeID: "sigil.core.theme.v1",
            tokens: [
                ThemeToken(key: "sigil.accent", value: "#A4693D"),
                ThemeToken(key: "sigil.background", value: "#0E1116"),
                ThemeToken(key: "sigil.surface", value: "#1A232E")
            ]
        ),
        toolbarItems: [],
        viewInjections: [
            ViewInjectionDescriptor(
                injectionID: "sigil-root-shell",
                slot: "module.workspace",
                viewID: SigilCoreModule.rootShellViewID,
                priority: 1000
            )
        ],
        overlaySchema: nil
    )

    private var isStarted = false

    public init() {}

    public func start(context: ForsettiContext) throws {
        guard !isStarted else { return }
        isStarted = true
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCoreModule started")
    }

    public func stop(context: ForsettiContext) {
        guard isStarted else { return }
        isStarted = false
        context.moduleLogger(moduleID: descriptor.moduleID).info("SigilCoreModule stopped")
    }
}

public enum SigilForsettiModuleRegistry {
    public static func registerAll(into registry: ModuleRegistry) {
        registry.register(entryPoint: SigilCoreModule.entryPoint) {
            SigilCoreModule()
        }
    }
}
