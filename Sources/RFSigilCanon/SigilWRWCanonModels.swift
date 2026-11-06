import Foundation

// MARK: - WRW (Where Ravens Wait) universal ontology semantics (typed, product-owned)
//
// Encoded as typed product models from the supplied WRW merged ontology
// (v2.0.0-luciferian-merged; source identity recorded in the canon manifest).
// These are the SEMANTICS the PersonalCodex enforces: the identity/bloodline/
// attunement/branching state machines and the explicit "forbidden" lists that
// double as interpretation guardrails. They are semantics, not a game runtime;
// unrelated game-loop mechanics are intentionally not brought into the product.

// MARK: Plane attunement semantics

/// A plane's attunement pressure state (a dynamic resonance state, not a fixed
/// class). A provenance-free or pressure-free score is forbidden upstream.
public enum SigilPlanePressureState: String, Codable, CaseIterable, Sendable {
    case dormant
    case latent
    case rising
    case dominant
    case unstable
    case integrated
}

public enum SigilPlaneTrend: String, Codable, CaseIterable, Sendable {
    case stable
    case increasing
    case decreasing
    case volatile
}

/// The full plane-attunement semantics (nine planes each carry a score in
/// 0...1, a pressure state, a trend, and source references).
public struct SigilWRWPlaneAttunementSemantics: Sendable {
    public static let pressureStates: [SigilPlanePressureState] = SigilPlanePressureState.allCases
    public static let trends: [SigilPlaneTrend] = SigilPlaneTrend.allCases
    public static let forbidden: [String] = [
        "fixed_plane_class",
        "provenance_free_score"
    ]
}

// MARK: Celestial identity semantics

/// Celestial identity reveal states: identity begins veiled and is revealed
/// through history; it is never a static class.
public enum SigilCelestialIdentityState: String, Codable, CaseIterable, Sendable {
    case veiled
    case suspected
    case fragmented
    case namedFragment = "named_fragment"
    case partialRevelation = "partial_revelation"
    case coherentRevelation = "coherent_revelation"
    case integrated
}

public struct SigilWRWCelestialIdentitySemantics: Sendable {
    public static let identityStates: [SigilCelestialIdentityState] = SigilCelestialIdentityState.allCases
    /// Fragment kinds a celestial identity may accumulate before reveal.
    public static let fragmentKinds: [String] = [
        "name_syllable", "memory", "symbol", "role",
        "plane_echo", "wolf_echo", "bloodline_echo", "prophecy_echo", "artifact_echo"
    ]
    public static let forbidden: [String] = [
        "identity_reveal_without_evidence",
        "static_class_lock",
        "celestial_identity_as_mortal_name"
    ]
}

// MARK: Bloodline / heritage resonance semantics

public enum SigilBloodlineStatus: String, Codable, CaseIterable, Sendable {
    case unknown
    case dormant
    case suspected
    case active
    case awakened
    case unstable
    case integrated
}

public enum SigilBloodlineStability: String, Codable, CaseIterable, Sendable {
    case stable
    case rising
    case declining
    case unstable
    case contained
}

/// Bloodline resonance is lineage pressure with per-signal status, score,
/// stability, and source references; it is NOT a deterministic biological
/// destiny claim and never a static class lock.
public struct SigilWRWBloodlineResonanceSemantics: Sendable {
    public static let statuses: [SigilBloodlineStatus] = SigilBloodlineStatus.allCases
    public static let stabilities: [SigilBloodlineStability] = SigilBloodlineStability.allCases
    public static let forbidden: [String] = [
        "bloodline_as_static_class_lock",
        "bloodline_reveal_without_evidence",
        "faction_claim_as_automatic_truth"
    ]
}

// MARK: Branching dynamics semantics

/// Choice significance levels for a bounded branch echo.
public enum SigilBranchSignificance: String, Codable, CaseIterable, Sendable {
    case minor
    case meaningful
    case major
    case threshold
    case cosmological
}

