# Sigil Phase 1 Implementation Plan

## Scope

Build the native iOS Phase 1 foundation with a Forsetti-backed modular structure, app-owned status gateways, one SwiftUI dashboard module, local-only diagnostics, and placeholder-only pipeline status.

## Implementation Steps

1. Define shared status, evidence, source-authority, integration, placeholder, privacy, and diagnostic models in `RFSigilCoreModels`.
2. Add service modules for APS, Aeostara, YWE/WRW source authority, placeholder pipeline, privacy/security, and diagnostics.
3. Add exactly one SwiftUI UI module for the Phase 1 dashboard.
4. Add a Forsetti module catalog that owns descriptors, manifests, schema `1.1`, runtime requirements, capability declarations, and public module registration.
5. Add a runtime assembly that composes services and feeds the dashboard through app-owned view models.
6. Validate with SwiftPM, Xcode simulator build/test, static analysis, and source-authority package commands.
7. Maintain repository documentation, wiki documentation, and changelog entries as the implementation surface expands.

## Boundaries

Phase 1 now includes a bounded deterministic visible-glyph service with local hidden geometry, visible vector paths, digest linkage, and quality gates. The full identity pipeline, numerology calculation, celestial naming, WRW lore generation, personal artifact package generation, export bundles, analytics, backend upload paths, and personal-data network flows remain unavailable.

## Documentation Surfaces

- `README.md` is the repository entry point for current status, architecture, verification, versioning, and boundaries.
- `docs/architecture.md` records module ownership, runtime composition, capability policy, and phase boundaries.
- `docs/visible-glyph-engine.md` records visible-glyph data flow, quality gates, validation behavior, and fixture evidence.
- `docs/verification.md` records local verification commands, test inventory, workflow expectations, and guardrail scope.
