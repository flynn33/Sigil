import ForsettiCore
import Foundation
import RFSigilAPSIntegration
import RFSigilAeostaraIntegration
import RFSigilCoreModels
import RFSigilDiagnostics
import RFSigilForsettiModules
import RFSigilPersonalCodex
import RFSigilPipelinePlaceholder
import RFSigilPrivacySecurity
import RFSigilSourceAuthority
import RFSigilVisibleGlyph

public struct SigilRuntimeAssembly: RFSigilDashboardStatusProviding {
    public let apsGateway: SigilAPSIntegrationGateway
    public let aeostaraGateway: SigilAeostaraIntegrationGateway
    public let visibleGlyphService: SigilVisibleGlyphService
    public let sourceAuthorityService: SigilSourceAuthorityService
    public let pipelinePlaceholderService: SigilPipelinePlaceholderService
    public let privacySecurityService: SigilPrivacySecurityService
    public let diagnosticsService: SigilDiagnosticsService
    public let diagnostics: any SigilDiagnosticCollector
    public let persistenceService: SigilSecurePersistenceService?
    public let personalCodexService: SigilPersonalCodexService?
    public let registration: SigilRuntimeRegistration

    /// Development builds select the rich development capture profile;
    /// release builds select the minimal release implementation. Source-
    /// level exclusion of development capture from distribution artifacts
    /// is completed in the delivery phase (see docs/diagnostics.md).
    public static var selectedDiagnosticProfile: SigilDiagnosticProfile {
        #if DEBUG
        .development
        #else
        .release
        #endif
    }

    public init(
        apsGateway: SigilAPSIntegrationGateway = SigilAPSIntegrationGateway(),
        aeostaraGateway: SigilAeostaraIntegrationGateway = SigilAeostaraIntegrationGateway(),
        visibleGlyphService: SigilVisibleGlyphService = SigilVisibleGlyphService(),
        sourceAuthorityService: SigilSourceAuthorityService = SigilSourceAuthorityService(),
        pipelinePlaceholderService: SigilPipelinePlaceholderService = SigilPipelinePlaceholderService(),
        privacySecurityService: SigilPrivacySecurityService = SigilPrivacySecurityService(),
        diagnosticsService: SigilDiagnosticsService = SigilDiagnosticsService(),
        diagnostics: any SigilDiagnosticCollector = SigilDiagnosticsFactory.collector(
            profile: SigilRuntimeAssembly.selectedDiagnosticProfile
        ),
        persistenceService: SigilSecurePersistenceService? = nil,
        personalCodexService: SigilPersonalCodexService? = nil,
        registration: SigilRuntimeRegistration = SigilModuleRegistryInstaller.registrationSummary()
    ) {
        self.apsGateway = apsGateway
        self.aeostaraGateway = aeostaraGateway
        self.visibleGlyphService = visibleGlyphService
        self.sourceAuthorityService = sourceAuthorityService
        self.pipelinePlaceholderService = pipelinePlaceholderService
        self.privacySecurityService = privacySecurityService
        self.diagnosticsService = diagnosticsService
        self.diagnostics = diagnostics
        self.persistenceService = persistenceService
        self.personalCodexService = personalCodexService
        self.registration = registration
    }

    private static func defaultBuildIdentity() -> SigilDiagnosticBuildIdentity {
        let info = Bundle.main.infoDictionary
        return SigilDiagnosticBuildIdentity(
            productVersion: info?["CFBundleShortVersionString"] as? String,
            buildNumber: info?["CFBundleVersion"] as? String,
            sourceCommit: nil,
            sourceCommitUnavailableReason: "Source commit is not injected into the running build; the authoritative commit is recorded in the project record.",
            componentVersions: [
                "forsetti": ForsettiVersion.current.description
            ]
        )
    }

    public var forsettiVersion: String {
        ForsettiVersion.current.description
    }

    @MainActor
    public func makeForsettiRuntime() throws -> ForsettiRuntime {
        try SigilRuntimeFactory.makeRuntime()
    }

