import Foundation

/// The narrow, typed public contract for Sigil diagnostics.
///
/// Business features depend on this contract only; the selected
/// implementation is injected at the composition boundary. Both
/// implementations honor the same semantic contract: local-only capture,
/// redaction before persistence, correlated incidents, bounded resources,
/// and the paired JSON/Markdown export. Switching implementations does not
/// change business results or product failure behavior.
public protocol SigilDiagnosticCollector: Sendable {
    /// The active capture profile.
    var profile: SigilDiagnosticProfile { get }
    /// The active resource limits.
    var limits: SigilDiagnosticLimits { get }

    /// Starts the diagnostic session. Idempotent: the first call wins and
    /// later calls are no-ops. When no session has started explicitly, the
    /// first capture auto-starts one and records the missing identity.
    func beginSession(
        buildIdentity: SigilDiagnosticBuildIdentity,
        environment: SigilDiagnosticEnvironment
    )

    /// Begins a tracked operation and returns its correlation ID.
    @discardableResult
    func beginOperation(name: String, expected: String, correlationID: String?) -> String

    /// Records a caller-supplied structured event.
    func record(_ input: SigilDiagnosticEventInput)

    /// Finishes a tracked operation with a success or blocked outcome.
    func finishOperation(
        id: String,
        outcome: SigilDiagnosticOutcome,
        context: [String: SigilDiagnosticValue],
        durationSeconds: Double?
    )

    /// Records a controlled failure: a typed error, expected versus observed
    /// behavior, recovery attempts, and fixture references become a
    /// correlated incident. Returns the incident ID. A collector failure
    /// never erases the product error being captured.
    @discardableResult
    func recordFailure(
        operationID: String?,
        operationName: String,
        expectedBehavior: String,
        observedBehavior: String,
        error: SigilDiagnosticError,
        context: [String: SigilDiagnosticValue],
        recoveryAttempts: [SigilDiagnosticRecoveryAttempt],
        fixtureReferences: [String],
        observedFacts: [String],
        supportedFindings: [String],
        hypotheses: [String],
        unknowns: [String],
        finalState: String
    ) -> String

    /// Returns one consistent redacted snapshot of the captured evidence.
    func snapshot() -> SigilDiagnosticSnapshot

    /// Writes the paired detailed JSON/Markdown export (plus bundle
    /// manifest) to the given directory, or the default protected local
    /// storage when nil. Throws a typed diagnostic export error on
    /// storage, serialization, size, or read-back failure.
    func exportBundle(to directory: URL?) throws -> SigilDiagnosticExportResult

    /// Returns the current bounded diagnostic health accounting.
    func health() -> SigilDiagnosticHealth
}

/// Rich development diagnostic implementation: full operation tracing,
/// redacted context snapshots, and detailed correlated failure accounts.
public final class SigilDevelopmentDiagnostics: SigilDiagnosticCollector, @unchecked Sendable {
    private let engine: SigilDiagnosticEngine

    public init(limits: SigilDiagnosticLimits = .default, storageDirectory: URL? = nil) {
        self.engine = SigilDiagnosticEngine(scope: .full, limits: limits, storageDirectory: storageDirectory)
    }

    public var profile: SigilDiagnosticProfile { engine.profile }
    public var limits: SigilDiagnosticLimits { engine.limits }

    public func beginSession(buildIdentity: SigilDiagnosticBuildIdentity, environment: SigilDiagnosticEnvironment) {
        engine.beginSession(buildIdentity: buildIdentity, environment: environment)
    }

    @discardableResult
    public func beginOperation(name: String, expected: String, correlationID: String?) -> String {
        engine.beginOperation(name: name, expected: expected, correlationID: correlationID)
    }

    public func record(_ input: SigilDiagnosticEventInput) {
        engine.record(input)
    }

    public func finishOperation(
        id: String,
        outcome: SigilDiagnosticOutcome,
        context: [String: SigilDiagnosticValue],
        durationSeconds: Double?
    ) {
        engine.finishOperation(id: id, outcome: outcome, context: context, durationSeconds: durationSeconds)
    }

