import Foundation
import RFSigilCoreModels
import RFSigilDiagnostics

// MARK: - Secure local persistence service (runtime integration)
//
// Thin, truthful runtime surface over the local-only encrypted record store
// (Slice 2). Two behaviors are load-bearing and are the point of this layer:
//
//   1. A failed save is NEVER reported as success. `save` returns a
//      `SigilSaveOutcome`; a write or key failure yields `success == false`
//      with a `failureCategory`, and the stored record count is left
//      unchanged.
//   2. Diagnostics are redacted by construction. The service only ever hands
//      the collector coarse, non-sensitive facts (record type, failure
//      category, record count, operation name, outcome). It never records the
//      record payload, key material, storage paths, or record identifiers.
//
// Local only: no network, no CloudKit, no sync service, no upload.

/// The coarse, non-sensitive classification of a persistence failure. A
/// distinct diagnostic category, never a raw error string, is what gets logged.
public enum SigilPersistenceFailureCategory: String, Codable, Hashable, Sendable {
    case keyUnavailable
    case writeFailed
    case notFound
    case decryptionFailed
    case corruptRecord
    case unsupportedVersion
    case unknown
}

/// Where the encryption key for a store partition comes from. Reported as a
/// category only; the key material itself is never stored beside ciphertext
/// and never recorded.
public enum SigilKeySource: String, Codable, Hashable, Sendable {
    case keychain
    case injected
}

/// The outcome of a secure save. Truthful: a failure is always `success ==
/// false` with a `failureCategory`; the record count only advances on success.
public struct SigilSaveOutcome: Hashable, Sendable {
    public let success: Bool
    public let recordCount: Int
    public let failureCategory: SigilPersistenceFailureCategory?

    public init(success: Bool, recordCount: Int, failureCategory: SigilPersistenceFailureCategory?) {
        self.success = success
        self.recordCount = recordCount
        self.failureCategory = failureCategory
    }
}

/// Pure, I/O-free readiness description used by the dashboard. Because it
/// performs no I/O it is safe to call at dashboard-assembly time.
public struct SigilPersistenceReadinessInfo: Hashable, Sendable {
    public let status: RFSigilStatusKind
    public let summary: String
    public let detail: String
    public let recordCount: Int

    public init(status: RFSigilStatusKind, summary: String, detail: String, recordCount: Int) {
        self.status = status
        self.summary = summary
        self.detail = detail
        self.recordCount = recordCount
    }
}

/// A tiny thread-safe counter. Its accessors are synchronous, keeping the lock
/// out of any asynchronous call path; the counter is therefore safe to read or
/// update from both the synchronous dashboard surface and the asynchronous save
/// path without tripping the async-context locking diagnostic.
private final class IntCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue = 0

    func value() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storedValue
    }

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        storedValue += 1
        return storedValue
    }
}

/// Runtime facade over a `SigilSecureRecordStore` with truthful outcomes and
/// redacted, local-only diagnostics. The cached record count is guarded by a
/// small lock so reads are I/O-free and safe from any context.
public final class SigilSecurePersistenceService: @unchecked Sendable {
    private let store: SigilSecureRecordStore
    private let diagnostics: (any SigilDiagnosticCollector)?
    private let counter = IntCounter()

    /// The key source, reported as a category only.
    public let keySource: SigilKeySource

    public init(
        store: SigilSecureRecordStore,
        diagnostics: (any SigilDiagnosticCollector)? = nil,
        keySource: SigilKeySource = .keychain
    ) {
        self.store = store
        self.diagnostics = diagnostics
        self.keySource = keySource
    }

    /// The number of records this service instance has successfully persisted.
    /// Maintained under a lock so no I/O is required to read it.
    public var recordCount: Int {
        counter.value()
    }

    /// Pure readiness for the dashboard. Performs no I/O.
    public func readiness() -> SigilPersistenceReadinessInfo {
        SigilPersistenceReadinessInfo(
            status: .pass,
            summary: "Sensitive records persist locally as AES-GCM ciphertext; a failed save is reported as a failure.",
            detail: "Key source: \(keySource.rawValue); keys are stored separately from ciphertext. Local only: no network, CloudKit, sync service, or upload.",
            recordCount: recordCount
        )
    }

