# Core Folder – Detailed Pipelines, Explanations, and Examples

The **core folder** is the heart of the Yggdrasil Engine. It contains the pipelines, modularized logic, and deterministic rules that define the framework. The systems within this folder are designed to be **engine-neutral**, allowing developers to easily port them into their game. These pipelines support procedural generation, gameplay systems, and cosmological interactions.

The `core/` directory implements the deterministic blueprints for:

1. **Sigil Creation**
2. **Creature Generation**
3. **Rune Activation**
4. **Plane Calculations**
5. **Gift Assignment**
6. **Cosmological Rules**
7. **Agent Interaction**
8. (Optional) **Mutation Mechanics**

This document provides complete implementations, detailed explanations, and examples for these systems to help developers integrate them into their projects.

---

## 1. Sigil Creation Pipeline

The **Sigil Creation Pipeline** converts player-defined or procedurally-generated traits into a **Sigil**. A Sigil is a procedural "signature" used to drive deterministic systems in the Yggdrasil Engine.

### Purpose — Sigil Creation

- **Determine the Agent's Identity**: Procedural starting point for Agents.
- **Provide Procedural Traits**: Outputs metrics such as entropy, fractal dimension, symmetry, and generator length.
- **Ensure Determinism**: Same input traits will always produce the same Sigil.

### Inputs — Sigil Creation

- Player-defined inputs (e.g., game character creation choices).
- Procedurally derived data (e.g., random seeds).

### Pseudo-Code — Sigil Creation

```pseudo
function CreateSigil(inputTraits: dict) -> Sigil
    // Step 1: Normalize Inputs
    normalizedInputs = NormalizeTraits(inputTraits)

    // Step 2: Serialize Inputs into Canonical Form
    serialized = SerializeInputs(normalizedInputs)

    // Step 3: Hash Serialized String into ImprintKey
    imprintKey = SHA256(serialized)

    // Step 4: Convert ImprintKey to Seed
    seed = BigInteger.Parse(imprintKey, Hex)

    // Step 5: Generate Sigil Metrics
    metrics = {
        H_entropy: ComputeEntropy(normalizedInputs),
        K_complexity: ComputeComplexity(normalizedInputs),
        D_fractal_dim: ComputeFractalDimension(normalizedInputs),
        S_symmetry: ComputeSymmetry(normalizedInputs),
        L_generator_length: ComputeGeneratorLength(normalizedInputs)
    }

    return { SigilBytes: seed, Metrics: metrics, ImprintKey: imprintKey }
end function
```

### Example Input and Output

#### Input Traits Example

```json
{
  "class": "Mage",
  "background": "Noble",
  "strength": 5,
  "dexterity": 7,
  "magic": 12,
  "randomSeed": "325468"
}
```

#### Output Example

```json
{
  "SigilBytes": "107584932184256",
  "Metrics": {
    "H_entropy": 0.25,
    "K_complexity": 0.55,
    "D_fractal_dim": 2.75,
    "S_symmetry": 0.80,
    "L_generator_length": 12
  },
  "ImprintKey": "9a7b6c3d1f..."
}
```

---

## 2. Creature Generation Pipeline

The **Creature Generation Pipeline** determines the physical structure, traits, and function of procedural creatures in the game.

### Purpose — Creature Generation

- Define deterministic procedural body plans using **L-systems**.
- Assign **Gift Abilities** based on the creature’s procedural **metrics**.
- Align the creature to the **Nine-Plane Cosmology**.

### Inputs — Creature Generation

- Sigil bytes from the **Sigil** system.
- Threshold-cleaned binary mask to compute metrics (optional).

### Pseudo-Code — Creature Generation

