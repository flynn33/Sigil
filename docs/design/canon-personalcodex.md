# Canon and PersonalCodex

Product-owned design decisions for the canon resource layer and the
PersonalCodex delivered in Package 04. The canon is the product's typed,
shipped, integrity-verified register of the narrative and mathematical source
data the interpretation reads; the PersonalCodex is the readable, canon-backed
interpretation of a profile's ASH identity. This is a design record, not a
promise of metaphysical truth: the interpretation is deterministic software
over pinned sources, carries provenance, and is never presented as fact about
a person.

## Naming: the compound is always PersonalCodex

The canonical compound for this product record is spelled `PersonalCodex` in
prose and identifiers, `personal_codex` for snake-case keys, and `personalcodex`
for the lowercase card and record id. The final word is never written on its
own, and never as a spaced or hyphenated form. The product's own guardrail
blocklists the standalone spelling of that final word, so the forms above keep
the guardrail from flagging the product's own vocabulary and keep the vocabulary
unambiguous in the project record.

## Scope and non-goals

Package 04 delivers two things and nothing else: a typed, integrity-verified
canon resource layer (`RFSigilCanon`) and the PersonalCodex record built from
it (`RFSigilPersonalCodex`). The PersonalCodex is a separate local product
record. It is not a payload the visible or hidden Sigil must carry, it is not
a mandatory metadata carrier, and it is not a sidecar that restores the removed
personal-data embedding requirement. The additional embedding requirement
remains removed, not deferred.

Non-goals: no network, no sync, no upload, no world-simulation runtime, and no
generic prose in place of the typed canon. The final mathematical glyph
materialization (the authoritative geometry behind the Sigil Reading) remains
in Package 05; Package 04 records a one-way provenance link to it and nothing
more.

## The canon resource layer

`SigilCanonLoader` loads the canon from the product-owned resource bundle in
four fail-closed steps:

1. Decode the canon manifest — the provenance registry. It names each source,
   its `version`, its SHA-256, its `mode`, its `resourcePath` (for raw
   sources), and its `role`. The manifest is the product's canonical data
   register.
2. For each `resource-raw` source, re-hash the shipped file at load and fail
   closed if it does not match the manifest SHA-256. The shipped data is the
   canonical data, or the load fails; there is no substitute-a-value path.
3. Decode the raw resources into typed models and structurally validate the
   required tables (fail closed on a missing or malformed table).
4. Assemble the aggregate: the decoded celestial generator, the decoded mythic
   map, the typed nine-plane taxonomy, and the source registry.

The five sources and their modes (recorded in `canon-manifest.json`):

| Source id | Mode | Role |
| --- | --- | --- |
| `celestial-gen` | resource-raw | Celestial name generator: life path, dominant plane, wolf score, weekday archetypes, heritage priority, name and epithet templates, and numerology prose. |
| `celestial-gen-pseudo` | resource-raw | Algorithm-level specification of the celestial name generator; deterministic syllable selection seeded by the mortal name. |
| `mythic-map` | resource-raw | Master mythic mapping: White and Dark Wolf as complementary dual attractors (not moral poles), angels, lucifer, trials, and the balance principle. |
| `nine-planes` | typed-embedded | Nine planes with mathematical types and roles, encoded as typed product models (fixed order, validated at load). |
| `wrw-ontology` | typed-embedded | WRW merged ontology: axioms, planes, pattern-vector model, existence potential, branching dynamics, celestial-identity, bloodline-resonance, and plane-attunement semantics, encoded as typed product models. |

`resource-raw` sources are re-hashed at load (the shipped bytes must match the
manifest SHA-256). `typed-embedded` sources carry their upstream file identity
in the manifest for provenance and are checked structurally at load, not
re-hashed, because their data is compiled in. A missing required table, or a
raw-source hash mismatch, is a `SigilCanonError` — never a default value.

