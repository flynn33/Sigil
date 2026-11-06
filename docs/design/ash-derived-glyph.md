# ASH-Derived Canonical Glyph

Product-owned design decisions for the visible glyph delivered in Package 05. The
visible glyph is now the **canonical ASH branch geometry**: the profile's decoded
ASH state is resolved to a branch message, and the visible vector paths are a
deterministic, source-backed branch fan projected from the canonical topology.
The temporary digest-parameterized renderer (the stand-in the earlier packages
labeled as such) is gone. This is a design record, not a promise of metaphysical
truth: the glyph is deterministic software over pinned, integrity-verified
sources.

## Scope and non-goals

Package 05 delivers one thing and nothing else: replace the bounded visible
renderer with the canonical ASH branch geometry, preserve the deterministic
generation and the existing quality, integrity, and presentation boundaries, and
complete the Package 04-deferred PersonalCodex Sigil Reading against the now-real
geometry.

Non-goals, preserved as hard boundaries:

- No new third-party runtime dependency. `RFSigilVisibleGlyph` uses Foundation and
  CryptoKit only. The branch topology is shipped as a product-owned resource with
  its own provenance manifest, not fetched from any source repository.
- No new internal target dependency. `RFSigilVisibleGlyph` remains independent of
  `RFSigilCanon`. The PersonalCodex completion adds **no** new edge:
  `RFSigilPersonalCodex` already imports `RFSigilVisibleGlyph` and `build(for:)`
  already holds the artifact.
- No reintroduction of the removed personal-data embedding. The glyph is not a
  payload, a metadata carrier, or a sidecar. The additional embedding requirement
  remains removed, not deferred.
- No change to the hidden canonical geometry, the numerology/ASH state record, the
  APS coordinate adapter, the digest scheme, or the quality-gate limits. The
  visible side is what changes; the canonical identity data is untouched.

## The branch topology resource

The canonical topology is a full ternary branch tree: depth 0-4, 121 nodes, 81
leaves, with 16 well-formed branch messages (the depth-4 leaf paths) and 16
codewords. It ships in `RFSigilVisibleGlyph` as:

- `Resources/ash/branch-topology.json` — the topology (nodes, edges, leaves,
  messages, codewords), re-hashed at load.
- `Resources/ash/ash-manifest.json` — a product-owned provenance manifest: the
  source SHA-256 of the topology file and the provenance of its origin.

`SigilBranchTopologyLoader` loads it in four fail-closed steps:

1. **Decode** the JSON into the manifest model and the topology model.
2. **Re-hash** the shipped topology file and compare its SHA-256 to the manifest.
   Any mismatch throws `resourceHashMismatch`; the shipped data is the canonical
   data or the load fails.
3. **Decode** the topology into typed models (`SigilBranchTopology`).
4. **Structurally validate** the tree: node/leaf counts, a single root, parent
   links resolve, finite coordinates, `state == codeword` at the nodes that carry
   one, exactly 16 well-formed messages, and 16 codewords. Any structural failure
   throws.

Generation then **throws `branchTopologyUnavailable`** rather than substituting a
fabricated renderer: if the topology is missing, mismatched, or structurally
invalid, the visible glyph is not produced. There is no silent fallback.

## The message seam: reference codeword to APS codeword

The 16 branch codewords form a `[9,4,4]` code. The profile's decoded ASH state is
resolved to a **branch message** through a product-owned seam. The seam is the
**unique mapping** that carries the reference codeword set (the 16 branch
codewords) exactly onto the product's APS-native `[9,4,4]` codeword set
(`SigilAshCodewordSet.nativeTuples`).

The seam's properties are pinned by test:

- It is a 16<->16 **bijection** (every reference codeword maps to exactly one APS
  codeword and vice versa).
- Every derived APS word has bit `b8 == 0` (the APS native convention), so the
  derived set is exactly the product's APS codeword set, not a translate of it.
- The minimum distance of the derived set is 4.

The seam is **derived at load** from the shipped topology resource and the product
codeword set, and it is **distinct** from the product's `b6 <-> b7` coordinate
adapter (`SigilCoordinateAdapter`): the coordinate adapter is an involution over
all 512 states that commutes with XOR-by-codeword; the message seam is a mapping
between two specific 16-element codeword sets. They are different objects and are
not conflated.

