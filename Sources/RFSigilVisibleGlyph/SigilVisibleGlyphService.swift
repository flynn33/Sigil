import CryptoKit
import ForsettiCore
import Foundation
import RFSigilCoreModels
import RFSigilDiagnostics

public struct SigilVisibleQualityGate: Sendable {
    public init() {}

    public func evaluate(
        vectorPaths: [VisibleVectorPath],
        candidateIndex: Int,
        majorCrossingCount: Int
    ) -> VisibleSigilQualityReport {
        var failures: [SigilQualityFailure] = []
        let segmentCount = vectorPaths.count
        let duplicateCount = segmentCount - Set(vectorPaths.map(\.pathData)).count

        if segmentCount == 0 {
            failures.append(.emptyPathSet)
        }
        if segmentCount < 10 {
            failures.append(.segmentBudgetTooLow)
        }
        if segmentCount > 14 {
            failures.append(.segmentBudgetExceeded)
        }
        if majorCrossingCount > 3 {
            failures.append(.majorCrossingLimitExceeded)
        }
        if duplicateCount > 2 {
            failures.append(.duplicatePathDensity)
        }

        let structuralScore = failures.contains(.emptyPathSet) ? 0.0 : bounded(1.0 - Double(max(0, segmentCount - 12)) * 0.06)
        let spacingScore = bounded(1.0 - Double(max(0, majorCrossingCount - 1)) * 0.08 - Double(duplicateCount) * 0.05)
        let silhouetteScore = bounded(1.0 - abs(Double(segmentCount) - 12.0) * 0.035)
        let intersectionCount = max(majorCrossingCount, min(3, segmentCount / 5))

        return VisibleSigilQualityReport(
            passed: failures.isEmpty && structuralScore >= 0.70 && spacingScore >= 0.70 && silhouetteScore >= 0.70,
            candidateIndex: candidateIndex,
            structuralScore: quantized(structuralScore),
            spacingScore: quantized(spacingScore),
            silhouetteScore: quantized(silhouetteScore),
            intersectionCount: intersectionCount,
            majorCrossingCount: majorCrossingCount,
            visibleSegmentCount: segmentCount,
            failures: failures,
            gateEvidence: [
                "segmentBudget": "10...14",
                "majorCrossingMaximum": "3",
                "candidateIndex": "\(candidateIndex)"
            ]
        )
    }
}

public struct SigilVisibleGlyphService: Sendable {
    private let qualityGate: SigilVisibleQualityGate
    /// Optional diagnostic contract for instrumenting the identity pipeline
    /// (normalization, reductions, state/orbit decisions, validation and
    /// failure paths). Never records personal raw values. No-op when nil.
    private let diagnostics: (any SigilDiagnosticCollector)?

    public init(
        qualityGate: SigilVisibleQualityGate = SigilVisibleQualityGate(),
        diagnostics: (any SigilDiagnosticCollector)? = nil
    ) {
        self.qualityGate = qualityGate
        self.diagnostics = diagnostics
    }

    public func generateArtifact(
        for profile: SigilProfileInput,
        existingVisibleSignatureHashes: Set<String> = []
    ) throws -> SigilVisibleGlyphArtifact {
        let hiddenGeometry = try makeHiddenGeometry(for: profile)
        let familyKey = makeFamilyKey(from: hiddenGeometry)

        for candidateIndex in 0..<64 {
            let vectorPaths = makeVectorPaths(
                hiddenGeometry: hiddenGeometry,
                familyKey: familyKey,
                candidateIndex: candidateIndex
            )
            let majorCrossings = majorCrossingCount(for: hiddenGeometry, candidateIndex: candidateIndex)
            let qualityReport = qualityGate.evaluate(
                vectorPaths: vectorPaths,
                candidateIndex: candidateIndex,
                majorCrossingCount: majorCrossings
            )
            let styleMetadata = VisibleStyleMetadata(
                strokeCount: vectorPaths.count,
                majorCrossingCount: majorCrossings,
                candidateIndex: candidateIndex,
                renderer: "RFSigilRenderer.svg.v1",
                paletteID: paletteID(for: familyKey)
            )
            let semanticMotifMap = makeSemanticMotifMap(familyKey: familyKey, hiddenGeometry: hiddenGeometry)
            let signatureHash = try visibleSignatureHash(
                profileDigest: hiddenGeometry.profileHash,
                canonicalGeometryDigest: hiddenGeometry.canonicalGeometryDigest,
                candidateIndex: candidateIndex,
                vectorPaths: vectorPaths,
                semanticMotifMap: semanticMotifMap
            )

            guard qualityReport.passed, !existingVisibleSignatureHashes.contains(signatureHash) else {
                continue
            }

            let visibleSigil = VisibleCanonicalSigil(
                profileDigest: hiddenGeometry.profileHash,
                canonicalGeometryDigest: hiddenGeometry.canonicalGeometryDigest,
                visibleSignatureHash: signatureHash,
                vectorPaths: vectorPaths,
                styleMetadata: styleMetadata,
                semanticMotifMap: semanticMotifMap,
                qualityReport: qualityReport
            )
            let artifact = SigilVisibleGlyphArtifact(
                hiddenGeometry: hiddenGeometry,
                familyKey: familyKey,
                visibleSigil: visibleSigil,
                svgDocument: renderSVG(for: visibleSigil),
                validationDecision: validate(hiddenGeometry: hiddenGeometry, visibleSigil: visibleSigil)
            )

            guard artifact.validationDecision.status == .pass else {
                continue
            }

            return artifact
        }

        throw SigilVisibleGlyphError.qualityUnsatisfied
    }

