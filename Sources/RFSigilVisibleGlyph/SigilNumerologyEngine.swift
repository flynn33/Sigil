import Foundation

// MARK: - Letter values
//
// Product policy `sigil-letter-values.v1` (§5.2). Exact conventional
// Pythagorean letter table. Normalization pipeline: NFKC -> casefold to base
// letter -> diacritic-marked characters transliterated to their base letter
// (e -> e, n -> n, u -> u), with the recorded v1 choice that the eszett folds to
// a single `s`. Punctuation, digits, and whitespace are ignored. A name with a
// letter outside the supported Latin set fails closed for the name-derived roots
// (no scalar sum, no default person).

public enum SigilLetterValues {
    /// A=1 B=2 C=3 D=4 E=5 F=6 G=7 H=8 I=9 J=1 K=2 L=3 M=4 N=5 O=6 P=7 Q=8 R=9
    /// S=1 T=2 U=3 V=4 W=5 X=6 Y=7 Z=8 (conventional Pythagorean).
    static let table: [Character: Int] = [
        "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8, "I": 9,
        "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "O": 6, "P": 7, "Q": 8, "R": 9,
        "S": 1, "T": 2, "U": 3, "V": 4, "W": 5, "X": 6, "Y": 7, "Z": 8
    ]

    /// `sig.y.always_vowel` — Y is always a vowel (v1 deterministic rule).
    public static let vowels: Set<Character> = ["A", "E", "I", "O", "U", "Y"]

    /// Normalizes a raw name component to its supported Latin base letters
    /// (uppercase A-Z), or nil when it contains a letter outside the supported
    /// set. Pipeline: NFKC, eszett folded to a single `s` (v1 choice), then
    /// diacritic-marked letters transliterated to their base letter. Punctuation,
    /// digits, and whitespace are ignored. An empty/absent component yields [].
    public static func normalizeLetters(_ raw: String) -> [Character]? {
        // Explicit compatibility fold for the eszett (v1 choice): eszett to s,
        // capital eszett to S.
        let ss = raw
            .replacingOccurrences(of: "\u{00DF}", with: "s")
            .replacingOccurrences(of: "\u{1E9E}", with: "S")
        // Canonical composition (NFC) then canonical decomposition (NFD) so each
        // diacritic-marked letter separates into its base letter plus combining
        // marks, which are dropped. This is the deterministic base-letter
        // equivalent for the supported Latin set on this SDK (which does not
        // expose `String.foldingString`). Compatibility-equivalent input such as
        // fullwidth forms or ligatures is outside the supported set and fails
        // closed rather than being silently coerced.
        let decomp = ss.precomposedStringWithCanonicalMapping
            .decomposedStringWithCanonicalMapping
        var hasUnsupported = false
        var out: [Character] = []
        for scalar in decomp.unicodeScalars {
            if Self.isCombiningMark(Int(scalar.value)) { continue }
            let ch = Character(scalar)
            guard ch.isLetter else { continue } // digits/punctuation/whitespace ignored
            guard let upper = ch.uppercased().first else { continue }
            if table[upper] != nil {
                out.append(upper)
            } else {
                hasUnsupported = true
            }
        }
        return hasUnsupported ? nil : out
    }

    /// Unicode combining-mark code-point ranges removed during base-letter
    /// extraction (canonical decomposition leaves marks as separate scalars).
    private static let combiningMarkRanges: [(Int, Int)] = [
        (0x0300, 0x036F), (0x0483, 0x0489), (0x0591, 0x05BD), (0x05BF, 0x05BF),
        (0x05C1, 0x05C2), (0x05C4, 0x05C5), (0x05C7, 0x05C7), (0x0610, 0x061A),
        (0x064B, 0x065F), (0x0670, 0x0670), (0x06D6, 0x06DD), (0x06DF, 0x06E4),
        (0x06E7, 0x06E8), (0x06EA, 0x06ED), (0x1AB0, 0x1AFF), (0x1DC0, 0x1DFF),
        (0x20D0, 0x20FF), (0xFE20, 0xFE2F)
    ]

    private static func isCombiningMark(_ value: Int) -> Bool {
        for (lo, hi) in combiningMarkRanges where value >= lo && value <= hi {
            return true
        }
        return false
    }

}

// MARK: - Numerology record
//
// The validated, deterministic numerology output. Roots are fully reduced to
// 1-9 (product policy `sigil-master-numbers.v1`: reduction always proceeds to
// 1-9; 11/22/33 are preserved annotations, never a stopping rule). Provenance
// records the intermediate reduction chains so a result can be explained.

public struct SigilNumerologyRecord: Codable, Equatable, Hashable, Sendable {
    public let lifePathRoot: Int
    public let birthDayRoot: Int
    public let expressionRoot: Int
    public let soulUrgeRoot: Int
    public let personalityRoot: Int
    public let weekday: Int
    public let preservedMasterNumbers: [Int]
    public let reductionProvenance: [String: [Int]]