## Deterministic, source-backed selection and completion

Per message, the visible glyph is a **branch fan**: a set of leaf edges selected
from the canonical topology. Selection is deterministic and source-backed:

- The candidate leaf fans are the leaf sets reachable within the presentation
  budget (**10...14 strokes**).
- The selected fan is the **smallest** in-budget fan whose **real** segment
  crossings are within the quality limit (**<= 3**). The major-crossing count is a
  real, recomputed proper-interior intersection count over the rendered geometry,
  not a synthetic stand-in and not a caller-provided number.
- **Sparse channels are completed deterministically** from adjacent messages,
  shifted by the candidate index. Collision resolution therefore changes the
  geometry: advancing the candidate advances the selection, so two profiles that
  share a profile-linked visible signature are resolved apart on the next
  candidate.

The completion is essential for most channels: the real per-channel leaf counts
total 81 across the 16 messages (no channel is at the budget ceiling), so the
selection and completion mechanism is load-bearing, not a corner case. All 16
messages are verified to yield a valid fan (candidate 0 all valid at 10-14 edges
with <= 3 crossings; candidate 1 all valid; all 16 collisions distinct).

A missing message, or an out-of-budget fan, **fails closed**: the quality gate
rejects the result rather than fabricating geometry.

## Geometry-only collision signature

Two different collisions are recorded:

- The **profile-linked visible signature** (unchanged): the digest over the
  rendered vector paths and the profile identity. The candidate loop advances on
  this, so it is the identity linkage.
- The **geometry-only collision signature** (new): a hash of the **quantized
  segment set**, independent of the profile digest. It is order-invariant (a
  permutation of the same segments gives the same signature), it distinguishes
  genuinely different geometries, and it is the cross-profile data-quality
  identity: two profiles that render the same geometry share the signature even
  though their profile-linked signatures differ. It is recorded on
  `VisibleStyleMetadata.geometryCollisionSignature`.

## Real-crossing verification

Crossings are counted as **proper interior** segment intersections only. A
degenerate contact (shared endpoint or collinear overlap) is not a crossing. The
count is recomputed from the rendered geometry at selection time, so the
major-crossing value in the artifact is always the real count over the real
paths, verified against the quality limit before the artifact is returned.

## PersonalCodex Sigil Reading completion

The Package 04 PersonalCodex recorded a Sigil Reading that was explicitly
incomplete, pending the canonical geometry. Package 05 completes it:

- `SigilReadingSection` gains `selectedGeometrySignature` and is now
  `complete == true`.
- `selectedGeometrySignature` records the **geometry-only identity** of the
  selected visible branch geometry (the picture the glyph renders) in addition to
  the one-way link to the canonical geometry digest.
- The link is **one-way**: the glyph does not hash back to the PersonalCodex, and
  the acyclic record digest is unchanged in construction (`digestPayload()` already
  covers the whole section, so the new field is inside the digest boundary).
- The PersonalCodex validator now requires `complete == true` and a non-empty
  signature, and the stale identity test was corrected: the master number is
  **annotation-only** (preserved in the numerology record and reduction
  provenance, not driving a visible stroke). The branch-derived glyph has no
  numerology accent path, which matches the test's own name better than the prior
  behavior.

No new target dependency was introduced; `RFSigilPersonalCodex` already imports
`RFSigilVisibleGlyph`.

## Boundaries preserved

- **F-08 (intact authoritative content):** the hidden canonical geometry, the
  numerology/ASH state record, the APS coordinate adapter, and the digest scheme
  are untouched; the visible side is re-derived from the canonical topology.
- **F-12 (canon constraints):** `RFSigilVisibleGlyph` remains independent of
  `RFSigilCanon`; the topology is a product-owned resource, not a canon table, and
  no canon dependency was added.
- **Determinism:** fixed input, source/policy versions, and declared
  candidate-selection context reproduce the same geometry.
- **Integrity:** the topology is re-hashed and structurally validated at load; a
  tampered resource fails closed.
- **Presentation:** Flare styling does not mutate canonical identity or vector
  path data; the geometry-only signature is a data-quality identity, not a
  presentation effect.
- **No payload:** the glyph carries no personal-data payload, metadata carrier, or
  sidecar; the removed embedding requirement is not reinstated.
