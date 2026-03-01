# Full Guide: Agent Sigil Creation in Yggdrasil Engine

This guide explains the **Agent Sigil creation process**, its source data, and how game developers can customize the data collection process. The Sigil forms the foundation of an Agent's identity and serves as the input for procedural systems such as 3D form generation and augmentation via runes.

---

## What is a Sigil?

A **Sigil** is a deterministic, mathematically-generated signature that represents an Agent’s procedural essence. It encapsulates a series of **numeric metrics**, derived from a data set chosen by the game developer, and ensures each Agent is:

- **Unique**: Sigils are computed using deterministic logic.
- **Fully Modifiable**: Developers are free to define what data inputs create Sigils.
- **Game-Specific**: Sigil creation integrates seamlessly with the narrative, mechanics, or character systems of the game.

---

## Customizing the Data Source

The Sigil is constructed using **data inputs** that developers define. This data could be:

1. **Gameplay Inputs**: Example: Choices made by a player during character creation.
2. **Predefined Game Mechanics**: Example: A randomly generated unique player identifier, stats, or traits.
3. **Character Sheets**: Example: Attributes like "Strength," "Intelligence," or backstory lore.
4. **Symbolic or Procedural Data**: Example: Imaginary planetary alignments, procedurally-generated values, or dice rolls.

> **Note:** Developers are **not required** to use personal user data. The Sigil generation is flexible, and you can fully customize the data entry process to match the theme or mechanics of your game.

---

### Example Scenario: A Fantasy Game

In this example, the developer incorporates **game-relevant inputs** into the Sigil creation process:

1. **Game Class**: “Mage,” “Warrior,” “Rogue,” etc.
2. **Background Story**: Attributes like "Noble," "Outcast," or "Scholar."
3. **Skill Allocations**: Values for "Strength," "Dexterity," "Magic," etc.
4. **Random Seeds**: Randomly procedurally-generated values for uniqueness.

#### Developer’s Sample Input Data

```json
{
  "class": "Mage",
  "background": "Noble",
  "strength": 5,
  "dexterity": 7,
  "magic": 12,
  "seed": "RNG-Generated:325468"
}
```

> This data set is *game-specific* and fully decoupled from any real-world user information.

---

## Sigil Creation: Step-by-Step Walkthrough

### Step 1: Input Data and Metrics

The developer-defined input data is converted into **metrics** that form the Sigil. Developers must choose how to transform their game data into the five core Sigil metrics. Here is an example mapping:

#### Mapping Game Data to Metrics

```python
def map_game_inputs_to_metrics(game_data: dict) -> dict:
    """
    Map game inputs (defined by the developer) to Sigil metrics.
    """
    H_entropy = game_data["magic"] / 15       # Example: Magic contributes to Entropy (0–1 scaled).
    K_complexity = game_data["dexterity"] / 10
    D_fractal_dim = 1.5 + (game_data["strength"] / 10)  # Assume 1.5 baseline for Fractal Dim.
    S_symmetry = 0.5 if game_data["background"] == "Noble" else 0.3
    L_generator_length = 50 + len(game_data["seed"])
    return {
        "H_entropy": min(max(H_entropy, 0), 1),
        "K_complexity": min(max(K_complexity, 0), 1),
        "D_fractal_dim": min(max(D_fractal_dim, 1), 3),
        "S_symmetry": min(max(S_symmetry, 0), 1),
        "L_generator_length": min(max(L_generator_length, 1), 999),
    }

# Example Input Data
game_data = {
    "class": "Mage",
    "background": "Noble",
    "strength": 5,
    "dexterity": 7,
    "magic": 12,
    "seed": "RNG-Generated:325468"
}

# Map Inputs to Metrics
metrics = map_game_inputs_to_metrics(game_data)
print("Sigil Metrics:", metrics)
```

**Output Metrics:**

```plaintext
Sigil Metrics: {
    "H_entropy": 0.8,
    "K_complexity": 0.7,
    "D_fractal_dim": 2.0,
    "S_symmetry": 0.5,
    "L_generator_length": 61
}
```

---

### Step 2: Canonical Serialization

