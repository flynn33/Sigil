# Sigil — Current Project Plan

**Planning revision:** 2026-10-10
**Scope:** Retained product requirements and current direction; not a completed-implementation report
**Delivery sequence and status:** [Product roadmap](roadmap.md)

## Product outcome

Sigil is a native, local-first iOS application for deterministic ASH/WRW identity interpretation and Sigil generation. The governing ASH cosmological mathematics must produce the structural identity and canonical form; an ASH visual theme or a digest-derived placeholder is not sufficient.

This plan continues the existing Phase 1 foundation. Forsetti, APS, and Aeostara support the product through their applicable contracts and product-owned realization; demonstrating those systems does not replace the user's identity/PersonalCodex/Sigil workflow with a project to rewrite every framework.

## Controlling decisions

| Record | Retained effect |
| --- | --- |
| July 8 context lock, subject to subsequent owner corrections | Native/local-first product, standard numerology input bridge, ASH/APS resolution, Aeostara health gates, WRW interpretation, PersonalCodex, canonical materialization, and non-authoritative Flare. Its old statement that the repository was empty is historical, not current state. |
| ASH mathematical requirement retained by the October 9 approval and October 10 amendment | The generation formula must be based on ASH mathematics and cosmology. Relevant canonical data and binary artifacts are not dismissed as unrelated. |
| `SIGIL-DEC-2026-10-09-ASH-TRACE` | Inspect the existing generation path and its source authority before choosing or applying a formula change. This is not a full framework-rewrite approval. |
| `SIGIL-DEC-2026-10-10-NO-EMBEDDING` | Remove the added data-embedding/personal-payload recovery requirement, rather than defer it. [Exact amendment](decisions/2026-10-10-no-personal-data-embedding.md). |

Later explicit owner decisions govern conflicts. Historical assistant proposals are not adopted wholesale. This plan and the roadmap do not silently upgrade the development playbook or select new source revisions.

## Inputs and deterministic bridge

The retained input model includes first and last name, date of birth, birth weekday, birth time, birth location with the specified Apple Maps/geocoding support, birth order, hair and eye color, parents' birth order, family/ancestral surnames, and heritage groups.

Canonicalize and validate locally. Apply the established standard numerology policy before ASH/WRW consumption. The recorded life-path requirement uses the full birth date in MMDDYYYY digit form, reduced under the selected policy. Every supported input needs an explicit deterministic treatment rather than an invented weighting rule or silent omission.

The historical celestial-name generator lists heritage, birth date, weekday, time, hair, eyes, and mortal name. Additional Sigil inputs require explicit policy and source-backed treatment; their presence in a UI or hash does not establish that mathematical integration.

Master-number handling, weekday authority, location precision/storage, birth-order treatment, and ancestry weighting must be recovered from applicable approved records and source contracts before dependent implementation. Do not infer approval from the current placeholder implementation.

## Source and component responsibilities

| Source/component | Required role and boundary |
| --- | --- |
| ASH Model | Governing cosmological/mathematical foundation. Trace applicable state, orbit, class, geometric relationships, source datasets, and referenced binary artifacts without inventing replacements. |
| APS | Source-backed ASH state resolution/stabilization, invariants, transitions and conformance/diagnostics under the applicable canonical and native contracts. Not a lore author or decorative style selector. |
| Forsetti | Sealed public runtime/module boundary with product-owned composition and services. Preserve the observed dependency for this update; future treatment must follow exact contracts, not whole-repository copying or a blanket rewrite rule. |
| Aeostara | Health validation of records and geometry, schemas, integrity, derivable optional metadata recovery, containment, and safe failure. Not a creator of identity, names, lore, or missing ASH facts. |
| WRW / Yggdrasil | Canon, lore, and character/world interpretation through typed resources and deterministic engines. Do not introduce a world-simulation runtime dependency merely to obtain lore. |
| Sigil application | Own input handling, policy bridge, orchestration, native UI, local records, mathematical materialization, quality checks, privacy, Flare, and explicit exports in cohesive modules. |

Source repositories are authority containers, not undifferentiated runtime dependencies. Canonical specifications, base designs, native implementations, governance, templates, examples, tests, corpora, binaries, and tools must retain their actual roles. A source-derived mathematical encoding or reversible transform is not the removed personal-payload layer.

## ASH/WRW identity and PersonalCodex

Preserve the nine-plane model: Physical, Etheric, Astral, Mental, Causal, Celestial, Shadow, Void, and Divine Core. The product uses a plane-attunement vector, not just a dominant-plane label. Retain the origin cosmology, White Wolf/Dark Wolf interpretation, and deterministic ancestry/bloodline treatment from the governing canon. Do not recast the wolves as simple good/evil opposites.

