import CryptoKit
import Foundation
import RFSigilPrivacySecurity
import XCTest

final class SecureStorageTests: XCTestCase {
    private var dirsToClean: [URL] = []

    override func tearDown() {
        super.tearDown()
        for url in dirsToClean {
            try? FileManager.default.removeItem(at: url)
        }
        dirsToClean.removeAll()
    }

    private func makeDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-secure-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        dirsToClean.append(url)
        return url
    }

    private func makeStore(in dir: URL, keyStore: SigilInMemoryKeyStore) -> SigilSecureRecordStore {
        SigilSecureRecordStore(directoryURL: dir, keyStore: keyStore, keyID: "k1")
    }

    // MARK: - Round-trip

    func testSaveLoadRoundTrip() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "alpha", recordType: .profile)
        let payload = Data("hello sensitive payload".utf8)

        try await store.save(payload, id: id)
        let loaded = try await store.load(id)

        XCTAssertEqual(loaded, payload)
        let existsNow = await store.exists(id)
        XCTAssertTrue(existsNow)
    }

    // MARK: - No plaintext leak on disk

    func testStoredBytesContainNoPlaintextMarker() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "leakcheck", recordType: .profile)
        let marker = "SIGIL_SYNTHETIC_SECRET_MARKER_XYZ_1234"
        let payload = Data(marker.utf8)

        try await store.save(payload, id: id)

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        let raw = try Data(contentsOf: files[0])
        XCTAssertFalse(raw.contains(Data(marker.utf8)), "Plaintext marker leaked to disk")
        // Round-trip still works.
        let loaded = try await store.load(id)
        XCTAssertEqual(loaded, payload)
    }

    // MARK: - Keys are stored separately from ciphertext

    func testKeyMaterialNotBesideCiphertext() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "keysafe", recordType: .identity)

        _ = try keyStore.createKey(id: "k1")
        let key = keyStore.key(for: "k1")!
        try await store.save(Data("some identity bytes".utf8), id: id)

        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        let raw = try Data(contentsOf: files[0])
        XCTAssertFalse(raw.contains(key.withUnsafeBytes { Data($0) }), "Key material found in the record file")
    }

    // MARK: - Atomic update (replace)

    func testUpdateReplacesAtomically() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "upd", recordType: .canonicalGeometry)

        try await store.save(Data("v1".utf8), id: id)
        try await store.save(Data("v2".utf8), id: id)
        let loaded = try await store.load(id)
        XCTAssertEqual(loaded, Data("v2".utf8))
        // Only one file on disk for the record.
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
    }

    // MARK: - Failed replacement preserves last-verified record

    func testFailedReplacementPreservesLastVerified() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "lastgood", recordType: .profile)

        try await store.save(Data("last-good".utf8), id: id)
        let priorMode = (try? FileManager.default.attributesOfItem(atPath: dir.path)[.posixPermissions] as? NSNumber)?.uint16Value ?? 0o755

        // Make the directory read-only so the next write fails.
        _ = chmod(dir.path, 0o555)
        defer { _ = chmod(dir.path, priorMode) }

        do {
            try await store.save(Data("should-not-land".utf8), id: id)
            XCTFail("Expected the failed write to throw")
        } catch is SigilSecureStorageError {
            // expected
        }

        // The last-verified record is still intact and readable.
        let loaded = try await store.load(id)
        XCTAssertEqual(loaded, Data("last-good".utf8))
    }

    // MARK: - Wrong key fails closed

    func testLoadWithWrongKeyFailsClosed() async throws {
        let dir = makeDir()
        let keyStoreA = SigilInMemoryKeyStore()
        let storeA = makeStore(in: dir, keyStore: keyStoreA)
        let id = SigilRecordIdentity(storageID: "wrongkey", recordType: .flare)
        try await storeA.save(Data("secret".utf8), id: id)

        // A different store whose key "k1" is different bytes.
        let keyStoreB = SigilInMemoryKeyStore()
        _ = try keyStoreB.createKey(id: "k1")
        let storeB = makeStore(in: dir, keyStore: keyStoreB)

        do {
            _ = try await storeB.load(id)
            XCTFail("Expected decryption failure with a different key")
        } catch SigilSecureStorageError.decryptionFailed {
            // expected
        }
    }

    // MARK: - Missing key fails closed

    func testLoadWithMissingKeyFailsClosed() async throws {
        let dir = makeDir()
        let keyStoreA = SigilInMemoryKeyStore()
        let storeA = makeStore(in: dir, keyStore: keyStoreA)
        let id = SigilRecordIdentity(storageID: "nokey", recordType: .profile)
        try await storeA.save(Data("secret".utf8), id: id)

        let keyStoreB = SigilInMemoryKeyStore() // has no key "k1"
        let storeB = makeStore(in: dir, keyStore: keyStoreB)

        do {
            _ = try await storeB.load(id)
            XCTFail("Expected keyUnavailable")
        } catch SigilSecureStorageError.keyUnavailable {
            // expected
        }
    }

    // MARK: - Tampered ciphertext fails authentication

    func testTamperedCiphertextFailsClosed() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "tamp", recordType: .personalCodex)
        try await store.save(Data("authentic".utf8), id: id)

        // Flip one byte in the stored ciphertext and write it back.
        let file = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)[0]
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(SigilSecureEnvelope.self, from: try Data(contentsOf: file))
        var tamperedCiphertext = envelope.ciphertext
        tamperedCiphertext[0] ^= 0xFF
        let tampered = SigilSecureEnvelope(
            version: envelope.version,
            keyID: envelope.keyID,
            recordType: envelope.recordType,
            storageID: envelope.storageID,
            recordDigest: envelope.recordDigest,
            ciphertext: tamperedCiphertext,
            createdAt: envelope.createdAt
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(tampered).write(to: file, options: .atomic)

        do {
            _ = try await store.load(id)
            XCTFail("Expected decryption failure for tampered ciphertext")
        } catch SigilSecureStorageError.decryptionFailed {
            // expected
        }
    }

    // MARK: - Corrupt (undecodable) record

    func testCorruptRecordFailsClosed() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "corrupt", recordType: .profile)

        let name = "corrupt.profile.sigilsec"
        try Data("not a valid envelope".utf8).write(to: dir.appendingPathComponent(name), options: .atomic)

        do {
            _ = try await store.load(id)
            XCTFail("Expected corruptRecord")
        } catch SigilSecureStorageError.corruptRecord {
            // expected
        }
    }

    // MARK: - Unsupported envelope version

    func testUnsupportedEnvelopeVersionFailsClosed() async throws {
        let dir = makeDir()
        let keyStore = SigilInMemoryKeyStore()
        let store = makeStore(in: dir, keyStore: keyStore)
        let id = SigilRecordIdentity(storageID: "ver", recordType: .identity)

        _ = try keyStore.createKey(id: "k1")
        let key = keyStore.key(for: "k1")!
        let sealed = try AES.GCM.seal(Data("x".utf8), using: key)
        let combined = try XCTUnwrap(sealed.combined)
        let envelope = SigilSecureEnvelope(
            version: 99,
            keyID: "k1",
            recordType: .identity,
            storageID: "ver",
            recordDigest: "deadbeef",
            ciphertext: Array(combined),
            createdAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(envelope).write(to: dir.appendingPathComponent("ver.identity.sigilsec"), options: .atomic)

        do {
            _ = try await store.load(id)
            XCTFail("Expected unsupported version")
        } catch SigilSecureStorageError.envelopeVersionUnsupported(let v) {
            XCTAssertEqual(v, 99)
        }
    }

    // MARK: - Not found

    func testLoadMissingRecordIsNotFound() async throws {
        let dir = makeDir()
        let store = makeStore(in: dir, keyStore: SigilInMemoryKeyStore())
        let id = SigilRecordIdentity(storageID: "ghost", recordType: .profile)
        do {
            _ = try await store.load(id)
            XCTFail("Expected notFound")
        } catch SigilSecureStorageError.notFound {
            // expected
        }
    }

    // MARK: - List and delete

    func testListAndDelete() async throws {
        let dir = makeDir()
        let store = makeStore(in: dir, keyStore: SigilInMemoryKeyStore())
        let a = SigilRecordIdentity(storageID: "a", recordType: .profile)
        let b = SigilRecordIdentity(storageID: "b", recordType: .personalCodex)
        try await store.save(Data("1".utf8), id: a)
        try await store.save(Data("2".utf8), id: b)

        let listed = try await store.list()
        XCTAssertEqual(Set(listed), Set([a, b]))

        try await store.delete(a)
        let existsA = await store.exists(a)
        XCTAssertFalse(existsA)
        let after = try await store.list()
        XCTAssertEqual(Set(after), Set([b]))
        do {
            _ = try await store.load(a)
            XCTFail("Expected notFound after delete")
        } catch SigilSecureStorageError.notFound {
            // expected
        }
    }

    // MARK: - Concurrent writes are serialized and consistent

    func testConcurrentWritesAreConsistent() async throws {
        let dir = makeDir()
        let store = makeStore(in: dir, keyStore: SigilInMemoryKeyStore())
        let ids: [SigilRecordIdentity] = (0..<8).map {
            SigilRecordIdentity(storageID: "c\($0)", recordType: .profile)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask {
                    try await store.save(Data("payload-\(index)".utf8), id: id)
                }
            }
            try await group.waitForAll()
        }

        for (index, id) in ids.enumerated() {
            let loaded = try await store.load(id)
            XCTAssertEqual(loaded, Data("payload-\(index)".utf8))
        }
        let listedCount = try await store.list().count
        XCTAssertEqual(listedCount, ids.count)
    }

    // MARK: - Storage identity is separate from mathematical identity

    func testStorageIdentityIsIndependentOfMathematicalIdentity() async throws {
        let dir = makeDir()
        let store = makeStore(in: dir, keyStore: SigilInMemoryKeyStore())
        // A storage id that is clearly not a SHA-256 profile hash.
        let id = SigilRecordIdentity(storageID: "p-0001", recordType: .profile)
        try await store.save(Data("profile bytes".utf8), id: id)
        let loaded = try await store.load(id)
        XCTAssertEqual(loaded, Data("profile bytes".utf8))
    }
}
