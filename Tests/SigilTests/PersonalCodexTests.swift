import Foundation
import RFSigilCanon
import RFSigilPersonalCodex
import RFSigilVisibleGlyph
import XCTest

// MARK: - PersonalCodex build + validation (deterministic, canon-backed)
//
// Builds the readable, canon-backed interpretation from the real identity
// pipeline (authoritative hidden geometry) and the deterministic celestial
// naming, then checks the structural invariants that keep it DERIVED (never
// looked up), deterministic, provenance-complete, and acyclic-digest-validated.
// There is no personal-data embedding; the record is deterministic and the
// Sigil Reading is complete (Package 05 realized the canonical branch geometry),
// linking one-way to the canonical geometry and the selected visible geometry.

final class PersonalCodexTests: XCTestCase {

    // MARK: - Helpers

    private static let goldenProfile = SigilProfileInput(
        id: "golden_mortal_a",
        name: "Eira Voss",
        birthDate: "1991-02-11",
        birthTime: "03:42",
        birthCity: "Uppsala",
        birthOrder: "2 of 3",
        eyes: "gray",
        hair: "dark_blonde",
        heritage: ["Swedish", "German"]
    )

    private func makeService() throws -> SigilPersonalCodexService {
        let canon = try SigilCanonLoader().load()
        return SigilPersonalCodexService(visibleGlyph: SigilVisibleGlyphService(), canon: canon)
    }

    private func buildOnce() throws -> (service: SigilPersonalCodexService, record: SigilPersonalCodex) {
        let service = try makeService()
        let record = try service.build(for: Self.goldenProfile)
        return (service, record)
    }

    // MARK: - Build + structural presence

    func testBuildSucceedsAndAllSectionsPresent() throws {
        let (_, record) = try buildOnce()

        XCTAssertEqual(record.schemaVersion, SigilPersonalCodex.schemaVersion)
        XCTAssertEqual(record.algorithmIdentity, SigilPersonalCodex.algorithmIdentity)
        XCTAssertEqual(record.profileStorageID, Self.goldenProfile.id,
                       "The record is keyed by the storage id, never the profile hash")

        XCTAssertEqual(record.provenance.sources.count, 5, "All five canon sources must be recorded")
        XCTAssertFalse(record.celestialName.celestialName.isEmpty, "A derived celestial name is present")
        XCTAssertEqual(record.ashIdentity.stateBits.count, 9, "The ASH identity carries the nine-bit state")
        XCTAssertEqual(record.planeAttunement.planes.count, 9, "Attunement spans all nine planes")
        XCTAssertFalse(record.ashIdentity.canonicalGeometryDigest.isEmpty)
        XCTAssertFalse(record.digest.isEmpty)
        XCTAssertEqual(record.digest.count, 64, "The record digest is a SHA-256 hex string")
    }

    // MARK: - Completed Sigil Reading (one-way provenance link)

    func testSigilReadingIsCompleteAndLinkedToSelectedGeometry() throws {
        let (_, record) = try buildOnce()
        XCTAssertTrue(record.sigilReading.complete, "The Sigil Reading is complete: Package 05 realized the canonical branch geometry")
        XCTAssertFalse(record.sigilReading.completionNote.isEmpty)
        XCTAssertFalse(record.sigilReading.canonicalGeometryDigest.isEmpty)
        // The one-way link is consistent with the ASH identity's geometry digest.
        XCTAssertEqual(record.sigilReading.canonicalGeometryDigest, record.ashIdentity.canonicalGeometryDigest)
        // The selected visible branch geometry's geometry-only identity is recorded
        // and matches the actually-rendered geometry. One-way: the glyph does not
        // hash back to the PersonalCodex.
        let glyph = SigilVisibleGlyphService()
        let artifact = try glyph.generateArtifact(for: Self.goldenProfile)
        XCTAssertFalse(record.sigilReading.selectedGeometrySignature.isEmpty)
        XCTAssertEqual(
            record.sigilReading.selectedGeometrySignature,
            artifact.visibleSigil.styleMetadata.geometryCollisionSignature,
            "the recorded selected-geometry identity must match the rendered branch geometry"
        )
    }

    // MARK: - Wolf divergence (source ±1.0 vs pipeline 0.12 band) is explicit

