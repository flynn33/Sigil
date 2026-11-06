import Foundation

// MARK: - Celestial Name Generator (typed, decoded from the shipped canonical resource)
//
// These models mirror the exact fields of the pinned celestial-name-generator
// reference (model v1.0.0, algorithm v1.0.1; source identity recorded in the
// canon manifest). They are decoded from the shipped resource and structurally
// validated at load; the loader fails closed on a missing or malformed required
// table. The canonical compound is always spelled PersonalCodex /
// personal_codex in this product (see docs/design/canon-personalcodex.md).

/// One of the nine planes with its numerology mapping and naming influence.
public struct SigilCelestialPlane: Codable, Equatable, Hashable, Sendable {
    public let id: Int
    public let code: String
    public let name: String
    public let numerologyValues: [Int]
    public let keywords: [String]
    public let nameInfluence: String

    public init(id: Int, code: String, name: String, numerologyValues: [Int], keywords: [String], nameInfluence: String) {
        self.id = id
        self.code = code
        self.name = name
        self.numerologyValues = numerologyValues
        self.keywords = keywords
        self.nameInfluence = nameInfluence
    }
}

/// A weekday archetype: deity axis, tone, and role bias.
public struct SigilWeekdayArchetype: Codable, Equatable, Hashable, Sendable {
    public let deityAxis: String
    public let tone: String
    public let roleBias: String

    public init(deityAxis: String, tone: String, roleBias: String) {
        self.deityAxis = deityAxis
        self.tone = tone
        self.roleBias = roleBias
    }
}

/// A canonical five-bucket birth-time window.
public struct SigilBirthTimeBucket: Codable, Equatable, Hashable, Sendable {
    public let start: String
    public let end: String

    public init(start: String, end: String) {
        self.start = start
        self.end = end
    }
}

/// The wolf balance scoring rules: base score, modifier tables, thresholds.
public struct SigilWolfBalanceRules: Codable, Equatable, Hashable, Sendable {
    public let baseScore: Double
    public let hairModifiers: [String: Double]
    public let eyeModifiers: [String: Double]
    public let birthTimeModifiers: [String: Double]
    /// Keys are the stringified life-path numbers "1"..."9".
    public let lifePathModifiers: [String: Double]
    public let thresholds: Thresholds

    public struct Thresholds: Codable, Equatable, Hashable, Sendable {
        public let whiteDominant: Double
        public let balancedLower: Double
        public let balancedUpper: Double
        public let darkDominant: Double

        public init(whiteDominant: Double, balancedLower: Double, balancedUpper: Double, darkDominant: Double) {
            self.whiteDominant = whiteDominant
            self.balancedLower = balancedLower
            self.balancedUpper = balancedUpper
            self.darkDominant = darkDominant
        }
    }

    public init(baseScore: Double, hairModifiers: [String: Double], eyeModifiers: [String: Double], birthTimeModifiers: [String: Double], lifePathModifiers: [String: Double], thresholds: Thresholds) {
        self.baseScore = baseScore
        self.hairModifiers = hairModifiers
        self.eyeModifiers = eyeModifiers
        self.birthTimeModifiers = birthTimeModifiers
        self.lifePathModifiers = lifePathModifiers
        self.thresholds = thresholds
    }
}

/// A heritage family: pantheon tone, syllable bias, and epithet flavor.
public struct SigilHeritageFamilyCanon: Codable, Equatable, Hashable, Sendable {
    public let pantheonTone: String
    public let syllableBias: [String]
    public let epithetFlavor: [String]

    public init(pantheonTone: String, syllableBias: [String], epithetFlavor: [String]) {
        self.pantheonTone = pantheonTone
        self.syllableBias = syllableBias
        self.epithetFlavor = epithetFlavor
    }
}

/// The syllable pools used to assemble a celestial name.
public struct SigilSyllableSets: Codable, Equatable, Hashable, Sendable {
    public let root: Root
    /// Plane pools keyed "P1"..."P9".
    public let plane: [String: [String]]
    public let wolf: Wolf

    public struct Root: Codable, Equatable, Hashable, Sendable {
        public let neutral: [String]
        public init(neutral: [String]) { self.neutral = neutral }
    }
    public struct Wolf: Codable, Equatable, Hashable, Sendable {
        public let white: [String]
        public let dark: [String]
        public let balanced: [String]
        public init(white: [String], dark: [String], balanced: [String]) {
            self.white = white
            self.dark = dark
            self.balanced = balanced
        }
    }

    public init(root: Root, plane: [String: [String]], wolf: Wolf) {
        self.root = root
        self.plane = plane
        self.wolf = wolf
    }
}

