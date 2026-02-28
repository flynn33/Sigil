import Foundation
import RFCoreModels

public protocol EngineDataProviding: Sendable {
    var engineDataVersion: String { get }
    func loadLoreDataset() throws -> LoreDataset
    func loadGiftTableRawJSON() throws -> String
    func loadSigilCreationSpecRawJSON() throws -> String
    func loadCelestialNameGeneratorRawJSON() throws -> String
    func loadCodexGenerationRawJSON() throws -> String
}

public enum EngineDataError: Error {
    case missingResource(String)
    case invalidData(String)
}

public final class EngineDataStore: EngineDataProviding, Sendable {
    public let engineDataVersion: String

    public init(engineDataVersion: String = RFConstants.engineDataVersion) {
        self.engineDataVersion = engineDataVersion
    }

    public func loadLoreDataset() throws -> LoreDataset {
        let canonicalData = try resourceData(at: "data/cosmology/canonical-pattern-vectors.json")
        let runesData = try resourceData(at: "data/runes/elder-futhark-9bit.json")
        let planesData = try resourceData(at: "data/wrw-canon/nine-planes-of-existence.json")
        let axiomsData = try resourceData(at: "data/wrw-canon/axioms-of-existence.json")
        let mythicData = try resourceData(at: "data/wrw-canon/master-mythic-mapping.json")

        let decoder = JSONDecoder()
        let entitiesRoot = try decoder.decode(CanonicalEntitiesRoot.self, from: canonicalData)
        let runesRoot = try decoder.decode(RunesRoot.self, from: runesData)
        let planes = try decodePlanes(planesData, decoder: decoder)
        let axioms = try decodeAxioms(axiomsData, decoder: decoder)
        let mythicPrinciples = try decodeMythicPrinciples(mythicData, decoder: decoder)

        let entities = entitiesRoot.entities.map {
            LoreEntity(
                id: $0.id,
                name: $0.name,
                vector: .init(
                    H_entropy: $0.vector.H_entropy,
                    K_complexity: $0.vector.K_complexity,
                    D_fractal_dim: $0.vector.D_fractal_dim,
                    S_symmetry: $0.vector.S_symmetry,
                    L_generator_length: $0.vector.L_generator_length
                ),
                primaryPlane: $0.primaryPlane,
                notes: $0.notes
            )
        }

        let runes = runesRoot.runes.map {
            RuneDescriptor(
                id: $0.id,
                character: $0.char,
                name: $0.name,
                bits: $0.bits,
                parity: $0.parity,
                wolf: $0.wolf,
                meaning: $0.meaning
            )
        }

        return LoreDataset(
            canonicalEntities: entities,
            runes: runes,
            planes: planes,
            axioms: axioms,
            mythicPrinciples: mythicPrinciples
        )
    }

    public func loadGiftTableRawJSON() throws -> String {
        let data = try resourceData(at: "data/agent/public-gift-tables.json")
        guard let raw = String(data: data, encoding: .utf8) else {
            throw EngineDataError.invalidData("public-gift-tables.json utf8")
        }
        return raw
    }

    public func loadSigilCreationSpecRawJSON() throws -> String {
        let data = try resourceData(at: "data/agent/agent-sigil-creation.JSON")
        guard let raw = String(data: data, encoding: .utf8) else {
            throw EngineDataError.invalidData("agent-sigil-creation.JSON utf8")
        }
        return raw
    }

    public func loadCelestialNameGeneratorRawJSON() throws -> String {
        let data = try resourceData(at: "data/wrw-canon/celestial-name-generator.json")
        guard let raw = String(data: data, encoding: .utf8) else {
            throw EngineDataError.invalidData("celestial-name-generator.json utf8")
        }
        return raw
    }

    public func loadCodexGenerationRawJSON() throws -> String {
        let data = try resourceData(at: "data/wrw-canon/codex-generation.json")
        guard let raw = String(data: data, encoding: .utf8) else {
            throw EngineDataError.invalidData("codex-generation.json utf8")
        }
        return raw
    }

    private func resourceData(at resourcePath: String) throws -> Data {
        let fileName = (resourcePath as NSString).lastPathComponent

        if let resourceRoot = Bundle.module.resourceURL,
           let enumerator = FileManager.default.enumerator(at: resourceRoot, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator {
                if url.lastPathComponent == fileName {
                    return try Data(contentsOf: url)
                }
            }
        }

        throw EngineDataError.missingResource(resourcePath)
    }

