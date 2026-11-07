import Foundation
import RFSigilCanon
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilUIModule
import RFSigilVisibleGlyph
import XCTest

// MARK: - Draft validation

final class ProfileDraftTests: XCTestCase {
    func testValidDraftPromotesToCanonicalInput() throws {
        let draft = SigilProfileDraft(
            storageID: "test-storage-1",
            firstName: "Avery",
            lastName: "Rowan",
            birthDate: "1990-04-15",
            birthTime: "06:30",
            birthCity: "Lund",
            birthOrder: "2 of 3",
            eyes: "blue",
            hair: "blond",
            heritage: ["swedish", "irish"],
            ancestralSurnames: ["Rowan"],
            parentalOrder: ["maternal: 1 of 2", "paternal 2 of 4"]
        )
        let result = SigilDraftPromoter.promote(draft)
        guard case .success(let input) = result else {
            return XCTFail("Expected a valid promotion, got \(result)")
        }
        XCTAssertEqual(input.id, "test-storage-1")
        XCTAssertEqual(input.name, "Avery Rowan")
        XCTAssertEqual(input.birthDate, "1990-04-15")
        XCTAssertEqual(input.birthCity, "Lund")
        XCTAssertEqual(input.birthOrder, "2 of 3")
        XCTAssertEqual(input.eyes, "blue")
        XCTAssertEqual(input.hair, "blond")
        XCTAssertEqual(input.heritage, ["swedish", "irish"])
        XCTAssertEqual(input.ancestralSurnames, ["Rowan"])
        XCTAssertEqual(input.parentalOrder.count, 2)
        XCTAssertEqual(input.parentalOrder.first?.side, "maternal")
        XCTAssertEqual(input.parentalOrder.last?.side, "paternal")
        // Weekday: 1990-04-15 is a Sunday.
        XCTAssertEqual(input.birthWeekday, "Sunday")
    }

    func testMissingRequiredFieldsProduceAllErrors() {
        let draft = SigilProfileDraft(
            firstName: "",
            lastName: "",
            birthDate: "",
            birthCity: ""
        )
        let result = SigilDraftPromoter.promote(draft)
        guard case .failure(let bag) = result else {
            return XCTFail("Expected validation failures")
        }
        let fields = Set(bag.errors.map { $0.field })
        XCTAssertEqual(fields, ["name", "birthDate", "birthCity"])
    }

    func testInvalidBirthDateProducesError() {
        let draft = SigilProfileDraft(
            firstName: "Avery",
            lastName: "Rowan",
            birthDate: "1990-13-45",
            birthCity: "Lund"
        )
        let result = SigilDraftPromoter.promote(draft)
        guard case .failure(let bag) = result else {
            return XCTFail("Expected a birthDate validation error")
        }
        XCTAssertTrue(bag.errors.contains { $0.field == "birthDate" })
    }

    func testInvalidBirthOrderProducesError() {
        let draft = SigilProfileDraft(
            firstName: "Avery",
            lastName: "Rowan",
            birthDate: "1990-04-15",
            birthCity: "Lund",
            birthOrder: "5 of 2"
        )
        let result = SigilDraftPromoter.promote(draft)
        guard case .failure(let bag) = result else {
            return XCTFail("Expected a birthOrder validation error")
        }
        XCTAssertTrue(bag.errors.contains { $0.field == "birthOrder" })
    }

    func testOptionalFieldsMayBeUnknown() {
        let draft = SigilProfileDraft(
            firstName: "Avery",
            lastName: "Rowan",
            birthDate: "1990-04-15",
            birthCity: "Lund"
        )
        let result = SigilDraftPromoter.promote(draft)
        guard case .success(let input) = result else {
            return XCTFail("Expected a valid promotion with optional fields unknown")
        }
        XCTAssertEqual(input.birthTime, "")
        XCTAssertEqual(input.birthOrder, "")
        XCTAssertEqual(input.eyes, "")
        XCTAssertEqual(input.hair, "")
        XCTAssertEqual(input.heritage, [])
        XCTAssertEqual(input.parentalOrder, [])
    }

