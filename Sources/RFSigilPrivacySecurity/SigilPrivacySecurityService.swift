import ForsettiCore
import RFSigilCoreModels

public protocol RFSigilPrivacySecurityProviding: Sendable {
    func status() -> PrivacyPostureStatus
}

public struct SigilPrivacySecurityService: RFSigilPrivacySecurityProviding {
    public let secureStorageReadiness: SecureStorageReadinessStatus

    public init(secureStorageReadiness: SecureStorageReadinessStatus = .encryptedAtRestNativeKeychain) {
        self.secureStorageReadiness = secureStorageReadiness
    }

    public func status() -> PrivacyPostureStatus {
        PrivacyPostureStatus(
            status: .pass,
            networkDenyStatus: NetworkDenyStatus(
                hasNetworkClient: false,
                hasBackendEndpoint: false,
                hasAnalyticsSDK: false,
                plannedLaterExternalService: "Apple Maps/geocoding later for birth-location lookup only"
            ),
            secureStorageReadiness: secureStorageReadiness,
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
                    id: "privacy-secure-storage-implemented",
                    source: "RFSigilPrivacySecurity",
                    summary: "Sensitive records persist only through local AES-GCM encryption with keychain-backed keys; keys are stored separately from ciphertext and never beside it. No CloudKit, sync service, or background upload.",
                    status: .pass
                ),
                RFSigilEvidenceRecord(
                    id: "privacy-atomic-local-persistence",
                    source: "RFSigilSecureRecordStore",
                    summary: "Writes are atomic (temp file + replace); a failed or interrupted write preserves the last-verified record. Stored bytes are ciphertext only.",
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
