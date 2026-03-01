# Yggdrasil Framework Pipelines – Code-Agnostic Reference

These pseudo-code snippets provide exact, deterministic implementations of the core subsystems. They are engine-neutral—port directly to C#, C++, Rust, etc. No rendering or assets required; outputs are data structures (e.g., L-system string, gift list) for your engine to interpret.

---

## Expanded Overview of the Framework

The **Yggdrasil Framework** is built on deterministic pipelines that capture procedural generation, cosmological alignment, and gameplay logic in a modular and engine-neutral way. Each pipeline represents a reusable algorithm for core subsystems like creature generation, rune activation, and plane alignment.

These pipelines are fully invariant and align with the following key principles:

- **Determinism**: Same input always produces the same output.
- **Engine Neutrality**: Math-driven and portable to any language/engine (C#, C++, Rust). No external dependencies.
- **Cosmological Fidelity**: Outputs align with the Yggdrasil Engine’s Nine-Plane system and metaphysical logic.
- **Expandability**: These pipelines are examples but can be extended based on game or system logic.

---

### General Mathematical Invariants

- **Plane Assignment Formula**: Defines alignment with the Nine-Plane cosmology.

  ```pseudo
  Plane = floor((C + S + P + (1 - H)) * 2.25) + 1 // Clamped to [1, 9]
  ```

- **ImprintKey Generation**: Create a deterministic SHA-256 hash of the `FeatureProfile`.
- **Rune Parity**: Count the number of `1` bits (popcount of 9-bit string):
  - Even → White Wolf (Preservers)
  - Odd → Dark Wolf (Transformers)
- **Drift Mechanism**: Applies minor uniform variations to metric-based systems:

  ```pseudo
  Drift = Uniform[-drift, +drift], clamped to [0, 1]
  ```

---

### Agent Tick Pipeline with Kripke Enforcement

Handles per-tick updates for agents, including drift, plane calculation, and Kripke enforcement.

```pseudo
# Full Agent Tick (integrate into simulation loops)
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

## Expanded Creature Generation Pipeline

This pipeline is a critical component of the framework. It transforms raw **sigil input** into a fully procedurally generated creature that includes:

- **Features**: Procedural traits like symmetry, fractal dimension, and entropy.
- **Gifts**: Deterministic abilities assigned based on the creature’s pattern vector.
- **Geometry**: Defined by L-systems for body plans.
- **Plane Alignment**: Placement within the Nine-Plane cosmology.

---

```pseudo
function GenerateCreature(sigilBytes: byte array) -> CreatureData
    // STEP 1: Threshold Binary Mask
    binaryMask = ThresholdAndClean(sigilBytes, threshold=128)  // 64x64 bitmap

    // STEP 2: Analyze Binary Mask into Feature Metrics
    metrics = ComputeFeatureProfile(binaryMask)
    // metrics = { H_entropy, K_complexity, D_fractal_dim, S_symmetry, L_generator_length }
    
    // STEP 3: ImprintKey Generation
    imprintKey = SHA256(SerializeMetrics(metrics))
    seed = BigInteger.Parse(imprintKey, Hex)

    // STEP 4: L-System Definition and Growth
    rng = DeterministicRNG(seed)
    lsystem = {
        axiom: ChooseFrom(["F", "X", "A"], rng),
        rules: DefaultRules(),
        angle: 22.5 + rng.NextFloat() * 30.0,
        iterations: 4 + rng.NextInt(6)
    }

    expandedLSystem = ExpandLSystem(lsystem.axiom, lsystem.rules, lsystem.iterations)

    // STEP 5: Gift Assignment
    gifts = EvaluateGifts("data/creatures/public-gift-tables.json")

    // STEP 6: Cosmological Plane Alignment
    plane = EstimatePlane(metrics)

    return {
        imprintKey: imprintKey,
        lsystem: lsystem,
        expandedString: expandedLSystem,
        gifts: gifts,
        plane: plane,
        metrics: metrics
    }
end function
```

---

### Step-By-Step Explanation

#### 1. Sigil Input and Binary Mask Generation

The input `sigilBytes` is a procedural or player-driven byte sequence. **ThresholdAndClean** converts this into a clean binary mask (e.g., 64x64 pixels) for metric extraction.

#### 2. Feature Metric Computation

The mask is analyzed to measure procedural features:

- **`H_entropy`**: Randomness or order within the mask.
- **`K_complexity`**: Compressibility proxy from the mask’s patterns.
- **`D_fractal_dim`**: Dimensional richness/scaling of patterns.
- **`S_symmetry`**: Reflection symmetry in vertical and horizontal axes.
- **`L_generator_length`**: Proxy measure for L-system generator complexity.

#### 3. ImprintKey Hashing

The deterministic SHA-256 hash of serialized metrics guarantees identical `imprintKey` generation for the same metrics.

#### 4. L-System Growth

The creature’s geometry is generated using the **L-system**:

- **Axiom**: The starting symbol (e.g., `F`, `X`, or `A`).
- **Rules**: Branching rules for recursive growth.
- **Angle**: Adjusts the angular direction of new branches.
- **Iterations**: Sets the depth of recursion.

#### 5. Gift Assignment

Evaluate the creature’s **metrics** against the rules in `public-gift-tables.json` to assign deterministic abilities. For example, high symmetry might give **SymmetryBloom**.

#### 6. Cosmological Plane Alignment

Maps the **metrics** to the Yggdrasil cosmology using the formula:

```plaintext
Plane = floor((K + S + D + (1 - H)) * 2.25) + 1
```

This determines its alignment within the Nine-Plane system.

---

## Rune Activation Pipeline

The Rune Activation Pipeline evaluates and applies rune-based procedural abilities.

### How It Works

When a rune is activated, its associated 9-bit string defines its **parity**:

- **Even popcount**: White Wolf (preservation, stability, pattern amplification).
- **Odd popcount**: Dark Wolf (transformation, chaos, symmetry-breaking).

---

```pseudo
function ActivateRune(runeId: string, target: AgentState) -> RuneEffect
    // STEP 1: Rune Data Loading
    runeData = LoadJSON("data/runes/elder-futhark-9bit.json", runeId)

    bits = runeData.bits  // e.g., "100110101"

    // STEP 2: Parity Check
    popcount = CountSetBits(bits)
    isWhiteWolf = (popcount mod 2 == 0)

    // STEP 3: Generate Rune Effect
    rng = DeterministicRNG(BigInt.Parse(bits, Binary))
    effect = {
        lsystemSpell: ExpandLSystem({
            axiom: "F",
            rules: ChooseRules(isWhiteWolf),
            angle: rng.NextFloat() * 90.0,
            iterations: 3 + rng.NextInt(4)
        }),
        alignment: isWhiteWolf ? "White Wolf" : "Dark Wolf"
    }

    // STEP 4: Apply Spell Effect
    if isWhiteWolf
        target.vector += SmallPositiveDrift(rng)
    else
        target.vector = InvertValues(target.vector, rng)
    end if

    return effect
end function
```

---

## Plane Calculation Pipeline

Maps entity metrics to the Nine-Plane cosmology.

### Formula

```pseudo
Plane = floor((K_complexity + S_symmetry + D_fractal_dim + (1 - H_entropy)) * 2.25) + 1
```

```json
Example Input:
{
  "K_complexity": 0.7,
  "S_symmetry": 0.9,
  "D_fractal_dim": 2.5,
  "H_entropy": 0.3
}
```

Example Output: `Plane = 6`

---

## Expanded Use Cases and Tools

1. **Unity Engine**: Use the `expandedString` from pipelines for procedural mesh generation with Unity’s LineRenderer or Mesh objects.
2. **Unreal Engine**: Integrate `expandedLSystem` output into `ProceduralMeshComponent` or particle effects.

Extendable for other gameplay layers—use structured deterministic outputs to control combat mechanics, interactions, or environmental transformations.
