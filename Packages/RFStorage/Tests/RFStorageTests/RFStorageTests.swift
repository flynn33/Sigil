import CryptoKit
import Foundation
import RFCoreModels
import RFSecurity
import Testing
@testable import RFStorage

private struct MockKeyProvider: MasterKeyProviding {
    let key = SymmetricKey(data: Data(repeating: 1, count: 32))

    func obtainMasterKey(requireBiometricGate: Bool) async throws -> SymmetricKey {
        key
    }
}

private final class MockLockProvider: LockConfigurationProviding, @unchecked Sendable {
    var isBiometricLockEnabled: Bool = false
    func setBiometricLockEnabled(_ enabled: Bool) {
        isBiometricLockEnabled = enabled
    }
}

@Test
func repositoryCRUDRoundTrip() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("store.sqlite")

    let encryption = EncryptionService(masterKeyProvider: MockKeyProvider(), lockProvider: MockLockProvider())
    let repository = CoreDataProfileRepository(storeURL: url, encryption: encryption)

    let profile = sampleProfile()
    try await repository.upsert(profile)

    let list = try await repository.listProfiles()
    #expect(list.count == 1)

    let loaded = try await repository.loadProfile(id: profile.id)
    #expect(loaded?.givenName == profile.givenName)

    try await repository.deleteProfile(id: profile.id)
    let empty = try await repository.listProfiles()
    #expect(empty.isEmpty)
}

@Test
func studioPresetCRUDRoundTrip() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("store.sqlite")

    let encryption = EncryptionService(masterKeyProvider: MockKeyProvider(), lockProvider: MockLockProvider())
    let repository = CoreDataProfileRepository(storeURL: url, encryption: encryption)

    let profile = sampleProfile()
    try await repository.upsert(profile)

    let preset = StudioLayerPreset(
        profileID: profile.id,
        name: "Solar Ember",
        isFavorite: true,
        layers: [
            DecorLayer(name: "Background", kind: .background, payload: ["style": "fire", "color": "#f6f4ef"]),
            DecorLayer(name: "Geometry", kind: .geometry, payload: ["color": "#111111", "effect_glow": "0.4"])
        ]
    )

    try await repository.upsertStudioPreset(preset)

    let list = try await repository.listStudioPresets(profileID: profile.id)
    #expect(list.count == 1)
    #expect(list.first?.name == "Solar Ember")
    #expect(list.first?.isFavorite == true)

    let loaded = try await repository.loadStudioPreset(id: preset.id)
    #expect(loaded?.layers.count == 2)
    #expect(loaded?.profileID == profile.id)
    #expect(loaded?.isFavorite == true)

    try await repository.deleteStudioPreset(id: preset.id)
    let empty = try await repository.listStudioPresets(profileID: profile.id)
    #expect(empty.isEmpty)
}

@Test
func deletingProfileRemovesStudioPresets() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("store.sqlite")

    let encryption = EncryptionService(masterKeyProvider: MockKeyProvider(), lockProvider: MockLockProvider())
    let repository = CoreDataProfileRepository(storeURL: url, encryption: encryption)

    let profile = sampleProfile()
    try await repository.upsert(profile)

    let preset = StudioLayerPreset(
        profileID: profile.id,
        name: "Temporary",
        layers: [DecorLayer(name: "Geometry", kind: .geometry)]
    )
    try await repository.upsertStudioPreset(preset)

    try await repository.deleteProfile(id: profile.id)
    let presets = try await repository.listStudioPresets(profileID: profile.id)
    #expect(presets.isEmpty)
}

@Test
func favoritePresetsAreListedFirst() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("store.sqlite")

    let encryption = EncryptionService(masterKeyProvider: MockKeyProvider(), lockProvider: MockLockProvider())
    let repository = CoreDataProfileRepository(storeURL: url, encryption: encryption)

    let profile = sampleProfile()
    try await repository.upsert(profile)

    let recent = Date()
    let older = Date(timeIntervalSinceNow: -3600)

    let presetA = StudioLayerPreset(
        profileID: profile.id,
        name: "Not Favorite",
        isFavorite: false,
        layers: [DecorLayer(name: "A", kind: .geometry)],
        createdAt: older,
        updatedAt: recent
    )

    let presetB = StudioLayerPreset(
        profileID: profile.id,
        name: "Pinned",
        isFavorite: true,
        layers: [DecorLayer(name: "B", kind: .geometry)],
        createdAt: older,
        updatedAt: older
    )

    try await repository.upsertStudioPreset(presetA)
    try await repository.upsertStudioPreset(presetB)

    let list = try await repository.listStudioPresets(profileID: profile.id)
    #expect(list.count == 2)
    #expect(list[0].name == "Pinned")
    #expect(list[0].isFavorite == true)
}

private func sampleProfile() -> PersonProfile {
    let calendar = Calendar(identifier: .gregorian)
    let date = calendar.date(from: DateComponents(year: 1990, month: 7, day: 15, hour: 12, minute: 0))!

    return PersonProfile(
        givenName: "Jane",
        familyName: "Doe",
        birthDetails: BirthDetails(date: date, isTimeUnknown: false),
        birthOrder: 2,
        birthplaceName: "Denver",
        birthplace: GeoPoint(latitude: 39.7392, longitude: -104.9903),
        mother: ParentTraits(birthOrder: 1, hairColor: "Black", eyeColor: "Brown"),
        father: ParentTraits(birthOrder: 3, hairColor: "Brown", eyeColor: "Green"),
        traits: TraitBundle(
            familyNames: ["Doe"],
            heritage: ["Irish"],
            petNames: ["Luna"],
            additionalTraits: ["lucky_number": "7"]
        )
    )
}