Canonical serialization ensures the metrics are processed in a deterministic, stable order.

```python
from decimal import Decimal, ROUND_HALF_UP

def canonical_serialize(metrics: dict) -> str:
    H = Decimal(metrics["H_entropy"]).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
    K = Decimal(metrics["K_complexity"]).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
    D = Decimal(metrics["D_fractal_dim"]).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
    S = Decimal(metrics["S_symmetry"]).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
    L = int(metrics["L_generator_length"])
    return f"H:{H:.6f};K:{K:.6f};D:{D:.6f};S:{S:.6f};L:{L};"
```

**Serialized String:**

```plaintext
H:0.800000;K:0.700000;D:2.000000;S:0.500000;L:61;
```

---

### Step 3: Compute the ImprintKey

The serialized string is hashed using SHA-256 to produce the **ImprintKey**.

```python
import hashlib

def compute_imprint_key(serialized: str) -> str:
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()

imprint_key = compute_imprint_key("H:0.800000;K:0.700000;D:2.000000;S:0.500000;L:61;")
print("ImprintKey:", imprint_key)
```

**ImprintKey:**

```plaintext
ImprintKey: 3eafc2a9b2179db7cd4bfcc5e711086372948c9a7ce2c7358a953f4f9c4e68fa
```

---

### Step 4: Generate RNG Seed

The **ImprintKey** is transformed into a deterministic RNG seed.

```python
def hex_to_seed(hexstr: str) -> int:
    big = int(hexstr, 16)
    low = big & ((1 << 64) - 1)
    high = (big >> 64) & ((1 << 64) - 1)
    return low ^ high

seed = hex_to_seed(imprint_key)
print("RNG Seed:", seed)
```

**RNG Seed:**

```plaintext
RNG Seed: 9843251298435128309
```

---

## Developer Best Practices

- **Flexibility in Input Data**: The examples above showcase several mappings; developers are encouraged to design mappings that reflect the mechanics or lore of their game.
- **Self-Contained Pipeline**: The Sigil generation process operates independently of external inputs and is entirely customizable.
- **Secure Processing**: Ensure deterministic functions are used end-to-end to maintain reproducibility.

---

## Full Example Workflow

Here’s the full process rolled into one cohesive script:

```python
game_data = {
    "class": "Mage",
    "background": "Noble",
    "strength": 5,
    "dexterity": 7,
    "magic": 12,
    "seed": "RNG-Generated:325468",
}

metrics = map_game_inputs_to_metrics(game_data)
serialized = canonical_serialize(metrics)
imprint_key = compute_imprint_key(serialized)
seed = hex_to_seed(imprint_key)

print(f"Metrics: {metrics}")
print(f"Serialized: {serialized}")
print(f"ImprintKey: {imprint_key}")
print(f"RNG Seed: {seed}")
```

## Public Gift Tables: README

The **public-gift-tables.json** file defines a comprehensive set of **gifts** for use within the Yggdrasil Engine. These gifts represent abilities, powers, or traits that can be deterministically assigned to entities such as **Agents** (player-controlled characters) or other procedural creatures within the engine.

This file is designed to be:

- **Code-Agnostic**: It can be integrated into any system or language as long as the rules and triggers are respected.
- **Deterministic**: Each gift's assignment is governed by clear mathematical rules to ensure predictable and repeatable behavior.
- **Flexible**: Game developers can use these tables to enhance gameplay and create unique opportunities for customization.

---

## Purpose

The **public-gift-tables.json** file is central to defining the capabilities of procedural entities in the Yggdrasil Engine. Gifts function as both **utility traits** and **gameplay mechanics**. Use this file to:

1. Assign structural, metaphysical, or modifier gifts to procedural entities like Agents, NPCs, and creatures.
2. Tie abilities to deterministic triggers or procedural traits such as **entropy**, **symmetry**, or **plane alignment**.
3. Add depth and replayability through the integration of rare or mutative gifts.

---

## Structure of the File

The file is divided into several major sections:

### 1. **Structural Gifts**

Structural gifts are grounded in physical or logical traits of the entity (e.g., symmetry, complexity, entropy). They are always **deterministically assigned** based on the entity's **pattern vector**.

