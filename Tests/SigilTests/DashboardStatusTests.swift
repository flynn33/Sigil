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
                "privacy-security"
            ]
        )
    }

    func testRuntimeAssemblyBuildsForsettiRuntime() {
        let assembly = SigilRuntimeAssembly()

        XCTAssertEqual(assembly.registration.entryPoints.count, 8)
        XCTAssertEqual(assembly.forsettiVersion, "0.1.4")
    }
}
