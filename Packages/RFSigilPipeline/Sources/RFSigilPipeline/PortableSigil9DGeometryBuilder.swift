import CryptoKit
import Foundation
import RFCoreModels

protocol Sigil9DGeometryBuilding: Sendable {
    func buildSegments(vector: CanonicalVector, profileSeed: SigilProfileSeed?) -> [SigilLine]
}

struct SigilProfileSeed: Sendable {
    let userID: String
    let birthDate: String
    let birthOrder: Int
    let siblingCount: Int
    let heightCentimeters: Double
    let hairColor: String
    let eyeColor: String
    let birthLatitude: Double
    let birthLongitude: Double
    let sex: String?
    let dominantHand: String?
    let nameSeed: String?
}

struct PortableSigil9DGeometryBuilder: Sigil9DGeometryBuilding {
    func buildSegments(vector: CanonicalVector, profileSeed: SigilProfileSeed?) -> [SigilLine] {
        let resolver = PortableSigil9DParameterResolver()
        let parameters = resolver.resolve(from: vector, profileSeed: profileSeed)
        return PortableSigil9DGenerator().buildSegments(parameters: parameters)
    }
}

private struct PortableSigil9DParameters: Sendable {
    let topologyMode: PortableTopologyMode
    let symmetryOrder: Int
    let sampleCount: Int
    let families: [PortableFamilyHarmonicSet]
    let projector: PortableSigil9DProjector
}

private enum PortableTopologyMode: Int, Sendable, CaseIterable {
    case roseWeb = 0
    case lissajousBraid = 1
    case hypotrochoidRune = 2
    case polygramLattice = 3
    case spiralGate = 4
    case lemniscateForge = 5
}

private struct PortableFamilyHarmonicSet: Sendable {
    let harmonics: [PortableFamilyHarmonic]
    let rosePhase: Double
    let latticeBlend: Double
    let hypotrochoidR: Double
    let hypotrochoidr: Double
    let hypotrochoidD: Double
    let hypotrochoidRate: Double
    let hypotrochoidPhase: Double
    let gateRate: Double
    let gatePhase: Double
    let lemniscateScale: Double
    let lemniscateRate: Double
    let lemniscatePhase: Double
}

private struct PortableFamilyHarmonic: Sendable {
    let a: Double
    let b: Double
    let n: Int
    let m: Int
    let phi: Double
    let psi: Double
}

private struct PortableResolvedProfileFeatures: Sendable {
    let features: [Double]   // F0...F8
    let lifePath: Int
    let seedMaterial: String
}

private struct PortableSigil9DParameterResolver: Sendable {
    private let weightClamp: ClosedRange<Double> = 0.10...1.55
    private let angleClamp: ClosedRange<Double> = -1.45...1.45
    private let hairPalette: [String: Double] = [
        "black": 0.08,
        "dark brown": 0.16,
        "brown": 0.22,
        "light brown": 0.28,
        "auburn": 0.34,
        "red": 0.42,
        "strawberry blonde": 0.52,
        "blonde": 0.58,
        "gray": 0.74,
        "grey": 0.74,
        "white": 0.88
    ]
    private let eyePalette: [String: Double] = [
        "black": 0.10,
        "dark brown": 0.14,
        "brown": 0.18,
        "hazel": 0.32,
        "green": 0.46,
        "amber": 0.52,
        "blue": 0.64,
        "gray": 0.79,
        "grey": 0.79
    ]

