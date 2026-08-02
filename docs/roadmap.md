# Sigil — Product Roadmap

**Version:** 2026-08-02  
**Current State:** PA.0.1.0 (Pre-Alpha, Phase 1 Foundation)  
**Target:** Shippable consumer product for iOS  
**Nature:** Sigil is a demonstrator for three underlying systems: Forsetti Framework, ASH Pattern System, and Aeostara.

---

## Executive Summary

Sigil is a native Apple-platform (iOS 17+, macOS 14+) application that serves as a **demonstrator and integration platform** for three underlying systems:

1. **The Forsetti Framework** — A modular runtime framework for iOS/macOS (module discovery, validation, activation, entitlements, UI contributions)
2. **The ASH Pattern System** — A semantic core implementing 9 modules operating on F2^9 state space (512 states) with XOR-by-codeword transitions, state classification, and recovery
3. **Aeostara** — A platform-specific realization providing platform isolation, baseline pinning, and migration provenance

The current Phase 1 establishes a modular runtime, dashboard, and a bounded local visible-glyph service. **This roadmap defines the path from pre-alpha to a shippable product by implementing all three systems within Sigil.**

**Critical constraint:** The three system repositories at `/Users/jimdaley/projects/qwen/sigil/` are **reference material only**. They must never be imported as dependencies. Templates may be copied, but implementation means coding according to the design specifications laid out in those repositories.

---

## Current State (PA.0.1.0 — Phase 1)

**Completed:**
- Modular runtime with 8 service modules (APS, Aeostara, VisibleGlyph, SourceAuthority, PipelinePlaceholder, PrivacySecurity, Diagnostics)
- Single SwiftUI dashboard (NavigationStack + LazyVGrid cards)
- Deterministic visible-glyph service (profile input → hidden geometry → family key → vector paths → quality gate → SVG artifact)
- Source authority hierarchy (ASH Model → Yggdrasil World Engine → APS → WRW → Sigil)
- Local-only privacy posture (no analytics, no backend, no network)
- 22 passing Swift tests, 0 failures
- Repository guardrails (attribution, version, changelog, source authority)

**Current architecture uses Forsetti as an external dependency** (pinned commit). This must change: Sigil must **implement** Forsetti, not depend on it.

---

## The Three Systems to Implement

### System 1: Forsetti Framework

**What it is:** A modularity-first, object-oriented Apple-platform framework for iOS and macOS applications.

**Core capabilities:**
- Module discovery from bundled manifests
- Compatibility validation before activation
- Entitlement-aware module locking/unlocking
- Flexible module activation (4 deployment patterns)
- Structured UI contributions (toolbar, theme tokens, overlays, view injection)

**Key contracts to implement:**
- `ForsettiModule`, `ForsettiAppModule`, `ForsettiUIModule`
- `ModuleManifest`, `ModuleDescriptor`
- `ModuleRegistry` (entry-point factories)
- `ManifestLoader` (discovers manifests from bundles)
- `CompatibilityChecker` (validates compatibility/capability/version)
- `CapabilityPolicy` (AllowAll or Fixed)
- `ActivationStore` (restores prior activation state)
- `ForsettiEntitlementProvider` (determines lock/unlock)
- `ForsettiServiceProviding` / `ForsettiServiceContainer`
- `UISurfaceManager` (reflects UI contributions)

**Deployment patterns to support:**
- Pattern A: Single-module app (most common)
- Pattern B: Multi-module single application (one UI module + service modules)
- Pattern C: Developer testing (multiple single-module apps)
- Pattern D: Dashboard deployment (end-user multi-app)

**Manifest contract (schema 1.1):**
- Required: `schemaVersion`, `manifestTemplateVersion`, `moduleID`, `displayName`, `moduleVersion`, `moduleType`, `supportedPlatforms`, `minForsettiVersion`, `capabilitiesRequested`, `entryPoint`, `runtimeRequirements`
- Optional: `maxForsettiVersion`, `iapProductID`, `defaultModuleRole`

### System 2: ASH Pattern System

**What it is:** A semantic core implementing 9 modules operating on the F2^9 state space (512 states).

