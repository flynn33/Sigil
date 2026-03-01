// Yggdrasil Engine Swift Prototype – Fully Fixed & Compilable
// Save as main.swift
// Run: swift main.swift   (or compile with swiftc main.swift -o yggdrasil_demo && ./yggdrasil_demo)

import Foundation

let planeNames = [
    "", "Physical", "Etheric", "Astral", "Mental", "Causal",
    "Celestial", "Shadow", "Void", "Divine Core"
]

struct Vector4 {
    var x, y, z, w: Double
    
    mutating func clamp(min: Double = 0.0, max: Double = 1.0) {
        x = Swift.max(min, Swift.min(max, x))
        y = Swift.max(min, Swift.min(max, y))
        z = Swift.max(min, Swift.min(max, z))
        w = Swift.max(min, Swift.min(max, w))
    }
}

struct Vector3 {
    var x, y, z: Double
    
    mutating func clamp(min: Double = 0.0, max: Double = 1.0) {
        x = Swift.max(min, Swift.min(max, x))
        y = Swift.max(min, Swift.min(max, y))
        z = Swift.max(min, Swift.min(max, z))
    }
}

class YggdrasilAgent {
    var s: Vector4
    var r: Vector3
    var currentPlane: Int
    var history: [Int]
    
    init(s: Vector4 = Vector4(x: Double.random(in: 0...1), y: Double.random(in: 0...1), z: Double.random(in: 0...1), w: Double.random(in: 0...1)),
         r: Vector3 = Vector3(x: Double.random(in: 0...1), y: Double.random(in: 0...1), z: Double.random(in: 0...1))) {
        self.s = s
        self.r = r
        
        // Inline computation to avoid calling instance method before init complete
        let score = s.x + s.y + s.z + (1.0 - s.w)
        let plane = Int(floor(score * 2.25) + 1)
        self.currentPlane = max(1, min(9, plane))
        
        self.history = [self.currentPlane]
    }
    
    private func computeBasePlane() -> Int {
        let score = s.x + s.y + s.z + (1.0 - s.w)
        let plane = Int(floor(score * 2.25) + 1)
        return max(1, min(9, plane))
    }
    
    func tick() {
        let dsx = Double.random(in: -0.02...0.02)
        let dsy = Double.random(in: -0.02...0.02)
        let dsz = Double.random(in: -0.02...0.02)
        let dsw = Double.random(in: -0.02...0.02)
        s.x += dsx
        s.y += dsy
        s.z += dsz
        s.w += dsw
        s.clamp()
        
        let drx = Double.random(in: -0.008...0.008)
        let dry = Double.random(in: -0.008...0.008)
        let drz = Double.random(in: -0.008...0.008)
        r.x += drx
        r.y += dry
        r.z += drz
        r.clamp()
        
       // Kripke Transition: p_t(c, p_b) = { p_b if |p_b - c| <= 1; c + sgn(p_b - c) otherwise }, clamped to [1,9]
    let proposed = computeBasePlane()
        if abs(proposed - currentPlane) > 1 {
            currentPlane += proposed > currentPlane ? 1 : -1
            currentPlane = max(1, min(9, currentPlane))  // Ensure clamped after snap
        }       else {
                        currentPlane = proposed
                    }
history.append(currentPlane)
    }
}

func simulate(nAgents: Int = 1000, ticks: Int = 1000, seed: UInt64 = 42) -> ([[Int]], [YggdrasilAgent]) {
    // Note: Random is not seeded for simplicity; runs differently each time but demonstrates the engine
    var agents: [YggdrasilAgent] = []
    for _ in 0..<nAgents {
        agents.append(YggdrasilAgent())
    }
    var history: [[Int]] = agents.map { [$0.currentPlane] }
    
    for _ in 1...ticks {
        for i in 0..<nAgents {
            agents[i].tick()
            history[i].append(agents[i].currentPlane)
        }
    }
    return (history, agents)
}

