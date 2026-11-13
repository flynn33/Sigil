# Verification

## Local Verification Standard

Before repository changes are published, run the strongest practical local checks for the changed surface. For normal repository work, start with the wrapper:

```bash
bash scripts/verify-sigil-guardrails.sh
```

The wrapper runs the strict project guardrail validator and Swift package tests.

## Focused Commands

```bash
swift test
python3 tools/sigil_guardrails/verify_sigil_guardrails.py --project-root . --policy tools/sigil_guardrails/sigil_guardrail_policy.json --strict
python3 scripts/attribution_guard.py --branch "$(git branch --show-current)" --repo-root .
python3 scripts/version_guard.py --repo-root .
python3 -m unittest Tests/SigilGuardrailTests/test_sigil_guardrails.py
python3 -m unittest Tests/AttributionGuardTests/test_attribution_guard.py
python3 -m unittest Tests/VersionGuardTests/test_version_guard.py
```

## Current Test Inventory

| Suite | Coverage |
| --- | --- |
| `DashboardStatusTests` | Dashboard cards and runtime assembly |
| `ForsettiModuleRegistrationTests` | Module registration, manifest schema, capability policy |
| `IntegrationGatewayTests` | APS and Aeostara status surfaces |
| `PlaceholderPipelineTests` | Explicit unavailable pipeline contract |
| `PrivacySecurityTests` | Local-only privacy posture |
| `SourceAuthorityTests` | Source hierarchy and boundary preservation |
| `VisibleGlyphGenerationTests` | Deterministic visible-glyph artifacts, quality gates, collision handling, validation |
| `DiagnosticCaptureTests` | Diagnostic success/failure correlation, paired export identity matching, nested synthetic-secret redaction, concurrent capture/export, queue limits, disk/export failure, unavailable source identity, release-profile scoping, instrumented runtime operation |
| `IdentityPipelineTests` | Independently computed spec fixtures, letter normalization and numerology roots, weekday reduction, master-number preservation, wolf categories, fail-closed input classes, the 512/16 codeword and coordinate-adapter invariants, and the ASH state record |
| `ArtifactHealthTests` | Aeostara base-lifecycle artifact-health validation: pass on a healthy artifact, fail-closed on corrupt JSON / unknown schema / missing required data / invalid topology / non-recoverable failure, non-destructive in-memory recovery of derivable authoritative digests only, monotonic containment, and agreement with the existing visible-glyph artifact validation |
| `SecureStorageTests` | Local-only encrypted persistence: AES-GCM round-trip, no-plaintext-leak, keys-not-beside-ciphertext, atomic update, failed-replacement preserves last-verified, wrong/missing key, tampered ciphertext, corrupt record, unsupported version, not found, list/delete, concurrent writes, and storage-identity-is-independent-of-mathematical-identity |
| `SecurePersistenceIntegrationTests` | Runtime integration: a failed save is reported as a `.writeFailed` failure and not counted as a record, a save/load round-trip through the service, the `secure-persistence` dashboard card is present and not a sensitive path, and a capturing collector proves no record payload, key material, storage path, or identifier leaks on the success and failure paths |
| `CanonResourceTests` | Product-owned canon resource layer: load succeeds and is structurally valid, the nine-plane taxonomy has nine planes in fixed order, the provenance digest is deterministic and version-sensitive, a missing manifest fails closed, and a tampered resource fails its hash check |
| `CelestialNamingTests` | Deterministic celestial naming: the life-path-dominant plane, the three wolf categories, heritage priority, deterministic reproduction and stability, a Unicode name is deterministic and valid, no reference-character name is ever produced, and name length bounds |
| `PersonalCodexTests` | Readable PersonalCodex record: build succeeds with all sections, the Sigil Reading is complete and linked to the selected geometry, the wolf divergence is documented, deterministic build, bloodline is not a destiny claim, trials are bounded and not fabricated, the provenance digest matches the canon, and `validate` accepts a well-formed record and rejects a tampered one |
| `PersonalCodexPersistenceTests` | Runtime integration for the PersonalCodex: a build/encode/save/load/decode/validate round trip, a failed save is never reported as success, the storage identity uses the profile id not the hash, and persist diagnostics leak no sensitive data |
| `BranchGlyphTests` | ASH-derived canonical glyph: the reference-to-APS message seam is a 16<->16 bijection onto the product's APS-native `[9,4,4]` set (every derived word has b8 == 0, minimum distance 4), deterministic message-driven projection, real proper-interior crossing verification, the geometry-only collision signature is order-invariant and distinguishes different geometries (with a cross-profile same-geometry pair), the topology loader fails closed on a tampered resource SHA, and the shipped topology is structurally well-formed (121 nodes / 81 leaves / 16 messages) |
| Guardrail Python suites | Attribution, version, changelog, source, and policy checks |

