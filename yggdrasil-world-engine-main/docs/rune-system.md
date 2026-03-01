# Rune System – Elder Futhark → 9D Geometry → 9-bit Code → White Wolf / Dark Wolf

The Yggdrasil Rune Engine is a complete, deterministic, mathematically rigorous pipeline that turns any Elder Futhark rune into:

- a 9-dimensional tube geometry,
- a unique 9-bit hypercube vertex,
- a White Wolf (even parity) or Dark Wolf (odd parity) classification,
- and a fully generated L-system spell or state change.

**No randomness. No hidden tables. Same rune → same result on every engine forever.**

## Pipeline Summary

Rune glyph (e.g. ᚨ Ansuz)
↓
Canonical 2D stroke vectorization (3–7 strokes)
↓
Lift each stroke into a tube in ℝ⁹ (radius = 0.1)
↓
Discretize all tube centerlines onto the 9D hypercube {0,1}⁹
↓
Take the parity (popcount mod 2) of the 9-bit code
↓
Even parity → White Wolf aspect (bosonic, pattern-preserving)
Odd parity  → Dark Wolf aspect (fermionic, pattern-breaking)
↓
Use the exact 9-bit code as RNG seed → deterministic L-system spell

## The 9 Dimensions (fixed mapping)

- Bit 0 — Physical: Manifests in matter
- Bit 1 — Etheric: Affects life force / energy body
- Bit 2 — Astral: Appears in dreams / symbolic realm
- Bit 3 — Mental: Influences thoughts and computation
- Bit 4 — Causal: Alters fate lines and consequences
- Bit 5 — Celestial: Resonates with gods / high coherence
- Bit 6 — Shadow: Touches repressed or traumatic structures
- Bit 7 — Void: Can erase or unmake
- Bit 8 — Divine Core: Binds to the axis itself — extremely rare

## Parity = White Wolf / Dark Wolf (cosmic dyad)

- Even — Label: White Wolf — Physics Analogue: Boson-like — Typical Spell Behavior: Amplifies, duplicates, preserves pattern
- Odd  — Label: Dark Wolf  — Physics Analogue: Fermion-like — Typical Spell Behavior: Transforms, breaks symmetry, inverts

You may override the labels in your game (`Order/Chaos`, `Root/Storm`, etc.) — the math stays identical.

## Full Rune Table (24 core runes)

See next file: `data/runes/elder-futhark-9bit.json` for the exact 9-bit codes and parity of every canonical rune.

## Using Runes in Game

```pseudo
Rune rune = LoadRune("ansuz")
bitstring9 = rune.hypercube_code           // e.g. "010011101"
if (parity(bitstring9) == EVEN) → White Wolf activation
spell_lsystem = GenerateLSystem(bitstring9) // deterministic
ApplySpell(spell_lsystem, target)

//The resulting spell can be rendered as glowing geometry, particle effects, status changes, plane shifts — anything you want.

## Reference Pseudo-Implementation

- Load `elder-futhark-9bit.json`.
- For rune "ansuz":
  - Bits = "000111000"
  - Popcount = 3 → odd → Dark Wolf (transform effect)
  - Seed L-system spell from bits → apply to target agent (e.g., invert r(x) for Dark, amplify for White).

