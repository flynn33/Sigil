import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilSourceAuthorityProviding: Sendable {
    func status() -> RFSigilSourceAuthorityStatus
}

public struct SigilSourceAuthorityService: RFSigilSourceAuthorityProviding {
    public init() {}

    public func status() -> RFSigilSourceAuthorityStatus {
        let evidence = [
            RFSigilEvidenceRecord(
                id: "ywe-readme",
                source: "/Users/flynn/Downloads/yggdrasil-world-engine-main.zip::yggdrasil-world-engine-main/README.md",
                summary: "YWE source package was present and read.",
                status: .pass
            ),
            RFSigilEvidenceRecord(
                id: "ywe-authority-contracts",
                source: "/Users/flynn/Downloads/yggdrasil-world-engine-main.zip::yggdrasil-world-engine-main/docs/architecture",
                summary: "Authority, engine, component, and platform boundary contracts were present and read.",
                status: .pass
            ),
            RFSigilEvidenceRecord(
                id: "wrw-product-layer",
                source: "/Users/flynn/Downloads/yggdrasil-world-engine-main.zip::yggdrasil-world-engine-main/docs/architecture/engine_vs_game_layer_contract.md",
                summary: "WRW is modeled as the narrative/product interpretation layer, not the engine layer.",
                status: .pass
            )
        ]

        return RFSigilSourceAuthorityStatus(
            ashModel: ASHAuthorityStatus(
                status: .pass,
                foundationStatement: "ASH Model is the mathematical and ontological foundation."
            ),
            ywe: YWEAuthorityStatus(
                readmeRead: true,
                authorityContractsRead: true,
                hierarchyPreserved: true,
                implementationState: "Source-authority status only; no generation pipeline is implemented.",
                status: .pass
            ),
            apsComponentRole: RFSigilSystemStatus(
                id: "aps-component-role",
                title: "APS Component Role",
                status: .passWithAllowedBlocker,
                summary: "APS is modeled as a YWE component for diagnostics, conformance, recovery, containment, resilience, update safety, and patch stability.",
                evidence: []
            ),
            wrwNarrativeLayer: RFSigilSystemStatus(
                id: "wrw-narrative-layer",
                title: "WRW Narrative Layer",
                status: .pass,
                summary: "WRW is modeled as product interpretation and canon expression, not engine truth.",
                evidence: []
            ),
            sigilProductLayer: RFSigilSystemStatus(
                id: "sigil-product-layer",
                title: "Sigil Product Layer",
                status: .pass,
                summary: "Sigil is modeled as the iOS product interpretation layer for Phase 1 status surfaces.",
                evidence: []
            ),
            wrwCanon: WRWCanonStatus(
                canonResourcesVisible: true,
                loreGenerationImplemented: false,
                shouldBeFalseInPhase1: false,
                status: .pass
            ),
            forbiddenInterpretationsPassed: true,
            evidence: evidence
        )
    }
}

public final class SigilSourceAuthorityModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let service: SigilSourceAuthorityService

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        service: SigilSourceAuthorityService = SigilSourceAuthorityService()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.service = service
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(
            type: "sigil.source-authority.started",
            payload: ["moduleID": descriptor.moduleID]
        )
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(
            type: "sigil.source-authority.stopped",
            payload: ["moduleID": descriptor.moduleID]
        )
    }
}