The provenance digest is a stable, order-independent hash of the source
registry (each source's identity, version, SHA-256, and role), so a
source-version change is visible without depending on array order. It is
exposed on the loaded canon and copied into every PersonalCodex record's
provenance section.

Resource lookup is layout-agnostic: the loader resolves both the manifest's
declared subdirectory (`canon/...`) and the flattened bundle layout produced by
the SwiftPM resource rule, so the same shipped file resolves under either
packaging. See the loader's `resourceURL`.

## Deterministic celestial naming

The celestial name generator reference is pinned at model `v1.0.0` and
algorithm `v1.0.1`; its source identity is recorded in the canon manifest. The
model is decoded from the shipped resource and structurally validated at load
(nine planes with non-empty numerology values; all seven weekday archetypes;
the required heritage families; non-empty root and per-plane syllables; the
white/dark/balanced wolf syllable pools; all four wolf-balance modifier tables;
per-plane and per-wolf numerology fragments; and at least one epithet template).

`SigilCelestialNameGenerator` derives a celestial name, epithet, dominant
plane, wolf score and category, weekday text, heritage-used, and numerology
prose from the same normalized signals the identity pipeline consumes
(heritage, birth date, weekday, birth-time bucket, hair, eyes, and the mortal
name as a deterministic seed). The output is deterministic: the same input
always yields the same name and the same record inputs. Nothing is looked up
from a reference character.

## Reference characters are not users

The celestial generator source carries named reference-character entries. In
this product they are **verification fixtures only**: they document the
generator's behavior at known inputs. They are never decoded into runtime
identity models, the generator never emits a reference name for a real
profile, and a test asserts that no reference-character name is ever produced
from a profile. A reference character is documentation of the algorithm, not a
celestial identity, and never a user.

## The PersonalCodex record

`SigilPersonalCodexService.build(for:)` derives the record by running the real
identity pipeline (the authoritative hidden geometry) and the deterministic
celestial naming, then composing the WRW / mythic-map interpretation with full
source provenance. The record is deterministic (no clock, no randomness), so
the same input always yields the same record and the same digest. Its sections,
human-readable first, are:

- **Mortal Incarnation** — the profile's own civil inputs (name, date, time,
  city, birth order, heritage, ancestral surnames, weekday).
- **Numerology Profile** — the standard numerology vector (life path and
  preserved master numbers, expression, soul urge, personality, birth day,
  birth-order ordinal/total, weekday).
- **ASH Identity** — the resolved nine-bit ASH state (bits, packed form,
  codeword classification, orbit, dominant plane, stability) plus a
  **one-way** link to the canonical geometry digest. The link points from the
  record to the geometry; the glyph never hashes back to the record.
- **Plane Attunement Vector** — the nine-plane vector with per-plane math type,
  role, weight, and a deterministic pressure state (dominant/rising/latent/
  dormant).
- **Celestial Class / Origin** — a canon-derived class over the real dominant
  plane and wolf category, with the pipeline's temporary basis id retained for
  provenance (the two are distinct, not conflated).
- **Celestial Name and Epithet** — the deterministic name and epithet with
  their plane, wolf, weekday, and numerology context.
- **Wolf Balance (both rules)** — the source rule and the pipeline rule are
  recorded side by side, with the divergence made explicit (see below).
- **Bloodline / Heritage Resonance** — lineage pressure with per-family weights
  and a status; explicitly **not** a destiny claim (the WRW
  `bloodline_as_static_class_lock` guardrail is honored).
- **Trials / Branch Echoes** — bounded symbolic interpretation from the WRW
  branching semantics and the mythic trials; a static profile carries no
  runtime branch history, so nothing is a fabricated or simulated life event.
- **Gifts, Burdens, Thresholds** — bounded symbolic framing from the dominant
  plane's keywords and the wolf category; not factual claims about the person.
- **Sigil Reading** — **explicitly incomplete** pending the Package 05
  canonical geometry; it records only the one-way provenance link to the
  canonical geometry digest.
- **Provenance** — the manifest version, the algorithm-specification SHA-256,
  the full source registry, and the provenance digest.

The record carries an **acyclic digest**: a hash over every section except the
digest itself, so a single tampered field is detected by `validate(_:)` (which
also checks the schema identity, required provenance, the present
canonical-geometry link, the still-incomplete Sigil Reading, and recomputes the
digest). `canonicalData(_:)` emits sorted-key JSON for deterministic storage;
`storageIdentity(for:)` keys the record by the profile's **storage id** (never
the profile's mathematical hash), consistent with Package 03's storage-identity
separation; `persist(_:for:)` writes through the local-only encrypted store and
a nil persistence service is a truthful failure, never a success.