## GitHub Actions

At the current HEAD `1f8ec799c7790d3123114db2d6f8f8f0500e395b`, no hosted GitHub Actions workflows are tracked; the hosted workflows were removed on 2026-10-24 to stop runner spend. The local scripts and wrapper above are the verification route; the baseline-scoped status below is historical.

At the inspected source baseline `19a0e2b9e9ad6fbaec06b62d2e084f444e92e84b`, the only tracked workflow is `.github/workflows/attribution-guard.yml`, triggered by pull-request events. Version and strict project guardrails have local scripts; this baseline does not establish active workflows for them.

A direct push does not establish that pull-request-triggered checks ran. Report actual local command results and remote checks separately; do not infer a current pass from historical evidence. Repository publication must follow the separately recorded authority.

## Version And Changelog Guard

`VERSION` must use:

```text
STAGE.major.feature.patch
```

Allowed stage prefixes:

- `PA`: pre-alpha
- `A`: alpha
- `R`: release

`CHANGELOG.md` must include a heading matching the current `VERSION`. Material repository changes must include `CHANGELOG.md` in the changed paths.

## Attribution Guard

Repository content, branch names, commit messages, PR text, and docs must not include attribution to development tools, providers, or generated authorship. The guard checks blocked phrases and standalone blocked tokens across content and path surfaces.

## Project Guardrails

The strict project guardrail validator checks:

- required evidence files are present
- JSON files parse
- source authority boundaries remain intact
- Forsetti internals are not copied into Sigil
- superseded ASH implementation markers are absent
- Aeostara platform boundaries remain separated and baseline-pinned
- attribution markers are absent

## Planning Synchronization And Remaining Product Verification

For the [current planning update](roadmap.md), verify links, requirements consistency, version/changelog identity, and the actual changed-file boundary. Source, dependency, native-project, and test changes are not part of the documentation assignment. If only documentation and descriptive policy text change, preserve current product/build/schema versions and record a reviewed no-change disposition for native project files.

Run the focused local guards above and `git diff --check`. When editing descriptive fields in `tools/sigil_guardrails/sigil_guardrail_policy.json`, confirm that `blocked_project_patterns`, `required_evidence_files`, and every authority `hard_rules` list are unchanged. Do not weaken tests, rule IDs, blocked paths, or enforcement to accommodate a roadmap.

Run the normal wrapper on a suitable assigned native host when available, and inspect its output: it conditionally skips Swift or Xcode checks when their executables are absent. A successful wrapper exit in that case is not a native build/test pass. New native verification is not established by a documentation review.

Later ASH implementation requires source-backed conformance, deterministic-generation, geometry-quality, privacy, integrity, and safe-failure checks. The [removed personal-payload requirement](decisions/2026-10-10-no-personal-data-embedding.md) must not return as a payload round-trip acceptance gate. Existing mathematical/state serialization, artifact-integrity, collision, and Flare tests remain unless a separately scoped implementation change proves a specific test encodes the superseded requirement.

## Current Evidence

The stored Phase 1 evidence records the following inherited results; they are not new runs for the current planning revision:

