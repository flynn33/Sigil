import Foundation
import CoreGraphics

public enum RFConstants {
    public static let pipelineVersion = "wrw_personal_sigil_v1"
    public static let geometrySchemaVersion = "rf.geometry.v1"
    public static let engineDataVersion = "yggdrasil.snapshot.2026-02-11"
}

public struct GeoPoint: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct ParentTraits: Codable, Hashable, Sendable {
    public var birthOrder: Int
    public var birthOrderTotal: Int?
    public var hairColor: String
    public var eyeColor: String

    public init(birthOrder: Int, hairColor: String, eyeColor: String) {
        self.birthOrder = birthOrder
        self.birthOrderTotal = nil
        self.hairColor = hairColor
        self.eyeColor = eyeColor
    }

    public init(
        birthOrder: Int,
        birthOrderTotal: Int?,
        hairColor: String,
        eyeColor: String
    ) {
        self.birthOrder = birthOrder
        self.birthOrderTotal = birthOrderTotal
        self.hairColor = hairColor
        self.eyeColor = eyeColor
    }

    enum CodingKeys: String, CodingKey {
        case birthOrder
        case birthOrderTotal
        case hairColor
        case eyeColor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        birthOrder = try container.decode(Int.self, forKey: .birthOrder)
        birthOrderTotal = try container.decodeIfPresent(Int.self, forKey: .birthOrderTotal)
        hairColor = try container.decode(String.self, forKey: .hairColor)
        eyeColor = try container.decode(String.self, forKey: .eyeColor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(birthOrder, forKey: .birthOrder)
        try container.encodeIfPresent(birthOrderTotal, forKey: .birthOrderTotal)
        try container.encode(hairColor, forKey: .hairColor)
        try container.encode(eyeColor, forKey: .eyeColor)
    }
}

public struct BirthDetails: Codable, Hashable, Sendable {
    public var date: Date
    public var isTimeUnknown: Bool

    public init(date: Date, isTimeUnknown: Bool) {
        self.date = date
        self.isTimeUnknown = isTimeUnknown
    }
}

public enum DynamicFieldType: String, Codable, Hashable, Sendable, CaseIterable {
    case text
    case number
    case date
    case boolean
    case singleChoice
    case multiChoice

    public var displayName: String {
        switch self {
        case .text:
            "Text"
        case .number:
            "Number"
        case .date:
            "Date"
        case .boolean:
            "Boolean"
        case .singleChoice:
            "Single Choice"
        case .multiChoice:
            "Multi Choice"
        }
    }

    public var allowsOptions: Bool {
        self == .singleChoice || self == .multiChoice
    }
}

public struct DynamicFieldDefinition: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var key: String
    public var label: String
    public var section: String
    public var type: DynamicFieldType
    public var isRequired: Bool
    public var options: [String]

    public init(
        id: UUID = UUID(),
        key: String,
        label: String,
        section: String = "Custom",
        type: DynamicFieldType = .text,
        isRequired: Bool = false,
        options: [String] = []
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.section = section
        self.type = type
        self.isRequired = isRequired
        self.options = options
    }
}

public struct ProfessionEntry: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var profession: String
    public var titleOrPosition: String
    public var yearsInProfession: Int
    public var customItemLabel: String
    public var customItemValue: String

    public init(
        id: UUID = UUID(),
        profession: String,
        titleOrPosition: String,
        yearsInProfession: Int,
        customItemLabel: String = "",
        customItemValue: String = ""
    ) {
        self.id = id
        self.profession = profession
        self.titleOrPosition = titleOrPosition
        self.yearsInProfession = yearsInProfession
        self.customItemLabel = customItemLabel
        self.customItemValue = customItemValue
    }
}

public struct TraitBundle: Codable, Hashable, Sendable {
    public var familyNames: [String]
    public var heritage: [String]
    public var petNames: [String]
    public var professions: [ProfessionEntry]
    public var hobbiesInterests: [String]
    public var additionalTraits: [String: String]
    public var dynamicFields: [DynamicFieldDefinition]
    public var dynamicFieldValues: [String: String]

