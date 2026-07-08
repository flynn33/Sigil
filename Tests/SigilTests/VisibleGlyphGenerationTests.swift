import RFSigilCoreModels
import RFSigilVisibleGlyph
import XCTest

final class VisibleGlyphGenerationTests: XCTestCase {
    private let profiles: [SigilProfileInput] = [
        SigilProfileInput(
            id: "golden_mortal_a",
            name: "Eira Voss",
            birthDate: "1991-02-11",
            birthTime: "03:42",
            birthCity: "Uppsala",
            birthOrder: "2 of 3",
            eyes: "gray",
            hair: "dark_blonde",
            heritage: ["Swedish", "German"]
        ),
        SigilProfileInput(
            id: "golden_mortal_b",
            name: "Maeve Kellan",
            birthDate: "1988-10-30",
            birthTime: "21:08",
            birthCity: "Cork",
            birthOrder: "1 of 2",
            eyes: "green",
            hair: "black",
            heritage: ["Irish", "English"]
        ),
        SigilProfileInput(
            id: "golden_mortal_c",
            name: "Nadia Kovalenko",
            birthDate: "2000-07-07",
            birthTime: "11:19",
            birthCity: "Krakow",
            birthOrder: "7 of 9",
            eyes: "hazel",
            hair: "brown",
            heritage: ["Polish", "Ukrainian"]
        ),
        SigilProfileInput(
            id: "golden_mortal_d",
            name: "Julian Hart",
            birthDate: "1977-11-04",
            birthTime: "17:55",
            birthCity: "York",
            birthOrder: "3 of 5",
            eyes: "blue",
            hair: "red",
            heritage: ["English", "German"]
        )
    ]

    func testCanonicalProfileGeneratesDeterministicHiddenAndVisibleArtifacts() throws {
        let service = SigilVisibleGlyphService()

        let first = try service.generateArtifact(for: profiles[0])
        let second = try service.generateArtifact(for: profiles[0])

        XCTAssertEqual(first.hiddenGeometry, second.hiddenGeometry)
        XCTAssertEqual(first.visibleSigil, second.visibleSigil)
        XCTAssertEqual(
            try service.canonicalVisibleJSON(for: first.visibleSigil),
            try service.canonicalVisibleJSON(for: second.visibleSigil)
        )
        XCTAssertEqual(
            service.renderSVG(for: first.visibleSigil),
            service.renderSVG(for: second.visibleSigil)
        )
        XCTAssertEqual(first.visibleSigil.profileDigest, first.hiddenGeometry.profileHash)
        XCTAssertEqual(first.visibleSigil.canonicalGeometryDigest, first.hiddenGeometry.canonicalGeometryDigest)
        XCTAssertFalse(first.visibleSigil.vectorPaths.map(\.id).contains("hidden.geometry.edge"))
    }

    func testGoldenProfilesProduceUniqueVisibleSignaturesAndPassingQualityReports() throws {
        let service = SigilVisibleGlyphService()
        let artifacts = try profiles.map { try service.generateArtifact(for: $0) }

        XCTAssertEqual(Set(artifacts.map(\.visibleSigil.visibleSignatureHash)).count, profiles.count)
        XCTAssertEqual(Set(artifacts.map { service.pathSignature(for: $0.visibleSigil) }).count, profiles.count)

        for artifact in artifacts {
            XCTAssertTrue(artifact.visibleSigil.qualityReport.passed)
            XCTAssertTrue((10...14).contains(artifact.visibleSigil.qualityReport.visibleSegmentCount))
            XCTAssertLessThanOrEqual(artifact.visibleSigil.qualityReport.majorCrossingCount, 3)
            XCTAssertEqual(artifact.visibleSigil.qualityReport.failures, [])
            XCTAssertEqual(artifact.visibleSigil.styleMetadata.renderer, "RFSigilRenderer.svg.v1")
            XCTAssertEqual(artifact.validationDecision.status, .pass)
        }
    }

