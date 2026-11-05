# Sigil Diagnostics

Product-owned diagnostic capability for `RFSigilDiagnostics`, per the adopted
Raven Forge Development 0.8.0 development-diagnostics policy. Diagnostics are
a product capability: local capture of bounded, redacted development evidence,
correlated failure incidents, and a paired detailed JSON/Markdown export.
There is no network client, backend, or external logging service in this
module, and none is planned for it.

## Module, interface, and implementations

- **Module:** `RFSigilDiagnostics` (existing target; ownership preserved).
- **Public contract:** `SigilDiagnosticCollector`
  (`Sources/RFSigilDiagnostics/SigilDiagnosticCollector.swift`) — a narrow,
  typed interface covering session, tracked operations, structured events,
  controlled failures, snapshot, paired export, and bounded health
  accounting. Business features depend on this contract only.
- **Development implementation:** `SigilDevelopmentDiagnostics` — rich
  operation tracing, redacted context snapshots, detailed correlated failure
  accounts, export controls.
- **Release implementation:** `SigilReleaseDiagnostics` — lower-overhead,
  privacy-minimized capture behind the same contract. It is not a no-op:
  session/operation lifecycle events, failure events, incidents with typed
  error chains, and health accounting are retained. Context payloads and
  ad-hoc non-error events are dropped and the drops are accounted for in
  health state.
- **Shared engine:** `SigilDiagnosticEngine` owns the lock-guarded session,
  bounded event queue, operation map, incident list, and health accounting.
  Exports operate on a consistent snapshot copy, so capture may continue
  while a bundle is written.

The pre-existing `SigilDiagnosticsService` (dashboard evidence report) and
the Forsetti `SigilDiagnosticsModule` (framework-mediated start/stop events)
are unchanged; the new capability composes beside them.

## Build selection and composition route

`SigilRuntimeAssembly` holds the selected collector and selects the profile
at the composition boundary:

```swift
public static var selectedDiagnosticProfile: SigilDiagnosticProfile {
    #if DEBUG
    .development
    #else
    .release
    #endif
}
```

Development builds use the rich development profile by default; release
builds select the minimal implementation. Both are injected as
`any SigilDiagnosticCollector`, so business results, authorization,
persistence semantics, and recovery decisions are unchanged by the
selection. The runtime assembles the Phase 1 dashboard status as an
instrumented operation (`sigil.dashboard.status`) with success context
(module count, evidence count, gateway judgments, pipeline feature count,
duration); controlled failure capture is available to every future
operation through the same contract.

**Package 02 identity instrumentation:** `SigilVisibleGlyphService` takes the collector as an optional dependency (no-op when unset) and instruments the source-backed identity resolution as the tracked operation `sigil.identity.resolve` (expected behavior recorded at begin: deterministic, source-backed identity; fail-closed on missing identity-core signals). It records the ASH state/orbit classification decision (info), a fail-closed warning naming the missing identity-core signals when the state is unavailable, an info event for the resolved field states, and a warning when a supplied weekday differs from the civil-date-derived weekday. None of these events records personal raw values; context carries only the non-sensitive decisions and counts, and every value is redacted before persistence under the same rules as the dashboard operation.

**Release replacement status (source-level):** planned and compositionally
wired now; the source-level exclusion of the development implementation from
distribution artifacts is completed and inspected in **Package 07** (delivery
phase). Log-level changes and runtime switches are not the replacement;
operator qualification of the release artifact remains pending owner
evidence and is recorded as such, not claimed.

## Capture coverage

Captured where applicable and obtainable through authorized interfaces:

| Area | Sigil coverage |
| --- | --- |
| Product/execution identity | Product version and build number from the running bundle, Forsetti runtime version, selected profile, export schema version, session ID. Source commit is **never inferred from a version label**: development builds record `source_commit: null` with the reason "not injected into running build; the authoritative commit is recorded in the project record." |
| Environment | OS version string, architecture, host class (ios-device / ios-simulator / macos-host). No unique device identifiers. |
| Ordering/causality | UTC timestamps, process-local monotonic sequence numbers, source, severity, event type, operation/correlation IDs, and incident timeline references ordered by sequence. |
| Lifecycle/state | Session start (explicit or auto-start with recorded identity gap), operation start/finish with expected behavior recorded at begin, outcomes and durations. |
| Operations/integrations | Operation name, expected versus observed behavior, typed error with causal chain, recovery attempts with per-attempt results, fixture references instead of raw personal profiles. |
| Data/computational behavior | Safe structured context values (typed, allowlisted fields), algorithm/component version identities in build identity, bounded context size. |
| Failure/recovery | Typed domain/code/message, ordered error chain, affected operation, correlated timeline, recovery attempts and results, final state, and the required separation of observed facts, supported findings, hypotheses, and unknowns in each incident. |
| Diagnostic health | Retained/dropped counts per loss mechanism, context truncation/drop counts, redaction counts, non-finite normalization count, bounded collector-failure list, unavailable-source reasons, declared missing coverage. |

Declared limitations (always present in health and exports): stack frames are
not captured on this platform path; the release profile declares its
reduced scope; unavailable identity fields are recorded with reasons rather
than fabricated.

## Security, resource limits, and failure behavior