    public func canonicalVisibleJSON(for visibleSigil: VisibleCanonicalSigil) throws -> Data {
        try SigilCanonicalJSON.encode(visibleSigil)
    }

    public func renderSVG(for visibleSigil: VisibleCanonicalSigil) -> String {
        let paths = visibleSigil.vectorPaths
            .map { path in
                "<path id=\"\(path.id)\" data-primitive=\"\(path.primitive.rawValue)\" d=\"\(path.pathData)\"/>"
            }
            .joined()

        return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" data-signature=\"\(visibleSigil.visibleSignatureHash)\"><g fill=\"none\" stroke=\"currentColor\" stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"4\">\(paths)</g></svg>"
    }

    public func pathSignature(for visibleSigil: VisibleCanonicalSigil) -> String {
        SigilCanonicalJSON.sha256Hex(
            Data(visibleSigil.vectorPaths.map(\.pathData).joined(separator: "|").utf8)
        )
    }

    public func makeFlarePresentation(
        for visibleSigil: VisibleCanonicalSigil,
        style: SigilFlareStyle
    ) -> SigilFlarePresentation {
        SigilFlarePresentation(
            profileDigest: visibleSigil.profileDigest,
            canonicalGeometryDigest: visibleSigil.canonicalGeometryDigest,
            visibleSignatureHash: visibleSigil.visibleSignatureHash,
            vectorPaths: visibleSigil.vectorPaths,
            style: style
        )
    }

    public func validateArtifact(_ artifact: SigilVisibleGlyphArtifact) -> AeostaraHealthDecision {
        validate(hiddenGeometry: artifact.hiddenGeometry, visibleSigil: artifact.visibleSigil)
    }

    // MARK: - Identity pipeline (Package 02)
    //
    // The owning canonical identity stage: retained inputs -> validated,
    // deterministic, source-backed numerology and ASH state. Replaces the
    // digest-byte substitutes (F-03) and the name/eye/hair scalar sums (F-04)
    // with real numerology and the celestial generator's wolf tables.

