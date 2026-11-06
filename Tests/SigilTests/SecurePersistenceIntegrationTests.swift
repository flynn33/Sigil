import Foundation
import RFSigilCoreModels
import RFSigilDiagnostics
import RFSigilPrivacySecurity
import RFSigilRuntime
import XCTest

final class SecurePersistenceIntegrationTests: XCTestCase {

    // MARK: - Helpers

    private static let sensitiveMarker = "SIGIL_SENTINEL_PERSONAL_DATA_MARKER_9F3"

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

    /// A self-contained capturing diagnostic collector. It records every event
    /// and operation finish exactly as handed to it and drops nothing, so the
    /// redaction test verifies the *service* never leaks sensitive material,
    /// independent of any production collector's own redaction.
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

    // MARK: - Failed save is never reported as success

    @MainActor
    func testFailedSaveIsReportedAsFailureNotSuccess() async throws {
        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("sigil-sec-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Make the partition read-only so the atomic write fails with EACCES.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }

        let store = SigilSecureRecordStore(
            directoryURL: directory,
            keyStore: SigilInMemoryKeyStore(),
            keyID: "sigil-default"
        )
        let service = SigilSecurePersistenceService(store: store, diagnostics: nil, keySource: .injected)

        let outcome = await service.save(Data([0x00, 0x01, 0x02]), id: SigilRecordIdentity(storageID: "rec", recordType: .profile))

        XCTAssertFalse(outcome.success)
        XCTAssertEqual(outcome.failureCategory, .writeFailed)
        // A failed save must not be counted as a persisted record.
        XCTAssertEqual(service.recordCount, 0)
    }

    // MARK: - Save + load round-trip through the service

    @MainActor
    func testSaveAndLoadRoundTripThroughService() async throws {
        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("sigil-sec-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SigilSecureRecordStore(
            directoryURL: directory,
            keyStore: SigilInMemoryKeyStore(),
            keyID: "sigil-default"
        )
        let service = SigilSecurePersistenceService(store: store, diagnostics: nil, keySource: .injected)

        let plaintext = Data("round-trip personal content".utf8)
        let identity = SigilRecordIdentity(storageID: "rec-1", recordType: .identity)
        let saveOutcome = await service.save(plaintext, id: identity)

        XCTAssertTrue(saveOutcome.success)
        XCTAssertNil(saveOutcome.failureCategory)
        XCTAssertEqual(saveOutcome.recordCount, 1)

        let loaded = try await service.load(identity)
        XCTAssertEqual(loaded, plaintext)
    }

    // MARK: - Dashboard exposes the secure-persistence card

    @MainActor
    func testDashboardIncludesSecurePersistenceCard() {
        let assembly = SigilRuntimeAssembly()
        let status = assembly.dashboardStatus()
        let card = status.cards.first { $0.id == "secure-persistence" }

        XCTAssertNotNil(card)
        XCTAssertEqual(card?.status, .pass)
        // The card must not surface any sensitive storage path.
        XCTAssertTrue(card?.summary.contains("AES-GCM") ?? false)
    }

    // MARK: - Diagnostics are redacted by construction (no payload / key leak)

    @MainActor
    func testSaveDiagnosticsNeverLeakRecordPayloadOrKeyMaterial() async throws {
        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("sigil-sec-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let keyStore = SigilInMemoryKeyStore()
        // Prime the key; its material must never appear in diagnostics.
        let key = try keyStore.createKey(id: "sigil-default")

        let store = SigilSecureRecordStore(
            directoryURL: directory,
            keyStore: keyStore,
            keyID: "sigil-default"
        )
        let collector = CapturingDiagnosticCollector()
        let service = SigilSecurePersistenceService(store: store, diagnostics: collector, keySource: .injected)

        let identity = SigilRecordIdentity(storageID: "rec-sensitive", recordType: .personalCodex)
        let sensitive = Data(Self.sensitiveMarker.utf8)
        let outcome = await service.save(sensitive, id: identity)
        XCTAssertTrue(outcome.success)

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

        // The record payload and its marker are never recorded.
        XCTAssertFalse(blob.contains(Self.sensitiveMarker))
        // The key material (raw bytes and its base-64 form) is never recorded.
        XCTAssertFalse(captured.contains(key.withUnsafeBytes { String(decoding: $0, as: UTF8.self) }))
        XCTAssertFalse(blob.contains(key.withUnsafeBytes { Data($0).base64EncodedString() }))
        // The storage path / identifier is not surfaced either.
        XCTAssertFalse(blob.contains(directory.lastPathComponent))
        XCTAssertFalse(blob.contains(identity.storageID))

        // A failure path is also redacted: no payload, only a coarse category.
        let failingDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("sigil-sec-ro-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: failingDirectory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: failingDirectory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: failingDirectory.path)
            try? FileManager.default.removeItem(at: failingDirectory)
        }
        let readOnlyStore = SigilSecureRecordStore(
            directoryURL: failingDirectory,
            keyStore: SigilInMemoryKeyStore(),
            keyID: "sigil-default"
        )
        let failingService = SigilSecurePersistenceService(store: readOnlyStore, diagnostics: collector, keySource: .injected)
        let failingOutcome = await failingService.save(sensitive, id: identity)
        XCTAssertFalse(failingOutcome.success)
        XCTAssertEqual(failingOutcome.failureCategory, .writeFailed)

        let blobAfterFailure = (collector.events.map { $0.message + $0.type }
            + collector.events.flatMap { $0.context.values.flatMap { flattenedStrings($0) } }
            + collector.operations.flatMap { $0.context.values.flatMap { flattenedStrings($0) } })
            .joined(separator: "\u{0}")
        XCTAssertFalse(blobAfterFailure.contains(Self.sensitiveMarker))
    }
}