    func testFlarePresentationDoesNotMutateCanonicalIdentityOrVectorData() throws {
        let service = SigilVisibleGlyphService()
        let artifact = try service.generateArtifact(for: profiles[1])

        let flare = service.makeFlarePresentation(
            for: artifact.visibleSigil,
            style: SigilFlareStyle(paletteID: "moonlit-green", glowStrength: 0.65, backgroundID: "dark-field")
        )

        XCTAssertEqual(flare.profileDigest, artifact.visibleSigil.profileDigest)
        XCTAssertEqual(flare.canonicalGeometryDigest, artifact.visibleSigil.canonicalGeometryDigest)
        XCTAssertEqual(flare.visibleSignatureHash, artifact.visibleSigil.visibleSignatureHash)
        XCTAssertEqual(flare.vectorPaths, artifact.visibleSigil.vectorPaths)
        XCTAssertNotEqual(flare.style.paletteID, artifact.visibleSigil.styleMetadata.paletteID)
    }

    func testQualityGateRejectsScribbleLikeOutput() {
        let invalidPaths = (0..<18).map { index in
            VisibleVectorPath(
                id: "invalid.\(index)",
                primitive: .sideOrnament,
                pathData: "M 0 0 L 100 100",
                strokeRole: "invalid",
                semanticSource: "test"
            )
        }

        let report = SigilVisibleQualityGate().evaluate(
            vectorPaths: invalidPaths,
            candidateIndex: 0,
            majorCrossingCount: 7
        )

        XCTAssertFalse(report.passed)
        XCTAssertTrue(report.failures.contains(.segmentBudgetExceeded))
        XCTAssertTrue(report.failures.contains(.majorCrossingLimitExceeded))
    }

    func testCollisionResolutionAdvancesCandidateDeterministically() throws {
        let service = SigilVisibleGlyphService()
        let baseline = try service.generateArtifact(for: profiles[2])
        let occupied = Set([baseline.visibleSigil.visibleSignatureHash])

        let firstResolved = try service.generateArtifact(
            for: profiles[2],
            existingVisibleSignatureHashes: occupied
        )
        let secondResolved = try service.generateArtifact(
            for: profiles[2],
            existingVisibleSignatureHashes: occupied
        )

        XCTAssertGreaterThan(firstResolved.visibleSigil.qualityReport.candidateIndex, 0)
        XCTAssertNotEqual(firstResolved.visibleSigil.visibleSignatureHash, baseline.visibleSigil.visibleSignatureHash)
        XCTAssertEqual(firstResolved.visibleSigil, secondResolved.visibleSigil)
    }

    func testArtifactValidationPassesAndFailsClosedForDigestMismatch() throws {
        let service = SigilVisibleGlyphService()
        let artifact = try service.generateArtifact(for: profiles[3])

        XCTAssertEqual(service.validateArtifact(artifact).status, .pass)

        let tamperedVisible = VisibleCanonicalSigil(
            schemaVersion: artifact.visibleSigil.schemaVersion,
            profileDigest: artifact.visibleSigil.profileDigest,
            canonicalGeometryDigest: String(repeating: "0", count: 64),
            visibleSignatureHash: artifact.visibleSigil.visibleSignatureHash,
            vectorPaths: artifact.visibleSigil.vectorPaths,
            styleMetadata: artifact.visibleSigil.styleMetadata,
            semanticMotifMap: artifact.visibleSigil.semanticMotifMap,
            qualityReport: artifact.visibleSigil.qualityReport
        )
        let tampered = SigilVisibleGlyphArtifact(
            hiddenGeometry: artifact.hiddenGeometry,
            familyKey: artifact.familyKey,
            visibleSigil: tamperedVisible,
            svgDocument: artifact.svgDocument,
            validationDecision: artifact.validationDecision
        )

        let decision = service.validateArtifact(tampered)
        XCTAssertEqual(decision.status, .blocked)
        XCTAssertFalse(decision.mutationAllowed)
        XCTAssertTrue(decision.requiresOperatorReview)
    }
}
