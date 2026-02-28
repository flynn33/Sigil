import Testing
@testable import RFEngineData

@Test
func loadsBundledLoreData() throws {
    let store = EngineDataStore()
    let lore = try store.loadLoreDataset()
    #expect(!lore.canonicalEntities.isEmpty)
    #expect(!lore.runes.isEmpty)
    #expect(!lore.planes.isEmpty)
    #expect(!lore.axioms.isEmpty)
    #expect(!lore.mythicPrinciples.isEmpty)
    #expect(lore.planes.contains(where: { $0.id == 7 && $0.name == "Shadow" }))
    #expect(lore.axioms.contains(where: { $0.id == "A1" }))
    #expect(lore.mythicPrinciples.contains(where: { $0.id == "balance_principle" }))
}

@Test
func loadsSigilSpecSnapshot() throws {
    let store = EngineDataStore()
    let raw = try store.loadSigilCreationSpecRawJSON()
    #expect(raw.contains("sigil"))
    #expect(raw.contains("pattern_vector"))
}

@Test
func loadsCelestialNameGeneratorSnapshot() throws {
    let store = EngineDataStore()
    let raw = try store.loadCelestialNameGeneratorRawJSON()
    #expect(raw.contains("celestial_name_generator"))
    #expect(raw.contains("wolf_balance_rules"))
    #expect(raw.contains("syllables"))
}

@Test
func loadsCodexGenerationSnapshot() throws {
    let store = EngineDataStore()
    let raw = try store.loadCodexGenerationRawJSON()
    #expect(raw.contains("ASH_Personal_Codex_Compiler"))
    #expect(raw.contains("luciferian_detection_engine"))
    #expect(raw.contains("sigil_generator_engine"))
}
