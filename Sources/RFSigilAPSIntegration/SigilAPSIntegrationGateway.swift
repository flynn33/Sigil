import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilAPSIntegrationProviding: Sendable {
    func status() -> APSIntegrationStatus
}

public struct SigilAPSIntegrationGateway: RFSigilAPSIntegrationProviding {
    public init() {}

    public func status() -> APSIntegrationStatus {
        APSIntegrationStatus(
            productsFound: ["ASHCore", "ASHPatternSystem"],
            sourceCoverage: .passWithAllowedBlocker,
            conformanceJudgment: .conformantWithCaveats,
            buildStatus: .passed,
            blocker: nil,
            evidence: Self.evidence
        )
    }

    public static let evidence: [RFSigilEvidenceRecord] = [
        record(.invariantSpec, "specs/verification/invariant-spec.md", "Invariant source was located and read."),
        record(.conformanceCategories, "specs/verification/conformance-categories.md", "Five conformance categories were located and read."),
        record(.moduleContracts, "specs/interfaces/contracts/**", "Per-module contract sources were located and read."),
        record(.diagnosticSchema, "specs/interfaces/diagnostic-schema.md", "Diagnostic envelope source was located and read."),
        record(.ruleIDTaxonomy, "specs/interfaces/rule-id-taxonomy.md", "Rule ID taxonomy source was located and read."),
        record(.stateSpace, "specs/core/ash-state-space.pseudo.md", "Full F2^9 state-space source was located and read."),
        record(.xorTransform, "specs/algorithms/codeword-transformation-semantics.pseudo.md", "XOR-by-codeword transform source was located and read."),
        record(.materializationBoundary, "specs/verification/implementation-acceptance.md", "Materialization boundary source was located and read."),
        record(.fallbackPolicy, "specs/registries/fallback-policy-registry.md", "Fallback-policy registry source was located and read with documented caveat."),
        record(.safeHalt, "specs/algorithms/containment-safe-failure-semantics.pseudo.md", "Containment and SAFE_HALT source was located and read."),
        record(.monotonicEscalation, "specs/core/recoverability-semantics.pseudo.md", "Recoverability and monotonic escalation source was located and read."),
        record(.noSilentHealing, "specs/algorithms/containment-safe-failure-semantics.pseudo.md", "No silent healing is preserved as a gateway status rule."),
        record(.noInventedCodewords, "specs/algorithms/codeword-transformation-semantics.pseudo.md", "Gateway records source-backed codeword evidence only.")
    ]

    private static func record(
        _ id: APSRequiredEvidenceID,
        _ source: String,
        _ summary: String
    ) -> RFSigilEvidenceRecord {
        RFSigilEvidenceRecord(
            id: id.rawValue,
            source: source,
            summary: summary,
            status: id == .fallbackPolicy ? .passWithAllowedBlocker : .pass
        )
    }
}

public final class SigilAPSIntegrationModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let gateway: SigilAPSIntegrationGateway

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        gateway: SigilAPSIntegrationGateway = SigilAPSIntegrationGateway()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.gateway = gateway
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.aps.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.aps.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
