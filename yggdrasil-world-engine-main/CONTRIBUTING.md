# Contributing to Yggdrasil Engine

Thank you for your interest in contributing to the Yggdrasil Engine! This project is a procedural cosmology and mythos simulation framework designed for personal use in game development, worldbuilding, and creative experimentation. All contributions must align with the project's [Personal Use License](LICENSE), which emphasizes non-commercial, personal applications only.

Please read this guide carefully before contributing. By submitting a contribution, you agree to abide by the terms of the LICENSE and these guidelines.

## Key Principles from the License

- **Personal Use Only**: Contributions must support private experimentation, academic learning, hobby projects, non-commercial worldbuilding, non-commercial games/prototypes, or non-monetized creative works. No contributions that enable or promote Commercial Use (e.g., revenue-generating features, corporate tools, or monetized content) will be accepted.
- **No Redistribution of Modified Versions Without Permission**: If your contribution modifies the core files, it may not be redistributed outside of this repository without explicit permission from the Creator (Flynn). Pull requests (PRs) are welcome for review and potential merging into the main repository.
- **Intellectual Property**: All formulas, models, systems, architectures, and innovations remain the intellectual property of the Creator. Contributions do not transfer ownership but are licensed under the same Personal Use terms if merged.
- **Prior Art and Patents**: This repository serves as timestamped prior art. Contributions should not introduce elements that could infringe on or dilute the Creator's rights to patent implementations or improvements.
- **No Warranty**: Contributions are provided "AS IS" without any warranty.

## What Contributions Are Welcome?

We encourage contributions that enhance the framework while preserving its core invariants (e.g., the 9-plane cosmology, pattern vectors, Kripke ladder, and White Wolf/Dark Wolf parity—see `docs/WORKFLOW_REFERENCE.md` for details). Examples include:

- New branches for use in specific game environments, e.g. Unity, Unreal, board games, etc. Contributors are encouraged to create dedicated branches for specific use cases.
- Bug fixes in example code (e.g., Unity/Unreal implementations).
- Documentation improvements (e.g., clearer explanations, additional examples).
- Minor enhancements to pseudo-code or pipelines (e.g., optimizations that maintain determinism).
- New non-core examples or ports (e.g., Godot or Rust implementations in the `examples/` folder).
- Typos, grammar, or formatting fixes.
- Suggestions for new features via issues (e.g., additional gift tables or L-system variations, as long as they respect canonical lore).

## Engine-Specific Implementations

The `main` branch contains the engine-agnostic core: framework, logic, math, JSON schemas, documentation, and pseudo-code. Engine-specific implementations (e.g., Unity, Unreal, Godot) live on **independent, self-contained branches** in the main repository (e.g., `unity`, `unreal`). Each engine branch is a complete, standalone implementation — it includes its own code, assets, data files, documentation, and tests. Engine branches do not depend on or inherit from `main` at runtime; they are fully independent codebases that implement the same core invariants described in `main`.

Think of `main` as the **specification** and each engine branch as a **complete implementation** of that spec in a particular engine.

To contribute an engine-specific implementation:

1. **Fork the Repository**: Create a fork of this repo on GitHub.
2. **Create a Branch in Your Fork**: If a dedicated engine branch (e.g., `unity`) already exists, branch from it. If you are starting a new engine implementation, create a new branch and build it from scratch — do not copy files from `main`.
   - Use descriptive branch names (e.g., `unity/creature-vfx` or `unreal-initial-implementation`).
   - Implement your code, ensuring it:
     - Faithfully implements the core math, logic, and invariants defined in `main` (e.g., plane calculations, state vectors, Kripke enforcement, determinism).
     - Is fully self-contained — all code, data, assets, and documentation needed to use the implementation must live within the branch.
     - Includes engine-specific details like scripts, prefabs, scenes, or blueprints.
     - Adds a README explaining setup, usage, and architecture for the target engine.
3. **Test Thoroughly**: Verify your implementation in the target engine (e.g., Unity 6+). Ensure it preserves core invariants (e.g., 9-plane cosmology, deterministic outputs).
4. **Submit a Pull Request (PR)**:
   - Target your PR to the appropriate engine branch (e.g., `unity`).
   - If the engine branch doesn't exist yet (e.g., first Godot contribution), note in the PR description that a new dedicated branch should be created. The maintainer will handle this.
   - In your PR description, include:
     - The engine and version (e.g., "Unity 6 implementation of agent dynamics").
     - Screenshots or demos of it working.
     - How it aligns with the Personal Use License (e.g., "This is for non-commercial hobby projects only").
