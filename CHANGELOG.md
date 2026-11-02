# Changelog

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