**Nine semantic modules to implement:**
1. `ASHStateModel` — Full 9-bit state classification, admissibility, validity diagnostics
2. `ASHRecoveryEngine` — Recovery, fallback, containment, safe halt behavior
3. `ASHRealmEncoder` — Realm identity encoding from full 9-bit state
4. `ASHTransitionRegistry` — Transition definitions, applicability rules, transition chains
5. `ASHTopologyGenerator` — Topology expansion over codeword transformations
6. `ASHAxiomEvaluator` — Axiom evaluation (passed, failed, indeterminate)
7. `ASHGenerationPlanner` — Inspectable planning before materialization
8. `ASHArtifactEmitter` — Traceable descriptor emission from plans
9. `ASHDiagnosticsModule` — Explainable diagnostics (why states are valid/invalid, why transitions accepted/rejected, why recovery/fallback/containment/safe-halt occurred)

**Core semantics:**
- **State space:** F2^9 (512 states), each state is a vertex in the state space
- **Transitions:** XOR-by-codeword on the full 9-bit state: `x' = x ⊕ c`
- **Codeword set:** Canonical codewords used in transformations
- **Realm identity:** Stable semantic encoding of an ASH state (deterministic, same state → same identity)
- **System-state classification:** STABLE, UNSTABLE, CORRECTABLE, DEGRADED, CONTAINED, FAILED, SAFE_HALT
- **Determinism:** Equal inputs must produce equal semantic outputs for state classification, normalization, realm/orbit identity, transition application, topology generation, axiom evaluation, generation planning, artifact emission
- **Diagnostics:** Must explain why states are valid/invalid, why transitions accepted/rejected, why recovery/fallback/containment/safe-halt occurred. Silent correction and silent failure are not acceptable.

**Classification hierarchy (monotonic severity):**
STABLE < UNSTABLE < CORRECTABLE < DEGRADED < CONTAINED < FAILED < SAFE_HALT

**Recovery categories:**
- STABLE → NO_ACTION (normal operation)
- UNSTABLE → NORMALIZE_STATE (codeword-based normalization)
- CORRECTABLE → APPLY_CORRECTION (known codeword correction sequence)
- DEGRADED → FALLBACK_REQUIRED (select known-good state from fallback-policy registry)
- CONTAINED → CONTAINMENT_REQUIRED (restrict operations, await resolution)
- FAILED → ESCALATION_REQUIRED (escalate to external authority)
- SAFE_HALT → TERMINAL_NO_RECOVERY (irrevocable terminal action)

### System 3: Aeostara

**What it is:** A platform-specific realization providing platform isolation, baseline pinning, and migration provenance.

**Key responsibilities:**
- Platform branch isolation (macOS and iOS branches are permanent, non-merging)
- Baseline pinning to Aeostara base release v1.0.0
- Migration provenance tracking (immutable import tags)
- Platform-specific realization requiring independent platform audit
- Platform status matrix (coordination vs. runtime product)

**Branch model:**
- `main` — Coordination and governance only (no platform implementation)
- `platform/macos` — Native macOS realization (permanent, non-merging)
- `platform/ios` — Native iOS realization (permanent, non-merging)

**Implementation requirements:**
- Platform-specific realization must validate against pinned base release
- No floating source branch as semantic authority
- Independent platform audit required for each platform

---

## Roadmap

### Phase 2 — Forsetti Framework Implementation (Alpha — A.1.0)

**Goal:** Implement the Forsetti Framework within Sigil, replacing the external dependency.

**Scope:**
1. **Core runtime contracts** — Implement `ForsettiCore` with:
   - `ModuleRegistry` (entry-point factories, registration)
   - `ModuleManifest` / `ModuleDescriptor` (schema 1.1)
   - `ManifestLoader` (discovers manifests from bundles)
   - `CompatibilityChecker` (validates compatibility/capability/version)
   - `CapabilityPolicy` (AllowAll and Fixed implementations)
   - `ActivationStore` (restores prior activation state)
   - `ForsettiEntitlementProvider` (default and debug implementations)
   - `ForsettiServiceProviding` / `ForsettiServiceContainer`

2. **Platform services** — Implement `ForsettiPlatform` with:
   - Native platform service adapters (Apple-native networking, storage, Keychain-backed secure storage, local file export, telemetry placeholders)
   - Default entitlement provider (StoreKit 2 for iOS, static allowlist for macOS)
   - In-memory secure storage (explicit test/debug composition only)

3. **Host template** — Implement `ForsettiHostTemplate` with:
   - SwiftUI host controller/views for module discovery and activation UI
   - `ForsettiHostTemplateBootstrap` (makes controller from manifests, registry, entitlement provider)
   - `ForsettiHostRootView` (renders host UI)

