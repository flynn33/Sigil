# Handoff — ASH Source Trace (SIGIL-DEC-2026-10-09-ASH-TRACE)

**Completed:** 2026-11-02
**Source baseline examined:** `53ba4895cdea2cb5d91888c369e1f980a2580067` (`main`, clean tree, remote in sync)
**Corrections (2026-11-03, Package 01 remediation):** the 39-character baseline hash on the line above was a transcription error and is corrected to the 40-character Git identity. Source-relationship claims (codeword-table relationship, state-space scope, branch-tree/rendering-grammar separation) are corrected in the linked trace documents as recorded in [findings-and-next-change.md](../ash-trace/findings-and-next-change.md) F-01/F-11 (restated) and the ledger `corrections_2026_11_03` field; executed results are unchanged.
**Publication identity:** see Git history for the integration of this documentation change into `main` (this record identifies the pre-publication baseline only; it does not embed its own commit hash).

## What this investigation established

The bounded read-only trace from `SigilVisibleGlyphService.makeHiddenGeometry(for:)` to the governing ASH mathematics, canonical data, and referenced binary artifacts is complete. Deliverables:

- [Source-to-output map](../ash-trace/source-to-output-map.md) — the full call/data-flow path with exact locators, the governing authorities and their identities, the per-intermediate relationship table, and the embedding-only responsibility check.
- [Trace ledger](../ash-trace/trace-ledger.json) — all 34 required trace rows classified `supported` / `substitution` / `unresolved` / `not_applicable`, with source-linked observations, references, findings, impact, and verification-case links.
- [Findings and next change](../ash-trace/findings-and-next-change.md) — findings F-01 through F-12, compatibility impact, and the smallest proposed change marked **draft / not accepted**.
- [Verification cases](../ash-trace/verification-cases.md) — executed current-behavior results kept separate from proposed conformance oracles.

Headline results:

- 14 rows `supported` (determinism, digest integrity, fail-closed validation, Flare immutability, privacy posture, runtime integration, quality gates, canonical serialization, embedding disposition, and the product-owned boundaries around them).
- 16 rows `substitution` — the identity layer (ASH state, orbit class, plane vector, wolf balance, ancestry, celestial basis, anchors, edges, candidates, vector paths) and several numerology/input treatments are local digest-derived or non-standard substitutions for the cited governing behavior.
- 4 rows `unresolved` with recorded retrieval evidence: birth weekday (required, absent, role undecided), birth location (plan requires geocoding support; canonical sources silent; role undecided), parents' birth order (required, absent, no source rule), and the master-number policy (product preserves 11/22/33; canonical generator fully reduces; no approved record decides).

## Unresolved items a successor must not invent an answer to

1. **F-01 representation and formalization (restated 2026-11-03):** the image/video reference application's 256-state integrity subset `E` inside the 512-state `F2^9` universe versus the APS R1 all-first-class-coordinate model — a domain distinction over a common nine-coordinate universe; the serialized codeword tables agree exactly under a documented final-two-coordinate swap (coordinate conventions: ASH-Model one-based `x1..x9`, APS zero-based `b0..b8`). Resolved as a product-owned design decision in the Package 01 planning pass under the 2026-11-03 assignment; any remaining genuine normative conflict stays specific and visible.
2. **F-02 profile mapping:** no canonical profile-input to F2^9 mapping exists in the retrieved sources; owner-adopted rule required.
3. **F-05 master numbers:** preserve or reduce.
4. **F-06 input treatments:** weekday, time, location (geocoding scope under the privacy boundary), birth order, parents' birth order, first/last split, ancestral surnames.

The smallest proposed change in the findings document is **draft / not accepted** and names these as prerequisites. No implementation, formula selection, dependency change, or version change is authorized by the trace.

## Boundaries preserved

- No changes to `Sources/`, `Tests/`, `Package.swift`, `Package.resolved`, `Sigil.xcodeproj/`, `project.yml`, `VERSION`, `scripts/`, `tools/`, `.github/`, `.githooks/`, or `Resources/`.
- No personal-data embedding of any form (removed, not deferred); no payload carrier, sidecar, or scan-to-record reintroduced.
- Version surfaces unchanged and re-verified: `PA.0.1.0` / build `1` (fresh Debug iOS-simulator build on 2026-11-02: `BUILD SUCCEEDED`, 0 errors, 0 project-code warnings).
- The owner has designated this repository as the authoritative Project Record; the external execution record (checkpoints, raw logs, result bundles, package working state) remains outside the repository by design.

## Verification summary (fresh 2026-11-02 at the baseline)

22/22 iOS-simulator tests passed (fresh DerivedData, fresh result bundle); repository guardrails, version guard, attribution guard, 17 guard unit tests, and the verification wrapper all passed; the instruction-package integrity check and 20 helper tests passed. Raw logs and the result bundle are in the owner-external evidence root, cited by measured SHA-256 in the ledger.

## Next eligible engineering action

**Superseded as a gate on 2026-11-03.** The owner's decision `SIGIL-DEC-2026-11-03-AUTONOMOUS-SEQUENCE` ([record](../decisions/2026-11-03-autonomous-phase-sequence.md)) authorizes the remaining development sequence, including the IDENTITY-PIPELINE workstream, as the seven-package work order. Items 1-4 above are resolved in the Package 01 planning pass as documented product-owned design decisions, following the source-reconciliation direction of the remediation brief; any genuine remaining upstream source conflict stays isolated and visible.

The historical boundary of this trace is preserved: the trace itself never authorized implementation, and its read-only results stand as recorded, subject to the documented corrections (coordinate convention, state-space scope, and topology/grammar separation) delivered with that planning pass.
