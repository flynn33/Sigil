# Sigil — Product Roadmap

**Planning revision:** 2026-11-05
**Observed product baseline:** `PA.0.3.0` (build 4), Phase 1 foundation with the Package 01 remediation/diagnostic foundation, the Package 02 identity pipeline, and the Package 03 artifact-health and encrypted local persistence
**Inspected source:** `main` at `bc277ea05239398d58e70b76ad318de2765148d3` (the 2026-11-02 ASH-TRACE publication; the 2026-10-10 revision inspected `19a0e2b9e9ad6fbaec06b62d2e084f444e92e84b`)
**Target product:** Native iOS Sigil application
**Current product plan:** [Project plan](project-plan.md)

## Direction and decision history

Sigil uses ASH cosmological mathematics to derive its generated form. It is not merely a themed symbol generator, and it is not required to be a container for an embedded personal record.

The October 10 owner decision removes the additional personal-data embedding layer from the product requirements. Payload encoding, decoding, and recovery from a Sigil are **removed, not deferred**. Do not reinstate the same requirement as a mandatory hidden layer, metadata payload, or sidecar. The exact decision and retained boundaries are recorded in [Remove personal-data embedding](decisions/2026-10-10-no-personal-data-embedding.md).

The approved next engineering action was the bounded ASH-to-Sigil source trace recorded as `SIGIL-DEC-2026-10-09-ASH-TRACE`, amended by `SIGIL-DEC-2026-10-10-NO-EMBEDDING`; the trace was completed on 2026-11-02 (see the ASH-TRACE workstream below). Neither this roadmap nor its publication authorizes an unspecified formula change or a full framework rewrite.

This revision reconciles the August 2 roadmap with the current project direction. Earlier text remains available in Git history; historical phase numbers and projected releases do not constitute completed work or an execution grant.

## Current state: retain the foundation

| Area | State at the inspected baseline |
| --- | --- |
| Runtime | Existing Forsetti-backed app-owned assembly and module catalog; one SwiftUI UI module and seven service modules. |
| Visible glyph | Bounded local geometry and SVG service, quality/collision checks, digest linkage, and separate Flare presentation. |
| ASH integration | Mathematical identity resolution is established in the visible-glyph service (source-backed numerology + nine-bit ASH state/orbit/classification through the APS canonical contract); the status/evidence gateway remains a separate reporting surface. |
| Generation path | `SigilVisibleGlyphService.makeHiddenGeometry(for:)` now resolves the source-backed ASH state (standard numerology, nine-bit state/orbit/classification, wolf balance) through the governing contracts; the final mathematical glyph materialization (Package 05) is pending. |
| Full workflow | The standard numerology and ASH/APS state resolution are delivered (Package 02); the input workflow UI, naming, lore, PersonalCodex, encrypted persistence, editor, and final exports are not yet completed. |
| Evidence | Fresh 2026-11-04 verification reports 48 Swift tests and 48 iOS-simulator tests (0 failures) and strict guardrails; the older 22-test figure is the inherited Phase 1 baseline. |
| Native targets | iOS 17+ app; Swift package declares macOS 14+ support. This does not add a separate macOS consumer-product milestone. |

Do not restart the app, relabel gateway status as a completed resolver, remove working internal geometry because it is called “hidden,” or declare encrypted storage implemented because readiness is modeled.

Source references: [architecture](architecture.md), [visible-glyph engine](visible-glyph-engine.md), [verification](verification.md), `Package.swift`, and the generation service and tests named below.

## Required product flow

Mortal input → local canonicalization and validation → standard numerology → source-backed ASH state/orbit/class resolution with APS stabilization → applicable Aeostara health validation → WRW interpretation → PersonalCodex → canonical ASH-derived Sigil → optional non-authoritative Flare → user-initiated display/export.

Health validation applies at the artifact boundaries that own the data; the sequence does not require validating a not-yet-created document. PersonalCodex is a separate local product record, not a payload the Sigil must carry.

No extra encoder/decoder stage appears in this flow. Reproducible generation from retained inputs and safe recovery of valid local artifacts remain distinct from reconstructing an embedded personal record from a glyph.

## Delivery workstreams

