# Sigil System Realization Contracts — Linked Contract Set

**Set ID:** `sigil-system-realization-set-2026-11-03`
**Target product:** `flynn33/Sigil` @ baseline `bc277ea05239398d58e70b76ad318de2765148d3`
**Policy binding:** Raven Forge Development 0.8.0 (local source of record: the configured policy repository; validator `tools/validate_system_realization.py`)
**Recorded:** 2026-11-03, as part of Package 01 (remediation, source alignment, diagnostic foundation) of the autonomous phase sequence.

This is the product's linked realization contract set, maintained within the authoritative Project Record. Each contract covers exactly one Raven Forge authority container at one immutable revision; canonical, native, base, and governance roles are kept separate and are never combined into one undifferentiated contract.

## Contract inventory

| Contract ID | Authority container | Role | Source pin | Profile | Status |
|---|---|---|---|---|---|
| [`SIGIL-SR-2026-11-03-FORSETTI-APPLE-015`](forsetti-apple-0.1.5/contract.md) | Forsetti Framework (Apple) | Native runtime (sealed modular runtime) | `flynn33/Forsetti-Framework-Mac-iOS` @ `0097a4227789ed7d39e1491ac0aede2d9ea4f6ea` (0.1.5) | `rfd.forsetti.apple.0.1.5` | reviewed / accepted for issuance |
| [`SIGIL-SR-2026-11-03-APS-CANONICAL-RC3`](aps-canonical-1.0.0-rc.3/contract.md) | ASH Pattern System (Canonical Specification) | Canonical specification (semantic authority) | `flynn33/ASH-Pattern-System` @ `50d7e5ab88932a4a967ffc2c83bd18fae45b73c8` (1.0.0-rc.3) | `rfd.aps.canonical.1.0.0-rc.3` | reviewed / accepted for issuance |
| [`SIGIL-SR-2026-11-03-AEOSTARA-BASE-100`](aeostara-base-1.0.0/contract.md) | Aeostara (Platform-Agnostic Base Design) | Base design | `flynn33/aeostara` @ `a1852cc5f9e094a8b7f7135479e3bf24df8c1513` (1.0.0) | `rfd.aeostara.base.1.0.0` | reviewed / accepted for issuance |

Every contract has a machine-readable companion (`contract.json`) validated against the set's JSON schema and the pinned profiles.

## Authority stack for Sigil

```text
ASH-Model cosmological mathematics (archive-hash identity; documented relationship, not a policy-catalog system)
        ↓
ASH Pattern System — Canonical Specification (semantic authority; contract above)
        ↓
Aeostara platform-agnostic base design (ASH-conformant; contract above)   Forsetti Framework (Apple) — native runtime (contract above)
        ↓                                                                              ↓
Sigil product-owned modules, services, guardrails, and conformance documentation
```

Conflict rule: ASH wins, Aeostara changes; the canonical APS specification wins over any implementation disagreement; Forsetti governs module/manifest/composition mechanics only and never product semantics.

## Deliberately not selected (recorded, not omitted)

| Candidate | Decision | Rationale |
|---|---|---|
| Forsetti Agentic Edition governance (`rfd.forsetti.agentic.1.1.0`) | **Not selected** | The product repository declares no agentic-edition artifacts, project context, or task contracts. Each contract records `governance.applies = false` with this rationale. If adopted in a later package, a separate governance contract must be added to this set before dependent work. |
| APS Apple native edition (`aps-apple-9354e31`, `flynn33/ASH-Pattern-System-Mac-iOS`) | **Not selected now** | Sigil has no APS package dependency (`Package.swift` lists ForsettiCore only). The Phase 1 evidence record read the Mac-iOS repository surface for authority purposes (products `ASHCore` + `ASHPatternSystem` observed), but no native APS target is consumed. If a later package introduces an APS package dependency, an APS-Apple native contract must be selected, read, validated, and independently accepted before that dependency is added. |
| Aeostara platform realizations (`aeostara-ios-79e3035`, `aeostara-macos-c20f506`, `aeostara-windows-0.1.0`; `flynn33/Aeostara-Mac-iOS`) | **Not selected now** | Sigil consumes no Aeostara platform package. Platform/ios observations remain product evidence (`evidence/phase1/source-authority-evidence.md`). The same pre-dependency contract rule applies if a later package introduces a platform dependency. |
| ASH-Model as a realization contract | **Not a policy-catalog system** | No pinned realization profile exists for the ASH-Model repository in the policy catalog. It is treated as canonical source authority with archive-hash identity in the design and trace records (see `docs/ash-trace`), not as a realization contract. No profile is invented for it. |

