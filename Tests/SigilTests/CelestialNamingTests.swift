import Foundation
import RFSigilCanon
import RFSigilPersonalCodex
import XCTest

// MARK: - Deterministic celestial naming (source-backed, product-owned)
//
// These tests exercise the public `generate(input:)` API only, driven by the
// real loaded canon model (nothing hard-coded from a reference character). They
// pin the life-path → dominant plane mapping, the wolf-balance equation under
// the source ±1.0 thresholds, the heritage priority, and the determinism /
// non-lookup guarantees (a reference character is a fixture, never a name source).

final class CelestialNamingTests: XCTestCase {

    // MARK: - Helpers

    private func makeGenerator() throws -> SigilCelestialNameGenerator {
        let canon = try SigilCanonLoader().load()
        return SigilCelestialNameGenerator(model: canon.celestialGenerator.model)
    }

    /// Canonical generator inputs. Hair/eye are the model's canonical generator
    /// keys (allowed_values); the mortal name is the deterministic seed.
    private func input(
        name: String = "Aria Sol",
        heritage: [String] = ["germanic"],
        birthDate: String = "1977-11-04",
        birthWeekday: String = "saturday",
        birthTime: String = "12:00",
        hair: String = "red",
        eye: String = "brown"
    ) -> SigilCelestialNameInput {
        SigilCelestialNameInput(
            heritage: heritage,
            birthDate: birthDate,
            birthWeekday: birthWeekday,
            birthTime: birthTime,
            hairColor: hair,
            eyeColor: eye,
            mortalName: name
        )
    }

    // MARK: - Life path → dominant plane

    func testLifePathDeterminesDominantPlane() throws {
        let generator = try makeGenerator()
        // 1977-11-04 → 1+9+7+7+1+1+0+4 = 30 → 3 → P3 (Astral).
        let result = try generator.generate(input: input(birthDate: "1977-11-04"))
        XCTAssertEqual(result.dominantPlaneCode, "P3")
        XCTAssertEqual(result.dominantPlaneName, "Astral")
        // 1994-01-01 → 1+9+9+4+0+1+0+1 = 25 → 7 → P7 (Shadow).
        let result7 = try generator.generate(input: input(birthDate: "1994-01-01"))
        XCTAssertEqual(result7.dominantPlaneCode, "P7")
        XCTAssertEqual(result7.dominantPlaneName, "Shadow")
    }

    // MARK: - Wolf balance equation under the source ±1.0 thresholds

    func testWolfCategoryWhiteDominant() throws {
        let generator = try makeGenerator()
        // blonde(+1) + blue(+1) + day(0) + life-path-3(+0.25) = 2.25 (>= 1.0).
        let result = try generator.generate(
            input: input(birthDate: "1977-11-04", birthTime: "12:00", hair: "blonde", eye: "blue")
        )
        XCTAssertEqual(result.wolfCategory, "white_dominant")
        XCTAssertEqual(result.wolfScore, 2.25)
    }

    func testWolfCategoryBalanced() throws {
        let generator = try makeGenerator()
        // red(0) + brown(-0.25) + day(0) + life-path-3(+0.25) = 0.0 (strictly inside (-1, 1)).
        let result = try generator.generate(
            input: input(birthDate: "1977-11-04", birthTime: "12:00", hair: "red", eye: "brown")
        )
        XCTAssertEqual(result.wolfCategory, "balanced")
        XCTAssertEqual(result.wolfScore, 0.0)
    }

    func testWolfCategoryDarkDominant() throws {
        let generator = try makeGenerator()
        // black(-1) + brown(-0.25) + night(-1) + life-path-7(-0.5) = -2.75 (<= -1.0).
        let result = try generator.generate(
            input: input(birthDate: "1994-01-01", birthTime: "02:00", hair: "black", eye: "brown")
        )
        XCTAssertEqual(result.wolfCategory, "dark_dominant")
        XCTAssertEqual(result.wolfScore, -2.75)
        XCTAssertEqual(result.dominantPlaneCode, "P7")
    }

    // MARK: - Heritage priority (scandinavian > celtic > germanic)

    func testHeritagePriorityScandinavian() throws {
        let generator = try makeGenerator()
        let result = try generator.generate(input: input(heritage: ["celtic", "scandinavian", "germanic"]))
        XCTAssertEqual(result.heritageUsed, "scandinavian")
    }

