# Yggdrasil Engine — Developer Integration Guide (Detailed, Step‑by‑Step)

Version: 1.0  
Repository: flynn33/yggdrasil-engine  
Purpose: Full step‑by‑step instructions and runnable examples to integrate the Yggdrasil Engine math + pipelines into a real project (Unity, Unreal, Godot, server-side, or custom engine). This guide assumes you will implement the algorithms from the repo's data and pseudocode files (no hidden proprietary code required).

## Table of contents

- Goals & design principles
- Prerequisites
- Repository layout (reference paths)
- Determinism fundamentals you must preserve
- Data loading & validation
- Core runtime objects (Agent state)
- Base plane & leaf calculations (code examples)
- Sigil creation pipeline (detailed steps + example)
- ImprintKey (SHA‑256) and seeding deterministic RNG
- Deterministic RNG recommendations & sample implementations
- L‑system generation (deterministic parameter selection, expansion)
- Turtle interpreter (2D and 3D) and mesh/line output
- Gift assignment (deterministic rules)
- Rune activation pipeline (9‑bit parity → spells)
- Agent migration & Kripke ladder enforcement
- Performance & caching recommendations
- Testing & validation checklist + sample unit tests
- Integration recipes: Unity, Unreal, Godot, server
- Helpful scripts and CI suggestions
- Privacy, license and contributor flow
- Appendix: useful code snippets and references

---

## Goals & design principles

- Determinism: identical inputs must give identical outputs on any platform. Implementations must preserve hashing, BigInt parsing, endianness expectations, and RNG seeding semantics.
- Data-first: all canonical constants, rune codes, gifts, and canonical vectors are in JSON files. Load these at startup.
- Keep core math engine-agnostic: pipeline produces data (L‑system strings, vectors, gift lists) that engines render.
- Respect the Personal Use License and CLA process for contributions.

## Prerequisites