The following labels organize retained work. They are not newly approved algorithms, deadlines, or product versions. The source trace was the approved next engineering investigation until it completed on 2026-11-02. The owner's 2026-11-03 decision `SIGIL-DEC-2026-11-03-AUTONOMOUS-SEQUENCE` (recorded in the [project plan](project-plan.md)) is the concrete source-backed assignment for the remaining workstreams, organized as the seven-package sequence: 01 remediation and source alignment, 02 identity pipeline, 03 artifact health and local storage, 04 canon and PersonalCodex, 05 ASH-derived glyph, 06 native experience and export, 07 integration and owner handover. Candidate/distribution builds, signing, releases, and physical-device qualification remain the owner's work.

### ASH-TRACE — Source trace (complete)

**State:** Investigation complete 2026-11-02 at source baseline `53ba4895cdea2cb5d91888c369e1f980a2580067`; source-relationship claims corrected 2026-11-03 in Package 01 remediation (coordinate convention, state-space scope, branch-tree/rendering-grammar separation; see the corrections noted in the linked documents). Deliverables: [source-to-output map](ash-trace/source-to-output-map.md), [34-row trace ledger](ash-trace/trace-ledger.json), [findings and smallest next change (draft, not accepted)](ash-trace/findings-and-next-change.md), [verification cases](ash-trace/verification-cases.md), and the [continuation handoff](handoffs/ash-trace.md). The exit condition was met: every mapped result is supported, an evidenced substitution, or explicitly unresolved; proposed tests are recorded separately from executed commands; no application source changed during the investigation. The findings' recorded decisions were the gate for the next assignment; the trace itself never authorized implementation (that gate was superseded on 2026-11-03 by [SIGIL-DEC-2026-11-03-AUTONOMOUS-SEQUENCE](decisions/2026-11-03-autonomous-phase-sequence.md), under which the decisions are resolved as documented product-owned design decisions).

Start at `Sources/RFSigilVisibleGlyph/SigilVisibleGlyphService.swift::makeHiddenGeometry(for:)`. Trace callers, helpers, shared models, consumers, and tests. Map each identity-bearing intermediate and geometric output to the applicable ASH mathematics, canonical data, and referenced binary artifacts. Follow APS, Aeostara, and Forsetti contracts where the actual path requires them.

**Deliverables:** A source-to-output map with exact source revisions and locators; supported conformance findings; temporary substitutions; unresolved evidence; any embedding-only responsibilities actually found; the smallest necessary change and its consumer/compatibility impact; and source-backed verification cases.

**Exit condition:** Each mapped result is supported or explicitly unresolved. Proposed tests identify expected results and their source, separately from commands actually executed. Embedded-payload round-trip recovery is not an exit gate. Do not change application source during this investigation merely because a candidate fix is identified.

### IDENTITY-PIPELINE — Inputs, numerology, and ASH/APS realization

**State:** Delivered 2026-11-04 at `PA.0.2.0` / build 3 (Package 02 of the authorized sequence). Package 01 (complete, 2026-11-04) delivered the bounded identity/input treatment specification ([design/identity-input-treatment.md](design/identity-input-treatment.md)) and the required system realization contracts with independent acceptance ([system-realization/](system-realization/README.md)). Package 02 implemented the retained input model and local validation, the explicit source-backed standard numerology bridge, and the ASH state/orbit/classification resolution through the governing contracts (finite nine-bit `F2^9` state, the exact 16-member `[9,4,4]` codeword set, 32 orbits, the named `sigil-profile-adapter.v1` seam, the `b6 <-> b7` coordinate involution, and wolf balance). The final mathematical glyph materialization remains in ASH-GLYPH (Package 05) and the PersonalCodex in CANON-AND-PersonalCodex (Package 04).

Implement the retained input model and local validation; make the standard numerology bridge explicit and source-backed; resolve the applicable ASH state/orbit/celestial-class basis through the governing contracts. Preserve all supported input signals rather than replacing them with profile-hash state selection. Reuse and extend the existing product-owned modules where the trace supports that choice.

**Exit condition:** End-to-end fixtures establish the agreed input reductions and ASH semantics, deterministic results, invalid/partial input behavior, and diagnostic explanations. Exact numerology policy choices are resolved from authoritative records and applicable sources before dependent behavior is implemented; this roadmap does not choose new weights or algorithms.