    func resolve(from vector: CanonicalVector, profileSeed: SigilProfileSeed?) -> PortableSigil9DParameters {
        let resolved = resolveProfileFeatures(vector: vector, profileSeed: profileSeed)
        let features = resolved.features
        let lifePath = resolved.lifePath
        let u = normalizedSequence(seedMaterial: resolved.seedMaterial, count: 448)

        let topologyBlend = 0.55 * sample(u, at: 0) + 0.45 * features[2]
        let topologyRaw = Int(floor(Double(PortableTopologyMode.allCases.count) * topologyBlend))
        let topologyMode = PortableTopologyMode(rawValue: topologyRaw % PortableTopologyMode.allCases.count) ?? .lissajousBraid
        let symmetryOrder = (2 + Int(floor(11.0 * (0.60 * sample(u, at: 1) + 0.40 * features[3])))).clamped(to: 2...12)
        let familyCount = (2 + Int(floor(4.0 * (0.50 * sample(u, at: 2) + 0.50 * features[4])))).clamped(to: 2...5)
        let harmonicsPerFamily = (3 + Int(floor(5.0 * (0.60 * sample(u, at: 3) + 0.40 * features[6])))).clamped(to: 3...7)
        let sampleCountBlend = 0.50 * sample(u, at: 4) + 0.50 * features[7]
        let sampleCount = 640 + (160 * Int(floor(3.0 * sampleCountBlend)))

        let families = resolveFamilies(
            count: familyCount,
            harmonicsPerFamily: harmonicsPerFamily,
            lifePath: lifePath,
            features: features,
            u: u
        )

        let hiddenProfiles: [PortableHiddenDimensionProfile] = (2...8).map { dimension in
            let offset = dimension - 2
            let amplitude = (0.012 + 0.074 * features[offset]) * (0.58 + 0.42 * sample(u, at: 200 + dimension))
            let frequency = 0.85 + 0.52 * Double(dimension) + 0.85 * sample(u, at: 220 + dimension)
            let phase = 2.0 * Double.pi * sample(u, at: 240 + dimension)
            return PortableHiddenDimensionProfile(
                dimension: dimension,
                amplitude: amplitude,
                frequency: frequency,
                phase: phase
            )
        }

        let planeWeights: [Double] = (0..<9).map { dimension in
            let weighted = 0.60 * features[dimension] + 0.40 * sample(u, at: 300 + dimension)
            let value = 0.12 + 1.30 * weighted
            return value.clamped(to: weightClamp)
        }

        let rotationPairs: [(Int, Int)] = [
            (0, 2),
            (1, 3),
            (0, 4),
            (1, 5),
            (0, 6),
            (1, 7),
            (0, 8),
            (1, 8)
        ]
        let rotations = rotationPairs.enumerated().map { offset, pair in
            let rawAngle =
                1.05 * Double.pi * (2.0 * sample(u, at: 330 + offset) - 1.0)
                + 0.28 * (features[offset % 9] - 0.5)
            return PortableGivensRotation(i: pair.0, j: pair.1, angle: rawAngle.clamped(to: angleClamp))
        }

        let projection = PortableProjectionMatrixBuilder().makeMatrix(
            rotations: rotations,
            planeWeights: planeWeights
        )
        let projector = PortableSigil9DProjector(
            matrix: projection,
            hiddenProfiles: hiddenProfiles,
            tubeProfile: PortableTubeProfile(
                radius: 0.0,
                omega: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                frequency: 1.0,
                phase: 0.0
            )
        )

        return PortableSigil9DParameters(
            topologyMode: topologyMode,
            symmetryOrder: symmetryOrder,
            sampleCount: max(120, sampleCount),
            families: families,
            projector: projector
        )
    }

