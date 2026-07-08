import ForsettiCore
import RFSigilAPSIntegration
import RFSigilAeostaraIntegration
import RFSigilCoreModels
import RFSigilDiagnostics
import RFSigilForsettiModules
import RFSigilPipelinePlaceholder
import RFSigilPrivacySecurity
import RFSigilSourceAuthority

public struct SigilRuntimeAssembly: RFSigilDashboardStatusProviding {
    public let apsGateway: SigilAPSIntegrationGateway
    public let aeostaraGateway: SigilAeostaraIntegrationGateway
    public let sourceAuthorityService: SigilSourceAuthorityService
    public let pipelinePlaceholderService: SigilPipelinePlaceholderService
    public let privacySecurityService: SigilPrivacySecurityService
    public let diagnosticsService: SigilDiagnosticsService
    public let registration: SigilRuntimeRegistration

    public init(
        apsGateway: SigilAPSIntegrationGateway = SigilAPSIntegrationGateway(),
        aeostaraGateway: SigilAeostaraIntegrationGateway = SigilAeostaraIntegrationGateway(),
        sourceAuthorityService: SigilSourceAuthorityService = SigilSourceAuthorityService(),
        pipelinePlaceholderService: SigilPipelinePlaceholderService = SigilPipelinePlaceholderService(),
        privacySecurityService: SigilPrivacySecurityService = SigilPrivacySecurityService(),
        diagnosticsService: SigilDiagnosticsService = SigilDiagnosticsService(),
        registration: SigilRuntimeRegistration = SigilModuleRegistryInstaller.registrationSummary()
    ) {
        self.apsGateway = apsGateway
        self.aeostaraGateway = aeostaraGateway
        self.sourceAuthorityService = sourceAuthorityService
        self.pipelinePlaceholderService = pipelinePlaceholderService
        self.privacySecurityService = privacySecurityService
        self.diagnosticsService = diagnosticsService
        self.registration = registration
    }

    public var forsettiVersion: String {
        ForsettiVersion.current.description
    }

    @MainActor
    public func makeForsettiRuntime() throws -> ForsettiRuntime {
        try SigilRuntimeFactory.makeRuntime()
    }

    public func dashboardStatus() -> RFSigilDashboardStatus {
        let aps = apsGateway.status()
        let aeostara = aeostaraGateway.status()
        let authority = sourceAuthorityService.status()
        let pipeline = pipelinePlaceholderService.status()
        let privacy = privacySecurityService.status()
        let aeostaraProducts = aeostara.productsFound.joined(separator: ", ")

        let cards = [
            RFSigilDashboardCard(
                id: "forsetti",
                title: "Forsetti Runtime",
                status: .pass,
                summary: "Seven Sigil modules are registered through Forsetti public module factories.",
                detail: "Version \(forsettiVersion); one UI module and six service modules.",
                symbolName: "square.stack.3d.up"
            ),
            RFSigilDashboardCard(
                id: "aps",
                title: "APS Gateway",
                status: aps.sourceCoverage,
                summary: "ASHCore and ASHPatternSystem are present with conformance evidence recorded.",
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
            )
        ]

        return RFSigilDashboardStatus(
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
    }
}
