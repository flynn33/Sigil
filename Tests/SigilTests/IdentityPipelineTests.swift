import RFSigilVisibleGlyph
import XCTest

/// Package 02 — identity pipeline verification.
///
/// Expected values are computed by an independent method (hand / external
/// calendar + Pythagorean letter table), per `docs/design/identity-input-treatment.md`
/// §10. They are NOT produced by the implementation under test. The four
/// primary fixtures reuse the established Package 01 golden profiles; a fifth
/// exercises Y-as-vowel, diacritic transliteration, and master-number
/// preservation through a single profile.
final class IdentityPipelineTests: XCTestCase {

    private let service = SigilVisibleGlyphService()

    // MARK: - Independent fixture table

    private struct Expected {
        let profile: SigilProfileInput
        let lifePath: Int
        let birthDay: Int
        let expression: Int
        let soulUrge: Int
        let personality: Int
        let weekday: Int
        let white: Double
        let dark: Double
        let wolfCategory: String
        let primary: String
        let bits: [Int]
        let packed: UInt16
        let masters: [Int]
    }

    private var fixtures: [Expected] {
        [
            Expected(
                profile: SigilProfileInput(id: "fixture_a", name: "Eira Voss", birthDate: "1991-02-11", birthTime: "03:42", birthCity: "Uppsala", birthOrder: "2 of 3", eyes: "gray", hair: "dark_blonde", heritage: ["Swedish", "German"]),
                lifePath: 6, birthDay: 2, expression: 9, soulUrge: 3, personality: 6, weekday: 1,
                white: 1.0, dark: 1.0, wolfCategory: "balanced", primary: "germanic",
                bits: [0, 0, 1, 1, 0, 1, 1, 0, 0], packed: 108, masters: [11]  // birth day 11 -> chain [11,2]
            ),
            Expected(
                profile: SigilProfileInput(id: "fixture_b", name: "Maeve Kellan", birthDate: "1988-10-30", birthTime: "21:08", birthCity: "Cork", birthOrder: "1 of 2", eyes: "green", hair: "black", heritage: ["Irish", "English"]),
                lifePath: 3, birthDay: 3, expression: 2, soulUrge: 8, personality: 3, weekday: 7,
                white: 0.75, dark: 1.5, wolfCategory: "dark_dominant", primary: "celtic",
                bits: [1, 1, 0, 0, 1, 1, 0, 1, 1], packed: 435, masters: [11]
            ),
            Expected(
                profile: SigilProfileInput(id: "fixture_c", name: "Nadia Kovalenko", birthDate: "2000-07-07", birthTime: "11:19", birthCity: "Krakow", birthOrder: "7 of 9", eyes: "hazel", hair: "brown", heritage: ["Polish", "Ukrainian"]),
                lifePath: 7, birthDay: 7, expression: 9, soulUrge: 2, personality: 7, weekday: 5,
                white: 0.25, dark: 0.5, wolfCategory: "dark_dominant", primary: "slavic",
                bits: [1, 1, 1, 0, 1, 1, 0, 1, 0], packed: 183, masters: [11]
            ),
            Expected(
                profile: SigilProfileInput(id: "fixture_d", name: "Julian Hart", birthDate: "1977-11-04", birthTime: "17:55", birthCity: "York", birthOrder: "3 of 5", eyes: "blue", hair: "red", heritage: ["English", "German"]),
                lifePath: 3, birthDay: 4, expression: 6, soulUrge: 5, personality: 1, weekday: 5,
                white: 1.25, dark: 0.5, wolfCategory: "white_dominant", primary: "germanic",
                bits: [1, 0, 0, 1, 1, 1, 1, 1, 0], packed: 249, masters: []
            ),
            // Y-as-vowel (Y counted in soul urge), diacritic transliteration
            // (Böhm -> BOHM), and master-11 preservation in the expression chain.
            Expected(
                profile: SigilProfileInput(id: "fixture_e", name: "Yara Böhm", birthDate: "1995-06-15", birthTime: "09:30", birthCity: "Leipzig", birthOrder: "1 of 1", eyes: "brown", hair: "black", heritage: ["German"]),
                lifePath: 9, birthDay: 6, expression: 2, soulUrge: 6, personality: 5, weekday: 4,
                white: 0.5, dark: 1.25, wolfCategory: "dark_dominant", primary: "germanic",
                bits: [1, 0, 0, 0, 1, 0, 0, 1, 0], packed: 145, masters: [11]
            ),
        ]
    }

    // MARK: - Primary state fixtures

