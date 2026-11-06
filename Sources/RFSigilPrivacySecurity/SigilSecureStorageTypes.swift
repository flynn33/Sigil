import Foundation

// MARK: - Secure local persistence (product-owned, Apple-native)
//
// Real, local-only, encrypted-at-rest persistence for sensitive Sigil records.
// This is the implementation the Phase 1 posture previously only *modeled*. It
// uses Apple-native crypto (CryptoKit AES-GCM) and key management
// (Security/Keychain) as appropriate, stores keys separately from ciphertext,
// and never confuses a hash with encryption. Local only: no CloudKit, no sync
// service, no background upload.

/// The kind of sensitive record being persisted. Storage identity is deliberately
/// separate from mathematical identity (a profile's `profileHash` is *not* used
/// as a storage key); these storage ids are opaque, storage-scoped identifiers.
public enum SigilRecordType: String, Codable, CaseIterable, Hashable, Sendable {
    case profile = "profile"
    case identity = "identity"
    case personalCodex = "personal_codex"
    case canonicalGeometry = "canonical_geometry"
    case flare = "flare"
}

/// A storage-scoped identity: which record, in which storage partition.
/// This is *storage* identity, not the profile's mathematical identity.
public struct SigilRecordIdentity: Hashable, Codable, Sendable {
    public let storageID: String
    public let recordType: SigilRecordType

    public init(storageID: String, recordType: SigilRecordType) {
        self.storageID = storageID
        self.recordType = recordType
    }
}

/// A versioned, self-describing encrypted envelope. The `ciphertext` field holds
/// the AES-GCM "combined" buffer (nonce || ciphertext || authentication tag).
/// `recordDigest` is a SHA-256 hash of the plaintext used as an integrity marker
/// on read (a hash, explicitly not the encryption).
public struct SigilSecureEnvelope: Codable, Hashable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let keyID: String
    public let recordType: SigilRecordType
    public let storageID: String
    public let recordDigest: String
    public let ciphertext: [UInt8]
    public let createdAt: Date

    public init(
        version: Int,
        keyID: String,
        recordType: SigilRecordType,
        storageID: String,
        recordDigest: String,
        ciphertext: [UInt8],
        createdAt: Date
    ) {
        self.version = version
        self.keyID = keyID
        self.recordType = recordType
        self.storageID = storageID
        self.recordDigest = recordDigest
        self.ciphertext = ciphertext
        self.createdAt = createdAt
    }
}

/// Fail-closed storage errors. Paths are stripped of sensitive detail; no key
/// material is ever included.
public enum SigilSecureStorageError: Error, Equatable, Sendable {
    case keyUnavailable
    case notFound
    case corruptRecord
    case decryptionFailed
    case envelopeVersionUnsupported(Int)
    case ioError
}
