import CryptoKit
import Foundation
import Testing
@testable import RFSecurity

private struct MockKeyProvider: MasterKeyProviding {
    let key = SymmetricKey(data: Data(repeating: 42, count: 32))

    func obtainMasterKey(requireBiometricGate: Bool) async throws -> SymmetricKey {
        key
    }
}

private actor RecordingKeyProvider: MasterKeyProviding {
    private var flags: [Bool] = []
    private let key = SymmetricKey(data: Data(repeating: 7, count: 32))

    func obtainMasterKey(requireBiometricGate: Bool) async throws -> SymmetricKey {
        flags.append(requireBiometricGate)
        return key
    }

    func recordedFlags() -> [Bool] {
        flags
    }
}

private final class MockLockProvider: LockConfigurationProviding, @unchecked Sendable {
    var isBiometricLockEnabled: Bool

    init(enabled: Bool = false) {
        self.isBiometricLockEnabled = enabled
    }

    func setBiometricLockEnabled(_ enabled: Bool) {
        isBiometricLockEnabled = enabled
    }
}

@Test
func encryptionRoundTrip() async throws {
    let service = EncryptionService(masterKeyProvider: MockKeyProvider(), lockProvider: MockLockProvider())
    let raw = Data("sigil-secret".utf8)

    let encrypted = try await service.encrypt(raw)
    #expect(encrypted != raw)

    let decrypted = try await service.decrypt(encrypted)
    #expect(decrypted == raw)
}

@Test
func encryptionPassesBiometricGateFlagWhenEnabled() async throws {
    let keyProvider = RecordingKeyProvider()
    let lockProvider = MockLockProvider(enabled: true)
    let service = EncryptionService(masterKeyProvider: keyProvider, lockProvider: lockProvider)

    _ = try await service.encrypt(Data("locked".utf8))

    let flags = await keyProvider.recordedFlags()
    #expect(flags == [true])
}

@Test
func encryptionPassesBiometricGateFlagWhenDisabled() async throws {
    let keyProvider = RecordingKeyProvider()
    let lockProvider = MockLockProvider(enabled: false)
    let service = EncryptionService(masterKeyProvider: keyProvider, lockProvider: lockProvider)

    _ = try await service.encrypt(Data("open".utf8))

    let flags = await keyProvider.recordedFlags()
    #expect(flags == [false])
}
