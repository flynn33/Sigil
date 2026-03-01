# Yggdrasil Engine – Overview

A **code-agnostic**, mathematics-first procedural cosmology engine.

Everything in this repository is deliberately written in pure data + documented rules so that any programmer can implement it in **Unreal Engine**, **Unity**, **Godot**, Bevy, custom C++/Rust engines, or even server-side tools — without ever depending on a single line of Flynn’s private source code.

## Core Mathematical Objects

| Symbol       | Dimension | Meaning                                                             | Range     |
|--------------|-----------|---------------------------------------------------------------------|-----------|
| s(x)         | 4         | Structural vector (Compressibility, Symmetry, Persistence, Entropy) | [0,1]^4   |
| r(x)         | 3         | Modifier vector (Elemental, Domain, Alignment)                      | [0,1]^3   |
| ŝ(x) = (s,r) | 7         | Full agent state – determines both base plane and leaf realm        | [0,1]^7   |

## Cosmology in One Sentence

Base plane (1–9) is derived from s(x) only.  
Leaf realm within that plane is derived from r(x) only.  
Agents may only move to adjacent planes (|i−j|≤1) – the Kripke ladder.

## Major Sub-systems

1. **Cosmology & Core Engine** – 9 planes + infinite leaves, agent dynamics, Kripke transitions  
2. **Creature Generator** – Sigil → ImprintKey → deterministic L-system bodies + gift tables (public alias layer)  
3. **Rune System** – Elder Futhark → 9D tube geometry → 9-bit hypercube code → White Wolf / Dark Wolf parity → L-system spells  
4. **Pattern Vector Lore System** – Every major character has a canonical (H,K,D,S,L) vector that places them in the cosmology  
5. **Category-theory unification layer** – optional but provided for metaphysical correctness

## How to Implement (high-level)

1. Load all JSON files in `/data/` at startup  
2. Create an `Agent` struct/class with `float[4] s` and `float[3] r`  
3. Every tick:  

4. Every tick:  

```pseudo
s += small_random_drift;  s = clamp(s, 0, 1)
r += smaller_random_drift; r = clamp(r, 0, 1)
proposed_base_plane = CalculateBasePlane(s)

// Enforce Kripke adjacency
current_base_plane = enforce_kripke(current_base_plane, proposed_base_plane)

current_leaf_realm  = CalculateLeafRealm(current_base_plane, r)
s += small_random_drift;  s = clamp(s, 0, 1)
r += smaller_random_drift; r = clamp(r, 0, 1)
current_base_plane  = CalculateBasePlane(s)
current_leaf_realm  = CalculateLeafRealm(current_base_plane, r)

//Enforce Kripke adjacency when migrating agents between planes
Generate creatures/runes on demand using the pipelines in docs/CREATURE_SYSTEM.md and docs/RUNE_SYSTEM.md

// Detailed step-by-step integration guides follow in the other docs.
The tree is real. The mathematics is exact. Everything else is yours to interpret.