4. **Deployment patterns** — Support all four patterns:
   - Pattern A: Single-module app (default)
   - Pattern B: Multi-module single application
   - Pattern C: Developer testing
   - Pattern D: Dashboard deployment

5. **Module authoring workflow** — Provide Xcode templates for:
   - Forsetti App (production starter)
   - Forsetti UI Module
   - Forsetti Service Module
   - Forsetti Manifest

**Key files (new targets in Sigil):**
- `Sources/ForsettiCore/` — Runtime contracts, models, compatibility checks, activation orchestration
- `Sources/ForsettiPlatform/` — Native platform service adapters and entitlement implementations
- `Sources/ForsettiHostTemplate/` — SwiftUI host controller/views for module discovery and activation UI

**Verification:**
- Module registry registers and discovers modules from manifests
- Compatibility validation rejects incompatible modules (platform mismatch, version range mismatch, denied capability, schema mismatch)
- Entitlement provider correctly locks/unlocks modules
- All four deployment patterns function correctly
- Existing 22 tests still pass (visible-glyph service unchanged)

**Exit criteria:** Forsetti Framework fully implemented within Sigil; external Forsetti dependency removed; all four deployment patterns functional; module manifests (schema 1.1) properly discovered and validated.

---

### Phase 3 — ASH Pattern System Implementation (Alpha — A.2.0)

**Goal:** Implement the ASH Pattern System within Sigil, replacing the external dependency.

**Scope:**
1. **ASHCore library** — Implement all 9 semantic modules:
   - `ASHStateModel` — Full 9-bit state classification, admissibility, validity diagnostics
   - `ASHRecoveryEngine` — Recovery, fallback, containment, safe halt behavior
   - `ASHRealmEncoder` — Realm identity encoding from full 9-bit state
   - `ASHTransitionRegistry` — Transition definitions, applicability rules, transition chains
   - `ASHTopologyGenerator` — Topology expansion over codeword transformations
   - `ASHAxiomEvaluator` — Axiom evaluation (passed, failed, indeterminate)
   - `ASHGenerationPlanner` — Inspectable planning before materialization
   - `ASHArtifactEmitter` — Traceable descriptor emission from plans
   - `ASHDiagnosticsModule` — Explainable diagnostics

2. **ASHPatternSystem library** — Composition root for all 9 modules

3. **Core semantics:**
   - F2^9 state space (512 states)
   - XOR-by-codeword transitions: `x' = x ⊕ c`
   - Canonical codeword set
   - Realm identity (deterministic, same state → same identity)
   - System-state classification (STABLE, UNSTABLE, CORRECTABLE, DEGRADED, CONTAINED, FAILED, SAFE_HALT)
   - Deterministic output: same input always produces same output

4. **Diagnostics:** Must explain why states are valid/invalid, why transitions accepted/rejected, why recovery/fallback/containment/safe-halt occurred. Silent correction and silent failure are not acceptable.

**Key files (new targets in Sigil):**
- `Sources/ASHCore/` — All 9 semantic modules (StateModel, RecoveryEngine, RealmEncoder, TransitionRegistry, TopologyGenerator, AxiomEvaluator, GenerationPlanner, ArtifactEmitter, DiagnosticsModule)
- `Sources/ASHPatternSystem/` — Composition root

**Verification:**
- Unit tests for each semantic module against canonical corpus fixtures
- Deterministic output: same input → same state classification, realm identity, topology, axiom evaluation, generation plan, artifact emission
- Diagnostics explain all state transitions, recoveries, and failures
- Classification hierarchy monotonic: STABLE < UNSTABLE < CORRECTABLE < DEGRADED < CONTAINED < FAILED < SAFE_HALT
- All 512 states in F2^9 can be encoded as realm identities
- Codeword transformations are deterministic and pure: `(x ⊕ c) ⊕ c = x`

**Exit criteria:** All 9 ASH semantic modules implemented and tested; deterministic output verified; diagnostics explain all behavior; all 512 states encodable as realm identities.

---

### Phase 4 — Aeostara Implementation (Alpha → Beta — R.1.0)

**Goal:** Implement Aeostara within Sigil, providing platform isolation, baseline pinning, and migration provenance.

**Scope:**
1. **Platform isolation** — Implement branch isolation model:
   - `main` — Coordination and governance only (no platform implementation)
   - `platform/macos` — Native macOS realization (permanent, non-merging)
   - `platform/ios` — Native iOS realization (permanent, non-merging)

2. **Baseline pinning** — Pin to Aeostara base release v1.0.0:
   - Validate all implementations against pinned base release
   - No floating source branch as semantic authority

