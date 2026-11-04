# ASH Source-to-Output Map

**Investigation:** `SIGIL-DEC-2026-10-09-ASH-TRACE` (amended by `SIGIL-DEC-2026-10-10-NO-EMBEDDING`)
**Product commit examined:** `53ba4895cdea2cb5d91888c369e1f980a2580067` (`main`, clean tree, remote-in sync)
**Completed:** 2026-11-02
**Status:** Investigation complete. Read-only: no application source, test, dependency, canonical resource, native project file, or version change was made in this investigation.

**Corrections (2026-11-03, Package 01 remediation):** this map's "Material source conflict" paragraph, the branch-grammar bullet, and the coordinate-convention wording are corrected as recorded there and in [findings-and-next-change.md](findings-and-next-change.md) F-01/F-11: the serialized ASH-Model and APS codeword tables are not identical (they agree exactly under a documented final-two-coordinate swap), the 8+1/full-9D framing is a domain distinction (256-state image/video integrity subset `E` inside the 512-state `F2^9` universe), and the semantic branch tree (121 nodes / 81 leaves) is a separate object from the independent rendering L-system (625 forward symbols at depth 4). This document's own baseline hash was already the correct 40-character Git identity and was re-verified against Git on 2026-11-03; the 39-character transcriptions in the sibling documents were corrected. Fresh evidence: independent finite calculation over the SHA-256-verified supplied archives (external evidence root, Package 01). The earlier text is preserved as the historical trace output; corrections supersede only the stated points.

This map traces every output-affecting intermediate of the current visible-glyph generator from its declared inputs to the governing ASH mathematics, canonical datasets, and referenced binary artifacts. Each relationship is classified `supported`, `substitution`, `unresolved`, or `not_applicable` in [trace-ledger.json](trace-ledger.json). Supporting findings and the smallest proposed next change are in [findings-and-next-change.md](findings-and-next-change.md); verification cases with executed versus proposed status are in [verification-cases.md](verification-cases.md).

## Source authorities

| Source ID | Kind | Identity | Role in this trace |
| --- | --- | --- | --- |
| `sigil` | git | `53ba4895cdea2cb5d91888c369e1f980a2580067` | Product checkout examined (this repository, `main`) |
| `ash-model` | archive | `a40206150252bd5caecd55a4a97bf8938b25b39664e737148ba381997a57de09` (SHA-256 of supplied `ASH-Model-main.zip`) | Mathematical authority: F2^9 state space, [9,4,4] transform code, canonical computational specification, canonical reference data |
| `aps-native` | archive | `1ac756bcbd2783dea9bd0f5dc3f2886f2fc02d7399bfba31c8bcaddebbaca6a6` (SHA-256 of supplied `ASH-Pattern-System-Mac-iOS-main.zip`) | Native Swift source contracts: state space, codeword set, orbit admissibility, averaging operator, containment/safe-failure semantics, conformance categories |
| `aeostara` | archive | `ea1b6e444284dedec05653d2157dfe0bc3f731f69865199743d8fb66b4468904` (SHA-256 of supplied `Aeostara-Mac-iOS-main.zip`) | Base-design authority (governance branch): base pin `v1.0.0` at `774b981ef2267a41c1b1a59497b2b0746a86f32b`, ASH baseline `e123f5d7fdbb381179971f721a3292c31eb1cbc2`, platform-branch isolation rules |
| `forsetti` | git | `43eef7a739f3b78253c64aa4b070521ab5b1f43c` | Observed product dependency pin (`ForsettiCore`, per `Package.resolved`) |
| `ywe` | archive | `4c4d3c29692c55c809ceb318c63947c897debd57b4a91056a2eda509a9227719` (SHA-256 of supplied `yggdrasil-world-engine-main.zip`) | Canon/interpretation contracts: cosmology authority hierarchy, plane attunement, celestial identity progression, twin-wolf canon, bloodline resonance |
| `celestial-gen` | file | `91fe15c05026621f2956ec0998dde384101bffab6b778bba92d0d03d090d04fb` (SHA-256 of supplied `celestial-name-generator.json`) | Canonical profile-side derivation: life path, dominant plane, wolf score equation, weekday archetypes, heritage priority, name/epithet templates |
| `celestial-gen-pseudo` | file | `2232c6e1460919b37cefd30af007178c99800b55efed8e247b6c84095e620cfa` (SHA-256 of supplied `celestial-name-generator-pseudocode.json`) | Algorithm-level specification of the celestial name generator |
| `nine-planes` | file | `f0f893c791262c47e2294f2e30d7ad38e8d1890c46c4c25f7a20eee693c96b1e` (SHA-256 of supplied `nine-planes-of-existence.json`) | Nine planes with mathematical types and story mappings |
| `mythic-map` | file | `a9235762a0b5d4f9c146abd547a65a1e585be94af301b27c06590f74eacfcee6` (SHA-256 of supplied `master-mythic-mapping.json`) | White/Dark Wolf as symbiotic dual attractors (not moral poles); canonical character birth date 1977-11-04 |
| `pattern-sheets` | file | `45ff9abc31532756f2851961932a6e498bc4674c25111b98a96e64a66a538a4c` (SHA-256 of supplied `pattern-vector-char-sheets.json`) | 5-dimension pattern vector per character (H, K, D, S, L) and active planes |
| `wrw-ontology` | file | `527f8d89226f8c7d363efbf10c7b95ce027e9a58cf8650c7f55ccb62c8b22323` (SHA-256 of the supplied Where Ravens Wait master-ontology JSON, v2.0.0-luciferian-merged) | Merged WRW ontology v2.0.0: axioms A1-A6, planes P1-P9, pattern vector model, existence potential Phi, branching dynamics |