/// An epithet template with its matching conditions.
public struct SigilEpithetTemplate: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let conditions: Conditions
    public let template: String

    public struct Conditions: Codable, Equatable, Hashable, Sendable {
        public let dominantPlane: String?
        public let dominantPlaneAnyOf: [String]?
        public let roleBiasAnyOf: [String]?

        public init(dominantPlane: String? = nil, dominantPlaneAnyOf: [String]? = nil, roleBiasAnyOf: [String]? = nil) {
            self.dominantPlane = dominantPlane
            self.dominantPlaneAnyOf = dominantPlaneAnyOf
            self.roleBiasAnyOf = roleBiasAnyOf
        }
    }

    public init(id: String, conditions: Conditions, template: String) {
        self.id = id
        self.conditions = conditions
        self.template = template
    }
}

/// The readable numerology prose fragments (planes, wolf balance, weekday).
public struct SigilNumerologyFragments: Codable, Equatable, Hashable, Sendable {
    public let planes: [String: String]
    public let wolfBalance: [String: String]
    public let weekday: [String: String]

    public init(planes: [String: String], wolfBalance: [String: String], weekday: [String: String]) {
        self.planes = planes
        self.wolfBalance = wolfBalance
        self.weekday = weekday
    }
}

/// The name-structure rules for the celestial name and epithet.
public struct SigilNameStructureRules: Codable, Equatable, Hashable, Sendable {
    public let celestialName: CelestialName
    public let epithet: Epithet

    public struct CelestialName: Codable, Equatable, Hashable, Sendable {
        public let parts: [String]
        public let joinStyle: String
        public let lengthPreference: LengthPreference
        public struct LengthPreference: Codable, Equatable, Hashable, Sendable {
            public let minSyllables: Int
            public let maxSyllables: Int
            public init(minSyllables: Int, maxSyllables: Int) {
                self.minSyllables = minSyllables
                self.maxSyllables = maxSyllables
            }
        }
        public init(parts: [String], joinStyle: String, lengthPreference: LengthPreference) {
            self.parts = parts
            self.joinStyle = joinStyle
            self.lengthPreference = lengthPreference
        }
    }
    public struct Epithet: Codable, Equatable, Hashable, Sendable {
        public let enabled: Bool
        public let useTemplates: Bool
        public init(enabled: Bool, useTemplates: Bool) {
            self.enabled = enabled
            self.useTemplates = useTemplates
        }
    }

    public init(celestialName: CelestialName, epithet: Epithet) {
        self.celestialName = celestialName
        self.epithet = epithet
    }
}

/// A canonical example profile. These are reference fixtures used for
/// independent verification only; a reference character is never treated as a
/// user's identity by the generator.
public struct SigilCanonExampleProfile: Codable, Equatable, Hashable, Sendable {
    public let label: String
    public let inputs: Inputs

    public struct Inputs: Codable, Equatable, Hashable, Sendable {
        public let heritage: [String]
        public let birthDate: String
        public let birthWeekday: String
        public let birthTime: String
        public let hairColor: String
        public let eyeColor: String
        public let mortalName: String

        public init(heritage: [String], birthDate: String, birthWeekday: String, birthTime: String, hairColor: String, eyeColor: String, mortalName: String) {
            self.heritage = heritage
            self.birthDate = birthDate
            self.birthWeekday = birthWeekday
            self.birthTime = birthTime
            self.hairColor = hairColor
            self.eyeColor = eyeColor
            self.mortalName = mortalName
        }
    }

    public init(label: String, inputs: Inputs) {
        self.label = label
        self.inputs = inputs
    }
}

/// The decoded celestial generator model (the fields the runtime uses; unknown
/// source fields are ignored during decoding).
public struct SigilCelestialGeneratorModel: Codable, Equatable, Hashable, Sendable {
    public let modelName: String
    public let version: String
    public let planes: [SigilCelestialPlane]
    public let weekdayArchetypes: [String: SigilWeekdayArchetype]
    public let wolfBalanceRules: SigilWolfBalanceRules
    public let heritageFamilies: [String: SigilHeritageFamilyCanon]
    public let syllables: SigilSyllableSets
    public let nameStructureRules: SigilNameStructureRules
    public let epithetTemplates: [SigilEpithetTemplate]
    public let numerologyFragments: SigilNumerologyFragments
    public let exampleProfiles: [SigilCanonExampleProfile]
    public let birthTimeBuckets: [String: SigilBirthTimeBucket]

