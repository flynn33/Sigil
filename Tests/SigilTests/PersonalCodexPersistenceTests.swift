import Foundation
import RFSigilCanon
import RFSigilDiagnostics
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilVisibleGlyph
import XCTest

// MARK: - PersonalCodex persistence (local-only, AES-GCM, redacted)
//
// Exercises the encrypted local-only persistence path for the PersonalCodex
// record: build → canonical data → save → load → decode → validate → equality;
// a failed save is never reported as success; the storage identity is keyed by
// the profile's storage id (never its mathematical hash); and diagnostics never
// leak profile values (name / birth date) or record payload.

@MainActor
final class PersonalCodexPersistenceTests: XCTestCase {

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

    private func makeTempDirectory(name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makePersistence(directory: URL, diagnostics: (any SigilDiagnosticCollector)? = nil) -> SigilSecurePersistenceService {
        let store = SigilSecureRecordStore(directoryURL: directory, keyStore: SigilInMemoryKeyStore(), keyID: "sigil-default")
        return SigilSecurePersistenceService(store: store, diagnostics: diagnostics, keySource: .injected)
    }

    private func makeService(persistence: SigilSecurePersistenceService?, diagnostics: (any SigilDiagnosticCollector)? = nil) throws -> SigilPersonalCodexService {
        let canon = try SigilCanonLoader().load()
        return SigilPersonalCodexService(
            visibleGlyph: SigilVisibleGlyphService(),
            canon: canon,
            persistence: persistence,
            diagnostics: diagnostics
        )
    }

    // MARK: - Round-trip (build → save → load → decode → validate → equal)

    func testRoundTripBuildEncodeSaveLoadDecodeValidate() async throws {
        let directory = try makeTempDirectory(name: "sigil-personalcodex-rt")
        defer { try? FileManager.default.removeItem(at: directory) }

        let persistence = makePersistence(directory: directory)
        let service = try makeService(persistence: persistence)
        let profile = Self.goldenProfile

        let record = try service.build(for: profile)
        let outcome = await service.persist(record, for: profile)
        XCTAssertTrue(outcome.success)
        XCTAssertNil(outcome.failureCategory)

        let identity = service.storageIdentity(for: profile)
        let loaded = try await persistence.load(identity)
        let decoded = try JSONDecoder().decode(SigilPersonalCodex.self, from: loaded)
        try service.validate(decoded)
        XCTAssertEqual(decoded, record, "An encrypted round-trip must reproduce the identical record")
    }

    // MARK: - Failed save is never reported as success

    func testFailedSaveNeverSuccess() async throws {
        let directory = try makeTempDirectory(name: "sigil-personalcodex-ro")
        // Make the partition read-only so the atomic write fails with EACCES.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }

        let persistence = makePersistence(directory: directory)
        let service = try makeService(persistence: persistence)
        let profile = Self.goldenProfile

        let record = try service.build(for: profile)
        let outcome = await service.persist(record, for: profile)

        XCTAssertFalse(outcome.success, "A failed write must never be reported as a successful persist")
        XCTAssertEqual(outcome.failureCategory, .writeFailed)
    }

    // MARK: - Storage identity uses the profile storage id, never its hash

    func testStorageIdentityUsesProfileIdNotHash() throws {
        let service = try makeService(persistence: nil)
        let identity = service.storageIdentity(for: Self.goldenProfile)
        XCTAssertEqual(identity.recordType, .personalCodex)
        XCTAssertEqual(identity.storageID, Self.goldenProfile.id,
                       "The storage identity is the profile's storage id, not its mathematical hash")
    }

    // MARK: - Diagnostics never leak sensitive data (build + persist)

    func testPersistDiagnosticsNeverLeakSensitiveData() async throws {
        let directory = try makeTempDirectory(name: "sigil-personalcodex-redact")
        defer { try? FileManager.default.removeItem(at: directory) }

        let collector = CapturingDiagnosticCollector()
        let persistence = makePersistence(directory: directory, diagnostics: collector)
        let service = try makeService(persistence: persistence, diagnostics: collector)
        let profile = Self.goldenProfile

        let record = try service.build(for: profile)
        _ = await service.persist(record, for: profile)

        // Collect every string the collector captured (events + operation finishes).
        var captured: [String] = []
        for event in collector.events {
            captured.append(event.message)
            captured.append(event.type)
            captured.append(event.source)
            for value in event.context.values {
                captured.append(contentsOf: flattenedStrings(value))
            }
        }
        for operation in collector.operations {
            for value in operation.context.values {
                captured.append(contentsOf: flattenedStrings(value))
            }
        }
        let blob = captured.joined(separator: "\u{0}")

        // The profile's identity and record payload are never recorded.
        XCTAssertFalse(blob.contains("Eira Voss"), "A profile value must not appear in diagnostics")
        XCTAssertFalse(blob.contains("1991-02-11"), "A profile value must not appear in diagnostics")
        // The record's derived celestial name is part of the payload, not diagnostics.
        XCTAssertFalse(blob.contains(record.celestialName.celestialName))
    }
}

// MARK: - Capturing diagnostic collector (self-contained; drops nothing)

/// Flattens a diagnostic value tree into its string leaves for leak scanning.
private func flattenedStrings(_ value: SigilDiagnosticValue) -> [String] {
    switch value {
    case let .string(s):
        return [s]
    case let .number(n):
        return [String(n)]
    case let .boolean(b):
        return [String(b)]
    case let .array(items):
        return items.flatMap { flattenedStrings($0) }
    case let .object(pairs):
        return pairs.flatMap { key, item in flattenedStrings(.string(key)) + flattenedStrings(item) }
    }
}

private final class CapturingDiagnosticCollector: SigilDiagnosticCollector, @unchecked Sendable {
    private let lock = NSLock()
    private var eventsStorage: [SigilDiagnosticEventInput] = []
    private var operationsStorage: [(outcome: SigilDiagnosticOutcome, context: [String: SigilDiagnosticValue])] = []