Development-policy method binding in effect during execution: Raven Forge Development 0.8.0. The package intake/reference pin is commit `5df71a97a7a3500d31a5ab0b07dd9f987c00be01` (0.8.0); the execution-time binding was the owner's local 0.8.0 policy snapshot. The two are distinct identities; this investigation does not claim historical adoption of either as a repository change and does not treat the intake pin as an automatic upgrade.

## Governing ASH mathematics (what the trace follows)

From `ash-model` (`docs/canonical-computational-specification.md`, spec v1.0.0, normative config `config/ash_mapping_v1.json`):

- State space `V = F2^9`, coordinate 1 most significant. Application integrity hyperplane `E = {x : x9 = x1 xor ... xor x8}`: 256 even-weight states.
- Transform code `C`: [9,4,4], doubly even, 16 codewords, weights `0^1 4^14 8^1`; for every `c in C`, `c8 = 0` and `c9 = c1 xor ... xor c8`. Canonical data: `data/codewords.csv` (16 rows), `data/ash-state-reference.csv` (all 512 states with integrity, coset, and decoder status).
- Orbits: `[x]_C = x + C`, 16 states each; 32 orbits in `V`, 16 in `E`; coordinate 8 is constant within each orbit (ASH-Model one-based `x1..x9` convention; see the coordinate-convention note below). Averaging projection `T` is the idempotent projection onto orbit-constant functions.
- Branch grammar (semantic): actions `0`, `+`, `-` (priors 0.5/0.25/0.25); at level `l`, `+` toggles message bit `l mod 4`, `-` toggles bit `(l+1) mod 4`; node state `x_node = x xor enc(m)`. Depth-4 reference topology `data/branch-topology.json`: 121 nodes, 81 leaves, all 16 messages reached.
- Rendering grammar (independent object, corrected 2026-11-03): the L-system `F -> FF[+F]F[-F]` with a 25-degree turn and 0.72 length decay expands the axiom to **625 forward (F) symbols at depth 4**. The ASH source separates `generate_branch_tree` from `expand_geometry_lsystem`/`interpret_geometry_lsystem`; the 121-node/81-leaf semantic tree and the 625-symbol rendering expansion must not be conflated, and neither count is an invented visible-glyph invariant.
- Candidate selection: deterministic ranking by `log P(message) + log S` with top-k pruning; no candidate repaired beyond the decoder's one-bit radius.
- Adinkra layer: puncturing coordinate 8 yields the self-dual doubly-even [8,4,4] code `C8`; the quotient `Q8/C8` has 16 vertices (8 even, 8 odd cosets) with the Garden matrix representation.

