# Data Folder

The `data` folder serves as the central repository for structured data assets, configurations, and procedural definitions used by the Yggdrasil Engine. These assets are essential for driving deterministic gameplay mechanisms, cosmological systems, creature definitions, and rune logic. The folder is organized into specific subfolders, each with its own role in shaping the engine's behavior and the immersive worlds it enables.

---

## Folder Structure

The `data` folder contains the following subfolders:

1. **agent/**
2. **cosmology/**
3. **creatures/**
4. **runes/**

Each subfolder serves a distinct purpose while adhering to the overarching procedural framework of the Yggdrasil Engine.

---

## 1. `agent/`

### Purpose (agent/)

The `agent/` subfolder contains data related to **Agents**, which are the procedural entities or players within the Yggdrasil Engine. This data governs how Agents are created, customized, and behave within the world.

### Key Files (agent/)

- **`agent-sigil-creation.json`**
  - **Description**: Defines the Sigil creation pipeline for Agents, including data mappings, numerology rules, celestial name generation, and Sigil projection methods (e.g., 9D to 2D visualization).
  - **Use**: Used during character creation to generate procedural signatures that drive behavior, gameplay traits, and cosmological affiliations.

- **`public-gift-tables.json`**
  - **Description**: Provides deterministic rules for assigning gifts (abilities) to Agents. Includes structural, metaphysical, modifier, mutation, and flavor gifts.
  - **Use**: Guides the augmentation of Agents with powers and traits based on their procedural characteristics.

---

## 2. `cosmology/`

### Purpose (cosmology/)

The `cosmology/` subfolder contains data defining the **cosmological framework of the Yggdrasil world**, including the Nine Planes of Existence and their interactions with procedural systems.

### Key Files (cosmology/)

- **`canonical-pattern-vectors.json`**
  - **Description**: Immutable definitions of the core entities that govern the planes of existence. Each entity has a deterministic pattern vector and plane alignment that influences gameplay and procedural logic.
  - **Use**: Drives interactions between Agents and entities, shapes world rules on each plane, and provides consistent cosmological fidelity.

- **`plane-properties.json`** *(future extension example)*
  - **Description**: Defines environmental properties unique to each plane (e.g., Plane 6: light coherence effects; Plane 8: entropy effects).
  - **Use**: Allows dynamic environmental generation based on the player’s plane alignment.

---

## 3. `creatures/`

### Purpose (creatures/)

The `creatures/` subfolder contains definitions for **procedural creatures** in the Yggdrasil world. These creatures are generated deterministically based on L-systems, pattern vectors, and rune alignment.

### Key Files (creatures/)

- **`creature-lsystem-definitions.json`**
  - **Description**: Contains L-system rulesets for defining creature body plans, growth patterns, and behaviors. Includes axiom, rules, angles, and other parameters.
  - **Use**: Drives creature procedural geometry and animation generation during gameplay.

- **`creature-traits-mapping.json`**
  - **Description**: Maps trait combinations (e.g., energy levels, symmetry) to precomputed creature behaviors and physical representations.
  - **Use**: Links procedural inputs (Sigils, environment data) to creature stats and aesthetics.

- **`creature-samples/`**
  - **Description**: A sample folder with predefined creatures (e.g., JSON files like `zebra-creature.json`).
  - **Use**: Provides examples for developers to understand the procedural generation framework.

---

## 4. `runes/`

### Purpose (runes/)

The `runes/` subfolder contains definitions for the **Elder Futhark Rune System**, which provides a secondary layer of augmentation and interaction within gameplay systems.

### Key Files (runes/)

- **`elder-futhark-9bit.json`**
  - **Description**: Encodes the Elder Futhark runes as 9-bit unique identifiers, with procedural mappings to powers and traits.
  - **Use**: Allows Agents and creatures to inherit or activate rune-based abilities deterministically.

- **`rune-precompute-tables.json`**
  - **Description**: Precomputations for all 512 (2^9) possible rune combinations, including parity (White Wolf / Dark Wolf alignments).
  - **Use**: Optimizes rune lookup and assignment during gameplay. Avoids runtime overhead for rune effect calculations.

- **`rune-effects-descriptions.json`**
  - **Description**: Links individual runes to detailed gameplay effects, lore descriptions, and compatibility rules.
  - **Use**: Enriches narrative depth and provides tailored rune-based mechanics.

---

## How to Use the Data

### In Development

1. **Agent Generation**:
   - Use files in `agent/` for Sigil creation, gift assignment, and Agent customization. These files are called during procedural pipelines for character initialization.
   - Example: Use `agent-sigil-creation.json` to convert player-defined character traits into Sigil-based procedural vectors.

2. **Worldbuilding & Environmental Rules**:
   - Use files in `cosmology/` to define the rules for each plane of existence and their interactions with Agents and creatures.
   - Example: Reference `canonical-pattern-vectors.json` to align procedural entities to their cosmological roles.

3. **Creature Creation**:
   - Use files in `creatures/` for generating dynamic, procedural creatures using L-systems and trait mappings.
   - Example: Use `creature-lsystem-definitions.json` to generate body geometries based on environment and rune alignment.

4. **Rune Augmentation**:
   - Use files in `runes/` to assign rune-based abilities and powers to Agents, creatures, or environmental objects.
   - Example: Use `rune-precompute-tables.json` to quickly determine the corresponding rune effects for a given 9-bit code.

---

## Integration Workflow Example

Here’s a general workflow for building a procedural gameplay loop:

1. **Agent Creation Pipeline**:
   - Extract player-defined character inputs (e.g., class, traits) and use `agent-sigil-creation.json` to generate procedural **Sigils**.
   - Assign gifts to Agents using `public-gift-tables.json`.

2. **World Interaction**:
   - Align Agent to the current plane using rules in `cosmology/canonical-pattern-vectors.json`.
   - Assign environmental effects based on plane rules (e.g., properties from future `plane-properties.json`).

3. **Creature Interaction**:
   - Generate procedural creatures using `creatures/creature-lsystem-definitions.json`.
   - Match creatures with the environment, rules, and rune alignments.

4. **Rune Integration**:
   - Allow Agents or creatures to acquire rune-based effects using files in `runes/`.

---

## Notes for Developers

- **Modifications**: While the data folder is designed for extensibility, maintain the deterministic and procedural design philosophy of the Yggdrasil Engine if extending these files.
- **File Fidelity**: Some files, such as `canonical-pattern-vectors.json`, are immutable and must remain consistent with the Yggdrasil cosmology.
- **Version Control**: Ensure all edits are versioned properly and consistent with the `version` field in each file.

---

## Contributing

If you would like to expand or modify the data folder:

1. Adhere to the engine’s procedural principles.
2. Ensure contributions are deterministic and align with the Yggdrasil Engine's design philosophy.
3. Open a pull request on GitHub with full documentation of your changes.
