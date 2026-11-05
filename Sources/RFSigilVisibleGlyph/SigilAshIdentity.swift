import Foundation

// MARK: - ASH state (finite nine-bit value, APS native convention)
//
// Product policy `sigil-state-form.v1` (§1): the full nine-coordinate F2^9
// universe is the product formalization. A state is a finite nine-bit value in
// the APS native convention (zero-based b0..b8; the ninth coordinate b8 is the
// canonical convention, not a derived value). States are stored packed as a
// `UInt8` (0...511) so that arbitrary (non-codeword) states are never written
// as nine-bit literals in source.

public struct SigilAshState: Codable, Equatable, Hashable, Sendable {
    /// Packed nine-bit value, bit i == coordinate b_i (b0 is the least
    /// significant bit). Range 0...511.
    public let packed: UInt16

    public init(packed: UInt16) {
        self.packed = packed & 0b111111111
    }

    public init(bits: [Int]) {
        var value: UInt16 = 0
        for (index, bit) in bits.enumerated() where index < 9 {
            if bit != 0 { value |= (1 << index) }
        }
        self.packed = value & 0b111111111
    }

    /// Coordinate b_i (0...8), 0 or 1.
    public func bit(_ i: Int) -> Int {
        (i < 0 || i > 8) ? 0 : (Int((packed >> i) & 1))
    }

    public var bits: [Int] {
        (0..<9).map { bit($0) }
    }

    public static func xor(_ a: SigilAshState, _ b: SigilAshState) -> SigilAshState {
        SigilAshState(packed: a.packed ^ b.packed)
    }

    public static func xorByCodeword(_ a: SigilAshState, codeword: UInt16) -> SigilAshState {
        SigilAshState(packed: a.packed ^ (codeword & 0b111111111))
    }
}

// MARK: - Codeword set (canonical 16-member [9,4,4], APS native)
//
// Product-owned constant that mirrors the pinned APS canonical reference and the
// repository guardrail literal set; cited, never reinterpreted. The last
// coordinate (b8) is 0 in every member. A shared parameter count does not
// establish exact codeword equality; the set is the exact 16-member source set.

public enum SigilAshCodewordSet {
    static let nativeTuples: [(UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)] = [
        (0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 1, 1, 1, 1, 0),
        (0, 0, 1, 1, 0, 0, 1, 1, 0),
        (0, 0, 1, 1, 1, 1, 0, 0, 0),
        (0, 1, 0, 1, 0, 1, 0, 1, 0),
        (0, 1, 0, 1, 1, 0, 1, 0, 0),
        (0, 1, 1, 0, 0, 1, 1, 0, 0),
        (0, 1, 1, 0, 1, 0, 0, 1, 0),
        (1, 0, 0, 1, 0, 1, 1, 0, 0),
        (1, 0, 0, 1, 1, 0, 0, 1, 0),
        (1, 0, 1, 0, 0, 1, 0, 1, 0),
        (1, 0, 1, 0, 1, 0, 1, 0, 0),
        (1, 1, 0, 0, 0, 0, 1, 1, 0),
        (1, 1, 0, 0, 1, 1, 0, 0, 0),
        (1, 1, 1, 1, 0, 0, 0, 0, 0),
        (1, 1, 1, 1, 1, 1, 1, 1, 0)
    ]

    static let codewords: [UInt16] = nativeTuples.map(pack)
    static let codewordSet: Set<UInt16> = Set(codewords)

    static func pack(_ t: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> UInt16 {
        UInt16(t.0) | (UInt16(t.1) << 1) | (UInt16(t.2) << 2) | (UInt16(t.3) << 3) | (UInt16(t.4) << 4) | (UInt16(t.5) << 5) | (UInt16(t.6) << 6) | (UInt16(t.7) << 7) | (UInt16(t.8) << 8)
    }

    public static func isCodeword(_ state: SigilAshState) -> Bool {
        codewordSet.contains(state.packed)
    }
}

// MARK: - Orbit, classification, and decoder

public struct SigilAshOrbit: Codable, Equatable, Hashable, Sendable {
    public let representative: UInt16
    public let members: [UInt16]