```pseudo
function GenerateCreature(sigilBytes: byte array) -> Creature
    binaryMask = ThresholdAndClean(sigilBytes, threshold=128)

    metrics = ComputeFeatureMetrics(binaryMask)

    imprintKeyHex = SHA256( Serialize(metrics.H, metrics.K, metrics.D, metrics.S, metrics.L) )
    seed = BigInteger.Parse(imprintKeyHex, Hex)

    rng = DeterministicRNG(seed)

    lsystem = {
        axiom: ChooseFrom(["F", "X", "A"], rng),
        rules: GenerateBranchingRules(rng),
        angle: 22.5 + rng.NextFloat() * 30.0,
        iterations: 4 + rng.NextInt(6)
    }
    
    expandedString = ExpandLSystem(lsystem.axiom, lsystem.rules, lsystem.iterations)

    gifts = AssignGifts(metrics)

    plane = EstimatePlaneFromMetrics(metrics)

    return { lsystemString: expandedString, gifts: gifts, plane: plane }
end function
```

---

## 3. Rune Activation Pipeline

The **Rune Activation Pipeline** transforms Elder Futhark rune data into deterministic spell effects or state changes.

### Purpose — Rune Activation

- Add **rune-based powers or spells** for Agents or Entities.
- Use **parity (binary)** to encode cosmological alignment (White Wolf = preserve; Dark Wolf = transform).
- Generate **spell-like procedural L-systems** for direct application.

### Inputs — Rune Activation

- Rune ID from the Elder Futhark rune table (`runeId`).
- Target AgentState for applying the rune’s effects.

### Pseudo-Code — Rune Activation

```pseudo
function ActivateRune(runeId: string, targetState: AgentState) -> RuneEffect
    runeData = LoadFromJSON("data/runes/elder-futhark-9bit.json", id=runeId)

    bits9 = runeData.bits
    popcount = CountBitsSet(bits9)
    isWhiteWolf = popcount mod 2 == 0

    rng = DeterministicRNG(BigInteger.Parse(bits9, Binary))

    lsystem = {
        axiom: "F",
        rules: ChooseTransformRule(rng, isWhiteWolf),
        angle: rng.NextFloat() * 90.0,
        iterations: 3 + rng.NextInt(4)
    }

    effect = {
        lsystemOutput: ExpandLSystem(lsystem.axiom, lsystem.rules, lsystem.iterations),
        type: isWhiteWolf ? "preserve/amplify" : "break/transform"
    }

    targetState.ApplyRuneEffect(effect)

    return effect
end function
```

---

## 4. Plane Calculation Pipeline

### Purpose — Plane Calculation

To calculate the **cosmological plane** of an entity based on procedural metrics. Each plane corresponds to a metaphysical or physical layer in the cosmology.

### Plane Formula

```pseudo
floor((C + S + P + (1 - H)) * 2.25) + 1
```

---

## 5. Gift Assignment Pipeline

### Purpose — Gift Assignment

To assign abilities to procedural creatures or Agents based on their metrics. Uses deterministic rules provided in `public-gift-tables.json`.

### Examples

- **Structural Gift**: `FractalCarapace` for high fractal dimensions.
- **Metaphysical Gift**: `FateThread` for entities aligned to Plane 5.

---

## 6. Cosmological Rules

### Purpose — Cosmological Rules

Defines the deterministic rules of cosmology (e.g., plane traversals, plane influences, adjacency rules).

---

## Integration Workflow

1. **Initialize Agent Sigils**: Use the Sigil pipeline to define procedural agents.
2. **Generate Creatures**: Use the Creature Generation Pipeline, augmented with L-systems and gifts.
3. **Apply Runes**: Dynamically activate runes in gameplay using the Rune Activation Pipeline.
4. **Determine Plane Alignment**: Calculate plane alignment to restrict or expand player choices.

---

## Examples in Unity/Unreal

Developers can adapt the pipelines to Unity (C#), Unreal (C++), or other engines. For example:

- **L-Systems** could generate procedural meshes.
- **Gift Assignment** could trigger gameplay-defining abilities.
- **Rune Activation** could control particle effects or combat mechanics.