Retain the celestial-class/mortal-incarnation/branch-instance ontology, bounded Trials and branch summaries, and source-backed celestial naming. Model these as deterministic software interpretation, not proof of metaphysical truth. Mortal name, ASH structural identity, and WRW celestial name remain distinct concepts.

The user-facing PersonalCodex retains: Mortal Incarnation Record; Numerology Profile; ASH Identity / Advanced Canon Record; Plane Attunement Vector; Celestial Class / Origin Attribution; Celestial Name and Epithet; Wolf Balance; Bloodline / Heritage Resonance; Trials / Branch Echoes; Gifts, Burdens, Thresholds; Sigil Reading; and export/provenance/integrity information. Technical diagnostics and geometry belong under advanced provenance, not as a substitute for readable lore.

The PersonalCodex is a separate local record. It is not a payload required inside a visible or hidden Sigil layer.

## Canonical Sigil, internal geometry, and Flare

Materialize the Sigil after source-backed identity resolution, rather than using an arbitrary visible form as the identity source. The approved source trace must connect actual mathematical outputs to geometry and identify the smallest supported correction to the current local generator.

Retain determinism, meaningful geometry/visual-quality gates, provenance, and declared collision handling. Preserve existing tests until a separately scoped implementation change establishes that a test encodes a superseded contract. Do not assume a digest proves mathematical conformance, universal uniqueness, encryption, or non-disclosure.

Internal geometry and intermediate state may remain when needed for ASH mathematics, validation, rendering, or reproducibility. No added encoder, personal-payload storage channel, decoder, photograph-to-record function, or payload round-trip test is required. Do not rename a payload carrier “provenance” or move it to a mandatory sidecar to preserve the removed feature.

Flare is presentation only: effects, color, background, filters, and permitted overlays do not mutate canonical identity or its authoritative geometry. Reversible editing history is not the same as reconstructing an embedded personal record.

## Privacy, storage, diagnostics, and export

Process personal data on device. Preserve the no-analytics, no-app-backend, and no-personal-data-upload boundary. Do not create an optional-network phase as an exception. Disclose the specified Apple Maps/geocoding and other Apple system-service behavior separately from application data collection.

Use Apple-native secure storage/key handling and encryption at rest for persistent profiles, codices, and artifacts. The existing status-only readiness model is not proof of this implementation. Local diagnostics must not store unnecessary personal input or secrets; retain actionable failure evidence without hidden telemetry.

Export and sharing are user-initiated. Canonical and Flare outputs must be distinguishable. A separately selected PersonalCodex/report export is not an embedding layer; the final format, selected fields, and privacy validation remain explicit design work. No guarantee that a deterministic Sigil reveals nothing about its inputs is created by removing embedding.

## Current execution boundary

**Current (2026-11-06):** Package 06 of the authorized seven-package sequence (native experience, presentation-only Flare, and explicit export) is complete and published at `PA.0.6.0` / build 7 (feature advance: the native input → generate → result journey, the presentation-only Flare editor, and the user-selected export now ship in the app on top of the real pipeline and the real secure store; build advance because the capability ships in the app). Delivered: a three-tab experience (Dashboard / Create / Records); a `SigilProfileDraft` distinct from the canonical input with a single domain-boundary `SigilDraftPromoter` (required: name, birth date, birth city; all other fields optional with unknown as a legitimate state); a `SigilGenerationJourneyViewModel` state machine (idle/loading/success/failure/cancelled) with a monotonically-increasing `requestSequence` that drops out-of-order completions and supersedes in-flight requests; the real `SigilVisibleGlyphService` + `SigilPersonalCodexService` run off the main actor; a `SigilRecordsStore` actor wrapping the real `SigilSecurePersistenceService` (AES-GCM, Keychain keys, local directory) with upsert/open/delete/list and explicit+cancellable delete; a presentation-only Flare editor (approved palettes/backgrounds + glow, canonical-vs-styled preview, return-to-canonical) that never mutates the canonical identity/vector/digest; and user-selected export/share (canonical SVG, styled SVG, PersonalCodex JSON, PersonalCodex Markdown, redacted diagnostic JSON) via a native `ShareLink` with temp-file cleanup. Native functional integration tests (`JourneyIntegrationTests`) exercise the real services through create → generate → read codex → save → reopen → Flare → export with a synthetic fixture. Fresh verification: 136/136 Swift package tests, the strict project guardrail wrapper (strict validator + `swift test --parallel` 136/0 + `xcodebuild -list`) exited 0, `git diff --check` clean; the full iOS-simulator build was not re-run this session (2026-11-06; [verification.md](verification.md)). The next engineering action is Package 07 (integration and owner handover). The additional embedding requirement remains removed, not deferred. Design rationale: [design/native-experience-export.md](design/native-experience-export.md).