## Pin divergences (recorded; neither pin moved)

| Container | Product-record pin | Profile/contract pin | Verified relationship | Treatment |
|---|---|---|---|---|
| Forsetti | `43eef7a739f3b78253c64aa4b070521ab5b1f43c` (0.1.4, per `Package.swift`/`Package.resolved`) | `0097a4227789ed7d39e1491ac0aede2d9ea4f6ea` (0.1.5) | Product pin is an ancestor of the profile pin; 20 commits apart (license, community boilerplate, CI removal, version bump) | Contract binds to the profile pin (validator-enforced); the live product pin is recorded in the dependency allowlist; a pin change is a separate policy-gated dependency change |
| Aeostara base | `774b981ef2267a41c1b1a59497b2b0746a86f32b` (v1.0.0 closeout, per product evidence) | `a1852cc5f9e094a8b7f7135479e3bf24df8c1513` (v1.0.0) | Product pin is an ancestor of the profile pin; interval is CI/license/community changes only; both postdate the `[1.0.0] - 2026-06-22` closeout (same semantic baseline) | Same treatment as above |
| APS canonical | (none — no prior canonical pin in the product record) | `50d7e5ab88932a4a967ffc2c83bd18fae45b73c8` (1.0.0-rc.3) | New deliberate selection at the profile pin; no historical adoption claimed | Contract records the selection note and the Phase 1 CONFORMANT WITH CAVEATS history |

## Validation and review state

- **Validator:** `tools/validate_system_realization.py` (policy repository). Contract mode, preflight mode (against the product checkout), and — at delivery — delivery mode are run for every contract in the set; a blocking report is an unresolved contract or implementation defect, not an advisory.
- **This set (Package 01):** contract mode ×3 — pass, zero findings (rounds 1, 2, and final after acceptance); preflight mode ×3 against the product checkout — pass, zero findings (97 files scanned; all required realization paths matched; dependency tokens verified; no prohibited material present). Reports: external evidence root, `phase01/validator/`.
- **Independent pre-implementation acceptance:** performed on a separate route (model-based independent review via the local LM Studio service, model `qwen/qwen3-coder-30b`; full prompts, responses, timestamps, and token usage preserved in the external evidence root, `phase01/reviews/`). Round 1 raised issues per contract; each was verified against the checkout and pinned sources — legitimate clarifications were applied and false claims were rejected with evidence (details in each contract's §10). Round 2 result for all three contracts: `VERDICT: accepted, ISSUES: none`. **This is model-based independent review, not human acceptance.**
- **Delivery conformance:** not yet reviewed (to be completed with delivery verification).

## Maintenance rules

1. One authority container per contract, at one immutable revision; re-pinning supersedes the old contract (status `superseded`), it does not silently edit it.
2. Any new authority container (or a new native dependency on an existing one) requires a new or extended contract **before** the dependent work: readings, validator contract mode, independent acceptance, preflight against the checkout.
3. Profile requirements may be made stricter by a contract, never omitted; profile values are copied exactly (verified programmatically).
4. The set, its reports, and review evidence stay consistent with the Project Record: this README, the affected docs, the changelog, and the wiki.
5. Raw execution logs and review transcripts remain in the external evidence root, outside the product repository.
