import Foundation
import RFSigilCoreModels
import RFSigilVisibleGlyph

// MARK: - Artifact health (Aeostara base, product-owned)
//
// Real, fail-closed artifact health for Sigil glyph artifacts. This is the
// product-owned realization of the Aeostara base lifecycle applied to a real
// `SigilVisibleGlyphArtifact`: diagnose, classify, determine recoverability,
// generate a recovery plan, evaluate the policy gate, execute the approved
// non-destructive recovery, verify it, and record monotonic containment and
// safe-halt. It never redefines ASH or Aeostara semantics and never reconstructs
// a broken authoritative value from plausible data: it recovers only metadata
// that is derivable from intact authoritative content, and it fails closed
// whenever that is not possible.

/// The source-backed schema and algorithm-identity markers the validator
/// recognizes. Anything else is an unknown, unrecognized format (fail closed).
private enum SigilArtifactHealthConstants {
    static let hiddenGeometrySchema = "rf.hidden_geometry.v1"
    static let visibleSigilSchema = "rf.visible_sigil.v1"
    static let hiddenAlgorithmIdentity = "sigil-identity-pipeline.v1"
    static let ashStateAlgorithmIdentity = "sigil-ash-state.v1"
    static let segmentBudgetLower = 10
    static let segmentBudgetUpper = 14
    static let majorCrossingMaximum = 3
    static let sha256HexLength = 64
}

/// Monotonic containment level. The validator only escalates, never
/// de-escalates, matching the source-defined monotonic-escalation invariant.
public enum SigilArtifactContainmentLevel: Int, Codable, CaseIterable, Comparable, Sendable {
    case none = 0
    case observe = 1
    case backupPreserved = 2
    case safeHalt = 3

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .none: return "NONE"
        case .observe: return "OBSERVE"
        case .backupPreserved: return "BACKUP_PRESERVED"
        case .safeHalt: return "SAFE_HALT"
        }
    }
}

/// A single, truthful diagnostic finding from the artifact health pass.
public struct SigilArtifactHealthFinding: Hashable, Sendable {
    public let checkID: String
    public let failureKind: AeostaraArtifactFailureKind
    public let reason: String
    /// Whether this defect could be recovered from intact authoritative content.
    /// Non-recoverable defects (unknown schema, missing authoritative identity,
    /// broken topology, internally-tampered authoritative content) are never
    /// "healed"; a recoverable one is, by construction, derivable from intact
    /// authoritative content (never from plausible/CRUD-derived data).
    public let recoverable: Bool

    public init(
        checkID: String,
        failureKind: AeostaraArtifactFailureKind,
        reason: String,
        recoverable: Bool
    ) {
        self.checkID = checkID
        self.failureKind = failureKind
        self.reason = reason
        self.recoverable = recoverable
    }
}

/// The recorded outcome of the non-destructive recovery step. Diagnostics
/// observe this decision; they do not invent a successful repair.
public struct SigilArtifactHealthRecovery: Hashable, Sendable {
    public let attemptedAction: String
    public let expectedResult: String
    public let observedVerification: String
    /// Only derivable authoritative/derived digests — never raw personal values.
    public let recoveredMetadata: [String: String]
    /// Whether a (non-destructive, in-memory) recovery was actually produced.
    public let executed: Bool
    /// Whether a failed replacement was rolled back to the last-verified record.
    /// Health validation is non-destructive, so this is false unless a proposed
    /// replacement could not be verified and the last-verified value is retained.
    public let rolledBack: Bool
    public let safeHalt: Bool

    public init(
        attemptedAction: String,
        expectedResult: String,
        observedVerification: String,
        recoveredMetadata: [String: String] = [:],
        executed: Bool,
        rolledBack: Bool,
        safeHalt: Bool
    ) {
        self.attemptedAction = attemptedAction
        self.expectedResult = expectedResult
        self.observedVerification = observedVerification
        self.recoveredMetadata = recoveredMetadata
        self.executed = executed
        self.rolledBack = rolledBack
        self.safeHalt = safeHalt
    }
}