/// Bounded branching semantics. Mortal-level choice induces branching of
/// histories; a PersonalCodex expresses this as bounded symbolic interpretation,
/// never as a simulated or fabricated life history.
public struct SigilWRWBranchingSemantics: Sendable {
    public static let significanceLevels: [SigilBranchSignificance] = SigilBranchSignificance.allCases
    public static let qualifiers: [String] = [
        "truth_revealed_or_concealed",
        "oath_made_broken_or_bound",
        "bloodline_awakening",
        "wolf_resonance_shift",
        "plane_attunement_threshold",
        "life_death_consequence",
        "shadow_void_celestial_threshold_event",
        "location_threshold_crossing"
    ]
    public static let forbidden: [String] = [
        "every_input_action_is_branch_event",
        "branch_event_as_randomizer_only",
        "branch_event_without_player_consequence",
        "branch_event_without_cosmology_provenance",
        "branch_event_mutates_base_ontology"
    ]
}

// MARK: Pattern-vector model and existence physics

/// The five-dimensional pattern-vector model (information-theoretic and
/// structural profile of an entity).
public struct SigilWRWPatternVectorModel: Sendable {
    public struct Component: Sendable {
        public let key: String
        public let interpretation: String
        public init(key: String, interpretation: String) {
            self.key = key
            self.interpretation = interpretation
        }
    }
    public static let components: [Component] = [
        Component(key: "H_entropy", interpretation: "How disordered or spread out the internal state is."),
        Component(key: "K_algorithmic_complexity", interpretation: "How hard it is to describe the entity as a program."),
        Component(key: "D_fractal_dimension", interpretation: "How branching and scale-rich its structure is."),
        Component(key: "S_symmetry_index", interpretation: "How balanced and ordered its structure is."),
        Component(key: "L_generator_length", interpretation: "Length or complexity of the core rules that generate it.")
    ]
}

/// Existence-potential physics. The existence potential Phi is
/// Phi = a1*C + a2*S + a3*P - a4*H (compressibility, symmetry, persistence,
/// minus entropy); existence is conserved across transformations.
public struct SigilWRWExistencePhysics: Sendable {
    public static let phiFormula = "Phi = a1*C + a2*S + a3*P - a4*H"
    public static let phiTerms: [String: String] = [
        "C": "compressibility",
        "S": "symmetry",
        "P": "persistence",
        "H": "entropy"
    ]
    public static let quantizationLevels: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    public static let conservationLaw = "d/dt of the integral of E over space equals 0"
}

// MARK: Axioms A1-A6 (semantic summaries)

public struct SigilWRWAxiom: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let summary: String

    public init(id: String, name: String, summary: String) {
        self.id = id
        self.name = name
        self.summary = summary
    }
}

public enum SigilWRWAxioms {
    public static let all: [SigilWRWAxiom] = [
        SigilWRWAxiom(id: "A1", name: "Relational_Existence", summary: "An entity exists in a world only if it participates in at least one relation with another entity."),
        SigilWRWAxiom(id: "A2", name: "Structural_Compressibility", summary: "An entity is a real pattern if its description can be compressed into a shorter rule set than its raw data."),
        SigilWRWAxiom(id: "A3", name: "Multi_Scale_Persistence", summary: "A real entity persists as a recognizable pattern across time and scale."),
        SigilWRWAxiom(id: "A4", name: "Energetic_Cost_of_Erasure", summary: "Erasing a structured pattern requires non-zero energy; structure that costs nothing to erase is not physically instantiated."),
        SigilWRWAxiom(id: "A5", name: "Self_Reference_for_Consciousness", summary: "A system is conscious if it contains a substructure that models itself and updates that model in response to its own state."),
        SigilWRWAxiom(id: "A6", name: "Branching_Choice_Realization", summary: "Whenever a conscious mortal agent faces a genuine choice, the underlying world state branches into distinct, decoherent histories realizing each option.")
    ]
}
