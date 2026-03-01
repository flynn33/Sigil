# Custom Instructions for GitHub Copilot in Yggdrasil-Engine

## Project Overview
- This is a code-agnostic procedural cosmology engine.
- Focus on providing logic, math, and pseudo-code only.
- Do not generate full implementations for Unity, Unreal, or other engines—leave that to developers.
- Reference core files like docs/COSMOLOGY_AND_CORE.md for plane calculations and PATTERN_VECTORS_AND_LORE.md for entity vectors.

## Key Rules
- Always preserve invariants: 9 planes, Kripke ladder (|current - target| ≤ 1), canonical pattern vectors (H, K, D, S, L).
- Use pseudo-code in a neutral format (e.g., no C# or C++ specifics).
- For suggestions: Emphasize deterministic outputs from ImprintKey (SHA-256 hashes).
- Avoid adding engine-specific code; suggest forks/branches for implementations as per CONTRIBUTING.md.