    func testWolfDivergenceDocumented() throws {
        let (_, record) = try buildOnce()
        let source = record.wolfBalance.sourceRule.category
        let pipeline = record.wolfBalance.pipelineRule.category
        XCTAssertEqual(record.wolfBalance.divergent, source != pipeline,
                       "`divergent` must reflect whether the two rules disagree for this profile")
        // Both rules are recorded with their rule identities.
        XCTAssertFalse(record.wolfBalance.sourceRule.rule.isEmpty)
        XCTAssertFalse(record.wolfBalance.pipelineRule.rule.isEmpty)
    }

    // MARK: - Determinism (same input → identical record, including digest)

    func testDeterministicBuild() throws {
        let service = try makeService()
        let a = try service.build(for: Self.goldenProfile)
        let b = try service.build(for: Self.goldenProfile)
        XCTAssertEqual(a.digest, b.digest, "The acyclic digest must be reproducible")
        XCTAssertEqual(a, b)
    }

    // MARK: - WRW guardrails (lineage pressure, never a destiny claim)

    func testBloodlineIsNotDestinyClaim() throws {
        let (_, record) = try buildOnce()
        XCTAssertFalse(record.bloodlineHeritageResonance.isDestinyClaim,
                       "Bloodline resonance is lineage pressure, never a destiny claim")
        XCTAssertFalse(record.bloodlineHeritageResonance.notADestinyClaimNote.isEmpty)
        XCTAssertFalse(record.bloodlineHeritageResonance.ancestryWeights.isEmpty)
    }

    func testTrialsAreBoundedSymbolicNotFabricated() throws {
        let (_, record) = try buildOnce()
        XCTAssertTrue(record.trialsBranchEchoes.boundedSymbolic)
        XCTAssertFalse(record.trialsBranchEchoes.isFabricatedLifeHistory,
                       "A static profile carries no fabricated or simulated life history")
        XCTAssertFalse(record.trialsBranchEchoes.qualifiers.isEmpty)
    }

    // MARK: - Provenance

    func testProvenanceDigestMatchesCanon() throws {
        let (_, record) = try buildOnce()
        let canon = try SigilCanonLoader().load()
        XCTAssertEqual(record.provenance.provenanceDigest, canon.provenanceDigest,
                       "The record's provenance digest is the canon registry's digest")
        XCTAssertEqual(record.provenance.sources.count, canon.sources.count)
        XCTAssertEqual(record.provenance.manifestVersion, canon.manifestVersion)
    }

    // MARK: - Validation (record boundary)

    func testValidateAcceptsWellFormed() throws {
        let (service, record) = try buildOnce()
        XCTAssertNoThrow(try service.validate(record))
    }

    func testValidateRejectsTamperedRecord() throws {
        let (service, original) = try buildOnce()
        // Reconstruct an otherwise-identical record with one field changed,
        // keeping the ORIGINAL digest: validation must detect the mismatch.
        let tamperedMortal = SigilPersonalCodex.MortalIncarnation(
            name: "Tampered Mortal Name",
            firstName: original.mortalIncarnation.firstName,
            lastName: original.mortalIncarnation.lastName,
            birthDate: original.mortalIncarnation.birthDate,
            birthTime: original.mortalIncarnation.birthTime,
            birthCity: original.mortalIncarnation.birthCity,
            birthOrder: original.mortalIncarnation.birthOrder,
            heritage: original.mortalIncarnation.heritage,
            ancestralSurnames: original.mortalIncarnation.ancestralSurnames,
            weekdayName: original.mortalIncarnation.weekdayName,
            prose: original.mortalIncarnation.prose
        )
        let tampered = SigilPersonalCodex(
            schemaVersion: original.schemaVersion,
            algorithmIdentity: original.algorithmIdentity,
            profileStorageID: original.profileStorageID,
            mortalIncarnation: tamperedMortal,
            numerologyProfile: original.numerologyProfile,
            ashIdentity: original.ashIdentity,
            planeAttunement: original.planeAttunement,
            celestialClassOrigin: original.celestialClassOrigin,
            celestialName: original.celestialName,
            wolfBalance: original.wolfBalance,
            bloodlineHeritageResonance: original.bloodlineHeritageResonance,
            trialsBranchEchoes: original.trialsBranchEchoes,
            giftsBurdensThresholds: original.giftsBurdensThresholds,
            sigilReading: original.sigilReading,
            provenance: original.provenance,
            digest: original.digest
        )
        XCTAssertThrowsError(try service.validate(tampered)) { error in
            guard case let SigilPersonalCodexError.digestMismatch(recorded, recomputed) = error else {
                return XCTFail("Expected .digestMismatch, got \(error)")
            }
            XCTAssertNotEqual(recorded, recomputed)
        }
    }
}
