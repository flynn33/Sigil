import Foundation

// MARK: - Field availability
//
// Product policy `sigil-partial-input.v1` (docs/design/identity-input-treatment.md §7):
// every field carries an explicit state. Unknown (the user did not record it) is
// distinct from unsupported (a value was recorded but is outside the supported
// domain). An unavailable identity-core field makes the ASH state record fail-closed
// for the affected derivation class; it is never substituted with a fabricated value.

public enum SigilFieldAvailability: String, Codable, Equatable, Hashable, Sendable {
    case present
    case unknown
    case unsupported
}

// MARK: - Civil date (timezone-free)
//
// Product policy `sigil-civil-date.v1` (§5.1). The birth date is a proleptic
// Gregorian civil date recorded as `YYYY-MM-DD`. Parsing is timezone-free: the
// civil date itself is the value. The weekday is a pure function of the civil
// date (no host clock, no timezone, no locale) derived by a fixed Gregorian
// day-number computation.

public struct SigilCivilDate: Codable, Equatable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parsed civil date, or nil when the string is absent or not a valid
    /// `YYYY-MM-DD` date. No host timezone or locale is consulted.
    public static func parse(_ raw: String) -> SigilCivilDate? {
        let parts = raw.split(separator: "-").map(String.init)
        guard parts.count == 3 else { return nil }
        guard let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        guard (1...9999).contains(y) else { return nil }
        guard (1...12).contains(m) else { return nil }
        let daysInMonth = [31, isLeap(y) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
        guard (1...daysInMonth).contains(d) else { return nil }
        return SigilCivilDate(year: y, month: m, day: d)
    }

    private static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// Proleptic Gregorian weekday, 1 = Monday ... 7 = Sunday. Pure function of
    /// the civil date; no timezone, clock, or locale. Verified against an
    /// independent Gregorian implementation (spec §10 independent fixtures).
    public var weekday: Int {
        var yy = year
        var mm = month
        if mm <= 2 {
            mm += 12
            yy -= 1
        }
        let era = (yy >= 4 ? yy : yy - 399) / 400
        let yoe = yy - era * 400
        let doy = (153 * (mm - 3) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        let daysSinceEpoch = era * 146097 + doe - 719468 // 1970-01-01 (a Thursday)
        let index = ((daysSinceEpoch % 7) + 7) % 7        // 0 == Thursday
        return [4, 5, 6, 7, 1, 2, 3][index]               // 1=Mon ... 7=Sun
    }
}

// MARK: - Birth order
//
// Product policy `sigil-birth-order.v1` (§6.3). Typed (ordinal, total) with
// validation `1 <= ordinal <= total`. Absent/unknown is an explicit state, never
// a fabricated `(1, 1)` (the prior silent default was a recorded defect).

public struct SigilBirthOrder: Codable, Equatable, Hashable, Sendable {
    public let ordinal: Int
    public let total: Int

    public init(ordinal: Int, total: Int) {
        self.ordinal = ordinal
        self.total = total
    }

    /// Parses a recorded birth order such as `"2 of 3"` or `"3/5"`. Returns nil
    /// when no valid `(ordinal, total)` pair can be established, or when the pair
    /// violates `1 <= ordinal <= total`.
    public static func parse(_ raw: String) -> SigilBirthOrder? {
        let numbers = raw.split { !$0.isNumber }.compactMap { Int($0) }
        guard numbers.count >= 2 else { return nil }
        let ordinal = numbers[0]
        let total = numbers[1]
        guard ordinal >= 1, total >= ordinal else { return nil }
        return SigilBirthOrder(ordinal: ordinal, total: total)
    }
}

// MARK: - Hair category
//
// Product policy `sigil-hair-eyes.v1` (§6.1). Fixed category table with a
// deterministic alias/normalization map. The value fed to the wolf resolver is
// the celestial generator's modifier key (cited supplied-generator behavior,
// §6.1); categories the generator does not name map to its documented `other`
// default-modifier path (weight 0), never an invented weight or a string sum.

public enum SigilHairCategory: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case black, darkBrown = "dark-brown", brown, lightBrown = "light-brown", blond
    case red, gray, white, mixed, other, unknown

    /// Celestial generator modifier key (cited table; `other` is the documented
    /// default-modifier path). Values are product-owned constants that mirror the
    /// pinned generator reference; see SigilWolfResolver for the weight table.
    public var generatorKey: String {
        switch self {
        case .black: return "black"
        case .darkBrown: return "dark_brown"
        case .lightBrown: return "light_brown"
        case .blond: return "blonde"
        case .red: return "red"
        case .gray, .white, .brown, .mixed, .other, .unknown: return "other"
        }
    }

    /// Normalizes a recorded value to a category. Values outside the supported
    /// table resolve to `.unknown` only when the field is empty/absent; a
    /// recorded-but-unrecognized value is `.other` (recorded as unsupported at the
    /// boundary) and uses the generator's documented default-modifier path.
    public static func normalize(_ raw: String) -> (category: SigilHairCategory, availability: SigilFieldAvailability) {
        let key = Self.fold(raw)
        switch key {
        case "": return (.unknown, .unknown)
        case "black": return (.black, .present)
        case "dark_brown", "darkbrown", "dark brown": return (.darkBrown, .present)
        case "brown": return (.brown, .present)
        case "light_brown", "lightbrown", "light brown", "blonde_light", "light blonde": return (.lightBrown, .present)
        case "blond", "blonde": return (.blond, .present)
        case "red", "auburn", "strawberry": return (.red, .present)
        case "gray", "grey": return (.gray, .present)
        case "white": return (.white, .present)
        case "mixed": return (.mixed, .present)
        case "other": return (.other, .present)
        default: return (.other, .unsupported)
        }
    }

    private static func fold(_ raw: String) -> String {
        raw.precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Eye category

public enum SigilEyeCategory: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case black, brown, hazel, green, blue, gray, amber, violet, mixed, other, unknown

    public var generatorKey: String {
        switch self {
        case .blue: return "blue"
        case .green: return "green"
        case .hazel: return "hazel"
        case .brown: return "brown"
        case .gray: return "grey"
        case .black, .amber, .violet, .mixed, .other, .unknown: return "other"
        }
    }

    public static func normalize(_ raw: String) -> (category: SigilEyeCategory, availability: SigilFieldAvailability) {
        let key = Self.fold(raw)
        switch key {
        case "": return (.unknown, .unknown)
        case "black": return (.black, .present)
        case "brown": return (.brown, .present)
        case "hazel": return (.hazel, .present)
        case "green": return (.green, .present)
        case "blue": return (.blue, .present)
        case "gray", "grey": return (.gray, .present)
        case "amber": return (.amber, .present)
        case "violet", "purple": return (.violet, .present)
        case "mixed": return (.mixed, .present)
        case "other": return (.other, .present)
        default: return (.other, .unsupported)
        }
    }

    private static func fold(_ raw: String) -> String {
        raw.precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Heritage family
//
// Product policy `sigil-heritage.v1` (§6.2). Canonical family groups with the
// v1 alias table. The canonical ordering (used for the `b8` coordinate index
// parity) is germanic, celtic, slavic, mixed.

public enum SigilHeritageFamily: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case germanic, celtic, slavic, mixed

    public static let canonicalOrder: [SigilHeritageFamily] = [.germanic, .celtic, .slavic, .mixed]

    public var canonicalIndex: Int {
        Self.canonicalOrder.firstIndex(of: self) ?? Self.canonicalOrder.count - 1
    }

    public static func group(_ raw: String) -> SigilHeritageFamily {
        let key = raw.precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .trimmingCharacters(in: .whitespaces)
        switch key {
        case "swedish", "german", "english", "scandinavian", "norse":
            return .germanic
        case "irish", "scottish", "welsh":
            return .celtic
        case "polish", "ukrainian", "russian", "slovak", "czech", "bulgarian", "serbian":
            return .slavic
        default:
            return .mixed
        }
    }
}

// MARK: - Time bucket (product canonical annotation)
//
// Product policy `sigil-birth-time.v1` (§5.3). The product records a canonical
// four-bucket annotation. This is a recorded signal; it is distinct from the
// celestial generator's own five-bucket time scheme, which the wolf resolver
// uses (supplied-generator behavior, §6.1).

public enum SigilProductTimeBucket: String, Codable, Equatable, Hashable, Sendable {
    case dawn, day, dusk, night, unknown

    public static func bucket(forTime raw: String) -> SigilProductTimeBucket {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return .unknown }
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 1 else { return .unknown }
        let minutes = (parts[0] % 24) * 60 + (parts.count > 1 ? parts[1] % 60 : 0)
        switch minutes {
        case 240..<480: return .dawn    // 04:00-07:59
        case 480..<960: return .day     // 08:00-15:59
        case 960..<1200: return .dusk   // 16:00-19:59
        default: return .night          // 20:00-03:59
        }
    }
}

// MARK: - Location precision
//
// Product policy `sigil-birth-place.v1` (§5.4). Precision is recorded only; it
// never triggers a network call. `place`/`region` are manual names; `coordinate`
// is user-supplied at the precision actually given.

public enum SigilLocationPrecision: String, Codable, Equatable, Hashable, Sendable {
    case unknown, place, region, coordinate

    public static func derive(fromPlace raw: String) -> SigilLocationPrecision {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return .unknown }
        if t.contains("(") || t.contains(",") || t.contains("+") || t.contains("-") && t.contains(".") {
            return .coordinate
        }
        return .place
    }
}

// MARK: - Parental birth order (annotation-only)
//
// Product policy `sigil-birth-order.v1` (§6.3). Typed (ordinal, total) per parent
// side. Recorded in the identity record and PersonalCodex; does not feed state
// bits in v1 (documented non-influence, tested as such).

public struct SigilParentalBirthOrder: Codable, Equatable, Hashable, Sendable {
    public let side: String          // "maternal" | "paternal"
    public let ordinal: Int
    public let total: Int

    public init(side: String, ordinal: Int, total: Int) {
        self.side = side
        self.ordinal = ordinal
        self.total = total
    }
}