**Prior (2026-11-06):** Package 05 of the authorized seven-package sequence (ASH-derived canonical glyph) was complete and published at `PA.0.5.0` / build 6 (feature advance: the canonical ASH-derived visible glyph now ships in the runtime; build advance because the capability ships in the app). Delivered: the canonical ASH branch geometry as the visible glyph — the profile's decoded ASH state resolves to a branch message through a product-owned reference-codeword-to-APS-codeword message seam (a 16<->16 bijection onto the product's APS-native `[9,4,4]` codeword set, distinct from the `b6 <-> b7` coordinate adapter), and the visible vector paths are a deterministic, source-backed branch fan projected from the canonical topology into the 100x100 viewBox; a fail-closed, integrity-verified branch-topology resource in `RFSigilVisibleGlyph` (`Resources/ash/branch-topology.json`, 121 nodes / 81 leaves / 16 messages, re-hashed against a provenance manifest at load and structurally validated); deterministic, source-backed candidate selection (the smallest in-budget leaf fan whose real crossings are within the quality limit, with sparse channels completed deterministically from adjacent messages so collision resolution changes the geometry); a real recomputed proper-interior major-crossing count; and a geometry-only collision signature for cross-profile data quality. The temporary digest-parameterized renderer is gone; a missing message or an out-of-budget fan fails closed. The Package 04-deferred PersonalCodex Sigil Reading is now complete, recording a one-way link to the canonical geometry digest and to the geometry-only identity of the selected visible branch geometry (no new target dependency; the acyclic record digest is unchanged in construction). A stale identity test was corrected: the master number is annotation-only, and the branch-derived glyph has no numerology accent path. Fresh verification: 111/111 Swift package tests, the strict project guardrail wrapper (strict validator + `swift test --parallel` 111/0 + `xcodebuild -list`) exited 0, `git diff --check` clean; the full iOS-simulator build was not re-run this session (2026-11-06; [verification.md](verification.md)). The next engineering action is Package 06 (native experience and export). The additional embedding requirement remains removed, not deferred. Design rationale: [design/ash-derived-glyph.md](design/ash-derived-glyph.md).

**Authorization (2026-11-03):** The owner's decision `SIGIL-DEC-2026-11-03-AUTONOMOUS-SEQUENCE` ([record](decisions/2026-11-03-autonomous-phase-sequence.md)) authorizes the remaining development sequence: in-scope remediation, implementation, testing, debugging, documentation, and version alignment, executed as the seven-package work order supplied in the external instruction bundle (01 remediation and source alignment through 07 integration and owner handover), with per-phase local commits and source publication to `flynn33/Sigil` under the owner identity, without model or tool attribution. Development builds and host/simulator checks are part of the sequence; candidate/distribution builds, signing, notarization, releases, deployment, and physical-device qualification remain the owner's work.

**Historical (2026-10-10 through 2026-11-02 assignments):** The documentation synchronization and the read-only ASH trace were bounded assignments. Their boundary text — updating planning, current documentation, and narrowly affected descriptive metadata without implementing the mathematical pipeline, and retaining `PA.0.1.0` for a documentation-only synchronization unless an actually adopted project rule required otherwise — describes those assignments and no longer states the current execution boundary. Product version, Apple build metadata, schema versions, planning revision, and playbook binding remain distinct identities.

After documentation synchronization, the approved ASH-to-Sigil source trace was completed on 2026-11-02; its results and unresolved decisions are recorded in [docs/ash-trace/](ash-trace/source-to-output-map.md) and [docs/handoffs/ash-trace.md](handoffs/ash-trace.md). The topics recorded as owner decisions in those findings are resolved in the Package 01 planning pass as documented product-owned design decisions under the 2026-11-03 decision; any genuine remaining upstream source conflict stays isolated and visible rather than treated as a workaround.

## Source continuity

The original context lock and approval/amendment records are supplied in the project context. Their relevant requirements are reconciled here, not represented as a newly recovered authoritative Project Record.

The owner has designated this repository (flynn33/Sigil) as the authoritative Project Record: the planning documents, decisions, evidence records, and handoffs in this repository are the project record. External execution state (session checkpoints, raw logs, instruction-package working state) remains outside the repository and does not replace it.

The development-policy binding in effect during the 2026-11-02 ASH-TRACE execution was Raven Forge Development 0.8.0. The instruction package's intake/reference pin is commit `5df71a97a7a3500d31a5ab0b07dd9f987c00be01` (0.8.0). These are distinct identities: the intake pin is preserved as the package reference, is not claimed as a historical repository adoption, and is not treated as an automatic upgrade.
