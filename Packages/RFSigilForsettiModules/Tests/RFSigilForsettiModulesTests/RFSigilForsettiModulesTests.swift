import Foundation
import ForsettiCore
import Testing
@testable import RFSigilForsettiModules

@Test
func registryRegistersSigilCoreModule() throws {
    let registry = ModuleRegistry()
    SigilForsettiModuleRegistry.registerAll(into: registry)

    let module = try registry.makeModule(entryPoint: SigilCoreModule.entryPoint)
    #expect(module.descriptor.moduleID == SigilCoreModule.moduleID)
    #expect((module as? any ForsettiUIModule) != nil)
}

@Test
func moduleManifestExistsInResourceBundle() throws {
    let manifestURL = try #require(
        SigilForsettiModuleResources.bundle.url(
            forResource: "SigilCoreModule",
            withExtension: "json"
        )
    )

    #expect(FileManager.default.fileExists(atPath: manifestURL.path))
}
