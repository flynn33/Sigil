import ForsettiCore
import Foundation
import RFSigilCoreModels

public protocol RFSigilDiagnosticsProviding: Sendable {
    func report(records: [RFSigilEvidenceRecord], generatedAt: Date) -> LocalDiagnosticReport
}

public struct SigilDiagnosticsService: RFSigilDiagnosticsProviding {
    public init() {}

    public func report(records: [RFSigilEvidenceRecord], generatedAt: Date = Date()) -> LocalDiagnosticReport {
        LocalDiagnosticReport(
            generatedAt: generatedAt,
            records: records,
            remoteTransmissionEnabled: false
        )
    }
}

public final class SigilDiagnosticsModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let service: SigilDiagnosticsService

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        service: SigilDiagnosticsService = SigilDiagnosticsService()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.service = service
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.diagnostics.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.diagnostics.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
