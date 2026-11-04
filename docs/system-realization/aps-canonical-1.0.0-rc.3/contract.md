# System Realization Contract — ASH Pattern System (Canonical Specification)

Machine-readable companion: [contract.json](contract.json). The Markdown and JSON describe the same source pin, dependency allowlist, prohibitions, product-owned realization, authority relationships, governance treatment, and review state.

## 1. Identity and authority

| Field | Value |
|---|---|
| Product | Sigil |
| Target product repository and baseline commit | `flynn33/Sigil` @ `bc277ea05239398d58e70b76ad318de2765148d3` |
| Selected system | ASH Pattern System — Canonical Specification |
| Authority-container role | Canonical specification (semantic authority) |
| Source repository | `https://github.com/flynn33/ASH-Pattern-System` |
| Source branch/tag and resolved commit | `main` @ `50d7e5ab88932a4a967ffc2c83bd18fae45b73c8` (2026-10-11, "Close diagnostic schema and reference precedence gaps for 1.0.0-rc.3") |
| System version | `1.0.0-rc.3` (verified: `VERSION` and `product-manifest.json` at the pinned commit) |
| Pinned realization profile ID and hash | `rfd.aps.canonical.1.0.0-rc.3` (`aps-canonical-1.0.0-rc.3.json`, SHA-256 recorded in validator reports) |
| Linked contract-set ID | `sigil-system-realization-set-2026-11-03` |
| Other linked contract IDs and roles | `SIGIL-SR-2026-11-03-FORSETTI-APPLE-015` (native runtime); `SIGIL-SR-2026-11-03-AEOSTARA-BASE-100` (base design) |
| Upstream authority and precedence | The canonical repository is the source of truth for ASH Pattern System semantics: "if an implementation disagrees with this repository, the specification here wins." The ASH-Model repository (cosmological mathematics) is upstream of APS in the product's recorded layering; its 8+1 versus full-9D source tension remains recorded in `docs/ash-trace` as an unresolved owner-visible item, not a contract input. |
| Machine-readable contract path/revision | `docs/system-realization/aps-canonical-1.0.0-rc.3/contract.json`, revision `0.1.0` |
| Controlling documents | Profile `aps-canonical-1.0.0-rc.3.json`; pinned-source readings (see §3); Raven Forge System Realization Enforcement |
| Contract revision | `0.1.0` |
| Prepared/reviewed by and date | Prepared by the Sigil project execution record, 2026-11-03; independent pre-implementation review (model-based, separate route) 2026-11-03 — see §10 |

**Selection note.** This is a new deliberate selection of the canonical authority at the profile pin. The Phase 1 product record (`evidence/phase1/source-authority-evidence.md`) read the APS Mac-iOS repository surface and recorded CONFORMANT WITH CAVEATS, but contains no canonical-repository pin. No historical canonical-repo adoption is claimed.

## 2. Teach-back

1. **What this container does for Sigil.** It is the semantic authority for everything ASH: the full `F2^9` state space (512 states), the fixed 16-member `[9,4,4]` doubly-even codeword set with 32 orbits, XOR-by-codeword transitions, realm and orbit identity, the seven system-state classes, recovery/fallback/containment/`SAFE_HALT` semantics, the fifteen-field diagnostic schema with nine-field semantic identity, and the rule-ID taxonomy. Sigil's visible-glyph engine, status gateways, guardrails, and diagnostics must preserve these invariants wherever they model ASH behavior.
2. **What it does not do.** No language, OS, runtime, build system, package, platform implementation, or emitted artifact tree; not a runtime dependency of Sigil; does not define numerology input policy, profile-to-state mapping, or personal identity semantics (product-owned decisions).
3. **Upstream/downstream.** Upstream: the ASH-Model cosmological mathematics (recorded relationship, archive-hash identity). Downstream: Sigil's product-owned ASH modeling and conformance documentation; the APS Mac-iOS repository is a separate native-edition container, not selected here (see set overview).
4. **What must be built in the product.** Product-owned integration module (exists: `RFSigilAPSIntegration`), product invariant guardrails (exist: `tools/sigil_guardrails`), conformance documentation (exists: `docs/ash-trace`), and — in later packages — any ASH state machine as product-owned code conformant to the pinned rc.3 specification.
5. **What may be consumed as runtime.** Nothing. `allowedRuntimeProducts` is empty; Sigil consumes no APS code.
6. **What remains external.** The entire repository: specs, canonical-data, conformance corpus, schemas, examples, handoff-templates, tools, governance, completion evidence.
7. **Templates/examples/fixtures.** Handoff templates shape the conformance documentation; examples and the conformance corpus are verification material only and never enter runtime targets.
8. **Forsetti Agentic Edition.** Not selected (see §9).
9. **Conformance demonstration.** Structural: validator modes against this contract. Semantic: trace ledger row-by-row source basis; guardrails enforce the 16-member codeword literal set and rule-ID taxonomy in product code. Behavioral: product tests. Native: `swift test` and Xcode routes via `scripts/verify-sigil-guardrails.sh`.

