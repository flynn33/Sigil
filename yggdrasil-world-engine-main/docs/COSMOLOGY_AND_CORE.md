# Cosmology & Core Engine

//The Yggdrasil Engine is built on a strict nine-plane cosmology with mathematically precise rules for agent placement, movement, and transformation.

## Purpose & Audience

This document explains the cosmology and core rules for game developers integrating the Yggdrasil Engine into gameplay systems. It focuses on implementation details, data formats, tuning guidance, and concrete examples you can drop into an update loop or simulation system.

Target reader: gameplay programmers, system designers, and technical designers building agents (creatures, NPCs, items, ideas) that participate in the nine-plane cosmology.

## The Nine Canonical Planes

| ID | Name          | Primary Quality                     | Typical Inhabitants / Phenomena                   |
|----|---------------|-------------------------------------|---------------------------------------------------|
| 1  | Physical      | Spacetime + entropy increase        | Mortal bodies, biology, physics                   |
| 2  | Etheric       | Subtle energy fields                | Life force, auras, chi/prana                      |
| 3  | Astral        | Symbolic / imaginal space           | Dreams, archetypes, visions                       |
| 4  | Mental        | Pure computation & self-models      | Thoughts, memories, internal narratives           |
| 5  | Causal        | Karmic chains & narrative causality | Fate lines, consequences, timelines               |
| 6  | Celestial     | High symmetry & coherence           | Angels, gods, completed patterns                  |
| 7  | Shadow        | Repressed / conflicted structures   | Trauma, hells, unintegrated aspects               |
| 8  | Void          | Unstructured information            | Oblivion, pure noise, pre-creation                |
| 9  | Divine Core   | Axis Mundi – source of all planes   | The Creator, terminal object, rule-set itself     |

## State Vectors

//Every agent (soul, god, monster, player character, NPC, star, idea) is defined by exactly seven normalized floats:

