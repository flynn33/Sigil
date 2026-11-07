import Foundation
import RFSigilCanon
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilUIModule
import RFSigilVisibleGlyph
import XCTest

// MARK: - Full journey integration test
//
// Exercises the real service integration (not mocks) through the full
// create → generate → read codex → save → reopen → Flare → export journey.
// Uses a synthetic fixture (never the owner's real personal record).

final class JourneyIntegrationTests: XCTestCase {
    // MARK: - Fixtures

    private func makeSyntheticDraft() -> SigilProfileDraft {
        SigilProfileDraft(
            storageID: "journey-test-\(UUID().uuidString.prefix(8))",
            firstName: "Avery",
            lastName: "Rowan",
            birthDate: "1992-08-21",
            birthTime: "14:30",
            birthCity: "Uppsala",
            birthOrder: "1 of 2",
            eyes: "green",
            hair: "brown",
            heritage: ["swedish", "german"],
            ancestralSurnames: ["Rowan", "Daley"],
            parentalOrder: ["maternal: 1 of 1", "paternal 2 of 3"]
        )
    }

    private func makeServices(in directory: URL) throws -> (
        glyph: SigilVisibleGlyphService,
        codex: SigilPersonalCodexService,
        persistence: SigilSecurePersistenceService,
        recordsStore: SigilRecordsStore
    ) {
        let glyph = SigilVisibleGlyphService()
        let canon = try SigilCanonLoader().load()
        let keyStore = SigilInMemoryKeyStore()
        let recordStore = SigilSecureRecordStore(
            directoryURL: directory,
            keyStore: keyStore,
            keyID: "journey-test-key"
        )
        let persistence = SigilSecurePersistenceService(store: recordStore)
        let codex = SigilPersonalCodexService(visibleGlyph: glyph, canon: canon)
        let store = SigilRecordsStore(persistence: persistence)
        return (glyph, codex, persistence, store)
    }

    // MARK: - Tests

    func testFullJourneyGenerateSaveReopenFlareExport() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-journey-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let services = try makeServices(in: dir)
        let draft = makeSyntheticDraft()

        // 1. Validate + promote the draft.
        let promoted = SigilDraftPromoter.promote(draft)
        guard case .success(let input) = promoted else {
            return XCTFail("Expected a valid promotion: \(promoted)")
        }
        XCTAssertEqual(input.id, draft.storageID)
        XCTAssertEqual(input.name, "Avery Rowan")

        // 2. Generate the artifact (real pipeline).
        let artifact = try services.glyph.generateArtifact(for: input)
        XCTAssertEqual(artifact.validationDecision.status, .pass)
        XCTAssertFalse(artifact.svgDocument.isEmpty)
        XCTAssertFalse(artifact.visibleSigil.visibleSignatureHash.isEmpty)

        // 3. Build the PersonalCodex (real pipeline).
        let codex = try services.codex.build(for: input)
        XCTAssertEqual(codex.profileStorageID, input.id)
        XCTAssertFalse(codex.digest.isEmpty)
        XCTAssertFalse(codex.celestialName.celestialName.isEmpty)

        // 4. Save all records to the real secure store.
        let store = services.recordsStore
        let profilePayload: [String: String] = [
            "firstName": draft.firstName,
            "lastName": draft.lastName,
            "birthDate": draft.birthDate,
            "birthCity": draft.birthCity
        ]
        let saveProfile = await store.upsert(
            profilePayload,
            storageID: draft.storageID,
            recordType: .profile
        )
        guard case .success = saveProfile else {
            return XCTFail("Expected profile save to succeed: \(saveProfile)")
        }
        let saveCodex = await store.upsert(codex, storageID: draft.storageID, recordType: .personalCodex)
        guard case .success = saveCodex else {
            return XCTFail("Expected codex save to succeed: \(saveCodex)")
        }
        let canonicalStyle = SigilFlareStyle(
            paletteID: "canonical", glowStrength: 0, backgroundID: "transparent"
        )
        let flare = services.glyph.makeFlarePresentation(for: artifact.visibleSigil, style: canonicalStyle)
        let saveFlare = await store.upsert(flare, storageID: draft.storageID, recordType: .flare)
        guard case .success = saveFlare else {
            return XCTFail("Expected flare save to succeed: \(saveFlare)")
        }

