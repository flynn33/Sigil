import CryptoKit
import Foundation

// MARK: - Secure record store (Apple-native, local-only)
//
// A serialized actor that owns transactional save/load/delete of sensitive
// records under a single partition. Each record is a versioned AES-GCM
// envelope written atomically: the plaintext is sealed with a fresh random
// nonce, written to a temporary file in the same directory, and then swapped
// into place with `replaceItemAt`. Because the swap is atomic and only runs
// after a complete, valid temp file exists, a failed or interrupted write never
// leaves a half-written record and always preserves the last-verified record.
// Local only: no CloudKit, no sync, no upload.
public actor SigilSecureRecordStore {
    private let directoryURL: URL
    private let keyStore: any SigilEncryptionKeyProviding
    private let keyID: String

    public init(
        directoryURL: URL,
        keyStore: any SigilEncryptionKeyProviding,
        keyID: String = "sigil-default"
    ) {
        self.directoryURL = directoryURL
        self.keyStore = keyStore
        self.keyID = keyID
    }

    /// Ensures the partition key exists, creating it if necessary.
    public func prepare() throws {
        if keyStore.key(for: keyID) == nil {
            _ = try keyStore.createKey(id: keyID)
        }
    }

    /// Encrypts and atomically persists a record. Auto-creates the key if needed.
    public func save(_ plaintext: Data, id: SigilRecordIdentity) throws {
        try prepare()
        guard let key = keyStore.key(for: keyID) else {
            throw SigilSecureStorageError.keyUnavailable
        }
        // Seal with AES-GCM using a fresh random nonce. `combined` is the
        // nonce || ciphertext || authentication tag buffer.
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw SigilSecureStorageError.ioError
        }
        let envelope = SigilSecureEnvelope(
            version: SigilSecureEnvelope.currentVersion,
            keyID: keyID,
            recordType: id.recordType,
            storageID: id.storageID,
            recordDigest: Self.sha256Hex(plaintext),
            ciphertext: Array(combined),
            createdAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let bytes = try encoder.encode(envelope)
        try Self.writeAtomically(bytes, to: fileURL(for: id))
    }

    /// Loads, decrypts and integrity-verifies a record. Fails closed.
    public func load(_ id: SigilRecordIdentity) throws -> Data {
        let url = fileURL(for: id)
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            throw SigilSecureStorageError.notFound
        }
        let bytes: Data
        do {
            bytes = try Data(contentsOf: url)
        } catch {
            throw SigilSecureStorageError.ioError
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(SigilSecureEnvelope.self, from: bytes) else {
            throw SigilSecureStorageError.corruptRecord
        }
        guard envelope.version == SigilSecureEnvelope.currentVersion else {
            throw SigilSecureStorageError.envelopeVersionUnsupported(envelope.version)
        }
        guard let key = keyStore.key(for: envelope.keyID) else {
            throw SigilSecureStorageError.keyUnavailable
        }
        let plaintext: Data
        do {
            let box = try AES.GCM.SealedBox(combined: Data(envelope.ciphertext))
            plaintext = try AES.GCM.open(box, using: key)
        } catch {
            throw SigilSecureStorageError.decryptionFailed
        }
        guard Self.sha256Hex(plaintext) == envelope.recordDigest else {
            throw SigilSecureStorageError.corruptRecord
        }
        return plaintext
    }

    public func delete(_ id: SigilRecordIdentity) throws {
        let url = fileURL(for: id)
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            throw SigilSecureStorageError.notFound
        }
        do {
            try fm.removeItem(at: url)
        } catch {
            throw SigilSecureStorageError.ioError
        }
    }

    public func exists(_ id: SigilRecordIdentity) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id).path)
    }

    public func list() throws -> [SigilRecordIdentity] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directoryURL.path) else { return [] }
        let files = (try? fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        var result: [SigilRecordIdentity] = []
        for file in files where file.pathExtension == Self.fileExtension {
            let name = file.deletingPathExtension().lastPathComponent
            guard let lastDot = name.lastIndex(of: "."),
                  let recordType = SigilRecordType(rawValue: String(name[name.index(after: lastDot)...]))
            else { continue }
            let storageID = String(name[..<lastDot])
            result.append(SigilRecordIdentity(storageID: storageID, recordType: recordType))
        }
        return result.sorted {
            if $0.storageID != $1.storageID { return $0.storageID < $1.storageID }
            return $0.recordType.rawValue < $1.recordType.rawValue
        }
    }

    // MARK: - File plumbing

    private static let fileExtension = "sigilsec"

    private func fileURL(for id: SigilRecordIdentity) -> URL {
        directoryURL.appendingPathComponent("\(Self.sanitize(id.storageID)).\(id.recordType.rawValue).\(Self.fileExtension)")
    }

    private static func sanitize(_ value: String) -> String {
        let allowed = value.unicodeScalars.filter {
            ($0.value >= 0x30 && $0.value <= 0x39)
                || ($0.value >= 0x41 && $0.value <= 0x5A)
                || ($0.value >= 0x61 && $0.value <= 0x7A)
                || $0 == "-" || $0 == "_"
        }
        let out = String(String.UnicodeScalarView(allowed))
        return out.isEmpty ? "record" : out
    }

    private static func writeAtomically(_ bytes: Data, to url: URL) throws {
        let fm = FileManager.default
        let parent = url.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path) {
            do {
                try fm.createDirectory(at: parent, withIntermediateDirectories: true)
            } catch {
                throw SigilSecureStorageError.ioError
            }
        }
        let temp = parent.appendingPathComponent(".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
        do {
            try bytes.write(to: temp, options: Self.writeOptions())
        } catch {
            try? fm.removeItem(at: temp)
            throw SigilSecureStorageError.ioError
        }
        do {
            _ = try fm.replaceItemAt(url, withItemAt: temp)
        } catch {
            try? fm.removeItem(at: temp)
            throw SigilSecureStorageError.ioError
        }
    }

    private static func writeOptions() -> Data.WritingOptions {
        var options: Data.WritingOptions = [.atomic]
        #if !os(macOS)
        options.insert(.completeFileProtection)
        #endif
        return options
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