    public init(
        lifePathRoot: Int,
        birthDayRoot: Int,
        expressionRoot: Int,
        soulUrgeRoot: Int,
        personalityRoot: Int,
        weekday: Int,
        preservedMasterNumbers: [Int],
        reductionProvenance: [String: [Int]]
    ) {
        self.lifePathRoot = lifePathRoot
        self.birthDayRoot = birthDayRoot
        self.expressionRoot = expressionRoot
        self.soulUrgeRoot = soulUrgeRoot
        self.personalityRoot = personalityRoot
        self.weekday = weekday
        self.preservedMasterNumbers = preservedMasterNumbers
        self.reductionProvenance = reductionProvenance
    }
}

// MARK: - Numerology engine

public enum SigilNumerologyEngine {
    static let masters: Set<Int> = [11, 22, 33]

    private static func digitSum(_ value: Int) -> Int {
        String(abs(value)).compactMap { $0.wholeNumberValue }.reduce(0, +)
    }

    /// Full reduction to 1-9 with the intermediate chain and any master numbers
    /// (11/22/33) met along the way. Reduction always proceeds to 1-9; the master
    /// numbers are annotations only (they never alter the reduced root).
    static func reduce(_ start: Int) -> (root: Int, chain: [Int], masters: Set<Int>) {
        var chain = [start]
        var current = start
        var masters: Set<Int> = []
        while current > 9 {
            current = digitSum(current)
            chain.append(current)
        }
        for value in chain where Self.masters.contains(value) {
            masters.insert(value)
        }
        return (current, chain, masters)
    }

    /// Full-date life path (retained, now normative, §5.1): sum of the eight
    /// digits of `YYYYMMDD`, then full reduction to 1-9.
    static func lifePath(_ date: SigilCivilDate) -> (root: Int, chain: [Int], masters: Set<Int>) {
        let padded = String(format: "%04d%02d%02d", date.year, date.month, date.day)
        let values = padded.compactMap { $0.wholeNumberValue }
        return reduce(values.reduce(0, +))
    }

    static func birthDayRoot(_ date: SigilCivilDate) -> (root: Int, chain: [Int], masters: Set<Int>) {
        reduce(date.day)
    }

    /// Name-derived roots over the normalized full name (first + last,
    /// order-preserving): expression over all letters, soul urge over vowels
    /// (Y always a vowel), personality over consonants.
    static func nameRoots(first: [Character], last: [Character]) -> (
        expression: (root: Int, chain: [Int], masters: Set<Int>),
        soulUrge: (root: Int, chain: [Int], masters: Set<Int>),
        personality: (root: Int, chain: [Int], masters: Set<Int>)
    ) {
        let letters = first + last
        let expressionValues = letters.map { SigilLetterValues.table[$0] ?? 0 }
        let vowelValues = letters.filter { SigilLetterValues.vowels.contains($0) }.map { SigilLetterValues.table[$0] ?? 0 }
        let consonantValues = letters.filter { !SigilLetterValues.vowels.contains($0) }.map { SigilLetterValues.table[$0] ?? 0 }
        return (
            reduce(expressionValues.reduce(0, +)),
            reduce(vowelValues.reduce(0, +)),
            reduce(consonantValues.reduce(0, +))
        )
    }

    /// Computes the validated numerology record for a civil date and normalized
    /// name letters. `hasName` distinguishes an empty name (name-derived roots
    /// unavailable, fail-closed) from a name that was present.
    public static func record(
        date: SigilCivilDate,
        firstLetters: [Character],
        lastLetters: [Character],
        hasName: Bool
    ) -> SigilNumerologyRecord {
        let life = lifePath(date)
        let birth = birthDayRoot(date)
        let names = nameRoots(first: firstLetters, last: lastLetters)

        var allMasters: Set<Int> = []
        allMasters.formUnion(life.masters)
        allMasters.formUnion(birth.masters)
        if hasName {
            allMasters.formUnion(names.expression.masters)
            allMasters.formUnion(names.soulUrge.masters)
            allMasters.formUnion(names.personality.masters)
        }

        var provenance: [String: [Int]] = [
            "life_path": life.chain,
            "birth_day": birth.chain
        ]
        if hasName {
            provenance["expression"] = names.expression.chain
            provenance["soul_urge"] = names.soulUrge.chain
            provenance["personality"] = names.personality.chain
        }

        return SigilNumerologyRecord(
            lifePathRoot: life.root,
            birthDayRoot: birth.root,
            expressionRoot: hasName ? names.expression.root : 0,
            soulUrgeRoot: hasName ? names.soulUrge.root : 0,
            personalityRoot: hasName ? names.personality.root : 0,
            weekday: date.weekday,
            preservedMasterNumbers: allMasters.sorted(),
            reductionProvenance: provenance
        )
    }
}