- Swift package tests passed: 22 tests, 0 failures
- configured Xcode simulator validation passed for `SigilApp`: 22 tests, 0 failures, 0 skipped
- attribution guard passed
- version guard passed
- strict project guardrails passed
- golden visible-glyph SVG fixtures and snapshot summary recorded under `ProjectEvidence/visible-glyph-snapshots/`

Fresh 2026-11-01 run (version alignment publication):

- Xcode iOS-simulator build for `SigilApp` (Debug, `generic/platform=iOS Simulator`): `BUILD SUCCEEDED`, 0 errors, 0 code warnings; built `Info.plist` reports `CFBundleShortVersionString = PA.0.1.0`, `CFBundleVersion = 1`, bundle identifier `com.ravenforge.sigil`.
- The build log contains 12 `appintentsmetadataprocessor` "Metadata extraction skipped, no AppIntents.framework dependency found" lines; these are Xcode 27 metadata-phase notices, not project warnings.
- Repository guards (strict project guardrail validator, version guard, attribution guard, guard unit tests, `git diff --check`, verification wrapper) re-ran fresh for this publication; raw logs are stored outside the repository.

Fresh 2026-11-02 run (ASH-TRACE investigation at `53ba4895cdea2cb5d91888c369e1f980a2580067`; the 39-character hash previously printed here was a transcription error, corrected 2026-11-03):

- Xcode iOS-simulator build for `SigilApp` (Debug, `generic/platform=iOS Simulator`, fresh DerivedData): `BUILD SUCCEEDED`, 0 errors, 0 project-code warnings; 12 `appintentsmetadataprocessor` toolchain notices (non-project).
- Xcode iOS-simulator test for `SigilApp` (fresh DerivedData and result bundle): `TEST SUCCEEDED`, 22 tests, 0 failures, 0 unexpected.
- Repository guards re-ran fresh: strict project guardrail validator, version guard, attribution guard (branch `main`), 17 guard unit tests, `git diff --check`, and the verification wrapper (strict guard plus 22/22 Swift package tests) — all passed.
- Instruction-package integrity check and 20 helper unit tests passed; the completed 34-row trace ledger passed the external structural validator.
- Raw logs and the result bundle are stored in the owner-external evidence root and cited by measured SHA-256 in [docs/ash-trace/trace-ledger.json](ash-trace/trace-ledger.json).

Fresh 2026-11-04 run (Package 01 remediation closeout: R-05 diagnostic foundation and R-06 dashboard status corrections, at `main`):

- Swift package tests (`swift test`, macOS arm64, Xcode 27.0/Swift 6.4 toolchain): 33 tests, 0 failures (24 product tests including 4 dashboard tests plus 9 new `DiagnosticCaptureTests`).
- Xcode iOS-simulator build for `SigilApp` (Debug, `generic/platform=iOS Simulator`, fresh DerivedData in the owner-external evidence root): `BUILD SUCCEEDED`, 0 errors, 0 project-code warnings; 12 `appintentsmetadataprocessor` toolchain notices (non-project).
- Xcode iOS-simulator test for `SigilApp` (`SigilTraceiPhone17`, iOS 27.0, fresh result bundle): `TEST SUCCEEDED`, 33 tests, 0 failures, 0 unexpected.
- Repository guards re-ran fresh: strict project guardrail validator, version guard, attribution guard (branch `main`), 17 guard unit tests (6 + 5 + 6), and the verification wrapper (strict guard plus Swift package tests) — all passed. Two blocked attribution markers in two Phase-01 docs (a two-word generation-attribution phrase and a standalone two-letter initialism token in authorization text) were reworded before the guard pass; no guard or test was weakened.
- External trace structural validator (instruction-package `tools/validate_trace.py` against `docs/ash-trace/trace-ledger.json`): `STRUCTURAL CHECK PASSED` (structural, not semantic approval).
- `xcodegen` (2.46.0) regenerated `Sigil.xcodeproj` to include the seven new diagnostic files; `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` values were unchanged by the regeneration until the closeout version alignment.
- Version-alignment build verification after the `PA.0.1.1` / build 2 update: Debug iOS-simulator rebuild `BUILD SUCCEEDED`, 0 project-code warnings; the built `SigilApp.app/Info.plist` reports `CFBundleShortVersionString = PA.0.1.1`, `CFBundleVersion = 2`, bundle identifier `com.ravenforge.sigil`. Internal framework targets keep xcodegen's stock dylib-versioning defaults (a separate binary-versioning identity from the app build number).
- Realization-contract validator results (contract mode and preflight mode) were completed in the preceding session with reports in the owner-external evidence root; they were not re-run in this session.
- Raw build/test logs and the result bundle are stored in the owner-external evidence root (`phase01/xcodebuild/`).