    func testGoldenProfileStatesMatchIndependentFixtures() throws {
        for fixture in fixtures {
            let artifact = try service.generateArtifact(for: fixture.profile)
            let state = artifact.hiddenGeometry.ashState
            let num = artifact.hiddenGeometry.numerologyVector
            let wolf = artifact.hiddenGeometry.wolfBalance

            XCTAssertEqual(state.statePacked, fixture.packed, "packed state \(fixture.profile.id)")
            XCTAssertEqual(state.stateBits, fixture.bits, "state bits \(fixture.profile.id)")
            XCTAssertEqual(state.classification, "orbit_member", "a valid profile state is not auto-corrected to a codeword")
            XCTAssertEqual(state.isCodeword, false, "none of the fixtures is a codeword")
            XCTAssertEqual(state.orbitSize, 16, "orbit cardinality")
            XCTAssertEqual(state.stability, "stable")
            XCTAssertEqual(state.available, true)
            XCTAssertEqual(state.unavailableIdentityCore, [])
            XCTAssertEqual(state.algorithmIdentity, "sigil-ash-state.v1")
            XCTAssertEqual(state.dominantPlaneId, fixture.lifePath, "dominant plane is the life-path mapping")

            // Real numerology (independent values).
            XCTAssertEqual(num.lifePathRoot, fixture.lifePath, "life path \(fixture.profile.id)")
            XCTAssertEqual(num.birthDayRoot, fixture.birthDay, "birth day \(fixture.profile.id)")
            XCTAssertEqual(num.expressionDestinyRoot, fixture.expression, "expression \(fixture.profile.id)")
            XCTAssertEqual(num.soulUrgeRoot, fixture.soulUrge, "soul urge \(fixture.profile.id)")
            XCTAssertEqual(num.personalityRoot, fixture.personality, "personality \(fixture.profile.id)")
            XCTAssertEqual(num.weekday, fixture.weekday, "weekday \(fixture.profile.id)")
            XCTAssertEqual(num.preservedMasterNumbers, fixture.masters, "master preservation \(fixture.profile.id)")

            // Wolf (supplied-generator behavior).
            XCTAssertEqual(wolf.category, fixture.wolfCategory, "wolf category \(fixture.profile.id)")
            XCTAssertEqual(wolf.whiteWeight, fixture.white, accuracy: 1e-9, "wolf white \(fixture.profile.id)")
            XCTAssertEqual(wolf.darkWeight, fixture.dark, accuracy: 1e-9, "wolf dark \(fixture.profile.id)")
        }
    }

    func testPrimaryHeritageFamilyMatchesIndependentGrouping() throws {
        for fixture in fixtures {
            let artifact = try service.generateArtifact(for: fixture.profile)
            let primary = artifact.hiddenGeometry.ancestryWeights
                .sorted { $0.weight > $1.weight || ($0.weight == $1.weight && $0.family < $1.family) }
                .first?.family
            XCTAssertEqual(primary, fixture.primary, "primary heritage \(fixture.profile.id)")
        }
    }

    func testWeekdayDerivationConsistencyAtCenturyBoundaries() throws {
        // Proleptic-Gregorian weekday for known civil dates (independent, 1=Mon..7=Sun).
        let cases: [(String, Int)] = [
            ("1970-01-01", 4),   // Thursday
            ("2000-01-01", 6),   // Saturday
            ("1900-01-01", 1),   // Monday
        ]
        for (date, expected) in cases {
            let profile = SigilProfileInput(
                id: "wd_\(date)", name: "Rowan Vale", birthDate: date, birthTime: "12:00",
                birthCity: "Test", birthOrder: "1 of 2", eyes: "brown", hair: "brown", heritage: ["English"]
            )
            let artifact = try service.generateArtifact(for: profile)
            XCTAssertEqual(artifact.hiddenGeometry.numerologyVector.weekday, expected, "weekday for \(date)")
        }
    }

    // MARK: - Master-number preservation

    func testMasterNumberPreservationIsAnnotationOnly() throws {
        let b = try service.generateArtifact(for: fixtures[1].profile)
        let c = try service.generateArtifact(for: fixtures[2].profile)

        // 11/22/33 are preserved annotations; the reduced roots still govern.
        XCTAssertEqual(b.hiddenGeometry.numerologyVector.preservedMasterNumbers, [11])
        XCTAssertEqual(b.hiddenGeometry.numerologyVector.expressionDestinyRoot, 2, "11 reduces to 2")
        XCTAssertEqual(c.hiddenGeometry.numerologyVector.preservedMasterNumbers, [11])
        XCTAssertEqual(c.hiddenGeometry.numerologyVector.soulUrgeRoot, 2, "11 reduces to 2")

        // The master is recorded in the reduction provenance chain; in the branch-
        // derived glyph (Package 05) it is annotation-only and does NOT drive a
        // visible stroke -- the visible geometry is the canonical branch geometry,
        // driven by the decoded ASH message, not by numerology accents. The reduced
        // root still governs derivation.
        XCTAssertTrue(b.hiddenGeometry.numerologyVector.reductionProvenance["expression"]!.contains(11), "master 11 is recorded in the expression reduction chain")
        XCTAssertFalse(b.visibleSigil.vectorPaths.contains { $0.semanticSource == "master_number" }, "annotation-only: the master number does not drive a visible stroke in the branch-derived glyph")
    }