- Basic dev tooling for your target engine (Unity, Unreal, Godot) and a language runtime (C#, C++, Python, Rust).
- Ability to compute SHA‑256 and parse/format hex and binary representations deterministically.
- A deterministic RNG (recommended: Xorshift / PCG or other simple family seeded with a reproducible 64-bit value).
- JSON parsing library.

## Repository layout (reference paths)

- Root:
  - README.md (add "Code‑Agnostic Reference Pipelines")
  - USER_GUIDE.md (this file)
  - CLA.md
  - CODE-OF-CONDUCT.md
  - CONTRIBUTING.md
  - PULL-REQUEST-TEMPLATE.md
- docs / core:
  - framework-pipelines.md
  - ENGINE_OVERVIEW.md
  - INTEGRATION_GUIDE.md
  - creature-lsystem-generation.md (suggested)
- data:
  - elder-futhark-9bit.json
  - public-gift-tables.json
  - canonical-pattern-vectors.json
  - example-creatures.json
  - creature-3d-lsystem-sample.json
  - creature-lsystem-sample.json
  - agent-sigil-creation.JSON
  - rune-mapping-draft-v0.3.json (historical)
  - v0.1-legacy-cosmology.json (historical)
- schema:
  - cosmology_schema.json

---

## Determinism fundamentals (must read)

1. Hashing: Use the same SHA‑256 algorithm on the same serialized bytes. Decide and document your canonical serialization format (e.g., canonical JSON with stable key ordering, or binary struct). The repo expects SHA256(serialized metrics).
2. Hex parsing & BigInt: When converting hex to BigInt, use the same endianness (convention: big‑endian parsing of hex string to integer).
3. RNG seeding: Convert the BigInt (or other seed) deterministically to a 64‑bit seed. Document your conversion (e.g., take the low 64 bits of the BigInt in big‑endian).
4. L‑systems & string replacements: Implement exact string replacement rules: process the current string left‑to‑right and replace every character using the rules for that iteration.
5. Bit counting: Popcount on 9‑bit strings should be straightforward; ensure bit mapping/order is consistent when forming bits9 from norm vector.
6. Floating point use: Avoid platform-dependent nondeterminism from non-integer maths if you must reproduce bit-for-bit outputs between different languages. For "logical determinism" (same algorithmic outputs) float differences are usually acceptable; for strict tests use fixed-point rational arithmetic or canonical references from example files.

---

## Data loading & validation (step‑by‑step)

1. Load JSON files from /data/ at application startup. Keep them read-only and treat canonical files (e.g., canonical-pattern-vectors.json, elder-futhark-9bit.json) as authoritative.
2. Validate JSON shapes:
   - Use cosmology_schema.json to validate canonical files where applicable.
   - Example (node/ajv):
     - npm i -g ajv-cli
     - ajv validate -s cosmology_schema.json -d canonical-pattern-vectors.json
3. Cache loaded data structures in memory to avoid repeated parsing.

---

## Core runtime objects

Design the Agent state as these two vectors (names in repo: s(x), r(x)).

- s: structural vector (C, S, P, H) — stored as 4 float values in [0,1].
  - C = compressibility / coherence (alias "C")
  - S = symmetry (alias "S")
  - P = persistence / pattern (alias "P")
  - H = entropy (alias "H"), note used as (1-H) in plane formula

- r: modifier vector (E, D, A) — stored as 3 float values in [0,1].
  - E = Elemental / domain
  - D = Domain/Drive
  - A = Alignment

Simple class examples follow.

### C# (Unity) sample

```csharp
public struct AgentState {
    // s: C, S, P, H mapped to x,y,z,w
    public Vector4 s; // [0,1]^4
    public Vector3 r; // [0,1]^3

    public int BasePlane() {
        float score = s.x + s.y + s.z + (1f - s.w);
        int plane = Mathf.FloorToInt(score * 2.25f) + 1;
        return Mathf.Clamp(plane, 1, 9);
    }

    public int LeafRealm(int leavesInPlane) {
        float avg = (r.x + r.y + r.z) / 3f;
        return Mathf.Clamp(Mathf.FloorToInt(avg * leavesInPlane) + 1, 1, leavesInPlane);
    }
}
```

### C++ (Unreal) sample

```cpp
struct FYggAgent {
    FVector4 s; // C,S,P,H
    FVector r;  // E,D,A

    int32 GetBasePlane() const {
        float score = s.X + s.Y + s.Z + (1.0f - s.W);
        int32 plane = FMath::FloorToInt(score * 2.25f) + 1;
        return FMath::Clamp(plane, 1, 9);
    }
};
```

Enforce values clamped to [0,1] after applying drift.

---

## Base plane & leaf calculations (step‑by‑step)

1. Compute planeScore = C + S + P + (1 − H)
2. basePlane = floor(planeScore * 2.25) + 1
3. Clamp basePlane to [1,9]
4. Leaf realm selection uses r: average of r components or other mapping per-plane. Many implementations pick leaf = floor(avg(r) * leavesInPlane) + 1.

Be sure to follow `ENGINE_OVERVIEW.md` / `INTEGRATION_GUIDE.md` examples (they match the above).

---

## Sigil creation pipeline — in-depth step‑by‑step

The sigil creation pipeline turns personal or input data into a canonical pattern vector and a 9‑bit sigil (used for rune-like behavior and imprinting). The repo provides agent-sigil-creation.JSON pseudocode — implement it exactly if you want deterministic compatibility.

High-level steps:

1. Collect inputs: first_name, last_name, birth_day/month/year, birth_hour/minute, birth_order, parents' birth_order, birth_lat/long, optional pet names and additional_data.
2. Convert names to numeric reductions:
   - Map letters A=1..Z=26; sum ordinals; reduce to single digit using the numerology rule: repeatedly sum digits until one digit 1..9 (9 stays 9).
3. Reduce datetime: format YYYYMMDDHHmm, sum digits, reduce to single digit.
4. Reduce orders: sum birth_order + mother + father, reduce.
5. Reduce geo: floor(abs(lat)*100), floor(abs(long)*100), sum digits combine, reduce.
6. Process additional_data: each string → ordinal reduce; numbers → reduce digits; average or sum then reduce. Default 5 if empty.
7. Pet names: average reductions or use additional_reduce default.
8. Map reductions into pattern vector components:
   - H = name_avg / 9.0  (range [0,1])
   - K = date_reduce / 9.0
   - D = 1 + (order_reduce / 9.0) * 2  (maps to [1,3])
   - S = geo_reduce / 9.0
   - L = 1 + Floor(pet_avg * 111)  (maps roughly to [1, 999])
   - Clamp to the ranges: H,K,S ∈ [0,1], D ∈ [1,3], L ∈ [1,999]
9. Generate 9 normalized values for bits: norms = [norm_H, norm_K, norm_D, norm_S, norm_L, norm_H, norm_K, norm_D, norm_S] where norm_D = (D - 1)/2 and norm_L = (L-1)/998.
10. bits9 = concat( for each n in norms -> '1' if n > 0.5 else '0' )
11. parity = popcount(bits9) % 2 == 0 ? "even" : "odd"
12. seed = BinaryToInt(bits9) (or use bits9 as small integer seed)
13. L‑system for sigil:
    - axiom = parity == even ? 'F' : 'X'
    - rules chosen deterministically from RNG seeded by seed
    - angle = RNG.nextFloat() * 90 etc.
    - iterations = 3 + RNG.nextInt(4)
14. Expand L‑system and render as 2D path with turtle rules to produce the displayed sigil.

Python example function (simplified)

```python
import hashlib
import math

def reduce_to_single_digit(n):
    while n > 9:
        n = sum(int(d) for d in str(n))
    if n == 0:
        return 9
    return n

def name_to_reduce(name):
    s = sum((ord(c.upper()) - 64) for c in name if c.isalpha())
    return reduce_to_single_digit(s)

def compute_pattern_vector(first, last, birth_tuple, orders, lat, lon, pet_names, additional_data):
    first_r = name_to_reduce(first)
    last_r = name_to_reduce(last)
    name_avg = reduce_to_single_digit(first_r + last_r)
    # date reduction
    y,m,d,h,mi = birth_tuple
    date_str = f"{y:04d}{m:02d}{d:02d}{h:02d}{mi:02d}"
    date_reduce = reduce_to_single_digit(sum(int(c) for c in date_str))
    order_sum = sum(orders); order_reduce = reduce_to_single_digit(order_sum)
    lat_int = int(abs(lat) * 100); lon_int = int(abs(lon) * 100)
    geo_reduce = reduce_to_single_digit(sum(int(c) for c in str(lat_int + lon_int)))
    # pets/additional simplification omitted for brevity
    H = name_avg / 9.0
    K = date_reduce / 9.0
    D = 1.0 + (order_reduce / 9.0) * 2.0
    S = geo_reduce / 9.0
    L = 1 + int(5 * 111)  # example
    return {"H":H,"K":K,"D":D,"S":S,"L":L}
```

Important: If you implement this pipeline differently, document differences. For interoperability with other implementations use exact same rules.

---

## ImprintKey (SHA‑256) and seeding deterministic RNG

- The imprintKey is SHA‑256 of the serialized feature profile (pattern metrics).
- Decide a canonical serialization: the repo suggests Serialize(metrics.H, metrics.K, metrics.D, metrics.S, metrics.L) — use a fixed ordering and stable numeric formatting (e.g., JSON with 6 decimal places). Example canonical string: "H:0.550000;K:0.440000;D:2.220000;S:0.770000;L:123;"
- Compute SHA‑256 → hex string (lowercase).
- To seed RNG:
  - Parse hex to BigInt (big‑endian).
  - Convert to 64‑bit seed deterministically. Two common approaches:
    - seed64 = BigInt & ((1<<64)-1) (take low 64 bits)
    - seed64 = (BigInt >> 64) & ((1<<64)-1) XOR (BigInt & ((1<<64)-1)) (folding)
  - Document which you choose. Use same across languages.

Example in C#:

```csharp
using System.Numerics;
string hex = ComputeSha256Hex(metricsString);
BigInteger big = BigInteger.Parse("0" + hex, System.Globalization.NumberStyles.HexNumber);
ulong seed = (ulong)(big & ((BigInteger.One << 64) - 1));
```

Keep big-endian string parse consistent.

---

## Deterministic RNG — recommended algorithms & sample implementations

- Choose a simple, fast, reproducible PRNG: xorshift64*, xorshift128+, or PCG. Avoid System.Random for cross-platform differences.
- Provide standard implementation and seed it with the 64-bit seed above.

xorshift64* (example C#)

```csharp
public struct XorShift64Star {
    private ulong state;
    public XorShift64Star(ulong seed) { state = seed != 0 ? seed : 0xdeadbeefcafebabeUL; }

    public ulong NextUInt64() {
        ulong x = state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        state = x;
        return x * 2685821657736338717UL;
    }

    public double NextDouble() {
        return (NextUInt64() >> 11) * (1.0 / (1UL << 53));
    }

    public int NextInt(int maxExclusive) {
        return (int)(NextUInt64() % (ulong)maxExclusive);
    }
}
```

Use the same bit shifts and multiplier in all ports.

---

## L‑system generation (deterministic parameter selection, expansion)

1. Seed RNG from imprintKey (as above).
2. Deterministic choices:
   - axiom = RNG.Choose(["F","X","A"])  (use RNG.NextInt)
   - rules set selected by RNG. Choose rule variants deterministically.
   - angle = baseAngle + RNG.NextDouble() * range
   - iterations = base + RNG.NextInt(range)
3. Expansion: implement the L‑System expansion exactly: for iteration in 1..iterations, build new string by replacing every char by rules[char] or char if no rule.

Pseudo-code (deterministic):

```pseudo
current = axiom
for i = 1..iterations:
  next = ""
  for each char c in current:
    if c in rules:
      next += rules[c]
    else:
      next += c
  current = next
return current
```

Large expansions can explode in memory; for production, stream expansion into turtle interpreter rather than keep full string if possible.

---

## Turtle interpreter — 2D and 3D

- 2D interpretation uses commands:
  - F: move forward and draw line
  - f: move forward without drawing
  - +: turn left by angle
  - -: turn right by angle
  - [: push state (pos, angle)
  - ]: pop state
- 3D adds:
  - ^ / &: pitch up/down
  - / \: roll left/right
  - maintain both yaw (azimuth) and pitch for forward vector

2D Python turtle interpreter (concept)

```python
import math

def interpret_2d(expanded, angle_deg, step_length=1.0):
    pos = (0.0, 0.0)
    angle = 0.0  # degrees, 0 = right
    stack = []
    lines = []
    for c in expanded:
        if c == 'F':
            nx = pos[0] + math.cos(math.radians(angle)) * step_length
            ny = pos[1] + math.sin(math.radians(angle)) * step_length
            lines.append(((pos[0], pos[1]), (nx, ny)))
            pos = (nx, ny)
        elif c == 'f':
            pos = (pos[0] + math.cos(math.radians(angle)) * step_length,
                   pos[1] + math.sin(math.radians(angle)) * step_length)
        elif c == '+':
            angle += angle_deg
        elif c == '-':
            angle -= angle_deg
        elif c == '[':
            stack.append((pos, angle))
        elif c == ']':
            pos, angle = stack.pop()
    return lines
```

For 3D output, collect vertices/edges and later convert to procedural mesh (tube along edges).

Rendering note: scale and center the bounding box to viewport. Optionally add thickness using tube geometry and S_symmetry to influence thickness.

---

## Gift assignment (deterministic)

- Load `public-gift-tables.json`
- Evaluate triggers deterministically from pattern metrics; implement trigger expressions as safe, parsed rules (do not eval raw text). Example triggers:
  - "D_fractal_dim >= 2.4 && K_complexity <= 0.35"
- Implementation approach:
  - Parse triggers into AST at startup or use small expression parser (safe).
  - Evaluate for each creature and select gifts according to assignment rules in file:
    - structural: always 1–2
    - metaphysical: exactly 1 if primary plane matches
    - modifier: 0–2 based on r(x)
    - mutation: 0–1 with probability influenced by bitmap anomalies (deterministic RNG seeded by imprintKey)
    - minor_flavor: exactly 2
- For any RNG-based assignment, seed with the same imprintKey RNG so assignment remains deterministic.

Example selection (pseudo):

```pseudo
if metric.D >= 2.4 and metric.K <= 0.35:
  add "FractalCarapace"
# For stochastic picks (rare mutations):
rng = DeterministicRNG(imprintKey)
if rng.NextDouble() < mutationChance:
  choose one mutation based on rarity weights using rng
```

---

## Rune activation pipeline (full)

1. Load `elder-futhark-9bit.json` at startup.
2. Given runeId:
   - bits9 = rune["bits"]
   - popcount = count('1' in bits9)
   - isWhiteWolf = (popcount % 2 == 0)
3. seed = parse bits9 as binary integer
4. RNG seeded with seed
5. Build spell L‑system:
   - axiom: "F"
   - rules: choose transform/preserve style rules based on isWhiteWolf
   - angle/iterations: deterministic from RNG
6. Expand to an lsystemSpell string. The effect structure returned:
   - parity: White Wolf or Dark Wolf
   - lsystemSpell: expanded string
   - domains: rune.game_domains
7. Apply effect to target agent:
   - if isWhiteWolf: small positive drift to targetAgent.r (preserve/amplify)
   - else: transform/invert or more radical change
   - Exact mapping of "preserve vs transform" is engine-defined but must respect parity intent.

Optimization: Precompute the 512 possible effects (all 9‑bit combos) at startup and store them in a lookup table to reduce runtime cost.

---

## Agent migration & Kripke ladder enforcement

- Agents may move planes only to adjacent plane indices: |i−j| ≤ 1
- When applying effects or drift that would change basePlane by >1, constrain changes:
  - Option A: Apply drift to s(x) and let the plane formula enforce adjacency (if a jump exceeds, clamp movement per tick to nearest adjacent plane).
  - Option B: Implement explicit checks: propose plane change; if |newPlane - oldPlane| > 1, set newPlane = oldPlane + sign(newPlane - oldPlane)
- Document the tick rate and drift scaling to ensure agents do not teleport across multiple planes in one frame.

- Agent migration & Kripke ladder enforcement

Agents migrate between planes via drift in \(\mathbf{s}\) and \(\mathbf{r}\), but transitions are governed by Kripke frames to enforce adjacency.

**Kripke Transition Formula**: \( p_t(c, p_b) = \begin{cases}
p_b & \text{if } |p_b - c| \leq 1 \\
c + \operatorname{sgn}(p_b - c) & \text{otherwise (snap to nearest in } R\text{)}
\end{cases} \), clamped to [1,9], where \( c \) is the current plane and \( p_b \) is the proposed base plane.

Implement in your engine's update loop:

```pseudo
# Inputs: current_plane (int: 1-9), proposed_plane (int: from p_b formula)
# Outputs: enforced_plane (int: snapped if needed)
function enforce_kripke(current_plane, proposed_plane):
    delta = proposed_plane - current_plane
    if abs(delta) <= 1:
        return proposed_plane  # Accessible: direct move allowed
    else:
        # Snap toward target by 1 step (Kripke accessibility)
        step = 1 if delta > 0 else -1
        return clamp(current_plane + step, 1, 9)  # Prevent out-of-bounds

# Helper: clamp(v, lo, hi) = max(lo, min(hi, v))

# Full Agent Tick Example (integrate with drift)
function agent_tick(agent):
    # Apply small drift (e.g., Gaussian noise, tunable sigma=0.01-0.05)
    agent.s += random_drift_vector(4)  # [C,S,P,H]; clamp each to [0,1]
    agent.r += random_drift_vector(3)  # [E,D,A]; clamp to [0,1]
    
    # Compute proposed
    score = compute_score(agent.s)  # C + S + P + (1 - H)
    proposed_plane = base_plane_from_score(score)  # floor(score * 2.25) + 1, clamped 1-9
    
    # Enforce Kripke
    agent.current_plane = enforce_kripke(agent.current_plane, proposed_plane)
    
    # Optional: Modal check for possibilities (e.g., for gifts or events)
    function is_possible(property_func, current_plane):
        for neighbor in [current_plane-1, current_plane, current_plane+1]:
            clamped = clamp(neighbor, 1, 9)
            if property_func(clamped):  # e.g., "gift available in plane?"
                return true
        return false
    
    # Update leaf realm (no Kripke needed, as it's intra-plane)
    agent.leaf_realm = leaf_from_r(agent.current_plane, agent.r)
    
    # Emit events if plane changed (for gameplay hooks)
    if agent.current_plane != old_plane:
        on_plane_transition(agent, old_plane, agent.current_plane)

---

## Performance & caching recommendations

- Precompute rune effects for all 512 9‑bit codes at startup (store spell L-systems, parity, seeds).
- Cache generated L-system meshes by ImprintKey; many creatures share identical ImprintKeys if they come from same sigil.
- Expand L-systems lazily: expand only as far as needed for rendering LOD.
- Use worker threads or engine-specific job systems for expansion and mesh generation.
- For large agent populations, use fixed-step updates of s(x)/r(x) and separate visual updates.

---

## Testing & validation checklist (must implement)

Unit tests you should have:

1. Hashing test:
   - Given canonical metrics serialization string S, SHA256(S) == expected hex from example-creatures.json imprintKey.
2. Seed mapping test:
   - Given hex imprintKey, BigInt parsing and 64-bit seed folding produce expected value (documented).
3. RNG cross-language parity test:
   - Starting seed X, first N outputs of RNG match reference stream.
4. L-system expansion:
   - Given axiom + rules + iterations, expansion equals reference sample (compare to creature-lsystem-sample.json expanded_string).
5. Turtle interpreter:
   - Given expanded string + angle + step, resulting lines / vertex list match reference approximations.
6. Rune parity:
   - For rune "fehu" bits "100000001", popcount == 2, parity == even.
7. Deterministic pipeline test:
   - Example: Compute pattern metrics for chosen sample input, imprintKey, L-system parameters and final gifts; compare to example-creatures.json.

Add CI (GitHub Actions) to run these tests on commits.

---

## Integration recipes

### Unity (C#) — minimal plan

1. Create an Agent MonoBehaviour that stores AgentState.
2. At startup, load JSON data using Unity's TextAsset or System.IO.
3. Implement deterministic RNG class (XorShift64Star).
4. Implement SHA‑256 and imprintKey generation (System.Security.Cryptography).
5. Use a background thread (Task/Job System) to expand L-systems and build Mesh objects.
6. Cache meshes by imprintKey; spawn prefabs with MeshFilter/MeshRenderer.

Unity minimal code pointers in INTEGRATION_GUIDE.md — implement exactly as shown with the RNG and deterministic serialization.

### Unreal (C++) — minimal plan

1. Create a UObject or Actor that holds agent state (FVector4, FVector).
2. Load JSON via FFileHelper + FJsonObjectConverter.
3. Implement deterministic RNG in C++.
4. Expand L-systems on worker thread, build ProceduralMeshComponent meshes.
5. Use replicated properties if networking — send imprintKey only, reconstruct mesh server-side or client-side deterministically.

### Godot (GDScript) — minimal plan

1. Use PoolByteArray + Crypto classes for SHA‑256 (Godot 3.2+ supports crypto in some builds; otherwise use a GDNative helper).
2. Implement L-system expansion and turtle interpreter in GDScript or C# for performance.
3. Use Resource cache keyed by imprintKey.

### Server (Python/Node) — minimal plan

1. Implement pipeline to produce JSON artifacts: imprintKey, lsystemString, glyph lines, gifts.
2. Serve these artifacts to clients; clients reconstruct meshes locally or download precomputed meshes.

---

## Helpful scripts & CI suggestions

- scripts/validate-json.sh — run `jq`/`ajv` to validate all data files.
- scripts/generate-sigil-sample.py — produce sample output from sample inputs and compare to example-creatures.json.
- GH Actions:
  - job: validate-json
  - job: run unit tests (Python/C# runner)
  - job: lint

Example sample CLI to compute imprintKey (Python skeleton)

```python
# scripts/generate_imprint.py
# Usage: python generate_imprint.py --input sample_input.json
```

(Implement reading sample, compute metrics → serialize canonical → sha256 hex → print.)

---

## Privacy, license and contributor flow

- Sigil creation may use personal data. NEVER publish raw personal-data-derived artifacts without consent.
- The repo's LICENSE is a Personal Use License. Read `CONTRIBUTING.md` and `CLA.md` when planning contributions.
- All contributors must sign the CLA before PR merges.

---

## Appendix — useful code snippets & references

1) Canonical metrics serialization (suggested format)

- Compose a single ASCII string with consistent numeric formatting, e.g.:
  - "H:0.550000;K:0.440000;D:2.220000;S:0.770000;L:123;"
- Use 6 decimal places for floats and integer for L. This avoids JSON ordering ambiguities.

1) Popcount function (portable)

```c
int popcount9(int bits) {
  int count = 0;
  for (int i=0;i<9;i++) if (bits & (1<<i)) count++;
  return count;
}
```

1) Bit order convention

- When creating bits9 from norms list, treat the list index 0 as most significant bit; when converting to integer choose big-endian interpretation and be consistent.
