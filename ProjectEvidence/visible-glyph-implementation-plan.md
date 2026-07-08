# Visible Glyph Implementation Plan

## Goal

Add a bounded visible-glyph generation foundation that is deterministic, local, testable, and integrated with the existing runtime surface.

## Architecture

- Add `RFSigilVisibleGlyph` as an app-owned service module.
- Keep data contracts public in the new module and reuse `RFSigilCoreModels` for status and validation decisions.
- Keep Forsetti integration at the module boundary only; do not modify dependency internals.
- Keep the full identity pipeline placeholder in place, but narrow the unavailable feature list to surfaces still out of scope.

## Tasks

1. Add failing XCTest coverage for deterministic generation, golden-profile uniqueness, quality rejection, collision retry, presentation invariance, and fail-closed validation.
2. Add public Swift models for profile input, hidden geometry, family key, visible vector paths, quality report, style metadata, visible sigil, presentation sidecar, and artifact bundle.
3. Add canonical JSON encoding and SHA-256 digest helpers inside the visible-glyph module.
4. Add deterministic hidden geometry, family-key derivation, constrained vector grammar, quality gate, SVG renderer, presentation sidecar, and artifact validator.
5. Add the module to SwiftPM, XcodeGen, the generated Xcode project, Forsetti module catalog, runtime assembly, and dashboard status.
6. Regenerate Xcode project from `project.yml`.
7. Generate SVG evidence for all golden profiles at full and thumbnail sizes.
8. Run SwiftPM, Xcode simulator, repository guardrail, attribution, version, and diff checks.
9. Commit locally and do not push or open a PR.