    public init(
        modelName: String,
        version: String,
        planes: [SigilCelestialPlane],
        weekdayArchetypes: [String: SigilWeekdayArchetype],
        wolfBalanceRules: SigilWolfBalanceRules,
        heritageFamilies: [String: SigilHeritageFamilyCanon],
        syllables: SigilSyllableSets,
        nameStructureRules: SigilNameStructureRules,
        epithetTemplates: [SigilEpithetTemplate],
        numerologyFragments: SigilNumerologyFragments,
        exampleProfiles: [SigilCanonExampleProfile],
        birthTimeBuckets: [String: SigilBirthTimeBucket]
    ) {
        self.modelName = modelName
        self.version = version
        self.planes = planes
        self.weekdayArchetypes = weekdayArchetypes
        self.wolfBalanceRules = wolfBalanceRules
        self.heritageFamilies = heritageFamilies
        self.syllables = syllables
        self.nameStructureRules = nameStructureRules
        self.epithetTemplates = epithetTemplates
        self.numerologyFragments = numerologyFragments
        self.exampleProfiles = exampleProfiles
        self.birthTimeBuckets = birthTimeBuckets
    }

    /// Coding keys aligned to the canonical reference JSON. `numerologyFragments`
    /// maps to the reference's `numerology_output_fragments`; `inputs` carries the
    /// nested `birth_time.buckets` (decoded in `init(from:)`).
    enum CodingKeys: String, CodingKey {
        case modelName
        case version
        case planes
        case weekdayArchetypes
        case wolfBalanceRules
        case heritageFamilies
        case syllables
        case nameStructureRules
        case epithetTemplates
        case numerologyFragments = "numerologyOutputFragments"
        case exampleProfiles
        case birthTimeBuckets
        case inputs
    }

    private struct InputsShape: Decodable {
        struct BirthTime: Decodable {
            let buckets: [String: SigilBirthTimeBucket]
        }
        let birthTime: BirthTime?
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.modelName = try c.decode(String.self, forKey: .modelName)
        self.version = try c.decode(String.self, forKey: .version)
        self.planes = try c.decode([SigilCelestialPlane].self, forKey: .planes)
        self.weekdayArchetypes = try c.decode([String: SigilWeekdayArchetype].self, forKey: .weekdayArchetypes)
        self.wolfBalanceRules = try c.decode(SigilWolfBalanceRules.self, forKey: .wolfBalanceRules)
        self.heritageFamilies = try c.decode([String: SigilHeritageFamilyCanon].self, forKey: .heritageFamilies)
        self.syllables = try c.decode(SigilSyllableSets.self, forKey: .syllables)
        self.nameStructureRules = try c.decode(SigilNameStructureRules.self, forKey: .nameStructureRules)
        self.epithetTemplates = try c.decode([SigilEpithetTemplate].self, forKey: .epithetTemplates)
        self.numerologyFragments = try c.decode(SigilNumerologyFragments.self, forKey: .numerologyFragments)
        self.exampleProfiles = try c.decode([SigilCanonExampleProfile].self, forKey: .exampleProfiles)
        // The reference nests the five birth-time buckets under
        // model.inputs.birth_time.buckets; decode from that path (empty when absent).
        let inputs = try c.decodeIfPresent(InputsShape.self, forKey: .inputs)
        self.birthTimeBuckets = inputs?.birthTime?.buckets ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(modelName, forKey: .modelName)
        try c.encode(version, forKey: .version)
        try c.encode(planes, forKey: .planes)
        try c.encode(weekdayArchetypes, forKey: .weekdayArchetypes)
        try c.encode(wolfBalanceRules, forKey: .wolfBalanceRules)
        try c.encode(heritageFamilies, forKey: .heritageFamilies)
        try c.encode(syllables, forKey: .syllables)
        try c.encode(nameStructureRules, forKey: .nameStructureRules)
        try c.encode(epithetTemplates, forKey: .epithetTemplates)
        try c.encode(numerologyFragments, forKey: .numerologyFragments)
        try c.encode(exampleProfiles, forKey: .exampleProfiles)
        try c.encode(birthTimeBuckets, forKey: .birthTimeBuckets)
    }
}

/// The full celestial generator: model plus the algorithm identity marker used
/// for provenance (a source-version change is therefore visible).
public struct SigilCelestialGenerator: Codable, Equatable, Hashable, Sendable {
    public let version: String
    public let model: SigilCelestialGeneratorModel
    public let algorithmVersion: String

    public init(version: String, model: SigilCelestialGeneratorModel, algorithmVersion: String) {
        self.version = version
        self.model = model
        self.algorithmVersion = algorithmVersion
    }
}