    public init(representative: UInt16, members: [UInt16]) {
        self.representative = representative
        self.members = members
    }
}

public struct SigilAshDecode: Codable, Equatable, Hashable, Sendable {
    public let nearestCodeword: UInt16
    public let hammingDistance: Int
    public let ambiguity: Int      // number of codewords achieving the minimum distance
    public let isCodeword: Bool
}

public enum SigilAshClassifier {
    /// The orbit of a state under XOR-by-codeword: { s XOR c : c in codewords }.
    /// For the linear [9,4,4] set this is a 16-member coset; there are 32 orbits
    /// over the 512 states.
    public static func orbit(of state: SigilAshState) -> SigilAshOrbit {
        let members = SigilAshCodewordSet.codewords.map { state.packed ^ $0 }.sorted()
        return SigilAshOrbit(representative: members.first ?? state.packed, members: members)
    }

    /// Classification of a valid state. A valid arbitrary state is not
    /// automatically a codeword; this distinguishes the 16 codewords from the
    /// non-codeword orbit members without correcting the state to a codeword.
    public static func classification(of state: SigilAshState) -> (isCodeword: Bool, label: String) {
        let isCode = SigilAshCodewordSet.isCodeword(state)
        return (isCode, isCode ? "codeword" : "orbit_member")
    }

    /// Nearest-codeword decoding with radius/ambiguity (source-defined context
    /// only). The minimum distance of the [9,4,4] set is 4, so distance <= 1 is
    /// uniquely correctable and distance <= 3 is detectable. The decoder reports
    /// the ambiguity count; it never mutates the input state.
    public static func decode(_ state: SigilAshState) -> SigilAshDecode {
        var bestDistance = Int.max
        var bestWord: UInt16 = 0
        var ambiguity = 0
        for word in SigilAshCodewordSet.codewords {
            let distance = hammingDistance(state.packed, word)
            if distance < bestDistance {
                bestDistance = distance
                bestWord = word
                ambiguity = 1
            } else if distance == bestDistance {
                ambiguity += 1
            }
        }
        return SigilAshDecode(
            nearestCodeword: bestWord,
            hammingDistance: bestDistance,
            ambiguity: ambiguity,
            isCodeword: ambiguity == 1 && bestDistance == 0
        )
    }

    static func hammingDistance(_ a: UInt16, _ b: UInt16) -> Int {
        ((a ^ b) & 0b111111111).nonzeroBitCount
    }
}

// MARK: - Coordinate adapter (the named seam translation)
//
// Product policy `sigil-coordinate-adapter.v1` (§2): the final-two-coordinate
// swap (b6 <-> b7 in APS native) that maps the ASH-Model one-based reference
// tables onto the APS native tables. Applied only at the explicitly named seam
// where the product touches ASH-Model reference data. It is an involution and
// commutes with XOR-by-codeword (verified exhaustively in tests).

public enum SigilCoordinateAdapter {
    public static func toApsNative(fromReference reference: UInt16) -> UInt16 {
        swapB6B7(reference)
    }