From `aps-native` (`specs/core/*`, `specs/algorithms/*`, `specs/verification/*`):

- R1 realignment treats all 9 coordinates as first-class and forbids re-deriving the 9th coordinate as parity/control; the 16-codeword set is fully closed (4 generators, `b8 = 0` for all 16 codewords) and must be used exactly as enumerated. APS tables use the zero-based `b0..b8` convention, in which `b8` is the ninth coordinate (corrected 2026-11-03: this is a different serialization convention from the ASH-Model one-based convention, not the same "b8").
- Orbit-based state admissibility (`VALID`, `TRANSFORMATION_COMPATIBLE`, `TRANSFORMATION_INCOMPATIBLE`, `UNCLASSIFIED`); averaging-operator stability is C-invariance.
- Containment/safe-failure semantics: monotonic escalation, terminal irrevocable `SAFE_HALT`, no silent containment or halt, diagnostic chaining with parent and chain-root references.
- Conformance acceptance is `CONFORMANT`, `CONFORMANT WITH CAVEATS`, or `NON-CONFORMANT` only; treating an 8+1 decomposition as canonical is a non-waivable failure.

**Material source relationship (restated 2026-11-03, supersedes the original "Material source conflict" paragraph):** `ash-model` v1.1.0 defines the full state space `V = F2^9` (512 states) and, for its image/video reference application, the integrity hyperplane `E` of 256 states (bit 9 as the parity of bits 1-8; coordinate 8 invariant under the code). States outside `E` remain valid `F2^9` vertices, so `E` is an application-specific integrity policy, not a second state space. `aps-native` R1 realignment treats all 9 coordinates as first-class and forbids re-deriving the 9th as parity/control. These are domain-level statements over a common nine-coordinate universe, not a same-domain contradiction. The serialized 16-codeword tables are **not identical** as written: the ASH table (one-based, `x8 = 0`) and the APS table (zero-based, `b8 = 0`, the ninth position) share 8 of 16 raw members, and swapping the final two coordinates of every ASH codeword makes the sets exactly equal; the permutation is an involution on all 512 states and commutes with XOR for all 512 x 16 state/codeword pairs (fresh independent calculation over the SHA-256-verified supplied archives, 2026-11-03; external evidence root). This is algebraic evidence for an explicit coordinate adapter at a documented boundary — not permission to erase source coordinate labels, silently swap data, or claim an upstream contract already approves a product boundary. Which representation Sigil's product record uses, and which documented boundary translates it, is resolved as a product-owned design decision under the 2026-11-03 assignment; see [findings-and-next-change.md](findings-and-next-change.md) F-01 (restated).

From the canon/interpretation layer (`ywe`, `wrw-ontology`, `celestial-gen`):

- Authority hierarchy: WRW narrative layer > Yggdrasil engine > ASH Cosmological Model (upstream foundation) > APS (YWE component for integrity, diagnostics, recovery, containment, conformance). The ASH Cosmological Model owns the nine planes, axioms A1-A6, Phi, pattern vectors, branching realization, wolf attractor logic, and bloodline resonance meaning; feature engines may not redefine the cosmology, and "local ASH math" or a "local codeword set" are forbidden authority-drift claims.
- Nine planes: `P1_Physical`, `P2_Etheric`, `P3_Astral`, `P4_Mental`, `P5_Causal`, `P6_Celestial`, `P7_Shadow`, `P8_Void`, `P9_Divine Core`. Plane attunement is a dynamic runtime resonance with score, pressure state, trend, and provenance; a fixed plane class or a provenance-free score is forbidden.
- Celestial identity begins veiled and is revealed through history; the celestial name generator supports flavor, seed values, and epithets without overriding the progression contract.
- Wolf canon: the White Wolf and Dark Wolf are complementary opposites, not moral opposites; the correct overwhelmed state is temporary decoherence, not permanent loss.
- Bloodline resonance is lineage pressure with per-signal status, score, stability, and source references; it is not a static class lock.
- Canonical profile-side derivation (`celestial-gen`): life path = digit sum of the birth date reduced to one digit; dominant plane = the plane whose numerology values contain the life path; wolf score = hair modifier + eye modifier + time-bucket modifier + life-path modifier with white >= 1.0 / dark <= -1.0 thresholds; weekday archetypes per day; heritage priority `scandinavian > celtic > germanic > other -> generic_northern`.

