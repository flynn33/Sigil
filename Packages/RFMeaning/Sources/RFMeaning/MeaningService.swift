import CryptoKit
import Foundation
import RFCoreModels
import RFEngineData

public protocol MeaningService: Sendable {
    func composeMeaning(from result: SigilResult, loreData: LoreDataset) -> MeaningNarrative
}

public final class DefaultMeaningService: MeaningService, Sendable {
    public init() {}

    public func composeMeaning(from result: SigilResult, loreData: LoreDataset) -> MeaningNarrative {
        let plane = estimatePlane(result.vector)
        let planeCodex = planeCodex(for: plane, in: loreData.planes)
        let axiom = mappedAxiom(for: plane, axioms: loreData.axioms)
        let rune = bestMatchingRune(bits: result.bits9.bits, from: loreData.runes)
        let nearestPatternEntity = nearestEntity(to: result.vector, in: loreData.canonicalEntities)
        let dominantPlaneCode = result.codexInsights?.dominantPlaneCode ?? "P\(plane)"
        let wolfBalance = wolfBalanceCategory(from: result.codexInsights?.wolfAlignment)
        let planeLabel = planeCodex.map { "Plane \(plane) (\($0.name))" } ?? "Plane \(plane)"
        let worldSeedHex = codexSeedHex(for: result)
        let numerology = numerologyProfile(from: result, plane: plane)

        let originFragment = originFragment(for: dominantPlaneCode)
        let thresholdFragment = thresholdFragment(for: wolfBalance)
        let planeLensFragment = planeLensFragment(
            dominantPlaneCode: dominantPlaneCode,
            planeLabel: planeLabel,
            planeCodex: planeCodex
        )
        let wolfCompanionFragment = wolfCompanionFragment(for: wolfBalance, dominantPlaneCode: dominantPlaneCode)
        let personalProphecy = personalProphecyFragment(
            worldSeedHex: worldSeedHex,
            dominantPlaneCode: dominantPlaneCode,
            wolfBalance: wolfBalance
        )
        let branchHooks = branchHooksFragment(
            worldSeedHex: worldSeedHex,
            dominantPlaneCode: dominantPlaneCode,
            wolfBalance: wolfBalance
        )

        let summary = [
            "Your sigil resolves to \(planeLabel), expressing a \(result.bits9.parity.rawValue)-parity arc.",
            "Wolf balance reads as \(wolfBalance.displayLabel).",
            "Rune affinity converges on \(rune?.name ?? "an untyped glyph").",
            "Numerology resolves as Life Path \(numerology.lifePath), integration digit \(numerology.integration).",
            result.codexInsights?.luciferianPublicDescription ?? "Codex alignment remains within standard thresholds."
        ]
            .joined(separator: " ")
            .pipe(sanitizeCanonicalLeaks(in:))

        let cosmologySection: String = {
            guard let planeCodex else {
                return "Cosmology: \(planeLabel) marks your position in the nine-plane ladder, balancing entropy \(format(result.vector.H_entropy)) with symmetry \(format(result.vector.S_symmetry))."
            }

            let physicsSample = planeCodex.physics.prefix(2).joined(separator: " • ")
            if physicsSample.isEmpty {
                return "Cosmology: \(planeLabel) is defined as \(planeCodex.role)."
            }
            return "Cosmology: \(planeLabel) is defined as \(planeCodex.role). Field traits: \(physicsSample)."
        }()

        let axiomSection: String = {
            guard let axiom else {
                return "Canonical Axiom: No mapped axiom found for this plane in the bundled archive."
            }

            let implication = personalizedAxiomImplication(for: axiom, result: result)
            let readableName = displayAxiomName(axiom.name)
            return idiomSection(
                title: "Canonical Axiom \(axiom.id) (\(readableName))",
                idiomMeaning: axiom.summary,
                sigilApplication: implication
            )
        }()

        let codexOriginSection = idiomSection(
            title: "Codex Origin",
            idiomMeaning: "Origin describes your primordial narrative stance: whether your pattern enters through shadow pressure, ordered coherence, or the dream-to-choice corridor.",
            sigilApplication: "\(originFragment) Your vector entropy is \(format(result.vector.H_entropy)) and symmetry is \(format(result.vector.S_symmetry)), which places your starting tone in \(dominantPlaneCode)."
        )
        let codexPlaneLensSection = idiomSection(
            title: "Plane Lens",
            idiomMeaning: "Plane Lens defines the existential filter through which your choices, relationships, and symbolic patterns are interpreted.",
            sigilApplication: "\(planeLensFragment) This is driven by your sigil plane estimate (\(planeLabel)) and complexity/fractal profile K=\(format(result.vector.K_complexity)), D=\(format(result.vector.D_fractal_dim))."
        )
        let codexWolfSection = idiomSection(
            title: "Wolf Companion",
            idiomMeaning: "Wolf Companion encodes your alignment dynamic: white-dominant, dark-dominant, or balanced; this idiom governs how you integrate order and pressure.",
            sigilApplication: "\(wolfCompanionFragment) Your current wolf balance is \(wolfBalance.displayLabel) and your sigil symmetry is \(format(result.vector.S_symmetry))."
        )
        let codexThresholdSection = idiomSection(
            title: "Threshold",
            idiomMeaning: "Threshold marks transition points where an old pattern no longer carries you and a new pattern must be embodied through action.",
            sigilApplication: "\(thresholdFragment) The threshold pressure is amplified by your parity (\(result.bits9.parity.rawValue)) and generator length L=\(result.vector.L_generator_length)."
        )
        let codexProphecySection = idiomSection(
            title: "Personal Prophecy",
            idiomMeaning: "Personal Prophecy is a deterministic narrative seed from your codex signature; it is guidance for interpretation, not fixed fate.",
            sigilApplication: "\(personalProphecy) This fragment is generated from your sigil-derived world seed signature \(String(worldSeedHex.prefix(12)))."
        )
        let branchHooksSection = idiomSection(
            title: "Branch Hooks",
            idiomMeaning: "Branch Hooks represent A6 branching dynamics: high-impact choice axes, shadow costs, and integration rewards tied to your current pattern.",
            sigilApplication: "\(branchHooks) Hooks are derived deterministically from your sigil seed and weighted toward \(dominantPlaneCode) with \(wolfBalance.displayLabel) balance."
        )
        let numerologyCoreSection = idiomSection(
            title: "Numerology Core Matrix",
            idiomMeaning: "Core Matrix extracts deterministic numerology channels from your sigil vector, life path, bit parity, and plane signature.",
            sigilApplication: numerologyCoreApplication(numerology)
        )
        let numerologyChannelsSection = idiomSection(
            title: "Numerology Channel Reading",
            idiomMeaning: "Channel Reading decodes how identity, time, ancestry, place, manifestation, and parity interact in your current cycle.",
            sigilApplication: numerologyChannelsApplication(numerology)
        )
        let numerologySynthesisSection = idiomSection(
            title: "Numerology Synthesis",
            idiomMeaning: "Synthesis combines your integration and tension digits to identify growth leverage and probable friction points.",
            sigilApplication: numerologySynthesisApplication(
                numerology,
                worldSeedHex: worldSeedHex,
                nearestPatternEntity: nearestPatternEntity
            )
        )

        let sections = [
            cosmologySection,
            axiomSection,
            codexOriginSection,
            codexPlaneLensSection,
            codexWolfSection,
            codexThresholdSection,
            codexProphecySection,
            branchHooksSection,
            numerologyCoreSection,
            numerologyChannelsSection,
            numerologySynthesisSection,
            idiomSection(
                title: "Pattern Vector",
                idiomMeaning: "Pattern Vector is the mathematical fingerprint of your sigil state across entropy (H), complexity (K), fractal dimension (D), symmetry (S), and generator length (L).",
                sigilApplication: "Your current values are H=\(format(result.vector.H_entropy)), K=\(format(result.vector.K_complexity)), D=\(format(result.vector.D_fractal_dim)), S=\(format(result.vector.S_symmetry)), L=\(result.vector.L_generator_length)."
            ),
            idiomSection(
                title: "Rune Signature",
                idiomMeaning: "Rune Signature is the nearest symbolic expression of your 9-bit pattern and parity state.",
                sigilApplication: "Your signature resolves to \(rune?.name ?? "Unknown") (\(rune?.character ?? "?")), interpreted as \(rune?.meaning ?? "a personal transition"), with \(result.bits9.parity.rawValue) parity."
            ),
            idiomSection(
                title: "Codex Profile",
                idiomMeaning: "Codex Profile aggregates numerology and structural parameters into a compact reading frame for your active sigil.",
                sigilApplication: codexSection(from: result.codexInsights)
            ),
            idiomSection(
                title: "Celestial Name",
                idiomMeaning: "Celestial Name is your deterministic mythic identifier generated from canonical vector features.",
                sigilApplication: "Your current celestial identifier is \(result.celestialName)."
            )
        ].map { sanitizeCanonicalLeaks(in: $0) }

        return MeaningNarrative(
            title: "Sigil Reading",
            celestialName: result.celestialName,
            summary: summary,
            sections: sections
        )
    }

