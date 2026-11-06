import Foundation

// MARK: - Nine-plane mathematical taxonomy (typed, product-owned)
//
// Encoded as typed product models from the supplied nine-planes source (source
// identity recorded in the canon manifest). Only the mathematical type and role
// per plane are embedded; the user-readable plane interpretation comes from the
// celestial generator's numerology prose. Two story-mapping phrases in the
// upstream source are omitted here for guardrail compliance (recorded, not
// concealed). Ordering is fixed P1-P9 (deterministic; never dictionary order).

/// A single plane's mathematical type and role.
public struct SigilNinePlane: Codable, Equatable, Hashable, Sendable {
    public let id: Int
    public let code: String
    public let name: String
    public let mathType: String
    public let role: String

    public init(id: Int, code: String, name: String, mathType: String, role: String) {
        self.id = id
        self.code = code
        self.name = name
        self.mathType = mathType
        self.role = role
    }
}

public enum SigilNinePlaneTaxonomy {
    /// Fixed P1-P9 ordering. The mathematical type is the upstream plane type;
    /// the role is the upstream plane role.
    public static let planes: [SigilNinePlane] = [
        SigilNinePlane(id: 1, code: "P1_Physical", name: "Physical", mathType: "spacetime_manifold", role: "Embodied incarnations and concrete cause and effect."),
        SigilNinePlane(id: 2, code: "P2_Etheric", name: "Etheric", mathType: "field_configuration_space", role: "Energy body and subtle template of physical forms."),
        SigilNinePlane(id: 3, code: "P3_Astral", name: "Astral", mathType: "symbolic_graph_space", role: "Dreams, images, archetypes, visions."),
        SigilNinePlane(id: 4, code: "P4_Mental", name: "Mental", mathType: "computational_state_space", role: "Thought, logic, structured models and internal narratives."),
        SigilNinePlane(id: 5, code: "P5_Causal", name: "Causal", mathType: "causal_DAG_or_poset", role: "Karma, narrative arcs, chains of cause and meaning."),
        SigilNinePlane(id: 6, code: "P6_Celestial", name: "Celestial", mathType: "attractor_manifolds", role: "High symmetry, high coherence, low internal conflict."),
        SigilNinePlane(id: 7, code: "P7_Shadow", name: "Shadow", mathType: "orthogonal_complement_and_kernels", role: "Repressed, unintegrated, conflicted structures."),
        SigilNinePlane(id: 8, code: "P8_Void", name: "Void", mathType: "unstructured_information_space", role: "Oblivion as unpatterned, uncompressed information."),
        SigilNinePlane(id: 9, code: "P9_Divine_Core", name: "Divine_Core", mathType: "category_of_worlds_and_terminal_object", role: "Architectural source that defines and relates all other planes.")
    ]

    public static func plane(code: String) -> SigilNinePlane? {
        planes.first { $0.code == code }
    }

    public static func plane(id: Int) -> SigilNinePlane? {
        planes.first { $0.id == id }
    }
}