**Canonical-data note:** the ASH-Model coordinates 1-8 are defined as image/video-domain measurements (luminance, contrast, edge/texture/chroma energy, gradients, temporal change). No supplied canonical source prescribes a personal-profile-input to F2^9 state mapping; the profile-side canon is the celestial-name generator plus the cosmological contracts above. This missing mapping is recorded as an explicit owner decision prerequisite (F-02), not filled by invention.

## Current product call/data-flow path (as read at `53ba489`)

Entry: `SigilVisibleGlyphService` (`Sources/RFSigilVisibleGlyph/SigilVisibleGlyphService.swift`).

```text
SigilProfileInput (Sources/RFSigilVisibleGlyph/SigilVisibleGlyphModels.swift:4)
  -> canonical JSON + SHA-256 profile digest (SigilVisibleGlyphService.swift:469 digest, :473 sha256Hex)
  -> 64-candidate collision window (SigilVisibleGlyphService.swift:72)
  -> makeHiddenGeometry(for:) (SigilVisibleGlyphService.swift:168)
       planeVector from digestBytes (SigilVisibleGlyphService.swift:172)
       dominantPlaneId = argmax (SigilVisibleGlyphService.swift:173)
       wolfBalance from digestBytes (SigilVisibleGlyphService.swift:174)
       celestialBasisID from (dominantPlane, wolfCategory) switch (SigilVisibleGlyphService.swift:177, :573)
       ashState = SigilStabilizedState(stateDigest: sha256("state:{profileHash}:{dominantPlaneId}"),
                                       stabilizerClass: "local_stable_basis") (SigilVisibleGlyphService.swift:180)
       anchorPoints = 5 fixed anchors + digest-byte offsets (SigilVisibleGlyphService.swift:185)
       NumerologyVector (SigilVisibleGlyphService.swift:488-492; SigilVisibleGlyphModels.swift:38)
  -> SigilFamilyKey (SigilVisibleGlyphModels.swift:182) with planeAttunementVector (SigilVisibleGlyphService.swift:204, :218)
  -> makeVectorPaths (SigilVisibleGlyphService.swift:259)
       parameter seed = sha256(profileHash : canonicalGeometryDigest : candidateIndex) (SigilVisibleGlyphService.swift:265)
       11 base paths + conditional ornaments (heritage/wolf/master-number driven, :325)
  -> quality gate (SigilVisibleQualityGate, SigilVisibleGlyphService.swift:6; report type SigilVisibleGlyphModels.swift:251)
       segment bounds, major crossings <= 3 (:334-335), duplicates, score >= 0.70
  -> SVG string artifact + digest linkage (SigilVisibleGlyphArtifact, SigilVisibleGlyphModels.swift:375)
  -> validateArtifact fail-closed -> AeostaraHealthDecision (SigilVisibleGlyphService.swift:164, :369-394)
  -> SigilFlarePresentation (presentation copy, SigilVisibleGlyphService.swift:151; SigilVisibleGlyphModels.swift:353)
```

Consumers: `SigilTests/VisibleGlyphGenerationTests.swift` (determinism, golden-profile uniqueness, gate rejection, collision advance, Flare immutability, fail-closed validation), `SigilTests/DashboardStatusTests.swift` (dashboard cards, runtime assembly), `SigilTests/IntegrationGatewayTests.swift` (APS/Aeostara status surfaces), `SigilTests/SourceAuthorityTests.swift` (authority hierarchy), `SigilTests/PrivacySecurityTests.swift` (local-only posture).

## Relationship map (per intermediate)

