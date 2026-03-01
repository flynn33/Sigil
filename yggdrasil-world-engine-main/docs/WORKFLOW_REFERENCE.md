# Yggdrasil Engine – Workflow & Validation Reference

This file exists so that **every future version** of the engine stays 100 % faithful to the original mathematics and metaphysics.

## Core Invariants (never break these)

1. **9 canonical planes** – must always exist exactly as defined  
2. **Base plane formula**: `floor((C + S + P + (1-H)) × 2.25) + 1` → planes 1–9  
3. **Kripke adjacency**: agents may only move to `|current - target| ≤ 1`
4. **Kripke adjacency**: agents may only move to `|current - target| ≤ 1`  
   **Enforcement Formula**: \( p_t(c, p_b) = \begin{cases}
   p_b & \text{if } |p_b - c| \leq 1 \\
   c + \operatorname{sgn}(p_b - c) & \text{otherwise (snap to nearest in } R\text{)}
   \end{cases} \), clamped to [1,9]. Implement via `enforce_kripke` in agent ticks.
5. **White Wolf / Dark Wolf parity** from 9-bit hypercube popcount  
6. **All 24 Elder Futhark runes** have fixed, immutable 9-bit codes  
7. **Canonical pattern vectors** in `data/cosmology/canonical-pattern-vectors.json` are law  
8. **T0–T8 timeline** is immutable narrative structure

## Validation Checklist (run before any release)

- [ ] Kripke multi-step snaps verified (e.g., run `test_kripke_multi_step_snap` in `test_plane.py` and confirm passes)
- [ ] `canonical-pattern-vectors.json` passes `schemas/cosmology_schema.json`  
- [ ] Every rune in `elder-futhark-9bit.json` has exactly 9 bits  
- [ ] Plane calculation in code matches the formula above (no “tweaks”)  
- [ ] No proprietary 9D DNA or internal codex files are present in public repo  
- [ ] LICENSE file is unmodified and present at root  
- [ ] All example code (Unity/Unreal) produces correct plane 1–9 behavior

## Versioning Rule

- Public releases: `v1.x` (current stable line)  
- Internal/private versions: `v9.x` (never published)  
- Any change that breaks an invariant = new major version (`v2.0+`)

The tree does not forget its rings.  
Neither should we.

— Flynn, 2025
