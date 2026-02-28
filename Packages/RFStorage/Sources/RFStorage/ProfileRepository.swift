import CoreData
import Foundation
import RFCoreModels
import RFSecurity

public struct StoredProfileSummary: Hashable, Sendable, Identifiable {
    public var id: UUID
    public var displayName: String
    public var updatedAt: Date

    public init(id: UUID, displayName: String, updatedAt: Date) {
        self.id = id
        self.displayName = displayName
        self.updatedAt = updatedAt
    }
}

public struct StoredStudioPresetSummary: Hashable, Sendable, Identifiable {
    public var id: UUID
    public var profileID: UUID
    public var name: String
    public var isFavorite: Bool
    public var updatedAt: Date

    public init(id: UUID, profileID: UUID, name: String, isFavorite: Bool, updatedAt: Date) {
        self.id = id
        self.profileID = profileID
        self.name = name
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}

public protocol ProfileRepository: Sendable {
    func upsert(_ profile: PersonProfile) async throws
    func listProfiles() async throws -> [StoredProfileSummary]
    func loadProfile(id: UUID) async throws -> PersonProfile?
    func deleteProfile(id: UUID) async throws
}

public protocol StudioPresetRepository: Sendable {
    func upsertStudioPreset(_ preset: StudioLayerPreset) async throws
    func listStudioPresets(profileID: UUID) async throws -> [StoredStudioPresetSummary]
    func loadStudioPreset(id: UUID) async throws -> StudioLayerPreset?
    func deleteStudioPreset(id: UUID) async throws
}

public enum ProfileRepositoryError: Error {
    case profileNotFound
    case invalidPayload
}

public final class CoreDataProfileRepository: @unchecked Sendable, ProfileRepository, StudioPresetRepository {
    private let container: NSPersistentContainer
    private let encryption: EncryptionService

