import Foundation
import RFSigilCanon
import RFSigilVisibleGlyph

// MARK: - PersonalCodex record (typed, readable, canon-backed, deterministic)
//
// The PersonalCodex is a readable, canon-backed interpretation of a profile's
// ASH identity. It composes the real pipeline outputs (numerology, ASH state,
// plane attunement, wolf balance, ancestry) with the deterministic celestial
// naming and the WRW / mythic-map semantics, and it records full source
// provenance. It is DERIVED, not looked up: a reference character is never
// treated as a user's identity. The record is deterministic (no clock, no
// randomness) so it serializes stably and its digest is reproducible.
//
// Source authority: ASH supplies structural identity; WRW interprets; the
// celestial generator supplies the name; the mythic map supplies the narrative
// context. Canonical and Flare remain separate. There is no personal-data
// embedding (that requirement was removed, not deferred).

/// A self-contained, order-stable canonical JSON encoder and digest for the
/// PersonalCodex record. It mirrors the pipeline's canonical form (sorted keys,
/// no slash escaping) so digests are reproducible across the product.
enum SigilPersonalCodexEncoding {
    static func canonicalJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }

    static func digest<T: Encodable>(_ value: T) throws -> String {
        SigilCanonHash.sha256Hex(try canonicalJSON(value))
    }
}

/// The readable, canon-backed PersonalCodex record for one profile.
public struct SigilPersonalCodex: Codable, Equatable, Hashable, Sendable {
    public static let schemaVersion = "rf.personal_codex.v1"
    public static let algorithmIdentity = "sigil-personalcodex.v1"

    public let schemaVersion: String
    public let algorithmIdentity: String
    /// The storage-scoped profile id (a storage identifier, never the
    /// profile's mathematical hash).
    public let profileStorageID: String

    public let mortalIncarnation: MortalIncarnation
    public let numerologyProfile: NumerologySection
    public let ashIdentity: ASHIdentitySection
    public let planeAttunement: PlaneAttunementSection
    public let celestialClassOrigin: CelestialClassOrigin
    public let celestialName: CelestialNameSection
    public let wolfBalance: WolfBalanceSection
    public let bloodlineHeritageResonance: BloodlineHeritageResonance
    public let trialsBranchEchoes: TrialsBranchEchoes
    public let giftsBurdensThresholds: GiftsBurdensThresholds
    public let sigilReading: SigilReadingSection
    public let provenance: Provenance

    /// An ACYCLIC digest: a SHA-256 over the canonical form of every section
    /// except the digest itself. The visible glyph does not hash back to this
    /// record (the Sigil Reading section is a one-way provenance link to the
    /// pipeline's canonical geometry digest).
    public let digest: String

    public init(
        schemaVersion: String,
        algorithmIdentity: String,
        profileStorageID: String,
        mortalIncarnation: MortalIncarnation,
        numerologyProfile: NumerologySection,
        ashIdentity: ASHIdentitySection,
        planeAttunement: PlaneAttunementSection,
        celestialClassOrigin: CelestialClassOrigin,
        celestialName: CelestialNameSection,
        wolfBalance: WolfBalanceSection,
        bloodlineHeritageResonance: BloodlineHeritageResonance,
        trialsBranchEchoes: TrialsBranchEchoes,
        giftsBurdensThresholds: GiftsBurdensThresholds,
        sigilReading: SigilReadingSection,
        provenance: Provenance,
        digest: String
    ) {
        self.schemaVersion = schemaVersion
        self.algorithmIdentity = algorithmIdentity
        self.profileStorageID = profileStorageID
        self.mortalIncarnation = mortalIncarnation
        self.numerologyProfile = numerologyProfile
        self.ashIdentity = ashIdentity
        self.planeAttunement = planeAttunement
        self.celestialClassOrigin = celestialClassOrigin
        self.celestialName = celestialName
        self.wolfBalance = wolfBalance
        self.bloodlineHeritageResonance = bloodlineHeritageResonance
        self.trialsBranchEchoes = trialsBranchEchoes
        self.giftsBurdensThresholds = giftsBurdensThresholds
        self.sigilReading = sigilReading
        self.provenance = provenance
        self.digest = digest
    }

