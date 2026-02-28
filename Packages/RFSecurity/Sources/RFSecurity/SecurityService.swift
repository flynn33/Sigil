import CryptoKit
import Foundation
import RFCoreModels
import Security

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public enum SecurityError: Error {
    case keychainFailure(OSStatus)
    case missingKey
    case encryptionFailure
    case decryptionFailure
    case authenticationFailed
}

public protocol AppLockAuthenticating: Sendable {
    func authenticate(reason: String) async -> Bool
}

public final class LocalDeviceAuthenticator: AppLockAuthenticating, @unchecked Sendable {
    public init() {}

    public func authenticate(reason: String) async -> Bool {
        await performLocalAuthentication(reason: reason)
    }
}

public protocol MasterKeyProviding: Sendable {
    func obtainMasterKey(requireBiometricGate: Bool) async throws -> SymmetricKey
}

public final class KeychainMasterKeyProvider: MasterKeyProviding, @unchecked Sendable {
    private let primaryService = "com.sigil.masterkey"
    private let legacyService = "com.runeforge.masterkey"
    private let account = "default"

    public init() {}

    public func obtainMasterKey(requireBiometricGate: Bool) async throws -> SymmetricKey {
        if requireBiometricGate {
            try await authenticateUser()
        }

        if let existing = try loadKeyData() {
            return SymmetricKey(data: existing)
        }

        let newKey = SymmetricKey(size: .bits256)
        let data = newKey.withUnsafeBytes { Data($0) }
        try saveKeyData(data)
        return newKey
    }

    private func saveKeyData(_ data: Data) throws {
        try saveKeyData(data, service: primaryService)
    }

    private func saveKeyData(_ data: Data, service: String) throws {
        let access = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: access,
            kSecValueData: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainFailure(status)
        }
    }

    private func loadKeyData() throws -> Data? {
        if let primary = try loadKeyData(service: primaryService) {
            return primary
        }

        guard let legacy = try loadKeyData(service: legacyService) else {
            return nil
        }

        // Promote legacy keychain item to the new service namespace.
        try saveKeyData(legacy, service: primaryService)
        return legacy
    }

    private func loadKeyData(service: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw SecurityError.keychainFailure(status)
        }
        return data
    }

    private func authenticateUser() async throws {
        let success = await performLocalAuthentication(reason: "Unlock Sigil profile encryption")
        guard success else {
            throw SecurityError.authenticationFailed
        }
    }
}

public protocol LockConfigurationProviding: Sendable {
    var isBiometricLockEnabled: Bool { get }
    func setBiometricLockEnabled(_ enabled: Bool)
}

public final class LockConfigurationStore: LockConfigurationProviding, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "rf.settings.biometric.lock.enabled"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isBiometricLockEnabled: Bool {
        defaults.bool(forKey: key)
    }

    public func setBiometricLockEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: key)
    }
}

public final class EncryptionService: @unchecked Sendable {
    private let masterKeyProvider: MasterKeyProviding
    private let lockProvider: LockConfigurationProviding

    public init(masterKeyProvider: MasterKeyProviding = KeychainMasterKeyProvider(), lockProvider: LockConfigurationProviding = LockConfigurationStore()) {
        self.masterKeyProvider = masterKeyProvider
        self.lockProvider = lockProvider
    }

    public func encrypt(_ plaintext: Data) async throws -> Data {
        let key = try await masterKeyProvider.obtainMasterKey(requireBiometricGate: lockProvider.isBiometricLockEnabled)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let payload = sealed.combined else {
            throw SecurityError.encryptionFailure
        }
        return payload
    }

    public func decrypt(_ ciphertext: Data) async throws -> Data {
        let key = try await masterKeyProvider.obtainMasterKey(requireBiometricGate: lockProvider.isBiometricLockEnabled)
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }
}

private func performLocalAuthentication(reason: String) async -> Bool {
    #if canImport(LocalAuthentication)
    let context = LAContext()
    var authError: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
        return false
    }

    return await withCheckedContinuation { continuation in
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            continuation.resume(returning: success)
        }
    }
    #else
    return true
    #endif
}
