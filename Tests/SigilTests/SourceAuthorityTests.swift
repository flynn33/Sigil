import RFSigilCoreModels
import RFSigilSourceAuthority
import XCTest

final class SourceAuthorityTests: XCTestCase {
    func testAuthorityHierarchyIsPreserved() {
        let status = SigilSourceAuthorityService().status()

        XCTAssertEqual(status.ashModel.status, .pass)
        XCTAssertEqual(status.ywe.status, .pass)
        XCTAssertEqual(status.apsComponentRole.status, .passWithAllowedBlocker)
        XCTAssertEqual(status.wrwNarrativeLayer.status, .pass)
        XCTAssertEqual(status.sigilProductLayer.status, .pass)
        XCTAssertTrue(status.forbiddenInterpretationsPassed)
        XCTAssertEqual(status.wrwCanon.loreGenerationImplemented, false)
        XCTAssertEqual(status.wrwCanon.shouldBeFalseInPhase1, false)
    }

    func testEvidenceUsesReadSourceRecords() {
        let status = SigilSourceAuthorityService().status()
        let evidenceIDs = Set(status.evidence.map(\.id))

        XCTAssertTrue(evidenceIDs.contains("ywe-readme"))
        XCTAssertTrue(evidenceIDs.contains("ywe-authority-contracts"))
        XCTAssertTrue(evidenceIDs.contains("wrw-product-layer"))
    }
}