    /// The section payload hashed into the acyclic digest.
    struct DigestPayload: Codable {
        let schemaVersion: String
        let algorithmIdentity: String
        let profileStorageID: String
        let mortalIncarnation: MortalIncarnation
        let numerologyProfile: NumerologySection
        let ashIdentity: ASHIdentitySection
        let planeAttunement: PlaneAttunementSection
        let celestialClassOrigin: CelestialClassOrigin
        let celestialName: CelestialNameSection
        let wolfBalance: WolfBalanceSection
        let bloodlineHeritageResonance: BloodlineHeritageResonance
        let trialsBranchEchoes: TrialsBranchEchoes
        let giftsBurdensThresholds: GiftsBurdensThresholds
        let sigilReading: SigilReadingSection
        let provenance: Provenance
    }

    func digestPayload() -> DigestPayload {
        DigestPayload(
            schemaVersion: schemaVersion,
            algorithmIdentity: algorithmIdentity,
            profileStorageID: profileStorageID,
            mortalIncarnation: mortalIncarnation,
            numerologyProfile: numerologyProfile,
            ashIdentity: ashIdentity,
            planeAttunement: planeAttunement,
            celestialClassOrigin: celestialClassOrigin,
            celestialName: celestialName,
            wolfBalance: wolfBalance,
            bloodlineHeritageResonance: bloodlineHeritageResonance,
            trialsBranchEchoes: trialsBranchEchoes,
            giftsBurdensThresholds: giftsBurdensThresholds,
            sigilReading: sigilReading,
            provenance: provenance
        )
    }
}

// MARK: - Sections (each: human-readable first, then technical detail, then provenance)

extension SigilPersonalCodex {
    /// The MORTAL identity (the person's own, civil-identity facts). Kept as a
    /// distinct type from the ASH identity and the WRW rendering.
    public struct MortalIncarnation: Codable, Equatable, Hashable, Sendable {
        public let name: String
        public let firstName: String?
        public let lastName: String?
        public let birthDate: String
        public let birthTime: String
        public let birthCity: String
        public let birthOrder: String
        public let heritage: [String]
        public let ancestralSurnames: [String]
        /// The civil-calendar weekday name (e.g. "friday"), derived from the
        /// birth date (a provenance-free input fact, not an interpretation).
        public let weekdayName: String
        /// A short, plain-language summary (human-readable first).
        public let prose: String

        public init(
            name: String,
            firstName: String?,
            lastName: String?,
            birthDate: String,
            birthTime: String,
            birthCity: String,
            birthOrder: String,
            heritage: [String],
            ancestralSurnames: [String],
            weekdayName: String,
            prose: String
        ) {
            self.name = name
            self.firstName = firstName
            self.lastName = lastName
            self.birthDate = birthDate
            self.birthTime = birthTime
            self.birthCity = birthCity
            self.birthOrder = birthOrder
            self.heritage = heritage
            self.ancestralSurnames = ancestralSurnames
            self.weekdayName = weekdayName
            self.prose = prose
        }
    }

    /// The standard numerology profile (the pipeline's reduced roots).
    public struct NumerologySection: Codable, Equatable, Hashable, Sendable {
        public let lifePathRoot: Int
        public let preservedMasterNumbers: [Int]
        public let birthDayRoot: Int
        public let expressionDestinyRoot: Int
        public let soulUrgeRoot: Int
        public let personalityRoot: Int
        public let birthOrderOrdinal: Int
        public let birthOrderTotal: Int
        public let weekday: Int
        public let prose: String