    public init(
        familyNames: [String] = [],
        heritage: [String] = [],
        petNames: [String] = [],
        professions: [ProfessionEntry] = [],
        hobbiesInterests: [String] = [],
        additionalTraits: [String: String] = [:],
        dynamicFields: [DynamicFieldDefinition] = [],
        dynamicFieldValues: [String: String] = [:]
    ) {
        self.familyNames = familyNames
        self.heritage = heritage
        self.petNames = petNames
        self.professions = professions
        self.hobbiesInterests = hobbiesInterests
        self.additionalTraits = additionalTraits
        self.dynamicFields = dynamicFields
        self.dynamicFieldValues = dynamicFieldValues
    }

    public init(
        familyNames: [String] = [],
        heritage: [String] = [],
        petNames: [String] = [],
        additionalTraits: [String: String] = [:],
        dynamicFields: [DynamicFieldDefinition] = [],
        dynamicFieldValues: [String: String] = [:]
    ) {
        self.init(
            familyNames: familyNames,
            heritage: heritage,
            petNames: petNames,
            professions: [],
            hobbiesInterests: [],
            additionalTraits: additionalTraits,
            dynamicFields: dynamicFields,
            dynamicFieldValues: dynamicFieldValues
        )
    }

    enum CodingKeys: String, CodingKey {
        case familyNames
        case heritage
        case petNames
        case professions
        case hobbiesInterests
        case hobbies // legacy alias support
        case additionalTraits
        case dynamicFields
        case dynamicFieldValues
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        familyNames = try container.decodeIfPresent([String].self, forKey: .familyNames) ?? []
        heritage = try container.decodeIfPresent([String].self, forKey: .heritage) ?? []
        petNames = try container.decodeIfPresent([String].self, forKey: .petNames) ?? []
        professions = try container.decodeIfPresent([ProfessionEntry].self, forKey: .professions) ?? []
        hobbiesInterests = try container.decodeIfPresent([String].self, forKey: .hobbiesInterests)
            ?? container.decodeIfPresent([String].self, forKey: .hobbies)
            ?? []
        additionalTraits = try container.decodeIfPresent([String: String].self, forKey: .additionalTraits) ?? [:]
        dynamicFields = try container.decodeIfPresent([DynamicFieldDefinition].self, forKey: .dynamicFields) ?? []
        dynamicFieldValues = try container.decodeIfPresent([String: String].self, forKey: .dynamicFieldValues) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(familyNames, forKey: .familyNames)
        try container.encode(heritage, forKey: .heritage)
        try container.encode(petNames, forKey: .petNames)
        try container.encode(professions, forKey: .professions)
        try container.encode(hobbiesInterests, forKey: .hobbiesInterests)
        try container.encode(additionalTraits, forKey: .additionalTraits)
        try container.encode(dynamicFields, forKey: .dynamicFields)
        try container.encode(dynamicFieldValues, forKey: .dynamicFieldValues)
    }
}