    func testHeritagePriorityFallsToCeltic() throws {
        let generator = try makeGenerator()
        let result = try generator.generate(input: input(heritage: ["celtic", "germanic"]))
        XCTAssertEqual(result.heritageUsed, "celtic")
    }

    // MARK: - Determinism

    func testDeterministicReproduction() throws {
        let generator = try makeGenerator()
        let a = try generator.generate(input: input(name: "Aria Sol"))
        let b = try generator.generate(input: input(name: "Aria Sol"))
        XCTAssertEqual(a.celestialName, b.celestialName)
        XCTAssertEqual(a, b)
    }

    func testDeterministicAcrossManyInvocations() throws {
        let generator = try makeGenerator()
        let baseline = try generator.generate(input: input(name: "Aria Sol"))
        for _ in 0..<25 {
            let again = try generator.generate(input: input(name: "Aria Sol"))
            XCTAssertEqual(again.celestialName, baseline.celestialName,
                           "The derived celestial name must be a stable function of its inputs")
        }
    }

    func testUnicodeNameIsDeterministicAndValid() throws {
        let generator = try makeGenerator()
        let a = try generator.generate(input: input(name: "José Álvarez Ñandú"))
        let b = try generator.generate(input: input(name: "José Álvarez Ñandú"))
        XCTAssertFalse(a.celestialName.isEmpty)
        XCTAssertEqual(a.celestialName.first?.isUppercase, true)
        XCTAssertEqual(a, b)
    }

    // MARK: - Non-lookup guarantee (a reference character is a fixture, never a name source)

    func testNoReferenceCharacterNameIsEverProduced() throws {
        let generator = try makeGenerator()
        // Reference fixtures from the source documents (two records disagree;
        // both are verification fixtures, never user identity).
        let reference = Set([
            "Nithruun", "Thal'Azur", "Kaelen Vareth",
            "Nythrun DalVhor", "Thalrion Aesyrune", "James John Daley III"
        ])
        // A varied, deterministic sample spread across planes, wolf categories,
        // heritages, and scripts (the seed is the mortal name).
        let samples: [SigilCelestialNameInput] = [
            input(name: "Aria Sol", heritage: ["germanic"], birthDate: "1977-11-04", birthTime: "12:00", hair: "blonde", eye: "blue"),
            input(name: "Bram Holt", heritage: ["scandinavian"], birthDate: "1979-07-25", birthTime: "03:15", hair: "black", eye: "brown"),
            input(name: "Cove Lind", heritage: ["celtic"], birthDate: "1994-01-01", birthTime: "22:40", hair: "red", eye: "green"),
            input(name: "Dara Vale", heritage: ["scandinavian", "celtic"], birthDate: "1985-05-19", birthTime: "18:33", hair: "light_brown", eye: "hazel"),
            input(name: "Elio Fenn", heritage: ["germanic", "celtic"], birthDate: "1990-12-31", birthTime: "06:30", hair: "dark_brown", eye: "blue"),
            input(name: "Faye Rost", heritage: ["celtic"], birthDate: "1982-09-09", birthTime: "14:08", hair: "grey_white", eye: "grey"),
            input(name: "José Álvarez Ñandú", heritage: ["scandinavian"], birthDate: "1977-11-04", birthTime: "12:00", hair: "blonde", eye: "blue"),
            input(name: "Iris Fell", heritage: ["germanic"], birthDate: "1988-03-03", birthTime: "10:00", hair: "black", eye: "brown")
        ]
        for sample in samples {
            let result = try generator.generate(input: sample)
            XCTAssertFalse(reference.contains(result.celestialName),
                           "A derived name reproduced a reference fixture name: \(result.celestialName)")
            XCTAssertFalse(result.celestialName.contains(" "),
                           "The derived name must be a single CamelCase token: \(result.celestialName)")
        }
    }

    // MARK: - Declared length preference

    func testNameRespectsLengthBounds() throws {
        let generator = try makeGenerator()
        for name in ["Aria Sol", "Bram Holt", "José Álvarez Ñandú"] {
            let result = try generator.generate(input: input(name: name))
            let count = Int(result.debugMetadata["syllable_count"] ?? "0") ?? 0
            XCTAssertTrue((2...4).contains(count),
                          "Syllable count \(count) is outside the declared 2...4 preference for seed \(name)")
        }
    }
}