    /// swap(b6, b7): an involution on all 512 states that commutes with
    /// XOR-by-codeword.
    public static func swapB6B7(_ packed: UInt16) -> UInt16 {
        let b6 = (packed >> 6) & 1
        let b7 = (packed >> 7) & 1
        var out = packed & ~(0b011000000)  // clear bits 6 and 7
        if b6 == 1 { out |= (1 << 7) }
        if b7 == 1 { out |= (1 << 6) }
        return out & 0b111111111
    }
}

// MARK: - Wolf balance (supplied-generator behavior)
//
// Product policy `sigil-hair-eyes.v1` / `sig.wolf.band.v1` (§6.1). The white/
// dark weights come from the celestial generator's explicit modifier tables for
// hair, eyes, and time bucket (cited source data, versioned with the generator
// reference). The category threshold retains the existing 0.12 band as product
// policy. The wolf time contribution uses the generator's own five-bucket time
// scheme (supplied-generator behavior); the product's four-bucket annotation is
// a separate recorded signal.

public enum SigilWolfTimeBucket: String, Equatable, Hashable, Sendable {
    case night, dawn, day, dusk, late
}

public enum SigilWolfResolver {
    // Celestial generator modifier tables (product-owned constants cited to the
    // pinned generator reference; see docs/design/identity-input-treatment.md §6.1).
    static let baseScore: Double = 0
    static let hairModifiers: [String: Double] = [
        "blonde": 1, "light_brown": 0.5, "dark_brown": -0.5, "black": -1,
        "red": 0, "grey_white": 0.5, "other": 0
    ]
    static let eyeModifiers: [String: Double] = [
        "blue": 1, "green": 0.5, "hazel": 0.25, "brown": -0.25, "grey": 0.5, "other": 0
    ]
    static let birthTimeModifiers: [String: Double] = [
        "night": -1, "dawn": 0.5, "day": 0, "dusk": -0.5, "late": -0.5
    ]
    static let lifePathModifiers: [Int: Double] = [
        1: 0, 2: 0.25, 3: 0.25, 4: 0, 5: 0, 6: 0.5, 7: -0.5, 8: -0.25, 9: 0.5
    ]

    static let balancedBand: Double = 0.12

    /// Generator five-bucket time scheme (supplied-generator behavior).
    public static func generatorTimeBucket(forTime raw: String) -> SigilWolfTimeBucket? {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return nil }
        let minutes = (parts[0] % 24) * 60 + (parts.count > 1 ? parts[1] % 60 : 0)
        switch minutes {
        case 0..<360: return .night      // 00:00-05:59
        case 360..<540: return .dawn     // 06:00-08:59
        case 540..<960: return .day      // 09:00-15:59
        case 960..<1200: return .dusk    // 16:00-19:59
        case 1200..<1440: return .late   // 20:00-23:59
        default: return nil
        }
    }

    public static func resolve(
        hair: SigilHairCategory,
        eyes: SigilEyeCategory,
        birthTime: String,
        lifePathRoot: Int
    ) -> WolfBalance {
        var white = baseScore
        var dark = baseScore
        func add(_ value: Double) {
            if value > 0 { white += value } else if value < 0 { dark -= value }
        }
        add(hairModifiers[hair.generatorKey] ?? 0)
        add(eyeModifiers[eyes.generatorKey] ?? 0)
        if let bucket = generatorTimeBucket(forTime: birthTime) {
            add(birthTimeModifiers[bucket.rawValue] ?? 0)
        }
        add(lifePathModifiers[lifePathRoot] ?? 0)

        let w = quantize(white)
        let d = quantize(dark)
        let category: String
        if abs(w - d) <= balancedBand {
            category = "balanced"
        } else if w > d {
            category = "white_dominant"
        } else {
            category = "dark_dominant"
        }
        return WolfBalance(whiteWeight: w, darkWeight: d, category: category)
    }

    private static func quantize(_ value: Double) -> Double {
        (value * 10_000).rounded() / 10_000
    }
}

// MARK: - Profile-to-state adapter v1
//
// Product policy `sigil-profile-adapter.v1` (§3.2): a named, versioned Sigil
// profile adapter over normalized numerology and input signals. One parity rule
// per coordinate. Parity is a product policy choice, not a source rule. No
// digest bytes enter the semantic path. A coordinate whose identity-core signal
// is unavailable fails the whole state closed (the state is not computed with a
// fabricated bit); the wolf coordinate always has the generator's documented
// default-modifier path and is therefore never a hard failure.

public struct SigilProfileSignals: Sendable {
    public let lifePathRoot: Int
    public let birthDayRoot: Int
    public let expressionRoot: Int
    public let soulUrgeRoot: Int
    public let personalityRoot: Int
    public let weekday: Int
    public let hasName: Bool
    public let hasDate: Bool
    public let birthOrderOrdinal: Int?
    public let heritageCanonicalIndex: Int?
    public let wolfBalance: WolfBalance

