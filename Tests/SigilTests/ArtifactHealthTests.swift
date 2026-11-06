import Foundation
import RFSigilAeostaraIntegration
import RFSigilCoreModels
import RFSigilVisibleGlyph
import XCTest

final class ArtifactHealthTests: XCTestCase {
    private let profile = SigilProfileInput(
        id: "health_a",
        name: "Eira Voss",
        birthDate: "1991-02-11",
        birthTime: "03:42",
        birthCity: "Uppsala",
        birthOrder: "2 of 3",
        eyes: "gray",
        hair: "dark_blonde",
        heritage: ["Swedish", "German"]
    )

    private func healthy() throws -> SigilVisibleGlyphArtifact {
        try SigilVisibleGlyphService().generateArtifact(for: profile)
    }

    // MARK: - Healthy

    func testHealthyGoldenArtifactPassesAndAgreesWithServiceValidation() throws {
        let service = SigilVisibleGlyphService()
        let gateway = SigilAeostaraIntegrationGateway()
        let artifact = try healthy()

        let result = gateway.validate(artifact: artifact)

        XCTAssertTrue(result.isHealthy)
        XCTAssertNil(result.failureKind)
        XCTAssertEqual(result.decision.status, .pass)
        XCTAssertEqual(result.containment, .none)
        XCTAssertFalse(result.decision.mutationAllowed)
        // Consistency with the existing owning-boundary validation.
        XCTAssertEqual(service.validateArtifact(artifact).status, .pass)
    }

    // MARK: - Cross-artifact digest tamper (recoverable-derivable)

    func testTamperedCrossDigestBlocksAndRecoversAuthoritativeValues() throws {
        let artifact = try healthy()
        let tampered = withVisible(
            artifact,
            canonicalGeometryDigest: String(repeating: "f", count: 64)
        )

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .nonRecoverableArtifactFailure)
        XCTAssertEqual(result.containment, .backupPreserved)
        XCTAssertFalse(result.decision.mutationAllowed)
        XCTAssertTrue(result.decision.requiresOperatorReview)

        let cross = result.findings.first { $0.checkID == "artifact.cross-digest" }
        XCTAssertEqual(cross?.failureKind, .nonRecoverableArtifactFailure)
        XCTAssertEqual(cross?.recoverable, true)

