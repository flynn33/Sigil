import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilPipelinePlaceholderProviding: Sendable {
    func status() -> PlaceholderPipelineStatus
    func unavailableResponse() -> PipelineUnavailableResponse
}

public struct SigilPipelinePlaceholderService: RFSigilPipelinePlaceholderProviding {
    public init() {}

    public func status() -> PlaceholderPipelineStatus {
        PlaceholderPipelineStatus(
            available: false,
            phase: "Phase 1",
            implementedFinalFeatures: [],
            unavailableReason: .placeholderOnly,
            evidence: [
                RFSigilEvidenceRecord(
                    id: "pipeline-placeholder",
                    source: "sigil_phase1_project_instruction_package_v2_1/07_PLACEHOLDER_PIPELINE_CONTRACT.md",
                    summary: "Pipeline is limited to deterministic placeholder status.",
                    status: .pass
                )
            ]
        )
    }

    public func unavailableResponse() -> PipelineUnavailableResponse {
        PipelineUnavailableResponse(
            status: .pass,
            reason: .placeholderOnly,
            forbiddenFeatures: ForbiddenPhase1Feature.allCases
        )
    }
}

public final class SigilPipelinePlaceholderModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let service: SigilPipelinePlaceholderService

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        service: SigilPipelinePlaceholderService = SigilPipelinePlaceholderService()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.service = service
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.pipeline-placeholder.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.pipeline-placeholder.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
