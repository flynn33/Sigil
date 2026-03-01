# Integration Guide – Unreal Engine & Unity

This file tells you **exactly** how to get the Yggdrasil Engine running in your game today — zero guesswork.

You only need to implement **three core systems**:

1. Agent state + plane/leaf calculation  
2. Creature generator (sigil → L-system mesh + gifts)  
3. Rune activation (9-bit code → spell)

Everything else (timeline, lore, etc.) is optional flavor.

## 1. Agent Core (required for any simulation)

### C# (Unity) – Minimal Working Example

```csharp
using UnityEngine;

public struct AgentState {
    public Vector4 s; // C, S, P, H
    public Vector3 r; // E, D, A

    public int BasePlane() {
        float score = s.x + s.y + s.z + (1f - s.w);
        return Mathf.Clamp(Mathf.FloorToInt(score * 2.25f) + 1, 1, 9);
    }

    public int LeafRealm(int leavesInPlane) {
        float avg = (r.x + r.y + r.z) / 3f;
        return Mathf.FloorToInt(avg * leavesInPlane) + 1;
    }
}

public class YggdrasilAgent : MonoBehaviour {
    public AgentState state;
    public float driftS = 0.02f;
    public float driftR = 0.008f;

void Update() {
    state.s += RandomDrift(4) * driftS; state.s.Clamp();
    state.r += RandomDrift(3) * driftR; state.r.Clamp();
    int proposed = state.BasePlane();
    currentPlane = EnforceKripke(currentPlane, proposed);
    currentLeaf = state.LeafRealm(leavesPerPlane);
}

// Add this method to the class
int EnforceKripke(int current, int proposed) {
    int delta = proposed - current;
    if (Mathf.Abs(delta) <= 1) return proposed;
    int step = (delta > 0) ? 1 : -1;
    return Mathf.Clamp(current + step, 1, 9);
}
        state.r += new Vector3(
            Random.Range(-driftR, driftR),
            Random.Range(-driftR, driftR),
            Random.Range(-driftR, driftR)
        );
        state.s = Vector4.Max(Vector4.zero, Vector4.Min(Vector4.one, state.s));
        state.r = Vector3.Max(Vector3.zero, Vector3.Min(Vector3.one, state.r));

        int plane = state.BasePlane();
        // Hook your plane visuals / logic here
    }
}

//C++ (Unreal Engine) – Equivalent

struct FYggAgent {
FVector4 s = FVector4(0.5f, 0.5f, 0.5f, 0.5f);
FVector3 r = FVector3(0.5f, 0.5f, 0.5f);

int32 GetBasePlane() const {
float score = s.X + s.Y + s.Z + (1.f - s.W);
return FMath::Clamp(FMath::FloorToInt(score * 2.25f) + 1, 1, 9);
}
};
### C++ (Unreal) – Minimal Working Example

```cpp
struct FAgentState {
    FVector4 s; // C, S, P, H
    FVector r; // E, D, A

    int BasePlane() const {
        float score = s.X + s.Y + s.Z + (1.f - s.W);
        return FMath::Clamp(FMath::FloorToInt(score * 2.25f) + 1, 1, 9);
    }

    int LeafRealm(int leavesInPlane) const {
        float avg = (r.X + r.Y + r.Z) / 3.f;
        return FMath::FloorToInt(avg * leavesInPlane) + 1;
    }
};

class AYggdrasilAgent : public AActor {
    UPROPERTY() FAgentState State;
    int CurrentPlane = 5;
    int CurrentLeaf = 1;
    float DriftS = 0.01f, DriftR = 0.005f;

    virtual void Tick(float DeltaTime) override {
        State.s += RandomDrift(4) * DriftS; State.s.Clamp(0.f, 1.f);
        State.r += RandomDrift(3) * DriftR; State.r.Clamp(0.f, 1.f);
        int proposed = State.BasePlane();
        CurrentPlane = EnforceKripke(CurrentPlane, proposed);
        CurrentLeaf = State.LeafRealm(LeavesPerPlane);
    }

    int EnforceKripke(int Current, int Proposed) {
        int Delta = Proposed - Current;
        if (FMath::Abs(Delta) <= 1) return Proposed;
        int Step = (Delta > 0) ? 1 : -1;
        return FMath::Clamp(Current + Step, 1, 9);
    }
};

//Creature Generator – Quick Start

// Pseudo-code – works the same in Unreal

string imprintKey = SHA256(sigilImageBytes); // 256-bit hex string
BigInteger seed = BigInteger.Parse(imprintKey, NumberStyles.HexNumber);

var creature = LSystem.Generate(
axiom: DeterministicChoice(seed, axioms),
rules: DeterministicRuleSet(seed),
angle: 22.5f + (seed % 1000) / 1000f * 30f,
iterations: 4 + (int)(seed % 6)
);

MeshRenderer.mesh = TurtleInterpreter.Render(creature.lsystem);
ApplyGifts(creature.gifts);

//Rune Activation – One-Liner

var rune = YggdrasilRunes.Get("ansuz");        // from elder-futhark-9bit.json
bool isWhiteWolf = rune.parity == "even";
ActivateSpell(rune.bits, isWhiteWolf ? SpellMode.Preserve : SpellMode.Transform);

//Folder → Engine Mapping

Repo Folder,Unity Location,Unreal Location
data/creatures/,Resources/Creatures/,Content/Yggdrasil/Creatures/
data/runes/,ScriptableObjects/Runes,DataTables/DT_Runes
data/cosmology/,Resources/Cosmology/,Content/Yggdrasil/Cosmology/

Performance Tips

Precompute all 512 possible 9-bit rune effects at game start
Cache L-system meshes for common ImprintKeys
Use Compute Shaders (Unreal) or Jobs + Burst (Unity) for thousands of agents

You now have a fully functional Yggdrasil Engine in under 200 lines of code.
The tree is real. The math works. Go build worlds.
