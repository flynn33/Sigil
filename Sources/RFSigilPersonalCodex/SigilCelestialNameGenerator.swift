import Foundation
import RFSigilCanon

// MARK: - Deterministic celestial name generation (source-backed, product-owned)
//
// Implements the celestial-name-generator algorithm (model v1.0.0 / algorithm
// v1.0.1) deterministically. Every table is read from the loaded canon model;
// nothing is hard-coded from a reference character. The syllable selection is a
// declared deterministic function of the mortal name (the source's RNG seed): no
// system randomness, no clock, no dictionary order. A reference character is a
// verification fixture, never a user's identity.

/// The canonical, normalized inputs to the celestial name generator.
public struct SigilCelestialNameInput: Equatable, Hashable, Sendable {
    public let heritage: [String]
    public let birthDate: String      // "YYYY-MM-DD"
    public let birthWeekday: String   // "monday"..."sunday"
    public let birthTime: String      // "HH:MM"
    public let hairColor: String      // canonical generator key
    public let eyeColor: String       // canonical generator key
    public let mortalName: String     // the deterministic seed; kept opaque

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

/// The deterministic celestial naming result. `celestialName` and `epithet` are
/// derived labels (not a raw profile value); `wolfScore` is derived from profile
/// signals and is kept out of routine diagnostics (see the PersonalCodex service).
public struct SigilCelestialNameResult: Equatable, Hashable, Sendable {
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
    /// Coarse, non-sensitive debug facts (the raw score is excluded from the
    /// diagnostic surface; it is present here only as a derived value).
    public let debugMetadata: [String: String]

    public init(celestialName: String, epithet: String, dominantPlaneCode: String, dominantPlaneName: String, dominantPlaneText: String, wolfCategory: String, wolfScore: Double, wolfText: String, weekdayText: String, heritageUsed: String, numerologyText: String, debugMetadata: [String: String]) {
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
        self.debugMetadata = debugMetadata
    }
}

/// Errors for the celestial name generator (fail closed on unusable inputs).
public enum SigilCelestialNameError: Error, Equatable, Sendable {
    case missingBirthDate
    case missingLifePath
    case missingDominantPlane(lifePath: Int)
    case missingWolfTable
    case emptySyllablePool(String)
}

public struct SigilCelestialNameGenerator: Sendable {
    private let model: SigilCelestialGeneratorModel

    public init(model: SigilCelestialGeneratorModel) {
        self.model = model
    }

    // MARK: Deterministic primitives

    private static func fold(_ s: String) -> String {
        s.precomposedStringWithCanonicalMapping
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// FNV-1a 32-bit over the UTF-8 bytes: a small, dependency-free,
    /// deterministic hash (the mortal-name seed).
    private static func fnv1a32(_ s: String) -> UInt32 {
        var hash: UInt32 = 0x811c9dc5
        for byte in s.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 0x01000193
        }
        return hash
    }

    /// Deterministically combine a seed and a positional salt.
    private static func mix(_ seed: UInt32, _ salt: UInt32) -> UInt32 {
        var h = seed &+ salt &* 0x9e3779b9
        h ^= h >> 15
        h = h &* 0x85ebca6b
        h ^= h >> 13
        return h
    }

    private static func capitalizeFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased() + String(s.dropFirst()).lowercased()
    }

    // MARK: Public entry point