    func testFullNameIsJoinedWithSingleSpace() {
        let draft = SigilProfileDraft(
            firstName: "  Avery  ",
            lastName: "  Rowan  "
        )
        XCTAssertEqual(draft.fullName, "Avery Rowan")
    }
}

// MARK: - Journey state machine (pure, deterministic)

final class GenerationJourneyStateTests: XCTestCase {
    private func makeArtifact() -> SigilVisibleGlyphArtifact {
        // Build a minimal artifact via a known-valid profile (deterministic).
        let profile = SigilProfileInput(
            id: "state-test",
            name: "Avery Rowan",
            birthDate: "1990-04-15",
            birthTime: "06:30",
            birthCity: "Lund",
            birthOrder: "2 of 3",
            eyes: "blue",
            hair: "blond",
            heritage: ["swedish", "irish"]
        )
        let service = SigilVisibleGlyphService()
        do {
            return try service.generateArtifact(for: profile)
        } catch {
            XCTFail("Could not build artifact: \(error)")
            return try! service.generateArtifact(for: profile)
        }
    }

    private func makeCodex() -> SigilPersonalCodex {
        let profile = SigilProfileInput(
            id: "state-test",
            name: "Avery Rowan",
            birthDate: "1990-04-15",
            birthTime: "06:30",
            birthCity: "Lund",
            birthOrder: "2 of 3",
            eyes: "blue",
            hair: "blond",
            heritage: ["swedish", "irish"]
        )
        do {
            let canon = try SigilCanonLoader().load()
            let service = SigilPersonalCodexService(
                visibleGlyph: SigilVisibleGlyphService(),
                canon: canon
            )
            return try service.build(for: profile)
        } catch {
            XCTFail("Could not build codex: \(error)")
            fatalError()
        }
    }

    func testIdleToStartEntersLoading() {
        let start = SigilGenerationJourney.advance(
            current: .idle,
            with: .start(1)
        )
        XCTAssertEqual(start, .loading(requestSequence: 1))
    }

    func testLoadingSucceededTransitionsToSuccess() {
        let artifact = makeArtifact()
        let codex = makeCodex()
        let start: SigilGenerationJourneyState = .loading(requestSequence: 1)
        let after = SigilGenerationJourney.advance(
            current: start,
            with: .succeeded(1, artifact, codex)
        )
        guard case .success(let seq, let a, let c) = after else {
            return XCTFail("Expected success, got \(after)")
        }
        XCTAssertEqual(seq, 1)
        XCTAssertEqual(a, artifact)
        XCTAssertEqual(c, codex)
    }

    func testLoadingFailedTransitionsToFailure() {
        let after = SigilGenerationJourney.advance(
            current: .loading(requestSequence: 1),
            with: .failed(1, "Something went wrong.")
        )
        XCTAssertEqual(after, .failure(requestSequence: 1, reason: "Something went wrong."))
    }

    func testLoadingCancelledTransitionsToCancelled() {
        let after = SigilGenerationJourney.advance(
            current: .loading(requestSequence: 1),
            with: .cancelled(1)
        )
        XCTAssertEqual(after, .cancelled(requestSequence: 1))
    }

    func testOutOfOrderSuccessIsDropped() {
        let artifact = makeArtifact()
        let codex = makeCodex()
        // We are loading seq=2; an event for seq=1 must be dropped.
        let after = SigilGenerationJourney.advance(
            current: .loading(requestSequence: 2),
            with: .succeeded(1, artifact, codex)
        )
        XCTAssertEqual(after, .loading(requestSequence: 2))
    }

    func testNewStartSupersedesOldLoading() {
        let after = SigilGenerationJourney.advance(
            current: .loading(requestSequence: 1),
            with: .start(2)
        )
        XCTAssertEqual(after, .loading(requestSequence: 2))
    }

    func testDuplicateStartIsIgnored() {
        let after = SigilGenerationJourney.advance(
            current: .loading(requestSequence: 2),
            with: .start(2)
        )
        // seq == s is not seq > s, so the default arm (drop) applies.
        XCTAssertEqual(after, .loading(requestSequence: 2))
    }

