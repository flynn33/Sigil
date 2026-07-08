import ForsettiCore
import RFSigilAPSIntegration
import RFSigilAeostaraIntegration
import RFSigilCoreModels
import RFSigilDiagnostics
import RFSigilPipelinePlaceholder
import RFSigilPrivacySecurity
import RFSigilSourceAuthority
import RFSigilUIModule
import RFSigilVisibleGlyph

public struct SigilModuleDefinition {
    public let moduleID: String
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let factory: ModuleFactory

    public init(
        moduleID: String,
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        factory: @escaping ModuleFactory
    ) {
        self.moduleID = moduleID
        self.descriptor = descriptor
        self.manifest = manifest
        self.factory = factory
    }
}

public enum SigilModuleCatalog {
    public static let definitions: [SigilModuleDefinition] = [
        uiDefinition,
        apsDefinition,
        aeostaraDefinition,
        visibleGlyphDefinition,
        sourceAuthorityDefinition,
        pipelinePlaceholderDefinition,
        privacySecurityDefinition,
        diagnosticsDefinition
    ]

    private static let moduleVersion = SemVer(major: 0, minor: 1, patch: 0)
    private static let minForsettiVersion = SemVer(major: 0, minor: 1, patch: 4)

    private static var uiDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .ui,
            displayName: "Sigil Phase 1 Dashboard",
            moduleType: .ui,
            capabilities: [.viewInjection],
            entryPoint: "RFSigilUIModule.SigilUIModule",
            runtimeRequirements: ModuleRuntimeRequirements(
                ui: ModuleUIRequirements(
                    viewIDs: ["sigil.phase1.dashboard"],
                    slotIDs: ["sigil.primary"]
                )
            )
        ) { descriptor, manifest in
            SigilUIModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var apsDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .aps,
            displayName: "Sigil APS Gateway",
            moduleType: .service,
            capabilities: [],
            entryPoint: "RFSigilAPSIntegration.SigilAPSIntegrationModule"
        ) { descriptor, manifest in
            SigilAPSIntegrationModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var aeostaraDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .aeostara,
            displayName: "Sigil Aeostara Gateway",
            moduleType: .service,
            capabilities: [],
            entryPoint: "RFSigilAeostaraIntegration.SigilAeostaraIntegrationModule"
        ) { descriptor, manifest in
            SigilAeostaraIntegrationModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var sourceAuthorityDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .sourceAuthority,
            displayName: "Sigil Source Authority",
            moduleType: .service,
            capabilities: [],
            entryPoint: "RFSigilSourceAuthority.SigilSourceAuthorityModule"
        ) { descriptor, manifest in
            SigilSourceAuthorityModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var visibleGlyphDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .visibleGlyph,
            displayName: "Sigil Visible Glyph",
            moduleType: .service,
            capabilities: [],
            entryPoint: "RFSigilVisibleGlyph.SigilVisibleGlyphModule"
        ) { descriptor, manifest in
            SigilVisibleGlyphModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var pipelinePlaceholderDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .pipelinePlaceholder,
            displayName: "Sigil Pipeline Placeholder",
            moduleType: .service,
            capabilities: [],
            entryPoint: "RFSigilPipelinePlaceholder.SigilPipelinePlaceholderModule"
        ) { descriptor, manifest in
            SigilPipelinePlaceholderModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var privacySecurityDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .privacySecurity,
            displayName: "Sigil Privacy Security",
            moduleType: .service,
            capabilities: [.security],
            entryPoint: "RFSigilPrivacySecurity.SigilPrivacySecurityModule",
            defaultModuleRole: .security
        ) { descriptor, manifest in
            SigilPrivacySecurityModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static var diagnosticsDefinition: SigilModuleDefinition {
        makeDefinition(
            moduleID: .diagnostics,
            displayName: "Sigil Diagnostics",
            moduleType: .service,
            capabilities: [.diagnostics],
            entryPoint: "RFSigilDiagnostics.SigilDiagnosticsModule",
            defaultModuleRole: .diagnostics,
            runtimeRequirements: ModuleRuntimeRequirements(
                io: [
                    ModuleIORequirement(
                        requirementID: "sigil.local-diagnostics.emit",
                        kind: .diagnostics,
                        access: .emit,
                        required: true,
                        description: "Local diagnostic evidence aggregation"
                    )
                ]
            )
        ) { descriptor, manifest in
            SigilDiagnosticsModule(descriptor: descriptor, manifest: manifest)
        }
    }

    private static func makeDefinition(
        moduleID: SigilModuleID,
        displayName: String,
        moduleType: ModuleType,
        capabilities: [Capability],
        entryPoint: String,
        defaultModuleRole: DefaultModuleRole? = nil,
        runtimeRequirements: ModuleRuntimeRequirements = ModuleRuntimeRequirements(),
        factory: @escaping (_ descriptor: ModuleDescriptor, _ manifest: ModuleManifest) -> ForsettiModule
    ) -> SigilModuleDefinition {
        let descriptor = ModuleDescriptor(
            moduleID: moduleID.rawValue,
            displayName: displayName,
            moduleVersion: moduleVersion,
            moduleType: moduleType
        )
        let manifest = ModuleManifest(
            schemaVersion: ModuleManifest.currentSchemaVersion,
            manifestTemplateVersion: .v1_1,
            moduleID: moduleID.rawValue,
            displayName: displayName,
            moduleVersion: moduleVersion,
            moduleType: moduleType,
            supportedPlatforms: [.iOS],
            minForsettiVersion: minForsettiVersion,
            capabilitiesRequested: capabilities,
            entryPoint: entryPoint,
            defaultModuleRole: defaultModuleRole,
            runtimeRequirements: runtimeRequirements
        )

        return SigilModuleDefinition(
            moduleID: moduleID.rawValue,
            descriptor: descriptor,
            manifest: manifest,
            factory: { factory(descriptor, manifest) }
        )
    }
}

public struct SigilRuntimeRegistration: Hashable, Sendable {
    public let entryPoints: [String]
    public let moduleIDs: [String]

    public init(entryPoints: [String], moduleIDs: [String]) {
        self.entryPoints = entryPoints
        self.moduleIDs = moduleIDs
    }
}

public enum SigilModuleRegistryInstaller {
    public static func registerAll(into registry: ModuleRegistry) throws {
        for definition in SigilModuleCatalog.definitions {
            try registry.register(
                entryPoint: definition.manifest.entryPoint,
                factory: definition.factory
            )
        }
    }

    public static func registrationSummary() -> SigilRuntimeRegistration {
        SigilRuntimeRegistration(
            entryPoints: SigilModuleCatalog.definitions.map(\.manifest.entryPoint),
            moduleIDs: SigilModuleCatalog.definitions.map(\.moduleID)
        )
    }
}

public enum SigilRuntimeFactory {
    @MainActor
    public static func makeRuntime() throws -> ForsettiRuntime {
        let registry = ModuleRegistry()
        try SigilModuleRegistryInstaller.registerAll(into: registry)

        return ForsettiRuntime(
            capabilityPolicy: FixedCapabilityPolicy(
                allowedCapabilities: [.viewInjection, .security, .diagnostics]
            ),
            moduleRegistry: registry
        )
    }
}
