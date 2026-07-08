import RFSigilCoreModels
import RFSigilPipelinePlaceholder
import XCTest

final class PlaceholderPipelineTests: XCTestCase {
    func testPipelineIsUnavailableAndPlaceholderOnly() {
        let status = SigilPipelinePlaceholderService().status()

        XCTAssertFalse(status.available)
        XCTAssertEqual(status.phase, "Phase 1")
        XCTAssertEqual(status.implementedFinalFeatures, [])
        XCTAssertEqual(status.unavailableReason, .placeholderOnly)
    }

    func testForbiddenFeatureListMatchesPhaseOneContract() {
        XCTAssertEqual(
            ForbiddenPhase1Feature.allCases.map(\.rawValue),
            [
                "standard_numerology_calculation",
                "life_path_calculation",
                "birth_order_numerology",
                "celestial_name_generation",
                "WRW_lore_generation",
                "PersonalCodex_generation",
                "Sigil_Flare_export",
                "Sigil_Flare_editor",
                "excess_personal_data_persistence",
                "final_export_bundle_generation"
            ]
        )
    }

    func testUnavailableResponseIsDeterministic() {
        let service = SigilPipelinePlaceholderService()

        XCTAssertEqual(service.unavailableResponse(), service.unavailableResponse())
        XCTAssertEqual(service.unavailableResponse().status, .pass)
    }
}
