import Foundation

// MARK: - Master Mythic Mapping (typed, decoded from the shipped canonical resource)
//
// Decoded from the shipped master-mythic-mapping resource (source identity in
// the canon manifest). The decoded fields are the narrative canon the
// PersonalCodex uses for wolf balance, the balance principle, angels, lucifer,
// and the trials. The two reference-character entries in the source are
// intentionally NOT decoded into runtime models: a reference character is a
// verification fixture, never a user's celestial identity (see
// docs/design/canon-personalcodex.md, "Reference characters are not users").

/// A primordial wolf (White or Dark): symbolism, planes, and function. The two
/// wolves are complementary attractors, not moral poles.
public struct SigilWolfPrimordial: Codable, Equatable, Hashable, Sendable {
    public let description: String
    public let symbolism: [String]
    public let planes: [String]
    public let function: [String]

    public init(description: String, symbolism: [String], planes: [String], function: [String]) {
        self.description = description
        self.symbolism = symbolism
        self.planes = planes
        self.function = function
    }
}

/// The balance principle: the wolves are symbiotic dual attractors, not moral
/// opposites.
public struct SigilBalancePrinciple: Codable, Equatable, Hashable, Sendable {
    public let description: String
    public let cosmicCycle: [String]
    public let modelInterpretation: String

    public init(description: String, cosmicCycle: [String], modelInterpretation: String) {
        self.description = description
        self.cosmicCycle = cosmicCycle
        self.modelInterpretation = modelInterpretation
    }
}

public struct SigilAngels: Codable, Equatable, Hashable, Sendable {
    public let description: String
    public let planeHome: String
    public let planeTarget: String
    public let punishment: String
    public let redemptionPath: String

    public init(description: String, planeHome: String, planeTarget: String, punishment: String, redemptionPath: String) {
        self.description = description
        self.planeHome = planeHome
        self.planeTarget = planeTarget
        self.punishment = punishment
        self.redemptionPath = redemptionPath
    }
}

public struct SigilLucifer: Codable, Equatable, Hashable, Sendable {
    public let description: String
    public let planes: [String]
    public let duties: [String]
    public let modelRole: String

    public init(description: String, planes: [String], duties: [String], modelRole: String) {
        self.description = description
        self.planes = planes
        self.duties = duties
        self.modelRole = modelRole
    }
}

public struct SigilTrials: Codable, Equatable, Hashable, Sendable {
    public let description: String
    public let planes: [String]
    public let failureCondition: String
    public let redemption: String

    public init(description: String, planes: [String], failureCondition: String, redemption: String) {
        self.description = description
        self.planes = planes
        self.failureCondition = failureCondition
        self.redemption = redemption
    }
}

/// The decoded mythic mapping (narrative canon; character entries are not
/// decoded into runtime models).
public struct SigilMythicMap: Codable, Equatable, Hashable, Sendable {
    public let darkWolvesPrimordial: SigilWolfPrimordial
    public let whiteWolvesPrimordial: SigilWolfPrimordial
    public let balancePrinciple: SigilBalancePrinciple
    public let angels: SigilAngels
    public let lucifer: SigilLucifer
    public let trials: SigilTrials

    public init(
        darkWolvesPrimordial: SigilWolfPrimordial,
        whiteWolvesPrimordial: SigilWolfPrimordial,
        balancePrinciple: SigilBalancePrinciple,
        angels: SigilAngels,
        lucifer: SigilLucifer,
        trials: SigilTrials
    ) {
        self.darkWolvesPrimordial = darkWolvesPrimordial
        self.whiteWolvesPrimordial = whiteWolvesPrimordial
        self.balancePrinciple = balancePrinciple
        self.angels = angels
        self.lucifer = lucifer
        self.trials = trials
    }
}
