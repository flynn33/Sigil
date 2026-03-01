import Foundation
import ForsettiCore
import Testing
@testable import RFSigilForsettiModules

@Test
func registryRegistersSigilModules() throws {
    let registry = ModuleRegistry()
    SigilForsettiModuleRegistry.registerAll(into: registry)

    let service = try registry.makeModule(entryPoint: SigilCoreServiceModule.entryPoint)
    let ui = try registry.makeModule(entryPoint: SigilCodexUIModule.entryPoint)

    #expect(service.descriptor.moduleID == SigilCoreServiceModule.moduleID)
    #expect(ui.descriptor.moduleID == SigilCodexUIModule.moduleID)
    #expect((ui as? any ForsettiUIModule) != nil)
}

@Test
func moduleManifestsExistInResourceBundle() throws {
    let serviceURL = try #require(
        SigilForsettiModuleResources.bundle.url(
            forResource: "SigilCoreServiceModule",
            withExtension: "json"
        )
    )
    let uiURL = try #require(
        SigilForsettiModuleResources.bundle.url(
            forResource: "SigilCodexUIModule",
            withExtension: "json"
        )
    )

    #expect(FileManager.default.fileExists(atPath: serviceURL.path))
    #expect(FileManager.default.fileExists(atPath: uiURL.path))
}