        public init(
            lifePathRoot: Int,
            preservedMasterNumbers: [Int],
            birthDayRoot: Int,
            expressionDestinyRoot: Int,
            soulUrgeRoot: Int,
            personalityRoot: Int,
            birthOrderOrdinal: Int,
            birthOrderTotal: Int,
            weekday: Int,
            prose: String
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
            self.prose = prose
        }
    }

    /// The ASH structural identity (the real nine-bit state and its orbit).
    /// Distinct from the mortal identity and the WRW rendering.
    public struct ASHIdentitySection: Codable, Equatable, Hashable, Sendable {
        public let statePacked: UInt16
        public let stateBits: [Int]
        public let isCodeword: Bool
        public let orbitSize: Int
        public let classification: String
        public let stability: String
        public let dominantPlaneId: Int
        public let stateDigest: String
        public let algorithmIdentity: String
        /// One-way provenance link to the pipeline's canonical geometry digest
        /// (the glyph does not hash back to this record).
        public let canonicalGeometryDigest: String
        public let prose: String

        public init(
            statePacked: UInt16,
            stateBits: [Int],
            isCodeword: Bool,
            orbitSize: Int,
            classification: String,
            stability: String,
            dominantPlaneId: Int,
            stateDigest: String,
            algorithmIdentity: String,
            canonicalGeometryDigest: String,
            prose: String
        ) {
            self.statePacked = statePacked
            self.stateBits = stateBits
            self.isCodeword = isCodeword
            self.orbitSize = orbitSize
            self.classification = classification
            self.stability = stability
            self.dominantPlaneId = dominantPlaneId
            self.stateDigest = stateDigest
            self.algorithmIdentity = algorithmIdentity
            self.canonicalGeometryDigest = canonicalGeometryDigest
            self.prose = prose
        }
    }

    /// Plane attunement: the pipeline's nine-plane vector, each plane annotated
    /// with its mathematical type (from the canon taxonomy) and a WRW pressure
    /// state; the dominant plane is the life-path mapping.
    public struct PlaneAttunementSection: Codable, Equatable, Hashable, Sendable {
        public struct PlaneEntry: Codable, Equatable, Hashable, Sendable {
            public let id: Int
            public let code: String
            public let name: String
            public let mathType: String
            public let role: String
            public let weight: Double
            public let pressureState: String
            public init(id: Int, code: String, name: String, mathType: String, role: String, weight: Double, pressureState: String) {
                self.id = id
                self.code = code
                self.name = name
                self.mathType = mathType
                self.role = role
                self.weight = weight
                self.pressureState = pressureState
            }
        }

        public let vector: [Double]
        public let planes: [PlaneEntry]
        public let dominantPlaneCode: String
        public let dominantPlaneName: String
        /// Source numerology prose for the dominant plane (from the celestial
        /// generator's numerology output fragments).
        public let dominantPlaneText: String
        public let prose: String

        public init(vector: [Double], planes: [PlaneEntry], dominantPlaneCode: String, dominantPlaneName: String, dominantPlaneText: String, prose: String) {
            self.vector = vector
            self.planes = planes
            self.dominantPlaneCode = dominantPlaneCode
            self.dominantPlaneName = dominantPlaneName
            self.dominantPlaneText = dominantPlaneText
            self.prose = prose
        }
    }

    /// A canon-derived celestial class and origin attribution. Distinct from
    /// the pipeline's temporary `celestialClassBasis` id (kept for provenance).
    public struct CelestialClassOrigin: Codable, Equatable, Hashable, Sendable {
        public let id: String
        public let basis: String
        public let dominantPlaneCode: String
        public let wolfCategory: String
        public let heritage: String
        /// Narrative context drawn from the mythic map (lucifer / angels /
        /// trials) as symbolic framing, never as a claim about the user.
        public let narrative: String
        /// The pipeline's temporary celestial basis id, recorded for provenance
        /// (refined by this canon-derived attribution).
        public let pipelineBasisId: String
        public let prose: String

