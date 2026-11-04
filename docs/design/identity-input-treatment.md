# Sigil Identity and Input Treatment — Design Specification

**Status:** Reviewed planning artifact (Package 01 planning pass, 2026-11-03). This document is design, not implementation: no code, test, dependency, version, or schema change is made by it. It records the product-owned decisions that the Package 02 identity pipeline implements.
**Inputs:** `docs/ash-trace/findings-and-next-change.md` (F-01, F-02, F-04, F-05, F-06, F-12, restated 2026-11-03), `docs/system-realization/` (linked contract set), `docs/decisions/2026-11-03-autonomous-phase-sequence.md` (delegated in-scope engineering latitude), the Raven Forge Development 0.8.0 policy binding, and the product design notes carried by the Package 01 instruction bundle.
**Labeling rule used throughout:** **PRODUCT POLICY** = a Sigil-owned decision recorded here (stable identifier, versioned, tested). **UPSTREAM** = fixed source semantics from a pinned authority (cited, never reinterpreted). **ISOLATED CONFLICT** = a genuine upstream source tension that remains visible and unresolved by this document.

## 1. State formalization (resolves F-01)

**PRODUCT POLICY `sigil-state-form.v1` — full nine-coordinate `F2^9` is the product formalization.**

- The product record uses the full 512-state nine-bit universe, with all nine coordinates first-class and no coordinate re-derived as parity or control. This matches the APS canonical contract (pinned `50d7e5ab`, 1.0.0-rc.3: `ash-state-space.pseudo.md` R1 realignment) and the product guardrail policy hard rule ("treat full F2^9 state space as canonical"; the superseded projection form is not canonical implementation authority).
- The ASH-Model reference application's integrity policy — the 256-state parity subset `E` with its always-zero eighth coordinate in the one-based `x1..x9` convention — is an **UPSTREAM application-specific policy of the image/video reference domain**, not a product constraint. It must not be imposed on personal-profile inputs (the reference pipeline's parity-derived coordinate is image-domain measurement, per the restated F-01).
- **ISOLATED CONFLICT (kept visible, not resolved here):** the restated F-01 records that the two sources state different domains (reference-application integrity policy vs all-first-class-coordinate model) and that the serialized 16-codeword tables agree exactly under a proven final-two-coordinate involution. This document does not declare which upstream framing is "more correct"; it records the product choice (full `F2^9`) and the seam (the coordinate adapter below). Any future upstream clarification is a separate source event, not a silent edit of this record.

## 2. Coordinate adapter (resolves the F-01 seam)

**PRODUCT POLICY `sigil-coordinate-adapter.v1` — the named, explicit, boundary-documented translation between the two source coordinate conventions.**

- Source conventions (UPSTREAM, preserved exactly):
  - ASH-Model reference tables: one-based `x1..x9`, coordinate 1 most significant, `x8 = 0` in every codeword, constant within each orbit.
  - APS native tables: zero-based `b0..b8`, `b8 = 0` in every codeword.
- The adapter is the final-two-coordinate swap: `swap(x8, x9)` on the one-based table (equivalently, `swap(b6, b7)` on the zero-based table). Verified properties (fresh independent calculation, 2026-11-03, evidence in the trace ledger `corrections_2026_11_03` field and the external evidence root):
  - It is an involution on all 512 states.
  - It commutes with XOR-by-codeword for all 512 × 16 state/codeword pairs.
  - Applied to the ASH-Model 16-codeword table, it produces exactly the APS table (e.g. ASH `000011101` ↔ APS `000011110`).
- **Boundary rule:** the adapter is applied only at the explicitly named seam where the product touches ASH-Model reference data (reference CSV/JSON artifacts). Product-owned state is always stored and computed in the APS native convention (`b0..b8`, zero-based, ninth coordinate `b8`), which is the canonical contract convention. Source coordinate labels are never erased, never silently swapped in stored data, and no table is regenerated in the wrong convention to make a test pass.
- **Verification (Package 02):** round-trip (`adapter(adapter(s)) == s` for all 512 states), commutation with XOR (all 512 × 16 pairs), exact-table equality at the seam (16/16 members), and orbit-invariance (the swap maps the 32 orbits onto the 32 orbits).

