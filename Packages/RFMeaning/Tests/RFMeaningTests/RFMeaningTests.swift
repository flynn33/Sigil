import Foundation
import RFCoreModels
import RFEngineData
import Testing
@testable import RFMeaning

@Test
func meaningIncludesCelestialNameAndSections() throws {
    let engine = EngineDataStore()
    let lore = try engine.loadLoreDataset()

    let result = SigilResult(
        profileID: UUID(),
        vector: CanonicalVector(H_entropy: 0.45, K_complexity: 0.55, D_fractal_dim: 2.2, S_symmetry: 0.66, L_generator_length: 224),
        bits9: SigilBits9(bits: "101010101", parity: .odd),
        celestialName: "Thal Rion Kael Void",
        lsystem: LSystemDefinition(axiom: "X", rules: ["F": "F"], angle: 42, iterations: 4),
        geometry: SigilGeometry(lines: []),
        geometryHash: "hash",
        pipelineVersion: RFConstants.pipelineVersion,
        engineDataVersion: RFConstants.engineDataVersion
    )

    let service = DefaultMeaningService()
    let narrative = service.composeMeaning(from: result, loreData: lore)

    #expect(narrative.celestialName == "Thal Rion Kael Void")
    #expect(narrative.sections.count >= 6)
    #expect(narrative.summary.contains("Plane"))
    #expect(narrative.summary.contains("Life Path"))
    #expect(narrative.sections.contains(where: { $0.contains("Canonical Axiom") }))
    #expect(narrative.sections.contains(where: { $0.contains("Codex Origin") }))
    #expect(narrative.sections.contains(where: { $0.contains("Personal Prophecy") }))
    #expect(narrative.sections.contains(where: { $0.contains("Numerology Core Matrix") }))
    #expect(narrative.sections.contains(where: { $0.contains("Numerology Channel Reading") }))
    #expect(narrative.sections.contains(where: { $0.contains("Numerology Synthesis") }))
}

@Test
func canonicalAxiomNamesAreUserReadable() throws {
    let engine = EngineDataStore()
    let lore = try engine.loadLoreDataset()

    // This vector resolves to plane 5 in DefaultMeaningService. Plane mapping then selects axiom index 4 (A5).
    let result = SigilResult(
        profileID: UUID(),
        vector: CanonicalVector(H_entropy: 0.5, K_complexity: 0.5, D_fractal_dim: 2.0, S_symmetry: 0.5, L_generator_length: 224),
        bits9: SigilBits9(bits: "010101010", parity: .even),
        celestialName: "Vale Orin",
        lsystem: LSystemDefinition(axiom: "X", rules: ["F": "F"], angle: 40, iterations: 3),
        geometry: SigilGeometry(lines: []),
        geometryHash: "hash",
        pipelineVersion: RFConstants.pipelineVersion,
        engineDataVersion: RFConstants.engineDataVersion
    )

    let service = DefaultMeaningService()
    let narrative = service.composeMeaning(from: result, loreData: lore)
    let axiomLine = narrative.sections.first(where: { $0.contains("Canonical Axiom") }) ?? ""

    #expect(!axiomLine.isEmpty)
    #expect(axiomLine.contains("Self Reference for Consciousness"))
    #expect(!axiomLine.contains("Self_Reference_for_Consciousness"))
    #expect(axiomLine.contains("Idiom Meaning"))
    #expect(axiomLine.contains("Your Sigil Application"))
    #expect(!axiomLine.localizedCaseInsensitiveContains("narrator"))
    #expect(!axiomLine.localizedCaseInsensitiveContains("kaelen"))

    let combined = ([narrative.summary] + narrative.sections).joined(separator: " ")
    #expect(combined.contains("Integration digit"))
    #expect(!combined.localizedCaseInsensitiveContains("narrator"))
    #expect(!combined.localizedCaseInsensitiveContains("kaelen"))
    #expect(!combined.localizedCaseInsensitiveContains("kalean"))
    #expect(!combined.localizedCaseInsensitiveContains("authun"))
}
