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

The repository has three workflow categories:

- Attribution guard
- Version guard
- Sigil project guardrails

Pull requests must satisfy all required guardrails before merge.

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

## Current Evidence

The current Phase 1 evidence records:

- Swift package tests passed: 22 tests, 0 failures
- configured Xcode simulator validation passed for `SigilApp`: 22 tests, 0 failures, 0 skipped
- attribution guard passed
- version guard passed
- strict project guardrails passed
- golden visible-glyph SVG fixtures and snapshot summary recorded under `ProjectEvidence/visible-glyph-snapshots/`