    @discardableResult
    public func recordFailure(
        operationID: String?,
        operationName: String,
        expectedBehavior: String,
        observedBehavior: String,
        error: SigilDiagnosticError,
        context: [String: SigilDiagnosticValue],
        recoveryAttempts: [SigilDiagnosticRecoveryAttempt],
        fixtureReferences: [String],
        observedFacts: [String],
        supportedFindings: [String],
        hypotheses: [String],
        unknowns: [String],
        finalState: String
    ) -> String {
        engine.recordFailure(
            operationID: operationID,
            operationName: operationName,
            expectedBehavior: expectedBehavior,
            observedBehavior: observedBehavior,
            error: error,
            context: context,
            recoveryAttempts: recoveryAttempts,
            fixtureReferences: fixtureReferences,
            observedFacts: observedFacts,
            supportedFindings: supportedFindings,
            hypotheses: hypotheses,
            unknowns: unknowns,
            finalState: finalState
        )
    }

    public func snapshot() -> SigilDiagnosticSnapshot {
        engine.snapshot()
    }

    public func exportBundle(to directory: URL?) throws -> SigilDiagnosticExportResult {
        try engine.exportBundle(to: directory)
    }

    public func health() -> SigilDiagnosticHealth {
        engine.health()
    }
}

/// Minimal release diagnostic implementation: lower-overhead,
/// privacy-minimized capture preserving essential actionable faults and the
/// supported paired export route. It is not a no-op: operation
/// start/finish, failure events, incidents with error chains, and health
/// accounting are retained, while context payloads and ad-hoc non-error
/// events are dropped and accounted for.
public final class SigilReleaseDiagnostics: SigilDiagnosticCollector, @unchecked Sendable {
    private let engine: SigilDiagnosticEngine

    public init(limits: SigilDiagnosticLimits = .default, storageDirectory: URL? = nil) {
        self.engine = SigilDiagnosticEngine(scope: .minimal, limits: limits, storageDirectory: storageDirectory)
    }

    public var profile: SigilDiagnosticProfile { engine.profile }
    public var limits: SigilDiagnosticLimits { engine.limits }

    public func beginSession(buildIdentity: SigilDiagnosticBuildIdentity, environment: SigilDiagnosticEnvironment) {
        engine.beginSession(buildIdentity: buildIdentity, environment: environment)
    }

    @discardableResult
    public func beginOperation(name: String, expected: String, correlationID: String?) -> String {
        engine.beginOperation(name: name, expected: expected, correlationID: correlationID)
    }

    public func record(_ input: SigilDiagnosticEventInput) {
        engine.record(input)
    }

    public func finishOperation(
        id: String,
        outcome: SigilDiagnosticOutcome,
        context: [String: SigilDiagnosticValue],
        durationSeconds: Double?
    ) {
        engine.finishOperation(id: id, outcome: outcome, context: context, durationSeconds: durationSeconds)
    }

    @discardableResult
    public func recordFailure(
        operationID: String?,
        operationName: String,
        expectedBehavior: String,
        observedBehavior: String,
        error: SigilDiagnosticError,
        context: [String: SigilDiagnosticValue],
        recoveryAttempts: [SigilDiagnosticRecoveryAttempt],
        fixtureReferences: [String],
        observedFacts: [String],
        supportedFindings: [String],
        hypotheses: [String],
        unknowns: [String],
        finalState: String
    ) -> String {
        engine.recordFailure(
            operationID: operationID,
            operationName: operationName,
            expectedBehavior: expectedBehavior,
            observedBehavior: observedBehavior,
            error: error,
            context: context,
            recoveryAttempts: recoveryAttempts,
            fixtureReferences: fixtureReferences,
            observedFacts: observedFacts,
            supportedFindings: supportedFindings,
            hypotheses: hypotheses,
            unknowns: unknowns,
            finalState: finalState
        )
    }

    public func snapshot() -> SigilDiagnosticSnapshot {
        engine.snapshot()
    }

    public func exportBundle(to directory: URL?) throws -> SigilDiagnosticExportResult {
        try engine.exportBundle(to: directory)
    }

    public func health() -> SigilDiagnosticHealth {
        engine.health()
    }
}

/// Composition-boundary factory that selects the diagnostic implementation
/// for the active profile.
public enum SigilDiagnosticsFactory {
    public static func collector(
        profile: SigilDiagnosticProfile = .development,
        limits: SigilDiagnosticLimits = .default,
        storageDirectory: URL? = nil
    ) -> any SigilDiagnosticCollector {
        switch profile {
        case .development:
            return SigilDevelopmentDiagnostics(limits: limits, storageDirectory: storageDirectory)
        case .release:
            return SigilReleaseDiagnostics(limits: limits, storageDirectory: storageDirectory)
        }
    }
}