3. **Migration provenance** — Track platform-specific realizations:
   - Immutable import tags preserving branch histories
   - Provenance tracking for platform-specific changes

4. **Platform status matrix** — Implement platform-specific realization requiring independent platform audit:
   - `main` — Coordination and governance only (not a runtime product)
   - `platform/macos` — Native macOS realization (requires independent platform audit)
   - `platform/ios` — Native iOS realization (requires independent platform audit)

**Key files (new targets in Sigil):**
- `Sources/AeostaraCore/` — Platform isolation, baseline pinning, migration provenance
- `Sources/AeostaraPlatform/` — Platform-specific realization (macOS and iOS)

**Verification:**
- Platform branches remain isolated (no merging between macOS and iOS)
- Baseline pinning validated against v1.0.0
- Migration provenance correctly tracked with immutable import tags
- Platform status matrix accurately reflects each platform's audit status

**Exit criteria:** Aeostara fully implemented within Sigil; platform isolation enforced; baseline pinning validated; migration provenance tracked.

---

### Phase 5 — Identity Pipeline (Beta — R.1.1)

**Goal:** Complete the core identity processing pipeline from profile input to numerological output, integrating all three systems.

**Scope:**
1. **Profile ingestion** — Accept full profile data (name, birth date/time/location, other identity fields)
2. **Numerology calculation engine** — Implement standard numerology calculations:
   - Life path number (birth date reduction)
   - Expression/destiny number (name letter values)
   - Soul urge number (vowels)
   - Personality number (consonants)
   - Maturity number, birthday number, sub-cycle numbers
3. **Hidden geometry expansion** — Extend current `HiddenCanonicalGeometry` to include full numerology vectors
4. **Life-path root derivation** — Map numerology results to visible shape families
5. **Source authority integration** — Connect ASH Model → Yggdrasil World Engine → APS calculations

**Key files:**
- `Sources/RFSigilVisibleGlyph/` — Extend `HiddenCanonicalGeometry`, `SigilFamilyKey`
- `Sources/RFSigilCoreModels/` — Add numerology model types
- `Sources/RFSigilSourceAuthority/` — Connect ASH/YWE/APS calculation chains

**Verification:**
- Unit tests for each numerology calculation against known reference values
- Deterministic output: same input → same numerology → same visible glyph
- Regression: existing tests still pass

**Exit criteria:** All 8 standard numerology calculations implemented and tested; visible glyphs remain deterministic and quality-gated.

---

### Phase 6 — Celestial Naming (Beta — R.1.2)

**Goal:** Generate celestial names from profile data, integrated with the visible-glyph service.

**Scope:**
1. **Celestial name algorithm** — Derive names from numerology + profile data
2. **Name-to-glyph linkage** — Celestial names influence visible path synthesis (stroke selection, ornaments)
3. **Presentation layer** — Display celestial names in the dashboard alongside visible glyphs
4. **Quality gate integration** — Celestial name variations tested for collision handling

**Key files:**
- `Sources/RFSigilVisibleGlyph/` — Add celestial name generation to artifact flow
- `Sources/RFSigilUIModule/` — Display celestial names in dashboard cards
- `Sources/RFSigilCoreModels/` — Add `CelestialName` model type

**Verification:**
- Deterministic: same profile → same celestial name
- Collision handling: multiple candidates resolved deterministically
- Dashboard displays names alongside glyphs

**Exit criteria:** Celestial names generated deterministically for all golden fixtures; displayed in dashboard.

---

### Phase 7 — WRW Lore Generation (Beta → Release — R.2.0)

**Goal:** Generate narrative/story interpretation from profile + numerology + celestial data.

**Scope:**
1. **WRW (World Engine) integration** — Connect Yggdrasil World Engine simulation framework
2. **Lore generation** — Generate narrative interpretation from profile data:
   - Character archetypes
   - Life themes and challenges
   - Relationship dynamics
   - Growth opportunities
3. **Narrative-to-glyph linkage** — Lore influences presentation styling (not canonical data)
4. **Personal Codex** — Generate a structured personal narrative document

**Key files:**
- `Sources/RFSigilVisibleGlyph/` — Integrate WRW narrative into presentation layer
- `Sources/RFSigilCoreModels/` — Add `PersonalCodex` model type
- `Sources/RFSigilUIModule/` — Display narrative in dashboard

**Verification:**
- Output is deterministic (same input → same narrative)
- Narrative is bounded (no harmful or misleading content)
- Presentation changes don't affect canonical glyph data