    private func decodePlanes(_ data: Data, decoder: JSONDecoder) throws -> [PlaneCodex] {
        let root = try decoder.decode(PlanesRoot.self, from: data)
        return root.planes.map {
            PlaneCodex(
                id: $0.value.id,
                key: $0.key,
                name: $0.value.name,
                planeType: $0.value.type,
                role: $0.value.role,
                physics: $0.value.physics,
                storyMapping: $0.value.storyMapping
            )
        }
        .sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return lhs.key < rhs.key
            }
            return lhs.id < rhs.id
        }
    }

    private func decodeAxioms(_ data: Data, decoder: JSONDecoder) throws -> [AxiomCodex] {
        let root = try decoder.decode(AxiomsRoot.self, from: data)
        return root.axioms.map {
            AxiomCodex(
                id: $0.id,
                name: $0.name,
                summary: $0.summary,
                formal: $0.formal,
                storyImplications: $0.storyImplications
            )
        }
    }

    private func decodeMythicPrinciples(_ data: Data, decoder: JSONDecoder) throws -> [MythicPrinciple] {
        let root = try decoder.decode(MythicMappingRoot.self, from: data)

        return root.mythicMapping
            .sorted { $0.key < $1.key }
            .map { key, value in
                var statements: [String] = []
                statements.append(contentsOf: value.symbolism ?? [])
                statements.append(contentsOf: value.function ?? [])
                statements.append(contentsOf: value.cosmicCycle ?? [])
                statements.append(contentsOf: value.duties ?? [])

                for scalar in [
                    value.modelInterpretation,
                    value.roleInModel,
                    value.modelRole,
                    value.punishment,
                    value.redemptionPath,
                    value.failureCondition,
                    value.redemption,
                    value.nature
                ] {
                    if let scalar {
                        statements.append(scalar)
                    }
                }

                let nameTriplet = [value.primordialName, value.celestialName, value.mortalName]
                    .compactMap { $0 }
                if !nameTriplet.isEmpty {
                    statements.append("Identity: " + nameTriplet.joined(separator: " / "))
                }

                var planeRefs: [String] = []
                planeRefs.append(contentsOf: value.planes ?? [])
                planeRefs.append(contentsOf: value.planesOrigin ?? [])
                planeRefs.append(contentsOf: value.planesCurrent ?? [])
                if let planeHome = value.planeHome {
                    planeRefs.append(planeHome)
                }
                if let planeTarget = value.planeTarget {
                    planeRefs.append(planeTarget)
                }

                let description = value.description
                    ?? value.modelInterpretation
                    ?? value.roleInModel
                    ?? value.modelRole
                    ?? value.nature
                    ?? "Canonical mythic mapping entry."

                return MythicPrinciple(
                    id: key,
                    description: description,
                    planeRefs: uniqueOrdered(planeRefs),
                    statements: uniqueOrdered(statements)
                )
            }
    }

    private func uniqueOrdered(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            guard !value.isEmpty else { return false }
            if seen.contains(value) {
                return false
            }
            seen.insert(value)
            return true
        }
    }
}

private struct CanonicalEntitiesRoot: Codable {
    let entities: [CanonicalEntity]
}

private struct CanonicalEntity: Codable {
    let id: String
    let name: String
    let vector: CanonicalEntityVector
    let notes: String
    let primaryPlane: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case vector
        case notes
        case primaryPlane = "primary_plane"
    }
}

private struct CanonicalEntityVector: Codable {
    let H_entropy: Double
    let K_complexity: Double
    let D_fractal_dim: Double
    let S_symmetry: Double
    let L_generator_length: Int
}

private struct RunesRoot: Codable {
    let runes: [RuneRecord]
}

private struct RuneRecord: Codable {
    let id: String
    let char: String
    let name: String
    let bits: String
    let parity: String
    let wolf: String
    let meaning: String
}

private struct PlanesRoot: Codable {
    let planes: [String: PlaneRecord]
}

private struct PlaneRecord: Codable {
    let id: Int
    let name: String
    let type: String
    let role: String
    let physics: [String]
    let storyMapping: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case role
        case physics
        case storyMapping = "story_mapping"
    }
}

private struct AxiomsRoot: Codable {
    let axioms: [AxiomRecord]
}

private struct AxiomRecord: Codable {
    let id: String
    let name: String
    let summary: String
    let formal: String
    let storyImplications: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case formal
        case storyImplications = "story_implications"
    }
}

private struct MythicMappingRoot: Codable {
    let mythicMapping: [String: MythicRecord]

    enum CodingKeys: String, CodingKey {
        case mythicMapping = "mythic_mapping"
    }
}

private struct MythicRecord: Codable {
    let description: String?
    let symbolism: [String]?
    let planes: [String]?
    let function: [String]?
    let cosmicCycle: [String]?
    let modelInterpretation: String?
    let roleInModel: String?
    let modelRole: String?
    let planesOrigin: [String]?
    let planesCurrent: [String]?
    let planeHome: String?
    let planeTarget: String?
    let duties: [String]?
    let punishment: String?
    let redemptionPath: String?
    let failureCondition: String?
    let redemption: String?
    let nature: String?
    let primordialName: String?
    let celestialName: String?
    let mortalName: String?

    enum CodingKeys: String, CodingKey {
        case description
        case symbolism
        case planes
        case function
        case cosmicCycle = "cosmic_cycle"
        case modelInterpretation = "model_interpretation"
        case roleInModel = "role_in_model"
        case modelRole = "model_role"
        case planesOrigin = "planes_origin"
        case planesCurrent = "planes_current"
        case planeHome = "plane_home"
        case planeTarget = "plane_target"
        case duties
        case punishment
        case redemptionPath = "redemption_path"
        case failureCondition = "failure_condition"
        case redemption
        case nature
        case primordialName = "primordial_name"
        case celestialName = "celestial_name"
        case mortalName = "mortal_name"
    }
}
