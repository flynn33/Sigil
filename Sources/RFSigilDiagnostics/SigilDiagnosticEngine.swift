import Foundation

/// Shared capture engine behind the development and release diagnostic
/// implementations. It owns the session, the bounded event queue, operation
/// correlation, incident construction, health accounting, and the
/// consistent snapshot boundary used by exports.
///
/// Concurrency: all state is guarded by a lock; exports operate on a
/// snapshot copy so capture may continue while a bundle is written. A
/// collector failure is recorded in bounded health state and never replaces
/// the product error it happened to capture.
final class SigilDiagnosticEngine: @unchecked Sendable {
    enum CaptureScope {
        case full
        case minimal
    }

    private let lock = NSLock()
    private let scope: CaptureScope
    private let diagnosticLimits: SigilDiagnosticLimits
    private let storageDirectory: URL?

    private var sessionStarted = false
    private var sessionID = ""
    private var captureStart = Date.distantPast
    private var buildIdentity = SigilDiagnosticBuildIdentity(
        productVersion: nil,
        buildNumber: nil,
        sourceCommit: nil
    )
    private var environment = SigilDiagnosticEnvironment.current()
    private var events: [SigilDiagnosticEvent] = []
    private var incidents: [SigilDiagnosticIncident] = []
    private var operations: [String: SigilDiagnosticOperation] = [:]
    private var sequence: UInt64 = 0
    private var healthState = SigilDiagnosticHealth()

    init(scope: CaptureScope, limits: SigilDiagnosticLimits, storageDirectory: URL?) {
        self.scope = scope
        self.diagnosticLimits = limits
        self.storageDirectory = storageDirectory
        if scope == .minimal {
            healthState.missingCoverage = [
                "context capture disabled in release profile",
                "ad-hoc non-error events outside essential scope are dropped in release profile",
                "stack frames are not captured on this platform path"
            ]
        } else {
            healthState.missingCoverage = [
                "stack frames are not captured on this platform path"
            ]
        }
    }

    var profile: SigilDiagnosticProfile {
        scope == .full ? .development : .release
    }

    var limits: SigilDiagnosticLimits {
        diagnosticLimits
    }

    // MARK: - Session

    func beginSession(buildIdentity: SigilDiagnosticBuildIdentity, environment: SigilDiagnosticEnvironment) {
        lock.lock()
        defer { lock.unlock() }
        guard !sessionStarted else { return }
        self.buildIdentity = buildIdentity
        self.environment = environment
        sessionStarted = true
        sessionID = UUID().uuidString
        captureStart = Date()
        recordUnavailableIdentity()
        appendEvent(
            type: "sigil.diagnostic.session.started",
            severity: .notice,
            message: "diagnostic session started (\(profile) profile, queue limit \(diagnosticLimits.maxQueuedEvents) events)"
        )
    }

    private func ensureSessionLocked() {
        guard !sessionStarted else { return }
        sessionStarted = true
        sessionID = UUID().uuidString
        captureStart = Date()
        healthState.unavailableSources.append(
            "buildIdentity: session auto-started without injected build identity"
        )
        appendEvent(
            type: "sigil.diagnostic.session.auto-started",
            severity: .notice,
            message: "diagnostic session auto-started before explicit build identity was provided"
        )
    }

    private func recordUnavailableIdentity() {
        if buildIdentity.sourceCommit == nil {
            healthState.unavailableSources.append(
                "sourceCommit: \(buildIdentity.sourceCommitUnavailableReason ?? "unavailable; no reason recorded")"
            )
        }
        if buildIdentity.productVersion == nil {
            healthState.unavailableSources.append("productVersion: not present in running bundle")
        }
        if buildIdentity.buildNumber == nil {
            healthState.unavailableSources.append("buildNumber: not present in running bundle")
        }
    }

    // MARK: - Operations and events

    @discardableResult
    func beginOperation(name: String, expected: String, correlationID: String?) -> String {
        lock.lock()
        defer { lock.unlock() }
        ensureSessionLocked()
        let id = UUID().uuidString
        let event = appendEvent(
            type: "sigil.diagnostic.operation.started",
            severity: .info,
            message: "operation \(name) started",
            operationID: id,
            correlationID: correlationID
        )
        operations[id] = SigilDiagnosticOperation(
            id: id,
            name: name,
            expected: expected,
            correlationID: correlationID,
            startedAt: event.timestamp,
            startedSequence: event.sequence
        )
        return id
    }