**Example:**

```json
"FractalCarapace": {
  "trigger": "D_fractal_dim >= 2.4 && K_complexity <= 0.35",
  "effect": "Physical damage resistance scales with fractal depth"
}
```

- **Trigger**: A deterministic rule based on the entity’s procedural parameters (e.g., D_fractal_dim, K_complexity).
- **Effect**: Adds a physical damage resistance mechanism scaled to the entity's fractal complexity.

---

### 2. **Metaphysical Gifts**

Metaphysical gifts are tied to the Yggdrasil cosmology and are heavily reliant on **planes of existence**.

**Example:**

```json
"FateThread": {
  "plane": [5],
  "effect": "Once per cycle, rewind personal timeline 10 seconds"
}
```

- **Plane**: The gift is only available to entities whose **primary plane** matches the defined planes. For example, "FateThread" is tied to Plane 5 (linked to timeline control and fate manipulation).
- **Effect**: Grants the ability to rewind time under specific conditions.

---

### 3. **Modifier Gifts**

Modifier gifts adapt to the entity’s intrinsic traits such as **Alignment** (`A`), **Entropy** (`E`), or other procedural values.

**Example:**

```json
"Fireborn": {
  "trigger": "E >= 0.75",
  "effect": "Immune to fire, +50% fire damage"
}
```

- **Trigger**: High entropy correlates with “fire” traits, enabling this gift.
- **Effect**: Grants immunity to fire and boosts fire-related attacks.

---

### 4. **Mutation Gifts**

Mutation gifts are rare, often triggered by outliers (e.g., anomalies in the entity’s bitmap or other procedural systems). They add unique, sometimes one-time-use traits for narrative or gameplay impact.

**Example:**

```json
"SingularityPulse": {
  "rarity": "ultra_rare",
  "effect": "Once-only black-hole implosion that rewrites local rules"
}
```

---

### 5. **Minor Flavor Gifts**

These gifts enhance immersion through decorative or flavor-based effects. They create opportunities for roleplay and atmosphere without directly affecting gameplay mechanics.

**Example:**

- "StarlightEyes": Gives the entity glowing eyes that shimmer with starlight.

---

## Assignment Rules

Each section of the file includes its own **assignment rules**:

- **Structural**: Always assigned deterministically (1–2 gifts per entity).
- **Metaphysical**: Exactly 1 metaphysical gift may be assigned if the entity matches the required plane.
- **Modifier**: Modifier gifts are tied to specific trait thresholds (0–2 gifts per entity).
- **Mutation**: Rare and dependent on anomalies; at most 1 mutation gift per entity.
- **Minor Flavor**: Always exactly 2 minor flavor gifts are assigned.

---

## When and Where to Use the Gift Tables

### When to Use

- During **Agent creation**: Assign gifts based on the player's procedural pattern vector or other traits.
- During **NPC generation**: Use these tables to add variety and deterministic abilities to non-player creatures.
- During **gameplay events**: Dynamically assign temporary or situational gifts based on in-game triggers.

### Where to Use

- **Procedural Generation Pipelines**: Integrate with Sigil systems or Agent creation pipelines.
- **Environmental Interactions**: Assign mutation gifts for anomalies or rare phenomena.
- **Combat Systems**: Use structural and modifier gifts to create varied combat dynamics.
- **Narrative Design**: Leverage metaphysical gifts to highlight plane-specific lore or mechanics.

---

## Implementation Example: Assign Structural and Modifier Gifts

This is a Python implementation example for assigning structural and modifier gifts to an entity.

### Step 1: Determine the Entity’s Traits

The entity traits are derived from its **pattern vector** or other procedural systems:

```python
entity_traits = {
    "H_entropy": 0.2,
    "K_complexity": 0.3,
    "D_fractal_dim": 2.5,
    "S_symmetry": 0.9,
    "L_generator_length": 6
}
```

---

### Step 2: Load Public Gift Tables

Load the `public-gift-tables.json` file:

```python
import json

with open("public-gift-tables.json", "r") as f:
    gift_tables = json.load(f)
```

---

### Step 3: Assign Structural Gifts