public struct PersonProfile: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var givenName: String
    public var familyName: String
    public var birthDetails: BirthDetails
    public var birthOrder: Int
    public var birthOrderTotal: Int?
    public var birthplaceName: String
    public var birthplace: GeoPoint
    public var mother: ParentTraits
    public var father: ParentTraits
    public var traits: TraitBundle
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        givenName: String,
        familyName: String,
        birthDetails: BirthDetails,
        birthOrder: Int,
        birthplaceName: String,
        birthplace: GeoPoint,
        mother: ParentTraits,
        father: ParentTraits,
        traits: TraitBundle,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.birthDetails = birthDetails
        self.birthOrder = birthOrder
        self.birthOrderTotal = nil
        self.birthplaceName = birthplaceName
        self.birthplace = birthplace
        self.mother = mother
        self.father = father
        self.traits = traits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(
        id: UUID = UUID(),
        givenName: String,
        familyName: String,
        birthDetails: BirthDetails,
        birthOrder: Int,
        birthOrderTotal: Int?,
        birthplaceName: String,
        birthplace: GeoPoint,
        mother: ParentTraits,
        father: ParentTraits,
        traits: TraitBundle,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.birthDetails = birthDetails
        self.birthOrder = birthOrder
        self.birthOrderTotal = birthOrderTotal
        self.birthplaceName = birthplaceName
        self.birthplace = birthplace
        self.mother = mother
        self.father = father
        self.traits = traits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case givenName
        case familyName
        case birthDetails
        case birthOrder
        case birthOrderTotal
        case birthplaceName
        case birthplace
        case mother
        case father
        case traits
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        givenName = try container.decode(String.self, forKey: .givenName)
        familyName = try container.decode(String.self, forKey: .familyName)
        birthDetails = try container.decode(BirthDetails.self, forKey: .birthDetails)
        birthOrder = try container.decode(Int.self, forKey: .birthOrder)
        birthOrderTotal = try container.decodeIfPresent(Int.self, forKey: .birthOrderTotal)
        birthplaceName = try container.decode(String.self, forKey: .birthplaceName)
        birthplace = try container.decode(GeoPoint.self, forKey: .birthplace)
        mother = try container.decode(ParentTraits.self, forKey: .mother)
        father = try container.decode(ParentTraits.self, forKey: .father)
        traits = try container.decode(TraitBundle.self, forKey: .traits)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(givenName, forKey: .givenName)
        try container.encode(familyName, forKey: .familyName)
        try container.encode(birthDetails, forKey: .birthDetails)
        try container.encode(birthOrder, forKey: .birthOrder)
        try container.encodeIfPresent(birthOrderTotal, forKey: .birthOrderTotal)
        try container.encode(birthplaceName, forKey: .birthplaceName)
        try container.encode(birthplace, forKey: .birthplace)
        try container.encode(mother, forKey: .mother)
        try container.encode(father, forKey: .father)
        try container.encode(traits, forKey: .traits)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct CanonicalVector: Codable, Hashable, Sendable {
    public var H_entropy: Double
    public var K_complexity: Double
    public var D_fractal_dim: Double
    public var S_symmetry: Double
    public var L_generator_length: Int

    public init(H_entropy: Double, K_complexity: Double, D_fractal_dim: Double, S_symmetry: Double, L_generator_length: Int) {
        self.H_entropy = H_entropy
        self.K_complexity = K_complexity
        self.D_fractal_dim = D_fractal_dim
        self.S_symmetry = S_symmetry
        self.L_generator_length = L_generator_length
    }
}

public enum SigilParity: String, Codable, Hashable, Sendable {
    case even
    case odd
}

public struct SigilBits9: Codable, Hashable, Sendable {
    public var bits: String
    public var parity: SigilParity

    public init(bits: String, parity: SigilParity) {
        self.bits = bits
        self.parity = parity
    }
}

public struct LSystemDefinition: Codable, Hashable, Sendable {
    public var axiom: String
    public var rules: [String: String]
    public var angle: Double
    public var iterations: Int

    public init(axiom: String, rules: [String: String], angle: Double, iterations: Int) {
        self.axiom = axiom
        self.rules = rules
        self.angle = angle
        self.iterations = iterations
    }
}

public struct SigilLine: Codable, Hashable, Sendable {
    public var startX: Double
    public var startY: Double
    public var endX: Double
    public var endY: Double

    public init(startX: Double, startY: Double, endX: Double, endY: Double) {
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
    }
}

public struct SigilGeometry: Codable, Hashable, Sendable {
    public var lines: [SigilLine]

    public init(lines: [SigilLine]) {
        self.lines = lines
    }
}

public enum DecorLayerKind: String, Codable, Hashable, Sendable {
    case geometry
    case background
    case symbolOverlay
}

public struct DecorLayer: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var kind: DecorLayerKind
    public var opacity: Double
    public var rotationDegrees: Double
    public var scale: Double
    public var offsetX: Double
    public var offsetY: Double
    public var payload: [String: String]

    public init(
        id: UUID = UUID(),
        name: String,
        kind: DecorLayerKind,
        opacity: Double = 1,
        rotationDegrees: Double = 0,
        scale: Double = 1,
        offsetX: Double = 0,
        offsetY: Double = 0,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.opacity = opacity
        self.rotationDegrees = rotationDegrees
        self.scale = scale
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.payload = payload
    }
}