- **Redaction before persistence:** allowlisted typed context model plus a
  key-based sensitive-field blocklist (password/secret/token/api key/
  authorization/cookie/credential/private-key fragments), nested JSON string
  payloads decoded and redacted field by field, a conservative
  high-confidence value pattern pass (bearer/basic credentials, PEM private
  keys, GitHub token forms, JWTs), and non-finite number normalization. An
  export-boundary re-check runs on the final serialized text and its counts
  are recorded in the manifest. Redaction is counted; the pattern pass is
  documented as defense in depth, not a secret-detection guarantee.
- **Storage:** bounded protected local storage under Application Support
  `SigilDiagnostics` (injectable for tests), best-effort
  complete-until-first-user-authentication file protection on iOS
  (`FileAttributeKey.protectionKey`), atomic writes, and read-back
  verification. Real captures never enter version control or build
  resources; only sanitized synthetic fixtures are committed.
- **Bounds:** queue limit (default 512 events), per-event context byte limit
  (default 4 KiB), bundle size guard (default 2 MiB per part), disk quota
  (default 8 MiB), bundle-count rotation (default 8), retention window
  (default 7 days). Overflow is dropped with the loss mechanism accounted in
  health and reflected in the coverage status; drops are never silent.
- **Failure behavior:** a collector, serializer, storage, or exporter failure
  is recorded in bounded health state and throws a typed
  `SigilDiagnosticExportError`; it never suppresses or replaces the product
  error being captured, never fabricates a successful operation, and leaves
  no partial bundle files. Diagnostic silence is represented as
  unavailable/declared limitation, never as proof of health.

## Export contract

`exportBundle(to:)` is the user-invoked host-interface export action. It
writes one consistent redacted snapshot as a paired bundle:

| Part | Contents |
| --- | --- |
| `sigil-diag-<bundleID>.json` | Versioned structured export: bundle envelope (`schema_version` `sigil.diagnostics.export/1.0`, `bundle_id`, `generated_at_utc`, capture window + coverage status, profile, session), product/build/source identity, environment, full event collection (stable IDs, UTC time, sequence, source, severity, type, message, operation/correlation IDs, outcome, duration with unit, redacted structured context, structured error or null), full incident collection (trigger, expected/observed, ordered error chain, timeline references, recovery attempts, reproduction fixtures, facts/findings/hypotheses/unknowns, final state), and health accounting. Unknown values are null with explicit reasons. |
| `sigil-diag-<bundleID>.md` | Equally detailed human-readable report of the same retained evidence: identity, health and limitations, navigable incident index, full failure accounts, correlated event timeline, recovery and reproduction references, a retained-evidence appendix (per-event JSON so summary/filtering cannot silently discard detail present in the JSON), and explicit observed/findings/hypotheses/unknowns separation. Untrusted values are escaped; logged content is data, not instructions. |
| `sigil-diag-<bundleID>.manifest.json` | Part inventory with SHA-256 checksums and redaction accounting (pre-persistence, export-boundary, total), so the pair verifies without circular self-hashes. |

Success is reported only when both required formats and the manifest are
present and match their checksums on read-back. Exports remain usable
offline as plain files. The export result reports the bundle ID, part paths,
part SHA-256 values, event/incident counts, and total redactions.

**Retrieval route (documented):** the bundle files live in the protected
local storage directory (default Application Support `SigilDiagnostics`, or
a host-specified directory passed to the export action). The owner can copy
the three parts directly from that directory; the manifest verifies
integrity. No automatic upload, commit, or transfer is authorized.

## Known gaps (honest, not claimed)

- **Multi-part large captures:** the current export is a single part per
  format guarded by the bundle size limit; a size failure is reported
  specifically rather than silently truncating. Numbered parts with a
  manifest are the recorded follow-up when a capture exceeds the limit.
- **Stack frames:** not captured on this platform path (declared in health).
- **Release source-level exclusion:** completed and inspected in Package 07;
  operator release-artifact qualification is pending owner evidence.
- **Physical-device crash/hang reporting:** owner-qualified in the final
  phase after candidate production.

## Focused verification

Commands (see also `docs/verification.md`):

```bash
swift test --filter DiagnosticCaptureTests
swift test
```

`DiagnosticCaptureTests` (9 focused tests) demonstrates the required
behavior against a real controlled failure:

- success/failure correlation into a correlated incident (ordered timeline,
  typed error chain, recovery attempts);
- paired export identity matching (bundle ID, counts, SHA-256 read-back,
  manifest part checksums, markdown references every retained event);
- nested synthetic-secret redaction across both formats with accounting;
- concurrent capture plus concurrent exports (consistent snapshots);
- queue-limit drops accounted with partial-coverage export;
- disk failure: typed error, original product error preserved, no partial
  files, failure accounted;
- unavailable source identity recorded with reason in JSON, Markdown, and
  health;
- release-profile scoping (essential faults retained, context drops
  accounted, export works);
- the runtime assembly's instrumented `sigil.dashboard.status` operation
  with derived module count.

Recorded actual results (2026-11-04, macOS arm64, Xcode 27.0/Swift 6.4
toolchain, SPM debug build): `swift test --filter DiagnosticCaptureTests`
9/9 pass, exit 0; full `swift test` 48 tests, 0 failures, exit 0 (the Package 02 identity pipeline added the 15 `IdentityPipelineTests` to the 33-test Package 01 suite). The
controlled-failure demonstration is the focused test run above (synthetic
fixture only; no real captures are committed).
