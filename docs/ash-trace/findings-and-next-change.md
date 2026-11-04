# ASH-Trace Findings and Next Change

**Investigation:** `SIGIL-DEC-2026-10-09-ASH-TRACE` (amended by `SIGIL-DEC-2026-10-10-NO-EMBEDDING`)
**Product commit examined:** `53ba4895cdea2cb5d91888c369e1f980a2580067`
**Date:** 2026-11-02
**Status:** Findings complete. The proposed change below is **draft / not accepted**. No implementation is authorized by this document and no executable future implementation package is issued.

**Corrections (2026-11-03, Package 01 remediation):** F-01 is restated with the corrected source facts — the serialized ASH-Model and APS codeword tables are **not identical** (they agree exactly under a documented final-two-coordinate swap; ASH-Model uses one-based `x1..x9` with `x8 = 0`, APS uses zero-based `b0..b8` with `b8 = 0`), and the 8+1/full-9D framing is reconciled as a domain distinction (the image/video reference application's 256-state integrity subset `E` inside the 512-state `F2^9` universe versus the APS R1 all-first-class-coordinate model). F-11 is restated with the semantic branch tree (121 nodes / 81 leaves) separated from the independent rendering L-system (625 forward symbols at depth 4). The 39-character baseline hash on line 4 was a transcription error and is corrected to the 40-character Git identity. Fresh verification: independent finite calculation over the SHA-256-verified supplied archives (external evidence root, Package 01), recorded in the trace ledger `corrections_2026_11_03` field. The earlier text of this document is preserved as the historical trace output; the corrections supersede only the stated points. F-10's recorded dashboard text defect was remediated in the 2026-11-04 Package 01 closeout (R-06) with fresh SPM and iOS-simulator verification recorded in [../verification.md](../verification.md); the broken `docs/phase1/source-authority-evidence.md` locator was corrected to `evidence/phase1/source-authority-evidence.md` (the file never existed under `docs/phase1/`).

Relationships and locators: [source-to-output-map.md](source-to-output-map.md). Row-level evidence: [trace-ledger.json](trace-ledger.json). Executed and proposed checks: [verification-cases.md](verification-cases.md).

## Findings

### F-01 — Source representation and formalization (restated 2026-11-03)

- **Observed (corrected 2026-11-03):** ASH-Model v1.1.0 (`ash-model`, `docs/canonical-computational-specification.md` sections 2-3, `config/ash_mapping_v1.json`) defines the full state space `V = F2^9` (512 states, coordinate 1 most significant) and, for its image/video reference application, the integrity hyperplane `E = {x : x9 = x1 xor ... xor x8}` (256 states). States outside `E` remain valid `F2^9` vertices; `E` is an application-specific integrity policy, not the whole state space. In the one-based `x1..x9` convention, coordinate 8 is zero in every codeword and constant within each code orbit.
- **Observed (corrected 2026-11-03):** APS native contracts (`aps-native`, `specs/core/ash-state-space.pseudo.md`) record the R1 realignment: all 9 coordinates are first-class, no coordinate is privileged, and re-deriving the 9th coordinate as parity/control is forbidden. APS tables use the zero-based `b0..b8` convention, in which `b8` (the ninth coordinate) is zero in every codeword.
- **Corrected (supersedes the original "Consistent across both" statement):** the serialized 16-codeword tables are **not identical**. ASH `data/codewords.csv` (one-based, `x8 = 0`) and APS `specs/core/codeword-set.pseudo.md` (zero-based, `b8 = 0`) share 8 of 16 members as raw strings. Swapping the final two coordinates of every ASH codeword makes its set **exactly equal** to the APS set (example: ASH `000011101` maps to APS `000011110`). The swap is an involution on all 512 states and commutes with XOR for all 512 x 16 state/codeword pairs (fresh independent calculation over the SHA-256-verified supplied archives, 2026-11-03; external evidence root). Both sets are closed 16-member doubly-even [9,4,4] codes with minimum nonzero weight 4 and 32 sixteen-state orbits in the full 512-state space.
- **Reconciliation:** the two sources state different domains — a reference application's integrity policy over `E` versus an all-first-class-coordinate state model. The full nine-coordinate universe is the common ground; the image/video parity subset does not by itself contradict the R1 model, and the R1 model does not invalidate the reference application's algebra, data, or branch computations. The equivalence under a proven final-two-coordinate permutation is algebraic evidence for an **explicit, explicitly-named coordinate adapter at a documented boundary** — not permission to erase the source coordinate labels, silently swap data, regenerate codewords in the wrong convention, or claim an upstream contract already approves a particular product boundary.
- **Impact:** the product-owned decision is which representation Sigil's product record uses (and which documented boundary translates it), plus whether any parity-derived term is adopted for personal-profile inputs at all (the image measurement pipeline and its parity-derived coordinate must not be imposed on profile inputs merely because they appear in the computational reference). Recorded under the 2026-11-03 assignment as a product-owned design decision resolved in the Package 01 planning pass; any remaining genuine normative conflict stays specific and visible.
- **Decision required before:** F-04 state derivation (VC-PROP-04).

### F-02 — No canonical profile-input to F2^9 mapping exists in the retrieved sources

- **Observed:** the ASH-Model coordinates 1-8 are defined as image/video-domain measurements (luminance, contrast, edge/texture/chroma energies, gradients, temporal change) with versioned thresholds and hysteresis (`config/ash_mapping_v1.json`, spec section 7). No supplied source maps personal profile inputs to the 9 coordinates.
- **Observed:** the canonical profile-side derivation is the celestial name generator (life path, dominant plane, wolf score, weekday archetypes, heritage priority) plus the cosmological contracts (`ywe`, `wrw-ontology`).
- **Impact:** the smallest change cannot "implement the canonical mapping" because none is canonically prescribed for profiles. The missing mapping is a **named source decision**, not an inference gap to fill with an invented formula.

### F-03 — The identity layer is digest-derived substitution

- **Observed:** `ashState` is a name-only `SigilStabilizedState` over `sha256("state:{profileHash}:{dominantPlaneId}")` with stabilizer class `local_stable_basis` (`SigilVisibleGlyphService.swift:180`); the plane vector derives from `digestBytes[0..8] % 89 + 11` with argmax dominance (line 172); wolf balance derives from `digestBytes[9..10]` (line 174); no orbit or codeword is computed; the celestial basis is a local switch on (dominant plane, wolf category) (lines 177, 573).
- **Controlling requirement:** the generation formula must be based on ASH mathematics and cosmology (project plan; roadmap ASH-GLYPH); F2^9 state space, code orbits, and the celestial derivation are cited in the map.
- **Impact:** every identity concept currently hangs off digest bytes; replacing the derivation re-derives the identity layer and changes artifact digests for all profiles.

### F-04 — Non-standard numerology roots

- **Observed:** `expressionDestinyRoot` = reduced Unicode scalar sum of `name`; `soulUrgeRoot` = reduced scalar sum of `eyes`; `personalityRoot` = reduced scalar sum of `hair` (`SigilVisibleGlyphService.swift:490-492`). Standard numerology derives these roots from name letter values (expression from the full name, soul urge from vowels, personality from consonants) under a fixed letter-to-number mapping; the canonical celestial generator uses explicit hair/eye modifiers for the wolf score, not scalar sums.
- **Supported part:** `lifePathRoot` matches the canonical digit-sum rule (ledger `input.birth_date`).
- **Impact:** the numerology record is a PersonalCodex input; correction changes digests and any numerology-driven geometry.

### F-05 — Master-number policy is a missing source decision

- **Observed:** the product preserves 11/22/33 (`SigilVisibleGlyphService.swift:488`) and keys an accent path to them (line 325); the canonical generator reduces the date total fully to one digit with no preservation rule; the roadmap lists master-number handling as an open question to reconcile from sources.
- **Impact:** both behaviors are citable; neither is canonical until the owner decision is recorded (VC-PROP-07 is deliberately unresolved).

### F-06 — Input model is incomplete versus the retained plan

- **Observed:** `SigilProfileInput` lacks birth weekday, parents' birth order, separate first/last name, and ancestral surnames; birth time, birth location, and birth order are digest-only (ledger rows `input.weekday`, `input.parent_birth_order`, `input.birth_time`, `input.birth_location`, `input.birth_order`, `input.heritage_surnames`).
- **Controlling requirement:** the retained input model and "every supported input needs an explicit deterministic treatment" (project plan).
- **Impact:** the identity derivation cannot be complete until the input model is extended and each field's treatment is source-backed or explicitly decided (VC-PROP-08).

### F-07 — Geometry is a local hash-parameterized substitution

- **Observed:** five fixed anchors with digest offsets; fixed edges and semantic roles; 11 base paths plus conditional ornaments from `sha256(profileHash:canonicalGeometryDigest:candidateIndex)` parameters; 64-candidate collision-advance selection (`SigilVisibleGlyphService.swift:185, 259-340, 72`).
- **Controlling requirement:** canonical branch geometry — L-system `F -> FF[+F]F[-F]`, 25-degree turns, 0.72 decay, per-node state/codeword segments (`ash-model` spec section 9, `data/branch-topology.json`) — and deterministic candidate ranking by prior plus score (spec section 11).
- **Impact:** the visible sigil itself is the surface; the ASH-GLYPH workstream replaces this synthesis with mathematical materialization once the identity layer is canonical.

### F-08 — Supported and intact behaviors (no defect)

- **Observed (fresh 2026-11-02 runs at `53ba489`, evidence in the external evidence root):** determinism, golden-profile uniqueness, quality-gate rejection, collision advance, Flare immutability, fail-closed digest validation, Aeostara fail-closed health decision, runtime assembly (8 modules, Forsetti 0.1.4 at pin `43eef7a`), and local-only privacy posture all pass (22/22 simulator tests; repository guards pass).
- **Impact:** these are the retained boundaries the proposed change must preserve, not replace.

### F-09 — No embedding machinery is present

- **Observed:** full source read found no payload encoder, decoder, sidecar channel, or scan-to-record path; the hidden geometry is internal state, not a carrier.
- **Impact:** `SIGIL-DEC-2026-10-10-NO-EMBEDDING` (removed, not deferred) is preserved; no payload round-trip gate exists or is required (VC-PROP-09).

### F-10 — Authority pins are intact; one stale source string recorded

- **Observed:** Aeostara base pin `v1.0.0` at `774b981ef2267a41c1b1a59497b2b0746a86f32b` (matches `evidence/phase1/source-authority-evidence.md`; path corrected 2026-11-04 — the file never existed under `docs/phase1/`); ForsettiCore pinned at `43eef7a739f3b78253c64aa4b070521ab5b1f43c`; module catalog holds 8 modules while the dashboard card text still says "Seven Sigil modules... one UI module and six service modules" in `Sources/RFSigilRuntime/SigilRuntimeAssembly.swift` (historical observation; see corrected status below).
- **Impact:** the stale string was a source defect outside the documentation-only trace assignment; it is recorded here as observed at `53ba489`.
- **Corrected status (2026-11-04, Package 01 closeout, R-06):** the stale dashboard text is fixed: `SigilRuntimeAssembly.dashboardStatus()` derives the module counts from registration/catalog and the APS card states recorded conformance evidence without implying a live dependency or resolver. Dashboard regression tests pin the derived counts (1 UI module, 7 service modules). See [../verification.md](../verification.md).

### F-11 — Canonical reference artifacts are the geometry/identity reference the product does not yet reference

- **Observed (corrected 2026-11-03):** `data/ash-state-reference.csv` (512 states with integrity/coset/decoder metadata), `data/codewords.csv` (16 codewords), and `data/branch-topology.json` (121 nodes / 81 leaves with per-node 2D segments) exist in the supplied ASH-Model archive and are internally consistent (all 16 messages reached at depth 4; node/leaf counts, parent links, and per-node states follow the encoded messages). The original text's claim that the leaf/node counts "match the L-system expansion" is corrected: the semantic branch tree (`generate_branch_tree`) and the independent rendering grammar (`expand_geometry_lsystem` / `interpret_geometry_lsystem`, `F -> FF[+F]F[-F]`) are separate objects; at depth 4 the rendering expansion contains **625 forward (F) symbols**, not 121 nodes or 81 leaves. Neither count may be enforced as an invented visible-glyph invariant.
- **Impact:** any implementation decision must state how these artifacts are used (embedded canonical data, generated at build, or referenced computation) without violating the no-new-dependency boundary.

### F-12 — Canon constraints on any future implementation

- **Observed:** wolves are complementary opposites, not moral poles, and the correct overwhelmed state is temporary decoherence (`ywe` twin-wolf contract, `mythic-map`); plane attunement requires provenance and forbids a fixed plane class or a plain level score (`ywe` plane attunement contract); celestial identity begins veiled and the name generator supports flavor without overriding progression (`ywe` celestial identity contract); bloodline is pressure with references, not a static class lock (`ywe` bloodline resonance contract); "local ASH math" and "local codeword set" are forbidden authority-drift claims (`ywe` ash upstream contract, superseded-section preserved as component evidence; `ywe` cosmology authority contract).
- **Impact:** these constrain interpretation and wording of any implementation, including diagnostics and user-facing text.

## Compatibility impact of the proposed change

| Surface | Consequence if the change proceeds |
| --- | --- |
| Artifact digests | Digest domain changes (identity derivation replaced); all artifact hashes change for all profiles. No persisted records exist in this phase, so no migration of stored data is triggered; the compatibility surface is future persistence/export consumers. |
| Tests | Existing visible-glyph tests encode the current digest-derived contract. They remain until a separately scoped implementation change establishes that a specific test encodes a superseded contract (project plan rule); golden fixtures will need regeneration under the new derivation. |
| Serialization | Types stay Codable; the digest chain is retained. A versioned schema marker would be appropriate in the implementation scope, not here. |
| Quality gates | Retained where compatible (F-08); thresholds are product policy. |
| Versioning | No product/build/schema version change in this investigation; `PA.0.1.0` / build `1` unchanged and re-verified by the fresh build (built `Info.plist`: `CFBundleShortVersionString = PA.0.1.0`, `CFBundleVersion = 1`). |

## Smallest proposed change (draft / not accepted)

**Prerequisite owner decisions (no code):**

1. **Formalization (F-01):** choose the governing state formalization — ASH-Model 8+1 parity structure or APS R1 full 9D — from the authoritative records.
2. **Profile mapping (F-02):** adopt a source-backed mapping from retained inputs to the F2^9 state (the canonical profile-side derivations in the celestial generator are the cited starting material; any profile-specific coordinate assignment requires an owner-adopted rule).
3. **Master-number policy (F-05):** preserve 11/22/33 or adopt full reduction.
4. **Input policy (F-06):** treatment rules for weekday, time, location (with geocoding scope under the privacy boundary), birth order, parents' birth order, first/last split, and ancestral surnames.

**Smallest implementation scope (after the decisions, in a separately authorized assignment):**

- **Owning module:** extend `RFSigilVisibleGlyph` (product-owned) with a canonical identity derivation stage between canonicalization and hidden-geometry construction; no new dependency, no Forsetti/APS/Aeostara repository changes.
- **Expected behavior:** retained inputs produce (a) standard numerology per the adopted policy, (b) a deterministic 9-bit ASH state per the adopted mapping, (c) orbit/codeword resolution using exactly the closed 16-codeword set, (d) dominant plane from the life path, (e) wolf balance from the canonical score equation, (f) weekday archetype and heritage priority per the cited tables, and (g) geometry derived from the branch-grammar/L-system structure with the existing quality gates, digest linkage, and fail-closed validation preserved.
- **Failure handling:** invalid or partial input yields explicit fail-closed decisions with local redacted diagnostics (plan rule: no invented weighting, no silent omission).
- **Canonical data handling:** decide embed-vs-generate for the 16-codeword set and branch constants (F-11) without adding dependencies.
- **Verification:** the proposed cases VC-PROP-01 through VC-PROP-09 become the conformance suite; existing tests are dispositioned per the project plan rule; determinism and fail-closed behavior remain passing.

**Rejected alternatives (with evidence):**

1. **Relabel the digest-derived identity as "ASH".** Rejected: the observed derivation is SHA-256 over profile digests (F-03); no read source supports digest bytes as an ASH semantic, and the roadmap requires the governing mathematics to determine the canonical form, not a themed or digest-derived placeholder (project plan).
2. **Full framework rewrite / adopt the APS native runtime as a dependency.** Rejected: outside the approved bounded scope; dependency changes are not authorized by the trace; APS remains the semantic authority for contracts, not a runtime import (project plan source-responsibility table).
3. **Reintroduce a payload channel to carry identity.** Rejected: explicitly removed, not deferred (`SIGIL-DEC-2026-10-10-NO-EMBEDDING`); the trace found no such machinery to preserve (F-09).

**Explicit non-goals:** no formula is selected here; no code is changed; no future workstream (IDENTITY-PIPELINE, ARTIFACT-HEALTH, CANON-AND-PersonalCodex, ASH-GLYPH, EXPERIENCE-AND-EXPORT, CANDIDATE-VALIDATION) is started; no version, native project, or schema change.