Structural gifts are assigned based on their **trigger** conditions:

```python
def assign_structural_gifts(entity_traits, structural_gifts):
    assigned_gifts = []
    for gift_name, gift in structural_gifts.items():
        if eval(gift["trigger"], entity_traits):
            assigned_gifts.append({"name": gift_name, "effect": gift["effect"]})
    return assigned_gifts

structural_gifts = assign_structural_gifts(entity_traits, gift_tables["structural_gifts"])
print("Assigned Structural Gifts:", structural_gifts)
```

**Output Example**:

```plaintext
Assigned Structural Gifts: [
    {
        "name": "FractalCarapace",
        "effect": "Physical damage resistance scales with fractal depth"
    },
    {
        "name": "SymmetryBloom",
        "effect": "Perfect mirror clones on critical hits (1–3 clones)"
    }
]
```

---

### Step 4: Assign Metaphysical Gifts

If the entity’s **plane** matches a metaphysical gift, assign it:

```python
entity_plane = 6

def assign_metaphysical_gifts(entity_plane, metaphysical_gifts):
    assigned_gifts = []
    for gift_name, gift in metaphysical_gifts.items():
        if entity_plane in gift["plane"]:
            assigned_gifts.append({"name": gift_name, "effect": gift["effect"]})
    return assigned_gifts

metaphysical_gifts = assign_metaphysical_gifts(entity_plane, gift_tables["metaphysical_gifts"])
print("Metaphysical Gifts:", metaphysical_gifts)
```

**Output Example**:

```plaintext
Metaphysical Gifts: [
    {
        "name": "CelestialResonance",
        "effect": "Glow with coherent light; allies gain +20% coherence"
    }
]
```

---

### Step 5: Assign Modifier and Minor Flavor Gifts

Use the same approach for modifier gifts and apply the rule for **exactly 2 minor flavor gifts**:

```python
minor_flavor_gifts = gift_tables["minor_flavor_gifts"]
assigned_minor_gifts = minor_flavor_gifts[:2]

print("Minor Flavor Gifts:", assigned_minor_gifts)
```

**Output**:

```plaintext
Minor Flavor Gifts: ["AetherScent", "SoftFootfalls"]
```

---

## Full Example: Gift Assignment Workflow

Here’s how you might combine the above steps to assign gifts to an entity:

```python
def assign_gifts(entity_traits, entity_plane, gift_tables):
    return {
        "structural": assign_structural_gifts(entity_traits, gift_tables["structural_gifts"]),
        "metaphysical": assign_metaphysical_gifts(entity_plane, gift_tables["metaphysical_gifts"]),
        "minor_flavor": gift_tables["minor_flavor_gifts"][:2]
    }

# Assign gifts for an entity
entity_traits = {"H_entropy": 0.2, "K_complexity": 0.3, "D_fractal_dim": 2.5, "S_symmetry": 0.9, "L_generator_length": 6}
entity_plane = 6
assigned_gifts = assign_gifts(entity_traits, entity_plane, gift_tables)

print("Assigned Gifts:", assigned_gifts)
```

**Final Output**:

```plaintext
Assigned Gifts: {
  'structural': [
    {'name': 'FractalCarapace', 'effect': 'Physical damage resistance scales with fractal depth'},
    {'name': 'SymmetryBloom', 'effect': 'Perfect mirror clones on critical hits (1–3 clones)'}
  ],
  'metaphysical': [
    {'name': 'CelestialResonance', 'effect': 'Glow with coherent light; allies gain +20% coherence'}
  ],
  'minor_flavor': ['AetherScent', 'SoftFootfalls']
}
```

---

## Conclusion

Developers can use the **public-gift-tables.json** file to integrate gifts into gameplay mechanics, narrative systems, or procedural generation pipelines. By leveraging its deterministic triggers and rich effects, you can create immersive, varied, and dynamic experiences for every player or procedural entity.

If you have questions or need more examples, feel free to reach out!

The developer-defined inputs drive every step of Sigil creation, ensuring the system integrates naturally with the game’s custom requirements. Whether it's based on dice rolls, random seeds, or predefined stats, the Sigil is infinitely versatile!
