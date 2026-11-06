import RFSigilAPSIntegration
import RFSigilForsettiModules
import RFSigilRuntime
import XCTest

final class DashboardStatusTests: XCTestCase {
    func testDashboardContainsRequiredPhaseOneCards() {
        let assembly = SigilRuntimeAssembly()
        let status = assembly.dashboardStatus()

        XCTAssertEqual(
            status.cards.map(\.id),
            [
                "forsetti",
                "aps",
                "aeostara",
                "visible-glyph",
                "source-authority",
                "pipeline-placeholder",
                "privacy-security",
                "secure-persistence",
                "personalcodex"
            ]
        )
    }

    func testRuntimeAssemblyBuildsForsettiRuntime() {
        let assembly = SigilRuntimeAssembly()

        XCTAssertEqual(assembly.registration.entryPoints.count, 8)
        XCTAssertEqual(assembly.forsettiVersion, "0.1.4")
    }

    func testForsettiCardCountsMatchRegistration() {
        let assembly = SigilRuntimeAssembly()
        let status = assembly.dashboardStatus()
        let card = status.cards.first { $0.id == "forsetti" }
        let registration = SigilModuleRegistryInstaller.registrationSummary()

        XCTAssertEqual(registration.moduleIDs.count, SigilModuleCatalog.definitions.count)
        XCTAssertEqual(assembly.registration, registration)

        let uiCount = SigilModuleCatalog.definitions
            .filter { $0.descriptor.moduleType == .ui }
            .count
        let serviceCount = registration.moduleIDs.count - uiCount
        XCTAssertEqual(uiCount, 1)
        XCTAssertEqual(serviceCount, 7)

        XCTAssertTrue(card?.summary.contains("\(registration.moduleIDs.count) Sigil modules") ?? false)
        XCTAssertTrue(
            card?.detail.contains("\(uiCount) UI module and \(serviceCount) service modules") ?? false
        )
    }

    func testAPSCardStatesRecordedEvidenceNotLiveDependency() {
        let assembly = SigilRuntimeAssembly()
        let status = assembly.dashboardStatus()
        let card = status.cards.first { $0.id == "aps" }
        let gateway = SigilAPSIntegrationGateway().status()

        XCTAssertEqual(card?.status, gateway.sourceCoverage)
        XCTAssertTrue(card?.summary.contains("Recorded conformance evidence") ?? false)
        XCTAssertTrue(card?.summary.contains("not a live APS dependency or resolver") ?? false)
    }
}
