import Foundation
import RFSigilCoreModels

public struct SigilProfileInput: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let birthDate: String
    public let birthTime: String
    public let birthCity: String
    public let birthOrder: String
    public let eyes: String
    public let hair: String
    public let heritage: [String]
    // Package 02 canonical additions (defaulted so retained inputs and existing
    // fixtures remain source-compatible). firstName/lastName are separate
    // canonical fields (§5.2); when absent they are derived from `name` in the
    // owning boundary. These are canonical user-confirmed data, not UI drafts.
    public let firstName: String?
    public let lastName: String?
    public let birthWeekday: String?
    public let parentalOrder: [SigilParentalBirthOrder]
    public let ancestralSurnames: [String]

    public init(
        id: String,
        name: String,
        birthDate: String,
        birthTime: String,
        birthCity: String,
        birthOrder: String,
        eyes: String,
        hair: String,
        heritage: [String],
        firstName: String? = nil,
        lastName: String? = nil,
        birthWeekday: String? = nil,
        parentalOrder: [SigilParentalBirthOrder] = [],
        ancestralSurnames: [String] = []
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthCity = birthCity
        self.birthOrder = birthOrder
        self.eyes = eyes
        self.hair = hair
        self.heritage = heritage
        self.firstName = firstName
        self.lastName = lastName
        self.birthWeekday = birthWeekday
        self.parentalOrder = parentalOrder
        self.ancestralSurnames = ancestralSurnames
    }
}

public struct NumerologyVector: Codable, Equatable, Hashable, Sendable {
    public let lifePathRoot: Int
    public let preservedMasterNumbers: [Int]
    public let birthDayRoot: Int
    public let expressionDestinyRoot: Int
    public let soulUrgeRoot: Int
    public let personalityRoot: Int
    public let birthOrderOrdinal: Int
    public let birthOrderTotal: Int
    // Package 02 provenance: derived civil-calendar weekday (1=Mon...7=Sun) and
    // the intermediate reduction chains so each root is explainable.
    public let weekday: Int
    public let reductionProvenance: [String: [Int]]

    public init(
        lifePathRoot: Int,
        preservedMasterNumbers: [Int],
        birthDayRoot: Int,
        expressionDestinyRoot: Int,
        soulUrgeRoot: Int,
        personalityRoot: Int,
        birthOrderOrdinal: Int,
        birthOrderTotal: Int,
        weekday: Int = 0,
        reductionProvenance: [String: [Int]] = [:]
    ) {
        self.lifePathRoot = lifePathRoot
        self.preservedMasterNumbers = preservedMasterNumbers
        self.birthDayRoot = birthDayRoot
        self.expressionDestinyRoot = expressionDestinyRoot
        self.soulUrgeRoot = soulUrgeRoot
        self.personalityRoot = personalityRoot
        self.birthOrderOrdinal = birthOrderOrdinal
        self.birthOrderTotal = birthOrderTotal
        self.weekday = weekday
        self.reductionProvenance = reductionProvenance
    }
}

public struct WolfBalance: Codable, Equatable, Hashable, Sendable {
    public let whiteWeight: Double
    public let darkWeight: Double
    public let category: String

    public init(whiteWeight: Double, darkWeight: Double, category: String) {
        self.whiteWeight = whiteWeight
        self.darkWeight = darkWeight
        self.category = category
    }
}

public struct AncestryWeight: Codable, Equatable, Hashable, Sendable {
    public let family: String
    public let weight: Double

    public init(family: String, weight: Double) {
        self.family = family
        self.weight = weight
    }
}

public struct CelestialClassBasis: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let source: String

    public init(id: String, source: String) {
        self.id = id
        self.source = source
    }
}

public struct SigilAnchorPoint: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let x: Double
    public let y: Double
    public let semanticRole: String

    public init(id: String, x: Double, y: Double, semanticRole: String) {
        self.id = id
        self.x = x
        self.y = y
        self.semanticRole = semanticRole
    }
}

public struct SigilGeometryEdge: Codable, Equatable, Hashable, Sendable {
    public let from: String
    public let to: String
    public let role: String

    public init(from: String, to: String, role: String) {
        self.from = from
        self.to = to
        self.role = role
    }
}

public struct HiddenCanonicalGeometry: Codable, Equatable, Hashable, Sendable {
    public let schemaVersion: String
    public let algorithmIdentity: String
    public let profileHash: String
    public let numerologyVector: NumerologyVector
    public let ashState: SigilAshStateRecord
    public let planeAttunementVector: [Double]
    public let wolfBalance: WolfBalance
    public let ancestryWeights: [AncestryWeight]
    public let celestialClassBasis: CelestialClassBasis
    public let anchorPoints: [SigilAnchorPoint]
    public let edges: [SigilGeometryEdge]
    public let semanticRoles: [String: String]
    public let canonicalGeometryDigest: String