Fresh 2026-11-04 run (Package 02 identity pipeline closeout, at `main`):

- Swift package tests (`swift test`, macOS arm64, Xcode 27.0/Swift 6.4 toolchain): 48 tests, 0 failures, 0 unexpected (33 product tests from Package 01 plus 15 new `IdentityPipelineTests`).
- Xcode iOS-simulator test for `SigilApp` (`SigilTraceiPhone17`, id `43AF4004-F06D-43C6-8019-0A438E0AEB40`, fresh DerivedData): build compiled and `TEST SUCCEEDED`, 48 tests, 0 failures, 0 unexpected.
- Repository guards re-ran fresh: strict project guardrail validator, version guard, attribution guard (branch `main`), 17 guard unit tests (6 + 5 + 6), and the verification wrapper (strict guard plus Swift package tests) — all passed.
- One pre-existing code warning in the Package 01 test file `DiagnosticCaptureTests.swift` (implicit optional promotion in a pattern match; test-only, not Package 02 source); no project-code warnings in Package 02 sources. The 42 `appintentsmetadataprocessor` lines are Xcode 27 toolchain notices, not project warnings.
- Version-alignment build verification after the `PA.0.2.0` / build 3 update: the built `SigilApp.app/Info.plist` reports `CFBundleShortVersionString = PA.0.2.0`, `CFBundleVersion = 3`, bundle identifier `com.ravenforge.sigil`.
- A previously missing `RFSigilDiagnostics` dependency edge on the `RFSigilVisibleGlyph` Xcode target was added to `project.yml` (the SwiftPM target already carried it); `xcodegen` regenerated `Sigil.xcodeproj`.
- Raw build/test logs and the result bundle are stored in the owner-external evidence root (`phase02/xcodebuild/`).

Fresh 2026-11-05 run (Package 03 artifact-health and encrypted local persistence closeout, on the phase branch):

- Swift build (`swift build`, macOS arm64): `BUILD SUCCEEDED`, 0 errors, 0 warnings in Package 03 sources.
- Swift package tests (`swift test`, macOS arm64): 76 tests, 0 failures, 0 unexpected (48 from Package 02 plus 10 `ArtifactHealthTests`, 14 `SecureStorageTests`, and 4 `SecurePersistenceIntegrationTests`).
- Strict project guardrail wrapper (`bash scripts/verify-sigil-guardrails.sh`): strict validator, `swift test --parallel` 76/0, and `xcodebuild -list` all passed; `git diff --check` clean. `xcodebuild -list` confirms the regenerated project is well-formed and target membership is complete.
- The full iOS-simulator `xcodebuild` build/test was not re-run in this session; this is recorded honestly rather than claimed as a pass.
- Device/simulator keychain data-protection behavior remains an owner qualification: the host tests exercise the native crypto, storage, and atomic-replacement logic with an injected key, not the OS keychain protection.
- `xcodegen` (2.46.0) regenerated `Sigil.xcodeproj`: the five new Package 03 source files were added to their framework targets and the app marketing/build version aligned to `PA.0.3.0` / build 4.
- Raw build/test output and the closeout receipt are stored in the owner-external evidence root (`phase03/closeout/`).

Fresh 2026-11-06 run (Package 04 canon and PersonalCodex closeout, on the phase branch):