        public init(id: String, basis: String, dominantPlaneCode: String, wolfCategory: String, heritage: String, narrative: String, pipelineBasisId: String, prose: String) {
            self.id = id
            self.basis = basis
            self.dominantPlaneCode = dominantPlaneCode
            self.wolfCategory = wolfCategory
            self.heritage = heritage
            self.narrative = narrative
            self.pipelineBasisId = pipelineBasisId
            self.prose = prose
        }
    }

    /// The deterministic celestial name and epithet (the source algorithm).
    public struct CelestialNameSection: Codable, Equatable, Hashable, Sendable {
        public let celestialName: String
        public let epithet: String
        public let dominantPlaneCode: String
        public let dominantPlaneName: String
        public let dominantPlaneText: String
        public let wolfCategory: String
        public let wolfScore: Double
        public let wolfText: String
        public let weekdayText: String
        public let heritageUsed: String
        public let numerologyText: String
        public let syllableCount: Int
        public let prose: String

        public init(
            celestialName: String,
            epithet: String,
            dominantPlaneCode: String,
            dominantPlaneName: String,
            dominantPlaneText: String,
            wolfCategory: String,
            wolfScore: Double,
            wolfText: String,
            weekdayText: String,
            heritageUsed: String,
            numerologyText: String,
            syllableCount: Int,
            prose: String
        ) {
            self.celestialName = celestialName
            self.epithet = epithet
            self.dominantPlaneCode = dominantPlaneCode
            self.dominantPlaneName = dominantPlaneName
            self.dominantPlaneText = dominantPlaneText
            self.wolfCategory = wolfCategory
            self.wolfScore = wolfScore
            self.wolfText = wolfText
            self.weekdayText = weekdayText
            self.heritageUsed = heritageUsed
            self.numerologyText = numerologyText
            self.syllableCount = syllableCount
            self.prose = prose
        }
    }

    /// Wolf balance recorded under BOTH the source rule and the pipeline rule,
    /// with any divergence made explicit.
    public struct WolfBalanceSection: Codable, Equatable, Hashable, Sendable {
        public struct RuleReading: Codable, Equatable, Hashable, Sendable {
            public let category: String
            public let score: Double
            public let rule: String
            public init(category: String, score: Double, rule: String) {
                self.category = category
                self.score = score
                self.rule = rule
            }
        }
        public let sourceRule: RuleReading
        public let pipelineRule: RuleReading
        /// True when the two rules assign different categories for this profile.
        public let divergent: Bool
        /// The mythic-map dual-attractor framing (the wolves are complementary
        /// attractors, not moral poles).
        public let dualAttractorNarrative: String
        public let prose: String

        public init(sourceRule: RuleReading, pipelineRule: RuleReading, divergent: Bool, dualAttractorNarrative: String, prose: String) {
            self.sourceRule = sourceRule
            self.pipelineRule = pipelineRule
            self.divergent = divergent
            self.dualAttractorNarrative = dualAttractorNarrative
            self.prose = prose
        }
    }

    /// Bloodline / heritage resonance, framed by the WRW bloodline semantics
    /// (lineage pressure, not a destiny claim, never a static class lock).
    public struct BloodlineHeritageResonance: Codable, Equatable, Hashable, Sendable {
        public struct Weight: Codable, Equatable, Hashable, Sendable {
            public let family: String
            public let weight: Double
            public init(family: String, weight: Double) {
                self.family = family
                self.weight = weight
            }
        }
        public let ancestryWeights: [Weight]
        public let heritage: [String]
        public let status: String
        public let stability: String
        /// Always false: bloodline resonance is lineage pressure, never a
        /// deterministic biological destiny claim.
        public let isDestinyClaim: Bool
        public let notADestinyClaimNote: String
        public let prose: String

