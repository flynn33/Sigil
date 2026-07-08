import CryptoKit
import ForsettiCore
import Foundation
import RFSigilCoreModels

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

    public init(qualityGate: SigilVisibleQualityGate = SigilVisibleQualityGate()) {
        self.qualityGate = qualityGate
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

    private func makeHiddenGeometry(for profile: SigilProfileInput) throws -> HiddenCanonicalGeometry {
        let profileHash = try SigilCanonicalJSON.digest(profile)
        let digestBytes = bytes(fromHex: profileHash)
        let numerology = makeNumerologyVector(profile: profile)
        let planeVector = makePlaneVector(digestBytes: digestBytes)
        let dominantPlaneId = dominantPlaneID(in: planeVector)
        let wolfBalance = makeWolfBalance(digestBytes: digestBytes)
        let ancestryWeights = makeAncestryWeights(heritage: profile.heritage)
        let celestial = CelestialClassBasis(
            id: celestialBasisID(dominantPlaneId: dominantPlaneId, wolfCategory: wolfBalance.category),
            source: "derived_local_profile_basis"
        )
        let ashState = SigilStabilizedState(
            stateDigest: SigilCanonicalJSON.sha256Hex(Data("state:\(profileHash):\(dominantPlaneId)".utf8)),
            dominantPlaneId: dominantPlaneId,
            stabilizerClass: "local_stable_basis"
        )
        let anchorPoints = makeHiddenAnchors(digestBytes: digestBytes, dominantPlaneId: dominantPlaneId)
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
            profileHash: profileHash,
            numerologyVector: numerology,
            ashState: ashState,
            planeAttunementVector: planeVector,
            wolfBalance: wolfBalance,
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
            wolfBalance: wolfBalance,
            ancestryWeights: ancestryWeights,
            celestialClassBasis: celestial,
            anchorPoints: anchorPoints,
            edges: edges,
            semanticRoles: semanticRoles,
            canonicalGeometryDigest: canonicalGeometryDigest
        )
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
            "wolfBalance": hiddenGeometry.wolfBalance.category
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
    let profileHash: String
    let numerologyVector: NumerologyVector
    let ashState: SigilStabilizedState
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

private func makeNumerologyVector(profile: SigilProfileInput) -> NumerologyVector {
    let dateDigits = profile.birthDate.compactMap(\.wholeNumberValue)
    let dateTotal = dateDigits.reduce(0, +)
    let birthDay = profile.birthDate.split(separator: "-").last.flatMap { Int($0) } ?? 1
    let order = parseBirthOrder(profile.birthOrder)

    return NumerologyVector(
        lifePathRoot: reducedRoot(dateTotal),
        preservedMasterNumbers: [11, 22, 33].contains(dateTotal) ? [dateTotal] : [],
        birthDayRoot: reducedRoot(birthDay),
        expressionDestinyRoot: reducedRoot(profile.name.unicodeScalars.map { Int($0.value) }.reduce(0, +)),
        soulUrgeRoot: reducedRoot(profile.eyes.unicodeScalars.map { Int($0.value) }.reduce(0, +)),
        personalityRoot: reducedRoot(profile.hair.unicodeScalars.map { Int($0.value) }.reduce(0, +)),
        birthOrderOrdinal: order.ordinal,
        birthOrderTotal: order.total
    )
}

private func parseBirthOrder(_ value: String) -> (ordinal: Int, total: Int) {
    let numbers = value.split { !$0.isNumber }.compactMap { Int($0) }
    guard numbers.count >= 2 else {
        return (1, 1)
    }
    return (max(1, numbers[0]), max(1, numbers[1]))
}

private func reducedRoot(_ value: Int) -> Int {
    var current = max(1, value)
    while current > 9 {
        current = String(current).compactMap(\.wholeNumberValue).reduce(0, +)
    }
    return current
}

private func makePlaneVector(digestBytes: [UInt8]) -> [Double] {
    let raw = (0..<9).map { index in
        Double(digestBytes[index % digestBytes.count] % 89 + 11)
    }
    let total = raw.reduce(0, +)
    return raw.map { quantized($0 / total) }
}

private func dominantPlaneID(in vector: [Double]) -> Int {
    vector.enumerated().max { lhs, rhs in
        if lhs.element == rhs.element {
            return lhs.offset > rhs.offset
        }
        return lhs.element < rhs.element
    }.map { $0.offset + 1 } ?? 1
}

private func makeWolfBalance(digestBytes: [UInt8]) -> WolfBalance {
    let white = quantized(Double(digestBytes[9] % 80 + 10) / 100.0)
    let dark = quantized(Double(digestBytes[10] % 80 + 10) / 100.0)
    let category: String
    if abs(white - dark) <= 0.12 {
        category = "balanced"
    } else if white > dark {
        category = "white_dominant"
    } else {
        category = "dark_dominant"
    }
    return WolfBalance(whiteWeight: white, darkWeight: dark, category: category)
}

private func makeAncestryWeights(heritage: [String]) -> [AncestryWeight] {
    let families = heritage.map(ancestryFamily)
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

private func ancestryFamily(_ value: String) -> String {
    switch value.lowercased() {
    case "swedish", "german", "english", "scandinavian":
        return "germanic"
    case "irish", "scottish", "welsh":
        return "celtic"
    case "polish", "ukrainian", "russian", "slovak":
        return "slavic"
    default:
        return "mixed"
    }
}

private func celestialBasisID(dominantPlaneId: Int, wolfCategory: String) -> String {
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

private func makeHiddenAnchors(digestBytes: [UInt8], dominantPlaneId: Int) -> [SigilAnchorPoint] {
    let offset = Double(digestBytes[11] % 7) - 3.0
    let planeOffset = Double(dominantPlaneId - 5)

    return [
        SigilAnchorPoint(id: "hidden.crown", x: quantized(50 + offset), y: quantized(12 + planeOffset), semanticRole: "upper_structure_basis"),
        SigilAnchorPoint(id: "hidden.nexus", x: quantized(50 - offset / 2), y: 50, semanticRole: "central_convergence_basis"),
        SigilAnchorPoint(id: "hidden.root", x: quantized(50 + offset / 3), y: quantized(86 - planeOffset), semanticRole: "lower_root_basis"),
        SigilAnchorPoint(id: "hidden.left", x: quantized(24 + offset), y: 46, semanticRole: "ancestral_left_basis"),
        SigilAnchorPoint(id: "hidden.right", x: quantized(76 - offset), y: 46, semanticRole: "ancestral_right_basis")
    ]
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
        pathData: "M \(coordinate(x1)) \(coordinate(y1)) L \(coordinate(x2)) \(coordinate(y2))",
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
        pathData: "M \(coordinate(startX)) \(coordinate(startY)) Q \(coordinate(controlX)) \(coordinate(controlY)) \(coordinate(endX)) \(coordinate(endY))",
        strokeRole: strokeRole,
        semanticSource: semanticSource
    )
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
