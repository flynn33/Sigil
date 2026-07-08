import Foundation

public enum RFSigilStatusKind: String, Codable, Hashable, Sendable {
    case pass = "PASS"
    case passWithAllowedBlocker = "PASS_WITH_ALLOWED_BLOCKER"
    case blocked = "BLOCKED"
    case fail = "FAIL"
}

public struct RFSigilEvidenceRecord: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let source: String
    public let summary: String
    public let status: RFSigilStatusKind

    public init(
        id: String,
        source: String,
        summary: String,
        status: RFSigilStatusKind
    ) {
        self.id = id
        self.source = source
        self.summary = summary
        self.status = status
    }
}

public struct RFSigilSystemStatus: Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let status: RFSigilStatusKind
    public let summary: String
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        id: String,
        title: String,
        status: RFSigilStatusKind,
        summary: String,
        evidence: [RFSigilEvidenceRecord] = []
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.summary = summary
        self.evidence = evidence
    }
}

public enum SigilModuleID: String, Codable, CaseIterable, Hashable, Sendable {
    case ui = "com.ravenforge.sigil.ui"
    case aps = "com.ravenforge.sigil.aps"
    case aeostara = "com.ravenforge.sigil.aeostara"
    case sourceAuthority = "com.ravenforge.sigil.source-authority"
    case pipelinePlaceholder = "com.ravenforge.sigil.pipeline-placeholder"
    case privacySecurity = "com.ravenforge.sigil.privacy-security"
    case diagnostics = "com.ravenforge.sigil.diagnostics"
}

public struct RFSigilDashboardCard: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let status: RFSigilStatusKind
    public let summary: String
    public let detail: String
    public let symbolName: String

    public init(
        id: String,
        title: String,
        status: RFSigilStatusKind,
        summary: String,
        detail: String,
        symbolName: String
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.summary = summary
        self.detail = detail
        self.symbolName = symbolName
    }
}

public struct RFSigilDashboardStatus: Codable, Hashable, Sendable {
    public let title: String
    public let cards: [RFSigilDashboardCard]
    public let evidence: [RFSigilEvidenceRecord]

    public init(
        title: String,
        cards: [RFSigilDashboardCard],
        evidence: [RFSigilEvidenceRecord]
    ) {
        self.title = title
        self.cards = cards
        self.evidence = evidence
    }
}

public protocol RFSigilDashboardStatusProviding {
    func dashboardStatus() -> RFSigilDashboardStatus
}