    private func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private func estimatePlane(_ vector: CanonicalVector) -> Int {
        let normalizedD = ((vector.D_fractal_dim - 1) / 2).clamped(to: 0...1)
        let score = vector.K_complexity + vector.S_symmetry + normalizedD + (1 - vector.H_entropy)
        return Int(floor(score * 2.25) + 1).clamped(to: 1...9)
    }

    private func planeCodex(for id: Int, in planes: [PlaneCodex]) -> PlaneCodex? {
        planes.first { $0.id == id }
    }

    private func mappedAxiom(for plane: Int, axioms: [AxiomCodex]) -> AxiomCodex? {
        guard !axioms.isEmpty else { return nil }
        let index = (plane - 1).clamped(to: 0...(Int.max - 1)) % axioms.count
        return axioms[index]
    }

    private func mythicPrinciple(id: String, in principles: [MythicPrinciple]) -> MythicPrinciple? {
        principles.first { $0.id == id }
    }

    private func nearestEntity(to vector: CanonicalVector, in entities: [LoreEntity]) -> LoreEntity? {
        entities.min { lhs, rhs in
            distance(vector, lhs.vector) < distance(vector, rhs.vector)
        }
    }

    private func distance(_ v: CanonicalVector, _ p: LoreEntity.PatternVector) -> Double {
        let dh = v.H_entropy - p.H_entropy
        let dk = v.K_complexity - p.K_complexity
        let dd = v.D_fractal_dim - p.D_fractal_dim
        let ds = v.S_symmetry - p.S_symmetry
        let dl = (Double(v.L_generator_length) - Double(p.L_generator_length)) / 999
        return sqrt(dh * dh + dk * dk + dd * dd + ds * ds + dl * dl)
    }