        // 5. Reopen the records (verify round-trip integrity).
        let reopenedCodex = await store.open(
            storageID: draft.storageID,
            recordType: .personalCodex,
            as: SigilPersonalCodex.self
        )
        guard case .success(let loadedCodex) = reopenedCodex else {
            return XCTFail("Expected codex reopen to succeed: \(reopenedCodex)")
        }
        XCTAssertEqual(loadedCodex.digest, codex.digest, "Codex digest must be stable across save/reopen")
        XCTAssertEqual(loadedCodex.celestialName.celestialName, codex.celestialName.celestialName)

        let reopenedFlare = await store.open(
            storageID: draft.storageID,
            recordType: .flare,
            as: SigilFlarePresentation.self
        )
        guard case .success(let loadedFlare) = reopenedFlare else {
            return XCTFail("Expected flare reopen to succeed: \(reopenedFlare)")
        }
        XCTAssertEqual(loadedFlare.canonicalGeometryDigest, flare.canonicalGeometryDigest)
        XCTAssertEqual(loadedFlare.visibleSignatureHash, flare.visibleSignatureHash)

        // 6. Apply a Flare style (presentation-only: canonical data unchanged).
        let auroraStyle = SigilFlareStyle(
            paletteID: "aurora", glowStrength: 0.6, backgroundID: "dark"
        )
        let styledFlare = services.glyph.makeFlarePresentation(
            for: artifact.visibleSigil, style: auroraStyle
        )
        // Canonical identity is preserved.
        XCTAssertEqual(styledFlare.canonicalGeometryDigest, flare.canonicalGeometryDigest)
        XCTAssertEqual(styledFlare.visibleSignatureHash, flare.visibleSignatureHash)
        XCTAssertEqual(styledFlare.profileDigest, flare.profileDigest)
        // Only the style changed.
        XCTAssertEqual(styledFlare.style.paletteID, "aurora")
        XCTAssertEqual(styledFlare.style.glowStrength, 0.6)
        XCTAssertEqual(styledFlare.style.backgroundID, "dark")

        // 7. Save the styled Flare.
        let saveStyled = await store.upsert(styledFlare, storageID: draft.storageID, recordType: .flare)
        guard case .success = saveStyled else {
            return XCTFail("Expected styled flare save to succeed: \(saveStyled)")
        }

        // 8. Export the canonical SVG.
        let svgData = Data(artifact.svgDocument.utf8)
        XCTAssertFalse(svgData.isEmpty)
        XCTAssertTrue(artifact.svgDocument.hasPrefix("<svg"))
        XCTAssertTrue(artifact.svgDocument.hasSuffix("</svg>"))

        // 9. Export the PersonalCodex as JSON.
        let codexJSON = try JSONEncoder().encode(codex)
        let decodedCodex = try JSONDecoder().decode(SigilPersonalCodex.self, from: codexJSON)
        XCTAssertEqual(decodedCodex.digest, codex.digest)