public struct StudioLayerPreset: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var profileID: UUID
    public var name: String
    public var isFavorite: Bool
    public var layers: [DecorLayer]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        profileID: UUID,
        name: String,
        isFavorite: Bool = false,
        layers: [DecorLayer],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.profileID = profileID
        self.name = name
        self.isFavorite = isFavorite
        self.layers = layers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case profileID
        case name
        case isFavorite
        case layers
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        profileID = try container.decode(UUID.self, forKey: .profileID)
        name = try container.decode(String.self, forKey: .name)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        layers = try container.decodeIfPresent([DecorLayer].self, forKey: .layers) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(profileID, forKey: .profileID)
        try container.encode(name, forKey: .name)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(layers, forKey: .layers)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct MeaningNarrative: Codable, Hashable, Sendable {
    public var title: String
    public var celestialName: String
    public var summary: String
    public var sections: [String]

    public init(title: String, celestialName: String, summary: String, sections: [String]) {
        self.title = title
        self.celestialName = celestialName
        self.summary = summary
        self.sections = sections
    }
}

public struct CodexSigilParameters: Codable, Hashable, Sendable {
    public var polygonSides: Int
    public var radialLayers: Int
    public var symmetryOrder: Int
    public var distortionFactor: Double
    public var wolfOverlayType: String

    public init(
        polygonSides: Int,
        radialLayers: Int,
        symmetryOrder: Int,
        distortionFactor: Double,
        wolfOverlayType: String
    ) {
        self.polygonSides = polygonSides
        self.radialLayers = radialLayers
        self.symmetryOrder = symmetryOrder
        self.distortionFactor = distortionFactor
        self.wolfOverlayType = wolfOverlayType
    }
}

public struct CodexInsights: Codable, Hashable, Sendable {
    public var lifePathNumber: Int
    public var dominantPlaneCode: String
    public var wolfAlignment: String
    public var luciferianPublicDescription: String
    public var luciferianPrivateFlag: Bool
    public var branchingReflectionText: String
    public var sigilParameters: CodexSigilParameters

    public init(
        lifePathNumber: Int,
        dominantPlaneCode: String,
        wolfAlignment: String,
        luciferianPublicDescription: String,
        luciferianPrivateFlag: Bool,
        branchingReflectionText: String,
        sigilParameters: CodexSigilParameters
    ) {
        self.lifePathNumber = lifePathNumber
        self.dominantPlaneCode = dominantPlaneCode
        self.wolfAlignment = wolfAlignment
        self.luciferianPublicDescription = luciferianPublicDescription
        self.luciferianPrivateFlag = luciferianPrivateFlag
        self.branchingReflectionText = branchingReflectionText
        self.sigilParameters = sigilParameters
    }
}

public struct SigilResult: Codable, Hashable, Sendable {
    public var profileID: UUID
    public var vector: CanonicalVector
    public var bits9: SigilBits9
    public var celestialName: String
    public var lsystem: LSystemDefinition
    public var geometry: SigilGeometry
    public var geometryHash: String
    public var pipelineVersion: String
    public var engineDataVersion: String
    public var codexInsights: CodexInsights?

    public init(
        profileID: UUID,
        vector: CanonicalVector,
        bits9: SigilBits9,
        celestialName: String,
        lsystem: LSystemDefinition,
        geometry: SigilGeometry,
        geometryHash: String,
        pipelineVersion: String,
        engineDataVersion: String,
        codexInsights: CodexInsights?
    ) {
        self.profileID = profileID
        self.vector = vector
        self.bits9 = bits9
        self.celestialName = celestialName
        self.lsystem = lsystem
        self.geometry = geometry
        self.geometryHash = geometryHash
        self.pipelineVersion = pipelineVersion
        self.engineDataVersion = engineDataVersion
        self.codexInsights = codexInsights
    }