    /// Encrypts and atomically persists a record. A failure is returned as a
    /// non-success `SigilSaveOutcome`; it never throws and never reports a
    /// failure as success.
    @discardableResult
    public func save(_ plaintext: Data, id: SigilRecordIdentity) async -> SigilSaveOutcome {
        let startedAt = Date()
        let diagnostic = diagnostics
        let operationID = diagnostic?.beginOperation(
            name: "sigil.persistence.save",
            expected: "The sensitive record is sealed with AES-GCM and persisted atomically; a failed save is reported as a failure, never as success.",
            correlationID: nil
        )
        do {
            try await store.save(plaintext, id: id)
            let newCount = counter.increment()
            let outcome = SigilSaveOutcome(success: true, recordCount: newCount, failureCategory: nil)
            if let diagnostic, let operationID {
                diagnostic.finishOperation(
                    id: operationID,
                    outcome: .success,
                    context: [
                        "recordType": .string(id.recordType.rawValue),
                        "recordCount": .number(Double(newCount)),
                        "keySource": .string(keySource.rawValue)
                    ],
                    durationSeconds: Date().timeIntervalSince(startedAt)
                )
                diagnostic.record(
                    SigilDiagnosticEventInput(
                        source: "sigil.persistence",
                        severity: .info,
                        type: "sigil.persistence.save.success",
                        message: "Sensitive record persisted locally as AES-GCM ciphertext.",
                        operationID: operationID,
                        context: [
                            "recordType": .string(id.recordType.rawValue),
                            "recordCount": .number(Double(newCount))
                        ]
                    )
                )
            }
            return outcome
        } catch {
            let category = Self.category(for: error)
            let current = recordCount
            let outcome = SigilSaveOutcome(success: false, recordCount: current, failureCategory: category)
            if let diagnostic, let operationID {
                diagnostic.finishOperation(
                    id: operationID,
                    outcome: .blocked,
                    context: [
                        "recordType": .string(id.recordType.rawValue),
                        "failureCategory": .string(category.rawValue),
                        "recordCount": .number(Double(current))
                    ],
                    durationSeconds: Date().timeIntervalSince(startedAt)
                )
                diagnostic.record(
                    SigilDiagnosticEventInput(
                        source: "sigil.persistence",
                        severity: .error,
                        type: "sigil.persistence.save.failure",
                        message: "Sensitive record save failed and is reported as a failure; the record payload is not recorded.",
                        operationID: operationID,
                        context: [
                            "recordType": .string(id.recordType.rawValue),
                            "failureCategory": .string(category.rawValue),
                            "recordCount": .number(Double(current))
                        ]
                    )
                )
            }
            return outcome
        }
    }

    /// Loads and decrypts a record. Fails closed by rethrowing the store's
    /// typed storage error (no key material, paths, or payloads are exposed).
    public func load(_ id: SigilRecordIdentity) async throws -> Data {
        try await store.load(id)
    }

    /// Removes a record from the local store. Throws `SigilSecureStorageError.notFound`
    /// when the record does not exist; the caller is expected to confirm destructive
    /// intent before invoking this.
    public func delete(_ id: SigilRecordIdentity) async throws {
        try await store.delete(id)
    }

    /// Lists all record identities in the store, sorted by storageID then
    /// recordType. Returns an empty array when the partition directory does not
    /// yet exist. This is a directory listing; it does not decrypt any record.
    public func list() async throws -> [SigilRecordIdentity] {
        try await store.list()
    }

    private static func category(for error: Error) -> SigilPersistenceFailureCategory {
        if let storageError = error as? SigilSecureStorageError {
            switch storageError {
            case .keyUnavailable: return .keyUnavailable
            case .notFound: return .notFound
            case .decryptionFailed: return .decryptionFailed
            case .corruptRecord: return .corruptRecord
            case .envelopeVersionUnsupported: return .unsupportedVersion
            case .ioError: return .writeFailed
            }
        }
        return .unknown
    }
}