    private func resolveProfileFeatures(
        vector: CanonicalVector,
        profileSeed: SigilProfileSeed?
    ) -> PortableResolvedProfileFeatures {
        if let profileSeed {
            let birthDate = parseBirthDate(profileSeed.birthDate)
            let lifePath = digitalRoot(fromDigits: String(format: "%04d%02d%02d", birthDate.year, birthDate.month, birthDate.day))
            let siblingCount = max(0, profileSeed.siblingCount)
            let heightCm = profileSeed.heightCentimeters.clamped(to: 90.0...260.0)
            let birthOrder = max(1, profileSeed.birthOrder)
            let lat = profileSeed.birthLatitude.clamped(to: -90.0...90.0)
            let lon = profileSeed.birthLongitude.clamped(to: -180.0...180.0)

            let f0 = (Double(birthDate.day) / 31.0).clamped(to: 0...1)
            let f1 = (Double(birthDate.month) / 12.0).clamped(to: 0...1)
            let f2 = (Double(lifePath) / 9.0).clamped(to: 0...1)
            let f3 = (Double(birthOrder - 1) / Double(max(1, siblingCount))).clamped(to: 0...1)
            let f4 = (Double(siblingCount) / 10.0).clamped(to: 0...1)
            let f5 = ((heightCm - 140.0) / 70.0).clamped(to: 0...1)
            let f6 = colorScalar(profileSeed.hairColor, palette: hairPalette)
            let f7 = colorScalar(profileSeed.eyeColor, palette: eyePalette)
            let f8 = (0.5 * ((lat + 90.0) / 180.0) + 0.5 * ((lon + 180.0) / 360.0)).clamped(to: 0...1)

            return PortableResolvedProfileFeatures(
                features: [f0, f1, f2, f3, f4, f5, f6, f7, f8],
                lifePath: lifePath,
                seedMaterial: canonicalSeedMaterial(for: profileSeed)
            )
        }

        let h = vector.H_entropy.clamped(to: 0...1)
        let k = vector.K_complexity.clamped(to: 0...1)
        let d = ((vector.D_fractal_dim - 1.0) / 2.0).clamped(to: 0...1)
        let s = vector.S_symmetry.clamped(to: 0...1)
        let l = (Double(vector.L_generator_length - 1) / 998.0).clamped(to: 0...1)
        let lifePath = fallbackLifePath(from: vector)
        let features = [
            h,
            k,
            Double(lifePath) / 9.0,
            s,
            l,
            0.5 * (d + l),
            0.5 * (h + k),
            0.5 * (s + l),
            0.5 * (d + h)
        ]
        .map { $0.clamped(to: 0...1) }

        return PortableResolvedProfileFeatures(
            features: features,
            lifePath: lifePath,
            seedMaterial: canonicalSeedMaterial(for: vector)
        )
    }

    private func resolveFamilies(
        count: Int,
        harmonicsPerFamily: Int,
        lifePath: Int,
        features: [Double],
        u: [Double]
    ) -> [PortableFamilyHarmonicSet] {
        (0..<count).map { familyIndex in
            let harmonics: [PortableFamilyHarmonic] = (0..<harmonicsPerFamily).map { harmonicIndex in
                let cursor = 20 + familyIndex * harmonicsPerFamily * 6 + harmonicIndex * 6
                let a =
                    (0.08 + 0.30 * sample(u, at: cursor))
                    * (0.55 + 0.45 * features[(familyIndex + harmonicIndex) % 9])
                let b =
                    (0.08 + 0.30 * sample(u, at: cursor + 1))
                    * (0.55 + 0.45 * features[(familyIndex + harmonicIndex + 2) % 9])
                let nSeed = Int(floor(12.0 * sample(u, at: cursor + 2)))
                let mSeed = Int(floor(12.0 * sample(u, at: cursor + 3)))
                let n = 1 + ((nSeed + lifePath + familyIndex + harmonicIndex + Int(floor(4.0 * features[0]))) % 19)
                let m = 1 + ((mSeed + familyIndex + 2 * harmonicIndex + Int(floor(6.0 * features[1]))) % 19)
                let phi = 2.0 * Double.pi * sample(u, at: cursor + 4)
                let psi = 2.0 * Double.pi * sample(u, at: cursor + 5)
                return PortableFamilyHarmonic(a: a, b: b, n: n, m: m, phi: phi, psi: psi)
            }

            return PortableFamilyHarmonicSet(
                harmonics: harmonics,
                rosePhase: 2.0 * Double.pi * sample(u, at: 96 + familyIndex),
                latticeBlend: (0.35 + 0.45 * features[(familyIndex + 2) % 9]).clamped(to: 0...1),
                hypotrochoidR: 0.20 + 0.30 * sample(u, at: 112 + familyIndex),
                hypotrochoidr: 0.05 + 0.20 * sample(u, at: 128 + familyIndex),
                hypotrochoidD: 0.06 + 0.28 * sample(u, at: 144 + familyIndex),
                hypotrochoidRate: 0.5 + 2.0 * sample(u, at: 160 + familyIndex),
                hypotrochoidPhase: 2.0 * Double.pi * sample(u, at: 176 + familyIndex),
                gateRate: sample(u, at: 192 + familyIndex),
                gatePhase: 2.0 * Double.pi * sample(u, at: 208 + familyIndex),
                lemniscateScale: 0.20 + 0.55 * sample(u, at: 224 + familyIndex),
                lemniscateRate: 0.40 + 2.20 * sample(u, at: 240 + familyIndex),
                lemniscatePhase: 2.0 * Double.pi * sample(u, at: 256 + familyIndex)
            )
        }
    }