    public init(
        profileID: UUID,
        vector: CanonicalVector,
        bits9: SigilBits9,
        celestialName: String,
        lsystem: LSystemDefinition,
        geometry: SigilGeometry,
        geometryHash: String,
        pipelineVersion: String,
        engineDataVersion: String
    ) {
        self.init(
            profileID: profileID,
            vector: vector,
            bits9: bits9,
            celestialName: celestialName,
            lsystem: lsystem,
            geometry: geometry,
            geometryHash: geometryHash,
            pipelineVersion: pipelineVersion,
            engineDataVersion: engineDataVersion,
            codexInsights: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case profileID
        case vector
        case bits9
        case celestialName
        case lsystem
        case geometry
        case geometryHash
        case pipelineVersion
        case engineDataVersion
        case codexInsights
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileID = try container.decode(UUID.self, forKey: .profileID)
        vector = try container.decode(CanonicalVector.self, forKey: .vector)
        bits9 = try container.decode(SigilBits9.self, forKey: .bits9)
        celestialName = try container.decode(String.self, forKey: .celestialName)
        lsystem = try container.decode(LSystemDefinition.self, forKey: .lsystem)
        geometry = try container.decode(SigilGeometry.self, forKey: .geometry)
        geometryHash = try container.decodeIfPresent(String.self, forKey: .geometryHash) ?? ""
        pipelineVersion = try container.decodeIfPresent(String.self, forKey: .pipelineVersion) ?? RFConstants.pipelineVersion
        engineDataVersion = try container.decodeIfPresent(String.self, forKey: .engineDataVersion) ?? RFConstants.engineDataVersion
        codexInsights = try container.decodeIfPresent(CodexInsights.self, forKey: .codexInsights)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profileID, forKey: .profileID)
        try container.encode(vector, forKey: .vector)
        try container.encode(bits9, forKey: .bits9)
        try container.encode(celestialName, forKey: .celestialName)
        try container.encode(lsystem, forKey: .lsystem)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(geometryHash, forKey: .geometryHash)
        try container.encode(pipelineVersion, forKey: .pipelineVersion)
        try container.encode(engineDataVersion, forKey: .engineDataVersion)
        try container.encodeIfPresent(codexInsights, forKey: .codexInsights)
    }
}

public struct SigilOptions: Codable, Hashable, Sendable {
    public var includeTraitExtensions: Bool

    public init(includeTraitExtensions: Bool = false) {
        self.includeTraitExtensions = includeTraitExtensions
    }
}

public struct PlaceCandidate: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var location: GeoPoint

    public init(id: UUID = UUID(), title: String, subtitle: String, location: GeoPoint) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.location = location
    }
}

public struct GeometryExportEnvelope: Codable, Hashable, Sendable {
    public var schemaVersion: String
    public var engineDataVersion: String
    public var pipelineVersion: String
    public var vector: CanonicalVector
    public var bits9: SigilBits9
    public var parity: SigilParity
    public var lsystem: LSystemDefinition
    public var geometry: SigilGeometry

    public init(
        schemaVersion: String,
        engineDataVersion: String,
        pipelineVersion: String,
        vector: CanonicalVector,
        bits9: SigilBits9,
        parity: SigilParity,
        lsystem: LSystemDefinition,
        geometry: SigilGeometry
    ) {
        self.schemaVersion = schemaVersion
        self.engineDataVersion = engineDataVersion
        self.pipelineVersion = pipelineVersion
        self.vector = vector
        self.bits9 = bits9
        self.parity = parity
        self.lsystem = lsystem
        self.geometry = geometry
    }
}

public enum ImageExportFormat: String, Codable, Sendable {
    case png
    case jpeg
}

public enum ExportProfilePreset: String, Codable, Hashable, Sendable, CaseIterable {
    case standard
    case social
    case print
    case gameAsset
    case custom

    public var displayName: String {
        switch self {
        case .standard:
            "Standard"
        case .social:
            "Social"
        case .print:
            "Print"
        case .gameAsset:
            "Game Asset"
        case .custom:
            "Custom"
        }
    }
}

public enum ExportMetadataMode: String, Codable, Hashable, Sendable, CaseIterable {
    case none
    case sidecarJSON
}

public struct ImageExportSettings: Codable, Hashable, Sendable {
    public var width: Int
    public var height: Int
    public var jpegQuality: Double
    public var preset: ExportProfilePreset
    public var metadataMode: ExportMetadataMode
    public var backgroundHexOverride: String?