    func testSuccessCannotTransitionFurther() {
        let artifact = makeArtifact()
        let codex = makeCodex()
        let after = SigilGenerationJourney.advance(
            current: .success(requestSequence: 1, artifact: artifact, codex: codex),
            with: .start(2)
        )
        // From .success, no event advances the state.
        guard case .success(let seq, _, _) = after else {
            return XCTFail("Expected to remain in success, got \(after)")
        }
        XCTAssertEqual(seq, 1)
    }
}

// MARK: - Records store (CRUD over real secure persistence)

final class RecordsStoreTests: XCTestCase {
    private func makeStore(in directory: URL) async throws -> SigilRecordsStore {
        let keyStore = SigilInMemoryKeyStore()
        let recordStore = SigilSecureRecordStore(
            directoryURL: directory,
            keyStore: keyStore,
            keyID: "test-key"
        )
        let persistence = SigilSecurePersistenceService(store: recordStore)
        return SigilRecordsStore(persistence: persistence)
    }

    struct TestPayload: Codable, Equatable {
        let name: String
        let value: Int
    }

    func testUpsertAndOpenRoundTrip() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        let upsert = await store.upsert(TestPayload(name: "alpha", value: 1), storageID: "s1", recordType: .profile)
        guard case .success(let id) = upsert else {
            return XCTFail("Expected upsert to succeed: \(upsert)")
        }
        XCTAssertEqual(id, "s1")

        let open = await store.open(storageID: "s1", recordType: .profile, as: TestPayload.self)
        guard case .success(let payload) = open else {
            return XCTFail("Expected open to succeed: \(open)")
        }
        XCTAssertEqual(payload, TestPayload(name: "alpha", value: 1))
    }

    func testOpenNotFailingReturnsNotFound() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        let open = await store.open(storageID: "missing", recordType: .profile, as: TestPayload.self)
        guard case .failure(let failure) = open else {
            return XCTFail("Expected open to fail")
        }
        XCTAssertEqual(failure.category, .notFound)
    }

    func testDeleteRemovesRecord() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        _ = await store.upsert(TestPayload(name: "alpha", value: 1), storageID: "s1", recordType: .profile)
        let del = await store.delete(storageID: "s1", recordType: .profile)
        guard case .success = del else {
            return XCTFail("Expected delete to succeed: \(del)")
        }
        let open = await store.open(storageID: "s1", recordType: .profile, as: TestPayload.self)
        guard case .failure(let failure) = open else {
            return XCTFail("Expected open to fail after delete")
        }
        XCTAssertEqual(failure.category, .notFound)
    }

    func testDeleteNotFoundFails() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        let del = await store.delete(storageID: "missing", recordType: .profile)
        guard case .failure(let failure) = del else {
            return XCTFail("Expected delete to fail")
        }
        XCTAssertEqual(failure.category, .notFound)
    }

    func testListReturnsPersistedRecords() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        _ = await store.upsert(TestPayload(name: "a", value: 1), storageID: "s1", recordType: .profile)
        _ = await store.upsert(TestPayload(name: "b", value: 2), storageID: "s2", recordType: .profile)
        _ = await store.upsert(TestPayload(name: "c", value: 3), storageID: "s1", recordType: .flare)

        let list = await store.list()
        guard case .success(let ids) = list else {
            return XCTFail("Expected list to succeed")
        }
        XCTAssertEqual(ids.count, 3)
        let keys = Set(ids.map { "\($0.storageID):\($0.recordType.rawValue)" })
        XCTAssertEqual(keys, [
            "s1:profile",
            "s2:profile",
            "s1:flare"
        ])
    }

    func testListEmptyStoreReturnsEmptyArray() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-records-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try await makeStore(in: dir)
        let list = await store.list()
        guard case .success(let ids) = list else {
            return XCTFail("Expected list to succeed")
        }
        XCTAssertEqual(ids, [])
    }
}
