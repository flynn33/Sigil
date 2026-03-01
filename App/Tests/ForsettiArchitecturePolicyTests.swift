import Foundation
import XCTest

final class ForsettiArchitecturePolicyTests: XCTestCase {
    func testProjectIncludesForsettiAndSigilModulePackages() throws {
        let projectYML = try String(contentsOf: repositoryRoot().appendingPathComponent("project.yml"))

        XCTAssertTrue(projectYML.contains("ForsettiFramework:"), "project.yml must declare Forsetti framework package.")
        XCTAssertTrue(projectYML.contains("RFSigilForsettiModules:"), "project.yml must declare app-owned Forsetti modules package.")
        XCTAssertTrue(projectYML.contains("product: ForsettiCore"), "SigilApp target must depend on ForsettiCore.")
        XCTAssertTrue(projectYML.contains("product: ForsettiPlatform"), "SigilApp target must depend on ForsettiPlatform.")
        XCTAssertTrue(projectYML.contains("product: ForsettiHostTemplate"), "SigilApp target must depend on ForsettiHostTemplate.")
    }

    func testConsumerCodeDoesNotImportForsettiExampleModules() throws {
        let sourceRoots = [
            repositoryRoot().appendingPathComponent("App/Sources"),
            repositoryRoot().appendingPathComponent("Packages/RFSigilForsettiModules/Sources")
        ]

        let swiftFiles = sourceRoots.flatMap(recursiveSwiftFiles(at:))
        XCTAssertFalse(swiftFiles.isEmpty, "Expected source files for policy checks.")

        for fileURL in swiftFiles {
            let content = try String(contentsOf: fileURL)
            XCTAssertFalse(
                content.contains("import ForsettiModulesExample"),
                "Forbidden import in \(fileURL.path)"
            )
        }
    }

    private func recursiveSwiftFiles(at root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            return []
        }

        var result: [URL] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            result.append(fileURL)
        }
        return result
    }

    private func repositoryRoot(filePath: StaticString = #filePath) -> URL {
        var url = URL(fileURLWithPath: String(describing: filePath))
        url.deleteLastPathComponent() // Tests
        url.deleteLastPathComponent() // App
        return url
    }
}