        // The recovery restates the authoritative value (not a fabricated one) and verifies it.
        XCTAssertTrue(result.recovery.executed)
        XCTAssertEqual(result.recovery.recoveredMetadata["expected.canonicalGeometryDigest"], artifact.hiddenGeometry.canonicalGeometryDigest)
        XCTAssertFalse(result.recovery.rolledBack)
    }

    // MARK: - Unknown schema

    func testUnknownSchemaBlocksSafeHaltAndIsNonRecoverable() throws {
        let artifact = try healthy()
        let tampered = withHidden(artifact, schemaVersion: "rf.hidden_geometry.v999")

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .unknownSchema)
        XCTAssertEqual(result.containment, .safeHalt)
        let schema = result.findings.first { $0.checkID == "artifact.schema" }
        XCTAssertEqual(schema?.failureKind, .unknownSchema)
        XCTAssertEqual(schema?.recoverable, false)
        XCTAssertFalse(result.recovery.executed)
    }

    // MARK: - Missing authoritative identity

    func testMissingAuthoritativeIdentityBlocksSafeHalt() throws {
        let artifact = try healthy()
        let unavailable = artifact.hiddenGeometry.ashState
        let tampered = withHidden(
            artifact,
            ashState: SigilAshStateRecord(
                statePacked: unavailable.statePacked,
                stateBits: unavailable.stateBits,
                isCodeword: unavailable.isCodeword,
                orbitSize: unavailable.orbitSize,
                classification: unavailable.classification,
                stability: unavailable.stability,
                dominantPlaneId: unavailable.dominantPlaneId,
                wolfBalance: unavailable.wolfBalance,
                algorithmIdentity: unavailable.algorithmIdentity,
                stateDigest: unavailable.stateDigest,
                available: false,
                unavailableIdentityCore: ["hair"]
            )
        )

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .missingRequiredData)
        XCTAssertEqual(result.containment, .safeHalt)
        XCTAssertTrue(result.findings.contains { $0.failureKind == .missingRequiredData && $0.recoverable == false })
    }

    // MARK: - Internally tampered authoritative digest

    func testInternallyTamperedAuthoritativeDigestBlocksSafeHalt() throws {
        let artifact = try healthy()
        let alteredNumerology = NumerologyVector(
            lifePathRoot: artifact.hiddenGeometry.numerologyVector.lifePathRoot + 1,
            preservedMasterNumbers: artifact.hiddenGeometry.numerologyVector.preservedMasterNumbers,
            birthDayRoot: artifact.hiddenGeometry.numerologyVector.birthDayRoot,
            expressionDestinyRoot: artifact.hiddenGeometry.numerologyVector.expressionDestinyRoot,
            soulUrgeRoot: artifact.hiddenGeometry.numerologyVector.soulUrgeRoot,
            personalityRoot: artifact.hiddenGeometry.numerologyVector.personalityRoot,
            birthOrderOrdinal: artifact.hiddenGeometry.numerologyVector.birthOrderOrdinal,
            birthOrderTotal: artifact.hiddenGeometry.numerologyVector.birthOrderTotal,
            weekday: artifact.hiddenGeometry.numerologyVector.weekday,
            reductionProvenance: artifact.hiddenGeometry.numerologyVector.reductionProvenance
        )
        // Keep the recorded digest: the recomputation now disagrees -> internal tamper.
        let tampered = withHidden(artifact, numerologyVector: alteredNumerology)

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .nonRecoverableArtifactFailure)
        XCTAssertEqual(result.containment, .safeHalt)
        let internalFinding = result.findings.first { $0.checkID == "artifact.internal-digest" }
        XCTAssertEqual(internalFinding?.failureKind, .nonRecoverableArtifactFailure)
        XCTAssertEqual(internalFinding?.recoverable, false)
        XCTAssertFalse(result.recovery.executed)
    }

    // MARK: - Invalid topology

    func testInvalidTopologyDanglingEdgeBlocksSafeHalt() throws {
        let artifact = try healthy()
        let dangling = artifact.hiddenGeometry.edges.map { edge -> SigilGeometryEdge in
            SigilGeometryEdge(from: edge.from, to: "hidden.missing", role: edge.role)
        }
        let tampered = withHidden(artifact, edges: dangling)

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.containment, .safeHalt)
        let topology = result.findings.first { $0.checkID == "artifact.topology" }
        XCTAssertEqual(topology?.failureKind, .invalidTopology)
        XCTAssertEqual(topology?.recoverable, false)
    }

    // MARK: - Corrupt JSON

    func testCorruptJSONBlocksSafeHaltAndIsNonRecoverable() {
        let result = SigilAeostaraIntegrationGateway().validate(data: Data("not-json".utf8))

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .corruptJSON)
        XCTAssertEqual(result.containment, .safeHalt)
        XCTAssertEqual(result.findings.first?.failureKind, .corruptJSON)
        XCTAssertEqual(result.findings.first?.recoverable, false)
        XCTAssertFalse(result.recovery.executed)
    }

    // MARK: - Quality / numeric bounds

    func testQualityBoundsFailureBlocksAndRestatesContract() throws {
        let artifact = try healthy()
        let report = artifact.visibleSigil.qualityReport
        let failed = VisibleSigilQualityReport(
            passed: false,
            candidateIndex: report.candidateIndex,
            structuralScore: report.structuralScore,
            spacingScore: report.spacingScore,
            silhouetteScore: report.silhouetteScore,
            intersectionCount: report.intersectionCount,
            majorCrossingCount: report.majorCrossingCount,
            visibleSegmentCount: report.visibleSegmentCount,
            failures: [.emptyPathSet],
            gateEvidence: report.gateEvidence
        )
        let tampered = withVisible(artifact, qualityReport: failed)

        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        XCTAssertEqual(result.decision.status, .blocked)
        XCTAssertEqual(result.failureKind, .nonRecoverableArtifactFailure)
        XCTAssertEqual(result.containment, .backupPreserved)
        let quality = result.findings.first { $0.checkID == "artifact.quality-bounds" }
        XCTAssertEqual(quality?.recoverable, true)
        XCTAssertEqual(result.recovery.recoveredMetadata["quality.majorCrossingMaximum"], "3")
    }

    // MARK: - Determinism and non-destructiveness

    func testValidationIsDeterministicAndNonDestructive() throws {
        let artifact = try healthy()
        let gateway = SigilAeostaraIntegrationGateway()
        let first = gateway.validate(artifact: artifact)
        let second = gateway.validate(artifact: artifact)

        XCTAssertEqual(first, second)
        // Validation is a pure read: the artifact is unchanged.
        XCTAssertEqual(first.decision.status, .pass)
        XCTAssertTrue(gateway.validate(artifact: artifact).isHealthy)
    }

    // MARK: - Recovery metadata hygiene

    func testRecoveryMetadataCarriesNoRawPersonalValues() throws {
        let artifact = try healthy()
        let tampered = withVisible(artifact, canonicalGeometryDigest: String(repeating: "0", count: 64))
        let result = SigilAeostaraIntegrationGateway().validate(artifact: tampered)

        let safeKeys: Set<String> = [
            "expected.profileDigest",
            "expected.canonicalGeometryDigest",
            "expected.visibleSignatureHash",
            "expected.svg.signatureHash",
            "expected.svg.rederived.matchesSignature",
            "quality.segmentBudget",
            "quality.majorCrossingMaximum"
        ]
        XCTAssertTrue(Set(result.recovery.recoveredMetadata.keys).isSubset(of: safeKeys))
        // No raw profile text leaks into recovered metadata or the decision reason.
        for value in result.recovery.recoveredMetadata.values {
            XCTAssertFalse(value.contains("Voss"))
            XCTAssertFalse(value.contains("1991-02-11"))
        }
        XCTAssertFalse(result.decision.reason.contains("Voss"))
    }

    // MARK: - Rebuild helpers (tamper a single field; everything else copied)

    private func withHidden(
        _ artifact: SigilVisibleGlyphArtifact,
        schemaVersion: String? = nil,
        algorithmIdentity: String? = nil,
        profileHash: String? = nil,
        numerologyVector: NumerologyVector? = nil,
        ashState: SigilAshStateRecord? = nil,
        edges: [SigilGeometryEdge]? = nil,
        canonicalGeometryDigest: String? = nil
    ) -> SigilVisibleGlyphArtifact {
        let h = artifact.hiddenGeometry
        let rebuilt = HiddenCanonicalGeometry(
            schemaVersion: schemaVersion ?? h.schemaVersion,
            algorithmIdentity: algorithmIdentity ?? h.algorithmIdentity,
            profileHash: profileHash ?? h.profileHash,
            numerologyVector: numerologyVector ?? h.numerologyVector,
            ashState: ashState ?? h.ashState,
            planeAttunementVector: h.planeAttunementVector,
            wolfBalance: h.wolfBalance,
            ancestryWeights: h.ancestryWeights,
            celestialClassBasis: h.celestialClassBasis,
            anchorPoints: h.anchorPoints,
            edges: edges ?? h.edges,
            semanticRoles: h.semanticRoles,
            canonicalGeometryDigest: canonicalGeometryDigest ?? h.canonicalGeometryDigest
        )
        return SigilVisibleGlyphArtifact(
            hiddenGeometry: rebuilt,
            familyKey: artifact.familyKey,
            visibleSigil: artifact.visibleSigil,
            svgDocument: artifact.svgDocument,
            validationDecision: artifact.validationDecision
        )
    }

    private func withVisible(
        _ artifact: SigilVisibleGlyphArtifact,
        schemaVersion: String? = nil,
        profileDigest: String? = nil,
        canonicalGeometryDigest: String? = nil,
        visibleSignatureHash: String? = nil,
        qualityReport: VisibleSigilQualityReport? = nil
    ) -> SigilVisibleGlyphArtifact {
        let v = artifact.visibleSigil
        let rebuilt = VisibleCanonicalSigil(
            schemaVersion: schemaVersion ?? v.schemaVersion,
            profileDigest: profileDigest ?? v.profileDigest,
            canonicalGeometryDigest: canonicalGeometryDigest ?? v.canonicalGeometryDigest,
            visibleSignatureHash: visibleSignatureHash ?? v.visibleSignatureHash,
            vectorPaths: v.vectorPaths,
            styleMetadata: v.styleMetadata,
            semanticMotifMap: v.semanticMotifMap,
            qualityReport: qualityReport ?? v.qualityReport
        )
        return SigilVisibleGlyphArtifact(
            hiddenGeometry: artifact.hiddenGeometry,
            familyKey: artifact.familyKey,
            visibleSigil: rebuilt,
            svgDocument: artifact.svgDocument,
            validationDecision: artifact.validationDecision
        )
    }
}