    func record(_ input: SigilDiagnosticEventInput) {
        lock.lock()
        defer { lock.unlock() }
        if scope == .minimal, input.error == nil, input.severity != .error {
            healthState.droppedEventCounts["releaseProfileScope", default: 0] += 1
            return
        }
        appendEvent(
            type: input.type,
            severity: input.severity,
            message: input.message,
            operationID: input.operationID,
            correlationID: input.correlationID,
            outcome: input.outcome,
            durationSeconds: input.durationSeconds,
            context: input.context,
            error: input.error
        )
    }

    func finishOperation(
        id: String,
        outcome: SigilDiagnosticOutcome,
        context: [String: SigilDiagnosticValue],
        durationSeconds: Double?
    ) {
        lock.lock()
        defer { lock.unlock() }
        ensureSessionLocked()
        guard let operation = operations.removeValue(forKey: id) else {
            appendBoundedCollectorFailure("finishOperation called for unknown operation id \(id)")
            return
        }
        _ = appendEvent(
            type: "sigil.diagnostic.operation.finished",
            severity: .notice,
            message: "operation \(operation.name) finished (\(outcome.rawValue))",
            operationID: id,
            correlationID: operation.correlationID,
            outcome: outcome.rawValue,
            durationSeconds: durationSeconds,
            context: context
        )
    }

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
    ) -> String {
        lock.lock()
        defer { lock.unlock() }
        ensureSessionLocked()

        let redactedErrorResult = SigilDiagnosticRedactor.redactError(error)
        healthState.redactionCount += redactedErrorResult.redactionCount
        let redactedError = redactedErrorResult.value

        let failureEvent = appendEvent(
            type: "sigil.diagnostic.operation.failed",
            severity: .error,
            message: "operation \(operationName) failed: \(redactedError.message)",
            operationID: operationID,
            context: context,
            error: redactedError
        )

        let timeline: [String]
        if let operationID {
            timeline = events.filter { $0.operationID == operationID }.map(\.id)
        } else {
            timeline = [failureEvent.id]
        }

        let incident = SigilDiagnosticIncident(
            id: UUID().uuidString,
            occurredAt: failureEvent.timestamp,
            operationID: operationID,
            operationName: operationName,
            expectedBehavior: expectedBehavior,
            observedBehavior: observedBehavior,
            affectedOperations: operationID.map { [$0] } ?? [],
            errorChain: redactedError.chain,
            timelineEventIDs: timeline,
            recoveryAttempts: recoveryAttempts,
            fixtureReferences: fixtureReferences,
            observedFacts: observedFacts,
            supportedFindings: supportedFindings,
            hypotheses: hypotheses,
            unknowns: unknowns,
            finalState: finalState
        )
        if incidents.count >= 64 {
            healthState.droppedEventCounts["incidentOverflow", default: 0] += 1
        } else {
            incidents.append(incident)
        }
        return incident.id
    }

    // MARK: - Snapshot and health

    func snapshot() -> SigilDiagnosticSnapshot {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        let start = sessionStarted ? captureStart : now
        let end = events.last?.timestamp ?? start
        var coverageStatus = "completeWithinCaptureWindow"
        if !sessionStarted {
            coverageStatus = "noSession"
        } else if healthState.droppedEventCounts["queueOverflow", default: 0] > 0 {
            coverageStatus = "partial:queueOverflow"
        }
        var healthCopy = healthState
        healthCopy.retainedEventCount = events.count
        return SigilDiagnosticSnapshot(
            bundleID: UUID().uuidString,
            schemaVersion: SigilDiagnosticSnapshot.schemaVersion,
            profile: profile,
            generatedAt: now,
            captureStart: start,
            captureEnd: end,
            coverageStatus: coverageStatus,
            sessionID: sessionStarted ? sessionID : "unavailable",
            buildIdentity: buildIdentity,
            environment: environment,
            events: events,
            incidents: incidents,
            health: healthCopy
        )
    }

    func health() -> SigilDiagnosticHealth {
        lock.lock()
        defer { lock.unlock() }
        var copy = healthState
        copy.retainedEventCount = events.count
        return copy
    }

    // MARK: - Export

    func exportBundle(to directory: URL?) throws -> SigilDiagnosticExportResult {
        let snapshot = snapshot()
        let storage = directory.map { SigilDiagnosticStorage(directory: $0) }
            ?? SigilDiagnosticStorage(directory: storageDirectory)
        do {
            let result = try SigilDiagnosticExporter.export(
                snapshot: snapshot,
                storage: storage,
                limits: diagnosticLimits
            )
            lock.lock()
            appendEvent(
                type: "sigil.diagnostic.export.completed",
                severity: .info,
                message: "diagnostic bundle exported (\(result.eventCount) events, \(result.incidentCount) incidents)",
                context: [
                    "bundleID": .string(result.bundleID),
                    "eventCount": .number(Double(result.eventCount)),
                    "incidentCount": .number(Double(result.incidentCount)),
                    "redactionCount": .number(Double(result.redactionCount))
                ]
            )
            lock.unlock()
            return result
        } catch {
            lock.lock()
            appendBoundedCollectorFailure("export failed: \(error)")
            lock.unlock()
            throw error
        }
    }

    // MARK: - Internal event pipeline (lock held)

    @discardableResult
    private func appendEvent(
        type: String,
        severity: SigilDiagnosticSeverity,
        message: String,
        operationID: String? = nil,
        correlationID: String? = nil,
        outcome: String? = nil,
        durationSeconds: Double? = nil,
        context: [String: SigilDiagnosticValue] = [:],
        error: SigilDiagnosticError? = nil
    ) -> SigilDiagnosticEvent {
        ensureSessionLocked()

        // Queue bound first: dropped events are not retained, so their
        // payloads are not redacted into health accounting. The returned
        // unretained event is still message-scrubbed because callers may
        // reference it, but it is never persisted or exported.
        if events.count >= diagnosticLimits.maxQueuedEvents {
            healthState.droppedEventCounts["queueOverflow", default: 0] += 1
            sequence += 1
            let droppedEvent = SigilDiagnosticEvent(
                id: UUID().uuidString,
                timestamp: Date(),
                sequence: sequence,
                source: "product",
                severity: severity,
                type: type,
                message: SigilDiagnosticRedactor.scrubText(message).text,
                operationID: operationID,
                correlationID: correlationID,
                outcome: outcome,
                durationSeconds: durationSeconds,
                durationUnit: durationSeconds == nil ? nil : "seconds",
                context: [:],
                error: nil
            )
            return droppedEvent
        }

        // Capture scope: the release profile drops context payloads and
        // accounts for the loss.
        var retainedContext = context
        if scope == .minimal, !context.isEmpty {
            healthState.contextDroppedCount += 1
            retainedContext = [:]
        }

        // Redaction before persistence.
        let messageScrub = SigilDiagnosticRedactor.scrubText(message)
        healthState.redactionCount += messageScrub.redactionCount
        healthState.nonFiniteNormalizedCount += Self.countNonFinite(in: .object(retainedContext))
        let contextRedacted = SigilDiagnosticRedactor.redactContext(retainedContext)
        healthState.redactionCount += contextRedacted.redactionCount
        var redactedContext = contextRedacted.value

        var redactedErrorValue = error
        if let redactedError = error {
            let result = SigilDiagnosticRedactor.redactError(redactedError)
            healthState.redactionCount += result.redactionCount
            redactedErrorValue = result.value
        }

        // Context size bound.
        if let encoded = try? JSONEncoder().encode(redactedContext),
           encoded.count > diagnosticLimits.maxContextBytes {
            redactedContext = .object([
                "[context-truncated]": .string(
                    "serialized context was \(encoded.count) bytes, above the \(diagnosticLimits.maxContextBytes) byte limit"
                )
            ])
            healthState.contextTruncatedCount += 1
        }
        var contextDictionary: [String: SigilDiagnosticValue] = [:]
        if case .object(let fields) = redactedContext {
            contextDictionary = fields
        }

        sequence += 1
        let event = SigilDiagnosticEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            sequence: sequence,
            source: "product",
            severity: severity,
            type: type,
            message: messageScrub.text,
            operationID: operationID,
            correlationID: correlationID,
            outcome: outcome,
            durationSeconds: durationSeconds,
            durationUnit: durationSeconds == nil ? nil : "seconds",
            context: contextDictionary,
            error: redactedErrorValue
        )
        events.append(event)
        return event
    }

    private func appendBoundedCollectorFailure(_ text: String) {
        healthState.collectorFailures.append(text)
        if healthState.collectorFailures.count > 8 {
            healthState.collectorFailures.removeFirst(healthState.collectorFailures.count - 8)
        }
    }

    private static func countNonFinite(in value: SigilDiagnosticValue) -> Int {
        switch value {
        case .number(let number):
            return number.isFinite ? 0 : 1
        case .string, .boolean:
            return 0
        case .array(let elements):
            return elements.reduce(0) { $0 + countNonFinite(in: $1) }
        case .object(let fields):
            return fields.values.reduce(0) { $0 + countNonFinite(in: $1) }
        }
    }
}