        // 10. Delete all records (destructive, explicit).
        _ = await store.delete(storageID: draft.storageID, recordType: .profile)
        _ = await store.delete(storageID: draft.storageID, recordType: .personalCodex)
        _ = await store.delete(storageID: draft.storageID, recordType: .flare)
        let listAfterDelete = await store.list()
        guard case .success(let remaining) = listAfterDelete else {
            return XCTFail("Expected list to succeed: \(listAfterDelete)")
        }
        XCTAssertEqual(remaining.count, 0, "All records should be deleted")
    }

    func testFlareRoundTripLeavesCanonicalDataUnchanged() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-flare-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let services = try makeServices(in: dir)
        let draft = makeSyntheticDraft()
        let promoted = try XCTUnwrap(SigilDraftPromoter.promote(draft).successValue)
        let artifact = try services.glyph.generateArtifact(for: promoted)

        // Canonical presentation.
        let canonicalStyle = SigilFlareStyle(paletteID: "canonical", glowStrength: 0, backgroundID: "transparent")
        let canonical = services.glyph.makeFlarePresentation(for: artifact.visibleSigil, style: canonicalStyle)

        // Styled presentation (multiple styles).
        let styles: [SigilFlareStyle] = [
            .init(paletteID: "aurora", glowStrength: 0.3, backgroundID: "light"),
            .init(paletteID: "ember", glowStrength: 0.7, backgroundID: "dark"),
            .init(paletteID: "midnight", glowStrength: 1.0, backgroundID: "transparent")
        ]
        for style in styles {
            let styled = services.glyph.makeFlarePresentation(for: artifact.visibleSigil, style: style)
            // Canonical identity is NEVER modified by Flare.
            XCTAssertEqual(styled.canonicalGeometryDigest, canonical.canonicalGeometryDigest,
                           "Flare must not change the canonical geometry digest")
            XCTAssertEqual(styled.visibleSignatureHash, canonical.visibleSignatureHash,
                           "Flare must not change the visible signature hash")
            XCTAssertEqual(styled.profileDigest, canonical.profileDigest,
                           "Flare must not change the profile digest")
            XCTAssertEqual(styled.vectorPaths, canonical.vectorPaths,
                           "Flare must not change the vector paths")
        }
    }

    func testJourneyStateOutOfOrderCompletionIsDropped() async throws {
        // Simulate out-of-order completions: seq 1 succeeds after seq 2 starts.
        let draft = makeSyntheticDraft()
        let services = try makeServices(in: FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-ooo-\(UUID().uuidString)"))

        let input = try XCTUnwrap(SigilDraftPromoter.promote(draft).successValue)
        let artifact = try services.glyph.generateArtifact(for: input)
        let codex = try services.codex.build(for: input)

        var state: SigilGenerationJourneyState = .idle
        // Start seq 1.
        state = SigilGenerationJourney.advance(current: state, with: .start(1))
        XCTAssertEqual(state, .loading(requestSequence: 1))
        // Start seq 2 (supersedes seq 1).
        state = SigilGenerationJourney.advance(current: state, with: .start(2))
        XCTAssertEqual(state, .loading(requestSequence: 2))
        // Seq 1 completes (out of order: should be dropped).
        state = SigilGenerationJourney.advance(current: state, with: .succeeded(1, artifact, codex))
        XCTAssertEqual(state, .loading(requestSequence: 2), "Out-of-order seq 1 must be dropped")
        // Seq 2 completes (in order: should be accepted).
        state = SigilGenerationJourney.advance(current: state, with: .succeeded(2, artifact, codex))
        guard case .success(let seq, _, _) = state else {
            return XCTFail("Expected success, got \(state)")
        }
        XCTAssertEqual(seq, 2)
    }

    func testEmptyDraftFailsValidation() {
        let draft = SigilProfileDraft()
        let result = SigilDraftPromoter.promote(draft)
        guard case .failure(let bag) = result else {
            return XCTFail("Expected validation failure")
        }
        XCTAssertFalse(bag.errors.isEmpty)
    }

    func testConcurrentEditsAreSerialized() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-concurrent-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let services = try makeServices(in: dir)
        let store = services.recordsStore

        // Write 10 records concurrently.
        struct ConcPayload: Codable {
            let index: Int
            let name: String
        }
        let allSucceeded: Bool = await withTaskGroup(of: Bool.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let payload = ConcPayload(index: i, name: "record-\(i)")
                    let result = await store.upsert(
                        payload,
                        storageID: "conc-\(i)",
                        recordType: .profile
                    )
                    if case .success = result { return true }
                    return false
                }
            }
            var allSucceeded = true
            for await succeeded in group {
                allSucceeded = allSucceeded && succeeded
            }
            return allSucceeded
        }

        // All 10 records should be present.
        let list = await store.list()
        guard case .success(let ids) = list else {
            return XCTFail("Expected list to succeed: \(list)")
        }
        XCTAssertEqual(ids.count, 10, "All 10 concurrent writes should succeed")
    }
}

// MARK: - Helpers

extension Result {
    var successValue: Success? {
        if case .success(let value) = self { return value }
        return nil
    }
}