    public init(
        schemaVersion: String = "rf.hidden_geometry.v1",
        algorithmIdentity: String = "sigil-identity-pipeline.v1",
        profileHash: String,
        numerologyVector: NumerologyVector,
        ashState: SigilAshStateRecord,
        planeAttunementVector: [Double],
        wolfBalance: WolfBalance,
        ancestryWeights: [AncestryWeight],
        celestialClassBasis: CelestialClassBasis,
        anchorPoints: [SigilAnchorPoint],
        edges: [SigilGeometryEdge],
        semanticRoles: [String: String],
        canonicalGeometryDigest: String
    ) {
        self.schemaVersion = schemaVersion
        self.algorithmIdentity = algorithmIdentity
        self.profileHash = profileHash
        self.numerologyVector = numerologyVector
        self.ashState = ashState
        self.planeAttunementVector = planeAttunementVector
        self.wolfBalance = wolfBalance
        self.ancestryWeights = ancestryWeights
        self.celestialClassBasis = celestialClassBasis
        self.anchorPoints = anchorPoints
        self.edges = edges
        self.semanticRoles = semanticRoles
        self.canonicalGeometryDigest = canonicalGeometryDigest
    }
}

public struct SigilFamilyKey: Codable, Equatable, Hashable, Sendable {
    public let lifePathRoot: Int
    public let preservedMasterNumbers: [Int]
    public let dominantPlaneId: Int
    public let secondaryPlaneIds: [Int]
    public let wolfBalanceCategory: String
    public let ancestryFamilyPrimary: String
    public let celestialClassBasisId: String

    public init(
        lifePathRoot: Int,
        preservedMasterNumbers: [Int],
        dominantPlaneId: Int,
        secondaryPlaneIds: [Int],
        wolfBalanceCategory: String,
        ancestryFamilyPrimary: String,
        celestialClassBasisId: String
    ) {
        self.lifePathRoot = lifePathRoot
        self.preservedMasterNumbers = preservedMasterNumbers
        self.dominantPlaneId = dominantPlaneId
        self.secondaryPlaneIds = secondaryPlaneIds
        self.wolfBalanceCategory = wolfBalanceCategory
        self.ancestryFamilyPrimary = ancestryFamilyPrimary
        self.celestialClassBasisId = celestialClassBasisId
    }
}

public enum VisiblePathPrimitive: String, Codable, Hashable, Sendable {
    case dominantSpine = "dominant_spine"
    case upperStructure = "upper_structure"
    case centralNexus = "central_nexus"
    case lowerRoot = "lower_root"
    case sideOrnament = "side_ornament"
    case terminal = "terminal"
    case internalDivision = "internal_division"
    case voidGate = "void_gate"
}

public struct VisibleVectorPath: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let primitive: VisiblePathPrimitive
    public let pathData: String
    public let strokeRole: String
    public let semanticSource: String

    public init(
        id: String,
        primitive: VisiblePathPrimitive,
        pathData: String,
        strokeRole: String,
        semanticSource: String
    ) {
        self.id = id
        self.primitive = primitive
        self.pathData = pathData
        self.strokeRole = strokeRole
        self.semanticSource = semanticSource
    }
}

public enum SigilQualityFailure: String, Codable, Hashable, Sendable {
    case emptyPathSet = "EMPTY_PATH_SET"
    case segmentBudgetTooLow = "SEGMENT_BUDGET_TOO_LOW"
    case segmentBudgetExceeded = "SEGMENT_BUDGET_EXCEEDED"
    case majorCrossingLimitExceeded = "MAJOR_CROSSING_LIMIT_EXCEEDED"
    case duplicatePathDensity = "DUPLICATE_PATH_DENSITY"
}

public struct VisibleSigilQualityReport: Codable, Equatable, Hashable, Sendable {
    public let passed: Bool
    public let candidateIndex: Int
    public let structuralScore: Double
    public let spacingScore: Double
    public let silhouetteScore: Double
    public let intersectionCount: Int
    public let majorCrossingCount: Int
    public let visibleSegmentCount: Int
    public let failures: [SigilQualityFailure]
    public let gateEvidence: [String: String]