    private func makeHiddenGeometry(for profile: SigilProfileInput) throws -> HiddenCanonicalGeometry {
        let operationID = beginDiagnosticOperation()
        defer { finishDiagnosticOperation(operationID, outcome: .success) }

        let profileHash = try SigilCanonicalJSON.digest(profile)
        let normalized = normalizeProfile(profile)

        // Fail-closed: an unavailable identity-core signal is never substituted
        // with a fabricated value. The state record reports the missing fields.
        let wolf = SigilWolfResolver.resolve(
            hair: normalized.hair,
            eyes: normalized.eyes,
            birthTime: profile.birthTime,
            lifePathRoot: normalized.numerology.lifePathRoot
        )

        let signals = SigilProfileSignals(
            lifePathRoot: normalized.numerology.lifePathRoot,
            birthDayRoot: normalized.numerology.birthDayRoot,
            expressionRoot: normalized.numerology.expressionRoot,
            soulUrgeRoot: normalized.numerology.soulUrgeRoot,
            personalityRoot: normalized.numerology.personalityRoot,
            weekday: normalized.numerology.weekday,
            hasName: normalized.hasName,
            hasDate: normalized.hasDate,
            birthOrderOrdinal: normalized.birthOrder?.ordinal,
            heritageCanonicalIndex: normalized.primaryHeritage?.canonicalIndex,
            wolfBalance: wolf
        )

        guard let state = SigilProfileAdapterV1.state(from: signals) else {
            let missing = SigilProfileAdapterV1.unavailableIdentityCore(signals)
            recordDiagnostic(
                operationID: operationID,
                severity: .warning,
                type: "identity.unavailable",
                message: "ASH state unavailable: identity-core signal missing.",
                context: ["missing": .array(missing.map { .string($0) })]
            )
            throw SigilVisibleGlyphError.identityUnavailable(missing)
        }

        recordDiagnostic(
            operationID: operationID,
            severity: .info,
            type: "identity.state",
            message: "ASH state resolved via \(SigilProfileAdapterV1.identity).",
            context: [
                "statePacked": .number(Double(state.packed)),
                "bits": .array(state.bits.map { .number(Double($0)) }),
                "isCodeword": .boolean(SigilAshCodewordSet.isCodeword(state)),
                "orbitSize": .number(16),
                "classification": .string(SigilAshClassifier.classification(of: state).label)
            ]
        )

        let orbit = SigilAshClassifier.orbit(of: state)
        let classification = SigilAshClassifier.classification(of: state)
        let dominantPlaneId = normalized.numerology.lifePathRoot
        // Canonical linkage digest of the state (not the semantic state): a
        // stable SHA-256 over the canonical bit string, for Flare/linkage use.
        let stateBitString = state.bits.map { $0 == 0 ? "0" : "1" }.joined()
        let stateDigest = SigilCanonicalJSON.sha256Hex(Data(stateBitString.utf8))
        let ashState = SigilAshStateRecord(
            statePacked: state.packed,
            stateBits: state.bits,
            isCodeword: classification.isCodeword,
            orbitSize: orbit.members.count,
            classification: classification.label,
            stability: "stable",
            dominantPlaneId: dominantPlaneId,
            wolfBalance: wolf,
            algorithmIdentity: "sigil-ash-state.v1",
            stateDigest: stateDigest,
            available: true,
            unavailableIdentityCore: []
        )

        let numerology = makeNumerologyVector(from: normalized)
        let planeVector = makePlaneVector(lifePathRoot: dominantPlaneId, state: state)
        let ancestryWeights = makeAncestryWeights(heritage: profile.heritage)
        let celestial = CelestialClassBasis(
            id: celestialBasisID(dominantPlaneId: dominantPlaneId, wolfCategory: wolf.category),
            source: "derived_local_profile_basis"
        )
        let anchorPoints = makeHiddenAnchors(profileHash: profileHash, canonicalIdentity: state, dominantPlaneId: dominantPlaneId)
        let edges = [
            SigilGeometryEdge(from: "hidden.crown", to: "hidden.nexus", role: "crown_axis"),
            SigilGeometryEdge(from: "hidden.nexus", to: "hidden.root", role: "root_axis"),
            SigilGeometryEdge(from: "hidden.left", to: "hidden.nexus", role: "left_balance"),
            SigilGeometryEdge(from: "hidden.right", to: "hidden.nexus", role: "right_balance")
        ]
        let semanticRoles = [
            "hidden.crown": "upper_structure_basis",
            "hidden.nexus": "central_convergence_basis",
            "hidden.root": "lower_root_basis",
            "hidden.left": "ancestral_left_basis",
            "hidden.right": "ancestral_right_basis"
        ]

        let digestPayload = HiddenCanonicalGeometryDigestPayload(
            schemaVersion: "rf.hidden_geometry.v1",
            algorithmIdentity: "sigil-identity-pipeline.v1",
            profileHash: profileHash,
            numerologyVector: numerology,
            ashState: ashState,
            planeAttunementVector: planeVector,
            wolfBalance: wolf,
            ancestryWeights: ancestryWeights,
            celestialClassBasis: celestial,
            anchorPoints: anchorPoints,
            edges: edges,
            semanticRoles: semanticRoles
        )
        let canonicalGeometryDigest = try SigilCanonicalJSON.digest(digestPayload)

        return HiddenCanonicalGeometry(
            profileHash: profileHash,
            numerologyVector: numerology,
            ashState: ashState,
            planeAttunementVector: planeVector,
            wolfBalance: wolf,
            ancestryWeights: ancestryWeights,
            celestialClassBasis: celestial,
            anchorPoints: anchorPoints,
            edges: edges,
            semanticRoles: semanticRoles,
            canonicalGeometryDigest: canonicalGeometryDigest
        )
    }