## Wolf balance: both rules, divergence explicit

Two independent wolf rules are recorded and their disagreement is made explicit
rather than silently reconciled:

- **Source rule** (celestial generator `v1.0.0`): white if the score is
  `>= 1.0`, dark if `<= -1.0`, else balanced.
- **Pipeline rule** (`sig.wolf.band.v1`): balanced when `|white − dark| <= 0.12`.

The record stores a `RuleReading` for each (category, quantized score, and the
rule's stated threshold) and a `divergent` flag set when the two assign
different categories. The White and Dark Wolves are complementary attractors,
not moral poles (the mythic-map balance principle). No rule is dropped or
merged to force agreement.

## Diagnostics are redacted by construction

`SigilPersonalCodexService` takes the collector as an optional dependency (no-op
when unset) and instruments the build as the tracked operation
`sigil.personal_codex.build`. It records only coarse, non-sensitive facts —
`recordType`, the outcome, a `failureCategory` on failure, and a derived
`dominantPlane`/`wolfCategory`. The profile name, birth date, profile hash, and
wolf score are never recorded, and on a fail-closed identity-unavailable path
only the missing field names are recorded. A `PersistDiagnosticsNeverLeakSensitiveData`
test proves a capturing collector sees no sensitive material. The pure, I/O-free
`readiness` drives the `personalcodex` dashboard card. See
[diagnostics](../diagnostics.md).

## Verification and limits

Host tests: `CanonResourceTests` (5 — load succeeds and is structurally valid;
the nine-plane taxonomy has nine planes in fixed order; the provenance digest is
deterministic and version-sensitive; a missing manifest fails closed; a
tampered resource fails its hash check), `CelestialNamingTests` (11 — the
life-path-dominant plane, the three wolf categories, heritage priority,
deterministic reproduction and stability, a Unicode name is deterministic and
valid, no reference-character name is ever produced, and name length bounds),
`PersonalCodexTests` (9 — build succeeds with all sections, the Sigil Reading
is explicitly incomplete, the wolf divergence is documented, deterministic
build, bloodline is not a destiny claim, trials are bounded and not fabricated,
the provenance digest matches the canon, and `validate` accepts a well-formed
record and rejects a tampered one), and `PersonalCodexPersistenceTests` (4 — a
build/encode/save/load/decode/validate round trip, a failed save is never
reported as success, the storage identity uses the profile id not the hash, and
persist diagnostics leak no sensitive data).

What a host unit test does **not** prove: the reference generator's named
outputs are fixtures, not evidence of universal uniqueness or of a metaphysical
claim; and device/simulator qualification of the persistence path remains the
owner's work. The full iOS-simulator `xcodebuild` test was not re-run in this
session (recorded honestly, not claimed); the guardrail `xcodebuild -list`
confirms the regenerated project is well-formed and target membership is
complete.

## Source references

- `Sources/RFSigilCanon/SigilCanonLoader.swift`, `SigilCanonResource.swift`,
  `SigilCelestialCanonModels.swift`, `SigilMythicMapModels.swift`,
  `SigilNinePlaneTaxonomy.swift`, `SigilWRWCanonModels.swift`
- `Sources/RFSigilCanon/Resources/canon/canon-manifest.json` (and the shipped
  raw resources it registers)
- `Sources/RFSigilPersonalCodex/SigilPersonalCodexService.swift`,
  `SigilPersonalCodexModels.swift`, `SigilCelestialNameGenerator.swift`
- `Tests/SigilTests/CanonResourceTests.swift`, `Tests/SigilTests/CelestialNamingTests.swift`,
  `Tests/SigilTests/PersonalCodexTests.swift`, `Tests/SigilTests/PersonalCodexPersistenceTests.swift`
- Provenance register: [source-to-output map](../ash-trace/source-to-output-map.md)
- Companion design: [design/secure-local-storage.md](secure-local-storage.md)
  (the persistence route the record is stored through)