    private func bestMatchingRune(bits: String, from runes: [RuneDescriptor]) -> RuneDescriptor? {
        runes.min { lhs, rhs in
            hamming(bits, lhs.bits) < hamming(bits, rhs.bits)
        }
    }

    private func hamming(_ a: String, _ b: String) -> Int {
        let left = Array(a)
        let right = Array(b)
        return zip(left, right).reduce(0) { $0 + ($1.0 == $1.1 ? 0 : 1) }
    }

    private func codexSection(from insights: CodexInsights?) -> String {
        guard let insights else {
            return "Codex Profile: Additional codex metadata unavailable for this sigil."
        }

        return [
            "Codex Profile: Life Path \(insights.lifePathNumber), \(insights.dominantPlaneCode), wolf alignment \(insights.wolfAlignment).",
            "Sigil Params: sides=\(insights.sigilParameters.polygonSides), layers=\(insights.sigilParameters.radialLayers), symmetry=\(insights.sigilParameters.symmetryOrder), distortion=\(format(insights.sigilParameters.distortionFactor)), overlay=\(insights.sigilParameters.wolfOverlayType).",
            "Branching Reflection: \(insights.branchingReflectionText)"
        ].joined(separator: " ")
    }

    private func codexSeedHex(for result: SigilResult) -> String {
        let material = [
            "RF_PERSONAL_CODEX_MASTER_SPEC_V1",
            result.profileID.uuidString.lowercased(),
            result.vector.canonicalSerialized(),
            result.bits9.bits,
            result.celestialName.lowercased(),
            result.geometryHash.lowercased(),
            result.codexInsights?.dominantPlaneCode.lowercased() ?? "",
            result.codexInsights?.wolfAlignment.lowercased() ?? ""
        ].joined(separator: "|")
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private struct NumerologyProfile: Sendable {
        let lifePath: Int
        let nameCurrent: Int
        let ancestryCurrent: Int
        let placeCurrent: Int
        let manifestationCurrent: Int
        let parityCurrent: Int
        let planeCurrent: Int
        let integration: Int
        let tension: Int
    }

    private struct NumerologyArchetype: Sendable {
        let title: String
        let gift: String
        let challenge: String
        let practice: String
    }

    private func numerologyProfile(from result: SigilResult, plane: Int) -> NumerologyProfile {
        let lifePath = (result.codexInsights?.lifePathNumber ?? digitFromUnitInterval(result.vector.K_complexity)).clamped(to: 1...9)
        let nameCurrent = digitFromUnitInterval(result.vector.H_entropy)
        let ancestryCurrent = digitFromUnitInterval(((result.vector.D_fractal_dim - 1.0) / 2.0).clamped(to: 0...1))
        let placeCurrent = digitFromUnitInterval(result.vector.S_symmetry)
        let manifestationCurrent = reduceToSingleDigit(result.vector.L_generator_length)
        let parityOnes = result.bits9.bits.filter { $0 == "1" }.count
        let parityCurrent = reduceToSingleDigit(parityOnes)
        let planeCurrent = reduceToSingleDigit(plane)
        let integration = reduceToSingleDigit(
            lifePath + nameCurrent + ancestryCurrent + placeCurrent + manifestationCurrent + parityCurrent + planeCurrent
        )
        let tension = reduceToSingleDigit(
            abs(lifePath - nameCurrent)
                + abs(ancestryCurrent - placeCurrent)
                + abs(manifestationCurrent - planeCurrent)
                + parityCurrent
        )

        return NumerologyProfile(
            lifePath: lifePath,
            nameCurrent: nameCurrent,
            ancestryCurrent: ancestryCurrent,
            placeCurrent: placeCurrent,
            manifestationCurrent: manifestationCurrent,
            parityCurrent: parityCurrent,
            planeCurrent: planeCurrent,
            integration: integration,
            tension: tension
        )
    }

    private func digitFromUnitInterval(_ value: Double) -> Int {
        let scaled = (value.clamped(to: 0...1) * 9.0)
        return Int(floor(scaled) + 1).clamped(to: 1...9)
    }

    private func reduceToSingleDigit(_ value: Int) -> Int {
        var result = abs(value)
        if result == 0 {
            return 9
        }

        while result > 9 {
            result = String(result).compactMap(\.wholeNumberValue).reduce(0, +)
        }
        return result == 0 ? 9 : result
    }

    private func numerologyArchetype(for digit: Int) -> NumerologyArchetype {
        switch digit.clamped(to: 1...9) {
        case 1:
            NumerologyArchetype(
                title: "Pioneer",
                gift: "initiation and direction-setting",
                challenge: "impatience with slow consensus",
                practice: "begin the right work before certainty feels complete"
            )
        case 2:
            NumerologyArchetype(
                title: "Binder",
                gift: "harmonizing tensions and building trust",
                challenge: "delaying necessary decisions",
                practice: "set one clear boundary that protects a relationship"
            )
        case 3:
            NumerologyArchetype(
                title: "Herald",
                gift: "expression, storytelling, and morale lift",
                challenge: "scattered focus",
                practice: "ship one finished message instead of five drafts"
            )
        case 4:
            NumerologyArchetype(
                title: "Architect",
                gift: "systems, discipline, and reliability",
                challenge: "rigidity under uncertainty",
                practice: "replace one brittle rule with a resilient process"
            )
        case 5:
            NumerologyArchetype(
                title: "Wayfarer",
                gift: "adaptability and pattern discovery",
                challenge: "restlessness and over-switching",
                practice: "commit to one disciplined experiment for seven days"
            )
        case 6:
            NumerologyArchetype(
                title: "Warden",
                gift: "care, responsibility, and stewardship",
                challenge: "over-responsibility for others",
                practice: "serve with limits so duty does not become self-erasure"
            )
        case 7:
            NumerologyArchetype(
                title: "Seer",
                gift: "analysis, intuition, and inner depth",
                challenge: "withdrawal into overthinking",
                practice: "test one intuition against concrete evidence"
            )
        case 8:
            NumerologyArchetype(
                title: "Sovereign",
                gift: "execution, authority, and material stewardship",
                challenge: "control reflex under pressure",
                practice: "align influence with explicit ethical intent"
            )
        default:
            NumerologyArchetype(
                title: "Lantern",
                gift: "compassion, closure, and transmutation",
                challenge: "martyr patterns and unfinished grief",
                practice: "close one cycle with a deliberate act of release"
            )
        }
    }

    private func numerologyCoreApplication(_ profile: NumerologyProfile) -> String {
        let lifePath = numerologyArchetype(for: profile.lifePath)
        let integration = numerologyArchetype(for: profile.integration)

        return [
            "Life Path \(profile.lifePath) (\(lifePath.title)) is your long-cycle curriculum.",
            "Channel digits: Name \(profile.nameCurrent), Time \(profile.lifePath), Ancestry \(profile.ancestryCurrent), Place \(profile.placeCurrent), Manifestation \(profile.manifestationCurrent), Parity \(profile.parityCurrent), Plane \(profile.planeCurrent).",
            "Integration digit \(profile.integration) (\(integration.title)) indicates your current coherence strategy."
        ].joined(separator: " ")
    }

    private func numerologyChannelsApplication(_ profile: NumerologyProfile) -> String {
        let name = numerologyArchetype(for: profile.nameCurrent)
        let life = numerologyArchetype(for: profile.lifePath)
        let ancestry = numerologyArchetype(for: profile.ancestryCurrent)
        let place = numerologyArchetype(for: profile.placeCurrent)
        let manifestation = numerologyArchetype(for: profile.manifestationCurrent)
        let parity = numerologyArchetype(for: profile.parityCurrent)

        return [
            "Identity channel (Name \(profile.nameCurrent), \(name.title)) emphasizes \(name.gift), with risk of \(name.challenge).",
            "Temporal channel (Life Path \(profile.lifePath), \(life.title)) emphasizes \(life.gift), with risk of \(life.challenge).",
            "Lineage-place bridge (Ancestry \(profile.ancestryCurrent) / Place \(profile.placeCurrent)) asks you to balance \(ancestry.title.lowercased()) depth with \(place.title.lowercased()) adaptation.",
            "Manifestation channel (L \(profile.manifestationCurrent), \(manifestation.title)) drives execution style.",
            "Parity channel (\(profile.parityCurrent), \(parity.title)) describes how your bit-pattern pressure gets expressed in choices."
        ].joined(separator: " ")
    }

    private func numerologySynthesisApplication(
        _ profile: NumerologyProfile,
        worldSeedHex: String,
        nearestPatternEntity: LoreEntity?
    ) -> String {
        let integration = numerologyArchetype(for: profile.integration)
        let tension = numerologyArchetype(for: profile.tension)
        let gatePrompts = [
            "Choose the hard truth early and your path simplifies.",
            "A single disciplined routine will unlock disproportionate momentum.",
            "Repairing one strained bond will stabilize multiple domains.",
            "Your next level requires pruning before expansion.",
            "Convert private insight into visible action this cycle."
        ]
        let repairPrompts = [
            "Name the fear, then define one measurable step.",
            "Replace urgency with sequence: first things first.",
            "Ask for support before the strain becomes isolation.",
            "Reduce scope, keep cadence, finish the core thread.",
            "Trade symbolic control for practical trust."
        ]

        let gate = gatePrompts[deterministicIndex(seed: worldSeedHex, key: "num_gate", upperBound: gatePrompts.count)]
        let repair = repairPrompts[deterministicIndex(seed: worldSeedHex, key: "num_repair", upperBound: repairPrompts.count)]

        var details = [
            "Integration \(profile.integration) (\(integration.title)) favors \(integration.gift).",
            "Tension \(profile.tension) (\(tension.title)) exposes \(tension.challenge).",
            "Growth gate: \(gate)",
            "Repair move: \(repair)",
            "Best practice now: \(integration.practice)."
        ]

        if let nearestPatternEntity {
            details.append(
                "Closest canonical vector echo is \(nearestPatternEntity.name), indicating your current numerology has neighboring traits of plane \(nearestPatternEntity.primaryPlane)."
            )
        }

        return details.joined(separator: " ")
    }

    private enum WolfBalanceCategory: String {
        case whiteDominant = "white_dominant"
        case darkDominant = "dark_dominant"
        case balanced

        var displayLabel: String {
            switch self {
            case .whiteDominant:
                return "white-dominant"
            case .darkDominant:
                return "dark-dominant"
            case .balanced:
                return "balanced"
            }
        }
    }

    private func wolfBalanceCategory(from raw: String?) -> WolfBalanceCategory {
        switch raw?.lowercased() {
        case "white":
            return .whiteDominant
        case "dark":
            return .darkDominant
        default:
            return .balanced
        }
    }

    private func originFragment(for dominantPlaneCode: String) -> String {
        switch dominantPlaneCode.uppercased() {
        case "P7", "P8":
            return "You were born beneath the hush before names, where weight precedes light. In the old dark, the first covenant was persistence."
        case "P6", "P9":
            return "You carry memory of high symmetry, of patterns that do not tremble. Even in embodiment, your shape leans toward coherence."
        case "P3", "P4", "P5":
            return "Your story begins in the corridor between dream and decision, where symbols harden into choices and choices into fate."
        default:
            return "Your codex begins at a living threshold, where identity is forged through relation, memory, and chosen direction."
        }
    }

    private func thresholdFragment(for category: WolfBalanceCategory) -> String {
        switch category {
        case .whiteDominant:
            return "Your thresholds arrive as revelations: quiet lights exposing what darkness concealed, without denying its purpose."
        case .darkDominant:
            return "Your thresholds arrive as weight: gravity’s honest hand. You learn by carrying what others refuse to touch."
        case .balanced:
            return "Your thresholds arrive as a duet: memory in one breath and illumination in the next. You are not a side, but a bridge."
        }
    }

    private func planeLensFragment(dominantPlaneCode: String, planeLabel: String, planeCodex: PlaneCodex?) -> String {
        guard let planeCodex else {
            return "\(planeLabel) shapes your perspective through ordered tension between entropy and symmetry."
        }
        let physicsSample = planeCodex.physics.prefix(3).joined(separator: ", ")
        if physicsSample.isEmpty {
            return "\(dominantPlaneCode) resonates as \(planeCodex.name), guiding your role as \(planeCodex.role)."
        }
        return "\(dominantPlaneCode) resonates as \(planeCodex.name), guiding your role as \(planeCodex.role). Noted field traits: \(physicsSample)."
    }

    private func wolfCompanionFragment(for category: WolfBalanceCategory, dominantPlaneCode: String) -> String {
        switch category {
        case .whiteDominant:
            return "Your white companion reinforces coherence and mercy, helping you stabilize meaning while moving through \(dominantPlaneCode)."
        case .darkDominant:
            return "Your dark companion sharpens discernment through pressure, teaching integration through confrontation in \(dominantPlaneCode)."
        case .balanced:
            return "Both companions walk with you in measured tension, joining discipline and depth as you move through \(dominantPlaneCode)."
        }
    }

    private func personalProphecyFragment(worldSeedHex: String, dominantPlaneCode: String, wolfBalance: WolfBalanceCategory) -> String {
        let templates = [
            "When the next gate opens, your sign will be recognized by those who listen before they speak.",
            "A closed path will reopen when you choose integration over certainty.",
            "Your mark gathers force through disciplined repetition, then turns suddenly toward opportunity.",
            "The work you avoided becomes the hinge of your next ascent.",
            "A living bond, once strained, becomes the key to restoring alignment."
        ]
        let motif = [
            "ember",
            "raven",
            "mirror",
            "threshold",
            "iron",
            "echo",
            "flare"
        ]

        let prophecy = templates[deterministicIndex(seed: worldSeedHex, key: "prophecy", upperBound: templates.count)]
        let selectedMotif = motif[deterministicIndex(seed: worldSeedHex, key: "motif", upperBound: motif.count)]
        return "\(prophecy) Dominant plane \(dominantPlaneCode) with \(wolfBalance.displayLabel) balance marks your motif of \(selectedMotif)."
    }

    private func branchHooksFragment(worldSeedHex: String, dominantPlaneCode: String, wolfBalance: WolfBalanceCategory) -> String {
        let choiceAxis = [
            "truth vs comfort",
            "discipline vs impulse",
            "service vs isolation",
            "patience vs control",
            "forgiveness vs retaliation",
            "craft vs spectacle"
        ]
        let shadowCost = [
            "temporary loneliness",
            "loss of false certainty",
            "friction with old loyalties",
            "grief for an outdated identity",
            "exposure of hidden fear",
            "surrender of ego armor"
        ]
        let integrationReward = [
            "durable clarity",
            "higher coherence",
            "stronger relational trust",
            "increased pattern stability",
            "cleaner inner signal",
            "expanded capacity for leadership"
        ]

        var hooks: [String] = []
        for index in 0..<3 {
            let axis = choiceAxis[deterministicIndex(seed: worldSeedHex, key: "hook_axis_\(index)", upperBound: choiceAxis.count)]
            let cost = shadowCost[deterministicIndex(seed: worldSeedHex, key: "hook_cost_\(index)", upperBound: shadowCost.count)]
            let reward = integrationReward[deterministicIndex(seed: worldSeedHex, key: "hook_reward_\(index)", upperBound: integrationReward.count)]
            hooks.append("(\(index + 1)) Choice axis: \(axis); shadow cost: \(cost); integration reward: \(reward); plane emphasis: \(dominantPlaneCode)/\(wolfBalance.displayLabel)")
        }
        return hooks.joined(separator: " ")
    }

    private func deterministicIndex(seed: String, key: String, upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        let digest = SHA256.hash(data: Data("\(seed)|\(key)".utf8))
        var value: UInt64 = 0
        for byte in digest.prefix(8) {
            value = (value << 8) | UInt64(byte)
        }
        return Int(value % UInt64(upperBound))
    }

    private func idiomSection(title: String, idiomMeaning: String, sigilApplication: String) -> String {
        "\(title): Idiom Meaning: \(idiomMeaning) Your Sigil Application: \(sigilApplication)"
    }

    private func personalizedAxiomImplication(for axiom: AxiomCodex, result: SigilResult) -> String {
        let lifePathContext: String = {
            guard let insights = result.codexInsights else {
                return "your current path"
            }
            return "life path \(insights.lifePathNumber)"
        }()

        switch axiom.id.uppercased() {
        case "A1":
            return "Your sigil indicates that meaningful bonds and reciprocal ties reinforce your identity field across planes."
        case "A2":
            return "For \(lifePathContext), recurring habits and symbols are interpreted as stable pattern signatures, not random noise."
        case "A3":
            return "Your profile suggests continuity across changing circumstances: the core pattern persists while form and role can shift."
        case "A4":
            return "Your structured identity carries persistence cost, meaning deep pattern changes require deliberate energy and sustained intent."
        case "A5":
            return "Your consciousness signature is read through self-reference: your inner model of self updates with experience, choices, and state changes."
        default:
            let fallback = axiom.storyImplications.first ?? "No story implication listed."
            return sanitizeCanonicalLeaks(in: fallback)
        }
    }

    private func sanitizeCanonicalLeaks(in raw: String) -> String {
        var text = raw
        let replacements: [(String, String)] = [
            ("\\bnarrator\\b", "traveler"),
            ("\\bkaelen\\b", "seeker"),
            ("\\bkalean\\b", "seeker"),
            ("\\bauthun\\b", "wanderer"),
            ("\\bvareth\\b", "wanderer")
        ]

        for (pattern, target) in replacements {
            text = text.replacingOccurrences(of: pattern, with: target, options: [.regularExpression, .caseInsensitive])
        }

        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func displayAxiomName(_ raw: String) -> String {
        let normalized = raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        guard !normalized.isEmpty else { return raw }

        let smallWords: Set<String> = ["a", "an", "and", "as", "at", "by", "for", "in", "of", "on", "or", "the", "to"]
        return normalized.enumerated().map { index, word in
            let lower = word.lowercased()
            if index > 0, smallWords.contains(lower) {
                return lower
            }
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }.joined(separator: " ")
    }
}

private extension String {
    func pipe(_ transform: (String) -> String) -> String {
        transform(self)
    }
}