- Swift build (`swift build`, macOS arm64): `BUILD SUCCEEDED`, 0 errors, 0 warnings in Package 04 sources.
- Swift package tests (`swift test --parallel`, macOS arm64): 105 tests, 0 failures, 0 unexpected (76 from Package 03 plus 5 `CanonResourceTests`, 11 `CelestialNamingTests`, 9 `PersonalCodexTests`, and 4 `PersonalCodexPersistenceTests`).
- Strict project guardrail wrapper (`bash scripts/verify-sigil-guardrails.sh`): strict validator, `swift test --parallel` 105/0, and `xcodebuild -list` all passed (exit 0); `git diff --check` clean. `xcodebuild -list` lists both new targets (`RFSigilCanon`, `RFSigilPersonalCodex`) and confirms the regenerated project is well-formed and target membership is complete.
- The full iOS-simulator `xcodebuild` build/test was not re-run in this session; this is recorded honestly rather than claimed as a pass.
- Device/simulator qualification of the PersonalCodex persistence path remains an owner qualification: the host tests exercise the deterministic derivation, the acyclic digest, the both-rule wolf recording, and the redaction logic, not device-level data protection.
- `xcodegen` (2.46.0) regenerated `Sigil.xcodeproj`: the `RFSigilCanon` and `RFSigilPersonalCodex` framework targets were added (wired into `RFSigilRuntime` and `SigilTests`), the four shipped canon JSON resources were added to a Resources build phase, and the app marketing/build version aligned to `PA.0.4.0` / build 5 (both Debug and Release); the Forsetti pin is unchanged.
- Raw build/test output and the closeout receipt are stored in the owner-external evidence root (`phase04/closeout/`).

Fresh 2026-11-06 run (Package 05 ASH-derived canonical glyph closeout, on `main`):

- Swift build (`swift build`, macOS arm64): `BUILD SUCCEEDED`, 0 errors, 0 warnings.
- Swift package tests (`swift test`, macOS arm64): 111 tests, 0 failures, 0 unexpected (105 from Package 04 plus 6 `BranchGlyphTests`; one stale identity test corrected to annotation-only).
- Strict project guardrail wrapper (`bash scripts/verify-sigil-guardrails.sh`): strict validator, `swift test --parallel` 111/0, and `xcodebuild -list` all passed (exit 0); `git diff --check` clean.
- The full iOS-simulator `xcodebuild` build/test was not re-run in this session; this is recorded honestly rather than claimed as a pass. The App target reports `PA.0.5.0` / build 6 via `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` (both Debug and Release) in `project.yml` and the regenerated `Sigil.xcodeproj`.
- `xcodegen` (2.46.0) regenerated `Sigil.xcodeproj`: the `RFSigilVisibleGlyph` target gained the `Resources/ash/*.json` build phase (the same `sources`-glob resource pattern `RFSigilCanon` uses) and the app marketing/build version aligned to `PA.0.5.0` / build 6 (both Debug and Release); the Forsetti pin is unchanged and no new target dependency was added (`RFSigilVisibleGlyph` remains independent of `RFSigilCanon`).
- Raw build/test output and the closeout receipt are stored in the owner-external evidence root (`phase05/closeout/`).

Fresh 2026-11-06 run (Package 06 native experience, presentation-only Flare, and explicit export closeout, on `main`):

- Swift build (`swift build`, macOS arm64): `BUILD SUCCEEDED`, 0 errors, 0 warnings.
- Swift package tests (`swift test`, macOS arm64): 136 tests, 0 failures, 0 unexpected (111 from Package 05 plus 20 `ProfileDraftAndJourneyTests` and 5 `JourneyIntegrationTests`).
- Strict project guardrail wrapper (`bash scripts/verify-sigil-guardrails.sh`): strict validator, `swift test --parallel` 136/0, and `xcodebuild -list` all passed (exit 0); `git diff --check` clean.
- The full iOS-simulator `xcodebuild` build/test was not re-run in this session; this is recorded honestly rather than claimed as a pass. The App target reports `PA.0.6.0` / build 7 via `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` (both Debug and Release) in `project.yml` and the regenerated `Sigil.xcodeproj`.
- `xcodegen` (2.46.0) regenerated `Sigil.xcodeproj`: the `RFSigilUIModule` target gained its three new source files (picked up by the existing `sources` glob) and the app marketing/build version aligned to `PA.0.6.0` / build 7 (both Debug and Release); the Forsetti pin is unchanged and no new third-party dependency was added (`RFSigilUIModule` now depends on the existing in-repo targets `RFSigilVisibleGlyph`, `RFSigilPrivacySecurity`, and `RFSigilPersonalCodex`).
- Raw build/test output and the closeout receipt are stored in the owner-external evidence root (`phase06/closeout/`).