    public func generate(input: SigilCelestialNameInput) throws -> SigilCelestialNameResult {
        guard !Self.fold(input.birthDate).isEmpty else { throw SigilCelestialNameError.missingBirthDate }
        let lifePath = Self.lifePath(fromDate: input.birthDate)
        guard let lifePath else { throw SigilCelestialNameError.missingLifePath }

        guard let plane = model.planes.first(where: { $0.numerologyValues.contains(lifePath) }) else {
            throw SigilCelestialNameError.missingDominantPlane(lifePath: lifePath)
        }

        let timeBucket = Self.birthTimeBucket(input.birthTime, buckets: model.birthTimeBuckets)
        let (wolfScore, wolfCategory) = try Self.wolfScore(
            model: model,
            hair: input.hairColor,
            eye: input.eyeColor,
            timeBucket: timeBucket,
            lifePath: lifePath
        )

        let weekday = Self.fold(input.birthWeekday)
        let weekdayArchetype = model.weekdayArchetypes[weekday]
        let heritage = Self.primaryHeritage(input.heritage, families: model.heritageFamilies)
        let heritageFamily = model.heritageFamilies[heritage]

        let seed = Self.fnv1a32(Self.fold(input.mortalName))

        // Root: neutral pool, weighted by the heritage syllable bias.
        let rootPool = model.syllables.root.neutral
        guard !rootPool.isEmpty else { throw SigilCelestialNameError.emptySyllablePool("root") }
        let root = Self.deterministicSelect(pool: rootPool, bias: heritageFamily?.syllableBias ?? [], seed: seed, salt: 0x01)

        // Plane: the dominant plane's pool.
        let planePool = model.syllables.plane[plane.code] ?? []
        guard !planePool.isEmpty else { throw SigilCelestialNameError.emptySyllablePool(plane.code) }
        let planeSyllable = Self.deterministicSelect(pool: planePool, bias: [], seed: seed, salt: 0x02)

        // Wolf: the category pool; the "0-1 optional" syllable is the seed's low bit.
        let wolfPool: [String]
        switch wolfCategory {
        case "white_dominant": wolfPool = model.syllables.wolf.white
        case "dark_dominant": wolfPool = model.syllables.wolf.dark
        default: wolfPool = model.syllables.wolf.balanced
        }
        var syllables: [String] = [root, planeSyllable]
        if !wolfPool.isEmpty, Self.mix(seed, 0x03) & 1 == 0 {
            syllables.append(Self.deterministicSelect(pool: wolfPool, bias: [], seed: seed, salt: 0x03))
        }

        // Enforce the declared min/max syllable count deterministically.
        let minS = model.nameStructureRules.celestialName.lengthPreference.minSyllables
        let maxS = model.nameStructureRules.celestialName.lengthPreference.maxSyllables
        syllables = Array(syllables.prefix(maxS))
        // Deterministic min-fill: pad with wolf syllables (seeded by the mortal
        // name) until the declared minimum is met, never duplicating an existing
        // syllable. Bounded so it can never loop indefinitely.
        var fillSalt: UInt32 = 0x04
        var fillGuard = 0
        while syllables.count < minS && !wolfPool.isEmpty && fillGuard < minS {
            let candidate = wolfPool[Int(Self.mix(seed, fillSalt)) % wolfPool.count]
            if !syllables.contains(candidate) {
                syllables.append(candidate)
            }
            fillSalt &+= 1
            fillGuard &+= 1
        }

        // CamelCase join with the deterministic optional apostrophe before the final syllable.
        let apostrophe = Self.mix(seed, 0x05) & 1 == 0 && syllables.count >= 2
        let parts = syllables.map(Self.capitalizeFirst)
        let celestialName: String
        if apostrophe, let last = parts.dropFirst().last {
            celestialName = parts.dropLast().joined() + "'" + last
        } else {
            celestialName = parts.joined()
        }

        // Epithet: first template matching all its conditions, else the fallback.
        let roleBias = weekdayArchetype?.roleBias
        let epithet = Self.selectEpithet(
            templates: model.epithetTemplates,
            dominantPlaneCode: plane.code,
            roleBias: roleBias,
            heritageFlavor: heritageFamily?.epithetFlavor ?? []
        )

        // Numerology prose (human-readable first), composed from the source fragments.
        let dominantPlaneText = model.numerologyFragments.planes[plane.code] ?? ""
        let wolfText = model.numerologyFragments.wolfBalance[wolfCategory] ?? ""
        let weekdayText = model.numerologyFragments.weekday[weekday] ?? ""
        let heritageLine = "Your heritage carries the tone: \(heritage)."
        let numerologyText = [dominantPlaneText, wolfText, weekdayText, heritageLine]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        let debugMetadata: [String: String] = [
            "life_path_number": "\(lifePath)",
            "dominant_plane": plane.code,
            "wolf_category": wolfCategory,
            "birth_time_bucket": timeBucket ?? "unknown",
            "heritage_used": heritage,
            "syllable_count": "\(syllables.count)"
        ]

        return SigilCelestialNameResult(
            celestialName: celestialName,
            epithet: epithet,
            dominantPlaneCode: plane.code,
            dominantPlaneName: plane.name,
            dominantPlaneText: dominantPlaneText,
            wolfCategory: wolfCategory,
            wolfScore: Self.quantize(wolfScore),
            wolfText: wolfText,
            weekdayText: weekdayText,
            heritageUsed: heritage,
            numerologyText: numerologyText,
            debugMetadata: debugMetadata
        )
    }

    // MARK: Source rules (each a pure function of the loaded canon model)

    /// Life path: sum all digits of YYYY-MM-DD, repeating until a single digit.
    static func lifePath(fromDate raw: String) -> Int? {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        var value = digits.reduce(0) { $0 + Int(($1.asciiValue ?? 0) - 48) }
        guard value > 0 else { return nil }
        while value > 9 {
            value = String(value).reduce(0) { $0 + Int(($1.asciiValue ?? 0) - 48) }
        }
        return value
    }