    private func canonicalSeedMaterial(for profileSeed: SigilProfileSeed) -> String {
        var entries: [String: String] = [
            "birth_date": normalizeToken(profileSeed.birthDate),
            "birth_latitude": String(format: "%.6f", profileSeed.birthLatitude.clamped(to: -90.0...90.0)),
            "birth_longitude": String(format: "%.6f", profileSeed.birthLongitude.clamped(to: -180.0...180.0)),
            "birth_order": String(max(1, profileSeed.birthOrder)),
            "eye_color": normalizeToken(profileSeed.eyeColor),
            "hair_color": normalizeToken(profileSeed.hairColor),
            "height_cm": String(format: "%.3f", profileSeed.heightCentimeters),
            "sibling_count": String(max(0, profileSeed.siblingCount)),
            "user_id": normalizeToken(profileSeed.userID)
        ]

        if let sex = profileSeed.sex?.trimmingCharacters(in: .whitespacesAndNewlines), !sex.isEmpty {
            entries["sex"] = normalizeToken(sex)
        }
        if let dominantHand = profileSeed.dominantHand?.trimmingCharacters(in: .whitespacesAndNewlines), !dominantHand.isEmpty {
            entries["dominant_hand"] = normalizeToken(dominantHand)
        }
        if let nameSeed = profileSeed.nameSeed?.trimmingCharacters(in: .whitespacesAndNewlines), !nameSeed.isEmpty {
            entries["name_seed"] = normalizeToken(nameSeed)
        }

        let body = entries.keys.sorted().map { key in
            "\"\(key)\":\"\(escapeJSON(entries[key] ?? ""))\""
        }
        .joined(separator: ",")
        return "{\(body)}"
    }

    private func canonicalSeedMaterial(for vector: CanonicalVector) -> String {
        let normL = (Double(vector.L_generator_length - 1) / 998.0).clamped(to: 0...1)
        let serialized = vector.canonicalSerialized()
        let fingerprint = SHA256.hash(data: Data(serialized.utf8)).prefix(8).map {
            String(format: "%02x", $0)
        }.joined()
        let entries: [String: String] = [
            "D_fractal_dim": String(format: "%.12f", vector.D_fractal_dim),
            "H_entropy": String(format: "%.12f", vector.H_entropy),
            "K_complexity": String(format: "%.12f", vector.K_complexity),
            "L_generator_norm": String(format: "%.12f", normL),
            "S_symmetry": String(format: "%.12f", vector.S_symmetry),
            "vector_fingerprint": fingerprint
        ]

        let body = entries.keys.sorted().map { key in
            "\"\(key)\":\"\(entries[key] ?? "")\""
        }
        .joined(separator: ",")
        return "{\(body)}"
    }

