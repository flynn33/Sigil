import Foundation
import RFCoreModels

public protocol MythosCatalogProviding: Sendable {
    var respectNotice: String { get }
    func packs() -> [MythosPack]
}

public struct DefaultMythosCatalogService: MythosCatalogProviding, Sendable {
    public init() {}

    public var respectNotice: String {
        "Mythos packs are interpretive lenses in the Yggdrasil Model. Use symbols respectfully and avoid mocking, hate, or misrepresentation."
    }

    public func packs() -> [MythosPack] {
        [
            makePack(id: "angelic", title: "Angelic", symbolNames: ["Radiant Wing", "Halo Crest", "Seraph Seal", "Guardian Arc"]),
            makePack(id: "norse", title: "Norse", symbolNames: ["Knot of Oaths", "Raven Path", "Shield Mark", "Frost Rune"]),
            makePack(id: "hindu", title: "Hindu", symbolNames: ["Lotus Wheel", "Sacred Flame", "Temple Arc", "Mantra Knot"]),
            makePack(id: "christian", title: "Christian", symbolNames: ["Cross Star", "Shepherd Mark", "Covenant Arc", "Trinity Weave"]),
            makePack(id: "muslim", title: "Muslim", symbolNames: ["Crescent Gate", "Star Bloom", "Unity Arc", "Guidance Weave"]),
            makePack(id: "buddhist", title: "Buddhist", symbolNames: ["Dharma Wheel", "Lotus Path", "Balance Seal", "Mindful Arc"]),
            makePack(id: "celtic", title: "Celtic", symbolNames: ["Trinity Knot", "Spiral Gate", "Oak Sigil", "River Weave"]),
            makePack(id: "egyptian", title: "Egyptian", symbolNames: ["Solar Wing", "Nile Arc", "Ankh Crest", "Horizon Seal"]),
            makePack(id: "shinto", title: "Shinto", symbolNames: ["Torii Mark", "Kami Ring", "Purity Arc", "Shrine Path"]),
            makePack(id: "taoist", title: "Taoist", symbolNames: ["Harmony Disc", "Flow Arc", "Balance Gate", "Sky Weave"]),
            makePack(id: "yoruba", title: "Yoruba", symbolNames: ["Ancestral Ring", "Thunder Mark", "River Star", "Oath Arc"]),
            makePack(id: "mayan", title: "Mayan", symbolNames: ["Solar Step", "Temple Knot", "Jaguar Arc", "Calendar Seal"]),
            makeMythicPack()
        ]
    }

    private func makeMythicPack() -> MythosPack {
        MythosPack(
            id: "mythic",
            title: "Mythic Arcana",
            symbols: [
                MythosSymbol(
                    id: "mythic-1",
                    name: "Twin Wings",
                    packID: "mythic",
                    svgPath: "M 6 50 L 15 44 L 28 40 L 40 43 L 46 50 L 39 56 L 27 59 L 15 57 L 8 53 Z M 94 50 L 85 44 L 72 40 L 60 43 L 54 50 L 61 56 L 73 59 L 85 57 L 92 53 Z M 46 50 L 50 46 L 54 50 L 50 58 Z M 14 52 L 28 52 L 37 49 M 86 52 L 72 52 L 63 49"
                ),
                MythosSymbol(
                    id: "mythic-2",
                    name: "Infernal Gate",
                    packID: "mythic",
                    svgPath: "M 50 8 L 47 13 L 47 18 L 50 23 L 53 18 L 53 13 Z M 20 24 L 80 24 M 20 24 L 50 54 L 80 24 M 50 24 L 50 92 M 36 44 L 64 64 M 64 44 L 36 64 M 32 70 L 50 86 L 68 70 M 34 86 L 50 70 L 66 86 M 50 86 L 50 96 M 26 78 L 22 78 L 19 81 L 19 84 L 22 86 L 26 85 M 74 78 L 78 78 L 81 81 L 81 84 L 78 86 L 74 85"
                ),
                MythosSymbol(
                    id: "mythic-3",
                    name: "Crown Of Embers",
                    packID: "mythic",
                    svgPath: "M 26 34 L 36 22 L 50 34 L 64 22 L 74 34 L 74 42 L 26 42 Z M 32 42 L 32 52 L 68 52 L 68 42 Z"
                ),
                MythosSymbol(
                    id: "mythic-4",
                    name: "Serpent Flourish",
                    packID: "mythic",
                    svgPath: "M 36 70 L 31 75 L 25 75 L 21 71 L 21 66 L 25 62 L 30 62 L 35 66 L 40 70 M 64 70 L 69 75 L 75 75 L 79 71 L 79 66 L 75 62 L 70 62 L 65 66 L 60 70 M 42 66 L 58 66"
                )
            ]
        )
    }

    private func makePack(id: String, title: String, symbolNames: [String]) -> MythosPack {
        let basePaths = [
            "M 50 8 L 68 40 L 92 40 L 73 60 L 80 92 L 50 74 L 20 92 L 27 60 L 8 40 L 32 40 Z",
            "M 15 50 L 50 15 L 85 50 L 50 85 Z",
            "M 12 18 L 88 18 L 88 82 L 12 82 Z M 25 30 L 75 30 L 75 70 L 25 70 Z",
            "M 50 10 L 60 40 L 90 50 L 60 60 L 50 90 L 40 60 L 10 50 L 40 40 Z"
        ]

        let symbols = symbolNames.enumerated().map { index, name in
            MythosSymbol(
                id: "\(id)-\(index + 1)",
                name: name,
                packID: id,
                svgPath: basePaths[index % basePaths.count]
            )
        }

        return MythosPack(id: id, title: title, symbols: symbols)
    }
}
