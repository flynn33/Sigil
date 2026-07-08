import Foundation

public enum APSConformanceJudgment: String, Codable, Hashable, Sendable {
    case conformant = "CONFORMANT"
    case conformantWithCaveats = "CONFORMANT WITH CAVEATS"
    case nonConformant = "NON-CONFORMANT"
}

public enum BuildVerificationStatus: String, Codable, Hashable, Sendable {
    case passed = "PASSED"
    case passedWithCaveats = "PASSED_WITH_CAVEATS"
    case blocked = "BLOCKED"
    case notApplicable = "NOT_APPLICABLE"
}

public struct APSIntegrationStatus: Codable, Hashable, Sendable {
    public let productsFound: [String]
    public let sourceCoverage: RFSigilStatusKind
    public let conformanceJudgment: APSConformanceJudgment
    public let buildStatus: BuildVerificationStatus
    public let blocker: String?
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        productsFound: [String],
        sourceCoverage: RFSigilStatusKind,
        conformanceJudgment: APSConformanceJudgment,
        buildStatus: BuildVerificationStatus,
        blocker: String?,
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.productsFound = productsFound
        self.sourceCoverage = sourceCoverage
        self.conformanceJudgment = conformanceJudgment
        self.buildStatus = buildStatus
        self.blocker = blocker
        self.evidence = evidence
    }
}

public enum APSRequiredEvidenceID: String, Codable, CaseIterable, Hashable, Sendable {
    case invariantSpec = "aps-invariant-spec"
    case conformanceCategories = "aps-conformance-categories"
    case moduleContracts = "aps-module-contracts"
    case diagnosticSchema = "aps-diagnostic-schema"
    case ruleIDTaxonomy = "aps-rule-id-taxonomy"
    case stateSpace = "aps-f2-9-state-space"
    case xorTransform = "aps-xor-by-codeword"
    case materializationBoundary = "aps-materialization-boundary"
    case fallbackPolicy = "aps-fallback-policy-registry"
    case safeHalt = "aps-safe-halt"
    case monotonicEscalation = "aps-monotonic-escalation"
    case noSilentHealing = "aps-no-silent-healing"
    case noInventedCodewords = "aps-no-invented-codewords"
}

public enum APSBlockedReason: String, Codable, Hashable, Sendable {
    case sourceUnavailable = "SOURCE_UNAVAILABLE"
    case buildUnavailable = "BUILD_UNAVAILABLE"
    case conformanceSourceConflict = "CONFORMANCE_SOURCE_CONFLICT"
}

public struct AeostaraBaselineEvidence: Codable, Hashable, Sendable {
    public let release: String
    public let commit: String

    public init(release: String, commit: String) {
        self.release = release
        self.commit = commit
    }
}

public struct AeostaraMigrationProvenance: Codable, Hashable, Sendable {
    public let sourceAndDestinationHistoryConfirmed: Bool
    public let sourceTag: String
    public let destinationTag: String
    public let commit: String

    public init(
        sourceAndDestinationHistoryConfirmed: Bool,
        sourceTag: String,
        destinationTag: String,
        commit: String
    ) {
        self.sourceAndDestinationHistoryConfirmed = sourceAndDestinationHistoryConfirmed
        self.sourceTag = sourceTag
        self.destinationTag = destinationTag
        self.commit = commit
    }
}

public struct AeostaraIntegrationStatus: Codable, Hashable, Sendable {
    public let platformIOSAccessible: Bool
    public let productsFound: [String]
    public let baselinePin: AeostaraBaselineEvidence
    public let migrationProvenance: AeostaraMigrationProvenance
    public let buildStatus: BuildVerificationStatus
    public let blocker: String?
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        platformIOSAccessible: Bool,
        productsFound: [String],
        baselinePin: AeostaraBaselineEvidence,
        migrationProvenance: AeostaraMigrationProvenance,
        buildStatus: BuildVerificationStatus,
        blocker: String?,
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.platformIOSAccessible = platformIOSAccessible
        self.productsFound = productsFound
        self.baselinePin = baselinePin
        self.migrationProvenance = migrationProvenance
        self.buildStatus = buildStatus
        self.blocker = blocker
        self.evidence = evidence
    }
}

public enum AeostaraArtifactFailureKind: String, Codable, Hashable, Sendable {
    case missingRequiredData = "MISSING_REQUIRED_DATA"
    case corruptJSON = "CORRUPT_JSON"
    case unknownSchema = "UNKNOWN_SCHEMA"
    case invalidTopology = "INVALID_TOPOLOGY"
    case nonRecoverableArtifactFailure = "NON_RECOVERABLE_ARTIFACT_FAILURE"
}

public struct AeostaraHealthDecision: Codable, Hashable, Sendable {
    public let status: RFSigilStatusKind
    public let mutationAllowed: Bool
    public let requiresBackupBeforeMutation: Bool
    public let requiresVerificationAfterExecution: Bool
    public let requiresOperatorReview: Bool
    public let reason: String

    public init(
        status: RFSigilStatusKind,
        mutationAllowed: Bool,
        requiresBackupBeforeMutation: Bool,
        requiresVerificationAfterExecution: Bool,
        requiresOperatorReview: Bool,
        reason: String
    ) {
        self.status = status
        self.mutationAllowed = mutationAllowed
        self.requiresBackupBeforeMutation = requiresBackupBeforeMutation
        self.requiresVerificationAfterExecution = requiresVerificationAfterExecution
        self.requiresOperatorReview = requiresOperatorReview
        self.reason = reason
    }
}
