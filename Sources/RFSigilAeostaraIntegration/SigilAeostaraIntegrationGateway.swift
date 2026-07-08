import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilAeostaraIntegrationProviding: Sendable {
    func status() -> AeostaraIntegrationStatus
    func healthDecision(for failure: AeostaraArtifactFailureKind) -> AeostaraHealthDecision
}

public struct SigilAeostaraIntegrationGateway: RFSigilAeostaraIntegrationProviding {
    public init() {}

    public func status() -> AeostaraIntegrationStatus {
        AeostaraIntegrationStatus(
            platformIOSAccessible: true,
            productsFound: ["AeostaraDomain", "AeostaraServices"],
            baselinePin: AeostaraBaselineEvidence(
                release: "v1.0.0",
                commit: "774b981ef2267a41c1b1a59497b2b0746a86f32b"
            ),
            migrationProvenance: AeostaraMigrationProvenance(
                sourceAndDestinationHistoryConfirmed: true,
                sourceTag: "archive/platform-ios-0c931a7",
                destinationTag: "import/platform-ios-0c931a7",
                commit: "0c931a7cbac349c6be93a6aeb4a253dd2268178f"
            ),
            buildStatus: .passed,
            blocker: nil,
            evidence: [
                RFSigilEvidenceRecord(
                    id: "aeostara-platform-ios",
                    source: "flynn33/Aeostara-Mac-iOS@platform/ios",
                    summary: "platform/ios branch was accessible and read.",
                    status: .pass
                ),
                RFSigilEvidenceRecord(
                    id: "aeostara-products",
                    source: "Package.swift",
                    summary: "AeostaraDomain, AeostaraServices, and AeostaraTests were declared.",
                    status: .pass
                ),
                RFSigilEvidenceRecord(
                    id: "aeostara-baseline",
                    source: "AEOSTARA_BASELINE_REFERENCE.md",
                    summary: "Baseline v1.0.0 and commit pin were confirmed.",
                    status: .pass
                ),
                RFSigilEvidenceRecord(
                    id: "aeostara-migration",
                    source: "MIGRATION_PROVENANCE.md",
                    summary: "Source and destination platform history were confirmed.",
                    status: .pass
                )
            ]
        )
    }

    public func healthDecision(for failure: AeostaraArtifactFailureKind) -> AeostaraHealthDecision {
        AeostaraHealthDecision(
            status: .blocked,
            mutationAllowed: false,
            requiresBackupBeforeMutation: true,
            requiresVerificationAfterExecution: true,
            requiresOperatorReview: true,
            reason: "Artifact health check failed closed for \(failure.rawValue)."
        )
    }
}

public final class SigilAeostaraIntegrationModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let gateway: SigilAeostaraIntegrationGateway

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        gateway: SigilAeostaraIntegrationGateway = SigilAeostaraIntegrationGateway()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.gateway = gateway
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.aeostara.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.aeostara.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