5. **Review and Merge**: The maintainer will review for compliance with the license, invariants, and quality. If approved, it will be merged into the appropriate engine branch.

**Important Notes**:

- Engine branches are **independent and self-contained**. They implement the same invariants as `main` but carry their own complete codebase — they do not reference or depend on `main` at runtime.
- Updates to `main` (e.g., new invariants or lore) may need to be implemented separately in each engine branch. The engine branches are not automatically synchronized with `main`.
- Future updates to an engine branch: Fork, branch off the existing dedicated branch (e.g., off `unity`), make changes, and PR back to that branch.
- All contributions must remain non-commercial and respect the license. No paid plugins, monetized assets, or commercial features.
- If your implementation introduces new dependencies (e.g., Unity packages), list them clearly and justify why they're needed.

This structure allows the Yggdrasil Engine to grow with community implementations while keeping each branch focused: `main` as the authoritative spec, and engine branches as independent, production-ready implementations.

**What We Won't Accept**:

- Changes that break core invariants or immutable lore (e.g., altering canonical pattern vectors, timeline, or rune codes).
- Commercial-oriented features (e.g., monetization integrations, enterprise scaling).
- Additions that require external dependencies not already listed.
- Modified versions of proprietary elements (e.g., attempts to reverse-engineer private 9D DNA).
- Large-scale rewrites without prior discussion.
- Changes to the main branch logic.

## How to Contribute

1. **Fork the Repository**: Create your own fork on GitHub to work on changes.
2. **Create an Issue First**: For anything beyond minor fixes, open an [issue](https://github.com/[your-username]/yggdrasil-engine/issues) to discuss your idea. This helps avoid duplicated effort and ensures alignment with the license and project goals.
3. **Make Your Changes**:
   - **For core/spec changes**: Branch from `main` (e.g., `fix/typo-in-docs` or `feature/new-gift-table`).
   - **For engine-specific changes**: Branch from the appropriate engine branch (e.g., branch from `unity` for Unity work). Do not target `main` for engine-specific code.
   - Follow the existing style: Use clear, commented code; maintain determinism; validate against `schemas/cosmology_schema.json` if applicable.
   - Test your changes: Ensure they do not break invariants.
   - Update documentation if your change affects usage (e.g., add to `docs/` or README).
4. **Submit a Pull Request (PR)**:
   - Target the appropriate branch: `main` for core/spec changes, or the relevant engine branch (e.g., `unity`) for engine-specific changes.
   - Provide a clear title and description: Explain what you changed, why, and how it aligns with the license.
   - Reference any related issues (e.g., "Fixes #123").
   - Include before/after examples if applicable (e.g., screenshots for visual changes).
5. **Review Process**: The Creator or maintainers will review your PR. We may request changes for compliance, quality, or alignment. If approved, it will be merged.
6. **Redistribution**: If your PR is merged, the modified repository may be redistributed under the license terms (unmodified LICENSE included). You may not redistribute your forked/modified version commercially or without permission.

## Contributor License Agreement (CLA)

To ensure the Yggdrasil Engine remains under the Creator's (Flynn's) control for IP and commercial licensing, all contributors must sign a Contributor License Agreement (CLA) before their pull requests can be merged. This CLA grants Flynn a perpetual, worldwide, royalty-free license to use, modify, distribute, and commercialize your contributions under the project's terms (including relicensing for commercial use). You retain copyright to your contributions but agree not to assert claims that interfere with the project's licensing.

- **Why a CLA?** It protects the project's integrity, allows seamless inclusion of contributions in any branches (e.g., unity or unreal), and ensures Flynn can handle commercial licenses without fragmentation.
- **How to Sign:** We use [CLA Assistant](https://cla-assistant.io/) (or a similar GitHub-integrated tool). When you open a PR, you'll be prompted to sign electronically if you haven't already. The full CLA text is available in (CLA.md) (add a new file like `CLA.md` to the repo root).
- **Individual vs. Entity:** If contributing on behalf of a company, use the Entity CLA version.
- **No Revenue Share:** Signing the CLA does not entitle you to any revenue from commercial licenses—that remains at Flynn's discretion.

By submitting a PR, you agree to sign the CLA. Unsigned PRs will not be merged.

## Code of Conduct

- Be respectful and collaborative in issues, PRs, and discussions.
- Avoid off-topic, promotional, or commercial content.
- Report any violations of the license or these guidelines via email to the Creator (contact details in LICENSE if provided).

## Questions?

If you're unsure about the license or how your contribution fits, open an issue or contact the Creator directly. We're excited to see how you build on the Yggdrasil framework for personal creative projects!

The tree grows stronger with careful tending. 🌳
