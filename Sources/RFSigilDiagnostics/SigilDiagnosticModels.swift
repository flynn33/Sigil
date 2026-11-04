import Foundation

// Sigil diagnostic capture models.
//
// These types define the narrow, typed semantic contract shared by the
// development and release diagnostic implementations (see
// SigilDiagnosticCollector). Capture is local only: there is no network
// client, backend, or external service in this module.

public enum SigilDiagnosticProfile: String, Codable, Hashable, Sendable {
    /// Rich development capture: full events, redacted context, detailed incidents.
    case development
    /// Minimal release capture: essential actionable faults and bounded context only.
    case release
}

public struct SigilDiagnosticLimits: Codable, Hashable, Sendable {
    /// Maximum events retained in the in-memory capture queue.
    public var maxQueuedEvents: Int
    /// Maximum serialized size of a single event context, in bytes.
    public var maxContextBytes: Int
    /// Maximum bytes occupied by retained diagnostic bundles on disk.
    public var maxDiskBytes: Int
    /// Maximum number of retained diagnostic bundles before rotation.
    public var maxRetainedBundles: Int
    /// Retention window for retained diagnostic bundles, in seconds.
    public var retentionSeconds: Int
    /// Maximum serialized size of a single export part, in bytes.
    public var maxBundleBytes: Int

    public init(
        maxQueuedEvents: Int = 512,
        maxContextBytes: Int = 4_096,
        maxDiskBytes: Int = 8 * 1_024 * 1_024,
        maxRetainedBundles: Int = 8,
        retentionSeconds: Int = 7 * 24 * 60 * 60,
        maxBundleBytes: Int = 2 * 1_024 * 1_024
    ) {
        self.maxQueuedEvents = maxQueuedEvents
        self.maxContextBytes = maxContextBytes
        self.maxDiskBytes = maxDiskBytes
        self.maxRetainedBundles = maxRetainedBundles
        self.retentionSeconds = retentionSeconds
        self.maxBundleBytes = maxBundleBytes
    }

    public static let `default` = SigilDiagnosticLimits()
}

public struct SigilDiagnosticEnvironment: Codable, Hashable, Sendable {
    public var operatingSystem: String
    public var architecture: String
    /// Host classification: ios-device, ios-simulator, or macos-host.
    public var hostClass: String

    public init(operatingSystem: String, architecture: String, hostClass: String) {
        self.operatingSystem = operatingSystem
        self.architecture = architecture
        self.hostClass = hostClass
    }

    public static func current() -> SigilDiagnosticEnvironment {
        let process = ProcessInfo.processInfo
        var hostClass = "macos-host"
        #if os(iOS)
        #if targetEnvironment(simulator)
        hostClass = "ios-simulator"
        #else
        hostClass = "ios-device"
        #endif
        #endif
        var architecture = "unknown"
        #if arch(arm64)
        architecture = "arm64"
        #elseif arch(x86_64)
        architecture = "x86_64"
        #endif
        return SigilDiagnosticEnvironment(
            operatingSystem: process.operatingSystemVersionString,
            architecture: architecture,
            hostClass: hostClass
        )
    }
}

public struct SigilDiagnosticBuildIdentity: Codable, Hashable, Sendable {
    public var productVersion: String?
    public var buildNumber: String?
    /// Never inferred from a version label. Nil with a reason when unavailable.
    public var sourceCommit: String?
    public var sourceCommitUnavailableReason: String?
    /// Safe component versions, for example the Forsetti runtime version.
    public var componentVersions: [String: String]

    public init(
        productVersion: String?,
        buildNumber: String?,
        sourceCommit: String?,
        sourceCommitUnavailableReason: String? = nil,
        componentVersions: [String: String] = [:]
    ) {
        self.productVersion = productVersion
        self.buildNumber = buildNumber
        self.sourceCommit = sourceCommit
        self.sourceCommitUnavailableReason = sourceCommitUnavailableReason
        self.componentVersions = componentVersions
    }
}