### ARTIFACT-HEALTH — Validation, privacy, and local persistence

**State:** Delivered 2026-11-05 at `PA.0.3.0` / build 4 (Package 03 of the authorized sequence). A product-owned, non-destructive Aeostara artifact-health validator over the real artifact (fail-closed, pure, recovering only metadata derivable from intact authoritative content, covering all five failure kinds) and real local-only encrypted persistence (versioned AES-GCM envelopes via CryptoKit, Keychain-backed keys stored separately from ciphertext, atomic replace preserving the last-verified record, no CloudKit/sync/upload) now ship in the runtime. A truthful runtime facade reports a failed save as a failure, never a success, with redacted diagnostics and a `secure-persistence` dashboard card. Design rationale: [design/secure-local-storage.md](design/secure-local-storage.md).

Apply source-backed Aeostara health checks to the actual records, geometry, schemas, and integrity relationships. Preserve safe failure, containment, and recovery of derivable optional metadata. Implement Apple-native encrypted-at-rest storage before introducing persistent sensitive records. Maintain local, redacted diagnostics and explicit error handling.

**Exit condition:** Tests cover invalid/corrupt records, schema and integrity failures, persistence failure and interruption, safe recovery, and the no-backend/no-analytics boundary. A passing local status object is not sufficient evidence. This workstream is not a personal-payload decoder and does not transfer another repository's branch layout into Sigil.

### CANON-AND-PersonalCodex — Celestial naming and WRW interpretation

**State:** Remaining product work; approved by the 2026-11-03 decision and executed as Package 04 of the authorized sequence. Depends on source-backed identity data and safe artifact handling from Packages 02 and 03.

Use the typed canon/specification resources for celestial naming, plane attunement, wolf balance, ancestry, bounded Trials/branch interpretation, and the user-facing PersonalCodex sections in the [project plan](project-plan.md). ASH supplies the structural identity; WRW interprets it. Do not substitute an unrelated world-simulation runtime or generic generated prose.

**Exit condition:** Approved fixtures demonstrate deterministic names, interpretations, and PersonalCodex records with provenance and bounded narrative behavior. Missing source rules are explicit rather than filled with invented identity meaning. The PersonalCodex is readable in the app and need not be recoverable from the Sigil.

### ASH-GLYPH — Mathematical materialization and visible quality

**State:** Approved by the 2026-11-03 decision and executed as Package 05 of the authorized sequence. The existing bounded generator is the starting point; the final mathematical connection is established from the corrected source alignment delivered in Package 01.

Apply the smallest ASH-TRACE-supported change so governing cosmological mathematics determines canonical form. Preserve deterministic generation and the existing quality, integrity, and presentation boundaries where compatible with the verified contract. Inspect internal geometry on its mathematical merits; do not delete it solely because its type name contains “Hidden.”

**Exit condition:** Source-backed fixtures connect mathematical state to actual geometry; generation is reproducible with fixed input, source/policy versions, and declared candidate-selection context; geometry and thumbnail-quality checks are meaningful; Flare does not mutate canonical identity. Fixture distinctness and collision handling must not be presented as a proof of universal uniqueness. No payload capacity, scan-to-record, or embedded-record recovery requirement is added.

### EXPERIENCE-AND-EXPORT — Native workflow, Flare, and explicit sharing

**State:** Remaining product work; approved by the 2026-11-03 decision and executed as Package 06 of the authorized sequence. Depends on stable identity, PersonalCodex, geometry, and storage contracts.

Complete the native input/results experience, user-facing PersonalCodex, presentation-only Flare editor, and explicit export/share workflow. Separate canonical content from display effects. Local export of a user-selected PersonalCodex/report is distinct from making the glyph an encoded personal record. Final export formats and metadata content remain governed by the applicable product decision, not by a reinstated embedding requirement.

**Exit condition:** UI and accessibility checks exercise empty, invalid, loading, cancelled, failure, and successful states. Editor changes preserve canonical identity. Export validation covers output correctness, selected content, error handling, and privacy. No analytics, application backend, automatic personal-data upload, or sync feature is introduced under an “optional” label.

### CANDIDATE-VALIDATION — Evidence-backed delivery