    public init(
        passed: Bool,
        candidateIndex: Int,
        structuralScore: Double,
        spacingScore: Double,
        silhouetteScore: Double,
        intersectionCount: Int,
        majorCrossingCount: Int,
        visibleSegmentCount: Int,
        failures: [SigilQualityFailure],
        gateEvidence: [String: String] = [:]
    ) {
        self.passed = passed
        self.candidateIndex = candidateIndex
        self.structuralScore = structuralScore
        self.spacingScore = spacingScore
        self.silhouetteScore = silhouetteScore
        self.intersectionCount = intersectionCount
        self.majorCrossingCount = majorCrossingCount
        self.visibleSegmentCount = visibleSegmentCount
        self.failures = failures
        self.gateEvidence = gateEvidence
    }
}

public struct VisibleStyleMetadata: Codable, Equatable, Hashable, Sendable {
    public let strokeCount: Int
    public let majorCrossingCount: Int
    public let candidateIndex: Int
    public let renderer: String
    public let paletteID: String

    public init(
        strokeCount: Int,
        majorCrossingCount: Int,
        candidateIndex: Int,
        renderer: String,
        paletteID: String
    ) {
        self.strokeCount = strokeCount
        self.majorCrossingCount = majorCrossingCount
        self.candidateIndex = candidateIndex
        self.renderer = renderer
        self.paletteID = paletteID
    }
}

public struct VisibleCanonicalSigil: Codable, Equatable, Hashable, Sendable {
    public let schemaVersion: String
    public let profileDigest: String
    public let canonicalGeometryDigest: String
    public let visibleSignatureHash: String
    public let vectorPaths: [VisibleVectorPath]
    public let styleMetadata: VisibleStyleMetadata
    public let semanticMotifMap: [String: String]
    public let qualityReport: VisibleSigilQualityReport

    public init(
        schemaVersion: String = "rf.visible_sigil.v1",
        profileDigest: String,
        canonicalGeometryDigest: String,
        visibleSignatureHash: String,
        vectorPaths: [VisibleVectorPath],
        styleMetadata: VisibleStyleMetadata,
        semanticMotifMap: [String: String],
        qualityReport: VisibleSigilQualityReport
    ) {
        self.schemaVersion = schemaVersion
        self.profileDigest = profileDigest
        self.canonicalGeometryDigest = canonicalGeometryDigest
        self.visibleSignatureHash = visibleSignatureHash
        self.vectorPaths = vectorPaths
        self.styleMetadata = styleMetadata
        self.semanticMotifMap = semanticMotifMap
        self.qualityReport = qualityReport
    }
}

public struct SigilFlareStyle: Codable, Equatable, Hashable, Sendable {
    public let paletteID: String
    public let glowStrength: Double
    public let backgroundID: String

    public init(paletteID: String, glowStrength: Double, backgroundID: String) {
        self.paletteID = paletteID
        self.glowStrength = glowStrength
        self.backgroundID = backgroundID
    }
}

public struct SigilFlarePresentation: Codable, Equatable, Hashable, Sendable {
    public let profileDigest: String
    public let canonicalGeometryDigest: String
    public let visibleSignatureHash: String
    public let vectorPaths: [VisibleVectorPath]
    public let style: SigilFlareStyle

    public init(
        profileDigest: String,
        canonicalGeometryDigest: String,
        visibleSignatureHash: String,
        vectorPaths: [VisibleVectorPath],
        style: SigilFlareStyle
    ) {
        self.profileDigest = profileDigest
        self.canonicalGeometryDigest = canonicalGeometryDigest
        self.visibleSignatureHash = visibleSignatureHash
        self.vectorPaths = vectorPaths
        self.style = style
    }
}

public struct SigilVisibleGlyphArtifact: Codable, Equatable, Hashable, Sendable {
    public let hiddenGeometry: HiddenCanonicalGeometry
    public let familyKey: SigilFamilyKey
    public let visibleSigil: VisibleCanonicalSigil
    public let svgDocument: String
    public let validationDecision: AeostaraHealthDecision

    public init(
        hiddenGeometry: HiddenCanonicalGeometry,
        familyKey: SigilFamilyKey,
        visibleSigil: VisibleCanonicalSigil,
        svgDocument: String,
        validationDecision: AeostaraHealthDecision
    ) {
        self.hiddenGeometry = hiddenGeometry
        self.familyKey = familyKey
        self.visibleSigil = visibleSigil
        self.svgDocument = svgDocument
        self.validationDecision = validationDecision
    }
}

public enum SigilVisibleGlyphError: Error, Equatable, Sendable {
    case qualityUnsatisfied
    /// Fail-closed: one or more identity-core signals were unavailable, so the
    /// ASH state record cannot be computed without a fabricated value. The array
    /// names the missing fields.
    case identityUnavailable([String])
}