    // MARK: - Letter normalization

    func testLetterNormalizationAndTransliteration() {
        // Supported Latin, casefold, diacritic -> base letter.
        XCTAssertEqual(SigilLetterValues.normalizeLetters("Éva")?.map(String.init), ["E", "V", "A"])
        XCTAssertEqual(SigilLetterValues.normalizeLetters("José")?.map(String.init), ["J", "O", "S", "E"])
        XCTAssertEqual(SigilLetterValues.normalizeLetters("Müller")?.map(String.init), ["M", "U", "L", "L", "E", "R"])
        // eszett -> single s (v1 choice).
        XCTAssertEqual(SigilLetterValues.normalizeLetters("Strauß")?.map(String.init), ["S", "T", "R", "A", "U", "S"])
        // Punctuation, digits, whitespace ignored; Y retained (always a vowel).
        XCTAssertEqual(SigilLetterValues.normalizeLetters("Mary-Jane 2.0")?.map(String.init), ["M", "A", "R", "Y", "J", "A", "N", "E"])
        XCTAssertTrue(SigilLetterValues.vowels.contains("Y"), "sig.y.always_vowel")
        // Unsupported script -> fail-closed (nil), never a fabricated default.
        XCTAssertNil(SigilLetterValues.normalizeLetters("Дима"))
        XCTAssertEqual(SigilLetterValues.normalizeLetters(""), [], "empty name is letterless (distinct from unsupported)")
    }

    func testYAsVowelInfluencesSoulUrgeNotPersonality() throws {
        // Yara Böhm: soul urge counts Y (7+1+1+6=15->6); if Y were a consonant it
        // would be 1+1+6=8. The 6 root proves Y-as-vowel.
        let artifact = try service.generateArtifact(for: fixtures[4].profile)
        let num = artifact.hiddenGeometry.numerologyVector
        XCTAssertEqual(num.soulUrgeRoot, 6)
        XCTAssertEqual(num.personalityRoot, 5, "consonants R,B,H,M = 9+2+8+4 = 23 -> 5")
    }

    // MARK: - Partial-input fail-closed

    @discardableResult
    private func assertIdentityUnavailable(_ profile: SigilProfileInput, expectedMissing: [String], file: StaticString = #filePath, line: UInt = #line) -> Bool {
        do {
            _ = try service.generateArtifact(for: profile)
            XCTFail("expected identityUnavailable, got success", file: file, line: line)
            return false
        } catch let error as SigilVisibleGlyphError {
            guard case .identityUnavailable(let missing) = error else {
                XCTFail("expected identityUnavailable, got \(error)", file: file, line: line)
                return false
            }
            XCTAssertEqual(missing, expectedMissing, file: file, line: line)
            return true
        } catch {
            XCTFail("expected identityUnavailable, got \(error)", file: file, line: line)
            return false
        }
    }

    private func validProfile(id: String, name: String = "Casey North", birthDate: String = "1994-05-20", birthOrder: String = "2 of 2", heritage: [String] = ["English"]) -> SigilProfileInput {
        SigilProfileInput(
            id: id, name: name, birthDate: birthDate, birthTime: "10:15",
            birthCity: "Test", birthOrder: birthOrder, eyes: "brown", hair: "black", heritage: heritage
        )
    }

    func testMissingIdentityCoreFieldsFailClosed() {
        assertIdentityUnavailable(validProfile(id: "no_date", birthDate: ""), expectedMissing: ["date", "weekday"])
        assertIdentityUnavailable(validProfile(id: "no_name", name: ""), expectedMissing: ["name"])
        assertIdentityUnavailable(validProfile(id: "no_birth_order", birthOrder: ""), expectedMissing: ["birth_order"])
        assertIdentityUnavailable(validProfile(id: "no_heritage", heritage: []), expectedMissing: ["heritage"])
    }

