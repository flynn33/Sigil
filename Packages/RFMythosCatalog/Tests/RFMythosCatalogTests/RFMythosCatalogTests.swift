import Testing
@testable import RFMythosCatalog

@Test
func defaultCatalogProvidesCorePacks() {
    let service = DefaultMythosCatalogService()
    let packs = service.packs()

    #expect(packs.count >= 10)
    #expect(packs.allSatisfy { $0.symbols.count >= 3 })
    #expect(service.respectNotice.contains("respectfully"))
}

@Test
func mythicArcanaPackProvidesWingedGateSymbols() {
    let service = DefaultMythosCatalogService()
    let packs = service.packs()
    let mythic = packs.first(where: { $0.id == "mythic" })

    #expect(mythic != nil)
    #expect(mythic?.symbols.contains(where: { $0.id == "mythic-1" }) == true)
    #expect(mythic?.symbols.contains(where: { $0.id == "mythic-2" }) == true)
    #expect(mythic?.symbols.contains(where: { $0.id == "mythic-4" }) == true)
}
