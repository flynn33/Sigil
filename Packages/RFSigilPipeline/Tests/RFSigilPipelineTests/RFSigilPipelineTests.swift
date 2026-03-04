import CryptoKit
import Foundation
import RFCoreModels
import Testing
@testable import RFSigilPipeline

@Test
func pipelineIsDeterministicForSameInput() throws {
    let service = DefaultSigilPipelineService()
    let profile = sampleProfile()

    let first = try service.generate(profile: profile, options: SigilOptions(includeTraitExtensions: true))
    let second = try service.generate(profile: profile, options: SigilOptions(includeTraitExtensions: true))

    #expect(first.vector == second.vector)
    #expect(first.bits9 == second.bits9)
    #expect(first.geometryHash == second.geometryHash)
    #expect(first.celestialName == second.celestialName)
    #expect(first.lsystem == second.lsystem)
}

@Test
func distinctCorePersonalInputsProduceDifferentSigils() throws {
    let service = DefaultSigilPipelineService()

    let inputA = UserProfileInput(
        firstName: "Alicia",
        lastName: "Wolfsbane",
        birthDate: "1990-07-15",
        birthTime: "12:00",
        birthOrder: 2,
        motherBirthOrder: 1,
        fatherBirthOrder: 3,
        petNames: ["Fen"],
        significantNumbers: [],
        additionalStrings: [],
        birthLatitude: 47.6062,
        birthLongitude: -122.3321
    )

    let inputB = UserProfileInput(
        firstName: "Marcus",
        lastName: "Ravenshield",
        birthDate: "1983-11-02",
        birthTime: "04:35",
        birthOrder: 4,
        motherBirthOrder: 2,
        fatherBirthOrder: 6,
        petNames: ["Nyx"],
        significantNumbers: [],
        additionalStrings: [],
        birthLatitude: 34.0522,
        birthLongitude: -118.2437
    )

    let resultA = try service.generateSigilResult(input: inputA)
    let resultB = try service.generateSigilResult(input: inputB)

    #expect(resultA.vector != resultB.vector)
    #expect(resultA.geometryHash != resultB.geometryHash)
}

@Test
func bitsAndParityFollow9DBuildRules() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    #expect(result.bits9.bits.count == 9)

    let ones = result.bits9.bits.filter { $0 == "1" }.count
    let expectedParity: SigilParity = ones.isMultiple(of: 2) ? .even : .odd
    #expect(result.bits9.parity == expectedParity)
}

@Test
func geometryNormalizesToUnitBounds() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    #expect(!result.geometry.lines.isEmpty)

    for line in result.geometry.lines {
        #expect((0.0...1.0).contains(line.startX))
        #expect((0.0...1.0).contains(line.startY))
        #expect((0.0...1.0).contains(line.endX))
        #expect((0.0...1.0).contains(line.endY))
    }
}

@Test
func portable9DProjectionProducesDenseGeometry() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    #expect(result.geometry.lines.count >= 400)
    #expect(result.geometry.lines.count <= 8_000)
}

@Test
func optionalTraitsInfluenceGenerationWhenEnabled() throws {
    let service = DefaultSigilPipelineService()
    var profileA = sampleProfile()
    var profileB = sampleProfile()
    profileA.traits.petNames = []
    profileB.traits.petNames = []

    profileA.traits.additionalTraits["totem"] = "Raven"
    profileA.traits.dynamicFieldValues["badge_number"] = "4172"
    profileA.traits.professions = [
        ProfessionEntry(
            profession: "Police Officer",
            titleOrPosition: "Patrol Sergeant",
            yearsInProfession: 20,
            customItemLabel: "Badge Number",
            customItemValue: "4172"
        )
    ]

    profileB.traits.additionalTraits["totem"] = "Wolf"
    profileB.traits.dynamicFieldValues["badge_number"] = "9921"
    profileB.traits.professions = [
        ProfessionEntry(
            profession: "IT",
            titleOrPosition: "Systems Engineer",
            yearsInProfession: 8,
            customItemLabel: "Cert",
            customItemValue: "AWS-SAA"
        )
    ]

    let resultA = try service.generate(profile: profileA, options: SigilOptions(includeTraitExtensions: true))
    let resultB = try service.generate(profile: profileB, options: SigilOptions(includeTraitExtensions: true))

    #expect(resultA.vector != resultB.vector)
    #expect(resultA.geometryHash != resultB.geometryHash)
}