/// The full, truthful artifact-health result.
public struct SigilArtifactHealthResult: Hashable, Sendable {
    public let decision: AeostaraHealthDecision
    /// Dominant failure kind, or nil when the artifact is healthy.
    public let failureKind: AeostaraArtifactFailureKind?
    public let findings: [SigilArtifactHealthFinding]
    public let recovery: SigilArtifactHealthRecovery
    public let containment: SigilArtifactContainmentLevel

    public var isHealthy: Bool { findings.isEmpty }

    public init(
        decision: AeostaraHealthDecision,
        failureKind: AeostaraArtifactFailureKind?,
        findings: [SigilArtifactHealthFinding],
        recovery: SigilArtifactHealthRecovery,
        containment: SigilArtifactContainmentLevel
    ) {
        self.decision = decision
        self.failureKind = failureKind
        self.findings = findings
        self.recovery = recovery
        self.containment = containment
    }
}

/// Product-owned, fail-closed validator for real Sigil glyph artifacts.
///
/// The validator is pure and non-destructive: it never mutates the artifact,
/// never regenerates a visible sigil as a side effect, and never fabricates a
/// value. Recovery is limited to restating authoritative/derived digests that
/// are computable from intact authoritative content, then verifying them in
/// memory. It holds a producer service reference solely to recompute the
/// authoritative canonical geometry digest and to re-derive the canonical SVG
/// using the producer's own canonical encoding (not to run generation).
public struct SigilArtifactHealthValidator: Sendable {
    private let producer: SigilVisibleGlyphService

    public init(producer: SigilVisibleGlyphService = SigilVisibleGlyphService()) {
        self.producer = producer
    }

    // MARK: Decoding path (covers corrupt JSON / malformed records)

    /// Validates raw stored bytes. A decode failure is a truthful `corruptJSON`
    /// failure (fail closed, non-recoverable); a successful decode defers to the
    /// struct-based pass.
    public func validate(data: Data) -> SigilArtifactHealthResult {
        guard let artifact = Self.decodeArtifact(data) else {
            let finding = SigilArtifactHealthFinding(
                checkID: "artifact.decode",
                failureKind: .corruptJSON,
                reason: "Stored bytes could not be decoded into a SigilVisibleGlyphArtifact.",
                recoverable: false
            )
            return SigilArtifactHealthResult(
                decision: Self.blockedDecision("Artifact JSON could not be decoded."),
                failureKind: .corruptJSON,
                findings: [finding],
                recovery: Self.noRecovery(safeHalt: true, reason: "Corrupt record; nothing derivable; last-verified record preserved."),
                containment: .safeHalt
            )
        }
        return validate(artifact: artifact)
    }

    // MARK: Struct path (the real health pass)