    private func normalizedSequence(seedMaterial: String, count: Int) -> [Double] {
        guard count > 0 else { return [] }

        var values: [Double] = []
        values.reserveCapacity(count)
        var counter = 0

        while values.count < count {
            let digest = Array(SHA512.hash(data: Data("\(seedMaterial)|\(counter)".utf8)))
            var index = 0
            while index + 3 < digest.count, values.count < count {
                let raw =
                    (UInt32(digest[index]) << 24)
                    | (UInt32(digest[index + 1]) << 16)
                    | (UInt32(digest[index + 2]) << 8)
                    | UInt32(digest[index + 3])
                values.append(Double(raw) / Double(UInt32.max))
                index += 4
            }
            counter += 1
        }

        return values
    }

    private func sample(_ values: [Double], at index: Int) -> Double {
        guard !values.isEmpty else { return 0.5 }
        return values[index % values.count].clamped(to: 0...1)
    }

    private func parseBirthDate(_ value: String) -> (year: Int, month: Int, day: Int) {
        let digits = value.filter(\.isNumber)
        guard digits.count >= 8 else { return (1970, 1, 1) }
        let year = Int(digits.prefix(4)) ?? 1970
        let month = Int(digits.dropFirst(4).prefix(2)) ?? 1
        let day = Int(digits.dropFirst(6).prefix(2)) ?? 1
        return (
            year.clamped(to: 1900...2200),
            month.clamped(to: 1...12),
            day.clamped(to: 1...31)
        )
    }

    private func fallbackLifePath(from vector: CanonicalVector) -> Int {
        let packed = String(
            format: "%04d%04d%04d%04d%03d",
            Int((vector.H_entropy.clamped(to: 0...1) * 1_000.0).rounded()),
            Int((vector.K_complexity.clamped(to: 0...1) * 1_000.0).rounded()),
            Int((((vector.D_fractal_dim - 1.0) / 2.0).clamped(to: 0...1) * 1_000.0).rounded()),
            Int((vector.S_symmetry.clamped(to: 0...1) * 1_000.0).rounded()),
            vector.L_generator_length.clamped(to: 1...999)
        )
        return digitalRoot(fromDigits: packed)
    }

    private func digitalRoot(fromDigits value: String) -> Int {
        let sum = value.compactMap(\.wholeNumberValue).reduce(0, +)
        return digitalRoot(sum)
    }

    private func digitalRoot(_ value: Int) -> Int {
        var result = max(1, value)
        while result > 9 {
            result = String(result).compactMap(\.wholeNumberValue).reduce(0, +)
        }
        return result.clamped(to: 1...9)
    }

    private func colorScalar(_ value: String, palette: [String: Double]) -> Double {
        let normalized = normalizeToken(value)
        if let known = palette[normalized] {
            return known.clamped(to: 0...1)
        }

        guard !normalized.isEmpty else { return 0.5 }
        let bytes = Array(SHA256.hash(data: Data(normalized.utf8)))
        guard bytes.count >= 4 else { return 0.5 }
        let raw =
            (UInt32(bytes[0]) << 24)
            | (UInt32(bytes[1]) << 16)
            | (UInt32(bytes[2]) << 8)
            | UInt32(bytes[3])
        return (Double(raw) / Double(UInt32.max)).clamped(to: 0...1)
    }

