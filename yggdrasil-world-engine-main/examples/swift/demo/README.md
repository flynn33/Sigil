# Yggdrasil Engine Swift Demo

This is a simple command-line prototype demonstrating the core mechanics of the Yggdrasil Engine in Swift. It simulates agent drift across the 9 realms and generates a procedural creature using L-systems.

## Requirements

- macOS with Swift 5+ (built-in; no external dependencies).

## How to Run

1. Open Terminal and navigate to this folder.
2. Run directly: `swift main.swift`
   - Or compile: `swiftc main.swift -o yggdrasil_demo` then `./yggdrasil_demo`

## Output

- Initial and final distributions of 1,000 agents across realms (bell-curve expected).
- Sample agent trajectory (first 30 ticks).
- Procedural creature stats from sigil "FEHU".

## Notes

- Randomness is unseeded—rerun for variations.
- This is a CLI stub; extend to SwiftUI for visuals or integrate with the engine's JSON schemas.
- Based on Yggdrasil Engine docs (cosmology, agents, creatures).

For full engine integration, see `docs/INTEGRATION_GUIDE.md`.