    public init(
        storeURL: URL? = nil,
        encryption: EncryptionService = EncryptionService()
    ) {
        self.container = NSPersistentContainer(name: "SigilStore", managedObjectModel: Self.makeModel())
        self.encryption = encryption

        let description = NSPersistentStoreDescription()
        if let storeURL {
            description.url = storeURL
        }
        #if os(iOS)
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        #endif
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func upsert(_ profile: PersonProfile) async throws {
        let plaintext = try Self.encodePayload(profile)
        let encrypted = try await encryption.encrypt(plaintext)

        try await performBackgroundWrite { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFProfileRecord")
            fetch.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
            fetch.fetchLimit = 1

            let object = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "RFProfileRecord", into: context)
            object.setValue(profile.id, forKey: "id")
            object.setValue(profile.displayName, forKey: "displayName")
            object.setValue(profile.updatedAt, forKey: "updatedAt")
            object.setValue(encrypted, forKey: "encryptedBlob")

            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func listProfiles() async throws -> [StoredProfileSummary] {
        try await performBackgroundRead { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFProfileRecord")
            fetch.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

            return try context.fetch(fetch).compactMap { object in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let displayName = object.value(forKey: "displayName") as? String,
                    let updatedAt = object.value(forKey: "updatedAt") as? Date
                else {
                    return nil
                }
                return StoredProfileSummary(id: id, displayName: displayName, updatedAt: updatedAt)
            }
        }
    }

    public func loadProfile(id: UUID) async throws -> PersonProfile? {
        let encrypted: Data? = try await performBackgroundRead { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFProfileRecord")
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try context.fetch(fetch).first?.value(forKey: "encryptedBlob") as? Data
        }

        guard let encrypted else {
            return nil
        }

        let plaintext = try await encryption.decrypt(encrypted)
        return try Self.decodePayload(PersonProfile.self, from: plaintext)
    }

    public func deleteProfile(id: UUID) async throws {
        try await performBackgroundWrite { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFProfileRecord")
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let object = try context.fetch(fetch).first {
                context.delete(object)
            }

            let presetFetch = NSFetchRequest<NSManagedObject>(entityName: "RFStudioPresetRecord")
            presetFetch.predicate = NSPredicate(format: "profileID == %@", id as CVarArg)
            let presets = try context.fetch(presetFetch)
            presets.forEach(context.delete)

            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func upsertStudioPreset(_ preset: StudioLayerPreset) async throws {
        let plaintext = try Self.encodePayload(preset)
        let encrypted = try await encryption.encrypt(plaintext)

        try await performBackgroundWrite { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFStudioPresetRecord")
            fetch.predicate = NSPredicate(format: "id == %@", preset.id as CVarArg)
            fetch.fetchLimit = 1

            let object = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "RFStudioPresetRecord", into: context)
            object.setValue(preset.id, forKey: "id")
            object.setValue(preset.profileID, forKey: "profileID")
            object.setValue(preset.name, forKey: "name")
            object.setValue(preset.isFavorite, forKey: "isFavorite")
            object.setValue(preset.createdAt, forKey: "createdAt")
            object.setValue(preset.updatedAt, forKey: "updatedAt")
            object.setValue(encrypted, forKey: "encryptedBlob")

            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func listStudioPresets(profileID: UUID) async throws -> [StoredStudioPresetSummary] {
        try await performBackgroundRead { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFStudioPresetRecord")
            fetch.predicate = NSPredicate(format: "profileID == %@", profileID as CVarArg)
            fetch.sortDescriptors = [
                NSSortDescriptor(key: "isFavorite", ascending: false),
                NSSortDescriptor(key: "updatedAt", ascending: false)
            ]

            return try context.fetch(fetch).compactMap { object in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let profileID = object.value(forKey: "profileID") as? UUID,
                    let name = object.value(forKey: "name") as? String,
                    let updatedAt = object.value(forKey: "updatedAt") as? Date
                else {
                    return nil
                }
                let isFavorite = object.value(forKey: "isFavorite") as? Bool ?? false
                return StoredStudioPresetSummary(id: id, profileID: profileID, name: name, isFavorite: isFavorite, updatedAt: updatedAt)
            }
        }
    }

    public func loadStudioPreset(id: UUID) async throws -> StudioLayerPreset? {
        let encrypted: Data? = try await performBackgroundRead { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFStudioPresetRecord")
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try context.fetch(fetch).first?.value(forKey: "encryptedBlob") as? Data
        }

        guard let encrypted else {
            return nil
        }

        let plaintext = try await encryption.decrypt(encrypted)
        return try Self.decodePayload(StudioLayerPreset.self, from: plaintext)
    }

    public func deleteStudioPreset(id: UUID) async throws {
        try await performBackgroundWrite { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "RFStudioPresetRecord")
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let object = try context.fetch(fetch).first {
                context.delete(object)
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func performBackgroundRead<T>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performBackgroundWrite(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    try block(context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func encodePayload<T: Encodable>(_ value: T) throws -> Data {
        // Binary plist avoids JSONEncoder crashes seen under SwiftPM test helper.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(value)
    }

    private static func decodePayload<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let plistDecoder = PropertyListDecoder()
        if let value = try? plistDecoder.decode(T.self, from: data) {
            return value
        }

        // Backward compatibility for payloads written with earlier JSON storage format.
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(T.self, from: data)
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let profileEntity = NSEntityDescription()
        profileEntity.name = "RFProfileRecord"
        profileEntity.managedObjectClassName = "NSManagedObject"

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let displayNameAttribute = NSAttributeDescription()
        displayNameAttribute.name = "displayName"
        displayNameAttribute.attributeType = .stringAttributeType
        displayNameAttribute.isOptional = false

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = false

        let encryptedBlobAttribute = NSAttributeDescription()
        encryptedBlobAttribute.name = "encryptedBlob"
        encryptedBlobAttribute.attributeType = .binaryDataAttributeType
        encryptedBlobAttribute.isOptional = false
        encryptedBlobAttribute.allowsExternalBinaryDataStorage = true

        profileEntity.properties = [idAttribute, displayNameAttribute, updatedAtAttribute, encryptedBlobAttribute]

        let presetEntity = NSEntityDescription()
        presetEntity.name = "RFStudioPresetRecord"
        presetEntity.managedObjectClassName = "NSManagedObject"

        let presetID = NSAttributeDescription()
        presetID.name = "id"
        presetID.attributeType = .UUIDAttributeType
        presetID.isOptional = false

        let presetProfileID = NSAttributeDescription()
        presetProfileID.name = "profileID"
        presetProfileID.attributeType = .UUIDAttributeType
        presetProfileID.isOptional = false

        let presetName = NSAttributeDescription()
        presetName.name = "name"
        presetName.attributeType = .stringAttributeType
        presetName.isOptional = false

        let presetCreatedAt = NSAttributeDescription()
        presetCreatedAt.name = "createdAt"
        presetCreatedAt.attributeType = .dateAttributeType
        presetCreatedAt.isOptional = false

        let presetIsFavorite = NSAttributeDescription()
        presetIsFavorite.name = "isFavorite"
        presetIsFavorite.attributeType = .booleanAttributeType
        presetIsFavorite.isOptional = true

        let presetUpdatedAt = NSAttributeDescription()
        presetUpdatedAt.name = "updatedAt"
        presetUpdatedAt.attributeType = .dateAttributeType
        presetUpdatedAt.isOptional = false

        let presetEncryptedBlob = NSAttributeDescription()
        presetEncryptedBlob.name = "encryptedBlob"
        presetEncryptedBlob.attributeType = .binaryDataAttributeType
        presetEncryptedBlob.isOptional = false
        presetEncryptedBlob.allowsExternalBinaryDataStorage = true

        presetEntity.properties = [
            presetID,
            presetProfileID,
            presetName,
            presetIsFavorite,
            presetCreatedAt,
            presetUpdatedAt,
            presetEncryptedBlob
        ]

        model.entities = [profileEntity, presetEntity]
        return model
    }
}