    // MARK: - Normalization and boundary validation

    private struct NormalizedProfile: Sendable {
        var hasDate: Bool
        var hasName: Bool
        var numerology: SigilNumerologyRecord
        var hair: SigilHairCategory
        var eyes: SigilEyeCategory
        var birthOrder: SigilBirthOrder?
        var primaryHeritage: SigilHeritageFamily?
        var fieldStates: [String: String]
    }

    private func normalizeProfile(_ profile: SigilProfileInput) -> NormalizedProfile {
        let date = SigilCivilDate.parse(profile.birthDate)

        // Name: separate canonical fields when present, else derived from `name`
        // (first word = first, remainder = last) in the owning boundary.
        let rawFirst = (profile.firstName?.isEmpty == false) ? profile.firstName! : Self.firstComponent(of: profile.name)
        let rawLast = (profile.lastName?.isEmpty == false) ? profile.lastName! : Self.lastComponent(of: profile.name)
        let firstLetters = SigilLetterValues.normalizeLetters(rawFirst) ?? []
        let lastLetters = SigilLetterValues.normalizeLetters(rawLast) ?? []
        let hasName = !firstLetters.isEmpty || !lastLetters.isEmpty

        var fieldStates: [String: String] = [:]
        fieldStates["date"] = date == nil ? "unknown" : "present"
        fieldStates["name"] = hasName ? "present" : "unknown"

        let hair = SigilHairCategory.normalize(profile.hair)
        let eyes = SigilEyeCategory.normalize(profile.eyes)
        fieldStates["hair"] = hair.availability.rawValue
        fieldStates["eyes"] = eyes.availability.rawValue

        let birthOrder = SigilBirthOrder.parse(profile.birthOrder)
        fieldStates["birth_order"] = birthOrder == nil ? "unknown" : "present"

        let families = profile.heritage.map(SigilHeritageFamily.group)
        let counts = Dictionary(grouping: families, by: { $0 }).mapValues(\.count)
        let total = max(1, families.count)
        let primary = counts
            .map { ($0.key, Double($0.value) / Double(total)) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0.rawValue < rhs.0.rawValue }
                return lhs.1 > rhs.1
            }
            .first?.0
        fieldStates["heritage"] = primary == nil ? "unknown" : "present"

        recordDiagnostic(
            operationID: nil,
            severity: .info,
            type: "identity.normalized",
            message: "Profile normalized at the owning boundary.",
            context: ["fields": .object(fieldStates.mapValues { .string($0) })]
        )

        // Weekday is a pure function of the civil date. A user-supplied weekday
        // is validated against it; a mismatch is recorded, not silently
        // overridden (spec §5.1).
        if let supplied = profile.birthWeekday, let date {
            let derivedName = Self.weekdayName(date.weekday)
            if Self.fold(supplied) != derivedName {
                recordDiagnostic(
                    operationID: nil,
                    severity: .warning,
                    type: "identity.weekday_mismatch",
                    message: "Supplied weekday disagrees with the derived weekday; the derived value is used.",
                    context: ["derived": .string(derivedName)]
                )
            }
        }

        let names = SigilNumerologyEngine.nameRoots(first: firstLetters, last: lastLetters)
        let numerology: SigilNumerologyRecord
        if let date {
            numerology = SigilNumerologyEngine.record(
                date: date,
                firstLetters: firstLetters,
                lastLetters: lastLetters,
                hasName: hasName
            )
        } else {
            // Date unavailable: date-derived roots and weekday are unavailable
            // (fail-closed for the state). Name roots are still computed for the
            // record when a name is present.
            var allMasters: Set<Int> = []
            if hasName {
                allMasters.formUnion(names.expression.masters)
                allMasters.formUnion(names.soulUrge.masters)
                allMasters.formUnion(names.personality.masters)
            }
            numerology = SigilNumerologyRecord(
                lifePathRoot: 0,
                birthDayRoot: 0,
                expressionRoot: hasName ? names.expression.root : 0,
                soulUrgeRoot: hasName ? names.soulUrge.root : 0,
                personalityRoot: hasName ? names.personality.root : 0,
                weekday: 0,
                preservedMasterNumbers: allMasters.sorted(),
                reductionProvenance: hasName ? [
                    "expression": names.expression.chain,
                    "soul_urge": names.soulUrge.chain,
                    "personality": names.personality.chain
                ] : [:]
            )
        }

