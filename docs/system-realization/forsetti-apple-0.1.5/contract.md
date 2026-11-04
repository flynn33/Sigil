# System Realization Contract — Forsetti Framework (Apple)

Machine-readable companion: [contract.json](contract.json). The Markdown and JSON describe the same source pin, dependency allowlist, prohibitions, product-owned realization, authority relationships, governance treatment, and review state.

## 1. Identity and authority

| Field | Value |
|---|---|
| Product | Sigil |
| Target product repository and baseline commit | `flynn33/Sigil` @ `bc277ea05239398d58e70b76ad318de2765148d3` |
| Selected system | Forsetti Framework — Apple |
| Authority-container role | Native runtime (sealed modular runtime framework) |
| Source repository | `https://github.com/flynn33/Forsetti-Framework-Mac-iOS` |
| Source branch/tag and resolved commit | `main` @ `0097a4227789ed7d39e1491ac0aede2d9ea4f6ea` (2026-08-16) |
| System version | `0.1.5` (verified: `version.txt` at the pinned commit) |
| Pinned realization profile ID and hash | `rfd.forsetti.apple.0.1.5` (`forsetti-apple-0.1.5.json`, SHA-256 recorded in validator reports) |
| Linked contract-set ID | `sigil-system-realization-set-2026-11-03` |
| Other linked contract IDs and roles | `SIGIL-SR-2026-11-03-APS-CANONICAL-RC3` (canonical specification); `SIGIL-SR-2026-11-03-AEOSTARA-BASE-100` (base design) |
| Upstream authority and precedence | Forsetti is a consumer-facing runtime; it has no upstream semantic authority over Sigil product semantics. Product semantics (ASH-derived) are governed by the APS canonical contract. |
| Machine-readable contract path/revision | `docs/system-realization/forsetti-apple-0.1.5/contract.json`, revision `0.1.0` |
| Controlling documents | Profile `forsetti-apple-0.1.5.json`; pinned-source readings (see §3); Raven Forge System Realization Enforcement |
| Contract revision | `0.1.0` |
| Prepared/reviewed by and date | Prepared by the Sigil project execution record, 2026-11-03; independent pre-implementation review (model-based, separate route) 2026-11-03 — see §10 |

## 2. Teach-back

1. **What this container does for Sigil.** It is the sealed modular runtime: `ForsettiCore` provides the module registry, manifest validation (schema/template 1.1), capability-scoped service lookup, entitlement-aware activation, and runtime composition. Sigil is a Pattern B multi-module single application — exactly one UI module (`RFSigilUIModule`, the Phase 1 dashboard) plus seven app-owned service modules — and `SigilRuntimeAssembly` composes the runtime and feeds the dashboard through app-owned status providers.
2. **What it does not do.** It does not provide ASH Pattern System semantics, Aeostara base semantics, numerology or glyph mathematics, personal-data processing, or any backend. Sigil never extends Forsetti internals for product behavior.
3. **Upstream/downstream.** No upstream semantic authority applies to this container. It governs the product's module registration, manifest shape, capability declarations, and runtime composition only.
4. **What must be built in the product.** Product-owned modules (already present as `RFSigil*` targets), product-owned manifests (in-code `ModuleManifest` objects in `SigilModuleCatalog.swift`), the product registry installer, and the product bootstrap/composition (`SigilRuntimeAssembly`, `SigilRuntimeFactory`).
5. **What may be consumed as public runtime.** `ForsettiCore` only (live product pin `43eef7a739f3b78253c64aa4b070521ab5b1f43c`, 0.1.4). `ForsettiPlatform` and `ForsettiHostTemplate` are allowed products under the profile but are not consumed and are not allowlist entries here.
6. **What remains external.** Everything in the Forsetti repository: `Sources/ForsettiCore`, `Sources/ForsettiPlatform`, `Sources/ForsettiHostTemplate`, the internal `ForsettiModulesExample` target, templates, scripts, and workflows.
7. **Templates/examples/fixtures.** The Xcode templates informed the app-owned scaffolding shape (bootstrap file, registry file, module class plus view, manifest conventions); `ForsettiModulesExample` is evaluation-only and never consumed. No template or sample code is copied; sample identity tokens are prohibited in product files (see §8).
8. **Forsetti Agentic Edition.** Not selected (see §9).
9. **Conformance demonstration.** Structural: validator contract/preflight/delivery modes against this contract. Semantic: manifest/descriptor alignment asserted by registration tests. Behavioral: runtime assembly and dashboard tests. Native: `swift test` plus Xcode build routes via `scripts/verify-sigil-guardrails.sh`.

