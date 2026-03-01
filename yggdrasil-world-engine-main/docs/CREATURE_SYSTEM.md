# Creature Generation System (Public Alias Layer)

This is the **fully public**, **deterministic**, **code-agnostic** creature generator you may freely implement in any engine.

The private 9D DNA and internal codex are **not** included in this repository (they remain proprietary), but the public pipeline below produces identical results using only alias terms.

## Public Pipeline Overview

User-provided Sigil (image/text)
↓
BinaryMask (thresholded & cleaned)
↓
FeatureProfile (spatial + spectral stats)
↓
ImprintKey (256-bit opaque hash – acts as seed)
↓
L-System Grammar + Production Rules (determined by ImprintKey)
↓
Final Creature: body plan, gifts, name fragments, lore hooks

## Step-by-Step (what you must implement)

1. **BinaryMask**  

- Convert sigil to grayscale → threshold at 50 % → erode/dilate once → crop tight  
- Output: 64×64 binary bitmap (4096 bits, but we only use first 256)

1. **FeatureProfile** (public alias metrics)

- H_entropy          → Shannon entropy of the bitmap
- K_complexity      → Estimated Kolmogorov complexity proxy (compressibility ratio)
- D_fractal_dim     → Box-counting dimension of the outline
- S_symmetry        → Horizontal + vertical reflection symmetry score
- L_generator_length→ Length of shortest L-system that approximates the shape

1. **ImprintKey**  
Take the 256 most significant bits from a SHA-256 hash of the concatenated FeatureProfile values.  
This 256-bit integer is your creature’s permanent DNA-like seed.

2. **L-System Generation**  
Use the ImprintKey as a deterministic RNG seed to select:

- Axiom (starting symbol)
- 4–8 production rules
- Angle δ (22.5°, 30°, 36°, 45°, etc.)
- Iteration count (4–9)

Standard alphabet used throughout the engine:

1. **Gift Assignment** (abilities / traits)

Gifts are assigned in five tiers using PatternMetrics derived from the same FeatureProfile:

| Tier | Input Used | Example Gifts (choose 1–3) |
| --- | --- | --- |
| Structural | H,K,D,S,L | FractalCarapace, LowEntropyAura, SymmetryBloom |
| Metaphysical | Plane + symmetry score | Dreamwalk, FateThread, VoidWhisper |
| Modifier | E,D,A from r(x) of creator | Fireborn, ChaosBloom, OrderAnchor |
| Mutation | Anomaly spikes in bitmap | SingularityPulse, EclipseShift |
| Minor Flavor | Noise & weak features | AetherScent, GlimmerTrail |

Exact lookup tables are provided in `data/creatures/public-gift-tables.json` (next files).

## Implementation Notes for Unity / Unreal

- Store ImprintKey as `BigInteger` (C#) or `uint64[4]` (C++)  
- Use it to seed a deterministic RNG (e.g., Xorshift128+) for all downstream choices  
- Render the L-system with a turtle graphics interpreter → procedural mesh  
- Assign gifts as scriptable components / data assets

The system is 100 % reproducible: same sigil → same creature forever, on any platform, in any language.

Next file contains the actual public gift tables and L-system rule sets.

## Reference Pseudo-Implementation (Code-Agnostic)

To implement in Unreal C++ or Unity C#:

- Load `public-gift-tables.json` at runtime (FJson in UE, JsonUtility in Unity).
- For a creature:
  - Use proxy metrics (H,K,D,S,L) from canonical-pattern-vectors.json or sigil analysis.
  - Compute ImprintKey = SHA256(serialized metrics).
  - Seed deterministic RNG → select L-system axiom/rules/angle/iterations.
  - Expand string → turtle interpret for mesh (ProceduralMeshComponent in UE, MeshFilter in Unity).
  - Evaluate gift triggers (e.g., D >= 2.4 && K <= 0.35 → "FractalCarapace").

Example output for "white_wolf":

- Metrics: H=0.07, K=0.05, D=2.61, S=0.99, L=4
- Estimated plane: 6
- Gifts: SymmetryBloom, LowEntropyAura