public enum SigilDiagnosticSeverity: String, Codable, Hashable, Sendable {
    case info
    case notice
    case warning
    case error
}

public enum SigilDiagnosticOutcome: String, Codable, Hashable, Sendable {
    case success
    case blocked
}

/// A typed, redactable diagnostic value. Non-finite numbers are normalized
/// before persistence so exports never contain invalid JSON numbers.
public indirect enum SigilDiagnosticValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case array([SigilDiagnosticValue])
    case object([String: SigilDiagnosticValue])
}

/// A reference type because the diagnostic error model must represent a
/// causal chain of arbitrary (bounded) depth; value types cannot store a
/// self-recursive optional in this toolchain.
public final class SigilDiagnosticError: Codable, Hashable, Sendable {
    public let domain: String
    public let code: Int
    public let message: String
    /// Underlying error, nearest to the cause first at the top of the chain.
    public let underlyingError: SigilDiagnosticError?
    public let sourceLocation: String?

    public init(
        domain: String,
        code: Int,
        message: String,
        underlyingError: SigilDiagnosticError? = nil,
        sourceLocation: String? = nil
    ) {
        self.domain = domain
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
        self.sourceLocation = sourceLocation
    }

    public static func == (
        lhs: SigilDiagnosticError,
        rhs: SigilDiagnosticError
    ) -> Bool {
        lhs.domain == rhs.domain
            && lhs.code == rhs.code
            && lhs.message == rhs.message
            && lhs.sourceLocation == rhs.sourceLocation
            && lhs.underlyingError == rhs.underlyingError
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(domain)
        hasher.combine(code)
        hasher.combine(message)
        hasher.combine(sourceLocation)
        hasher.combine(underlyingError)
    }

    /// Adapts a thrown error to the typed diagnostic form. Underlying error
    /// extraction is best-effort: Swift does not expose a universal
    /// underlying-error interface, so only NSError-style wrapping is
    /// unwrapped; everything else is recorded as observed.
    public static func fromThrown(_ error: Error) -> SigilDiagnosticError {
        fromThrown(error, depth: 0)
    }

    private static func fromThrown(_ error: Error, depth: Int) -> SigilDiagnosticError {
        if let typed = error as? SigilDiagnosticError {
            return typed
        }
        let nsError = error as NSError
        let message = nsError.localizedDescription.isEmpty
            ? String(reflecting: type(of: error))
            : nsError.localizedDescription
        var underlying: SigilDiagnosticError?
        if depth < 8,
           let wrapped = nsError.userInfo[NSUnderlyingErrorKey] as? Error,
           (wrapped as AnyObject) !== (error as AnyObject) {
            underlying = fromThrown(wrapped, depth: depth + 1)
        }
        return SigilDiagnosticError(
            domain: String(reflecting: type(of: error)),
            code: nsError.code,
            message: message,
            underlyingError: underlying
        )
    }

    /// Orders the causal chain from this error toward the root cause.
    /// Depth is bounded to prevent pathological hand-built cycles.
    public var chain: [SigilDiagnosticError] {
        var result = [self]
        var current = self
        var depth = 0
        while let next = current.underlyingError, depth < 8 {
            result.append(next)
            current = next
            depth += 1
        }
        return result
    }
}

/// Caller-supplied event data. The collector assigns stable ID, sequence,
/// and UTC timestamp before retention.
public struct SigilDiagnosticEventInput: Hashable, Sendable {
    public var source: String
    public var severity: SigilDiagnosticSeverity
    public var type: String
    public var message: String
    public var operationID: String?
    public var correlationID: String?
    public var outcome: String?
    public var durationSeconds: Double?
    public var context: [String: SigilDiagnosticValue]
    public var error: SigilDiagnosticError?

    public init(
        source: String,
        severity: SigilDiagnosticSeverity,
        type: String,
        message: String,
        operationID: String? = nil,
        correlationID: String? = nil,
        outcome: String? = nil,
        durationSeconds: Double? = nil,
        context: [String: SigilDiagnosticValue] = [:],
        error: SigilDiagnosticError? = nil
    ) {
        self.source = source
        self.severity = severity
        self.type = type
        self.message = message
        self.operationID = operationID
        self.correlationID = correlationID
        self.outcome = outcome
        self.durationSeconds = durationSeconds
        self.context = context
        self.error = error
    }
}

