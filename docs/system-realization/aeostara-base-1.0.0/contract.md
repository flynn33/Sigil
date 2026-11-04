# System Realization Contract — Aeostara (Platform-Agnostic Base Design)

Machine-readable companion: [contract.json](contract.json). The Markdown and JSON describe the same source pin, dependency allowlist, prohibitions, product-owned realization, authority relationships, governance treatment, and review state.

## 1. Identity and authority

| Field | Value |
|---|---|
| Product | Sigil |
| Target product repository and baseline commit | `flynn33/Sigil` @ `bc277ea05239398d58e70b76ad318de2765148d3` |
| Selected system | Aeostara — Platform-Agnostic Base Design |
| Authority-container role | Base design (platform-neutral semantic specification and downstream obligations) |
| Source repository | `https://github.com/flynn33/aeostara` |
| Source branch/tag and resolved commit | `main` @ `a1852cc5f9e094a8b7f7135479e3bf24df8c1513` (2026-09-04) |
| System version | `1.0.0` (both the profile pin and the product-record pin postdate the `[1.0.0] - 2026-06-22` base closeout; the interval between them contains CI workflow and license/community changes only) |
| Pinned realization profile ID and hash | `rfd.aeostara.base.1.0.0` (`aeostara-base-1.0.0.json`, SHA-256 recorded in validator reports) |
| Linked contract-set ID | `sigil-system-realization-set-2026-11-03` |
| Other linked contract IDs and roles | `SIGIL-SR-2026-11-03-FORSETTI-APPLE-015` (native runtime); `SIGIL-SR-2026-11-03-APS-CANONICAL-RC3` (canonical specification) |
| Upstream authority and precedence | ASH Pattern System is the fixed upstream semantic authority (Aeostara's own `ASH_BASELINE_REFERENCE.md` pins `flynn33/ASH-Pattern-System` main at `e123f5d7fdbb381179971f721a3292c31eb1cbc2`). Conflict rule: ASH wins, Aeostara changes. Platform repositories (and Sigil-facing behavior) implement, never redefine. |
| Machine-readable contract path/revision | `docs/system-realization/aeostara-base-1.0.0/contract.json`, revision `0.1.0` |
| Controlling documents | Profile `aeostara-base-1.0.0.json`; pinned-source readings (see §3); Raven Forge System Realization Enforcement |
| Contract revision | `0.1.0` |
| Prepared/reviewed by and date | Prepared by the Sigil project execution record, 2026-11-03; independent pre-implementation review (model-based, separate route) 2026-11-03 — see §10 |

**Pin-divergence note.** The product evidence record pins the base at `774b981ef2267a41c1b1a59497b2b0746a86f32b` (2026-06-22 closeout commit). The profile pins `a1852cc5f9e094a8b7f7135479e3bf24df8c1513` (2026-09-04). Git history verified `774b981` is an ancestor of `a1852cc5` and the interval is CI/license/community changes only, both after the v1.0.0 closeout, so the semantic baseline is identical. The contract binds to the profile pin per the pinned profile; the product-record pin is recorded, and neither is moved.

## 2. Teach-back

1. **What this container does for Sigil.** It is the health and validation authority pin for Aeostara-facing behavior: the mandatory platform-neutral lifecycle (observe, normalize, project JSON/configuration state, diagnose, classify, determine recoverability, generate recovery plan, evaluate policy gate, prepare backup, execute approved plan, verify, rollback/fallback/containment/safe-halt, emit diagnostic and audit chain), the downstream obligations (pin the base version, map interfaces, implement contracts without field-meaning changes, run fixture vectors, conforming diagnostics and audit events, documented deviations), and the fail-closed health-decision posture Sigil's gateway records today.
2. **What it does not do.** Not a runtime dependency; authorizes no package or native target import; does not own native iOS implementation (that is `flynn33/Aeostara-Mac-iOS` platform/ios); does not define Sigil's identity pipeline or glyph mathematics; cannot modify ASH. Generic JSON diffing is not semantic truth; recovery is never derived from CRUD repair.
3. **Upstream/downstream.** Upstream: ASH (wins conflicts). Downstream: the platform repositories (Windows, macOS, iOS) — and, for Sigil, the product-owned integration surface that records Aeostara authority and makes fail-closed decisions.
4. **What must be built in the product.** Product-owned integration module and service (exist: `RFSigilAeostaraIntegration`), guardrails preserving platform separation and baseline pinning (exist: `tools/sigil_guardrails`), conformance documentation (exists: `evidence/phase1/source-authority-evidence.md`, `docs/ash-trace`). Future lifecycle work must be product-owned code conformant to the base's semantics.
5. **What may be consumed as runtime.** Nothing. `allowedRuntimeProducts` and `allowedDevelopmentTools` are empty.
6. **What remains external.** All of `flynn33/aeostara` and all of `flynn33/Aeostara-Mac-iOS`.
7. **Templates/examples/fixtures.** `implementation_handoff` and `templates/platform_repo` define downstream obligations and shape; fixtures and schema examples are verification material only.
8. **Forsetti Agentic Edition.** Not selected (see §9).
9. **Conformance demonstration.** Structural: validator modes against this contract. Semantic: recorded baseline/provenance evidence asserted by tests; guardrails enforce platform separation and baseline pinning. Behavioral: fail-closed health-decision tests. Native: `swift test` and Xcode routes via `scripts/verify-sigil-guardrails.sh`.

## 3. Source-role disposition

| Source | Role | Meaning for Sigil | Permitted treatment | Prohibited treatment |
|---|---|---|---|---|
| `specs/**` (ash_baseline, contracts, algorithms, interfaces, architecture, acceptance) | specification | Platform-neutral base semantics: ASH bindings, lifecycle boundary contracts, diagnosis-first JSON-pointer algorithms, adapter/orchestration boundaries, authority hierarchy, completion gates | Read at the pinned commit; cite; implement product-owned conformant services | Copying spec files into the product tree; redefining base semantics in product code |
| `conformance/**` | test | The base's own module mapping, invariant coverage, diagnostics, boundary, deviation, and judgment artifacts | Read to understand the base's conformance evidence shape | Treat as Sigil conformance evidence |
| `fixtures/conformance/**`, `fixtures/schema_examples/**` | test | Expected-output vectors and valid schema instances | Verification material when Sigil implements lifecycle behavior | Shipping fixture material in runtime targets |
| `ci/**` | tool | Schema, fixture, traceability, JSON semantics, diagnostic-chain, recovery, handoff, completion validators | Read for the validation approach; consult gate definitions | Adopting as product tooling |
| `implementation_handoff/**`, `templates/platform_repo/**` | template | Downstream handoff requirements and platform-repository templates (including branch profiles) | Keep downstream obligations explicit and documented | Treat as base semantics or product configuration |
| `branch_profiles/**`, repository status and closeout documents | history | Platform branch profile material and repository-separation history | Cite as historical provenance of the v1.0.0 separation | Treat as active base-design authority |
| `LICENSE`, `CHANGELOG.md` | history | Apache-2.0 license and release history | Cite license and version identity | Treat as implementation authority |

All seven profile-required readings (`README.md`, `BASE_DESIGN_COMPLETION.md`, `ASH_BASELINE_REFERENCE.md`, `specs/architecture/repository_role_contract.md`, `specs/architecture/downstream_platform_repository_contract.md`, `specs/architecture/platform_implementation_boundary.md`, `specs/architecture/base_to_platform_versioning.md`) were read in full at the pinned commit on 2026-11-03; extraction and read evidence is recorded in the JSON `sourceCoverage` records and in the external evidence root.

## 4. Dependency allowlist

`none`. The base profile allows no runtime products or development tools, and Sigil consumes no Aeostara code.

## 5. Prohibited acquisition

| Prohibited material | Reason | Detection/review method |
|---|---|---|
| Whole `flynn33/aeostara` repository (copies, submodules, vendor trees under `Vendor/`, `ThirdParty/`, `External/`, `vendor/`) | Base-design authority, not a dependency unit | Tree inspection; validator `repositoryNames`/`pathPatterns` checks (preflight against the actual checkout) |
| Dependency token `github.com/flynn33/aeostara` | Prevents accidental acquisition via dependency declarations | Validator `dependencyTokens` scan of dependency declarations (RFD-SR-106) |
| Fingerprint group 1: `specs/contracts/**` + `specs/algorithms/**` + `specs/architecture/**` | Core base-design material must never appear in the product tree | Validator fingerprint group (RFD-SR-104) |
| Fingerprint group 2: `fixtures/conformance/**` + `implementation_handoff/**` + `templates/platform_repo/**` + `ci/**` | Supporting base material must never appear in the product tree | Validator fingerprint group (RFD-SR-104) |

All values required by the pinned profile are present in the contract (verified programmatically against `aeostara-base-1.0.0.json`). The product evidence record references the platform repository `flynn33/Aeostara-Mac-iOS` by branch/commit as a citation; that repository is a separate authority container (not selected here — see set overview) and does not appear in dependency files (verified in preflight).

## 6. Product-local realization map

| Product-owned target | Kind | Responsibility | Source basis | Required transformation | Ownership/lifecycle | Verification |
|---|---|---|---|---|---|---|
| `Sources/RFSigilAeostaraIntegration/**` | module | Product-owned Aeostara integration module: recorded baseline and provenance evidence, fail-closed health decisions, `SigilAeostaraIntegrationModule` wrapper. Recorded-evidence and decision logic in product code, not a live dependency | Downstream platform repository contract (preserve Aeostara authority, document deviations, prohibited downstream behaviors) | App-owned gateway and module; Package 01 R-06 keeps dashboard wording consistent with the gateway's actual nature | Product-owned | Integration gateway tests; registration tests |
| `Sources/RFSigilAeostaraIntegration/SigilAeostaraIntegrationGateway.swift` | service | The product-owned service implementing Sigil's Aeostara-facing behavior: baseline pin evidence (v1.0.0, product-record commit `774b981…`), platform/ios observations, migration provenance (archive/import tags at `0c931a7…`), fail-closed `healthDecision` (mutation disallowed, backup required, verification required, operator review required) | Platform implementation boundary (base defines semantics, platform implements mechanics); downstream obligations | Product-owned service semantics | Product-owned | Integration gateway tests (decision fields asserted) |
| `tools/sigil_guardrails/**` | guardrail | Preserves the Aeostara authority boundary: distinct-product treatment, platform separation, baseline-pinned usage, attribution integrity | Repository role contract and downstream contract | Product-owned guardrail policy + validator | Product-owned | `scripts/verify-sigil-guardrails.sh`; guard unit tests |
| `evidence/phase1/source-authority-evidence.md` | documentation | Product conformance documentation for the Aeostara authority: observed base pin, platform provenance, products, migration tags | Base-to-platform versioning rule (downstream must explicitly pin the base version or commit) | Evidence-record style, not dependency | Product-owned | Cross-checked against clone history 2026-11-03; validator path match |
| `docs/system-realization/aeostara-base-1.0.0/contract.md` | documentation | Human-readable companion contract | Raven Forge contract template | — | Product-owned | Validator contract mode; independent review evidence |

The profile-required kinds (`module`, `service`, `guardrail`, `documentation`) are all represented.

## 7. Authority, composition, and boundaries

- Precedence: ASH > Aeostara base > platform implementation. Sigil-facing behavior implements and records; it never redefines base or ASH semantics.
- Composition: no runtime composition role for this container; product-owned services model Aeostara-facing behavior.
- Dependency direction: no dependency on the base repository exists or may be added.
- Persistence: local-only; backup and audit artifacts, when implemented, stay under product-owned services.
- Semantic invariants: lifecycle ordering (diagnosis before plan, policy gate before execution, backup before mutation, verification after execution); fail-closed health decisions; no CRUD-derived recovery; no silent bypass of fallback/containment/halt; platform separation (macOS and iOS lines never merged).
- Exclusions: the platform repository (`flynn33/Aeostara-Mac-iOS`) is a separate container, not selected by this contract; its observations remain product evidence.

## 8. Template, example, fixture, and corpus transformation

| Source material | Why consulted | Product-owned output | Required adaptation | Sample identity to remove | Verification |
|---|---|---|---|---|---|
| `implementation_handoff/**`, `templates/platform_repo/**` | Downstream obligations and platform-repo shape | `evidence/phase1/source-authority-evidence.md` and `docs/ash-trace/**` (explicit pins, provenance by commit, deviations documented as product policy) | Evidence-record style mapping of the eight downstream obligations | None (no sample data used) | Validator RFD-SR-111 output presence (delivery); recorded pins cross-checked against clone history |

## 9. Governance and conformance plan

### Authority relationships

| Concern | Value |
|---|---|
| Canonical/base-design authority | This repository (pinned `a1852cc5`, v1.0.0) |
| Native implementation authority | Not selected (no Aeostara package dependency in the product; the platform/ios branch is a separate container) |
| Precedence/conflict rule | ASH wins, Aeostara changes; base semantics are not redefined downstream |
| Required semantic/conformance validator | Realization validator + product guardrails (platform separation, baseline pinning) |
| Required fixtures/corpora | Base fixture vectors as verification basis when lifecycle work is implemented |
| Deviation/caveat treatment | Pin divergence (product record `774b981` vs profile `a1852cc5`) recorded with git evidence; neither pin moved |
| Linked contract IDs | `SIGIL-SR-2026-11-03-FORSETTI-APPLE-015`, `SIGIL-SR-2026-11-03-APS-CANONICAL-RC3` |

### Forsetti Agentic Edition governance

Not selected (see set overview). Rationale recorded in the JSON companion.

## 10. Pre-implementation review

All checklist items in the JSON companion were verified during review. Key confirmations: exactly one authority container at one immutable revision; profile binding coherent (repository/commit/version all match the profile; `product.baselineCommit` is a distinct product-repository field by schema design); all seven required readings performed and evidenced; teach-back specific with no placeholders; dependency allowlist correctly empty; prohibitions at least as strict as the profile (repository names, vendor path patterns, URL token, both fingerprint groups); realization map names concrete existing product outputs covering the required kinds including the product-owned service; governance not-applicable with rationale; pin divergence recorded honestly with git evidence.

**Review result:** Accepted for issuance
**Reviewer and date:** Independent model-based pre-implementation review (separate route from preparation; LM Studio local service, model `qwen/qwen3-coder-30b`; not human acceptance), 2026-11-03
**Evidence/reference:** Round 1 review record (`…/Sigil-Autonomous-Phase-Packages-v1.0-evidence/phase01/reviews/review-aeostara.json`); round 2 `VERDICT: accepted, ISSUES: none` (`review-aeostara-round2.json`, full prompt/response preserved). Round 1 raised three issues: (1) a clarity request for the product-owned service label — addressed by strengthening the service entry wording; (2) a false claim that the `github.com/flynn33/aeostara` dependency token is absent (it is present in `prohibitedAcquisition`); (3) a request to confirm `docs/ash-trace/**` exists (verified: four files, committed in PR #10 at `bc277ea`).
**Contract report:** `phase01/validator/contract-aeostara.json` (+ round 2 and final: pass, zero findings)
**Preflight report:** `phase01/validator/preflight-aeostara.json` (pass, zero findings; 97 files scanned, all realization paths matched, no prohibited tokens in dependency files)

## 11. Delivery conformance review

| Review | Result | Evidence | Limitations/corrections |
|---|---|---|---|
| Source understanding and realization | Not reviewed | — | Completed at delivery |
| Instruction accuracy | Not reviewed | — | Completed at delivery |
| Instruction adherence | Not reviewed | — | Completed at delivery |
| Implementation conformance | Not reviewed | — | Completed at delivery |
| Dependency/import prohibition | Not reviewed | — | Preflight already verifies against the live checkout |
| Governance conformance | Not applicable | Governance not selected (see §9) | Re-assess if agentic edition governance is adopted |