Fresh 2026-11-07 run (Package 07 integration, development verification, and owner handover closeout, on `main` at the `PA.0.6.1` / build 8 source revision):

- Swift build (`swift build`, macOS arm64, Debug): `BUILD SUCCEEDED`, 0 errors, 0 project-code warnings.
- Swift build, release configuration (`swift build -c release`, macOS arm64): `BUILD SUCCEEDED` — confirms the module composes with the invasive development diagnostic capture (`SigilDevelopmentDiagnostics`) compiled out of the distributable configuration (source-level exclusion; not a runtime switch).
- Swift package tests (`swift test`, macOS arm64): 137 tests, 0 failures, 0 unexpected (136 from Package 06 plus 1 `DiagnosticCaptureTests` business-outcome-parity case).
- Strict project guardrail wrapper (`bash scripts/verify-sigil-guardrails.sh`): strict validator, `swift test --parallel` 137/0, and `xcodebuild -list` all passed (exit 0); `git diff --check` clean.
- Dependency/target composition inspected against the real graph: a single pinned external dependency (`ForsettiCore` @ `43eef7a739f3b78253c64aa4b070521ab5b1f43c`), no prohibited internal/example/demo/tooling target linked, no Forsetti-internal source path copied into the product, and the acyclic target graph unchanged; no instruction package, source archive, real diagnostic capture, secret, or personal test data in the product tree or application resources.
- The full iOS-simulator `xcodebuild` build/test was not re-run in that session; that limitation is superseded by the 2026-11-13 Xcode buildability closeout below. The App target at Package 07 closeout reported `PA.0.6.1` / build 8 via `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` and the regenerated `Sigil.xcodeproj`.
- `xcodegen` regenerated `Sigil.xcodeproj`: the app marketing/build version aligned to `PA.0.6.1` / build 8 (both Debug and Release); the Forsetti pin is unchanged and no new dependency or target was added.
- Raw build/test output and the closeout receipt are stored in the owner-external evidence root (`phase07/closeout/`).

Fresh 2026-11-13 run (Xcode project buildability closeout, on `main` at the `PA.0.6.2` / build 9 source revision):

- Xcode Debug iOS-simulator build (`xcodebuild -project Sigil.xcodeproj -scheme SigilApp -destination 'platform=iOS Simulator,…' build`): `BUILD SUCCEEDED`, 0 errors, 0 project-source warnings (toolchain `appintentsmetadataprocessor` notices only).
- Xcode Debug iOS-simulator test (`xcodebuild … test`): **TEST SUCCEEDED**, 137 tests, 0 failures.
- Swift build (`swift build`, macOS arm64, Debug): `BUILD SUCCEEDED`.
- Swift build, release configuration (`swift build -c release`, macOS arm64): `BUILD SUCCEEDED`.
- Swift package tests (`swift test`, macOS arm64): 137 tests, 0 failures.
- `project.yml` target dependencies aligned with `Package.swift`; `#if !SWIFT_PACKAGE` `Bundle.module` accessors added for `RFSigilCanon` and `RFSigilVisibleGlyph`; `xcodegen` regenerated `Sigil.xcodeproj` at `PA.0.6.2` / build 9 (Debug and Release). Forsetti pin unchanged.
- A fresh clone of `main` is expected to open `Sigil.xcodeproj`, resolve the pinned Forsetti package, and build/test scheme `SigilApp` on an iOS 17+ Simulator.