    public init(
        width: Int = 2048,
        height: Int = 2048,
        jpegQuality: Double = 0.95,
        preset: ExportProfilePreset = .standard,
        metadataMode: ExportMetadataMode = .none,
        backgroundHexOverride: String? = nil
    ) {
        self.width = width
        self.height = height
        self.jpegQuality = jpegQuality
        self.preset = preset
        self.metadataMode = metadataMode
        self.backgroundHexOverride = backgroundHexOverride
    }

    public static func settings(for preset: ExportProfilePreset) -> ImageExportSettings {
        switch preset {
        case .standard:
            ImageExportSettings(width: 2048, height: 2048, jpegQuality: 0.95, preset: .standard)
        case .social:
            ImageExportSettings(width: 1080, height: 1080, jpegQuality: 0.9, preset: .social)
        case .print:
            ImageExportSettings(width: 4096, height: 4096, jpegQuality: 1.0, preset: .print)
        case .gameAsset:
            ImageExportSettings(width: 2048, height: 2048, jpegQuality: 0.95, preset: .gameAsset)
        case .custom:
            ImageExportSettings(width: 2048, height: 2048, jpegQuality: 0.95, preset: .custom)
        }
    }

    public func normalized() -> ImageExportSettings {
        ImageExportSettings(
            width: width.clamped(to: 128...8192),
            height: height.clamped(to: 128...8192),
            jpegQuality: jpegQuality.clamped(to: 0.1...1),
            preset: preset,
            metadataMode: metadataMode,
            backgroundHexOverride: backgroundHexOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    enum CodingKeys: String, CodingKey {
        case width
        case height
        case jpegQuality
        case preset
        case metadataMode
        case backgroundHexOverride
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 2048
        height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 2048
        jpegQuality = try container.decodeIfPresent(Double.self, forKey: .jpegQuality) ?? 0.95
        preset = try container.decodeIfPresent(ExportProfilePreset.self, forKey: .preset) ?? .standard
        metadataMode = try container.decodeIfPresent(ExportMetadataMode.self, forKey: .metadataMode) ?? .none
        backgroundHexOverride = try container.decodeIfPresent(String.self, forKey: .backgroundHexOverride)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(jpegQuality, forKey: .jpegQuality)
        try container.encode(preset, forKey: .preset)
        try container.encode(metadataMode, forKey: .metadataMode)
        try container.encode(backgroundHexOverride, forKey: .backgroundHexOverride)
    }
}

public struct ExportMetadataManifest: Codable, Hashable, Sendable {
    public var profileID: UUID
    public var geometryHash: String
    public var pipelineVersion: String
    public var engineDataVersion: String
    public var exportFormat: ImageExportFormat
    public var settings: ImageExportSettings
    public var exportedAt: Date

    public init(
        profileID: UUID,
        geometryHash: String,
        pipelineVersion: String,
        engineDataVersion: String,
        exportFormat: ImageExportFormat,
        settings: ImageExportSettings,
        exportedAt: Date = .now
    ) {
        self.profileID = profileID
        self.geometryHash = geometryHash
        self.pipelineVersion = pipelineVersion
        self.engineDataVersion = engineDataVersion
        self.exportFormat = exportFormat
        self.settings = settings
        self.exportedAt = exportedAt
    }
}

public extension PersonProfile {
    var displayName: String { "\(givenName) \(familyName)" }

    func derivedBirthWeekday(calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
        let weekday = calendar.component(.weekday, from: birthDetails.date)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.weekdaySymbols[(weekday - 1).clamped(to: 0...6)]
    }
}

public extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

public extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

public extension CanonicalVector {
    func canonicalSerialized() -> String {
        let h = String(format: "%.6f", H_entropy)
        let k = String(format: "%.6f", K_complexity)
        let d = String(format: "%.6f", D_fractal_dim)
        let s = String(format: "%.6f", S_symmetry)
        return "H:\(h);K:\(k);D:\(d);S:\(s);L:\(L_generator_length);"
    }
}

public struct LoreEntity: Codable, Hashable, Sendable {
    public struct PatternVector: Codable, Hashable, Sendable {
        public var H_entropy: Double
        public var K_complexity: Double
        public var D_fractal_dim: Double
        public var S_symmetry: Double
        public var L_generator_length: Int

        public init(H_entropy: Double, K_complexity: Double, D_fractal_dim: Double, S_symmetry: Double, L_generator_length: Int) {
            self.H_entropy = H_entropy
            self.K_complexity = K_complexity
            self.D_fractal_dim = D_fractal_dim
            self.S_symmetry = S_symmetry
            self.L_generator_length = L_generator_length
        }
    }

    public var id: String
    public var name: String
    public var vector: PatternVector
    public var primaryPlane: Int
    public var notes: String

    public init(id: String, name: String, vector: PatternVector, primaryPlane: Int, notes: String) {
        self.id = id
        self.name = name
        self.vector = vector
        self.primaryPlane = primaryPlane
        self.notes = notes
    }
}

public struct RuneDescriptor: Codable, Hashable, Sendable {
    public var id: String
    public var character: String
    public var name: String
    public var bits: String
    public var parity: String
    public var wolf: String
    public var meaning: String

    public init(id: String, character: String, name: String, bits: String, parity: String, wolf: String, meaning: String) {
        self.id = id
        self.character = character
        self.name = name
        self.bits = bits
        self.parity = parity
        self.wolf = wolf
        self.meaning = meaning
    }
}

public struct PlaneCodex: Codable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var key: String
    public var name: String
    public var planeType: String
    public var role: String
    public var physics: [String]
    public var storyMapping: [String]

    public init(
        id: Int,
        key: String,
        name: String,
        planeType: String,
        role: String,
        physics: [String],
        storyMapping: [String]
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.planeType = planeType
        self.role = role
        self.physics = physics
        self.storyMapping = storyMapping
    }
}

public struct AxiomCodex: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var summary: String
    public var formal: String
    public var storyImplications: [String]

