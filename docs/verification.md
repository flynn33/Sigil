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

Fresh 2026-11-02 run (ASH-TRACE investigation at `53ba4895cdea2cb5d9188c369e1f980a2580067`):

- Xcode iOS-simulator build for `SigilApp` (Debug, `generic/platform=iOS Simulator`, fresh DerivedData): `BUILD SUCCEEDED`, 0 errors, 0 project-code warnings; 12 `appintentsmetadataprocessor` toolchain notices (non-project).
- Xcode iOS-simulator test for `SigilApp` (fresh DerivedData and result bundle): `TEST SUCCEEDED`, 22 tests, 0 failures, 0 unexpected.
- Repository guards re-ran fresh: strict project guardrail validator, version guard, attribution guard (branch `main`), 17 guard unit tests, `git diff --check`, and the verification wrapper (strict guard plus 22/22 Swift package tests) — all passed.
- Instruction-package integrity check and 20 helper unit tests passed; the completed 34-row trace ledger passed the external structural validator.
- Raw logs and the result bundle are stored in the owner-external evidence root and cited by measured SHA-256 in [docs/ash-trace/trace-ledger.json](ash-trace/trace-ledger.json).
