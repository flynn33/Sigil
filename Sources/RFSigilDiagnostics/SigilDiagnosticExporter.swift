import CryptoKit
import Foundation

/// Generates the paired diagnostic export (detailed JSON, detailed Markdown,
/// and a bundle manifest) from one consistent redacted snapshot.
///
/// The JSON document is the structured, versioned export; the Markdown is an
/// equally detailed human-readable report of the same retained evidence. The
/// manifest carries part checksums and redaction accounting so the pair can
/// be verified without a self-referential hash. Both formats are generated
/// from the same redacted snapshot; the export boundary re-checks the final
/// text and records any additional redactions in the manifest.
enum SigilDiagnosticExporter {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).reduce(into: "") { $0 += String(format: "%02x", $1) }
    }

    static func export(
        snapshot: SigilDiagnosticSnapshot,
        storage: SigilDiagnosticStorage,
        limits: SigilDiagnosticLimits
    ) throws -> SigilDiagnosticExportResult {
        let stem = "sigil-diag-\(snapshot.bundleID)"
        let jsonName = "\(stem).json"
        let markdownName = "\(stem).md"
        let manifestName = "\(stem).manifest.json"

        // 1. Markdown from the redacted snapshot.
        var markdownText = buildMarkdown(snapshot: snapshot, jsonPartName: jsonName, manifestName: manifestName)
        let boundaryMarkdown = SigilDiagnosticRedactor.scrubText(markdownText)
        markdownText = boundaryMarkdown.text
        let markdownData = Data(markdownText.utf8)
        let markdownSHA = sha256Hex(markdownData)

        // 2. JSON document from the same snapshot.
        var jsonText = try encodeJSONDocument(snapshot: snapshot)
        let boundaryJSON = SigilDiagnosticRedactor.scrubText(jsonText)
        if boundaryJSON.redactionCount > 0 {
            jsonText = boundaryJSON.text
        }
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw SigilDiagnosticExportError.serializationFailed("export JSON is not valid UTF-8")
        }
        let jsonSHA = sha256Hex(jsonData)

        // 3. Manifest with part checksums and redaction accounting.
        let exportBoundaryCount = boundaryMarkdown.redactionCount + boundaryJSON.redactionCount
        let manifest = ExportManifest(
            schemaVersion: SigilDiagnosticSnapshot.schemaVersion,
            bundleID: snapshot.bundleID,
            profile: snapshot.profile.rawValue,
            generatedAtUTC: snapshot.generatedAt,
            coverageStatus: snapshot.coverageStatus,
            partKind: "paired-json-markdown",
            parts: [
                ExportManifest.PartInfo(file: jsonName, kind: "json", sha256: jsonSHA, bytes: jsonData.count),
                ExportManifest.PartInfo(file: markdownName, kind: "markdown", sha256: markdownSHA, bytes: markdownData.count)
            ],
            redaction: ExportManifest.RedactionSummary(
                prePersistenceCount: snapshot.health.redactionCount,
                exportBoundaryCount: exportBoundaryCount,
                total: snapshot.health.redactionCount + exportBoundaryCount
            )
        )
        let manifestData = try encode(manifest)

        // 4. Size guard before any retention work.
        let largest = max(jsonData.count, markdownData.count, manifestData.count)
        if largest > limits.maxBundleBytes {
            throw SigilDiagnosticExportError.bundleExceedsLimit(bytes: largest, limit: limits.maxBundleBytes)
        }

        // 5. Protected storage directory, then quota/retention.
        try storage.makeDirectory()
        storage.applyQuotaAndRetention(
            maxDiskBytes: limits.maxDiskBytes,
            maxRetainedBundles: limits.maxRetainedBundles,
            retentionSeconds: limits.retentionSeconds,
            now: snapshot.generatedAt
        )

        // 6. Atomic writes; a failed part removes the partial bundle.
        let jsonURL = storage.directory.appendingPathComponent(jsonName)
        let markdownURL = storage.directory.appendingPathComponent(markdownName)
        let manifestURL = storage.directory.appendingPathComponent(manifestName)
        do {
            try storage.writeAtomic(markdownData, to: markdownURL)
            try storage.writeAtomic(jsonData, to: jsonURL)
            try storage.writeAtomic(manifestData, to: manifestURL)
        } catch {
            try? storage.removePart(markdownURL)
            try? storage.removePart(jsonURL)
            try? storage.removePart(manifestURL)
            throw error
        }

        // 7. Read-back verification: success is only claimed when both
        // required formats are present and match their checksums.
        do {
            let readJSON = try Data(contentsOf: jsonURL)
            let readMarkdown = try Data(contentsOf: markdownURL)
            let readManifest = try Data(contentsOf: manifestURL)
            guard sha256Hex(readJSON) == jsonSHA,
                  sha256Hex(readMarkdown) == markdownSHA,
                  sha256Hex(readManifest) == sha256Hex(manifestData) else {
                throw SigilDiagnosticExportError.readbackMismatch(stem)
            }
        } catch let error as SigilDiagnosticExportError {
            throw error
        } catch {
            throw SigilDiagnosticExportError.readbackMismatch("\(stem): \(error.localizedDescription)")
        }

        return SigilDiagnosticExportResult(
            bundleID: snapshot.bundleID,
            jsonPath: jsonURL.path,
            markdownPath: markdownURL.path,
            jsonSHA256: jsonSHA,
            markdownSHA256: markdownSHA,
            eventCount: snapshot.events.count,
            incidentCount: snapshot.incidents.count,
            redactionCount: snapshot.health.redactionCount + exportBoundaryCount
        )
    }

    // MARK: - JSON document

    private static func encodeJSONDocument(snapshot: SigilDiagnosticSnapshot) throws -> String {
        let document = ExportDocument(
            schemaVersion: snapshot.schemaVersion,
            bundleID: snapshot.bundleID,
            generatedAtUTC: snapshot.generatedAt,
            captureStartUTC: snapshot.captureStart,
            captureEndUTC: snapshot.captureEnd,
            coverageStatus: snapshot.coverageStatus,
            profile: snapshot.profile,
            sessionID: snapshot.sessionID,
            buildIdentity: snapshot.buildIdentity,
            environment: snapshot.environment,
            events: snapshot.events,
            incidents: snapshot.incidents,
            health: snapshot.health
        )
        let data = try encode(document)
        guard let text = String(data: data, encoding: .utf8) else {
            throw SigilDiagnosticExportError.serializationFailed("export JSON is not valid UTF-8")
        }
        return text
    }

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(value)
        } catch {
            throw SigilDiagnosticExportError.serializationFailed(error.localizedDescription)
        }
    }

    private struct ExportDocument: Encodable {
        let schemaVersion: String
        let bundleID: String
        let generatedAtUTC: Date
        let captureStartUTC: Date
        let captureEndUTC: Date
        let coverageStatus: String
        let profile: SigilDiagnosticProfile
        let sessionID: String
        let buildIdentity: SigilDiagnosticBuildIdentity
        let environment: SigilDiagnosticEnvironment
        let events: [SigilDiagnosticEvent]
        let incidents: [SigilDiagnosticIncident]
        let health: SigilDiagnosticHealth
    }

    private struct ExportManifest: Encodable {
        let schemaVersion: String
        let bundleID: String
        let profile: String
        let generatedAtUTC: Date
        let coverageStatus: String
        let partKind: String
        let parts: [PartInfo]
        let redaction: RedactionSummary

        struct PartInfo: Encodable {
            let file: String
            let kind: String
            let sha256: String
            let bytes: Int
        }

        struct RedactionSummary: Encodable {
            let prePersistenceCount: Int
            let exportBoundaryCount: Int
            let total: Int
        }
    }

    // MARK: - Markdown report

    private static func buildMarkdown(
        snapshot: SigilDiagnosticSnapshot,
        jsonPartName: String,
        manifestName: String
    ) -> String {
        var lines: [String] = []
        lines.append("# Sigil Diagnostic Bundle `\(snapshot.bundleID)`")
        lines.append("")
        lines.append("- Schema: \(snapshot.schemaVersion)")
        lines.append("- Profile: \(snapshot.profile.rawValue)")
        lines.append("- Generated (UTC): \(isoFormatter.string(from: snapshot.generatedAt))")
        lines.append("- Capture window (UTC): \(isoFormatter.string(from: snapshot.captureStart)) — \(isoFormatter.string(from: snapshot.captureEnd))")
        lines.append("- Coverage: \(snapshot.coverageStatus)")
        lines.append("- Session: \(snapshot.sessionID)")
        lines.append("")

        lines.append("## Product and Environment Identity")
        lines.append("")
        lines.append("| Field | Value |")
        lines.append("|---|---|")
        lines.append(identityRow("Product version", snapshot.buildIdentity.productVersion))
        lines.append(identityRow("Build number", snapshot.buildIdentity.buildNumber))
        if let commit = snapshot.buildIdentity.sourceCommit {
            lines.append(identityRow("Source commit", commit))
        } else {
            lines.append(identityRow(
                "Source commit",
                "unavailable — \(snapshot.buildIdentity.sourceCommitUnavailableReason ?? "no reason recorded")"
            ))
        }
        for (component, version) in snapshot.buildIdentity.componentVersions.sorted(by: { $0.key < $1.key }) {
            lines.append(identityRow("Component: \(component)", version))
        }
        lines.append(identityRow("Operating system", snapshot.environment.operatingSystem))
        lines.append(identityRow("Architecture", snapshot.environment.architecture))
        lines.append(identityRow("Host class", snapshot.environment.hostClass))
        lines.append("")

        lines.append("## Diagnostic Health and Limitations")
        lines.append("")
        lines.append("- Retained events: \(snapshot.health.retainedEventCount)")
        let dropped = snapshot.health.droppedEventCounts.sorted(by: { $0.key < $1.key })
        if dropped.isEmpty {
            lines.append("- Dropped events: none")
        } else {
            lines.append("- Dropped events: \(dropped.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
        }
        lines.append("- Context payloads truncated: \(snapshot.health.contextTruncatedCount)")
        lines.append("- Context payloads dropped by capture scope: \(snapshot.health.contextDroppedCount)")
        lines.append("- Redactions before persistence: \(snapshot.health.redactionCount) (export-boundary re-check recorded in the manifest)")
        lines.append("- Non-finite values normalized: \(snapshot.health.nonFiniteNormalizedCount)")
        lines.append("- Collector failures: \(snapshot.health.collectorFailures.isEmpty ? "none" : snapshot.health.collectorFailures.joined(separator: "; "))")
        lines.append("- Unavailable sources: \(snapshot.health.unavailableSources.isEmpty ? "none" : snapshot.health.unavailableSources.joined(separator: "; "))")
        lines.append("- Missing coverage: \(snapshot.health.missingCoverage.isEmpty ? "none" : snapshot.health.missingCoverage.joined(separator: "; "))")
        lines.append("")

        if snapshot.incidents.isEmpty {
            lines.append("## Incident Index")
            lines.append("")
            lines.append("No incidents retained in this capture window.")
            lines.append("")
        } else {
            lines.append("## Incident Index")
            lines.append("")
            lines.append("| Incident | Operation | Occurred (UTC) | Final state |")
            lines.append("|---|---|---|---|")
            for incident in snapshot.incidents {
                lines.append("| `\(incident.id)` | \(escapeCell(incident.operationName)) | \(isoFormatter.string(from: incident.occurredAt)) | \(escapeCell(incident.finalState)) |")
            }
            lines.append("")
            for incident in snapshot.incidents {
                lines.append("## Incident `\(incident.id)`")
                lines.append("")
                lines.append("- Operation: \(escapeCell(incident.operationName))\(incident.operationID.map { " (`\($0)`)" } ?? "")")
                lines.append("- Occurred (UTC): \(isoFormatter.string(from: incident.occurredAt))")
                lines.append("")
                lines.append("### Expected Behavior")
                lines.append("")
                lines.append(escapeCell(incident.expectedBehavior))
                lines.append("")
                lines.append("### Observed Behavior")
                lines.append("")
                lines.append(escapeCell(incident.observedBehavior))
                lines.append("")
                lines.append("### Failure Mechanics (error chain, ordered)")
                lines.append("")
                for (index, error) in incident.errorChain.enumerated() {
                    var entry = "\(index + 1). [\(escapeCell(error.domain))] code \(error.code) — \(escapeCell(error.message))"
                    if let location = error.sourceLocation {
                        entry += " (source: \(escapeCell(location)))"
                    }
                    lines.append(entry)
                }
                lines.append("")
                lines.append("### Correlated Timeline")
                lines.append("")
                if incident.timelineEventIDs.isEmpty {
                    lines.append("No retained timeline events correlated to this incident.")
                } else {
                    for eventID in incident.timelineEventIDs {
                        if let event = snapshot.events.first(where: { $0.id == eventID }) {
                            lines.append("- seq \(event.sequence) `\(event.id)` \(escapeCell(event.type)) [\(escapeCell(event.source)), \(event.severity.rawValue)]")
                        } else {
                            lines.append("- `\(eventID)` (not retained in this capture window)")
                        }
                    }
                }
                lines.append("")
                lines.append("### Recovery Attempts")
                lines.append("")
                if incident.recoveryAttempts.isEmpty {
                    lines.append("None recorded.")
                } else {
                    for attempt in incident.recoveryAttempts {
                        lines.append("- \(escapeCell(attempt.description)) — result: \(escapeCell(attempt.result)) (UTC \(isoFormatter.string(from: attempt.occurredAt)))")
                    }
                }
                lines.append("")
                lines.append("### Reproduction")
                lines.append("")
                if incident.fixtureReferences.isEmpty {
                    lines.append("No fixture references recorded.")
                } else {
                    for reference in incident.fixtureReferences {
                        lines.append("- \(escapeCell(reference))")
                    }
                }
                lines.append("")
                lines.append("### Observed Facts")
                lines.append("")
                lines.append(bulletList(incident.observedFacts))
                lines.append("")
                lines.append("### Supported Findings")
                lines.append("")
                lines.append(bulletList(incident.supportedFindings))
                lines.append("")
                lines.append("### Hypotheses")
                lines.append("")
                lines.append(bulletList(incident.hypotheses))
                lines.append("")
                lines.append("### Unknowns")
                lines.append("")
                lines.append(bulletList(incident.unknowns))
                lines.append("")
                lines.append("### Final State")
                lines.append("")
                lines.append(escapeCell(incident.finalState))
                lines.append("")
            }
        }

        lines.append("## Correlated Event Timeline")
        lines.append("")
        if snapshot.events.isEmpty {
            lines.append("No events retained in this capture window.")
        } else {
            lines.append("| Seq | Time (UTC) | Severity | Type | Source | Operation | Message |")
            lines.append("|---|---|---|---|---|---|---|")
            for event in snapshot.events {
                lines.append("| \(event.sequence) | \(isoFormatter.string(from: event.timestamp)) | \(event.severity.rawValue) | \(escapeCell(event.type)) | \(escapeCell(event.source)) | \(event.operationID ?? "—") | \(escapeCell(event.message)) |")
            }
        }
        lines.append("")

        lines.append("## Appendix: Retained Event Evidence")
        lines.append("")
        if snapshot.events.isEmpty {
            lines.append("No retained events to append.")
        } else {
            for event in snapshot.events {
                lines.append("### Event `\(event.id)` (seq \(event.sequence), \(event.type))")
                lines.append("")
                lines.append("````json")
                lines.append(eventJSON(event))
                lines.append("````")
                lines.append("")
            }
        }

        lines.append("## Integrity")
        lines.append("")
        lines.append("- JSON part: \(jsonPartName)")
        lines.append("- Manifest (part checksums, redaction accounting): \(manifestName)")
        lines.append("- Both parts were generated from one redacted snapshot identified by bundle `\(snapshot.bundleID)`.")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func identityRow(_ field: String, _ value: String?) -> String {
        "| \(escapeCell(field)) | \(value.map(escapeCell) ?? "unavailable") |"
    }

    private static func bulletList(_ items: [String]) -> String {
        guard !items.isEmpty else { return "None recorded." }
        return items.map { "- \(escapeCell($0))" }.joined(separator: "\n")
    }

    private static func eventJSON(_ event: SigilDiagnosticEvent) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(event),
              let text = String(data: data, encoding: .utf8) else {
            return "{\"note\": \"event serialization unavailable\"}"
        }
        return text
    }

    /// Escapes a value for a Markdown table cell. Logged content is treated
    /// as data, never as markup or instructions.
    private static func escapeCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