    private func normalizeToken(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func escapeJSON(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

private struct PortableSigil9DGenerator: Sendable {
    func buildSegments(parameters: PortableSigil9DParameters) -> [SigilLine] {
        let sampleCount = max(2, parameters.sampleCount)
        let totalCurves = max(1, parameters.families.count * parameters.symmetryOrder)
        var lines: [SigilLine] = []
        lines.reserveCapacity(totalCurves * sampleCount)
        var curveIndex = 0

        for family in parameters.families {
            for symmetryIndex in 0..<parameters.symmetryOrder {
                let angle = 2.0 * Double.pi * Double(symmetryIndex) / Double(parameters.symmetryOrder)
                let cosTheta = cos(angle)
                let sinTheta = sin(angle)
                var previous: (x: Double, y: Double)?
                var first: (x: Double, y: Double)?

                for sampleIndex in 0..<sampleCount {
                    let t = Double(sampleIndex) / Double(sampleCount)
                    let localForGlobal = Double(sampleIndex) / Double(max(1, sampleCount - 1))
                    var point = basePoint(t: t, family: family)
                    point = applyTopologyTransform(
                        point: point,
                        t: t,
                        mode: parameters.topologyMode,
                        symmetryOrder: parameters.symmetryOrder,
                        family: family
                    )
                    point = rotate(point: point, cosTheta: cosTheta, sinTheta: sinTheta)

                    let globalT = (Double(curveIndex) + localForGlobal) / Double(totalCurves)
                    let projected = parameters.projector.project(point2D: point, globalT: globalT)
                    if let previous {
                        appendSegment(from: previous, to: projected, into: &lines)
                    } else {
                        first = projected
                    }
                    previous = projected
                }

                if let first, let previous {
                    appendSegment(from: previous, to: first, into: &lines)
                }

                curveIndex += 1
            }
        }

        return lines
    }

    private func basePoint(t: Double, family: PortableFamilyHarmonicSet) -> (x: Double, y: Double) {
        let tau = 2.0 * Double.pi
        var x = 0.0
        var y = 0.0
        for harmonic in family.harmonics {
            x += harmonic.a * cos(tau * Double(harmonic.n) * t + harmonic.phi)
            y += harmonic.b * sin(tau * Double(harmonic.m) * t + harmonic.psi)
        }
        return (x, y)
    }

    private func applyTopologyTransform(
        point: (x: Double, y: Double),
        t: Double,
        mode: PortableTopologyMode,
        symmetryOrder: Int,
        family: PortableFamilyHarmonicSet
    ) -> (x: Double, y: Double) {
        switch mode {
        case .roseWeb:
            let r = hypot(point.x, point.y)
            let angle = atan2(point.y, point.x)
            let petals = max(2, symmetryOrder)
            let compression = 0.72 + 0.28 * cos(Double(petals) * angle + family.rosePhase)
            let adjustedR = r * compression
            return (adjustedR * cos(angle), adjustedR * sin(angle))

        case .lissajousBraid:
            return point

        case .hypotrochoidRune:
            let theta = 2.0 * Double.pi * t * family.hypotrochoidRate + family.hypotrochoidPhase
            let r = max(family.hypotrochoidr, 0.00001)
            let ratio = (family.hypotrochoidR - r) / r
            let offsetX = (family.hypotrochoidR - r) * cos(theta) + family.hypotrochoidD * cos(ratio * theta)
            let offsetY = (family.hypotrochoidR - r) * sin(theta) - family.hypotrochoidD * sin(ratio * theta)
            return (
                point.x + 0.35 * offsetX,
                point.y + 0.35 * offsetY
            )

        case .polygramLattice:
            let r = hypot(point.x, point.y)
            let angle = atan2(point.y, point.x)
            let step = (2.0 * Double.pi) / Double(max(2, symmetryOrder))
            let snapped = (angle / step).rounded() * step
            let blended = angle * (1.0 - family.latticeBlend) + snapped * family.latticeBlend
            return (r * cos(blended), r * sin(blended))

        case .spiralGate:
            let r = hypot(point.x, point.y)
            let angle = atan2(point.y, point.x)
            let ramp = 0.25 + 0.75 * t
            let gate = 2.0 * Double.pi * (0.6 + 1.8 * family.gateRate) * t + family.gatePhase
            let adjustedR = r * (0.55 + 0.90 * ramp)
            return (
                adjustedR * cos(angle + gate),
                adjustedR * sin(angle + gate)
            )

        case .lemniscateForge:
            let theta = 2.0 * Double.pi * family.lemniscateRate * t + family.lemniscatePhase
            let denom = 1.0 + pow(sin(theta), 2.0)
            let lx = family.lemniscateScale * cos(theta) / denom
            let ly = family.lemniscateScale * sin(theta) * cos(theta) / denom
            return (
                point.x + lx,
                point.y + ly
            )
        }
    }

    private func rotate(
        point: (x: Double, y: Double),
        cosTheta: Double,
        sinTheta: Double
    ) -> (x: Double, y: Double) {
        (
            point.x * cosTheta - point.y * sinTheta,
            point.x * sinTheta + point.y * cosTheta
        )
    }

    private func appendSegment(
        from start: (x: Double, y: Double),
        to end: (x: Double, y: Double),
        into lines: inout [SigilLine]
    ) {
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite else {
            return
        }

        let dx = end.x - start.x
        let dy = end.y - start.y
        guard (dx * dx + dy * dy) > 1e-12 else {
            return
        }

        lines.append(
            SigilLine(
                startX: start.x,
                startY: start.y,
                endX: end.x,
                endY: end.y
            )
        )
    }
}

private struct PortableSigil9DProjector: Sendable {
    let matrix: PortableProjectionMatrix2x9
    let hiddenProfiles: [PortableHiddenDimensionProfile]
    let tubeProfile: PortableTubeProfile

    func project(point2D: (x: Double, y: Double), globalT: Double) -> (x: Double, y: Double) {
        var vector = [Double](repeating: 0.0, count: 9)
        vector[0] = point2D.x
        vector[1] = point2D.y

        for (offset, profile) in hiddenProfiles.enumerated() {
            let signal = profile.amplitude * sin(2.0 * Double.pi * profile.frequency * globalT + profile.phase)
            let tubeSignal = tubeProfile.radius
                * (tubeProfile.omega[safe: offset] ?? 0.0)
                * sin((2.0 * Double.pi * tubeProfile.frequency * globalT) + tubeProfile.phase + Double(offset) * 0.41)
            vector[profile.dimension] = signal + tubeSignal
        }

        return matrix.project(vector)
    }
}

private struct PortableProjectionMatrix2x9: Sendable {
    let rowX: [Double]
    let rowY: [Double]

    func project(_ vector: [Double]) -> (x: Double, y: Double) {
        (dot(rowX, vector), dot(rowY, vector))
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { partial, pair in
            partial + pair.0 * pair.1
        }
    }
}

private struct PortableGivensRotation: Sendable {
    let i: Int
    let j: Int
    let angle: Double
}

private struct PortableProjectionMatrixBuilder: Sendable {
    func makeMatrix(rotations: [PortableGivensRotation], planeWeights: [Double]) -> PortableProjectionMatrix2x9 {
        var basis = identity(size: 9)

        for rotation in rotations {
            apply(rotation, to: &basis)
        }

        var rowX = basis[0]
        var rowY = basis[1]
        for index in 0..<9 {
            rowX[index] *= planeWeights[safe: index] ?? 1.0
            rowY[index] *= planeWeights[safe: index] ?? 1.0
        }

        return PortableProjectionMatrix2x9(rowX: rowX, rowY: rowY)
    }

    private func identity(size: Int) -> [[Double]] {
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        for index in 0..<size {
            matrix[index][index] = 1.0
        }
        return matrix
    }

    private func apply(_ rotation: PortableGivensRotation, to matrix: inout [[Double]]) {
        guard (0..<9).contains(rotation.i), (0..<9).contains(rotation.j), rotation.i != rotation.j else {
            return
        }

        let c = cos(rotation.angle)
        let s = sin(rotation.angle)
        let rowI = matrix[rotation.i]
        let rowJ = matrix[rotation.j]

        for column in 0..<9 {
            matrix[rotation.i][column] = c * rowI[column] - s * rowJ[column]
            matrix[rotation.j][column] = s * rowI[column] + c * rowJ[column]
        }
    }
}

private struct PortableHiddenDimensionProfile: Sendable {
    let dimension: Int
    let amplitude: Double
    let frequency: Double
    let phase: Double
}

private struct PortableTubeProfile: Sendable {
    let radius: Double
    let omega: [Double]
    let frequency: Double
    let phase: Double
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
