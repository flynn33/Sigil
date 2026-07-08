import Foundation

public enum ForbiddenPhase1Feature: String, Codable, CaseIterable, Hashable, Sendable {
    case standardNumerologyCalculation = "standard_numerology_calculation"
    case lifePathCalculation = "life_path_calculation"
    case birthOrderNumerology = "birth_order_numerology"
    case celestialNameGeneration = "celestial_name_generation"
    case wrwLoreGeneration = "WRW_lore_generation"
    case personalCodexGeneration = "PersonalCodex_generation"
    case hiddenReversibleGeometry = "hidden_reversible_geometry"
    case visibleSigilGrammarSynthesis = "visible_sigil_grammar_synthesis"
    case finalGlyphRenderingAsOutput = "final_glyph_rendering_as_output"
    case sigilFlareExport = "Sigil_Flare_export"
    case sigilFlareEditor = "Sigil_Flare_editor"
    case excessPersonalDataPersistence = "excess_personal_data_persistence"
    case canonicalProfileHashingForIdentity = "canonical_profile_hashing_for_identity"
    case finalExportBundleGeneration = "final_export_bundle_generation"
}

public enum PipelineUnavailableReason: String, Codable, Hashable, Sendable {
    case placeholderOnly = "PLACEHOLDER_ONLY"
}

public struct PlaceholderPipelineStatus: Codable, Hashable, Sendable {
    public let available: Bool
    public let phase: String
    public let implementedFinalFeatures: [ForbiddenPhase1Feature]
    public let unavailableReason: PipelineUnavailableReason
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        available: Bool,
        phase: String,
        implementedFinalFeatures: [ForbiddenPhase1Feature],
        unavailableReason: PipelineUnavailableReason,
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.available = available
        self.phase = phase
        self.implementedFinalFeatures = implementedFinalFeatures
        self.unavailableReason = unavailableReason
        self.evidence = evidence
    }
}

public struct PipelineUnavailableResponse: Codable, Hashable, Sendable {
    public let status: RFSigilStatusKind
    public let reason: PipelineUnavailableReason
    public let forbiddenFeatures: [ForbiddenPhase1Feature]

    public init(
        status: RFSigilStatusKind,
        reason: PipelineUnavailableReason,
        forbiddenFeatures: [ForbiddenPhase1Feature]
    ) {
        self.status = status
        self.reason = reason
        self.forbiddenFeatures = forbiddenFeatures
    }
}

public struct NetworkDenyStatus: Codable, Hashable, Sendable {
    public let hasNetworkClient: Bool
    public let hasBackendEndpoint: Bool
    public let hasAnalyticsSDK: Bool
    public let plannedLaterExternalService: String?

    public init(
        hasNetworkClient: Bool,
        hasBackendEndpoint: Bool,
        hasAnalyticsSDK: Bool,
        plannedLaterExternalService: String?
    ) {
        self.hasNetworkClient = hasNetworkClient
        self.hasBackendEndpoint = hasBackendEndpoint
        self.hasAnalyticsSDK = hasAnalyticsSDK
        self.plannedLaterExternalService = plannedLaterExternalService
    }
}

public enum SecureStorageReadinessStatus: String, Codable, Hashable, Sendable {
    case modeledNotPersistingSensitiveData = "MODELED_NOT_PERSISTING_SENSITIVE_DATA"
}

public struct PrivacyPostureStatus: Codable, Hashable, Sendable {
    public let status: RFSigilStatusKind
    public let networkDenyStatus: NetworkDenyStatus
    public let secureStorageReadiness: SecureStorageReadinessStatus
    public let diagnosticsLocalOnly: Bool
    public let userSensitiveDataLogged: Bool
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        status: RFSigilStatusKind,
        networkDenyStatus: NetworkDenyStatus,
        secureStorageReadiness: SecureStorageReadinessStatus,
        diagnosticsLocalOnly: Bool,
        userSensitiveDataLogged: Bool,
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.status = status
        self.networkDenyStatus = networkDenyStatus
        self.secureStorageReadiness = secureStorageReadiness
        self.diagnosticsLocalOnly = diagnosticsLocalOnly
        self.userSensitiveDataLogged = userSensitiveDataLogged
        self.evidence = evidence
    }
}

public struct LocalDiagnosticReport: Codable, Hashable, Sendable {
    public let generatedAt: Date
    public let records: [RFSigilEvidenceRecord]
    public let remoteTransmissionEnabled: Bool

    public init(
        generatedAt: Date,
        records: [RFSigilEvidenceRecord],
        remoteTransmissionEnabled: Bool
    ) {
        self.generatedAt = generatedAt
        self.records = records
        self.remoteTransmissionEnabled = remoteTransmissionEnabled
    }
}

public struct Phase1AuditEvidence: Codable, Hashable, Sendable {
    public let sourceEvidence: [RFSigilEvidenceRecord]
    public let moduleEvidence: [RFSigilEvidenceRecord]
    public let buildEvidence: [RFSigilEvidenceRecord]
    public let privacyEvidence: [RFSigilEvidenceRecord]

    public init(
        sourceEvidence: [RFSigilEvidenceRecord],
        moduleEvidence: [RFSigilEvidenceRecord],
        buildEvidence: [RFSigilEvidenceRecord],
        privacyEvidence: [RFSigilEvidenceRecord]
    ) {
        self.sourceEvidence = sourceEvidence
        self.moduleEvidence = moduleEvidence
        self.buildEvidence = buildEvidence
        self.privacyEvidence = privacyEvidence
    }
}