@Test
func optionalTraitsCanBeIgnoredViaOptions() throws {
    let service = DefaultSigilPipelineService()
    var profileA = sampleProfile()
    var profileB = sampleProfile()
    profileA.traits.petNames = []
    profileB.traits.petNames = []

    profileA.traits.additionalTraits["totem"] = "Raven"
    profileA.traits.dynamicFieldValues["badge_number"] = "4172"

    profileB.traits.additionalTraits["totem"] = "Wolf"
    profileB.traits.dynamicFieldValues["badge_number"] = "9921"

    let resultA = try service.generate(profile: profileA, options: SigilOptions(includeTraitExtensions: false))
    let resultB = try service.generate(profile: profileB, options: SigilOptions(includeTraitExtensions: false))

    #expect(resultA.vector == resultB.vector)
    #expect(resultA.geometryHash == resultB.geometryHash)
}

@Test
func extensionToggleChangesOutputWhenExtensionSignalsExist() throws {
    let service = DefaultSigilPipelineService()
    var profile = sampleProfile()
    profile.traits.petNames = []

    let canonical = try service.generate(profile: profile, options: SigilOptions(includeTraitExtensions: false))
    let extended = try service.generate(profile: profile, options: SigilOptions(includeTraitExtensions: true))

    #expect(canonical.vector != extended.vector)
    #expect(canonical.geometryHash != extended.geometryHash)
}

@Test
func userPhysicalTraitsInfluenceCanonicalGeneration() throws {
    let service = DefaultSigilPipelineService()
    var profileA = sampleProfile()
    var profileB = sampleProfile()

    profileA.userHairColor = "Brown"
    profileA.userEyeColor = "Hazel"
    profileA.userHeightCentimeters = 170

    profileB.userHairColor = "Black"
    profileB.userEyeColor = "Blue"
    profileB.userHeightCentimeters = 189

    let resultA = try service.generate(profile: profileA, options: SigilOptions(includeTraitExtensions: false))
    let resultB = try service.generate(profile: profileB, options: SigilOptions(includeTraitExtensions: false))

    #expect(resultA.vector != resultB.vector)
    #expect(resultA.geometryHash != resultB.geometryHash)
}

@Test
func singleFieldChangeAltersSigilGeometry() throws {
    let service = DefaultSigilPipelineService()
    let inputA = UserProfileInput(
        firstName: "James",
        lastName: "Daley",
        birthDate: "1985-03-14",
        birthTime: "09:42",
        birthOrder: 3,
        motherBirthOrder: 3,
        fatherBirthOrder: 7,
        userHairColor: "Brown",
        userEyeColor: "Hazel",
        userHeightCentimeters: 180,
        petNames: ["Fen"],
        significantNumbers: [7, 9, 20],
        additionalStrings: ["Norse", "Celtic", "Raven"],
        birthLatitude: 47.6062,
        birthLongitude: -122.3321
    )
    var inputB = inputA
    inputB.userEyeColor = "Blue"

    let resultA = try service.generateSigilResult(input: inputA)
    let resultB = try service.generateSigilResult(input: inputB)

    #expect(resultA.vector != resultB.vector)
    #expect(resultA.geometryHash != resultB.geometryHash)
}

@Test
func regenerateGeometryMatchesGeneratedVectorGeometry() throws {
    let service = DefaultSigilPipelineService()
    let generated = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    let regenerated = try service.regenerateGeometry(from: generated.vector)
    #expect(regenerated == generated.geometry)
}

