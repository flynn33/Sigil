import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilPrivacySecurityProviding: Sendable {
    func status() -> PrivacyPostureStatus
}

public struct SigilPrivacySecurityService: RFSigilPrivacySecurityProviding {
    public init() {}

    public func status() -> PrivacyPostureStatus {
        PrivacyPostureStatus(
            status: .pass,
            networkDenyStatus: NetworkDenyStatus(
                hasNetworkClient: false,
                hasBackendEndpoint: false,
                hasAnalyticsSDK: false,
                plannedLaterExternalService: "Apple Maps/geocoding later for birth-location lookup only"
            ),
            secureStorageReadiness: .modeledNotPersistingSensitiveData,
            diagnosticsLocalOnly: true,
            userSensitiveDataLogged: false,
            evidence: [
                RFSigilEvidenceRecord(
                    id: "privacy-local-first",
                    source: "sigil_phase1_project_instruction_package_v2_1/08_PRIVACY_SECURITY_LOCAL_FIRST.md",
                    summary: "No collection, backend upload path, analytics SDK, or network client is present.",
                    status: .pass
                ),
                RFSigilEvidenceRecord(
                    id: "privacy-secure-storage-readiness",
                    source: "RFSigilPrivacySecurity",
                    summary: "Encrypted-at-rest readiness is modeled without storing sensitive data.",
                    status: .pass
                )
            ]
        )
    }
}

public final class SigilPrivacySecurityModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let service: SigilPrivacySecurityService

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        service: SigilPrivacySecurityService = SigilPrivacySecurityService()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.service = service
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.privacy-security.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.privacy-security.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
