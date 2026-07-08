import Foundation

public struct ASHAuthorityStatus: Codable, Hashable, Sendable {
    public let status: RFSigilStatusKind
    public let foundationStatement: String

    public init(status: RFSigilStatusKind, foundationStatement: String) {
        self.status = status
        self.foundationStatement = foundationStatement
    }
}

public struct YWEAuthorityStatus: Codable, Hashable, Sendable {
    public let readmeRead: Bool
    public let authorityContractsRead: Bool
    public let hierarchyPreserved: Bool
    public let implementationState: String
    public let status: RFSigilStatusKind

    public init(
        readmeRead: Bool,
        authorityContractsRead: Bool,
        hierarchyPreserved: Bool,
        implementationState: String,
        status: RFSigilStatusKind
    ) {
        self.readmeRead = readmeRead
        self.authorityContractsRead = authorityContractsRead
        self.hierarchyPreserved = hierarchyPreserved
        self.implementationState = implementationState
        self.status = status
    }
}

public struct WRWCanonStatus: Codable, Hashable, Sendable {
    public let canonResourcesVisible: Bool
    public let loreGenerationImplemented: Bool
    public let shouldBeFalseInPhase1: Bool
    public let status: RFSigilStatusKind

    public init(
        canonResourcesVisible: Bool,
        loreGenerationImplemented: Bool,
        shouldBeFalseInPhase1: Bool,
        status: RFSigilStatusKind
    ) {
        self.canonResourcesVisible = canonResourcesVisible
        self.loreGenerationImplemented = loreGenerationImplemented
        self.shouldBeFalseInPhase1 = shouldBeFalseInPhase1
        self.status = status
    }
}

public struct RFSigilSourceAuthorityStatus: Codable, Hashable, Sendable {
    public let ashModel: ASHAuthorityStatus
    public let ywe: YWEAuthorityStatus
    public let apsComponentRole: RFSigilSystemStatus
    public let wrwNarrativeLayer: RFSigilSystemStatus
    public let sigilProductLayer: RFSigilSystemStatus
    public let wrwCanon: WRWCanonStatus
    public let forbiddenInterpretationsPassed: Bool
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        ashModel: ASHAuthorityStatus,
        ywe: YWEAuthorityStatus,
        apsComponentRole: RFSigilSystemStatus,
        wrwNarrativeLayer: RFSigilSystemStatus,
        sigilProductLayer: RFSigilSystemStatus,
        wrwCanon: WRWCanonStatus,
        forbiddenInterpretationsPassed: Bool,
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.ashModel = ashModel
        self.ywe = ywe
        self.apsComponentRole = apsComponentRole
        self.wrwNarrativeLayer = wrwNarrativeLayer
        self.sigilProductLayer = sigilProductLayer
        self.wrwCanon = wrwCanon
        self.forbiddenInterpretationsPassed = forbiddenInterpretationsPassed
        self.evidence = evidence
    }
}