@Test
func unsupportedPipelineVersionFailsRegeneration() throws {
    let service = DefaultSigilPipelineService()
    let vector = CanonicalVector(
        H_entropy: 0.35,
        K_complexity: 0.62,
        D_fractal_dim: 2.1,
        S_symmetry: 0.44,
        L_generator_length: 222
    )

    do {
        _ = try service.regenerateGeometry(from: vector, pipelineVersion: "rf.pipeline.v99")
        Issue.record("Expected unsupported pipeline version error")
    } catch SigilPipelineError.unsupportedPipelineVersion(let version) {
        #expect(version == "rf.pipeline.v99")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func publicInputApiIsDeterministic() throws {
    let service = DefaultSigilPipelineService()
    let input = UserProfileInput(
        firstName: "James",
        lastName: "Daley",
        birthDate: "1985-03-14",
        birthTime: "09:42",
        birthOrder: 3,
        motherBirthOrder: 3,
        fatherBirthOrder: 7,
        petNames: ["Fen", "Ash"],
        significantNumbers: [7, 9, 20],
        additionalStrings: ["Norse", "Celtic", "Raven"],
        birthLatitude: 47.6062,
        birthLongitude: -122.3321
    )

    let first = try service.generateSigilResult(input: input)
    let second = try service.generateSigilResult(input: input)

    #expect(first.vector == second.vector)
    #expect(first.bits9 == second.bits9)
    #expect(first.geometryHash == second.geometryHash)
}

@Test
func planeEstimatorRemainsBounded() {
    let vector = CanonicalVector(
        H_entropy: 0.4,
        K_complexity: 0.5,
        D_fractal_dim: 2.2,
        S_symmetry: 0.6,
        L_generator_length: 123
    )

    let service = DefaultSigilPipelineService()
    let plane = service.estimatePlane(for: vector)
    #expect((1...9).contains(plane))
}

@Test
func nonFiniteCoordinatesAreHandledSafely() throws {
    let service = DefaultSigilPipelineService()
    let input = UserProfileInput(
        firstName: "Alicia",
        lastName: "Wolfsbane",
        birthDate: "1990-07-15",
        birthTime: "12:00",
        birthOrder: 2,
        motherBirthOrder: 1,
        fatherBirthOrder: 3,
        petNames: ["Fen", "Ash"],
        significantNumbers: [7, 9, 20],
        additionalStrings: ["Raven"],
        birthLatitude: .nan,
        birthLongitude: .infinity
    )

    let result = try service.generateSigilResult(input: input)
    #expect(result.vector.S_symmetry.isFinite)
    #expect(!result.geometry.lines.isEmpty)
}

@Test
func geometrySizeIsBoundedForStability() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    #expect(result.geometry.lines.count <= 100_000)
}

@Test
func highVarianceInputsYieldDistinctGeometryHashes() throws {
    let service = DefaultSigilPipelineService()
    let variants: [(first: String, last: String, hair: String, eye: String, height: Int, lat: Double, lon: Double)] = [
        ("Alicia", "Wolfsbane", "Brown", "Hazel", 170, 47.6062, -122.3321),
        ("Marcus", "Ravenshield", "Black", "Blue", 189, 34.0522, -118.2437),
        ("Nora", "Frost", "Blonde", "Green", 165, 41.8781, -87.6298),
        ("Elias", "Crowe", "Auburn", "Gray", 181, 29.7604, -95.3698),
        ("Selene", "Vale", "Red", "Amber", 172, 25.7617, -80.1918),
        ("Jonas", "Stone", "Brown", "Brown", 177, 39.7392, -104.9903),
        ("Mira", "Ashford", "Black", "Hazel", 160, 33.4484, -112.0740),
        ("Theo", "Draven", "Sandy", "Blue", 185, 32.7157, -117.1611),
        ("Aria", "Night", "Platinum", "Violet", 168, 45.5152, -122.6784),
        ("Orin", "Dusk", "Chestnut", "Green", 174, 42.3601, -71.0589),
        ("Leona", "Myers", "Copper", "Gray", 171, 36.1699, -115.1398),
        ("Kieran", "Blake", "Dark Brown", "Honey", 183, 40.7128, -74.0060)
    ]

    let hashes = try Set(
        variants.enumerated().map { index, variant in
            let input = UserProfileInput(
                firstName: variant.first,
                lastName: variant.last,
                birthDate: "1990-07-\(String(format: "%02d", (index % 28) + 1))",
                birthTime: "1\(index % 10):\(String(format: "%02d", (index * 7) % 60))",
                birthOrder: (index % 6) + 1,
                motherBirthOrder: ((index + 2) % 7) + 1,
                fatherBirthOrder: ((index + 4) % 8) + 1,
                userHairColor: variant.hair,
                userEyeColor: variant.eye,
                userHeightCentimeters: variant.height,
                petNames: ["PET\(index)"],
                significantNumbers: [7 + index, 13 + index],
                additionalStrings: ["TOTEM\(index)"],
                birthLatitude: variant.lat,
                birthLongitude: variant.lon
            )
            return try service.generateSigilResult(input: input).geometryHash
        }
    )

    #expect(hashes.count >= 10)
}

@Test
func generatedGeometryMaintainsDirectionalSpread() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))
    let lines = result.geometry.lines
    #expect(!lines.isEmpty)

    let binCount = 24
    var bins = Array(repeating: 0, count: binCount)
    var measured = 0

    for line in lines {
        let dx = line.endX - line.startX
        let dy = line.endY - line.startY
        let length2 = dx * dx + dy * dy
        guard length2 > 1e-12 else { continue }
        let theta = atan2(dy, dx)
        let normalized = (theta + Double.pi) / (2.0 * Double.pi)
        let bin = Int(floor(normalized * Double(binCount))).clamped(to: 0...(binCount - 1))
        bins[bin] += 1
        measured += 1
    }

    #expect(measured > 0)
    let occupied = bins.filter { $0 > 0 }.count
    #expect(occupied >= 8)
    if let dominant = bins.max() {
        let dominantRatio = Double(dominant) / Double(max(1, measured))
        #expect(dominantRatio < 0.60)
    } else {
        Issue.record("Expected non-empty direction bins")
    }
}