struct LSystem {
    let axiom: String
    let rules: [Character: String]
    let angle: Double
    let iterations: Int
}

func generateCreature(sigilText: String = "FEHU") -> LSystem {
    // Simple non-seeded random for demo; consistent runs same if needed
    let axioms = ["F", "X", "A"]
    let axiomIndex = Int(arc4random_uniform(UInt32(axioms.count)))
    let axiom = axioms[axiomIndex]
    
    let possibleFRules = ["F[+F]F[-F]F", "FF-[-F+F+F]+[+F-F-F]"]
    let fRuleIndex = Int(arc4random_uniform(2))
    let fRule = possibleFRules[fRuleIndex]
    
    let rules: [Character: String] = [
        "F": fRule,
        "X": "[X]FX",
        "A": "A[+F]F[-F]A"
    ]
    
    let angles = [22.5, 25.7, 30.0, 36.0, 45.0]
    let angleIndex = Int(arc4random_uniform(UInt32(angles.count)))
    let angle = angles[angleIndex]
    
    let iterations = Int(arc4random_uniform(4)) + 4  // 4-7
    
    return LSystem(axiom: axiom, rules: rules, angle: angle, iterations: iterations)
}

func printLSystemStats(_ lsystem: LSystem) {
    func expand(_ start: String, rules: [Character: String], iterations: Int) -> String {
        var current = start
        for _ in 0..<iterations {
            current = current.reduce("") { $0 + (rules[$1] ?? String($1)) }
        }
        return current
    }
    
    let commands = expand(lsystem.axiom, rules: lsystem.rules, iterations: lsystem.iterations)
    let forwards = commands.filter { $0 == "F" || $0 == "G" }.count
    let branches = commands.filter { $0 == "[" }.count
    
    print("Creature L-System Stats:")
    print("  Axiom: \(lsystem.axiom)")
    print("  Iterations: \(lsystem.iterations)")
    print("  Angle: \(lsystem.angle)°")
    print("  Rules: \(lsystem.rules)")
    print("  Forward segments (approx body parts): \(forwards)")
    print("  Branches: \(branches)")
    print("  Command string length: \(commands.count)")
    print("  Sample commands prefix: \(commands.prefix(50))...")
}

print("🌳 Yggdrasil Engine Swift Prototype 🌳")
print("Simulating 1000 agents over 1000 ticks...\n")

let (history, agents) = simulate()

// Initial distribution
var initial = Array(repeating: 0, count: 10)
for h in history { initial[h[0]] += 1 }

print("Initial Distribution:")
for p in 1...9 {
    let pct = Double(initial[p]) * 100.0 / Double(history.count)
    let namePrefix = planeNames[p].prefix(8)
    print("Plane \(p) (\(namePrefix.padding(toLength: 8, withPad: " ", startingAt: 0))): \(String(format: "%.1f", pct))%")
}

// Final distribution
var finalDist = Array(repeating: 0, count: 10)
for h in history { finalDist[h.last!] += 1 }

print("\nFinal Distribution:")
for p in 1...9 {
    let pct = Double(finalDist[p]) * 100.0 / Double(history.count)
    let namePrefix = planeNames[p].prefix(8)
    print("Plane \(p) (\(namePrefix.padding(toLength: 8, withPad: " ", startingAt: 0))): \(String(format: "%.1f", pct))%")
}

// Sample agent journey (first 30 ticks for brevity)
print("\nSample Agent Journey (first 30 ticks):")
let sample = agents[0].history.prefix(30)
for (tick, plane) in sample.enumerated() {
    print("Tick \(String(format: "%4d", tick)) → Plane \(plane) (\(planeNames[plane]))")
}

// Creature generation
print("\n🦉 Generating creature from sigil \"FEHU\"...")
let creature = generateCreature(sigilText: "FEHU")
printLSystemStats(creature)

print("\n✅ Done! The tree grows. (Randomness not seeded; rerun for variations.)")
print("To extend: Add full hashing/seeding if needed.")