public struct SigilDiagnosticEvent: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let sequence: UInt64
    public var source: String
    public var severity: SigilDiagnosticSeverity
    public var type: String
    public var message: String
    public var operationID: String?
    public var correlationID: String?
    public var outcome: String?
    public var durationSeconds: Double?
    public var durationUnit: String?
    public var context: [String: SigilDiagnosticValue]
    public var error: SigilDiagnosticError?

    public init(
        id: String,
        timestamp: Date,
        sequence: UInt64,
        source: String,
        severity: SigilDiagnosticSeverity,
        type: String,
        message: String,
        operationID: String?,
        correlationID: String?,
        outcome: String?,
        durationSeconds: Double?,
        durationUnit: String?,
        context: [String: SigilDiagnosticValue],
        error: SigilDiagnosticError?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sequence = sequence
        self.source = source
        self.severity = severity
        self.type = type
        self.message = message
        self.operationID = operationID
        self.correlationID = correlationID
        self.outcome = outcome
        self.durationSeconds = durationSeconds
        self.durationUnit = durationUnit
        self.context = context
        self.error = error
    }
}

public struct SigilDiagnosticOperation: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let expected: String
    public let correlationID: String?
    public let startedAt: Date
    public let startedSequence: UInt64

    public init(
        id: String,
        name: String,
        expected: String,
        correlationID: String?,
        startedAt: Date,
        startedSequence: UInt64
    ) {
        self.id = id
        self.name = name
        self.expected = expected
        self.correlationID = correlationID
        self.startedAt = startedAt
        self.startedSequence = startedSequence
    }
}

public struct SigilDiagnosticRecoveryAttempt: Codable, Hashable, Sendable {
    public var description: String
    public var result: String
    public var occurredAt: Date

    public init(description: String, result: String, occurredAt: Date) {
        self.description = description
        self.result = result
        self.occurredAt = occurredAt
    }
}

public struct SigilDiagnosticIncident: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let occurredAt: Date
    public let operationID: String?
    public let operationName: String
    public let expectedBehavior: String
    public let observedBehavior: String
    public let affectedOperations: [String]
    /// Causal chain ordered from the surfaced error toward the root cause.
    public let errorChain: [SigilDiagnosticError]
    /// Retained timeline event IDs correlated to this incident, in sequence order.
    public let timelineEventIDs: [String]
    public let recoveryAttempts: [SigilDiagnosticRecoveryAttempt]
    public let fixtureReferences: [String]
    public let observedFacts: [String]
    public let supportedFindings: [String]
    public let hypotheses: [String]
    public let unknowns: [String]
    public let finalState: String

    public init(
        id: String,
        occurredAt: Date,
        operationID: String?,
        operationName: String,
        expectedBehavior: String,
        observedBehavior: String,
        affectedOperations: [String],
        errorChain: [SigilDiagnosticError],
        timelineEventIDs: [String],
        recoveryAttempts: [SigilDiagnosticRecoveryAttempt],
        fixtureReferences: [String],
        observedFacts: [String],
        supportedFindings: [String],
        hypotheses: [String],
        unknowns: [String],
        finalState: String
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.operationID = operationID
        self.operationName = operationName
        self.expectedBehavior = expectedBehavior
        self.observedBehavior = observedBehavior
        self.affectedOperations = affectedOperations
        self.errorChain = errorChain
        self.timelineEventIDs = timelineEventIDs
        self.recoveryAttempts = recoveryAttempts
        self.fixtureReferences = fixtureReferences
        self.observedFacts = observedFacts
        self.supportedFindings = supportedFindings
        self.hypotheses = hypotheses
        self.unknowns = unknowns
        self.finalState = finalState
    }
}