**State:** Package 07 of the authorized sequence prepares the integrated development verification, remaining repairs, and owner test procedures. Candidate production, physical-device validation, and any release remain the owner's work under the 2026-11-03 decision; this roadmap grants no release.

Run the applicable native host/simulator checks, source-conformance tests, privacy/storage checks, and repository guardrails against an identified source revision. Keep README, changelog, project configuration, versions, and wiki consistent with actual delivered behavior. Prepare owner hardware-validation procedures when a candidate exists.

**Exit condition:** Required evidence identifies actual commands, environment, results, limits, and source version. Unrun checks and owner physical-device validation remain distinct from host/simulator passes. Candidate delivery, repository publication, and release approval are separate states.

## Disposition of the previous roadmap

| August 2 item | Current disposition |
| --- | --- |
| Phase 1 foundation | Retained; correct the module count to eight total, not eight service modules. |
| Phases 2–4: implement all three systems before product work | Not an active blanket rewrite mandate. Preserve existing boundaries; let the source trace and applicable contracts establish necessary product-owned realization. Do not change dependencies or adopt a new system architecture in this documentation update. |
| “Never import any dependency” statements | Not a replacement for exact source-role and public-product classification. The observed `ForsettiCore` dependency is pinned at `43eef7a739f3b78253c64aa4b070521ab5b1f43c`; preserve it for this bounded update without treating presence as a conformance certificate. |
| Aeostara permanent branch scheme copied into Sigil | Not an approved Sigil branch migration. Keep upstream source-platform boundaries separate from product repository organization. |
| Phases 5–7: input/numerology, names, lore | Retained within IDENTITY-PIPELINE and CANON-AND-PersonalCodex, with the governing ASH connection and full PersonalCodex restored to the foreground. |
| Phases 8–9: Flare and exports | Retained without a recoverable personal payload inside the glyph or a mandatory substitute carrier. |
| Phase 10: analytics, upload, network sharing, sync | Excluded by the retained product privacy boundary; not merely delayed until a later version. User-initiated native export and disclosed Apple system-service behavior remain separate. |
| Projected `A.1.0` / `R.1.0` style milestones | Not release commitments. Use the repository's four-part version policy when a real version change is justified. No candidate or stage advance is established here. |
| Older project notes requiring a reversible personal-data carrier | Superseded only for added payload embedding/recovery; retain mathematical transformations, canonical source data, and safety recovery. |

## Unresolved items and continuity

The exact mathematical mapping, smallest code change, test expectations, and any required compatibility migration remain investigation outputs. Older context questions about master-number handling, weekday authority, location precision, birth-order/ancestry rules, bounded Trials summaries, and export details must first be reconciled with existing decisions; they are not a request to repeat answered questions.

The owner has designated this repository as the authoritative Project Record (recorded in the [project plan](project-plan.md), Source continuity); the [ASH-TRACE handoff](handoffs/ash-trace.md) is the current continuation record for the completed trace. The development-policy binding distinction (execution-time 0.8.0 snapshot versus the package intake/reference pin) is preserved in the project plan. The policy version, the Phase 1 package revision, this planning date, and the application version remain different identities; none substitutes for another.

**Next engineering action:** Package 04 of the authorized seven-package sequence (Canon and PersonalCodex). Package 03 (artifact health and encrypted local persistence) completed 2026-11-05 at `PA.0.3.0` / build 4 with fresh SwiftPM verification (76 tests, 0 failures; strict guardrails, version and attribution guards, and the wrapper with `swift test --parallel` and `xcodebuild -list` passed; the full iOS-simulator build was not re-run this session): the product-owned non-destructive Aeostara artifact-health validator (fail-closed, pure, recovering only metadata derivable from intact authoritative content, covering all five failure kinds), real local-only encrypted persistence (versioned AES-GCM envelopes via CryptoKit, Keychain-backed keys stored separately from ciphertext, atomic replace preserving the last-verified record, no CloudKit/sync/upload), and a truthful runtime facade reporting a failed save as a failure with redacted diagnostics and a `secure-persistence` dashboard card. Package 04 depends on the safe artifact handling from Packages 02 and 03. The final mathematical glyph materialization remains in ASH-GLYPH (Package 05). The additional embedding requirement remains removed.