@Test
func geometryNormalizerMapsCartesianYToScreenY() {
    let normalizer = GeometryNormalizer()
    let geometry = normalizer.normalize(
        segments: [SigilLine(startX: 0.0, startY: 1.0, endX: 0.0, endY: -1.0)],
        canvas: CGSize(width: 100.0, height: 100.0),
        padding: 0.0
    )

    #expect(geometry.lines.count == 1)
    guard let line = geometry.lines.first else {
        Issue.record("Expected one normalized line")
        return
    }

    #expect(line.startY < line.endY)
}

@Test
func geometryMatchesPortable9DProjectionSpecPath() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    let builder = PortableSigil9DGeometryBuilder()
    let normalizer = GeometryNormalizer()
    let projected = builder.buildSegments(vector: result.vector)
    let seed64 = deterministicSeed64(for: result.vector)
    let coreSeed = UInt64(result.bits9.bits, radix: 2) ?? 0
    let geometrySeed = seed64 ^ coreSeed
    let sampled = deterministicSample(projected, maxCount: 8_000, seed64: geometrySeed)
    let normalized = normalizer.normalize(
        segments: sampled,
        canvas: CGSize(width: 1024.0, height: 1024.0),
        padding: 0.10
    )

    #expect(result.geometry == normalized)
}

private func deterministicSeed64(for vector: CanonicalVector) -> UInt64 {
    let serialized = vector.canonicalSerialized()
    let digest = Array(SHA256.hash(data: Data(serialized.utf8)))
    guard digest.count >= 32 else { return 0x9E37_79B9_7F4A_7C15 }

    let high = digest[16..<24].reduce(UInt64(0)) { partial, byte in
        (partial << 8) | UInt64(byte)
    }
    let low = digest[24..<32].reduce(UInt64(0)) { partial, byte in
        (partial << 8) | UInt64(byte)
    }
    let folded = high ^ low
    return folded == 0 ? 0x9E37_79B9_7F4A_7C15 : folded
}

private func deterministicSample(_ segments: [SigilLine], maxCount: Int, seed64: UInt64) -> [SigilLine] {
    guard maxCount > 0, segments.count > maxCount else { return segments }
    var indices = Array(segments.indices)
    var rng = XorShift64Star(seed: seed64 == 0 ? 0x9E37_79B9_7F4A_7C15 : seed64)
    let count = indices.count

    for i in 0..<maxCount {
        let remaining = count - i
        let j = i + rng.nextInt(max(1, remaining))
        indices.swapAt(i, j)
    }

    let selected = Array(indices.prefix(maxCount)).sorted()
    return selected.map { segments[$0] }
}

private struct XorShift64Star {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2_685_821_657_736_338_717
    }

    mutating func nextInt(_ upperBound: Int) -> Int {
        guard upperBound > 1 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
}

private func sampleProfile() -> PersonProfile {
    var components = DateComponents()
    components.year = 1990
    components.month = 7
    components.day = 15
    components.hour = 12
    components.minute = 0

    let date = Calendar(identifier: .gregorian).date(from: components)!

    return PersonProfile(
        givenName: "Alicia",
        familyName: "Wolfsbane",
        birthDetails: BirthDetails(date: date, isTimeUnknown: false),
        birthOrder: 2,
        birthplaceName: "Seattle",
        birthplace: GeoPoint(latitude: 47.6062, longitude: -122.3321),
        userHairColor: "Brown",
        userEyeColor: "Hazel",
        userHeightCentimeters: 170,
        mother: ParentTraits(birthOrder: 1, hairColor: "Brown", eyeColor: "Hazel"),
        father: ParentTraits(birthOrder: 3, hairColor: "Black", eyeColor: "Blue"),
        traits: TraitBundle(
            familyNames: ["Wolfsbane", "Dale"],
            heritage: ["Norse", "Celtic"],
            petNames: ["Fen", "Ash"],
            professions: [],
            hobbiesInterests: ["Archery"],
            additionalTraits: ["lucky_number": "7"]
        )
    )
}