Statuses use the ledger vocabulary; full observations, refs, findings, and gaps are in [trace-ledger.json](trace-ledger.json).

| Intermediate (model field) | Product derivation at `53ba489` | Relationship | Controlling authority |
| --- | --- | --- | --- |
| `profileHash` / digest chain | SHA-256 over canonical input JSON; geometry and artifact digests chained | supported | Product-owned integrity; consistent with safe-failure semantics (`aps-native`, `aeostara`) |
| `NumerologyVector.lifePathRoot` | Digit-sum reduction of the birth date | supported (life path) | `celestial-gen` (same digit-sum rule); master-number divergence tracked separately |
| `NumerologyVector.preservedMasterNumbers` | Preserves 11/22/33 when the date total is in the set (SigilVisibleGlyphService.swift:488) | unresolved | `celestial-gen` reduces all the way to 1-9 (no preservation); no approved record decides the policy |
| `NumerologyVector.expressionDestinyRoot` / `soulUrgeRoot` / `personalityRoot` | Unicode scalar sums of `name`, `eyes`, `hair` (SigilVisibleGlyphService.swift:490-492) | substitution | Standard numerology derives these roots from name letter values; canonical wolf score uses explicit hair/eye modifiers (`celestial-gen`) |
| `planeVector` / `dominantPlaneId` | 9 values from `digestBytes[0..8] % 89 + 11`, normalized; dominant = argmax | substitution | `celestial-gen` dominant plane from life path; named nine planes (`nine-planes`, `wrw-ontology`); attunement semantics (`ywe` plane attunement contract) |
| `WolfBalance` | White/dark from `digestBytes[9..10] % 80 + 10`; category by absolute difference | substitution | `celestial-gen` wolf score equation and thresholds; dual-attractor canon (`mythic-map`, `ywe` twin-wolf contract) |
| `SigilStabilizedState` (`ashState`) | Name-only stabilized state over a digest string; stabilizer class `local_stable_basis` | substitution | F2^9 state space and code orbits (`ash-model`); orbit admissibility (`aps-native`); formalization conflict F-01 |
| orbit / closure class | Not computed | substitution | 16-state code orbits, 32 total / 16 in `E`, coordinate 8 orbit-constant (ASH-Model one-based convention; `ash-model`) |
| `CelestialClassBasis` (`celestialBasisID`) | Local switch on (dominant plane, wolf category) to five local basis names; source `derived_local_profile_basis` | substitution | Celestial identity and plane/wolf canon (`celestial-gen`, `ywe` celestial identity contract, `wrw-ontology`) |
| `AncestryWeight` list | Local family taxonomy and weights from heritage and digest | substitution | Bloodline resonance semantics (not a static class lock; provenance-bearing) (`ywe` bloodline resonance contract); heritage priority (`celestial-gen`) |
| `SigilAnchorPoint` / `SigilGeometryEdge` / semantic roles | 5 fixed anchors with digest-byte offsets; fixed edge list and role labels | substitution | Branch-topology node geometry and branch action grammar (`ash-model` `data/branch-topology.json`, spec section 9); Adinkra colored edges (`ash-model` spec section 12) |
| `candidateIndex` / 64-window | Collision-advance over `sha256(profileHash:canonicalGeometryDigest:candidateIndex)` | substitution | Deterministic candidate ranking `log P + log S`, top-k, no repair beyond radius 1 (`ash-model` spec section 11) |
| `VisibleVectorPath` set | SHA-256-parameterized path synthesis plus conditional ornaments (celtic/balanced left, slavic/dark-dominant right, master-number accent), cap 14 | substitution | Semantic branch topology (121 nodes / 81 leaves) plus the independent rendering L-system `F -> FF[+F]F[-F]` (625 forward symbols at depth 4), 25-degree turn, 0.72 decay, per-node segments (`ash-model` spec section 9, `data/branch-topology.json`; corrected 2026-11-03) |
| `VisibleSigilQualityReport` | Segment 10-14, crossings <= 3, duplicates <= 2, score >= 0.70 | supported | Product-owned bounded gate; no conflicting canonical rule found |
| artifact digest validation | Fail-closed `AeostaraHealthDecision` on mismatch | supported | Aeostara base pin and safe-failure invariants (`aeostara`, `aps-native` containment-safe-failure spec) |
| `SigilFlarePresentation` | Presentation copy of canonical fields plus style metadata | supported | Plan/roadmap Flare boundary (presentation only, non-authoritative); immutability test-proven |
| SVG render/export | Local string rendering; no export bundle in this phase | supported | Bounded local behavior per plan; export workstream remains pending product work |
| runtime integration | Forsetti assembly, 8 modules (1 UI + 7 service), `forsettiVersion 0.1.4` at pin `43eef7a` | supported | `forsetti` pin; roadmap module-count disposition (record-only defect: stale "Seven Sigil modules" dashboard string) |
| privacy/diagnostics | Local-only; no analytics/network capability | supported | Product privacy boundary (plan); local-only posture test |
| embedding disposition | No payload encoder, decoder, sidecar, or scan-to-record in source (full source read) | supported | `SIGIL-DEC-2026-10-10-NO-EMBEDDING` (removed, not deferred) |

