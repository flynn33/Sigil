import Foundation

// MARK: - Canon loader (typed, validated, fail-closed)
//
// Loads the canon from the product-owned resource bundle:
//   1. Decode the canon manifest (the provenance registry).
//   2. For each "resource-raw" source, re-hash the shipped file and fail closed
//      if it does not match the manifest SHA-256 (the shipped data IS the
//      canonical data, or the load fails).
//   3. Decode the raw resources into typed models and structurally validate the
//      required tables (fail closed on missing or malformed tables).
//   4. Assemble the aggregate, combining the decoded resources with the typed
//      nine-plane taxonomy and the source registry.
//
// No field is substituted with a fabricated value: a missing or malformed
// required table is an error, not a default.

public struct SigilCanonLoader: Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? Bundle.module
    }

    /// Loads and validates the full canon resource. Throws `SigilCanonError` on
    /// any missing, mismatched, malformed, or structurally invalid source.
    public func load() throws -> SigilCanonResource {
        let manifest = try loadManifest()
        let celestialGenerator = try loadCelestialGenerator(manifest: manifest)
        let mythicMap = try loadMythicMap(manifest: manifest)
        let algorithmSpecificationSha256 = try sha256(ofSourceID: "celestial-gen-pseudo", manifest: manifest)

        // Typed-embedded sources are validated by presence in the manifest with a
        // recorded SHA; their data is compiled in and checked structurally below.
        try requireSource(id: "nine-planes", manifest: manifest)
        try requireSource(id: "wrw-ontology", manifest: manifest)
        try Self.validateNinePlaneTaxonomy()

        return SigilCanonResource(
            celestialGenerator: celestialGenerator,
            mythicMap: mythicMap,
            ninePlanes: SigilNinePlaneTaxonomy.planes,
            sources: manifest.sources,
            manifestVersion: manifest.version,
            algorithmSpecificationSha256: algorithmSpecificationSha256
        )
    }

    // MARK: Manifest

    private func loadManifest() throws -> SigilCanonManifest {
        guard let url = resourceURL(path: "canon/canon-manifest.json") else {
            throw SigilCanonError.manifestMissing
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw SigilCanonError.manifestMalformed("manifest could not be read")
        }
        do {
            return try Self.decoder().decode(SigilCanonManifest.self, from: data)
        } catch {
            throw SigilCanonError.manifestMalformed(String(describing: error))
        }
    }

    // MARK: Celestial generator

    private struct CelestialGeneratorRoot: Decodable {
        let celestialNameGenerator: Inner
        struct Inner: Decodable {
            let version: String
            let model: SigilCelestialGeneratorModel
            let algorithm: AlgorithmRef
            struct AlgorithmRef: Decodable { let version: String }
        }
    }

    private func loadCelestialGenerator(manifest: SigilCanonManifest) throws -> SigilCelestialGenerator {
        let data = try rawData(ofSourceID: "celestial-gen", manifest: manifest)
        do {
            let root = try Self.decoder().decode(CelestialGeneratorRoot.self, from: data)
            let generator = SigilCelestialGenerator(
                version: root.celestialNameGenerator.version,
                model: root.celestialNameGenerator.model,
                algorithmVersion: root.celestialNameGenerator.algorithm.version
            )
            try Self.validateCelestialGenerator(generator)
            return generator
        } catch let error as SigilCanonError {
            throw error
        } catch {
            throw SigilCanonError.decodeFailed(sourceID: "celestial-gen", detail: String(describing: error))
        }
    }

    // MARK: Mythic map

    private struct MythicMapRoot: Decodable {
        let mythicMapping: SigilMythicMap
    }

    private func loadMythicMap(manifest: SigilCanonManifest) throws -> SigilMythicMap {
        let data = try rawData(ofSourceID: "mythic-map", manifest: manifest)
        do {
            let root = try Self.decoder().decode(MythicMapRoot.self, from: data)
            return root.mythicMapping
        } catch {
            throw SigilCanonError.decodeFailed(sourceID: "mythic-map", detail: String(describing: error))
        }
    }

    // MARK: Resource I/O and integrity

    private func requireSource(id: String, manifest: SigilCanonManifest) throws {
        guard manifest.source(id: id) != nil else {
            throw SigilCanonError.invalidTable(sourceID: "manifest", table: "sources", reason: "missing source \(id)")
        }
    }

    private func sha256(ofSourceID id: String, manifest: SigilCanonManifest) throws -> String {
        guard let source = manifest.source(id: id) else {
            throw SigilCanonError.invalidTable(sourceID: "manifest", table: "sources", reason: "missing source \(id)")
        }
        try verifyHash(source: source, manifest: manifest)
        return source.sha256
    }

    private func rawData(ofSourceID id: String, manifest: SigilCanonManifest) throws -> Data {
        guard let source = manifest.source(id: id), let path = source.resourcePath else {
            throw SigilCanonError.resourceMissing(id)
        }
        try verifyHash(source: source, manifest: manifest)
        guard let url = resourceURL(path: path) else {
            throw SigilCanonError.resourceMissing(id)
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw SigilCanonError.decodeFailed(sourceID: id, detail: "resource could not be read")
        }
    }

    private func verifyHash(source: SigilCanonSource, manifest: SigilCanonManifest) throws {
        guard source.mode == .resourceRaw, let path = source.resourcePath, let url = resourceURL(path: path) else {
            return // typed-embedded sources are not re-hashed (compiled in)
        }
        guard let data = try? Data(contentsOf: url) else {
            throw SigilCanonError.resourceMissing(source.id)
        }
        let actual = SigilCanonHash.sha256Hex(data)
        guard actual.lowercased() == source.sha256.lowercased() else {
            throw SigilCanonError.resourceHashMismatch(sourceID: source.id)
        }
    }

    private func resourceURL(path: String) -> URL? {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let lastSlash = trimmed.lastIndex(of: "/")
        if let lastSlash {
            let sub = String(trimmed[trimmed.startIndex..<lastSlash])
            let fileName = String(trimmed[trimmed.index(after: lastSlash)...])
            // Try the declared subdirectory first (e.g. "canon/..."), then the
            // flattened bundle layout (SwiftPM `.process` places the shipped
            // files at the bundle root). Both resolve to the same resource.
            return bundle.url(forResource: fileName, withExtension: nil, subdirectory: sub)
                ?? urlForFull(fileName: fileName, subdirectory: sub)
                ?? bundle.url(forResource: fileName, withExtension: nil)
                ?? urlForFull(fileName: fileName, subdirectory: nil)
        }
        return bundle.url(forResource: trimmed, withExtension: nil, subdirectory: nil)
            ?? urlForFull(fileName: trimmed, subdirectory: nil)
    }

    private func urlForFull(fileName: String, subdirectory: String?) -> URL? {
        // Fallback that preserves an explicit extension when the resource path
        // includes one (e.g. "canon-manifest.json").
        let dot = fileName.lastIndex(of: ".")
        guard let dot, dot != fileName.startIndex else { return nil }
        let base = String(fileName[..<dot])
        let ext = String(fileName[fileName.index(after: dot)...])
        if let subdirectory {
            return bundle.url(forResource: base, withExtension: ext, subdirectory: subdirectory)
        }
        return bundle.url(forResource: base, withExtension: ext)
    }

    // MARK: Structural validation (fail closed)

    static func validateNinePlaneTaxonomy() throws {
        let planes = SigilNinePlaneTaxonomy.planes
        guard planes.count == 9 else {
            throw SigilCanonError.invalidTable(sourceID: "nine-planes", table: "planes", reason: "expected 9 planes, got \(planes.count)")
        }
        for expected in 1...9 where planes.first(where: { $0.id == expected }) == nil {
            throw SigilCanonError.invalidTable(sourceID: "nine-planes", table: "planes", reason: "missing plane id \(expected)")
        }
    }

    static func validateCelestialGenerator(_ g: SigilCelestialGenerator) throws {
        let m = g.model
        guard m.planes.count == 9 else {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "planes", reason: "expected 9 planes, got \(m.planes.count)")
        }
        for plane in m.planes where plane.numerologyValues.isEmpty {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "planes.\(plane.code)", reason: "empty numerology_values")
        }
        let requiredWeekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for day in requiredWeekdays where m.weekdayArchetypes[day] == nil {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "weekday_archetypes", reason: "missing \(day)")
        }
        let requiredHeritages = ["scandinavian", "celtic", "germanic", "generic_northern"]
        for family in requiredHeritages where m.heritageFamilies[family] == nil {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "heritage_families", reason: "missing \(family)")
        }
        if m.syllables.root.neutral.isEmpty {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "syllables.root.neutral", reason: "empty root syllables")
        }
        for code in (1...9).map({ "P\($0)" }) where m.syllables.plane[code]?.isEmpty ?? true {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "syllables.plane.\(code)", reason: "missing or empty plane syllables")
        }
        for (name, pool) in [("white", m.syllables.wolf.white), ("dark", m.syllables.wolf.dark), ("balanced", m.syllables.wolf.balanced)] where pool.isEmpty {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "syllables.wolf.\(name)", reason: "empty wolf syllables")
        }
        guard m.wolfBalanceRules.hairModifiers.isEmpty == false,
              m.wolfBalanceRules.eyeModifiers.isEmpty == false,
              m.wolfBalanceRules.birthTimeModifiers.isEmpty == false,
              m.wolfBalanceRules.lifePathModifiers.isEmpty == false else {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "wolf_balance_rules", reason: "missing a modifier table")
        }
        for code in (1...9).map({ "P\($0)" }) where m.numerologyFragments.planes[code] == nil {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "numerology_output_fragments.planes", reason: "missing \(code)")
        }
        for key in ["white_dominant", "dark_dominant", "balanced"] where m.numerologyFragments.wolfBalance[key] == nil {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "numerology_output_fragments.wolf_balance", reason: "missing \(key)")
        }
        for day in requiredWeekdays where m.numerologyFragments.weekday[day] == nil {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "numerology_output_fragments.weekday", reason: "missing \(day)")
        }
        guard m.epithetTemplates.isEmpty == false else {
            throw SigilCanonError.invalidTable(sourceID: "celestial-gen", table: "epithet_templates", reason: "no templates")
        }
    }

    private static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}

// MARK: - Manifest convenience

extension SigilCanonManifest {
    func source(id: String) -> SigilCanonSource? {
        sources.first { $0.id == id }
    }
}
