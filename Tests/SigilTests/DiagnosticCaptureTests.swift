import CryptoKit
import Foundation
import RFSigilDiagnostics
import RFSigilRuntime
import XCTest

/// Focused verification for the R-05 diagnostic capture path:
/// success/failure correlation, paired export identity matching, nested
/// synthetic-secret redaction, concurrent capture/export, queue limits,
/// disk/export failure behavior, unavailable source identity, release
/// profile scoping, and the runtime assembly's instrumented operation.
final class DiagnosticCaptureTests: XCTestCase {
    private var tempDirectories: [URL] = []

    override func setUp() {
        super.setUp()
        tempDirectories = []
    }

    override func tearDown() {
        for directory in tempDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        tempDirectories = []
        super.tearDown()
    }

    private func makeTempDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sigil-diag-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        tempDirectories.append(directory)
        return directory
    }

    private func testBuildIdentity(sourceCommit: String? = "0123456789abcdef0123456789abcdef01234567") -> SigilDiagnosticBuildIdentity {
        SigilDiagnosticBuildIdentity(
            productVersion: "PA.0.1.0",
            buildNumber: "1",
            sourceCommit: sourceCommit,
            sourceCommitUnavailableReason: sourceCommit == nil ? "not injected in test" : nil,
            componentVersions: ["forsetti": "0.1.4"]
        )
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).reduce(into: "") { $0 += String(format: "%02x", $1) }
    }

    func testSuccessAndControlledFailureCorrelateIntoIncident() {
        let storage = try! makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )

        // One successful operation.
        let successOperationID = collector.beginOperation(
            name: "fixture.success",
            expected: "fixture-alpha resolves to a stable value",
            correlationID: nil
        )
        collector.record(
            SigilDiagnosticEventInput(
                source: "SigilTests",
                severity: .info,
                type: "fixture.load",
                message: "loading fixture-alpha",
                operationID: successOperationID,
                context: ["fixture": .string("fixture-alpha")]
            )
        )
        collector.finishOperation(
            id: successOperationID,
            outcome: .success,
            context: ["fixture": .string("fixture-alpha")],
            durationSeconds: 0.004
        )

        // One controlled failure.
        let failureOperationID = collector.beginOperation(
            name: "fixture.failure",
            expected: "fixture-alpha resolves to a stable value",
            correlationID: nil
        )
        collector.record(
            SigilDiagnosticEventInput(
                source: "SigilTests",
                severity: .info,
                type: "fixture.resolve",
                message: "resolving fixture-alpha",
                operationID: failureOperationID
            )
        )
        let incidentID = collector.recordFailure(
            operationID: failureOperationID,
            operationName: "fixture.failure",
            expectedBehavior: "fixture-alpha resolves to a stable value",
            observedBehavior: "fixture-alpha was rejected during resolution",
            error: SigilDiagnosticError(
                domain: "SigilTest",
                code: 42,
                message: "controlled failure: fixture rejected",
                underlyingError: SigilDiagnosticError(
                    domain: "SigilTest",
                    code: 7,
                    message: "fixture state mismatch"
                )
            ),
            context: ["fixture": .string("fixture-alpha")],
            recoveryAttempts: [
                SigilDiagnosticRecoveryAttempt(
                    description: "retry with alternate fixture",
                    result: "failed: same rejection",
                    occurredAt: Date()
                )
            ],
            fixtureReferences: ["fixture-alpha"],
            observedFacts: ["fixture-alpha load was attempted once"],
            supportedFindings: ["rejection occurred during resolution"],
            hypotheses: ["fixture state loader produced a stale digest"],
            unknowns: ["why the fixture state mismatched"],
            finalState: "unresolved"
        )

        let snapshot = collector.snapshot()
        XCTAssertEqual(snapshot.incidents.count, 1)
        let incident = snapshot.incidents[0]
        XCTAssertEqual(incident.id, incidentID)
        XCTAssertEqual(incident.operationID, failureOperationID)
        XCTAssertEqual(incident.operationName, "fixture.failure")
        XCTAssertEqual(incident.errorChain.count, 2)
        XCTAssertEqual(incident.errorChain[0].code, 42)
        XCTAssertEqual(incident.errorChain[1].code, 7)
        XCTAssertEqual(incident.recoveryAttempts.count, 1)
        XCTAssertEqual(incident.fixtureReferences, ["fixture-alpha"])

        // The success event carries the operation outcome.
        let successEvent = snapshot.events.first {
            $0.type == "sigil.diagnostic.operation.finished" && $0.operationID == successOperationID
        }
        XCTAssertEqual(successEvent?.outcome, "success")

        // The incident timeline correlates the operation's events in order.
        let resolveEvent = snapshot.events.first { $0.type == "fixture.resolve" }
        let failureEvent = snapshot.events.first {
            $0.type == "sigil.diagnostic.operation.failed" && $0.operationID == failureOperationID
        }
        XCTAssertNotNil(resolveEvent)
        XCTAssertNotNil(failureEvent)
        XCTAssertEqual(failureEvent?.severity, .error)
        XCTAssertEqual(failureEvent?.error?.code, 42)
        let timeline = incident.timelineEventIDs
        guard let resolveEvent, let failureEvent,
              let resolveIndex = timeline.firstIndex(of: resolveEvent.id),
              let failureIndex = timeline.firstIndex(of: failureEvent.id) else {
            return XCTFail("incident timeline is missing the correlated events")
        }
        XCTAssertLessThan(resolveIndex, failureIndex)
        XCTAssertEqual(timeline, snapshot.events.filter { $0.operationID == failureOperationID }.map(\.id))
    }

    func testExportProducesMatchingJSONAndMarkdown() throws {
        let storage = try makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        let operationID = collector.beginOperation(
            name: "fixture.export",
            expected: "export bundle parts match the snapshot",
            correlationID: nil
        )
        collector.finishOperation(
            id: operationID,
            outcome: .success,
            context: ["fixture": .string("fixture-alpha")],
            durationSeconds: 0.002
        )
        let incidentID = collector.recordFailure(
            operationID: nil,
            operationName: "fixture.export",
            expectedBehavior: "export bundle parts match the snapshot",
            observedBehavior: "controlled failure recorded for export correlation",
            error: SigilDiagnosticError(domain: "SigilTest", code: 1, message: "controlled export failure"),
            context: [:],
            recoveryAttempts: [],
            fixtureReferences: ["fixture-alpha"],
            observedFacts: [],
            supportedFindings: [],
            hypotheses: [],
            unknowns: [],
            finalState: "unresolved"
        )

        let result = try collector.exportBundle(to: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.jsonPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.markdownPath))

        let jsonData = try Data(contentsOf: URL(fileURLWithPath: result.jsonPath))
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        XCTAssertEqual(json["schema_version"] as? String, SigilDiagnosticSnapshot.schemaVersion)
        XCTAssertEqual(json["bundle_id"] as? String, result.bundleID)
        XCTAssertEqual(json["profile"] as? String, "development")
        let sessionID = json["session_id"] as? String
        XCTAssertNotNil(sessionID)
        XCTAssertNotEqual(sessionID, "unavailable")
        let events = json["events"] as! [[String: Any]]
        let incidents = json["incidents"] as! [[String: Any]]
        XCTAssertEqual(events.count, result.eventCount)
        XCTAssertEqual(incidents.count, result.incidentCount)
        XCTAssertEqual(incidents[0]["id"] as? String, incidentID)
        XCTAssertNotNil(json["health"])
        XCTAssertNotNil(json["build_identity"])
        XCTAssertNotNil(json["environment"])
        XCTAssertEqual(sha256Hex(jsonData), result.jsonSHA256)

        let markdownData = try Data(contentsOf: URL(fileURLWithPath: result.markdownPath))
        let markdown = String(data: markdownData, encoding: .utf8)!
        XCTAssertEqual(sha256Hex(markdownData), result.markdownSHA256)
        XCTAssertTrue(markdown.contains(result.bundleID))
        XCTAssertTrue(markdown.contains(incidentID))
        XCTAssertTrue(markdown.contains(SigilDiagnosticSnapshot.schemaVersion))
        // The markdown timeline references the retained events.
        for event in events {
            let eventID = event["id"] as! String
            XCTAssertTrue(markdown.contains(eventID), "markdown is missing event \(eventID)")
        }

        // The manifest carries part checksums matching the files on disk.
        let manifestName = (result.jsonPath as NSString).deletingPathExtension + ".manifest.json"
        let manifestData = try Data(contentsOf: URL(fileURLWithPath: manifestName))
        let manifest = try JSONSerialization.jsonObject(with: manifestData) as! [String: Any]
        XCTAssertEqual(manifest["bundle_id"] as? String, result.bundleID)
        let parts = manifest["parts"] as! [[String: Any]]
        let jsonPart = parts.first { $0["file"] as? String == (result.jsonPath as NSString).lastPathComponent }
        let markdownPart = parts.first { $0["file"] as? String == (result.markdownPath as NSString).lastPathComponent }
        XCTAssertEqual(jsonPart?["sha256"] as? String, result.jsonSHA256)
        XCTAssertEqual(markdownPart?["sha256"] as? String, result.markdownSHA256)
        let redaction = manifest["redaction"] as! [String: Any]
        let total = redaction["total"] as! Int
        XCTAssertEqual(total, result.redactionCount)
    }

    func testNestedSyntheticSecretRedaction() throws {
        let storage = try makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        collector.record(
            SigilDiagnosticEventInput(
                source: "SigilTests",
                severity: .info,
                type: "request.capture",
                message: "capturing synthetic request payload",
                context: [
                    "request": .string(
                        "{\"authorization\": \"Bearer SYNTHETIC_SECRET_VALUE_0001\", \"user\": \"dev-fixture\"}"
                    ),
                    "api_key": .string("SYNTHETIC_SECRET_VALUE_0002")
                ]
            )
        )
        let result = try collector.exportBundle(to: nil)
        let jsonText = String(data: try Data(contentsOf: URL(fileURLWithPath: result.jsonPath)), encoding: .utf8)!
        let markdownText = String(data: try Data(contentsOf: URL(fileURLWithPath: result.markdownPath)), encoding: .utf8)!

        // Synthetic secrets must not survive in either export format.
        XCTAssertFalse(jsonText.contains("SYNTHETIC_SECRET_VALUE_0001"))
        XCTAssertFalse(jsonText.contains("SYNTHETIC_SECRET_VALUE_0002"))
        XCTAssertFalse(markdownText.contains("SYNTHETIC_SECRET_VALUE_0001"))
        XCTAssertFalse(markdownText.contains("SYNTHETIC_SECRET_VALUE_0002"))
        // Non-secret nested content is preserved.
        XCTAssertTrue(jsonText.contains("dev-fixture"))
        // Redactions are accounted for.
        XCTAssertGreaterThanOrEqual(collector.health().redactionCount, 2)
        XCTAssertGreaterThanOrEqual(result.redactionCount, 2)
    }

    func testConcurrentRecordAndExport() throws {
        let storage = try makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )

        DispatchQueue.concurrentPerform(iterations: 8) { iteration in
            for index in 0..<25 {
                collector.record(
                    SigilDiagnosticEventInput(
                        source: "SigilTests",
                        severity: .info,
                        type: "concurrent.\(iteration).\(index)",
                        message: "concurrent capture"
                    )
                )
            }
        }

        let exportRoot = try makeTempDirectory()
        let group = DispatchGroup()
        let lock = NSLock()
        var results: [SigilDiagnosticExportResult] = []
        var failures: [String] = []
        DispatchQueue.concurrentPerform(iterations: 4) { iteration in
            group.enter()
            do {
                let result = try collector.exportBundle(
                    to: exportRoot.appendingPathComponent("export-\(iteration)", isDirectory: true)
                )
                lock.lock()
                results.append(result)
                lock.unlock()
            } catch {
                lock.lock()
                failures.append("\(iteration): \(error)")
                lock.unlock()
            }
            group.leave()
        }
        XCTAssertEqual(group.wait(timeout: .now() + 60), .success)
        XCTAssertTrue(failures.isEmpty, "concurrent exports failed: \(failures)")
        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(Set(results.map(\.bundleID)).count, 4, "each export must be a distinct snapshot")

        for result in results {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: result.jsonPath))
            let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            XCTAssertEqual(json["bundle_id"] as? String, result.bundleID)
            let events = json["events"] as? [[String: Any]] ?? []
            XCTAssertEqual(events.count, result.eventCount)
            XCTAssertEqual(sha256Hex(jsonData), result.jsonSHA256)
        }
        // All retained event IDs referenced by incidents must exist in the snapshot.
        for result in results {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: result.jsonPath))
            let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            let eventIDs = Set((json["events"] as! [[String: Any]]).compactMap { $0["id"] as? String })
            for incident in json["incidents"] as! [[String: Any]] {
                for eventID in incident["timeline_event_ids"] as! [String] {
                    XCTAssertTrue(eventIDs.contains(eventID), "incident references an unretained event")
                }
            }
        }
    }

    func testQueueLimitDropsAreAccounted() throws {
        let storage = try makeTempDirectory()
        let limits = SigilDiagnosticLimits(maxQueuedEvents: 16)
        let collector = SigilDevelopmentDiagnostics(limits: limits, storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        for index in 0..<100 {
            collector.record(
                SigilDiagnosticEventInput(
                    source: "SigilTests",
                    severity: .info,
                    type: "flood.\(index)",
                    message: "queue flood"
                )
            )
        }
        let health = collector.health()
        XCTAssertEqual(health.retainedEventCount, 16)
        XCTAssertEqual(health.droppedEventCounts["queueOverflow"], 85)

        let snapshot = collector.snapshot()
        XCTAssertEqual(snapshot.coverageStatus, "partial:queueOverflow")
        let result = try collector.exportBundle(to: nil)
        XCTAssertEqual(result.eventCount, 16)
        let jsonText = String(data: try Data(contentsOf: URL(fileURLWithPath: result.jsonPath)), encoding: .utf8)!
        XCTAssertTrue(jsonText.contains("partial:queueOverflow"))
    }

    func testDiskFailureIsReportedAndPreservesOriginalError() throws {
        let baseDir = try makeTempDirectory()
        // A file where a storage directory is expected: mkdir must fail.
        let blockerFile = baseDir.appendingPathComponent("blocker")
        try Data([0x00]).write(to: blockerFile)

        let collector = SigilDevelopmentDiagnostics(storageDirectory: blockerFile)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        let operationID = collector.beginOperation(
            name: "fixture.storage",
            expected: "storage is writable",
            correlationID: nil
        )
        collector.recordFailure(
            operationID: operationID,
            operationName: "fixture.storage",
            expectedBehavior: "storage is writable",
            observedBehavior: "storage path is a file",
            error: SigilDiagnosticError(
                domain: "SigilTest",
                code: 42,
                message: "controlled failure: storage should be unavailable"
            ),
            context: [:],
            recoveryAttempts: [],
            fixtureReferences: [],
            observedFacts: [],
            supportedFindings: [],
            hypotheses: [],
            unknowns: [],
            finalState: "unresolved"
        )

        do {
            _ = try collector.exportBundle(to: nil)
            XCTFail("export should have failed with a typed storage error")
        } catch let exportError as SigilDiagnosticExportError {
            guard case .storageUnavailable = exportError else {
                return XCTFail("expected storageUnavailable, got \(exportError)")
            }
        }

        // The original product error is preserved in the captured incident.
        let snapshot = collector.snapshot()
        XCTAssertEqual(snapshot.incidents.count, 1)
        XCTAssertEqual(
            snapshot.incidents[0].errorChain.first?.message,
            "controlled failure: storage should be unavailable"
        )
        // The collector failure is accounted for in health.
        XCTAssertTrue(
            collector.health().collectorFailures.contains { $0.hasPrefix("export failed") }
        )
        // No partial bundle files were left behind.
        let entries = try FileManager.default.contentsOfDirectory(atPath: baseDir.path)
        XCTAssertTrue(entries.filter { $0.hasPrefix("sigil-diag-") }.isEmpty)
    }

    func testUnavailableSourceIdentityRecordedWithReason() throws {
        let storage = try makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(sourceCommit: nil),
            environment: SigilDiagnosticEnvironment.current()
        )
        let result = try collector.exportBundle(to: nil)
        let json = try JSONSerialization.jsonObject(
            with: Data(contentsOf: URL(fileURLWithPath: result.jsonPath))
        ) as! [String: Any]
        let identity = json["build_identity"] as! [String: Any]
        XCTAssertNil(identity["source_commit"])
        XCTAssertEqual(identity["source_commit_unavailable_reason"] as? String, "not injected in test")
        XCTAssertTrue(
            collector.health().unavailableSources.contains { $0.hasPrefix("sourceCommit:") }
        )
        let markdown = String(data: try Data(contentsOf: URL(fileURLWithPath: result.markdownPath)), encoding: .utf8)!
        XCTAssertTrue(markdown.contains("unavailable — not injected in test"))
    }

    func testReleaseProfileMinimizesCapture() throws {
        let storage = try makeTempDirectory()
        let collector = SigilReleaseDiagnostics(storageDirectory: storage)
        collector.beginSession(
            buildIdentity: testBuildIdentity(),
            environment: SigilDiagnosticEnvironment.current()
        )
        let operationID = collector.beginOperation(
            name: "fixture.release",
            expected: "essential faults survive release scoping",
            correlationID: nil
        )
        collector.record(
            SigilDiagnosticEventInput(
                source: "SigilTests",
                severity: .info,
                type: "ad-hoc.context",
                message: "ad-hoc context event",
                context: ["userContext": .string("should-not-be-retained")]
            )
        )
        collector.finishOperation(
            id: operationID,
            outcome: .success,
            context: ["fixture": .string("fixture-alpha")],
            durationSeconds: 0.001
        )
        collector.recordFailure(
            operationID: nil,
            operationName: "fixture.release",
            expectedBehavior: "essential faults survive release scoping",
            observedBehavior: "controlled failure under release profile",
            error: SigilDiagnosticError(
                domain: "SigilTest",
                code: 42,
                message: "controlled failure",
                underlyingError: SigilDiagnosticError(
                    domain: "SigilTest",
                    code: 7,
                    message: "fixture state mismatch"
                )
            ),
            context: ["userContext": .string("should-not-be-retained")],
            recoveryAttempts: [],
            fixtureReferences: ["fixture-alpha"],
            observedFacts: [],
            supportedFindings: [],
            hypotheses: [],
            unknowns: [],
            finalState: "unresolved"
        )

        let snapshot = collector.snapshot()
        XCTAssertEqual(collector.profile, .release)
        // Ad-hoc non-error events are dropped and accounted for.
        XCTAssertEqual(snapshot.health.droppedEventCounts["releaseProfileScope"], 1)
        // Context payloads (finish + failure) are dropped and accounted for.
        XCTAssertGreaterThanOrEqual(snapshot.health.contextDroppedCount, 2)
        // Every retained event has an empty context.
        XCTAssertTrue(snapshot.events.allSatisfy { $0.context.isEmpty })
        // Essential operation events are retained.
        XCTAssertTrue(snapshot.events.contains { $0.type == "sigil.diagnostic.operation.started" })
        XCTAssertTrue(snapshot.events.contains { $0.type == "sigil.diagnostic.operation.finished" })
        XCTAssertTrue(snapshot.events.contains { $0.type == "sigil.diagnostic.operation.failed" })
        // The incident with its error chain survives.
        XCTAssertEqual(snapshot.incidents.count, 1)
        XCTAssertEqual(snapshot.incidents[0].errorChain.count, 2)
        // The scoped limitation is declared.
        XCTAssertTrue(
            snapshot.health.missingCoverage.contains { $0.contains("context capture disabled") }
        )
        // The paired export route still works.
        let result = try collector.exportBundle(to: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.jsonPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.markdownPath))
    }

    func testRuntimeAssemblyInstrumentsDashboardOperation() throws {
        let storage = try makeTempDirectory()
        let collector = SigilDevelopmentDiagnostics(storageDirectory: storage)
        let assembly = SigilRuntimeAssembly(diagnostics: collector)
        let status = assembly.dashboardStatus()
        XCTAssertEqual(status.title, "Sigil Phase 1")

        let snapshot = collector.snapshot()
        let started = snapshot.events.first { $0.type == "sigil.diagnostic.operation.started" }
        let finished = snapshot.events.first { $0.type == "sigil.diagnostic.operation.finished" }
        XCTAssertNotNil(started)
        XCTAssertNotNil(finished)
        XCTAssertEqual(started?.message, "operation sigil.dashboard.status started")
        XCTAssertEqual(finished?.outcome, "success")
        XCTAssertNotNil(finished?.durationSeconds)

        // The finish event context derives the module count from registration.
        let moduleCount = finished?.context["moduleCount"]
        guard case .some(.number(let count))? = moduleCount else {
            return XCTFail("finish event is missing the moduleCount context value")
        }
        XCTAssertEqual(count, 8)
        XCTAssertEqual(finished?.context["apsJudgment"], .string("CONFORMANT WITH CAVEATS"))
    }
}