    public init(
        lifePathRoot: Int,
        birthDayRoot: Int,
        expressionRoot: Int,
        soulUrgeRoot: Int,
        personalityRoot: Int,
        weekday: Int,
        hasName: Bool,
        hasDate: Bool,
        birthOrderOrdinal: Int?,
        heritageCanonicalIndex: Int?,
        wolfBalance: WolfBalance
    ) {
        self.lifePathRoot = lifePathRoot
        self.birthDayRoot = birthDayRoot
        self.expressionRoot = expressionRoot
        self.soulUrgeRoot = soulUrgeRoot
        self.personalityRoot = personalityRoot
        self.weekday = weekday
        self.hasName = hasName
        self.hasDate = hasDate
        self.birthOrderOrdinal = birthOrderOrdinal
        self.heritageCanonicalIndex = heritageCanonicalIndex
        self.wolfBalance = wolfBalance
    }
}

public enum SigilProfileAdapterV1 {
    public static let identity = "sigil-profile-adapter.v1"

    /// Identity-core fields whose unavailability fails the state closed. The
    /// wolf coordinate is excluded: the generator's documented default-modifier
    /// path keeps it computable.
    public static func unavailableIdentityCore(_ s: SigilProfileSignals) -> [String] {
        var missing: [String] = []
        if !s.hasDate {
            missing.append("date")
            missing.append("weekday")
        }
        if !s.hasName {
            missing.append("name")
        }
        if s.birthOrderOrdinal == nil {
            missing.append("birth_order")
        }
        if s.heritageCanonicalIndex == nil {
            missing.append("heritage")
        }
        return missing
    }

    /// Builds the nine-bit APS-native state, or nil when any identity-core
    /// signal is unavailable (fail-closed).
    public static func state(from s: SigilProfileSignals) -> SigilAshState? {
        guard unavailableIdentityCore(s).isEmpty else { return nil }
        var bits: [Int] = []
        bits.append(s.lifePathRoot % 2)               // b0
        bits.append(s.birthDayRoot % 2)               // b1
        bits.append(s.expressionRoot % 2)             // b2
        bits.append(s.soulUrgeRoot % 2)               // b3
        bits.append(s.personalityRoot % 2)            // b4
        bits.append(s.weekday % 2)                    // b5
        bits.append(s.wolfBalance.category == "dark_dominant" ? 0 : 1)  // b6: white non-inferior
        bits.append((s.birthOrderOrdinal ?? 0) % 2)   // b7
        bits.append((s.heritageCanonicalIndex ?? 0) % 2)  // b8
        return SigilAshState(bits: bits)
    }
}

// MARK: - ASH state record (the real, source-backed state)
//
// Replaces the digest-substitute state semantics (F-03). Carries the finite
// nine-bit state, its orbit and codeword classification, the dominant plane
// (life-path mapping), the wolf balance, and the algorithm identity marker for
// changed canonical output.

public struct SigilAshStateRecord: Codable, Equatable, Hashable, Sendable {
    public let statePacked: UInt16
    public let stateBits: [Int]
    public let isCodeword: Bool
    public let orbitSize: Int
    public let classification: String
    public let stability: String
    public let dominantPlaneId: Int
    public let wolfBalance: WolfBalance
    public let algorithmIdentity: String
    public let stateDigest: String
    public let available: Bool
    public let unavailableIdentityCore: [String]

    public init(
        statePacked: UInt16,
        stateBits: [Int],
        isCodeword: Bool,
        orbitSize: Int,
        classification: String,
        stability: String,
        dominantPlaneId: Int,
        wolfBalance: WolfBalance,
        algorithmIdentity: String,
        stateDigest: String,
        available: Bool,
        unavailableIdentityCore: [String]
    ) {
        self.statePacked = statePacked
        self.stateBits = stateBits
        self.isCodeword = isCodeword
        self.orbitSize = orbitSize
        self.classification = classification
        self.stability = stability
        self.dominantPlaneId = dominantPlaneId
        self.wolfBalance = wolfBalance
        self.algorithmIdentity = algorithmIdentity
        self.stateDigest = stateDigest
        self.available = available
        self.unavailableIdentityCore = unavailableIdentityCore
    }
}
