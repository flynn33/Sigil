# Changelog

## PA.0.1.1 - 2026-11-04

### Package 01 closeout — remediation, source alignment, and diagnostic foundation

- Corrected the ASH source-trace record with fresh evidence (R-01 through R-04): the serialized ASH-Model and APS codeword tables are not identical but agree exactly under a documented final-two-coordinate swap (one-based `x8 = 0` versus zero-based `b8 = 0`); the 8+1 versus full-9D framing is reconciled as a domain distinction (the reference application's 256-state integrity subset inside the 512-state `F2^9` universe versus the APS R1 all-first-class-coordinate model); the semantic branch tree (121 nodes / 81 leaves) is separated from the independent rendering L-system (625 forward symbols at depth 4); the 39-character baseline hash transcription error is corrected to the 40-character Git identity.
- Added the system realization contracts (Forsetti Apple 0.1.5, APS canonical 1.0.0-rc.3, Aeostara base 1.0.0) in `docs/system-realization/` with strict and preflight validator passes and an independent model-based acceptance record.
- Added the bounded identity/input treatment specification (`docs/design/identity-input-treatment.md`) as documented product-owned design decisions; the one genuine upstream framing conflict is isolated and visible, not resolved unilaterally.
- R-05 diagnostic foundation in `RFSigilDiagnostics`: a narrow typed `SigilDiagnosticCollector` contract with a development implementation (rich operation tracing, redacted context, detailed correlated failure accounts) and a release implementation (essential fault capture with accounted context drops), a shared lock-guarded engine, redaction before persistence with an export-boundary recheck and accounting, bounded protected local storage with retention, rotation, and disk quota, and a paired detailed JSON/Markdown export with a manifest carrying part checksums and redaction accounting from one consistent snapshot. `SigilRuntimeAssembly` selects the profile at the composition boundary and instruments the dashboard status as a real operation. See `docs/diagnostics.md`.
- R-06 dashboard status correction: module counts are derived from registration/catalog (8 total: 1 UI module, 7 service modules) and the APS card states recorded conformance evidence rather than implying a live dependency or resolver.
- Version/build: `PA.0.1.0` → `PA.0.1.1` (patch advance for a repair-and-foundation phase); Apple build identity 1 → 2 (app-affecting closeout). `VERSION` is the source of truth; `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are aligned in `project.yml` and the regenerated `Sigil.xcodeproj`; `Info.plist` continues to use build settings. Forsetti pin and schema/algorithm versions are unchanged.
- Verification (fresh 2026-11-04): 33/33 Swift package tests; 33/33 iOS-simulator tests; Debug iOS-simulator build with 0 errors and 0 project-code warnings; strict project guardrails, version guard, attribution guard, and 17 guard unit tests passed; external trace structural validator passed. See `docs/verification.md`.
- No dependency, schema, or test changes; the additional personal-data embedding requirement remains removed, not deferred.

## PA.0.1.0 - 2026-07-08

### Planning synchronization — 2026-10-10

- Reconciled the product roadmap with the retained ASH-first identity, PersonalCodex, and Sigil workflow; added a current project plan and navigation links.
- Recorded removal, not deferral, of the additional personal-data embedding and payload-recovery requirement; retained mathematical state/geometry, integrity, safety recovery, and canonical/Flare separation.
- Identified the approved ASH source trace as the next engineering investigation; removed unsupported blanket framework-rewrite, branch-migration, and optional-network mandates from the active plan while preserving history.
- Clarified current versus planned behavior, inherited versus fresh verification, and the actual tracked workflow inventory; aligned descriptive guardrail references without changing enforcement.
- Kept application source, dependencies, tests, product/build/schema versions, and native project configuration unchanged.

### Documentation clarification — 2026-11-01

- Corrected stale README statements about the tracked workflow inventory and project wiki to match the actual repository state at `1f8ec799c7790d3123114db2d6f8f8f0500e395b`.
- Clarified current hosted-workflow status in the verification documentation against the 2026-10-24 removal; historical baseline text retained.
- No application source, test, dependency, version, enforcement, or native project configuration changes.

### Version alignment and Xcode verification — 2026-11-01

- Aligned application version surfaces with the repository `VERSION` (`PA.0.1.0`): SigilApp `MARKETING_VERSION` in `Sigil.xcodeproj` and the XcodeGen manifest `project.yml`; `Info.plist` now references `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` instead of hard-coded values.
- Verified a fresh Xcode iOS-simulator build of `SigilApp` (Debug): `BUILD SUCCEEDED`, 0 errors, 0 code warnings; built `Info.plist` reports `CFBundleShortVersionString = PA.0.1.0` and `CFBundleVersion = 1`.
- Published the project wiki pages (Home, Architecture, Visible Glyph, Release Governance); repository documentation remains the authoritative reference.
- No application source, test, dependency, schema-version, or repository version changes.

### ASH source trace investigation — 2026-11-02

- Completed the approved read-only ASH source trace (`SIGIL-DEC-2026-10-09-ASH-TRACE`): source-to-output map, 34-row trace ledger, findings with the smallest proposed next change (draft, not accepted), and source-backed verification cases under `docs/ash-trace/`; continuation handoff at `docs/handoffs/ash-trace.md`.
- Recorded 14 supported relationships, 16 evidenced local substitutions (digest-derived identity layer and non-standard numerology/input treatments), and 4 unresolved owner decisions (weekday role, location/geocoding scope, parents' birth-order rule, master-number policy), plus the unresolved ASH-Model 8+1 versus APS full-9D formalization conflict.
- Re-verified current behavior fresh at `53ba4895cdea2cb5d9188c369e1f980a2580067`: 22/22 iOS-simulator tests, repository guardrails, version and attribution guards, guard unit tests, verification wrapper, and a Debug iOS-simulator build with 0 errors and 0 project-code warnings.
- No application source, test, dependency, schema-version, repository version, or native project configuration changes; `PA.0.1.0` / build `1` unchanged.

### Foundation

- Established the Phase 1 foundation for the Sigil iOS runtime surface.
- Added repository governance checks for attribution, version policy, and changelog coverage.
- Added project-level source authority guardrails, local hooks, verification wrappers, and evidence records.
- Added deterministic visible-glyph generation with local hidden geometry, digest linkage, quality gates, SVG rendering evidence, and fail-closed artifact validation.
- Added repository README and expanded architecture, visible-glyph, verification, and wiki documentation.