    /// Five-bucket birth-time scheme, driven by the model's bucket windows.
    static func birthTimeBucket(_ raw: String, buckets: [String: SigilBirthTimeBucket]) -> String? {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return nil }
        let totalMinutes = (parts[0] % 24) * 60 + (parts.count > 1 ? parts[1] % 60 : 0)
        for (name, bucket) in buckets {
            guard let start = minutes(for: bucket.start), let end = minutes(for: bucket.end) else { continue }
            if totalMinutes >= start && totalMinutes <= end { return name }
        }
        return nil
    }

    private static func minutes(for hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return nil }
        return (parts[0] % 24) * 60 + (parts.count > 1 ? parts[1] % 60 : 0)
    }

    /// Wolf balance score and category per the source equation and thresholds:
    /// wolf_score = base + hair + eye + time + life_path; white if score >=
    /// white_dominant, dark if score <= dark_dominant, else balanced.
    static func wolfScore(model: SigilCelestialGeneratorModel, hair: String, eye: String, timeBucket: String?, lifePath: Int) throws -> (Double, String) {
        let rules = model.wolfBalanceRules
        var score = rules.baseScore
        score += rules.hairModifiers[hair] ?? 0
        score += rules.eyeModifiers[eye] ?? 0
        if let timeBucket {
            score += rules.birthTimeModifiers[timeBucket] ?? 0
        }
        score += rules.lifePathModifiers[String(lifePath)] ?? 0
        let t = rules.thresholds
        let category: String
        if score >= t.whiteDominant {
            category = "white_dominant"
        } else if score <= t.darkDominant {
            category = "dark_dominant"
        } else {
            category = "balanced"
        }
        return (quantize(score), category)
    }

    /// Primary heritage family per the source priority: scandinavian, celtic,
    /// germanic, else generic_northern. Operates on the raw input heritage list.
    static func primaryHeritage(_ heritage: [String], families: [String: SigilHeritageFamilyCanon]) -> String {
        let folded = Set(heritage.map { fold($0).replacingOccurrences(of: " ", with: "_") })
        if families.keys.contains("scandinavian") && folded.contains("scandinavian") { return "scandinavian" }
        if families.keys.contains("celtic") && folded.contains("celtic") { return "celtic" }
        if families.keys.contains("germanic") && folded.contains("germanic") { return "germanic" }
        return families.keys.contains("generic_northern") ? "generic_northern" : (families.keys.sorted().first ?? "generic_northern")
    }

    /// Deterministic weighted selection. Candidate order is the pool's declared
    /// order; heritage-bias syllables not already present are appended in bias
    /// order, and syllables present in both are weighted. The selection is a pure
    /// function of (seed, salt) — no system randomness, no clock, no dict order.
    static func deterministicSelect(pool: [String], bias: [String], seed: UInt32, salt: UInt32) -> String {
        var candidates: [String] = pool
        var weight: [String: Int] = [:]
        for s in pool { weight[s, default: 0] += 1 }
        for s in bias where weight[s] == nil {
            candidates.append(s)
            weight[s] = 1
        }
        for s in bias where weight[s] != nil {
            weight[s, default: 1] += 1
        }
        let total = weight.values.reduce(0, +)
        guard total > 0 else { return candidates.first ?? "" }
        let position = Int(mix(seed, salt) % UInt32(total))
        var cumulative = 0
        for s in candidates {
            cumulative += weight[s] ?? 0
            if position < cumulative { return s }
        }
        return candidates.last ?? ""
    }

    /// Epithet: first template whose conditions all hold, else the documented
    /// fallback. A heritage flavor word is appended when one is available.
    static func selectEpithet(templates: [SigilEpithetTemplate], dominantPlaneCode: String, roleBias: String?, heritageFlavor: [String]) -> String {
        for template in templates {
            let c = template.conditions
            if let dp = c.dominantPlane, dp != dominantPlaneCode { continue }
            if let list = c.dominantPlaneAnyOf, !list.contains(dominantPlaneCode) { continue }
            if let roles = c.roleBiasAnyOf, let roleBias, !roles.contains(roleBias) { continue }
            var epithet = template.template
            if !heritageFlavor.isEmpty {
                // Deterministic flavor selection: pick by the plane code hash.
                let flavor = heritageFlavor[Int(dominantPlaneCode.unicodeScalars.compactMap { $0.value }.reduce(UInt32(0)) { $0 &* 31 &+ $1 } % UInt32(heritageFlavor.count))]
                if !epithet.hasSuffix(flavor) {
                    epithet = "\(epithet) (\(flavor))"
                }
            }
            return epithet
        }
        return "The One Who Walks Between Paths"
    }

    private static func quantize(_ value: Double) -> Double {
        (value * 10_000).rounded() / 10_000
    }
}