## 3. Source-role disposition

| Source | Role | Meaning for Sigil | Permitted treatment | Prohibited treatment |
|---|---|---|---|---|
| `specs/core/**`, `specs/algorithms/**`, `specs/registries/**`, `specs/interfaces/**`, `specs/verification/**` | specification | Canonical semantics (state, codewords, transitions, classification, recoverability, containment/safe failure, diagnostic schema, taxonomy, invariants, acceptance) | Read at pinned commit; cite; implement product-owned conformant code | Copying spec files into the product tree; treating rc.1/rc.2 clauses superseded by the rc.3 reconciliation as binding |
| `canonical-data/**` | specification | Versioned canonical data (codewords, realms, orbits, transitions, fallback definitions, rule registry) | Read and cite by pinned commit and artifact identity; expected-value basis for tests | Vendoring into the product; treating a single artifact hash as the whole baseline |
| `conformance/**` | test | Versioned implementation-neutral conformance corpus | Verification material for product conformance tests | Shipping corpus material in runtime targets |
| `schemas/**` | specification | Versioned JSON Schemas (diagnostics, safety records, product manifest) | Read; validate product serialization against them | Vendoring as product configuration |
| `handoff-templates/**` | template | Downstream delivery and conformance-evidence requirements | Structure product conformance documentation | Treat as canonical semantics |
| `examples/**` | example | Valid/invalid schema examples | Verify serialization understanding | Copying example records into product runtime data |
| `tools/product/**` | tool | Canonical product generation/validation tooling | Read for artifact-generation semantics | Adopting as product tooling |
| `governance/**`, `.github/**` | governance | Upstream repository rules, protected handoff policy, math-change notes | Read for math-change and protected-surface rules | Importing into product runtime or configuration |
| `completion-evidence/**` | history | Completion evidence of the canonical repository itself | Cite as historical evidence of the pinned release state | Treat as Sigil conformance evidence |

All nine profile-required readings (`README.md`, `PUBLIC-SPECIFICATION-API.md`, `docs/00-repository-purpose.md`, `specs/verification/implementation-acceptance.md`, `handoff-templates/common-downstream-handoff-requirements.md`, `COMPATIBILITY.md`, `MIGRATION-GUIDE.md`, `specs/interfaces/diagnostic-schema.md`, `specs/algorithms/containment-safe-failure-semantics.pseudo.md`) were read in full at the pinned commit on 2026-11-03; extraction and read evidence is recorded in the JSON `sourceCoverage` records and in the external evidence root.

## 4. Dependency allowlist

`none`. The canonical repository is a semantic specification authority; the profile allows no runtime products or development tools, and Sigil consumes no APS code today.

## 5. Prohibited acquisition