    public func dashboardStatus() -> RFSigilDashboardStatus {
        diagnostics.beginSession(
            buildIdentity: Self.defaultBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        let operationID = diagnostics.beginOperation(
            name: "sigil.dashboard.status",
            expected: "Phase 1 dashboard status assembles from local module services with no network access",
            correlationID: nil
        )
        let operationStartedAt = Date()
        let aps = apsGateway.status()
        let aeostara = aeostaraGateway.status()
        let authority = sourceAuthorityService.status()
        let pipeline = pipelinePlaceholderService.status()
        let privacy = privacySecurityService.status()
        let persistence = persistenceService?.readiness() ?? SigilPersistenceReadinessInfo(
            status: .pass,
            summary: "Sensitive records persist locally as AES-GCM ciphertext; a failed save is reported as a failure.",
            detail: "Key source: keychain; keys are stored separately from ciphertext. Local only: no network, CloudKit, sync service, or upload.",
            recordCount: 0
        )
        let personalcodexReadiness = personalCodexService?.readiness ?? SigilPersonalCodexReadiness(
            status: .pass,
            summary: "The PersonalCodex derives a readable, canon-backed interpretation and a deterministic celestial name from the ASH identity.",
            detail: "Canonical and Flare remain separate; no personal-data embedding. Local only."
        )
        let aeostaraProducts = aeostara.productsFound.joined(separator: ", ")
        let apsProducts = aps.productsFound.joined(separator: " and ")
        let moduleCount = registration.moduleIDs.count
        let uiModuleCount = SigilModuleCatalog.definitions
            .filter { $0.descriptor.moduleType == .ui }
            .count
        let serviceModuleCount = moduleCount - uiModuleCount

        let cards = [
            RFSigilDashboardCard(
                id: "forsetti",
                title: "Forsetti Runtime",
                status: .pass,
                summary: "\(moduleCount) Sigil modules are registered through Forsetti public module factories.",
                detail: "Version \(forsettiVersion); \(uiModuleCount) UI module and \(serviceModuleCount) service modules.",
                symbolName: "square.stack.3d.up"
            ),
            RFSigilDashboardCard(
                id: "aps",
                title: "APS Gateway",
                status: aps.sourceCoverage,
                summary: "Recorded conformance evidence for \(apsProducts) is preserved; the gateway is not a live APS dependency or resolver.",
                detail: "Judgment: \(aps.conformanceJudgment.rawValue).",
                symbolName: "checklist.checked"
            ),
            RFSigilDashboardCard(
                id: "aeostara",
                title: "Aeostara Gateway",
                status: aeostara.platformIOSAccessible ? .pass : .blocked,
                summary: "platform/ios authority, products, baseline, and migration provenance are recorded.",
                detail: "Products: \(aeostaraProducts).",
                symbolName: "waveform.path.ecg"
            ),
            RFSigilDashboardCard(
                id: "visible-glyph",
                title: "Visible Glyph",
                status: .pass,
                summary: "Deterministic visible glyph synthesis is available as a local bounded service.",
                detail: "Canonical hidden geometry, visible vector paths, quality gates, and validation stay local.",
                symbolName: "scribble.variable"
            ),
            RFSigilDashboardCard(
                id: "source-authority",
                title: "YWE / WRW Authority",
                status: authority.forbiddenInterpretationsPassed ? .pass : .fail,
                summary: "ASH, YWE, APS, WRW, and Sigil layer boundaries are preserved.",
                detail: authority.ywe.implementationState,
                symbolName: "point.3.connected.trianglepath.dotted"
            ),
            RFSigilDashboardCard(
                id: "pipeline-placeholder",
                title: "Pipeline Placeholder",
                status: pipeline.available ? .fail : .pass,
                summary: "The final Sigil pipeline is intentionally unavailable in Phase 1.",
                detail: "Implemented final feature count: \(pipeline.implementedFinalFeatures.count).",
                symbolName: "pause.circle"
            ),
            RFSigilDashboardCard(
                id: "privacy-security",
                title: "Privacy / Security",
                status: privacy.status,
                summary: "No collection, backend upload path, analytics SDK, or personal-data network client is present.",
                detail: "Diagnostics remain local and sensitive-data logging is disabled.",
                symbolName: "lock.shield"
            ),
            RFSigilDashboardCard(
                id: "secure-persistence",
                title: "Secure Persistence",
                status: persistence.status,
                summary: persistence.summary,
                detail: persistence.detail,
                symbolName: "internaldrive.connected"
            ),
            RFSigilDashboardCard(
                id: "personalcodex",
                title: "PersonalCodex",
                status: personalcodexReadiness.status,
                summary: personalcodexReadiness.summary,
                detail: personalcodexReadiness.detail,
                symbolName: "book.closed"
            )
        ]

        let status = RFSigilDashboardStatus(
            title: "Sigil Phase 1",
            cards: cards,
            evidence: diagnosticsService
                .report(
                    records: aps.evidence
                        + aeostara.evidence
                        + authority.evidence
                        + pipeline.evidence
                        + privacy.evidence
                )
                .records
        )
        diagnostics.finishOperation(
            id: operationID,
            outcome: .success,
            context: [
                "moduleCount": .number(Double(moduleCount)),
                "evidenceCount": .number(Double(status.evidence.count)),
                "apsJudgment": .string(aps.conformanceJudgment.rawValue),
                "aeostaraPlatformIOSAccessible": .boolean(aeostara.platformIOSAccessible),
                "pipelineImplementedFinalFeatures": .number(Double(pipeline.implementedFinalFeatures.count))
            ],
            durationSeconds: Date().timeIntervalSince(operationStartedAt)
        )
        return status
    }
}
