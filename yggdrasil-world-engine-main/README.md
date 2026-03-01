# 🌳 Yggdrasil Engine V.1 (Base/Main)

[![License: Personal Use](https://img.shields.io/badge/license-Personal%20Use-blue)](LICENSE)
[![Unity Branch](https://img.shields.io/badge/Unity-6%2B-blue?logo=unity)](../../tree/unity)
[![Unreal Branch](https://img.shields.io/badge/Unreal-5.0%2B-blue?logo=unrealengine)](../../tree/Unreal-Engine)
[![Math Core](https://img.shields.io/badge/core-9--plane%20math-green)](docs/COSMOLOGY_AND_CORE.md)

## A Procedural Cosmology & Mythos Simulation Framework

The Yggdrasil Engine is a plug-and-play system for building **worlds**, **mythologies**, **RPGs**, **simulation games**, and **AI-driven narrative universes**.
It combines:

- a formal 9-realm cosmology (from the original Yggdrasil metaphysics),
- a mathematically structured state-space,
- expandable leaf-dimensions,
- agent dynamics,
- and a clean, mod-friendly API.

This is not physics.
This is a **myth-architecture**, engineered with mathematical clarity to support infinite creative expression.

Whether you're a **game developer**, **GM**, **world-builder**, or **AI narrative designer**, Yggdrasil Engine gives you a structured skeleton for crafting emergent cosmologies and procedural legends.

---

## ✨ Features

### ✔ Canonical 9-Realm Cosmology

The core cosmology is based on the original Nine Realms:

1. Physical
2. Etheric
3. Astral
4. Mental
5. Causal
6. Celestial
7. Shadow
8. Void
9. Divine Core

These form the **trunk** of the universe model.

---

### ✔ Infinite Leaf Realms

Each base realm can branch into **any number of sub-realms** using modifier vectors.

- Variations, biomes, pocket dimensions
- Procedural god-domains
- Elemental or thematic subdivisions
- Unique world “leaves” on each branch

The system grows like a **living tree**.

---

### ✔ Agent Simulation

Agents evolve in a bounded structural space:

`
s(x) ∈ [0,1]^4  # structure vector
r(x) ∈ [0,1]^3  # modifier/leaf vector
`

Their world-position is determined by:

- **Base realm** via structure vector
- **Leaf realm** via modifier vector

- Bounded random walk dynamics
- Adjacency-constrained transitions (Kripke frame)
- Partition rules for plane/leaf assignment

### ✔ Creature Generator

Deterministic sigil-based creature generation:

- Sigil input → PatternCore → BinaryMask → FeatureProfile → ImprintKey
- L-system for appearance and traits
- Gift system for abilities (structural, metaphysical, mutation, etc.)

Public alias layer hides proprietary 9D DNA internals.

### ✔ Rune System

Elder Futhark runes mapped to:

- 9D tube geometry
- Adinkra-style graphs on 9-bit hypercube
- Parity dyad (White Wolf/Dark Wolf, boson/fermion-inspired)
- L-system generators for spells/states

Full pipeline for dimensional reduction and game domains.

### ✔ Narrative & Lore Integration

- Pattern vectors for characters (H_entropy, K_complexity, D_fractal_dim, S_symmetry, L_generator_length)
- Metaphysical timeline (T0_Primordial_Void to T8_Awakening)
- Category-theory unification for planes and entities

### ✔ Integration Ready

Code-agnostic: Implement in Unity, Unreal, or any engine.

- Load JSON schemas
- Parse state vectors and rules
- Hook into simulation loop for dynamics

See docs/INTEGRATION_GUIDE.md for details.

---

## Getting Started

1. Clone this repo.
2. Load data JSONs into your engine (e.g., Unity ScriptableObjects or Unreal DataTables).
3. Implement core rules:
   - State vectors s(x), r(x)
   - Partition for planes/leaves
   - Dynamics for agent updates
4. Extend with your lore or mechanics.

For examples, see examples/.

---

## Quick start (local)

1. Create a Python venv and activate it (optional but recommended):

```bash
python3 -m venv .venv
source .venv/bin/activate
```

1. Install requirements for scripts:

```bash
pip install -r scripts/requirements.txt
```

1. Run the plane demo script (generates sample output in `out/`):

```bash
python scripts/plane.py
```

1. Run repository checks and tests:

```bash
bash scripts/run_checks.sh
pytest -q
```

If you prefer the GUI, open this folder in VS Code and use the Source Control view to run fetch/pull and inspect changes.

---

## Documentation

- docs/ENGINE_OVERVIEW.md: High-level architecture.
- docs/COSMOLOGY_AND_CORE.md: 9-plane model and math.
- docs/CREATURE_SYSTEM.md: Creature generation pipeline.
- docs/RUNE_SYSTEM.md: Rune geometry and L-systems.
- docs/PATTERN_VECTORS_AND_LORE.md: Character sheets and timeline.
- docs/INTEGRATION_GUIDE.md: How to implement in your engine.
- docs/WORKFLOW_REFERENCE.md: Developer workflow.

---

## Examples

//Working Proof of Concept in Swift Available Now!

- **Swift CLI Demo**: A command-line prototype simulating agent drift and creature generation. See [examples/swift/demo/](examples/swift/demo/).

## Engine Implementations

Engine-specific implementations live on **separate, independent branches** — they do not merge with `main`. Each engine branch is a complete, self-contained codebase that implements the spec defined here.

| Engine | Branch |
|--------|--------|
| Unity 6+ | [`unity`](../../tree/unity) |
| Unreal 5+ | [`Unreal-Engine`](../../tree/Unreal-Engine) |

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute engine implementations or core changes.

## License

Personal use free; commercial requires license. See LICENSE.

Copyright © 2025 Flynn (Creator)

## README.md tests — MD025 (single top-level heading)

Run with: pytest (the test below is a Python pytest snippet). It checks that README.md contains exactly one top-level heading ("# ...").

```python
# test_README.md (pytest)
import re
import pathlib
import pytest

HEADING_RE = re.compile(r'^[ \t]*(#{1,6})\s+(\S.*)$')

def _collect_headings(text):
    headings = []
    for i, line in enumerate(text.splitlines(), start=1):
        m = HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            txt = m.group(2).strip()
            headings.append((i, level, txt))
    return headings

def test_readme_single_h1():
    readme_path = pathlib.Path(__file__).parent / "README.md"
    text = readme_path.read_text(encoding="utf-8")
    headings = _collect_headings(text)
    h1_lines = [f"{ln}: {('#'*lvl)} {txt}" for ln, lvl, txt in headings if lvl == 1]
    assert len(h1_lines) == 1, (
        f"MD025: README.md must contain a single top-level heading (#). "
        f"Found {len(h1_lines)} top-level headings:\n" + "\n".join(h1_lines)
    )

def test_readme_heading_increment_md001():
    readme_path = pathlib.Path(__file__).parent / "README.md"
    text = readme_path.read_text(encoding="utf-8")
    headings = _collect_headings(text)
    violations = []
    if headings:
        prev_ln, prev_lvl, prev_txt = headings[0]
        for ln, lvl, txt in headings[1:]:
            if lvl - prev_lvl > 1:
                violations.append(
                    f"Line {ln}: level h{prev_lvl} -> h{lvl} (prev line {prev_ln}: '{prev_txt}' ; this: '{txt}')"
                )
            prev_ln, prev_lvl, prev_txt = ln, lvl, txt
    assert not violations, (
        "MD001: Heading levels must only increment by one level at a time. "
        "Found violations:\n" + "\n".join(violations)
    )
```