## 3. Profile-to-state mapping (resolves F-02)

**PRODUCT POLICY `sigil-profile-adapter.v1` — a named, versioned Sigil profile adapter over normalized numerology and input signals.**

**No retrieved source supplies a personal-profile-to-`F2^9` mapping** (F-02: the ASH-Model coordinates 1–8 are image/video-domain measurements; the canonical profile-side material is the celestial generator's life-path/plane/wolf/weekday/heritage behavior). This adapter is therefore a **product design choice, not an ASH theorem**, and is labeled as such everywhere it appears (code comments, diagnostics, documentation). It is versioned; a new mapping is a new version (`v2`, …), never a silent edit.

### 3.1 Normalized signals (inputs to the adapter)

| Signal | Stable ID | Derivation | Class |
|---|---|---|---|
| Life-path root | `sig.signal.life_path` | Full-date digit method (§5.1), fully reduced to 1–9; master annotations recorded separately (§4) | Conventional numerology |
| Birth-day root | `sig.signal.birth_day` | Day component of the civil birth date, fully reduced to 1–9 | Conventional numerology |
| Expression root | `sig.signal.expression` | Letter-value table (§5.2) over the normalized full name (first + last), fully reduced to 1–9 | Conventional numerology |
| Soul-urge root | `sig.signal.soul_urge` | Letter values of the vowels in the normalized full name, fully reduced to 1–9 | Conventional numerology |
| Personality root | `sig.signal.personality` | Letter values of the consonants in the normalized full name, fully reduced to 1–9 | Conventional numerology |
| Weekday | `sig.signal.weekday` | Civil-calendar weekday of the birth date (1=Monday … 7=Sunday), §5.1 | Deterministic calendar derivation |
| Wolf balance | `sig.signal.wolf` | Canonical white/dark weights from the cited generator modifier tables and time buckets (§6), with category `balanced` / `white_dominant` / `dark_dominant` (existing 0.12 threshold retained as product policy) | Supplied-generator behavior |
| Birth order | `sig.signal.birth_order` | Typed (ordinal, total), validated `1 ≤ ordinal ≤ total`; explicit unknown state (§7) | Versioned Sigil input policy |
| Parental birth order | `sig.signal.parental_order` | Typed (ordinal, total) per parent side; explicit unknown states | Versioned Sigil input policy (new) |
| Heritage | `sig.signal.heritage` | Normalized family weights (§6.3), canonical ordering | Supplied family rules + product normalization |
| Ancestral surnames | `sig.signal.ancestral_surnames` | Normalized list of specific ancestor surnames; treated as provenance references with weight, not class locks (F-12 bloodline-resonance canon) | Versioned Sigil input policy (new) |
| Time bucket | `sig.signal.time_bucket` | Derived from known birth time: `dawn` / `day` / `dusk` / `night` (canonical buckets, §5.3) or `unknown` | Versioned Sigil input policy |
| Location precision | `sig.signal.location` | `unknown` / `place` (manual name) / `region` / `coordinate` (user-supplied precision, §5.4) | Versioned Sigil input policy |

### 3.2 Coordinate assignment (the v1 rule table)

Each coordinate takes exactly one named parity projection of one named signal. Parity (`value mod 2`) is the minimal deterministic binary projection; it is a **product policy choice**, not a source rule. No hidden weights, no omitted signals, no digest bytes in the semantic path.

| Coordinate (APS native, zero-based) | Rule (stable ID) | Signal |
|---|---|---|
| `b0` | `coord.life_path.parity` | `sig.signal.life_path` mod 2 |
| `b1` | `coord.birth_day.parity` | `sig.signal.birth_day` mod 2 |
| `b2` | `coord.expression.parity` | `sig.signal.expression` mod 2 |
| `b3` | `coord.soul_urge.parity` | `sig.signal.soul_urge` mod 2 |
| `b4` | `coord.personality.parity` | `sig.signal.personality` mod 2 |
| `b5` | `coord.weekday.parity` | `sig.signal.weekday` mod 2 |
| `b6` | `coord.wolf.white_noninferior` | 1 iff white weight ≥ dark weight (category `balanced` counts as white-noninferior) |
| `b7` | `coord.birth_order.ordinal_parity` | `sig.signal.birth_order.ordinal` mod 2 |
| `b8` | `coord.heritage.primary_index_parity` | index (0-based) of the primary heritage family in the canonical family order (germanic, celtic, slavic, mixed), mod 2 |

- **Availability coupling:** a coordinate whose signal is unavailable (explicit unknown/unsupported, §7) makes the **identity record unavailable, fail-closed**, for the affected derivation class — the state is not computed with a fabricated bit. Which derivations can continue is listed in §7.
- **Collision policy:** finite-state collisions are expected and accepted (512 states over many profiles). Distinctness fixtures assert selected known pairs, not universal uniqueness. An arbitrary valid state is not automatically a codeword; the product never "corrects" a valid profile state to the nearest codeword (Package 02 orbit/codeword semantics follow the canonical contract: orbit enumeration, classification, decoding only in source-defined contexts).
- **What this replaces:** the current digest-byte substitutes (plane vector from `digestBytes[0..8] % 89 + 11`, wolf balance from `digestBytes[9..10]`, name scalar sums) are superseded by this mapping when Package 02 implements it. Until then, current behavior is retained (F-08 boundaries stay intact).

## 4. Master-number policy (resolves F-05)

**PRODUCT POLICY `sigil-master-numbers.v1` — full reduction governs derivation; 11/22/33 are preserved annotations.**

- The life-path value used for plane mapping and state derivation is the **fully reduced** digit root (1–9), matching the canonical celestial generator's full-reduction behavior (UPSTREAM).
- When the un-reduced date total (or any recorded intermediate total) equals 11, 22, or 33, the record preserves it in `preservedMasterNumbers` (existing field) as **product metadata annotation** with the stable source label `sig.master.preserved`. The accent/ornament path keyed to master numbers (current service behavior) continues to read the annotations, not the reduced root.
- This separates the two roles without confusing them: reduction and annotation coexist in one record; intermediate totals that reach a master number mid-reduction are recorded in a provenance list (new field in Package 02), and the stopping rule is explicit: reduction always proceeds to 1–9; preservation never alters the reduced value.
- Divergence recorded: the canonical generator has no preservation rule; the product's preservation is product metadata, not a claim about upstream semantics.

## 5. Date, weekday, time, place (resolves F-06 date/time/place topics)

### 5.1 Birth date and weekday

**PRODUCT POLICY `sigil-civil-date.v1`.**
- The birth date is a **civil date** in the proleptic Gregorian calendar, user-recorded as `YYYY-MM-DD`. Parsing is timezone-free: the civil date itself is the value; no host-default timezone or locale may shift it. Unknown/absent date → explicit unknown state (fail-closed for all date-derived signals).
- **Full-date digit method (retained, now normative):** `dateTotal = sum of the eight digits of YYYYMMDD`. Life-path = full reduction of `dateTotal` with master-number preservation (§4). Birth-day root = full reduction of the day component. Leap dates are valid inputs; no normalization of the calendar value itself.
- **Weekday:** derived deterministically from the civil date by the Gregorian calendar (weekday of that date, 1=Monday … 7=Sunday). It is a pure function of the date — no timezone, no host clock. The derived weekday is validated against any user-supplied weekday; a mismatch is a validation failure (explicit diagnostic), not a silent override.

### 5.2 Name normalization and letter values

**PRODUCT POLICY `sigil-letter-values.v1`.**
- Supported script: Latin (A–Z). Normalization pipeline: NFKC → casefold to base letter → ignore punctuation, digits, whitespace, and diacritic-marked characters are transliterated to their base letter (é→e, ñ→n, ü→u, ß→ss is **not** applied; ß→s single letter, recorded as v1 choice). A name with any letter outside the supported set → `unsupported_script` state for the name-derived roots (fail-closed; no scalar sum, no default person).
- **Letter-value table (exact, conventional Pythagorean):** A=1 B=2 C=3 D=4 E=5 F=6 G=7 H=8 I=9, J=1 K=2 L=3 M=4 N=5 O=6 P=7 Q=8 R=9, S=1 T=2 U=3 V=4 W=5 X=6 Y=7 Z=8.
- **Name split:** `firstName` and `lastName` are separate canonical fields (F-06); the expression/soul-urge/personality roots run over the combined normalized name (first + last, order-preserving).
- **Vowel/consonant and Y policy:** vowels = A E I O U and **Y is always a vowel** (v1 deterministic rule; stable ID `sig.y.always_vowel`; the alternative context-dependent Y conventions are recorded as non-adopted). Soul urge = vowels only; personality = consonants only; expression = all letters. (Supersedes the current scalar-sum behavior over name/eyes/hair strings — F-04 — which is conventional-numerology in name only, not in substance.)
- Empty name (both fields empty/unknown) → name-derived roots unavailable (fail-closed), not a fabricated default.

### 5.3 Birth time

**PRODUCT POLICY `sigil-birth-time.v1`.**
- `birthTime` is optional canonical user-confirmed data: exact time string as recorded, or explicit `unknown`. It is never back-filled, never rounded, never defaulted.
- `time_bucket` derives from a known time using canonical buckets (dawn 04:00–07:59, day 08:00–15:59, dusk 16:00–19:59, night 20:00–03:59, v1 definitions recorded) in the **user-stated** local zone when the user supplies one; otherwise the bucket is `unknown`. Uncertain historical timezone is preserved explicitly, not resolved by host default.
- The bucket feeds the wolf score per the cited generator's time-bucket modifiers (§6) — supplied-generator behavior, labeled as such.

### 5.4 Birth place and geocoding scope

**PRODUCT POLICY `sigil-birth-place.v1`.**
- `birthPlace` is optional canonical user-confirmed data with explicit precision: `place` (manual name), `region` (manual), or `coordinate` (user-supplied, at the precision the user actually gives).
- **Privacy boundary (retained):** offline manual place/coordinate entry is the default development and product path; a **mocked geocoder** is the test/development double. Apple geocoding is an **explicit user-requested system-service operation** (user-initiated, no background fetch, no profile upload); it belongs to the Package 06 experience scope and is not part of the identity derivation — location precision influences only the recorded signal, never a network call.
- No geocoder result is ever written back into canonical identity fields without explicit user confirmation (service results stay separate from canonical user-confirmed data).

## 6. Wolf balance, heritage, surnames (resolves F-06 remaining topics)

### 6.1 Hair/eyes and wolf

**PRODUCT POLICY `sigil-hair-eyes.v1`.**
- `hair` and `eyes` are canonical categorical fields with a fixed category table (v1: hair — black, dark-brown, brown, light-brown, blond, red, gray, white, mixed, other, unknown; eyes — black, brown, hazel, green, blue, gray, amber, violet, mixed, other, unknown). Aliases normalize deterministically (casefold, NFKC, alias table with stable IDs); unrecognized values → explicit `unsupported_category` state (fail-closed for the affected contribution), never a Unicode-sum fallback.
- **Wolf balance (supplied-generator behavior, labeled):** the white/dark weights come from the celestial generator's explicit modifier tables for hair, eyes, and time bucket (cited source data, versioned with the generator reference), not from scalar sums of strings. Category thresholds retain the existing 0.12 band as product policy `sig.wolf.band.v1`. Wolves are complementary opposites, not moral poles; the overwhelmed state is temporary decoherence (F-12 canon constraint governs all wording).

### 6.2 Heritage

**PRODUCT POLICY `sigil-heritage.v1`.**
- Heritage entries normalize deterministically (casefold, NFKC, trim, collapse internal whitespace, alias table). Canonical family groups retain the product mapping (germanic / celtic / slavic / mixed; v1 alias table: swedish/german/english/scandinavian→germanic; irish/scottish/welsh→celtic; polish/ukrainian/russian/slovak→slavic; all else→mixed).
- Multi-value input: duplicates collapse with count; weights are the existing count-normalized weights; canonical ordering is weight-descending then family-name-ascending (retained, now normative). No biological or moral claims in any record or export.

### 6.3 Birth order and parental order

**PRODUCT POLICY `sigil-birth-order.v1`.**
- `birthOrder` = typed (ordinal, total) with validation `1 ≤ ordinal ≤ total`; parsing is from the user's recorded value; **absent/unknown is an explicit state, never a fabricated `(1,1)`** (the current silent default is a recorded defect this policy removes).
- `parentalOrder` (new) = typed (ordinal, total) per parent side (maternal/paternal), same validation, explicit unknown per side.
- The symbolic role of these fields in the identity (the `b7` coordinate uses birth-order ordinal parity; parental order is recorded in the provenance/annotation set and influences the PersonalCodex reading sections, not the state bits) is **versioned Sigil input policy** — it is not attributed to the celestial generator or any upstream source (per the design notes: an invented rule must not be attributed).

### 6.4 Ancestral surnames

**PRODUCT POLICY `sigil-ancestral-surnames.v1`.**
- A normalized list of specific ancestor surnames (family-side labeled where the user records it). Treatment: provenance references with weight (count-based, like heritage weights), never class locks — bloodline is pressure with references (F-12). They feed the PersonalCodex bloodline/heritage-resonance section; they do not feed state bits in v1 (documented non-influence, tested as such).

## 7. Partial input and availability (resolves F-06 partial-input topic)

**PRODUCT POLICY `sigil-partial-input.v1`.**
- Every field carries an explicit state: `present` / `unknown` (user did not record) / `unsupported` (value recorded but outside supported domain). Unknown ≠ empty string ≠ fabricated fallback.
- **Availability classes (fail-closed, no invented weighting, no silent omission):**
  - **Identity-core** (all required for the state): date (§5.1), name (§5.2), weekday (derived), wolf inputs (hair/eyes categories or documented fallback to the generator's default-modifier path if the source defines one), birth order, heritage (at least one entry; `mixed` is a valid single value). Any unavailable identity-core field → the ASH state record is unavailable with an explicit diagnostic naming the missing field(s).
  - **Annotation-only** (missing fields do not block the state): time bucket, location, parental order, ancestral surnames, master annotations. These are recorded as `unknown` in the identity record.
  - **Continuing operations:** numerology roots that do not depend on an unavailable field remain available; quality gates, digest linkage, and fail-closed validation apply to whatever is computed. The PersonalCodex renders available sections and marks unavailable sections explicitly.
- No operation may report success over a derivation that used a fabricated default; diagnostics preserve the original error (collector failure must not erase it — R-05).

## 8. Canonical identity record and serialization

**PRODUCT POLICY `sigil-canonical-record.v1`.**
- **Acyclic identity graph (one documented graph):** `NormalizedProfile → NumerologyRecord → AshStateRecord (via sigil-profile-adapter.v1; coordinate adapter only at the reference seam) → { PersonalCodexRecord, GeometryRecord } → IdentityManifest`. The manifest links digests of the produced records; a PersonalCodex reading section can be completed from the produced geometry without the geometry hash recursively depending on the final PersonalCodex hash.
- **Canonical identity inputs:** the normalized profile fields, the applied policy versions (`sigil-state-form.v1`, `sigil-coordinate-adapter.v1`, `sigil-profile-adapter.v1`, `sigil-master-numbers.v1`, `sigil-civil-date.v1`, `sigil-letter-values.v1`, `sigil-birth-time.v1`, `sigil-birth-place.v1`, `sigil-hair-eyes.v1`, `sigil-heritage.v1`, `sigil-birth-order.v1`, `sigil-ancestral-surnames.v1`), and the pinned source identities (APS canonical commit, letter-table version, codeword-set version). **Never semantic inputs:** runtime timestamps, storage IDs, diagnostic run IDs, randomized nonces, and the local database `id`.
- **`id` treatment (recorded decision):** the current `SigilProfileInput.id` (local database UUID) is a **local handle, not semantic identity**. Canonical identity derives from normalized content plus policy/source versions; two local records with the same normalized content and versions have the same canonical identity. The handle is retained for local references and exports, explicitly labeled non-semantic.
- **Serialization rules:** stable declared field order (fixed by the record definitions, not hash-sorted), NFKC-normalized UTF-8 strings, decimal integers without leading zeros, doubles quantized by the existing product quantization (recorded: round-half-away-from-zero to the fixed declared precision), declared optional fields serialized as explicit `null` (never omitted, never empty-string substituted), and a schema-version marker on the record. Encrypted storage may use fresh nonces while the decrypted canonical artifact stays byte-deterministic.
- **Compatibility:** replacing the digest-derived identity (F-03) changes the artifact digest domain for all profiles. No persisted records exist at this phase, so no stored-data migration is triggered; the compatibility surface is future persistence/export consumers, and the versioned schema marker makes the transition explicit (old artifacts are never reinterpreted under new math).
- **Digests** establish linkage, not encryption, non-disclosure, or mathematical fidelity (retained property).

## 9. Geometry and export boundaries (design notes for later packages)

- **Geometry (Package 05):** the Package 02 identity record feeds the existing product flow through the owning boundary; the old bounded renderer may temporarily consume the real identity contract, with its remaining geometry limitations labeled accurately. Canonical branch geometry (L-system `F -> FF[+F]F[-F]`, 25-degree turns, 0.72 decay, per-node state/codeword segments; deterministic candidate ranking) replaces the digest-parameterized synthesis in that package. Neither the 121-node/81-leaf semantic branch tree nor the 625-forward-symbol rendering expansion is an invented glyph invariant (F-11, corrected).
- **Export (Package 06):** canonical SVG plus an explicitly selected raster/Flare image (non-authoritative, retained); the user-selected PersonalCodex report is separate with all planned sections (mortal record, numerology, ASH identity, plane attunement, celestial class/origin, celestial name and epithet, wolf balance, bloodline/heritage resonance, trials/branch echoes, gifts/burdens/thresholds, sigil reading, export/provenance/digest). Bounded Apple-native route; exact included metadata documented per export. **No mandatory personal payload or substitute sidecar — `SIGIL-DEC-2026-10-10-NO-EMBEDDING` remains removed, not deferred (F-09).**
- **Flare:** non-authoritative rendering surface; independence from canonical identity retained.

## 10. Verification expectations (carried into Package 02)

- **Independent fixtures:** expected values computed by hand or an independent method, never produced by the implementation under test.
- **Coverage (minimum):** conventional letter values and table spot-checks; vowel/consonant split; `sig.y.always_vowel`; punctuation/Unicode/transliteration; unsupported script; zero/empty/unsupported inputs; leap dates; weekday derivation consistency (including century boundaries of the proleptic Gregorian calendar); timezone-independence of the civil date; master-number preservation and intermediate-total provenance; every retained input's declared normalization, influence, or documented non-influence (ancestral surnames, parental order, location); partial-input fail-closed classes (§7).
- **Exhaustive where applicable:** all 512 states and the 16-codeword set — coordinate adapter round-trip, XOR commutation, orbit cardinality (32 sixteen-state orbits), stable classification; decoder distance/ambiguity only in source-defined contexts. A shared parameter count does not establish codeword equality.
- **Determinism:** repeated canonical inputs with the same policy/source versions reproduce the same semantic record and serialization byte-for-byte.
- **Regressions:** caller/module/runtime tests, applicable realization checks, repository guards, SwiftPM, and the iOS Simulator Debug route; failures inspected and repaired, not snapshot-changed blindly.

## 11. Decision summary

| Former owner topic | Resolution | Class |
|---|---|---|
| (1) State formalization (F-01) | Full `F2^9` governs the product record; reference-domain parity subset stays upstream; the 8+1 vs full-9D domain distinction is recorded, not papered over | PRODUCT POLICY + ISOLATED CONFLICT (visible) |
| (2) Profile-to-`F2^9` mapping (F-02) | `sigil-profile-adapter.v1`, named/versioned, one parity rule per coordinate, no digest semantics, no invented formula presented as source | PRODUCT POLICY (explicitly not upstream mathematics) |
| (3) Master-number policy (F-05) | Full reduction governs derivation; 11/22/33 preserved as product metadata annotations | PRODUCT POLICY (divergence from canonical generator recorded) |
| (4) Input treatment rules (F-06) | §5–§7: civil date + weekday, letter table + Y policy, time/place privacy boundary, birth/parental order, heritage/surnames, explicit partial-input states | PRODUCT POLICY (per-field, stable IDs, testable) |

Genuine upstream source conflicts (the 8+1 vs full-9D framing; any canonical-profile-mapping absence) remain isolated and visible in the ASH-Trace record; nothing in this document resolves upstream meaning unilaterally.