## Referenced canonical data and binary artifacts

| Artifact | Location (in `ash-model` unless noted) | Role in trace |
| --- | --- | --- |
| `data/ash-state-reference.csv` | 512 states + header; columns: index, bits, hamming weight, integrity, coset id/representative, nearest code distance/count, decoder status | Full state-space reference for any future state derivation |
| `data/codewords.csv` | 16 message/codeword/weight/syndrome rows | The closed codeword set; no invented codewords permitted |
| `data/branch-topology.json` | 121 nodes / 81 leaves, depth 4; per-node state, codeword, message, 2D segment geometry | Canonical branch geometry reference |
| `config/ash_mapping_v1.json` | Bit order, thresholds/hysteresis, code parameters, generator matrix, transform masks, branching/geometry constants, reconstruction/scoring weights | Normative executable configuration |
| `docs/canonical-computational-specification.md` | 14 sections as summarized above | Normative computational specification (v1.0.0) |
| APS native specs (`aps-native` `specs/`) | State space, codeword set, realm identity, admissibility, transformation/averaging/branching semantics, containment-safe-failure, conformance categories, implementation acceptance | Native-contract authority for any Swift realization |
| Aeostara base pin (`aeostara` governance docs) | Base `v1.0.0` at `774b981ef2267a41c1b1a59497b2b0746a86f32b`; ASH baseline `e123f5d7fdbb381179971f721a3292c31eb1cbc2` | Health/validation authority pin (matches product `evidence/phase1/source-authority-evidence.md`) |
| Forsetti pin (`forsetti`) | `43eef7a739f3b78253c64aa4b070521ab5b1f43c` per `Package.resolved` | Runtime module boundary |

## Embedding-only responsibility check

A full read of all 17 product source files found **no** personal-payload encoder, decoder, sidecar channel, or scan-to-record path. The hidden geometry is internal mathematical/visual state, not a data carrier. The removed embedding requirement is not present under any other name; see ledger row `requirements.embedding_disposition`.

## Record-only observations (not changed in this investigation)

1. Dashboard card text in `Sources/RFSigilRuntime/SigilRuntimeAssembly.swift` reads "Seven Sigil modules... one UI module and six service modules" while the module catalog holds eight modules (1 UI + 7 service). The roadmap disposition already records the module count as eight. This is a stale source string; fixing it is a source edit outside this documentation assignment.
2. The golden test fixture `golden_mortal_d` carries the birth date 1977-11-04, which matches the canonical current-cycle birth date in `mythic-map` and the mortal-identity record in `wrw-ontology`. The fixture is synthetic product test data; the overlap is recorded as an observed cross-reference, not as an established derivation.
3. The two supplied canon records use different celestial names for the same mortal pattern (`Kaelen Vareth` with primordial `Nithruun/Thal'Azur` in `mythic-map`; `Thalrion Aesyrune` with primordial `Nythrun DalVhor` in `wrw-ontology`). Both are cited; the current name of record for Sigil use is not decided by this investigation.