```text
s(x) = [C, S, P, H] ∈ [0,1]⁴   → structural vector
r(x) = [E, D, A]   ∈ [0,1]³   → modifier / leaf vector

//Structural vector components

C = Compressibility (how rule-based the pattern is)
S = Symmetry / harmony
P = Persistence across time & scale
H = Normalized entropy / chaos

Modifier vector components

E = Elemental affinity continuum
D = Domain (war, love, knowledge, dream, etc.)
A = Alignment (order ↔ chaos)

score = C + S + P + (1 - H)               // range ≈ [0,4]
base_plane = clamp(floor(score * 2.25) + 1, 1, 9)

//This formula guarantees the canonical 9-stratum distribution while remaining completely deterministic and language-neutral.
//Leaf realm within a plane (infinite possible):

//Kripke Ladder – Allowed Transitions
//Agents may only migrate to an adjacent plane:

//This formula guarantees the canonical 9-stratum distribution while remaining completely deterministic and language-neutral.
//Leaf realm within a plane (infinite possible):

leaf_index = floor( (E + D + A)/3 × number_of_leaves_in_plane ) + 1

//Dynamics (bounded random walk)

Δs ∼ Uniform[-0.02, +0.02]  per step  (adjustable)
Δr ∼ Uniform[-0.008, +0.008] per step
snew = clamp(s + Δs, 0, 1)
rnew = clamp(r + Δr, 0, 1)

//Kripke Ladder – Allowed Transitions
//Agents may only migrate to an adjacent plane:

|current − target| ≤ 1

//This creates the characteristic “ladder” or “world tree” structure that gives the engine its name.

//Existence Axioms (formal layer)
//See data/cosmology/axion-of-existence.json for the five core axioms (Relational Existence, Structural Compressibility, Mult-Scale Persistence, Energetic Cost of Erasure, Self-Reference for Consciousness).

//These axioms are not flavor text — they are enforced by the mathematics above.

//The cosmology is complete, deterministic, and ready for immediate implementation in any engine.

## Kripke Ladder Enforcement (Advanced)

Agents may only migrate to adjacent planes (|current - target| ≤ 1).

Implementation note:
- In plane calculation (after drift):
  - Compute new_plane from score.
  - If |new_plane - current_plane| > 1:
    - Snap to current_plane ±1 (toward target).
- This prevents invalid jumps while preserving drift math.

- This prevents invalid jumps while preserving drift math.

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

Add in agent Tick/UpdatePlane for forced migrations.

**Quick Implementation Summary**

- Compute the score from the structural vector: `score = C + S + P + (1 - H)`.
- Compute `base_plane = clamp(floor(score * 2.25) + 1, 1, 9)` (deterministic mapping).
- After applying random drift to `s` and `r`, recompute `base_plane` and enforce `|new_plane - current_plane| ≤ 1` by snapping if necessary.

The rest of this file expands those steps, offers JSON examples, pseudocode for the update loop, and guidance for tuning.

**Terminology (concise)**

- Plane: one of the nine canonical strata (1..9). Controls macro-categorization of agents.
- Structural vector (`s`): four floats `[C,S,P,H]` determining how rule-like, symmetric, persistent, and entropic an agent is.
- Modifier vector (`r`): three floats `[E,D,A]` describing elemental affinity, domain, and alignment; used to pick leaf realms within a plane.
- Leaf: an addressable sub-region inside a plane (infinite/discrete depending on design); used for micro-location and interactions.
- Kripke Ladder: the adjacency rule that permits only ±1 plane migrations per tick.

**Data Model / JSON example**

Below is a minimal example of how an agent might be serialized in JSON for storage or network replication. The engine expects normalized floats in `[0,1]`.

```json
{
  "id": "goblin-001",
  "type": "creature",
  "displayName": "Gnasher",
  "state": {
    "s": { "C": 0.48, "S": 0.32, "P": 0.21, "H": 0.55 },
    "r": { "E": 0.10, "D": 0.55, "A": 0.30 }
  },
  "meta": {
    "current_plane": 1,
    "leaf_index": 42
  }
}
```

Concrete computed example (numbers above):

- score = C + S + P + (1 - H) = 0.48 + 0.32 + 0.21 + (1 - 0.55) = 1.46
- base_plane = clamp(floor(1.46 * 2.25) + 1, 1, 9) = clamp(floor(3.285) + 1, 1, 9) = 4

If `current_plane` was 1, the engine must snap the agent toward 4 by at most +1 this tick, yielding `current_plane = 2` after enforcement.

## Integration: update loop pseudocode

JavaScript-like pseudocode for an agent tick. This is intentionally minimal so you can adapt it to your engine.

```js
function tickAgent(agent, params) {
  // apply bounded drift
  for (let k of ['C','S','P','H']) {
    agent.state.s[k] = clamp(agent.state.s[k] + randomUniform(-params.ds, params.ds), 0, 1);
  }
  for (let k of ['E','D','A']) {
    agent.state.r[k] = clamp(agent.state.r[k] + randomUniform(-params.dr, params.dr), 0, 1);
  }

  // compute score and proposed plane
  const C = agent.state.s.C, S = agent.state.s.S, P = agent.state.s.P, H = agent.state.s.H;
  let score = C + S + P + (1 - H);
  let proposed = clamp(Math.floor(score * 2.25) + 1, 1, 9);

  // enforce Kripke ladder
  const cur = agent.meta.current_plane;
  if (Math.abs(proposed - cur) > 1) {
    agent.meta.current_plane = cur + Math.sign(proposed - cur);
  } else {
    agent.meta.current_plane = proposed;
  }

  // compute leaf_index (example mapping)
  const avgR = (agent.state.r.E + agent.state.r.D + agent.state.r.A) / 3;
  agent.meta.leaf_index = Math.floor(avgR * params.leavesPerPlane[agent.meta.current_plane]) + 1;
}
```

Suggested default params:

- `ds = 0.02` (structural drift per tick)
- `dr = 0.008` (modifier drift per tick)
- `leavesPerPlane` — tune per plane; e.g., `[0, 256, 512, 512, 256, 128, 64, 128, 32, 8]` (index 0 unused)

## JSON Schema and existing data

Reference cosmology and pattern data in the repository:

- `data/cosmology/cosmology_schema.json` — canonical schema for cosmology objects.
- `data/cosmology/canonical-pattern-vectors.json` — example canonical vectors and pattern presets.
- Creature and agent examples: `data/creatures/example-creatures.json` and `data/agent/agent-sigil-creation.JSON`.

When you author new creatures or artifacts, prefer including explicit `s` and `r` values so their cosmological behaviour is deterministic and testable.

### Gameplay integration patterns

- Anchors: lock an agent to a plane (ignore drift) while an in-game effect applies (e.g., artifact, ritual).
- Phase-shift events: temporarily relax Kripke ladder constraints to allow cross-plane abilities (use sparingly).
- Plane-based queries: use `current_plane` for broad rule checks (collision layers, visibility, interaction filters).
- Procedural generation: seed `s` and `r` from procedural noise or templates in `data/cosmology` for consistent, reproducible worlds.

### Tuning & balancing

- Higher `ds` increases cosmological volatility; good for chaotic regions or dreamscapes.
- Increase `dr` to let modifiers wander faster (useful for mutable magic effects).
- Use `H` to control how 'noisy' an agent is; low `H` biases toward higher score and higher planes.
- For predictable NPC behavior, clamp one or more structural components (freeze `C` or `P`).

#### Example: spell that shifts alignment

- Spell modifies `r.A` by ±0.2 (clamped). After next tick, `leaf_index` and possibly `base_plane` will update; Kripke ladder ensures smooth migration.

### Developer checklist before release

- Ensure all persisted agents include normalized `s` and `r` values.
- Add unit tests covering plane calculation, Kripke enforcement, and leaf indexing.
- Provide tools to visualize distribution of `base_plane` across an environment (histogram or heatmap).

## References & related docs

- Engine overview: `docs/ENGINE_OVERVIEW.md`
- Creature system: `docs/CREATURE_SYSTEM.md`
- Cosmology data: `data/cosmology/canonical-pattern-vectors.json`, `data/cosmology/cosmology_schema.json`

## Appendix — constants & equations

- score = C + S + P + (1 - H)
- base_plane = clamp(floor(score * 2.25) + 1, 1, 9)
- Δs ∼ Uniform[-ds, +ds]
- Δr ∼ Uniform[-dr, +dr]

Default engine tuning (recommended starting values):

- `ds = 0.02`, `dr = 0.008`
- `leavesPerPlane` as described above.

---

## Formal Kripke Frame for Plane Transitions

The engine's plane transition rules are formally grounded in a Kripke frame from modal logic, ensuring metaphysical consistency for agent migrations. This models "possible worlds" (planes) with an accessibility relation enforcing the ladder structure.

### Mathematical Definition

A Kripke frame is a pair \(\langle W, R \rangle\), where:

- \( W = \{1, 2, \dots, 9\} \) is the set of worlds (canonical planes: 1=Physical to 9=Divine Core).
- \( R \subseteq W \times W \) is the accessibility relation, defined as:
  \[
  R = \{ (i, j) \mid |i - j| \leq 1 \}
  \]
  This is a symmetric, reflexive relation (each plane is accessible to itself and its immediate neighbors), forming a linear chain graph (the "ladder").

In modal logic terms:

- \(\Diamond p\): "It is possible that p" holds at plane \( i \) if there exists \( j \) such that \( (i, j) \in R \) and p holds at \( j \) (e.g., an agent can transition to a neighboring plane where property p is true).
- \(\Box p\): "It is necessary that p" holds at plane \( i \) if for all \( j \) with \( (i, j) \in R \), p holds at \( j \) (e.g., core axioms like existence must hold across adjacent planes).

This frame enforces "no leaps": Agents cannot jump non-adjacent planes, preserving narrative and metaphysical gradients (e.g., gradual ascent from Physical to Celestial).

### Pseudo-Code Enforcement

Enforce the frame in any agent update loop using the following mathematical formulation:

**Kripke Transition Formula**: \( p_t(c, p_b) = \begin{cases}
p_b & \text{if } |p_b - c| \leq 1 \\
c + \operatorname{sgn}(p_b - c) & \text{otherwise (snap to nearest in } R\text{)}
\end{cases} \), clamped to [1,9], where \( c \) is the current plane and \( p_b \) is the proposed base plane.

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