    func testUnsupportedScriptNameFailsClosed() {
        assertIdentityUnavailable(validProfile(id: "unsupported_script", name: "Дима Иван"), expectedMissing: ["name"])
    }

    // MARK: - Exhaustive codeword and orbit structure

    /// The 16 APS-native codewords as packed values (bit i = b_i, b0 LSB),
    /// independently fixed from the pinned guardrail / canonical reference
    /// (b8 = 0 in every member). Not read from the implementation.
    private let expectedCodewords: [UInt16] = [0, 15, 51, 60, 85, 90, 102, 105, 150, 153, 165, 170, 195, 204, 240, 255]

    func testCodewordSetMatchesIndependentReference() {
        let found: [UInt16] = (0..<512).map { UInt16($0) }.filter { SigilAshCodewordSet.isCodeword(SigilAshState(packed: $0)) }
        XCTAssertEqual(found.sorted(), expectedCodewords.sorted(), "exact 16-member codeword set")
        XCTAssertEqual(Set(found).count, 16)
        for value in found {
            XCTAssertEqual((value >> 8) & 1, 0, "b8 is 0 in every codeword")
            let weight = value.nonzeroBitCount
            XCTAssertTrue(weight % 4 == 0, "doubly-even (weight multiple of 4)")
        }
        // Minimum distance 4: every nonzero codeword has weight >= 4.
        XCTAssertGreaterThanOrEqual(found.filter { $0 != 0 }.map { $0.nonzeroBitCount }.min() ?? 0, 4)
    }

    func testCodewordXorClosure() {
        for a in expectedCodewords {
            for b in expectedCodewords {
                XCTAssertTrue(SigilAshCodewordSet.isCodeword(SigilAshState(packed: a ^ b)),
                              "XOR of codewords \(a), \(b) is a codeword")
            }
        }
    }

    func testOrbitsPartitionTheStateSpace() {
        var seen = Set<UInt16>()
        var orbitCount = 0
        for x in 0..<512 {
            let packed = UInt16(x)
            if seen.contains(packed) { continue }
            orbitCount += 1
            let orbit = SigilAshClassifier.orbit(of: SigilAshState(packed: packed))
            XCTAssertEqual(orbit.members.count, 16, "each orbit has 16 members")
            for member in orbit.members {
                XCTAssertTrue(SigilAshState(packed: member).bits.count == 9)
                seen.insert(member)
            }
        }
        XCTAssertEqual(orbitCount, 32, "32 orbits partition 512 states")
        XCTAssertEqual(seen.count, 512, "no overlap between orbits")
    }

    func testStateClassificationAndStability() {
        for fixture in fixtures {
            let state = SigilAshState(packed: fixture.packed)
            let classification = SigilAshClassifier.classification(of: state)
            XCTAssertEqual(classification.isCodeword, false)
            XCTAssertEqual(classification.label, "orbit_member")
            let orbit = SigilAshClassifier.orbit(of: state)
            XCTAssertEqual(orbit.members.count, 16)
        }
    }

    // MARK: - Coordinate adapter (the named seam)

    func testCoordinateAdapterIsInvolution() {
        for x in 0..<512 {
            let packed = UInt16(x)
            XCTAssertEqual(SigilCoordinateAdapter.swapB6B7(SigilCoordinateAdapter.swapB6B7(packed)), packed,
                           "swap(b6,b7) is an involution at \(x)")
        }
    }

    func testCoordinateAdapterCommutesWithXorByCodeword() {
        for x in 0..<512 {
            let packed = UInt16(x)
            for c in expectedCodewords {
                XCTAssertEqual(
                    SigilCoordinateAdapter.swapB6B7(packed ^ c),
                    SigilCoordinateAdapter.swapB6B7(packed) ^ SigilCoordinateAdapter.swapB6B7(c),
                    "commutation at state \(x), codeword \(c)"
                )
            }
        }
    }

    // MARK: - Determinism

    func testRepeatedInputReproducesIdenticalRecordAndSerialization() throws {
        let profile = fixtures[1].profile
        let first = try service.generateArtifact(for: profile)
        let second = try service.generateArtifact(for: profile)

        XCTAssertEqual(first.hiddenGeometry.ashState, second.hiddenGeometry.ashState)
        XCTAssertEqual(first.hiddenGeometry.numerologyVector, second.hiddenGeometry.numerologyVector)
        XCTAssertEqual(
            try service.canonicalVisibleJSON(for: first.visibleSigil),
            try service.canonicalVisibleJSON(for: second.visibleSigil)
        )
        XCTAssertEqual(first.hiddenGeometry.ashState.stateDigest, second.hiddenGeometry.ashState.stateDigest)
    }
}