        public init(ancestryWeights: [Weight], heritage: [String], status: String, stability: String, isDestinyClaim: Bool, notADestinyClaimNote: String, prose: String) {
            self.ancestryWeights = ancestryWeights
            self.heritage = heritage
            self.status = status
            self.stability = stability
            self.isDestinyClaim = isDestinyClaim
            self.notADestinyClaimNote = notADestinyClaimNote
            self.prose = prose
        }
    }

    /// Bounded symbolic trials / branch echoes from the WRW branching semantics
    /// and the mythic trials. NEVER a fabricated or simulated life history.
    public struct TrialsBranchEchoes: Codable, Equatable, Hashable, Sendable {
        public let boundedSymbolic: Bool
        public let isFabricatedLifeHistory: Bool
        public let significance: String
        public let qualifiers: [String]
        public let trialsContext: String
        public let prose: String

        public init(boundedSymbolic: Bool, isFabricatedLifeHistory: Bool, significance: String, qualifiers: [String], trialsContext: String, prose: String) {
            self.boundedSymbolic = boundedSymbolic
            self.isFabricatedLifeHistory = isFabricatedLifeHistory
            self.significance = significance
            self.qualifiers = qualifiers
            self.trialsContext = trialsContext
            self.prose = prose
        }
    }

    /// Bounded symbolic gifts / burdens / thresholds from plane pressure and
    /// wolf resonance. Symbolic framing, not a factual claim about the user.
    public struct GiftsBurdensThresholds: Codable, Equatable, Hashable, Sendable {
        public let symbolic: Bool
        public let gifts: [String]
        public let burdens: [String]
        public let thresholds: [String]
        public let prose: String

        public init(symbolic: Bool, gifts: [String], burdens: [String], thresholds: [String], prose: String) {
            self.symbolic = symbolic
            self.gifts = gifts
            self.burdens = burdens
            self.thresholds = thresholds
            self.prose = prose
        }
    }

    /// The Sigil Reading is EXPLICITLY incomplete pending the Package 05
    /// canonical geometry. It carries a one-way provenance link to the
    /// pipeline's canonical geometry digest (the glyph does not hash back to
    /// this record).
    public struct SigilReadingSection: Codable, Equatable, Hashable, Sendable {
        public let complete: Bool
        public let completionNote: String
        public let canonicalGeometryDigest: String
        public let prose: String

        public init(complete: Bool, completionNote: String, canonicalGeometryDigest: String, prose: String) {
            self.complete = complete
            self.completionNote = completionNote
            self.canonicalGeometryDigest = canonicalGeometryDigest
            self.prose = prose
        }
    }

    /// Source provenance: the canon registry, manifest version, algorithm
    /// specification identity, and a stable provenance digest.
    public struct Provenance: Codable, Equatable, Hashable, Sendable {
        public struct SourceRef: Codable, Equatable, Hashable, Sendable {
            public let id: String
            public let version: String
            public let sha256: String
            public let role: String
            public let mode: String
            public init(id: String, version: String, sha256: String, role: String, mode: String) {
                self.id = id
                self.version = version
                self.sha256 = sha256
                self.role = role
                self.mode = mode
            }
        }
        public let manifestVersion: String
        public let algorithmSpecificationSha256: String
        public let sources: [SourceRef]
        public let provenanceDigest: String
        public let prose: String

        public init(manifestVersion: String, algorithmSpecificationSha256: String, sources: [SourceRef], provenanceDigest: String, prose: String) {
            self.manifestVersion = manifestVersion
            self.algorithmSpecificationSha256 = algorithmSpecificationSha256
            self.sources = sources
            self.provenanceDigest = provenanceDigest
            self.prose = prose
        }
    }
}

// MARK: - Fail-closed PersonalCodex errors

public enum SigilPersonalCodexError: Error, Equatable, Sendable {
    case invalidSchemaVersion(String)
    case digestMismatch(recorded: String, recomputed: String)
    case missingSection(String)
    case provenanceIncomplete
    case pipelineIdentityUnavailable([String])
    case canonicalEncodeFailed(String)
}