## 3. Source-role disposition

| Source | Role | Meaning for Sigil | Permitted treatment | Prohibited treatment |
|---|---|---|---|---|
| `Sources/ForsettiCore`, `Sources/ForsettiPlatform`, `Sources/ForsettiHostTemplate` | public runtime | Sealed modular runtime; Sigil consumes `ForsettiCore` only | SwiftPM product dependency at a pinned revision; public API only | Copying, vendoring, forking, patching, importing internals |
| `ForsettiModulesExample` target | example | Evaluation reference for module contract behavior | Read upstream for understanding | Use as a product dependency or sample identity |
| `XcodeTemplates/**` | template | Defines the app-owned scaffolding shape and ownership split | Consult as scaffold reference | Copying generated code or placeholder tokens into product sources |
| `README.md`, `IMPLEMENTATION_GUIDE.md`, `MODULE_BOUNDARY_RULES.md`, `xcode-template-guide.md` | specification | Canonical integration and boundary guidance | Read at the pinned revision; cite in conformance documentation | Treating prose as license to bypass module boundaries |
| `Scripts/**`, `.github/**`, lint configuration | tool | Upstream guardrail and release tooling | Consult for the guardrail approach Sigil replicates locally | Adopting upstream tooling as Sigil configuration |
| `LICENSE`, `CHANGELOG.md`, release metadata | history | Apache-2.0 license and release history | Cite license and version identity | Treat as implementation authority |

All four profile-required readings (`README.md`, `IMPLEMENTATION_GUIDE.md`, `MODULE_BOUNDARY_RULES.md`, `xcode-template-guide.md`) were read in full at the pinned commit on 2026-11-03; extraction and read evidence is recorded in the JSON `sourceCoverage` records and in the external evidence root.

## 4. Dependency allowlist

| Exact product | Source authority | Consumed by | Why it must be a dependency | Version/ref constraint | Declaration evidence |
|---|---|---|---|---|---|
| `ForsettiCore` (package product) | `flynn33/Forsetti-Framework-Mac-iOS` | All `RFSigil*` service and UI targets, `RFSigilForsettiModules`, `RFSigilRuntime`, `SigilTests` | Provides the modular runtime (registry, manifests, capability policy, activation, composition) that Sigil's Pattern B architecture requires | Pinned SwiftPM revision. Live product pin: `43eef7a739f3b78253c64aa4b070521ab5b1f43c` (0.1.4, per `Package.resolved` at `bc277ea`). Profile authority revision: `0097a4227789ed7d39e1491ac0aede2d9ea4f6ea` (0.1.5). Divergence recorded; neither pin moved by this contract; a pin change is a separate policy-gated dependency change. | `Package.swift` product declaration; both `Package.resolved` locks; `requiredDeclarationTokens: ["ForsettiCore"]` verified present in preflight |

## 5. Prohibited acquisition

| Prohibited material | Reason | Detection/review method |
|---|---|---|
| Whole `Forsetti-Framework-Mac-iOS` repository (copies, submodules, vendor trees) | Authority container is not a product dependency unit | Tree inspection; validator `repositoryNames` and fingerprint group checks (preflight against the actual checkout) |
| `Sources/ForsettiCore/**`, `Sources/ForsettiPlatform/**`, `Sources/ForsettiHostTemplate/**` | Framework internals are sealed; app behavior must never be implemented by copying them | Validator `pathPatterns` (RFD-SR-102) and fingerprint group (RFD-SR-104) |
| `ForsettiModulesExample` target and its manifests | Sample-only material; not a public product | Validator `targetNames`/`dependencyTokens` scan of dependency declarations (RFD-SR-106/107) |

These entries include every value required by the pinned profile (verified programmatically against `forsetti-apple-0.1.5.json`).

## 6. Product-local realization map