public struct SigilDiagnosticHealth: Codable, Hashable, Sendable {
    public var retainedEventCount: Int
    /// Dropped event counts keyed by loss mechanism (for example queueOverflow).
    public var droppedEventCounts: [String: Int]
    public var contextTruncatedCount: Int
    /// Context payloads dropped by the active capture scope (release profile).
    public var contextDroppedCount: Int
    public var redactionCount: Int
    public var nonFiniteNormalizedCount: Int
    /// Bounded list of recent collector/storage/export failures.
    public var collectorFailures: [String]
    /// Unavailable identity or source fields, each with its reason.
    public var unavailableSources: [String]
    /// Declared coverage limits for the active profile and implementation.
    public var missingCoverage: [String]

    public init() {
        self.retainedEventCount = 0
        self.droppedEventCounts = [:]
        self.contextTruncatedCount = 0
        self.contextDroppedCount = 0
        self.redactionCount = 0
        self.nonFiniteNormalizedCount = 0
        self.collectorFailures = []
        self.unavailableSources = []
        self.missingCoverage = []
    }
}

/// One consistent, redacted snapshot of captured evidence. Both export
/// formats are generated from this single snapshot.
public struct SigilDiagnosticSnapshot: Codable, Hashable, Sendable {
    public static let schemaVersion = "sigil.diagnostics.export/1.0"

    public let bundleID: String
    public let schemaVersion: String
    public let profile: SigilDiagnosticProfile
    public let generatedAt: Date
    public let captureStart: Date
    public let captureEnd: Date
    /// completeWithinCaptureWindow, partial:queueOverflow, or noSession.
    public let coverageStatus: String
    public let sessionID: String
    public let buildIdentity: SigilDiagnosticBuildIdentity
    public let environment: SigilDiagnosticEnvironment
    public let events: [SigilDiagnosticEvent]
    public let incidents: [SigilDiagnosticIncident]
    public let health: SigilDiagnosticHealth

    public init(
        bundleID: String,
        schemaVersion: String,
        profile: SigilDiagnosticProfile,
        generatedAt: Date,
        captureStart: Date,
        captureEnd: Date,
        coverageStatus: String,
        sessionID: String,
        buildIdentity: SigilDiagnosticBuildIdentity,
        environment: SigilDiagnosticEnvironment,
        events: [SigilDiagnosticEvent],
        incidents: [SigilDiagnosticIncident],
        health: SigilDiagnosticHealth
    ) {
        self.bundleID = bundleID
        self.schemaVersion = schemaVersion
        self.profile = profile
        self.generatedAt = generatedAt
        self.captureStart = captureStart
        self.captureEnd = captureEnd
        self.coverageStatus = coverageStatus
        self.sessionID = sessionID
        self.buildIdentity = buildIdentity
        self.environment = environment
        self.events = events
        self.incidents = incidents
        self.health = health
    }
}

public struct SigilDiagnosticExportResult: Hashable, Sendable {
    public let bundleID: String
    public let jsonPath: String
    public let markdownPath: String
    public let jsonSHA256: String
    public let markdownSHA256: String
    public let eventCount: Int
    public let incidentCount: Int
    public let redactionCount: Int

    public init(
        bundleID: String,
        jsonPath: String,
        markdownPath: String,
        jsonSHA256: String,
        markdownSHA256: String,
        eventCount: Int,
        incidentCount: Int,
        redactionCount: Int
    ) {
        self.bundleID = bundleID
        self.jsonPath = jsonPath
        self.markdownPath = markdownPath
        self.jsonSHA256 = jsonSHA256
        self.markdownSHA256 = markdownSHA256
        self.eventCount = eventCount
        self.incidentCount = incidentCount
        self.redactionCount = redactionCount
    }
}

public enum SigilDiagnosticExportError: Error, Hashable, Sendable {
    case storageUnavailable(String)
    case partWriteFailed(String)
    case bundleExceedsLimit(bytes: Int, limit: Int)
    case serializationFailed(String)
    case readbackMismatch(String)
}