| Prohibited material | Reason | Detection/review method |
|---|---|---|
| Whole `ASH-Pattern-System` repository (copies, submodules, vendor trees under `ASH-Pattern-System/`, `Vendor/`, `ThirdParty/`, `External/`) | Specification authority, not a dependency unit | Tree inspection; validator `repositoryNames`/`pathPatterns` checks (preflight against the actual checkout) |
| Repository URL/clone tokens (21 URL-variant dependency tokens from the profile) | Prevents accidental acquisition via dependency declarations | Validator `dependencyTokens` scan of dependency declarations (RFD-SR-106) |
| Fingerprint group 1: `canonical-data/**` + `conformance/**` + `specs/core/**` + `specs/algorithms/**` | Core canonical material must never appear in the product tree | Validator fingerprint group (RFD-SR-104) |
| Fingerprint group 2: `schemas/**` + `handoff-templates/**` + `tools/product/**` | Supporting canonical material must never appear in the product tree | Validator fingerprint group (RFD-SR-104) |

All values required by the pinned profile are present in the contract (verified programmatically against `aps-canonical-1.0.0-rc.3.json`). Product documentation cites the repository by pinned commit as a reference; citations are not dependency declarations and do not appear in dependency files (verified in preflight).

## 6. Product-local realization map

| Product-owned target | Kind | Responsibility | Source basis | Required transformation | Ownership/lifecycle | Verification |
|---|---|---|---|---|---|---|
| `Sources/RFSigilAPSIntegration/**` | module | Product-owned APS integration module: recorded source-coverage status, conformance judgment, `SigilAPSIntegrationModule`. Status is a recorded-evidence provider, not a live resolver | Common downstream handoff requirements (module mapping, verification inputs, diagnostics integration) | App-owned gateway and module; Package 01 R-06 corrects dashboard wording that overstates the gateway capability | Product-owned | Integration gateway tests; registration tests |
| `tools/sigil_guardrails/**` | guardrail | Enforces the canonical 16-member codeword literal set, the diagnostic rule-ID taxonomy, attribution and ASH-misuse marker absence, and Forsetti internal copy-path absence across the product tree | Implementation-acceptance non-waivable requirements (full `F2^9` processing, exact 16-codeword set, diagnostic schema and taxonomy conformance) | Product-owned guardrail policy + validator | Product-owned | `scripts/verify-sigil-guardrails.sh`; 17 guard unit tests |
| `docs/ash-trace/**` | documentation | Conformance documentation: source-to-output map, trace ledger, findings and smallest-change proposal, verification cases, handoff record | Proof-of-conformance deliverables per the handoff requirements (module mapping, verification report, diagnostics conformance, materialization boundary, deviation log, acceptance judgment) | Map the six deliverables onto existing doc surfaces; no runtime artifacts | Product-owned | `validate_trace.py` structural check; R-01..R-04 corrections with fresh evidence |
| `docs/system-realization/aps-canonical-1.0.0-rc.3/contract.md` | documentation | Human-readable companion contract | Raven Forge contract template | — | Product-owned | Validator contract mode; independent review evidence |

The profile-required kinds (`module`, `guardrail`, `documentation`) are all represented.

## 7. Authority, composition, and boundaries

- Precedence: this canonical specification is the semantic authority for ASH behavior in Sigil. The Aeostara base conforms to ASH and defers to it; the Forsetti runtime governs mechanics only. If product code and this specification disagree, the specification wins and the product is corrected.
- Composition: no runtime composition role for this container; Sigil models ASH semantics in product-owned code.
- Dependency direction: no dependency on the canonical repository exists or may be added.
- Persistence: local-only; no APS-owned persistence in Sigil.
- Semantic invariants and conformance obligations: full `F2^9` state space (no projection as canonical), exact 16-member codeword set (no invented or extended codewords), XOR-by-codeword as canonical transformation, materialization boundary (planner/emitter separation), non-waivable diagnostic schema and taxonomy conformance, `SAFE_HALT` terminal finality, monotonic escalation, no silent healing, no silent containment or halt.
- Exclusions: rc.1/rc.2 superseded clauses (as named by the rc.3 reconciliation) are not binding; the canonical repo's own governance material governs the upstream repository only.

## 8. Template, example, fixture, and corpus transformation