        return NormalizedProfile(
            hasDate: date != nil,
            hasName: hasName,
            numerology: numerology,
            hair: hair.category,
            eyes: eyes.category,
            birthOrder: birthOrder,
            primaryHeritage: primary,
            fieldStates: fieldStates
        )
    }

    private func makeNumerologyVector(from normalized: NormalizedProfile) -> NumerologyVector {
        let order = normalized.birthOrder
        return NumerologyVector(
            lifePathRoot: normalized.numerology.lifePathRoot,
            preservedMasterNumbers: normalized.numerology.preservedMasterNumbers,
            birthDayRoot: normalized.numerology.birthDayRoot,
            expressionDestinyRoot: normalized.numerology.expressionRoot,
            soulUrgeRoot: normalized.numerology.soulUrgeRoot,
            personalityRoot: normalized.numerology.personalityRoot,
            birthOrderOrdinal: order?.ordinal ?? 0,
            birthOrderTotal: order?.total ?? 0,
            weekday: normalized.numerology.weekday,
            reductionProvenance: normalized.numerology.reductionProvenance
        )
    }

    private static func fold(_ raw: String) -> String {
        raw.precomposedStringWithCanonicalMapping
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }

    private static func weekdayName(_ weekday: Int) -> String {
        ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"][weekday - 1]
    }

    private static func firstComponent(of name: String) -> String {
        let parts = name.split(separator: " ").map(String.init)
        return parts.first ?? name
    }

    private static func lastComponent(of name: String) -> String {
        let parts = name.split(separator: " ").map(String.init)
        return parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""
    }

    // MARK: - Plane and celestial basis (real identity)

    /// Plane attunement derived from the real identity: the dominant plane is
    /// the life-path mapping (P1-P9); secondary planes carry a deterministic,
    /// state-linked spread. Not a digest-byte substitute.
    private func makePlaneVector(lifePathRoot: Int, state: SigilAshState) -> [Double] {
        let weights = (0..<9).map { index -> Double in
            if index + 1 == lifePathRoot { return 1.0 }
            let bit = state.bit(index)
            return 0.35 + Double(bit) * 0.15 - Double(index) * 0.01
        }
        let total = weights.reduce(0, +)
        return weights.map { quantized($0 / total) }
    }

    private func celestialBasisID(dominantPlaneId: Int, wolfCategory: String) -> String {
        // Temporary product mapping over the REAL dominant plane and wolf
        // category; Package 04 refines celestial class derivation from canon.
        switch (dominantPlaneId, wolfCategory) {
        case (6, _), (9, _):
            return "crown-bearer"
        case (_, "dark_dominant"):
            return "root-walker"
        case (8, _):
            return "veil-crossing"
        case (_, "balanced"):
            return "wolf-balanced"
        default:
            return "star-bound"
        }
    }

    private func makeAncestryWeights(heritage: [String]) -> [AncestryWeight] {
        let families = heritage.map { SigilHeritageFamily.group($0).rawValue }
        let counts = Dictionary(grouping: families, by: { $0 }).mapValues(\.count)
        let total = max(1, families.count)

        return counts
            .map { AncestryWeight(family: $0.key, weight: quantized(Double($0.value) / Double(total))) }
            .sorted { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.family < rhs.family
                }
                return lhs.weight > rhs.weight
            }
    }

    private func makeHiddenAnchors(profileHash: String, canonicalIdentity: SigilAshState, dominantPlaneId: Int) -> [SigilAnchorPoint] {
        // Deterministic, identity-linked seed (the real state + profile digest).
        // The bounded renderer remains temporary until Package 05 replaces it
        // with canonical branch geometry.
        let seedBytes = bytes(fromHex: profileHash)
        let offset = Double(seedBytes[11 % seedBytes.count] % 7) - 3.0
        let planeOffset = Double(dominantPlaneId - 5)
        let stateNudge = Double(canonicalIdentity.packed % 5) - 2.0

        return [
            SigilAnchorPoint(id: "hidden.crown", x: quantized(50 + offset), y: quantized(12 + planeOffset), semanticRole: "upper_structure_basis"),
            SigilAnchorPoint(id: "hidden.nexus", x: quantized(50 - offset / 2 + stateNudge / 4), y: 50, semanticRole: "central_convergence_basis"),
            SigilAnchorPoint(id: "hidden.root", x: quantized(50 + offset / 3), y: quantized(86 - planeOffset), semanticRole: "lower_root_basis"),
            SigilAnchorPoint(id: "hidden.left", x: quantized(24 + offset), y: 46, semanticRole: "ancestral_left_basis"),
            SigilAnchorPoint(id: "hidden.right", x: quantized(76 - offset), y: 46, semanticRole: "ancestral_right_basis")
        ]
    }

    private func makeFamilyKey(from hiddenGeometry: HiddenCanonicalGeometry) -> SigilFamilyKey {
        let rankedPlanes = hiddenGeometry.planeAttunementVector
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element == rhs.element {
                    return lhs.offset < rhs.offset
                }
                return lhs.element > rhs.element
            }
            .map { $0.offset + 1 }
        let primaryAncestry = hiddenGeometry.ancestryWeights
            .sorted { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.family < rhs.family
                }
                return lhs.weight > rhs.weight
            }
            .first?.family ?? "mixed"

        return SigilFamilyKey(
            lifePathRoot: hiddenGeometry.numerologyVector.lifePathRoot,
            preservedMasterNumbers: hiddenGeometry.numerologyVector.preservedMasterNumbers,
            dominantPlaneId: rankedPlanes[0],
            secondaryPlaneIds: Array(rankedPlanes.dropFirst().prefix(2)),
            wolfBalanceCategory: hiddenGeometry.wolfBalance.category,
            ancestryFamilyPrimary: primaryAncestry,
            celestialClassBasisId: hiddenGeometry.celestialClassBasis.id
        )
    }

    private func makeVectorPaths(
        hiddenGeometry: HiddenCanonicalGeometry,
        familyKey: SigilFamilyKey,
        candidateIndex: Int
    ) -> [VisibleVectorPath] {
        let digest = SigilCanonicalJSON.sha256Hex(
            Data("\(hiddenGeometry.profileHash):\(hiddenGeometry.canonicalGeometryDigest):\(candidateIndex)".utf8)
        )
        let bytes = bytes(fromHex: digest)
        let shoulder = 21.0 + Double(bytes[0] % 8)
        let crownY = 8.0 + Double(bytes[1] % 5)
        let nexusY = 47.0 + Double(bytes[2] % 7)
        let rootY = 85.0 + Double(bytes[3] % 6)
        let rootSpread = 13.0 + Double(bytes[4] % 8)
        let curveLift = Double(bytes[5] % 7)
        let sideOffset = 8.0 + Double(bytes[6] % 5)
        let divisionOffset = Double(familyKey.lifePathRoot % 5)

        var paths: [VisibleVectorPath] = [
            path("visible.spine", .dominantSpine, "central_axis", "life_path", 50, crownY, 50, rootY),
            path("visible.upper.left", .upperStructure, "left_crown", "plane_\(familyKey.dominantPlaneId)", 50, crownY, shoulder, 25 + curveLift),
            path("visible.upper.right", .upperStructure, "right_crown", "plane_\(familyKey.dominantPlaneId)", 50, crownY, 100 - shoulder, 25 + curveLift),
            path("visible.shoulder.left", .upperStructure, "left_shoulder", familyKey.ancestryFamilyPrimary, shoulder, 25 + curveLift, 34, nexusY),
            path("visible.shoulder.right", .upperStructure, "right_shoulder", familyKey.ancestryFamilyPrimary, 100 - shoulder, 25 + curveLift, 66, nexusY),
            path("visible.nexus.left", .centralNexus, "nexus_cross_left", familyKey.wolfBalanceCategory, 34, nexusY - 8, 66, nexusY + 8),
            path("visible.nexus.right", .centralNexus, "nexus_cross_right", familyKey.wolfBalanceCategory, 66, nexusY - 8, 34, nexusY + 8),
            path("visible.root.left", .lowerRoot, "left_root", "birth_order", 50, nexusY + 4, 50 - rootSpread, rootY),
            path("visible.root.right", .lowerRoot, "right_root", "birth_order", 50, nexusY + 4, 50 + rootSpread, rootY),
            path("visible.terminal", .terminal, "root_terminal", familyKey.celestialClassBasisId, 50 - rootSpread, rootY, 50 + rootSpread, rootY),
            path("visible.division", .internalDivision, "internal_division", "birth_order", 43 + divisionOffset, nexusY, 57 - divisionOffset, nexusY)
        ]

        if familyKey.ancestryFamilyPrimary == "celtic" || familyKey.wolfBalanceCategory == "balanced" {
            paths.append(
                curvePath(
                    id: "visible.ornament.left",
                    primitive: .sideOrnament,
                    strokeRole: "left_side_ornament",
                    semanticSource: familyKey.ancestryFamilyPrimary,
                    startX: 34 - sideOffset,
                    startY: nexusY - 2,
                    controlX: 24,
                    controlY: nexusY + 10,
                    endX: 35,
                    endY: nexusY + 18
                )
            )
        }

        if familyKey.ancestryFamilyPrimary == "slavic" || familyKey.wolfBalanceCategory == "dark_dominant" {
            paths.append(
                curvePath(
                    id: "visible.ornament.right",
                    primitive: .sideOrnament,
                    strokeRole: "right_side_ornament",
                    semanticSource: familyKey.ancestryFamilyPrimary,
                    startX: 66 + sideOffset,
                    startY: nexusY - 2,
                    controlX: 76,
                    controlY: nexusY + 10,
                    endX: 65,
                    endY: nexusY + 18
                )
            )
        }

        if hiddenGeometry.numerologyVector.preservedMasterNumbers.isEmpty == false {
            paths.append(
                path("visible.master.accent", .upperStructure, "master_number_accent", "master_number", 44, crownY + 11, 56, crownY + 11)
            )
        }

        return Array(paths.prefix(14))
    }

    // MARK: - Bounded temporary renderer (Package 05 replaces this with canonical
    // branch geometry; the geometry here is a placeholder that consumes the real
    // identity contract and is explicitly not final glyph math).

    private func fmt(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        return rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(rounded))
            : String(format: "%.2f", rounded)
    }

    private func path(
        _ id: String,
        _ primitive: VisiblePathPrimitive,
        _ strokeRole: String,
        _ semanticSource: String,
        _ x1: Double,
        _ y1: Double,
        _ x2: Double,
        _ y2: Double
    ) -> VisibleVectorPath {
        VisibleVectorPath(
            id: id,
            primitive: primitive,
            pathData: "M \(fmt(x1)) \(fmt(y1)) L \(fmt(x2)) \(fmt(y2))",
            strokeRole: strokeRole,
            semanticSource: semanticSource
        )
    }

    private func curvePath(
        id: String,
        primitive: VisiblePathPrimitive,
        strokeRole: String,
        semanticSource: String,
        startX: Double,
        startY: Double,
        controlX: Double,
        controlY: Double,
        endX: Double,
        endY: Double
    ) -> VisibleVectorPath {
        VisibleVectorPath(
            id: id,
            primitive: primitive,
            pathData: "M \(fmt(startX)) \(fmt(startY)) Q \(fmt(controlX)) \(fmt(controlY)) \(fmt(endX)) \(fmt(endY))",
            strokeRole: strokeRole,
            semanticSource: semanticSource
        )
    }

    private func majorCrossingCount(for hiddenGeometry: HiddenCanonicalGeometry, candidateIndex: Int) -> Int {
        let base = 2 + (hiddenGeometry.numerologyVector.birthDayRoot + candidateIndex) % 2
        return min(3, base)
    }

    private func visibleSignatureHash(
        profileDigest: String,
        canonicalGeometryDigest: String,
        candidateIndex: Int,
        vectorPaths: [VisibleVectorPath],
        semanticMotifMap: [String: String]
    ) throws -> String {
        let payload = VisibleSignaturePayload(
            profileDigest: profileDigest,
            canonicalGeometryDigest: canonicalGeometryDigest,
            candidateIndex: candidateIndex,
            pathSignature: SigilCanonicalJSON.sha256Hex(Data(vectorPaths.map(\.pathData).joined(separator: "|").utf8)),
            semanticMotifMap: semanticMotifMap
        )
        return try SigilCanonicalJSON.digest(payload)
    }

    private func makeSemanticMotifMap(
        familyKey: SigilFamilyKey,
        hiddenGeometry: HiddenCanonicalGeometry
    ) -> [String: String] {
        [
            "ancestry": familyKey.ancestryFamilyPrimary,
            "celestialClass": familyKey.celestialClassBasisId,
            "dominantPlane": "P\(familyKey.dominantPlaneId)",
            "lifePathRoot": "\(familyKey.lifePathRoot)",
            "wolfBalance": hiddenGeometry.wolfBalance.category,
            "ashClassification": hiddenGeometry.ashState.classification
        ]
    }

    private func validate(
        hiddenGeometry: HiddenCanonicalGeometry,
        visibleSigil: VisibleCanonicalSigil
    ) -> AeostaraHealthDecision {
        guard visibleSigil.profileDigest == hiddenGeometry.profileHash else {
            return blockedDecision("Visible profile digest does not match hidden geometry profile hash.")
        }
        guard visibleSigil.canonicalGeometryDigest == hiddenGeometry.canonicalGeometryDigest else {
            return blockedDecision("Visible geometry digest does not match hidden canonical geometry digest.")
        }
        guard visibleSigil.qualityReport.passed else {
            return blockedDecision("Visible glyph quality report failed.")
        }

        return AeostaraHealthDecision(
            status: .pass,
            mutationAllowed: false,
            requiresBackupBeforeMutation: false,
            requiresVerificationAfterExecution: true,
            requiresOperatorReview: false,
            reason: "Visible glyph artifact passed local digest and quality validation."
        )
    }

    private func blockedDecision(_ reason: String) -> AeostaraHealthDecision {
        AeostaraHealthDecision(
            status: .blocked,
            mutationAllowed: false,
            requiresBackupBeforeMutation: true,
            requiresVerificationAfterExecution: true,
            requiresOperatorReview: true,
            reason: reason
        )
    }

    private func paletteID(for familyKey: SigilFamilyKey) -> String {
        switch familyKey.wolfBalanceCategory {
        case "white_dominant":
            return "pale-gold"
        case "dark_dominant":
            return "deep-violet"
        default:
            return "silver-green"
        }
    }

    // MARK: - Diagnostic instrumentation (no personal raw values)

    private func beginDiagnosticOperation() -> String? {
        guard let diagnostics else { return nil }
        return diagnostics.beginOperation(
            name: "sigil.identity.resolve",
            expected: "Deterministic, source-backed identity; fail-closed on missing identity-core signals.",
            correlationID: nil
        )
    }

    private func finishDiagnosticOperation(_ operationID: String?, outcome: SigilDiagnosticOutcome) {
        guard let diagnostics, let operationID else { return }
        diagnostics.finishOperation(id: operationID, outcome: outcome, context: [:], durationSeconds: nil)
    }

    private func recordDiagnostic(
        operationID: String?,
        severity: SigilDiagnosticSeverity,
        type: String,
        message: String,
        context: [String: SigilDiagnosticValue]
    ) {
        guard let diagnostics else { return }
        diagnostics.record(
            SigilDiagnosticEventInput(
                source: "RFSigilVisibleGlyph",
                severity: severity,
                type: type,
                message: message,
                operationID: operationID,
                context: context
            )
        )
    }
}