**Exit criteria:** WRW lore generation produces deterministic, bounded narratives for all golden fixtures.

---

### Phase 8 — Sigil Flare Editor (Release — R.2.1)

**Goal:** Provide visual editing and customization of generated sigils.

**Scope:**
1. **Interactive editor** — Allow users to modify visible glyphs:
   - Adjust stroke weight, color, opacity
   - Add/remove ornaments
   - Modify presentation metadata (palette, glow, background)
2. **Canonical preservation** — Editor changes affect presentation only, not canonical data
3. **Version tracking** — Track editing history, allow revert
4. **Export preview** — Real-time preview of edited sigil

**Key files:**
- `Sources/RFSigilUIModule/` — Add editor views and view models
- `Sources/RFSigilCoreModels/` — Extend `SigilFlarePresentation` with editing support
- `Sources/RFSigilVisibleGlyph/` — Editor integration with quality gates

**Verification:**
- Editor changes don't affect canonical digest or vector paths
- Quality gates still apply to edited output
- Editing history is trackable and reversible

**Exit criteria:** Interactive editor functional; edited sigils pass quality gates; canonical data unchanged by editing.

---

### Phase 9 — Export & Bundles (Release — R.2.2)

**Goal:** Generate and export personal artifact packages.

**Scope:**
1. **Export bundle generation** — Package complete sigil artifacts:
   - SVG files (high-res)
   - Numerology report (PDF)
   - Celestial name document
   - Personal Codex (narrative)
   - Metadata (JSON)
2. **Share sheet integration** — Native iOS share sheet for exported bundles
3. **File format support** — SVG, PDF, PNG, JSON
4. **Bundle naming convention** — Deterministic bundle names from profile digest

**Key files:**
- `Sources/RFSigilUIModule/` — Add export/share sheet views
- `Sources/RFSigilCoreModels/` — Add `ExportBundle` model type
- `Sources/SigilApp/` — Add file sharing handlers

**Verification:**
- Exported bundles contain all expected artifacts
- Files are valid (SVG validates, PDF renders, JSON parses)
- Bundle names are deterministic

**Exit criteria:** Complete export bundles generated and shareable via iOS share sheet.

---

### Phase 10 — Optional Network Features (Release — R.2.3+)

**Goal:** Add optional network features, always opt-in and user-controlled.

**Scope:**
1. **Analytics (opt-in)** — Anonymous usage analytics (which features used, not personal data)
2. **Backend upload (opt-in)** — User-initiated upload of exported bundles to cloud storage
3. **Personal-data network (opt-in)** — User-controlled sharing of sigils with other users
4. **Sync across devices** — User-initiated sync of personal data (encrypted at rest)

**Key files:**
- `Sources/RFSigilDiagnostics/` — Add optional analytics collection
- `Sources/RFSigilAPSIntegration/` — Add optional backend upload
- `Sources/RFSigilPrivacySecurity/` — Add network opt-in controls

**Verification:**
- All network features are opt-in with clear user controls
- No network activity occurs without explicit user consent
- Sensitive data never leaves device without encryption and user approval

**Exit criteria:** All network features are opt-in, user-controlled, and respect privacy boundaries.

---

## Version Progression

| Stage | Version | Description |
|-------|---------|-------------|
| **PA** (Pre-Alpha) | PA.0.1.0 | Current state — modular runtime, dashboard, bounded visible-glyph service (Forsetti as external dependency) |
| **A** (Alpha) | A.1.0 | Phase 2 — Forsetti Framework implementation (replacing external dependency) |
| | A.2.0 | Phase 3 — ASH Pattern System implementation (replacing external dependency) |
| **R** (Release) | R.1.0 | Phase 4 — Aeostara implementation (replacing external dependency) |
| | R.1.1 | Phase 5 — Identity pipeline (numerology) |
| | R.1.2 | Phase 6 — Celestial naming |
| | R.2.0 | Phase 7 — WRW lore generation (first shippable product) |
| | R.2.1 | Phase 8 — Sigil Flare editor |
| | R.2.2 | Phase 9 — Export & bundles |
| | R.2.3+ | Phase 10 — Optional network features |

---

## Architecture Dependencies

The roadmap builds on the existing Phase 1 architecture and adds three internal systems:

