import RFSigilAPSIntegration
import RFSigilAeostaraIntegration
import RFSigilCoreModels
import XCTest

final class IntegrationGatewayTests: XCTestCase {
    func testAPSStatusContainsRequiredConformanceSurface() {
        let status = SigilAPSIntegrationGateway().status()

        XCTAssertEqual(status.productsFound, ["ASHCore", "ASHPatternSystem"])
        XCTAssertEqual(status.conformanceJudgment, .conformantWithCaveats)
        XCTAssertNil(status.blocker)

        let evidenceIDs = Set(status.evidence.map(\.id))
        for requiredID in APSRequiredEvidenceID.allCases.map(\.rawValue) {
            XCTAssertTrue(evidenceIDs.contains(requiredID), "Missing \(requiredID)")
        }
    }

    func testAeostaraStatusContainsPlatformIOSAuthorityEvidence() {
        let status = SigilAeostaraIntegrationGateway().status()

        XCTAssertTrue(status.platformIOSAccessible)
        XCTAssertEqual(status.productsFound, ["AeostaraDomain", "AeostaraServices"])
        XCTAssertEqual(status.baselinePin.release, "v1.0.0")
        XCTAssertEqual(status.baselinePin.commit, "774b981ef2267a41c1b1a59497b2b0746a86f32b")
        XCTAssertTrue(status.migrationProvenance.sourceAndDestinationHistoryConfirmed)
        XCTAssertNil(status.blocker)
    }

    func testAeostaraHealthDecisionFailsClosedForInvalidArtifacts() {
        let decision = SigilAeostaraIntegrationGateway().healthDecision(for: .invalidTopology)

        XCTAssertEqual(decision.status, .blocked)
        XCTAssertFalse(decision.mutationAllowed)
        XCTAssertTrue(decision.requiresOperatorReview)
    }
}