| Product-owned target | Kind | Responsibility | Source basis | Required transformation | Ownership/lifecycle | Verification |
|---|---|---|---|---|---|---|
| `Sources/RFSigilUIModule/**` | module | The single dedicated UI module (Phase 1 dashboard) | Pattern B, one dedicated UI module | App-owned UI implementation | Product-owned; evolves with product phases | Registration + dashboard tests; guardrails |
| `Sources/RFSigilAPSIntegration/**` | module | APS gateway service module | Service module boundary | App-owned gateway + module | Product-owned | Integration gateway tests |
| `Sources/RFSigilAeostaraIntegration/**` | module | Aeostara gateway service module | Service module boundary | App-owned gateway + module | Product-owned | Integration gateway tests |
| `Sources/RFSigilVisibleGlyph/**` | module | Visible-glyph service module | Service module boundary | Product-owned engine (ASH-derived semantics stay product-owned) | Product-owned | Glyph generation tests; guardrail codeword checks |
| `Sources/RFSigilSourceAuthority/**` | module | YWE/WRW source-authority service module | Service module boundary | App-owned status service | Product-owned | Source authority tests |
| `Sources/RFSigilPipelinePlaceholder/**` | module | Placeholder pipeline service module | Service module boundary | App-owned placeholder status | Product-owned | Placeholder pipeline tests |
| `Sources/RFSigilPrivacySecurity/**` | module | Privacy/security service module (security capability, default role) | Capability governance (README §14) | App-owned posture service | Product-owned | Privacy/security tests |
| `Sources/RFSigilDiagnostics/**` | module | Diagnostics service module (diagnostics capability, emit I/O requirement) | Capability governance (README §14) | App-owned diagnostics; Package 01 extends the capture/export path | Product-owned | Registration + diagnostic tests (Package 01) |
| `Sources/RFSigilForsettiModules/SigilModuleCatalog.swift` | manifest + registry | Eight product-owned module definitions with in-code `ModuleManifest` objects (template 1.1, `minForsettiVersion` 0.1.4); `SigilModuleRegistryInstaller` | Manifest contract (README §12) and authoring workflow (README §11) | Manifests constructed in product code through the public API; no manifest JSON resources shipped today | Product-owned | Registration tests; guardrail manifest checks |
| `Sources/RFSigilRuntime/SigilRuntimeAssembly.swift` | bootstrap | Runtime factory, service composition, dashboard status derivation | Core runtime concepts (README §7/§10) | App-owned composition over `ForsettiCore` | Product-owned | Dashboard status tests; registration tests |

The profile-required kinds (`module`, `manifest`, `registry`, `bootstrap`) are all represented.

## 7. Authority, composition, and boundaries

- Precedence: Forsetti governs module/manifest/composition mechanics only; product semantics come from the APS canonical contract; no conflict exists because the scopes do not overlap.
- Composition pattern: Pattern B (multi-module single application), 1 UI + 7 services, local-only.
- Dependency direction: UI and service modules → `RFSigilCoreModels` + `ForsettiCore`; `RFSigilForsettiModules` → all modules; `RFSigilRuntime` → catalog + services + `ForsettiCore`. No service module imports the UI module.
- Registration and discovery: `SigilModuleCatalog.definitions` (single source) → `SigilModuleRegistryInstaller.registerAll(into:)` → `ForsettiCore ModuleRegistry`.
- Communication: framework-mediated (module context services, published events) plus app-owned status providers feeding `dashboardStatus()`.
- Lifecycle: idempotent `ForsettiModule` start/stop; runtime built per launch.
- Persistence: local-only in Phase 1; no backend.
- Capabilities: minimal per module (UI: view injection; privacy/security: security + default role; diagnostics: diagnostics + emit I/O; others: none).
- Public API boundary: Forsetti public products and contracts only; no internal imports.
- Upstream-owned source boundary: the entire Forsetti repository (see §5).
- Semantic invariants: manifest/descriptor identity alignment; one UI module; no capability scope creep.
- Exclusions: no `ForsettiPlatform`/`ForsettiHostTemplate` consumption today; no paid/entitlement gating (`iapProductID` absent).

## 8. Template, example, fixture, and corpus transformation

