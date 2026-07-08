import ForsettiCore
import RFSigilForsettiModules
import RFSigilCoreModels
import XCTest

final class ForsettiModuleRegistrationTests: XCTestCase {
    func testCatalogHasExactlyOnePrimaryUIModule() {
        let uiModules = SigilModuleCatalog.definitions.filter { $0.manifest.moduleType == .ui }
        XCTAssertEqual(uiModules.map(\.moduleID), [SigilModuleID.ui.rawValue])
    }

    func testServiceModulesDoNotOwnPrimaryUI() {
        let serviceModules = SigilModuleCatalog.definitions.filter { $0.manifest.moduleType == .service }
        XCTAssertFalse(serviceModules.isEmpty)
        XCTAssertTrue(serviceModules.allSatisfy { $0.manifest.runtimeRequirements.ui == nil })
    }

    func testManifestsUseCurrentTemplateAndRuntimeRequirements() {
        for definition in SigilModuleCatalog.definitions {
            XCTAssertEqual(definition.manifest.schemaVersion, ModuleManifest.currentSchemaVersion)
            XCTAssertEqual(definition.manifest.manifestTemplateVersion, .v1_1)
            XCTAssertEqual(definition.descriptor.moduleID, definition.manifest.moduleID)
            XCTAssertEqual(definition.descriptor.moduleType, definition.manifest.moduleType)
        }
    }

    func testCapabilityPolicyExcludesNetworkAndTelemetry() {
        for definition in SigilModuleCatalog.definitions {
            XCTAssertFalse(definition.manifest.capabilitiesRequested.contains(.networking))
            XCTAssertFalse(definition.manifest.capabilitiesRequested.contains(.telemetry))
            XCTAssertFalse(definition.manifest.capabilitiesRequested.contains(.api))
        }
    }

    func testRegistryCreatesAllSigilModulesThroughPublicFactories() throws {
        let registry = ModuleRegistry()
        try SigilModuleRegistryInstaller.registerAll(into: registry)

        XCTAssertEqual(
            Set(registry.registeredEntryPoints),
            Set(SigilModuleCatalog.definitions.map(\.manifest.entryPoint))
        )

        for definition in SigilModuleCatalog.definitions {
            let module = try registry.makeModule(entryPoint: definition.manifest.entryPoint)
            XCTAssertEqual(module.descriptor.moduleID, definition.moduleID)
            XCTAssertEqual(module.manifest.entryPoint, definition.manifest.entryPoint)
        }
    }
}