    public init(
        id: String,
        name: String,
        summary: String,
        formal: String,
        storyImplications: [String]
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.formal = formal
        self.storyImplications = storyImplications
    }
}

public struct MythicPrinciple: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var description: String
    public var planeRefs: [String]
    public var statements: [String]

    public init(id: String, description: String, planeRefs: [String], statements: [String]) {
        self.id = id
        self.description = description
        self.planeRefs = planeRefs
        self.statements = statements
    }
}

public struct LoreDataset: Codable, Hashable, Sendable {
    public var canonicalEntities: [LoreEntity]
    public var runes: [RuneDescriptor]
    public var planes: [PlaneCodex]
    public var axioms: [AxiomCodex]
    public var mythicPrinciples: [MythicPrinciple]

    public init(
        canonicalEntities: [LoreEntity],
        runes: [RuneDescriptor],
        planes: [PlaneCodex] = [],
        axioms: [AxiomCodex] = [],
        mythicPrinciples: [MythicPrinciple] = []
    ) {
        self.canonicalEntities = canonicalEntities
        self.runes = runes
        self.planes = planes
        self.axioms = axioms
        self.mythicPrinciples = mythicPrinciples
    }

    enum CodingKeys: String, CodingKey {
        case canonicalEntities
        case runes
        case planes
        case axioms
        case mythicPrinciples
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canonicalEntities = try container.decode([LoreEntity].self, forKey: .canonicalEntities)
        runes = try container.decode([RuneDescriptor].self, forKey: .runes)
        planes = try container.decodeIfPresent([PlaneCodex].self, forKey: .planes) ?? []
        axioms = try container.decodeIfPresent([AxiomCodex].self, forKey: .axioms) ?? []
        mythicPrinciples = try container.decodeIfPresent([MythicPrinciple].self, forKey: .mythicPrinciples) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(canonicalEntities, forKey: .canonicalEntities)
        try container.encode(runes, forKey: .runes)
        try container.encode(planes, forKey: .planes)
        try container.encode(axioms, forKey: .axioms)
        try container.encode(mythicPrinciples, forKey: .mythicPrinciples)
    }
}

public struct MythosSymbol: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var packID: String
    public var svgPath: String

    public init(id: String, name: String, packID: String, svgPath: String) {
        self.id = id
        self.name = name
        self.packID = packID
        self.svgPath = svgPath
    }
}

public struct MythosPack: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var symbols: [MythosSymbol]

    public init(id: String, title: String, symbols: [MythosSymbol]) {
        self.id = id
        self.title = title
        self.symbols = symbols
    }
}
