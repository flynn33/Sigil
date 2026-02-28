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
func rotationalSymmetryProducesDenseDeterministicGeometry() throws {
    let service = DefaultSigilPipelineService()
    let result = try service.generate(profile: sampleProfile(), options: SigilOptions(includeTraitExtensions: true))

    #expect(result.geometry.lines.count >= 24)
    #expect(result.geometry.lines.count.isMultiple(of: 12))
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