| Source material | Why consulted | Product-owned output | Required adaptation | Sample identity that must be removed | Verification |
|---|---|---|---|---|---|
| Forsetti Xcode templates (`Forsetti App`, `UI Module`, `Service Module`, `Manifest`) | App-owned scaffolding shape and ownership split | `RFSigilForsettiModules` (registry/catalog), `RFSigilRuntime` (bootstrap/composition), `RFSigilUIModule` (module + view) | Sigil-owned module IDs, entry points, capabilities; in-code manifests via public API; exactly one UI module | `ForsettiModulesExample`, `___PACKAGENAME___`, `com.forsetti.iap.example-ui` (listed as `prohibitedSampleTokens`; must not appear anywhere in product files) | Validator RFD-SR-112 token scan; registration tests |

## 9. Governance and conformance plan

### Authority relationships

| Concern | Value |
|---|---|
| Canonical/base-design authority | Not applicable to this container (see APS canonical contract for semantic authority) |
| Native implementation authority | This pinned Forsetti revision is the native runtime authority for module mechanics |
| Precedence/conflict rule | Forsetti mechanics vs product semantics: no overlap; product semantics governed by the APS contract |
| Required semantic/conformance validator | Realization validator (contract/preflight/delivery) + product guardrails |
| Required fixtures/corpora | None from this container |
| Deviation/caveat treatment | Pin divergence (product 0.1.4 vs profile 0.1.5) recorded in §4 and the JSON `sourceCoverage`; neither pin moved |
| Linked contract IDs | `SIGIL-SR-2026-11-03-APS-CANONICAL-RC3`, `SIGIL-SR-2026-11-03-AEOSTARA-BASE-100` |

### Forsetti Agentic Edition governance

Not selected. The product repository declares no agentic-edition artifacts, project context, or task contracts, and the profile `mustApply` flag is false. If Forsetti Agentic Edition governance is adopted in a later package, a separate governance contract (`rfd.forsetti.agentic.1.1.0`) must be added to the linked set before dependent work.

## 10. Pre-implementation review

All checklist items in the JSON companion were verified during review. Key confirmations: the contract represents exactly this authority container at this immutable revision; the linked set is complete for the selected Forsetti/APS/Aeostara authorities (governance recorded not-applicable; APS-Apple-native and Aeostara-platform-native contracts not required because the product consumes no such packages — see set overview); every profile-required reading was performed; the allowlist is exact (one entry); canonical/spec/base materials are not declared as runtime dependencies; the realization map names concrete existing product outputs; template/sample identity is prohibited in product files; prohibitions are at least as strict as the profile; validation detects both missing implementation and forbidden importation.

**Review result:** Accepted for issuance
**Reviewer and date:** Independent model-based pre-implementation review (separate route from preparation; LM Studio local service, model `qwen/qwen3-coder-30b`; not human acceptance), 2026-11-03
**Evidence/reference:** Round 1 review record with issue-by-issue verification (`…/Sigil-Autonomous-Phase-Packages-v1.0-evidence/phase01/reviews/review-forsetti.json`); round 2 `VERDICT: accepted, ISSUES: none` (`review-forsetti-round2.json`, full prompt/response preserved). Round 1 raised three issues; two were false readings (the allowlist contains exactly one entry; the `ForsettiModulesExample` token is present in `prohibitedAcquisition`) and one was a clarity nit, which was addressed by wording changes recorded in the JSON.
**Contract report:** `phase01/validator/contract-forsetti.json` (+ round 2 and final: pass, zero findings)
**Preflight report:** `phase01/validator/preflight-forsetti.json` (pass, zero findings; 97 files scanned, all realization paths matched, dependency tokens verified)

## 11. Delivery conformance review

| Review | Result | Evidence | Limitations/corrections |
|---|---|---|---|
| Source understanding and realization | Not reviewed | — | Completed at delivery |
| Instruction accuracy | Not reviewed | — | Completed at delivery |
| Instruction adherence | Not reviewed | — | Completed at delivery |
| Implementation conformance | Not reviewed | — | Completed at delivery |
| Dependency/import prohibition | Not reviewed | — | Preflight already verifies against the live checkout |
| Governance conformance | Not applicable | Governance not selected (see §9) | Re-assess if agentic edition governance is adopted |