public final class SigilVisibleGlyphModule: ForsettiModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest
    public let service: SigilVisibleGlyphService

    public init(
        descriptor: ModuleDescriptor,
        manifest: ModuleManifest,
        service: SigilVisibleGlyphService = SigilVisibleGlyphService()
    ) {
        self.descriptor = descriptor
        self.manifest = manifest
        self.service = service
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.visible-glyph.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.visible-glyph.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}

private struct HiddenCanonicalGeometryDigestPayload: Encodable {
    let schemaVersion: String
    let algorithmIdentity: String
    let profileHash: String
    let numerologyVector: NumerologyVector
    let ashState: SigilAshStateRecord
    let planeAttunementVector: [Double]
    let wolfBalance: WolfBalance
    let ancestryWeights: [AncestryWeight]
    let celestialClassBasis: CelestialClassBasis
    let anchorPoints: [SigilAnchorPoint]
    let edges: [SigilGeometryEdge]
    let semanticRoles: [String: String]
}

private struct VisibleSignaturePayload: Encodable {
    let profileDigest: String
    let canonicalGeometryDigest: String
    let candidateIndex: Int
    let pathSignature: String
    let semanticMotifMap: [String: String]
}

private enum SigilCanonicalJSON {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }

    static func digest<T: Encodable>(_ value: T) throws -> String {
        try sha256Hex(encode(value))
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private func bytes(fromHex hex: String) -> [UInt8] {
    var output: [UInt8] = []
    var index = hex.startIndex
    while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        output.append(UInt8(hex[index..<next], radix: 16) ?? 0)
        index = next
    }
    return output.isEmpty ? [0] : output
}

private func quantized(_ value: Double) -> Double {
    (value * 10_000).rounded() / 10_000
}

private func bounded(_ value: Double) -> Double {
    min(1.0, max(0.0, value))
}

private func coordinate(_ value: Double) -> String {
    String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), quantized(value))
}