    public func validate(artifact: SigilVisibleGlyphArtifact) -> SigilArtifactHealthResult {
        let hidden = artifact.hiddenGeometry
        let visible = artifact.visibleSigil
        var findings: [SigilArtifactHealthFinding] = []

        // 1. Schema and algorithm-identity recognition (unrecognized format).
        let hiddenSchemaOK = hidden.schemaVersion == SigilArtifactHealthConstants.hiddenGeometrySchema
        let visibleSchemaOK = visible.schemaVersion == SigilArtifactHealthConstants.visibleSigilSchema
        if !(hiddenSchemaOK && visibleSchemaOK) {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.schema",
                    failureKind: .unknownSchema,
                    reason: "Unrecognized schema version (hidden: \(hidden.schemaVersion), visible: \(visible.schemaVersion)).",
                    recoverable: false
                )
            )
        }

        let algorithmIDOK = hidden.algorithmIdentity == SigilArtifactHealthConstants.hiddenAlgorithmIdentity
            && hidden.ashState.algorithmIdentity == SigilArtifactHealthConstants.ashStateAlgorithmIdentity
        if !algorithmIDOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.algorithm-identity",
                    failureKind: .unknownSchema,
                    reason: "Unrecognized algorithm-identity markers on the hidden geometry or ASH state.",
                    recoverable: false
                )
            )
        }

        // 2. Authoritative identity must be present and available.
        let identityOK = !hidden.profileHash.isEmpty && hidden.ashState.available
        if !identityOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.identity",
                    failureKind: .missingRequiredData,
                    reason: hidden.ashState.available
                        ? "Authoritative profile hash is missing."
                        : "ASH state is unavailable; the authoritative identity is missing.",
                    recoverable: false
                )
            )
        }

        // 3. Authoritative internal integrity: the recorded canonical geometry
        //    digest must match a recomputation from intact authoritative content.
        let recomputed = producer.canonicalGeometryDigest(for: hidden)
        let internalDigestOK = !recomputed.isEmpty && recomputed == hidden.canonicalGeometryDigest
        if !internalDigestOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.internal-digest",
                    failureKind: .nonRecoverableArtifactFailure,
                    reason: "Recorded canonical geometry digest does not match recomputation from authoritative content.",
                    recoverable: false
                )
            )
        }

        // 4. Geometry topology: edges reference valid anchors; ids are unique;
        //    the anchor set is non-empty.
        let anchorIDs = Set(hidden.anchorPoints.map(\.id))
        let duplicateAnchorIDs = anchorIDs.count != hidden.anchorPoints.count
        let danglingEdge = hidden.edges.contains { !anchorIDs.contains($0.from) || !anchorIDs.contains($0.to) }
        let pathIDs = visible.vectorPaths.map(\.id)
        let duplicatePathIDs = Set(pathIDs).count != pathIDs.count
        let topologyOK = !hidden.anchorPoints.isEmpty && !duplicateAnchorIDs && !danglingEdge && !duplicatePathIDs
        if !topologyOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.topology",
                    failureKind: .invalidTopology,
                    reason: "Geometry topology is invalid (dangling edge, duplicate id, or empty anchor set).",
                    recoverable: false
                )
            )
        }

        // The authoritative half is intact only when every authoritative-side
        // check above passed. This gates whether a visible-side defect is
        // recoverable-derivable (it is) or non-recoverable (it is not).
        let authoritativeIntact = hiddenSchemaOK && visibleSchemaOK && algorithmIDOK
            && identityOK && internalDigestOK && topologyOK

        // 5. Cross-artifact digest relationship (visible must match authoritative).
        let profileDigestOK = visible.profileDigest == hidden.profileHash
        let geometryDigestOK = visible.canonicalGeometryDigest == hidden.canonicalGeometryDigest
        if !(profileDigestOK && geometryDigestOK) {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.cross-digest",
                    failureKind: .nonRecoverableArtifactFailure,
                    reason: "Visible digests do not match the authoritative hidden geometry.",
                    recoverable: authoritativeIntact
                )
            )
        }

        // 6. Serialized SVG must carry the canonical visible signature.
        let signatureToken = "data-signature=\"\(visible.visibleSignatureHash)\""
        let svgOK = !artifact.svgDocument.isEmpty && artifact.svgDocument.contains(signatureToken)
        if !svgOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.svg-signature",
                    failureKind: .nonRecoverableArtifactFailure,
                    reason: "Serialized SVG does not carry the canonical visible signature.",
                    recoverable: authoritativeIntact
                )
            )
        }

        // 7. Numeric / quality contract of the visible sigil.
        let report = visible.qualityReport
        let segmentOK = (SigilArtifactHealthConstants.segmentBudgetLower...SigilArtifactHealthConstants.segmentBudgetUpper)
            .contains(report.visibleSegmentCount)
        let crossingOK = report.majorCrossingCount <= SigilArtifactHealthConstants.majorCrossingMaximum
        let styleOK = visible.styleMetadata.strokeCount == visible.vectorPaths.count
            && visible.styleMetadata.majorCrossingCount == report.majorCrossingCount
            && visible.styleMetadata.candidateIndex == report.candidateIndex
        let qualityOK = report.passed && segmentOK && crossingOK && styleOK
        if !qualityOK {
            findings.append(
                SigilArtifactHealthFinding(
                    checkID: "artifact.quality-bounds",
                    failureKind: .nonRecoverableArtifactFailure,
                    reason: "Visible quality and numeric contract is unsatisfied.",
                    recoverable: authoritativeIntact
                )
            )
        }

        return finalize(findings: findings, artifact: artifact, authoritativeIntact: authoritativeIntact)
    }

    // MARK: Finalization (classify, policy gate, recovery, containment)

    private func finalize(
        findings: [SigilArtifactHealthFinding],
        artifact: SigilVisibleGlyphArtifact,
        authoritativeIntact: Bool
    ) -> SigilArtifactHealthResult {
        guard !findings.isEmpty else {
            return SigilArtifactHealthResult(
                decision: AeostaraHealthDecision(
                    status: .pass,
                    mutationAllowed: false,
                    requiresBackupBeforeMutation: false,
                    requiresVerificationAfterExecution: false,
                    requiresOperatorReview: false,
                    reason: "Sigil artifact passed real health validation (schema, identity, digests, topology, quality)."
                ),
                failureKind: nil,
                findings: [],
                recovery: SigilArtifactHealthRecovery(
                    attemptedAction: "No recovery required.",
                    expectedResult: "Artifact is healthy.",
                    observedVerification: "All checks passed.",
                    executed: false,
                    rolledBack: false,
                    safeHalt: false
                ),
                containment: .none
            )
        }

        // Classify: dominant = first non-recoverable finding, else first finding.
        let dominant = findings.first { !$0.recoverable } ?? findings[0]

        // Policy gate: health validation is non-destructive (fail closed).
        let decision = Self.blockedDecision(dominant.reason)

        // Containment: monotonic escalation.
        let hasNonRecoverable = findings.contains { !$0.recoverable }
        let containment: SigilArtifactContainmentLevel = hasNonRecoverable ? .safeHalt : .backupPreserved

        // Recovery: restatement of authoritative/derived digests, verified in
        // memory, only when the authoritative half is intact. Never a mutation.
        let recovery = recoveryPlan(
            findings: findings,
            artifact: artifact,
            authoritativeIntact: authoritativeIntact,
            safeHalt: containment == .safeHalt
        )

        return SigilArtifactHealthResult(
            decision: decision,
            failureKind: dominant.failureKind,
            findings: findings,
            recovery: recovery,
            containment: containment
        )
    }

    private func recoveryPlan(
        findings: [SigilArtifactHealthFinding],
        artifact: SigilVisibleGlyphArtifact,
        authoritativeIntact: Bool,
        safeHalt: Bool
    ) -> SigilArtifactHealthRecovery {
        let hidden = artifact.hiddenGeometry
        let visible = artifact.visibleSigil
        let kinds = Set(findings.map(\.checkID))

        guard authoritativeIntact else {
            return Self.noRecovery(
                safeHalt: safeHalt,
                reason: "Authoritative content is not intact; no value is derivable without the true source. Last-verified record preserved."
            )
        }

        // The authoritative half is intact, so the following values are derivable
        // from it. Restate them (never raw personal values) and verify.
        var recovered: [String: String] = [:]
        var actions: [String] = []

        if kinds.contains("artifact.cross-digest") || kinds.contains("artifact.svg-signature") {
            recovered["expected.profileDigest"] = hidden.profileHash
            recovered["expected.canonicalGeometryDigest"] = hidden.canonicalGeometryDigest
            recovered["expected.visibleSignatureHash"] = visible.visibleSignatureHash
            actions.append("restated authoritative digest/identity values from the intact hidden geometry")
        }

        if kinds.contains("artifact.svg-signature") {
            // Re-derive the canonical SVG from the intact visible sigil and
            // verify it carries the signature (a real, non-fabricated check).
            let rederived = producer.renderSVG(for: visible)
            recovered["expected.svg.signatureHash"] = visible.visibleSignatureHash
            recovered["expected.svg.rederived.matchesSignature"] = rederived.contains("data-signature=\"\(visible.visibleSignatureHash)\"") ? "true" : "false"
            actions.append("re-derived the canonical SVG and verified its signature")
        }

        if kinds.contains("artifact.quality-bounds") {
            // A passing visible sigil is regenerable from the intact authoritative
            // hidden geometry (deterministic). Regeneration is a production action
            // and is NOT executed here; the recovery restates the authoritative
            // quality contract so the operator can regenerate and re-validate.
            recovered["quality.segmentBudget"] = "\(SigilArtifactHealthConstants.segmentBudgetLower)...\(SigilArtifactHealthConstants.segmentBudgetUpper)"
            recovered["quality.majorCrossingMaximum"] = "\(SigilArtifactHealthConstants.majorCrossingMaximum)"
            actions.append("restated the authoritative quality contract; regeneration is planned, not executed, under fail-closed health policy")
        }

        // Verify the restated values are well-formed SHA-256 hex digests.
        let digestValues = [
            recovered["expected.profileDigest"],
            recovered["expected.canonicalGeometryDigest"],
            recovered["expected.visibleSignatureHash"]
        ].compactMap { $0 }
        let verificationPassed = digestValues.allSatisfy { Self.isWellFormedSha256Hex($0) }

        let observed: String
        if verificationPassed || digestValues.isEmpty {
            observed = digestValues.isEmpty
                ? "Quality contract restated; nothing to verify against authoritative digests."
                : "Recovered authoritative values verified as well-formed SHA-256 digests."
        } else {
            observed = "Verification failed; no recovery committed; last-verified record preserved."
        }

        return SigilArtifactHealthRecovery(
            attemptedAction: actions.isEmpty
                ? "No non-destructive recovery derivable from intact authoritative content."
                : "Non-destructive in-memory recovery: \(actions.joined(separator: "; ")).",
            expectedResult: "Recovered values match the intact authoritative hidden geometry and carry the canonical visible signature.",
            observedVerification: observed,
            recoveredMetadata: recovered,
            executed: verificationPassed,
            rolledBack: !verificationPassed,
            safeHalt: safeHalt
        )
    }

    // MARK: Shared helpers

    private static func blockedDecision(_ reason: String) -> AeostaraHealthDecision {
        AeostaraHealthDecision(
            status: .blocked,
            mutationAllowed: false,
            requiresBackupBeforeMutation: true,
            requiresVerificationAfterExecution: true,
            requiresOperatorReview: true,
            reason: reason
        )
    }

    private static func noRecovery(safeHalt: Bool, reason: String) -> SigilArtifactHealthRecovery {
        SigilArtifactHealthRecovery(
            attemptedAction: "No recovery executed.",
            expectedResult: "Artifact remains as recorded; no mutation attempted.",
            observedVerification: reason,
            recoveredMetadata: [:],
            executed: false,
            rolledBack: false,
            safeHalt: safeHalt
        )
    }

    private static func decodeArtifact(_ data: Data) -> SigilVisibleGlyphArtifact? {
        try? JSONDecoder().decode(SigilVisibleGlyphArtifact.self, from: data)
    }

    private static func isWellFormedSha256Hex(_ value: String) -> Bool {
        guard value.count == SigilArtifactHealthConstants.sha256HexLength else { return false }
        return value.allSatisfy { $0.isHexDigit }
    }
}