| Source material | Why consulted | Product-owned output | Required adaptation | Sample identity to remove | Verification |
|---|---|---|---|---|---|
| `handoff-templates/common-downstream-handoff-requirements.md` | Shape of downstream conformance evidence | `docs/ash-trace/**` (ledger as module mapping plus source basis; verification cases as verification evidence; findings as deviation log; acceptance judgment in the handoff record) | Map the six deliverables onto existing doc surfaces | None (no sample data used) | Validator RFD-SR-111 output presence (delivery); `validate_trace.py` |
| `conformance/**`, `examples/**` | Expected results for serialization and behavior | Verification material for future product conformance tests (Package 05) | None yet — no runtime output produced in Phase 01 | None | Deferred to the ASH glyph workstream |

## 9. Governance and conformance plan

### Authority relationships

| Concern | Value |
|---|---|
| Canonical/base-design authority | This repository (pinned rc.3 commit) |
| Native implementation authority | Not selected (no APS package dependency in the product) |
| Precedence/conflict rule | Specification wins over implementation; rc.3 reconciliation wins over named superseded rc.1/rc.2 clauses |
| Required semantic/conformance validator | Realization validator + product guardrails (codeword literals, rule-ID taxonomy) + trace ledger structural check |
| Required fixtures/corpora | Canonical conformance corpus as verification basis when the ASH state machine is implemented (Package 05) |
| Deviation/caveat treatment | Phase 1 recorded CONFORMANT WITH CAVEATS (fallback registry wording); caveats named, not silently waived |
| Linked contract IDs | `SIGIL-SR-2026-11-03-FORSETTI-APPLE-015`, `SIGIL-SR-2026-11-03-AEOSTARA-BASE-100` |

### Forsetti Agentic Edition governance

Not selected (see set overview). Rationale recorded in the JSON companion.

## 10. Pre-implementation review

All checklist items in the JSON companion were verified during review. Key confirmations: exactly one authority container at one immutable revision; profile binding coherent (repository/commit/version all match the profile; `product.baselineCommit` is a distinct product-repository field by schema design); all nine required readings performed and evidenced; teach-back specific with no placeholders; dependency allowlist correctly empty; prohibitions at least as strict as the profile (21 URL-variant tokens plus both fingerprint groups); realization map names concrete existing product outputs covering the required kinds; governance not-applicable with rationale; pin selection is a new deliberate selection with no false historical-adoption claim.

**Review result:** Accepted for issuance
**Reviewer and date:** Independent model-based pre-implementation review (separate route from preparation; LM Studio local service, model `qwen/qwen3-coder-30b`; not human acceptance), 2026-11-03
**Evidence/reference:** Round 1 review record (`…/Sigil-Autonomous-Phase-Packages-v1.0-evidence/phase01/reviews/review-aps.json`); round 2 `VERDICT: accepted, ISSUES: none` (`review-aps-round2.json`, full prompt/response preserved). Round 1 raised three issues: (1) a misunderstanding of `product.baselineCommit` versus `system.sourceCommit` (distinct fields by schema design — addressed with an explicit field note in the contract), (2) and (3) false claims that `Sources/RFSigilAPSIntegration` does not exist as a separate directory (verified false — the directory and `SigilAPSIntegrationGateway.swift` exist in the checkout; `RFSigilForsettiModules` is a separate catalog target).
**Contract report:** `phase01/validator/contract-aps.json` (+ round 2 and final: pass, zero findings)
**Preflight report:** `phase01/validator/preflight-aps.json` (pass, zero findings; 97 files scanned, all realization paths matched, no prohibited tokens in dependency files)

## 11. Delivery conformance review

| Review | Result | Evidence | Limitations/corrections |
|---|---|---|---|
| Source understanding and realization | Not reviewed | — | Completed at delivery |
| Instruction accuracy | Not reviewed | — | Completed at delivery |
| Instruction adherence | Not reviewed | — | Completed at delivery |
| Implementation conformance | Not reviewed | — | Completed at delivery |
| Dependency/import prohibition | Not reviewed | — | Preflight already verifies against the live checkout |
| Governance conformance | Not applicable | Governance not selected (see §9) | Re-assess if agentic edition governance is adopted |
