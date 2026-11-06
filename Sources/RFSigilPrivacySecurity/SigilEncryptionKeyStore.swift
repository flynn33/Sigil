import CryptoKit
import Foundation
#if canImport(Security)
import Security
#endif

// MARK: - Encryption key management (Apple-native, injectable)
//
// Keys are managed separately from ciphertext and are never stored beside the
// encrypted record. The production store uses the platform keychain with the
// most restrictive local-only accessibility; an in-memory store is provided so
// the native crypto/storage logic can be exercised deterministically on the
// host. Key protection by the OS (data protection / keychain access control)
// is a device/simulator qualification, not something a host unit test proves.

/// Provides AES-GCM keys by key identifier. Implementation-owned.
public protocol SigilEncryptionKeyProviding: AnyObject {
    /// Returns the key for an existing identifier, or nil if unavailable.
    func key(for keyID: String) -> SymmetricKey?
    /// Creates and persists a fresh 256-bit key under the identifier.
    @discardableResult
    func createKey(id: String) throws -> SymmetricKey
}

/// In-memory key store for tests and ephemeral use. Thread-safe.
public final class SigilInMemoryKeyStore: SigilEncryptionKeyProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var keys: [String: Data] = [:]

    public init() {}

    public func key(for keyID: String) -> SymmetricKey? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = keys[keyID], data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    @discardableResult
    public func createKey(id: String) throws -> SymmetricKey {
        let raw = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        lock.lock()
        keys[id] = raw
        lock.unlock()
        return SymmetricKey(data: raw)
    }
}

/// Production key store backed by the platform keychain with local-only,
/// most-restrictive accessibility. Keys are 256-bit AES-GCM keys.
public final class SigilKeychainKeyStore: SigilEncryptionKeyProviding, @unchecked Sendable {
    private let service: String

    public init(service: String = "com.ravenforge.sigil.secure-storage") {
        self.service = service
    }

    public func key(for keyID: String) -> SymmetricKey? {
        #if canImport(Security)
        guard let raw = Self.readRawKey(id: keyID, service: service), raw.count == 32 else { return nil }
        return SymmetricKey(data: raw)
        #else
        return nil
        #endif
    }

    @discardableResult
    public func createKey(id: String) throws -> SymmetricKey {
        let raw = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        #if canImport(Security)
        try Self.writeRawKey(raw, id: id, service: service)
        #endif
        return SymmetricKey(data: raw)
    }

    #if canImport(Security)
    private static func baseQuery(id: String, service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id
        ]
    }

    private static func readRawKey(id: String, service: String) -> Data? {
        var query = baseQuery(id: id, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    private static func writeRawKey(_ raw: Data, id: String, service: String) throws {
        var query = baseQuery(id: id, service: service)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: raw] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery(id: id, service: service)
            addQuery[kSecValueData as String] = raw
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw SigilSecureStorageError.ioError
            }
        } else if updateStatus != errSecSuccess {
            throw SigilSecureStorageError.ioError
        }
    }
    #endif
}