    let profile: SigilDiagnosticProfile = .development
    let limits: SigilDiagnosticLimits = .default

    var events: [SigilDiagnosticEventInput] {
        lock.lock(); defer { lock.unlock() }
        return eventsStorage
    }

    var operations: [(outcome: SigilDiagnosticOutcome, context: [String: SigilDiagnosticValue])] {
        lock.lock(); defer { lock.unlock() }
        return operationsStorage
    }

    func beginSession(buildIdentity: SigilDiagnosticBuildIdentity, environment: SigilDiagnosticEnvironment) {}

    func beginOperation(name: String, expected: String, correlationID: String?) -> String {
        UUID().uuidString
    }

    func record(_ input: SigilDiagnosticEventInput) {
        lock.lock(); eventsStorage.append(input); lock.unlock()
    }

    func finishOperation(
        id: String,
        outcome: SigilDiagnosticOutcome,
        context: [String: SigilDiagnosticValue],
        durationSeconds: Double?
    ) {
        lock.lock(); operationsStorage.append((outcome, context)); lock.unlock()
    }

    func recordFailure(
        operationID: String?,
        operationName: String,
        expectedBehavior: String,
        observedBehavior: String,
        error: SigilDiagnosticError,
        context: [String: SigilDiagnosticValue],
        recoveryAttempts: [SigilDiagnosticRecoveryAttempt],
        fixtureReferences: [String],
        observedFacts: [String],
        supportedFindings: [String],
        hypotheses: [String],
        unknowns: [String],
        finalState: String
    ) -> String {
        UUID().uuidString
    }

    func snapshot() -> SigilDiagnosticSnapshot {
        SigilDiagnosticSnapshot(
            bundleID: UUID().uuidString,
            schemaVersion: SigilDiagnosticSnapshot.schemaVersion,
            profile: profile,
            generatedAt: Date(),
            captureStart: Date(),
            captureEnd: Date(),
            coverageStatus: "noSession",
            sessionID: UUID().uuidString,
            buildIdentity: SigilDiagnosticBuildIdentity(
                productVersion: nil,
                buildNumber: nil,
                sourceCommit: nil,
                componentVersions: [:]
            ),
            environment: SigilDiagnosticEnvironment(operatingSystem: "test", architecture: "arm64", hostClass: "macos-host"),
            events: [],
            incidents: [],
            health: SigilDiagnosticHealth()
        )
    }

    func exportBundle(to directory: URL?) throws -> SigilDiagnosticExportResult {
        SigilDiagnosticExportResult(
            bundleID: UUID().uuidString,
            jsonPath: "",
            markdownPath: "",
            jsonSHA256: "",
            markdownSHA256: "",
            eventCount: events.count,
            incidentCount: 0,
            redactionCount: 0
        )
    }

    func health() -> SigilDiagnosticHealth {
        SigilDiagnosticHealth()
    }
}