```
SigilApp (iOS app)
  └── SigilRuntime (runtime assembly)
        └── SigilForsettiModules (module catalog)
              ├── ForsettiCore (NEW — internal implementation)
              ├── ForsettiPlatform (NEW — internal implementation)
              ├── ForsettiHostTemplate (NEW — internal implementation)
              ├── ASHCore (NEW — internal implementation)
              ├── ASHPatternSystem (NEW — internal implementation)
              ├── AeostaraCore (NEW — internal implementation)
              ├── AeostaraPlatform (NEW — internal implementation)
              ├── RFSigilVisibleGlyph (visible-glyph service)
              ├── RFSigilSourceAuthority (source hierarchy)
              ├── RFSigilAPSIntegration (APS gateway)
              ├── RFSigilAeostaraIntegration (platform gateway)
              ├── RFSigilPrivacySecurity (privacy status)
              ├── RFSigilDiagnostics (local diagnostics)
              └── RFSigilUIModule (dashboard + editor + export)
```

**Key invariant:** Canonical data (profile digest, hidden geometry, vector paths) is never modified by presentation, editing, or export operations.

**Critical constraint:** The three system repositories at `/Users/jimdaley/projects/qwen/sigil/` are **reference material only**. They must never be imported as dependencies. Templates may be copied, but implementation means coding according to the design specifications.

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Forsetti implementation complexity (ModuleRegistry, ManifestLoader, CompatibilityChecker, CapabilityPolicy, ActivationStore, EntitlementProvider) | Implement incrementally; start with Pattern A (single-module); add patterns B/C/D as needed |
| ASH Pattern System complexity (9 semantic modules, F2^9 state space, 512 states, XOR-by-codeword) | Implement incrementally; start with StateModel and TransitionRegistry; add remaining modules; verify determinism at each step |
| Aeostara platform isolation (permanent branches, baseline pinning, migration provenance) | Implement platform isolation first; add baseline pinning; verify against v1.0.0 |
| Numerology calculations may produce unexpected results | Extensive unit tests against known reference values; deterministic output guaranteed |
| WRW lore generation may produce harmful content | Bounded output with quality gates; no unbounded generation |
| Editor may corrupt canonical data | Editor operates on presentation layer only; canonical data immutable |
| Network features may violate privacy | All network features opt-in; no network activity without consent; encrypted at rest |
| Dual build system (xcodegen + SwiftPM) drift | Guardrail validator checks both manifests; CI checks both |

---

## Success Metrics

A shippable Sigil product (R.1.0+) should:

1. **Demonstrate all three systems** — Forsetti Framework, ASH Pattern System, and Aeostara fully implemented within Sigil (not as dependencies)
2. **Be functional** — Users can input profile data and receive complete sigils with numerology, celestial names, and narrative
3. **Be deterministic** — Same input always produces same output (no randomness)
4. **Be private** — All processing local; no network required
5. **Be beautiful** — High-quality SVG output with quality gates
6. **Be exportable** — Complete artifact packages shareable via iOS share sheet
7. **Be stable** — 22+ passing tests, no regressions

---

## Reference Material

The following repositories contain the design specifications for the three systems. They are **reference material only** and must never be imported as dependencies:

- `/Users/jimdaley/projects/qwen/sigil/Forsetti-Framework-Mac-iOS-main/` — Forsetti Framework (module discovery, validation, activation, entitlements, UI contributions)
- `/Users/jimdaley/projects/qwen/sigil/ASH-Pattern-System-Mac-iOS-main/` — ASH Pattern System (9 semantic modules, F2^9 state space)
- `/Users/jimdaley/projects/qwen/sigil/Aeostara-Mac-iOS-main/` — Aeostara (platform isolation, baseline pinning, migration provenance)

Templates from these repositories may be copied for use in Sigil. Implementation means coding according to the design specifications laid out in those repositories.

---

## Notes

- This roadmap is **software-focused**, not business-focused. It describes what the software must do, not pricing, marketing, or distribution.
- The visible-glyph service (Phase 1) is the foundation for all future phases — it will grow in capability but not change its core contract.
- Privacy is a **hard constraint**, not a feature. Network features are optional and always user-controlled.
- The product is designed for **local-first** operation. Network features, when added, are supplements, not requirements.
- **Sigil is a demonstrator.** The three systems (Forsetti, ASH Pattern System, Aeostara) are the primary focus. The visible-glyph service, numerology, celestial naming, and narrative are secondary features that demonstrate the systems' capabilities.
- The three system repositories are **reference material only**. They must never be imported as dependencies. Templates may be copied, but implementation means coding according to the design specifications.
