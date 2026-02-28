import CryptoKit
import Foundation
import RFCoreModels
import RFEngineData

public protocol SigilPipelineService: Sendable {
    func generate(profile: PersonProfile, options: SigilOptions) throws -> SigilResult
    func regenerateGeometry(from vector: CanonicalVector) throws -> SigilGeometry
    func estimatePlane(for vector: CanonicalVector) -> Int
}

public enum SigilPipelineError: Error {
    case invalidBits
    case invalidInput(String)
    case unsupportedPipelineVersion(String)
}

public struct UserProfileInput: Codable, Hashable, Sendable {
    public var firstName: String
    public var lastName: String
    public var birthDate: String
    public var birthTime: String
    public var birthOrder: Int
    public var motherBirthOrder: Int
    public var fatherBirthOrder: Int
    public var petNames: [String]
    public var significantNumbers: [Int]
    public var additionalStrings: [String]
    public var birthLatitude: Double?
    public var birthLongitude: Double?

    public init(
        firstName: String,
        lastName: String,
        birthDate: String,
        birthTime: String,
        birthOrder: Int,
        motherBirthOrder: Int,
        fatherBirthOrder: Int,
        petNames: [String] = [],
        significantNumbers: [Int] = [],
        additionalStrings: [String] = [],
        birthLatitude: Double? = nil,
        birthLongitude: Double? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthOrder = birthOrder
        self.motherBirthOrder = motherBirthOrder
        self.fatherBirthOrder = fatherBirthOrder
        self.petNames = petNames
        self.significantNumbers = significantNumbers
        self.additionalStrings = additionalStrings
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
    }
}

public final class DefaultSigilPipelineService: SigilPipelineService, Sendable {
    private let engineData: EngineDataProviding
    private let inputAdapter: any ProfileInputAdapting
    private let canonicalizer: any InputCanonicalizing
    private let vectorBuilder: any PatternVectorBuilding
    private let imprintBuilder: any ImprintKeyBuilding
    private let coreBuilder: any SigilCore9DBuilding
    private let lsystemEngine: any LSystemGenerating
    private let turtleProjector: any TurtleProjecting
    private let symmetryComposer: any SymmetryComposing
    private let geometryNormalizer: any SegmentGeometryNormalizing
    private let hasher: any StableHashing
    private let nameGenerator: any CelestialNaming
    private let insightsBuilder: any CodexInsightsBuilding

    private let symmetryOrder = 12
    private let canvasSize = CGSize(width: 1024, height: 1024)
    private let canvasPadding = 0.10
    private let maxExpandedLSystemLength = 80_000
    private let maxBaseSegmentCount = 8_000

    public init(engineData: EngineDataProviding = EngineDataStore()) {
        self.engineData = engineData
        self.inputAdapter = ProfileInputAdapter()
        self.canonicalizer = InputCanonicalizer()
        self.vectorBuilder = AgentPatternVectorBuilder()
        self.imprintBuilder = ImprintKeyBuilder()
        self.coreBuilder = SigilCore9DBuilder()
        self.lsystemEngine = AgentLSystemEngine()
        self.turtleProjector = TurtleProjector2D()
        self.symmetryComposer = RotationalSymmetryComposer()
        self.geometryNormalizer = GeometryNormalizer()
        self.hasher = FNV1a64Hasher()
        self.nameGenerator = CelestialNameGenerator()
        self.insightsBuilder = DefaultCodexInsightsBuilder()
    }

    public func generate(profile: PersonProfile, options: SigilOptions = SigilOptions()) throws -> SigilResult {
        let input = inputAdapter.makeInput(from: profile, includeOptionalTraits: options.includeTraitExtensions)
        return try generateInternal(profileID: profile.id, input: input)
    }

    public func generateSigilResult(input: UserProfileInput) throws -> SigilResult {
        let normalized = canonicalizer.normalize(input)
        let canonical = canonicalizer.canonicalString(for: normalized)
        let digest = SHA256.hash(data: Data(canonical.utf8)).hexString
        let profileID = deterministicUUID(fromHex: digest)
        return try generateInternal(profileID: profileID, input: normalized)
    }

    public func regenerateGeometry(from vector: CanonicalVector) throws -> SigilGeometry {
        try regenerateGeometry(from: vector, pipelineVersion: RFConstants.pipelineVersion)
    }

    public func regenerateGeometry(from vector: CanonicalVector, pipelineVersion: String) throws -> SigilGeometry {
        guard pipelineVersion == RFConstants.pipelineVersion || pipelineVersion == "wrw_personal_sigil_v1" else {
            throw SigilPipelineError.unsupportedPipelineVersion(pipelineVersion)
        }

        let core = coreBuilder.buildCore9D(vector: vector)
        let imprint = imprintBuilder.build(for: vector)
        let (_, geometry) = buildGeometry(core9D: core, seed64: imprint.seed64)
        return geometry
    }

    public func estimatePlane(for vector: CanonicalVector) -> Int {
        Self.estimatePlane(for: vector)
    }

    public static func estimatePlane(for vector: CanonicalVector) -> Int {
        let safeH = vector.H_entropy.finiteOr(0.5).clamped(to: 0...1)
        let safeK = vector.K_complexity.finiteOr(0.5).clamped(to: 0...1)
        let safeD = vector.D_fractal_dim.finiteOr(2.0)
        let safeS = vector.S_symmetry.finiteOr(0.5).clamped(to: 0...1)
        let normalizedD = ((safeD - 1.0) / 2.0).clamped(to: 0...1)
        let score = safeK + safeS + normalizedD + (1.0 - safeH)
        guard score.isFinite else { return 5 }
        return Int(floor(score * 2.25) + 1).clamped(to: 1...9)
    }

    private func generateInternal(profileID: UUID, input: UserProfileInput) throws -> SigilResult {
        let normalized = canonicalizer.normalize(input)
        let vectorOutput = vectorBuilder.buildPatternVector(input: normalized)
        let vector = vectorOutput.vector

        let core9D = coreBuilder.buildCore9D(vector: vector)
        guard core9D.bits9.count == 9 else {
            throw SigilPipelineError.invalidBits
        }

        let imprint = imprintBuilder.build(for: vector)
        let (lsystem, geometry) = buildGeometry(core9D: core9D, seed64: imprint.seed64)
        let geometryHash = hasher.hex(hasher.hashString(geometry.serialized()))

        let hasOptionalExtras = !normalized.significantNumbers.isEmpty || !normalized.additionalStrings.isEmpty
        let celestialName = nameGenerator.generate(vector: vector, includeFifthSyllable: hasOptionalExtras)
        let codexInsights = insightsBuilder.buildInsights(
            vector: vector,
            dateReduction: vectorOutput.dateReduce,
            symmetryOrder: symmetryOrder
        )

        return SigilResult(
            profileID: profileID,
            vector: vector,
            bits9: SigilBits9(bits: core9D.bits9, parity: core9D.parity),
            celestialName: celestialName,
            lsystem: lsystem,
            geometry: geometry,
            geometryHash: geometryHash,
            pipelineVersion: RFConstants.pipelineVersion,
            engineDataVersion: engineData.engineDataVersion,
            codexInsights: codexInsights
        )
    }

    private func buildGeometry(core9D: SigilCore9DState, seed64: UInt64) -> (LSystemDefinition, SigilGeometry) {
        let lsystem = lsystemEngine.makeConfig(core9D: core9D, seed64: seed64)
        let expanded = lsystemEngine.expand(
            axiom: lsystem.axiom,
            rules: lsystem.rules,
            iterations: lsystem.iterations,
            maxLength: maxExpandedLSystemLength
        )
        let projected = turtleProjector.project(lsys: expanded, angleDeg: lsystem.angle, step: 1.0)
        let boundedBaseSegments = deterministicSample(projected, maxCount: maxBaseSegmentCount)
        let segments = symmetryComposer.applyRotationalSymmetry(
            segments: boundedBaseSegments,
            order: symmetryOrder,
            center: (0.0, 0.0)
        )
        let geometry = geometryNormalizer.normalize(segments: segments, canvas: canvasSize, padding: canvasPadding)
        return (lsystem, geometry)
    }

    private func deterministicSample(_ segments: [SigilLine], maxCount: Int) -> [SigilLine] {
        guard maxCount > 0, segments.count > maxCount else { return segments }
        let stride = Int(ceil(Double(segments.count) / Double(maxCount)))
        guard stride > 1 else { return Array(segments.prefix(maxCount)) }

        var sampled: [SigilLine] = []
        sampled.reserveCapacity(maxCount)
        for (index, segment) in segments.enumerated() where index.isMultiple(of: stride) {
            sampled.append(segment)
            if sampled.count == maxCount {
                break
            }
        }

        if sampled.count < maxCount {
            let remaining = maxCount - sampled.count
            sampled.append(contentsOf: segments.suffix(remaining))
        }
        return sampled
    }

    private func deterministicUUID(fromHex hex: String) -> UUID {
        let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        var bytes: [UInt8] = []
        bytes.reserveCapacity(16)

        var index = cleanHex.startIndex
        while index < cleanHex.endIndex, bytes.count < 16 {
            let next = cleanHex.index(index, offsetBy: 2, limitedBy: cleanHex.endIndex) ?? cleanHex.endIndex
            let chunk = String(cleanHex[index..<next])
            if let value = UInt8(chunk, radix: 16) {
                bytes.append(value)
            }
            index = next
        }

        while bytes.count < 16 {
            bytes.append(0)
        }

        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let tuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: tuple)
    }
}

private protocol ProfileInputAdapting: Sendable {
    func makeInput(from profile: PersonProfile, includeOptionalTraits: Bool) -> UserProfileInput
}

private protocol InputCanonicalizing: Sendable {
    func normalize(_ input: UserProfileInput) -> UserProfileInput
    func canonicalString(for input: UserProfileInput) -> String
}

private protocol PatternVectorBuilding: Sendable {
    func buildPatternVector(input: UserProfileInput) -> PatternVectorBuildOutput
}

private protocol ImprintKeyBuilding: Sendable {
    func build(for vector: CanonicalVector) -> ImprintKeyDescriptor
}

private protocol SigilCore9DBuilding: Sendable {
    func buildCore9D(vector: CanonicalVector) -> SigilCore9DState
}

private protocol LSystemGenerating: Sendable {
    func makeConfig(core9D: SigilCore9DState, seed64: UInt64) -> LSystemDefinition
    func expand(axiom: String, rules: [String: String], iterations: Int, maxLength: Int) -> String
}

private protocol TurtleProjecting: Sendable {
    func project(lsys: String, angleDeg: Double, step: Double) -> [SigilLine]
}

private protocol SymmetryComposing: Sendable {
    func applyRotationalSymmetry(segments: [SigilLine], order: Int, center: (Double, Double)) -> [SigilLine]
}

private protocol SegmentGeometryNormalizing: Sendable {
    func normalize(segments: [SigilLine], canvas: CGSize, padding: Double) -> SigilGeometry
}

private protocol StableHashing: Sendable {
    func hashString(_ string: String) -> UInt64
    func hex(_ value: UInt64) -> String
}

private protocol CelestialNaming: Sendable {
    func generate(vector: CanonicalVector, includeFifthSyllable: Bool) -> String
}

private protocol CodexInsightsBuilding: Sendable {
    func buildInsights(vector: CanonicalVector, dateReduction: Int, symmetryOrder: Int) -> CodexInsights
}

private struct PatternVectorBuildOutput: Sendable {
    let vector: CanonicalVector
    let dateReduce: Int
}

private struct ImprintKeyDescriptor: Sendable {
    let hex: String
    let seed64: UInt64
}

private struct SigilCore9DState: Sendable {
    let bits9: String
    let parity: SigilParity
    let seed: UInt64
}

private struct ProfileInputAdapter: ProfileInputAdapting {
    func makeInput(from profile: PersonProfile, includeOptionalTraits: Bool) -> UserProfileInput {
        let dateTime = normalizeDateTime(from: profile)
        let numbers = includeOptionalTraits ? significantNumbers(from: profile) : []
        let strings = includeOptionalTraits ? additionalStrings(from: profile) : []

        return UserProfileInput(
            firstName: profile.givenName,
            lastName: profile.familyName,
            birthDate: dateTime.date,
            birthTime: dateTime.time,
            birthOrder: max(1, profile.birthOrder),
            motherBirthOrder: max(1, profile.mother.birthOrder),
            fatherBirthOrder: max(1, profile.father.birthOrder),
            petNames: profile.traits.petNames,
            significantNumbers: numbers,
            additionalStrings: strings,
            birthLatitude: profile.birthplace.latitude,
            birthLongitude: profile.birthplace.longitude
        )
    }

    private func normalizeDateTime(from profile: PersonProfile) -> (date: String, time: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezoneFromLongitude(profile.birthplace.longitude)

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: profile.birthDetails.date)
        if profile.birthDetails.isTimeUnknown {
            components.hour = 12
            components.minute = 0
        }

        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 12
        let minute = components.minute ?? 0

        return (
            String(format: "%04d-%02d-%02d", year, month, day),
            String(format: "%02d:%02d", hour, minute)
        )
    }

    private func timezoneFromLongitude(_ longitude: Double) -> TimeZone {
        let offsetHours = Int((longitude / 15).rounded()).clamped(to: -12...14)
        let seconds = offsetHours * 3600
        return TimeZone(secondsFromGMT: seconds) ?? TimeZone(secondsFromGMT: 0)!
    }

    private func significantNumbers(from profile: PersonProfile) -> [Int] {
        var values: [Int] = []

        values.append(contentsOf: [
            profile.birthOrderTotal,
            profile.mother.birthOrderTotal,
            profile.father.birthOrderTotal
        ].compactMap { $0 })

        values.append(contentsOf: profile.traits.professions.map { $0.yearsInProfession })

        for (_, value) in profile.traits.additionalTraits.sorted(by: { $0.key < $1.key }) {
            if let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                values.append(parsed)
            }
        }

        for (_, value) in profile.traits.dynamicFieldValues.sorted(by: { $0.key < $1.key }) {
            if let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                values.append(parsed)
            }
        }

        return values
    }

    private func additionalStrings(from profile: PersonProfile) -> [String] {
        var values: [String] = [
            profile.birthplaceName,
            profile.mother.hairColor,
            profile.mother.eyeColor,
            profile.father.hairColor,
            profile.father.eyeColor
        ]

        values.append(contentsOf: profile.traits.familyNames)
        values.append(contentsOf: profile.traits.heritage)
        values.append(contentsOf: profile.traits.hobbiesInterests)

        for profession in profile.traits.professions {
            values.append(profession.profession)
            values.append(profession.titleOrPosition)
            values.append(profession.customItemLabel)
            values.append(profession.customItemValue)
        }

        for (_, value) in profile.traits.additionalTraits.sorted(by: { $0.key < $1.key }) {
            if Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
                values.append(value)
            }
        }

        for (_, value) in profile.traits.dynamicFieldValues.sorted(by: { $0.key < $1.key }) {
            if Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
                values.append(value)
            }
        }

        return values
    }
}

private struct InputCanonicalizer: InputCanonicalizing {
    func normalize(_ input: UserProfileInput) -> UserProfileInput {
        UserProfileInput(
            firstName: normalizeName(input.firstName),
            lastName: normalizeName(input.lastName),
            birthDate: normalizeDate(input.birthDate),
            birthTime: normalizeTime(input.birthTime),
            birthOrder: max(1, input.birthOrder),
            motherBirthOrder: max(1, input.motherBirthOrder),
            fatherBirthOrder: max(1, input.fatherBirthOrder),
            petNames: input.petNames.map(normalizeName).filter { !$0.isEmpty },
            significantNumbers: input.significantNumbers,
            additionalStrings: input.additionalStrings.map(normalizeString).filter { !$0.isEmpty },
            birthLatitude: input.birthLatitude,
            birthLongitude: input.birthLongitude
        )
    }

    func canonicalString(for input: UserProfileInput) -> String {
        let lat = input.birthLatitude.map { String(format: "%.6f", $0) } ?? ""
        let lon = input.birthLongitude.map { String(format: "%.6f", $0) } ?? ""

        return [
            input.firstName,
            input.lastName,
            input.birthDate,
            input.birthTime,
            String(input.birthOrder),
            String(input.motherBirthOrder),
            String(input.fatherBirthOrder),
            input.petNames.joined(separator: ","),
            input.significantNumbers.map(String.init).joined(separator: ","),
            input.additionalStrings.joined(separator: ","),
            lat,
            lon
        ]
        .joined(separator: "|")
    }

    private func normalizeName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func normalizeString(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func normalizeDate(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        guard digits.count >= 8 else { return "1970-01-01" }
        let y = digits.prefix(4)
        let m = digits.dropFirst(4).prefix(2)
        let d = digits.dropFirst(6).prefix(2)
        return "\(y)-\(m)-\(d)"
    }

    private func normalizeTime(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        guard digits.count >= 4 else { return "12:00" }
        let h = digits.prefix(2)
        let m = digits.dropFirst(2).prefix(2)
        return "\(h):\(m)"
    }
}

private struct NumerologyReducer: Sendable {
    func reduceToSingleDigit(_ value: Int) -> Int {
        var result = abs(value)
        if result == 0 {
            return 9
        }
        while result > 9 {
            result = sumDigits(result)
        }
        return result == 0 ? 9 : result
    }

    func sumDigits(_ value: Int) -> Int {
        String(abs(value)).compactMap(\.wholeNumberValue).reduce(0, +)
    }

    func letterOrdinalSum(_ value: String) -> Int {
        value.uppercased().unicodeScalars
            .filter { $0.value >= 65 && $0.value <= 90 }
            .reduce(0) { partial, scalar in
                partial + Int(scalar.value - 64)
            }
    }

    func datetimeReduce(date: String, time: String) -> Int {
        let digits = (date + time).compactMap { $0.wholeNumberValue }
        return reduceToSingleDigit(digits.reduce(0, +))
    }
}

private struct AgentPatternVectorBuilder: PatternVectorBuilding {
    private let reducer = NumerologyReducer()

    func buildPatternVector(input: UserProfileInput) -> PatternVectorBuildOutput {
        let firstReduce = reducer.reduceToSingleDigit(reducer.letterOrdinalSum(input.firstName))
        let lastReduce = reducer.reduceToSingleDigit(reducer.letterOrdinalSum(input.lastName))
        let petReduces = input.petNames.map {
            reducer.reduceToSingleDigit(reducer.letterOrdinalSum($0))
        }

        let nameReduces = [firstReduce, lastReduce] + petReduces
        let nameAverage = reducer.reduceToSingleDigit(nameReduces.reduce(0, +))

        let dateReduce = reducer.datetimeReduce(date: input.birthDate, time: input.birthTime)
        let orderReduce = reducer.reduceToSingleDigit(input.birthOrder + input.motherBirthOrder + input.fatherBirthOrder)

        let geoReduce: Int? = {
            guard let latitude = input.birthLatitude, let longitude = input.birthLongitude else {
                return nil
            }
            guard latitude.isFinite, longitude.isFinite else {
                return nil
            }
            let latInt = Int(floor(abs(latitude) * 100.0))
            let lonInt = Int(floor(abs(longitude) * 100.0))
            let combined = latInt + lonInt
            return reducer.reduceToSingleDigit(reducer.sumDigits(combined))
        }()

        let additionalNumberReduces = input.significantNumbers.map { reducer.reduceToSingleDigit($0) }
        let additionalStringReduces = input.additionalStrings.map {
            reducer.reduceToSingleDigit(reducer.letterOrdinalSum($0))
        }
        let additionalReduces = additionalNumberReduces + additionalStringReduces
        let hasAdditionalData = !additionalReduces.isEmpty
        let additionalReduce = hasAdditionalData
            ? reducer.reduceToSingleDigit(additionalReduces.reduce(0, +))
            : 5

        let petAverage: Int = {
            if petReduces.isEmpty {
                return additionalReduce
            }
            let numerator = petReduces.reduce(0, +) + (hasAdditionalData ? additionalReduce : 0)
            let divisor = petReduces.count + (hasAdditionalData ? 1 : 0)
            let average = Int(floor(Double(numerator) / Double(max(1, divisor))))
            return reducer.reduceToSingleDigit(average)
        }()

        let vector = CanonicalVector(
            H_entropy: (Double(nameAverage) / 9.0).clamped(to: 0...1),
            K_complexity: (Double(dateReduce) / 9.0).clamped(to: 0...1),
            D_fractal_dim: (1.0 + (Double(orderReduce) / 9.0) * 2.0).clamped(to: 1...3),
            S_symmetry: (Double(geoReduce ?? additionalReduce) / 9.0).clamped(to: 0...1),
            L_generator_length: (1 + Int(floor(Double(petAverage) * 111.0))).clamped(to: 1...999)
        )

        return PatternVectorBuildOutput(vector: vector, dateReduce: dateReduce)
    }
}

private struct ImprintKeyBuilder: ImprintKeyBuilding {
    func build(for vector: CanonicalVector) -> ImprintKeyDescriptor {
        let serialized = canonicalSerialize(vector: vector)
        let digest = SHA256.hash(data: Data(serialized.utf8))
        let hex = digest.hexString
        let seed = seed64(fromDigestBytes: Array(digest))
        return ImprintKeyDescriptor(hex: hex, seed64: seed)
    }

    private func canonicalSerialize(vector: CanonicalVector) -> String {
        String(
            format: "H:%.6f;K:%.6f;D:%.6f;S:%.6f;L:%d;",
            vector.H_entropy,
            vector.K_complexity,
            vector.D_fractal_dim,
            vector.S_symmetry,
            vector.L_generator_length
        )
    }

    private func seed64(fromDigestBytes bytes: [UInt8]) -> UInt64 {
        guard bytes.count >= 32 else { return 0x9E37_79B9_7F4A_7C15 }

        let high = readUInt64BigEndian(bytes[16..<24])
        let low = readUInt64BigEndian(bytes[24..<32])
        let folded = high ^ low
        return folded == 0 ? 0x9E37_79B9_7F4A_7C15 : folded
    }

    private func readUInt64BigEndian(_ slice: ArraySlice<UInt8>) -> UInt64 {
        slice.reduce(0) { partial, byte in
            (partial << 8) | UInt64(byte)
        }
    }
}

private struct SigilCore9DBuilder: SigilCore9DBuilding {
    func buildCore9D(vector: CanonicalVector) -> SigilCore9DState {
        let normH = vector.H_entropy.clamped(to: 0...1)
        let normK = vector.K_complexity.clamped(to: 0...1)
        let normD = ((vector.D_fractal_dim - 1.0) / 2.0).clamped(to: 0...1)
        let normS = vector.S_symmetry.clamped(to: 0...1)
        let normL = (Double(vector.L_generator_length - 1) / 998.0).clamped(to: 0...1)

        let norms = [normH, normK, normD, normS, normL, normH, normK, normD, normS]
        let bits9 = norms.map { $0 > 0.5 ? "1" : "0" }.joined()

        let ones = bits9.filter { $0 == "1" }.count
        let parity: SigilParity = ones.isMultiple(of: 2) ? .even : .odd
        let seed = UInt64(bits9, radix: 2) ?? 0

        return SigilCore9DState(bits9: bits9, parity: parity, seed: seed)
    }
}

private struct AgentLSystemEngine: LSystemGenerating {
    func makeConfig(core9D: SigilCore9DState, seed64: UInt64) -> LSystemDefinition {
        let combinedSeed = core9D.seed ^ seed64
        var rng = XorShift64Star(seed: combinedSeed)

        let axiom = core9D.parity == .even ? "F" : "X"
        let evenRules = [
            "F[+F]",
            "F[-F]F",
            "FF-[-F+F+F]+[+F-F-F]"
        ]
        let oddRules = [
            "F[+F]F[-F]F",
            "F[-F][+F]F",
            "F[+F]--F[-F]"
        ]

        let pool = core9D.parity == .even ? evenRules : oddRules
        let selectedRule = pool[rng.nextInt(pool.count)]

        return LSystemDefinition(
            axiom: axiom,
            rules: [
                "F": selectedRule,
                "X": "F"
            ],
            angle: rng.nextDouble01() * 90.0,
            iterations: 3 + rng.nextInt(4)
        )
    }

    func expand(axiom: String, rules: [String: String], iterations: Int, maxLength: Int) -> String {
        var current = axiom

        for _ in 0..<max(0, iterations) {
            var next = String()
            next.reserveCapacity(min(maxLength, current.count * 3))

            for char in current {
                if let replacement = rules[String(char)] {
                    next.append(replacement)
                } else {
                    next.append(char)
                }

                if next.count > maxLength {
                    return current
                }
            }

            current = next
        }

        return current
    }
}

private struct TurtleProjector2D: TurtleProjecting {
    func project(lsys: String, angleDeg: Double, step: Double = 1.0) -> [SigilLine] {
        var lines: [SigilLine] = []

        var x = 0.0
        var y = 0.0
        var heading = 0.0

        let turn = angleDeg
        let stackLimit = 20_000
        var stack: [(x: Double, y: Double, heading: Double)] = []

        for symbol in lsys {
            switch symbol {
            case "F":
                let radians = heading * .pi / 180.0
                let nextX = x + cos(radians) * step
                let nextY = y + sin(radians) * step
                lines.append(SigilLine(startX: x, startY: y, endX: nextX, endY: nextY))
                x = nextX
                y = nextY
            case "+":
                heading += turn
            case "-":
                heading -= turn
            case "[":
                if stack.count < stackLimit {
                    stack.append((x, y, heading))
                }
            case "]":
                if let previous = stack.popLast() {
                    x = previous.x
                    y = previous.y
                    heading = previous.heading
                }
            default:
                continue
            }
        }

        return lines
    }
}

private struct RotationalSymmetryComposer: SymmetryComposing {
    func applyRotationalSymmetry(segments: [SigilLine], order: Int, center: (Double, Double)) -> [SigilLine] {
        guard order > 1, !segments.isEmpty else { return segments }

        let safeOrder = max(1, order)
        let angleStep = 2.0 * Double.pi / Double(safeOrder)

        var composed: [SigilLine] = []
        composed.reserveCapacity(segments.count * safeOrder)

        for copyIndex in 0..<safeOrder {
            let theta = angleStep * Double(copyIndex)
            let cosT = cos(theta)
            let sinT = sin(theta)

            for segment in segments {
                let start = rotate(
                    point: (segment.startX, segment.startY),
                    center: center,
                    cosT: cosT,
                    sinT: sinT
                )
                let end = rotate(
                    point: (segment.endX, segment.endY),
                    center: center,
                    cosT: cosT,
                    sinT: sinT
                )

                composed.append(
                    SigilLine(
                        startX: start.0,
                        startY: start.1,
                        endX: end.0,
                        endY: end.1
                    )
                )
            }
        }

        return composed
    }

    private func rotate(
        point: (Double, Double),
        center: (Double, Double),
        cosT: Double,
        sinT: Double
    ) -> (Double, Double) {
        let translatedX = point.0 - center.0
        let translatedY = point.1 - center.1

        let rx = translatedX * cosT - translatedY * sinT
        let ry = translatedX * sinT + translatedY * cosT

        return (rx + center.0, ry + center.1)
    }
}

private struct GeometryNormalizer: SegmentGeometryNormalizing {
    func normalize(segments: [SigilLine], canvas: CGSize, padding: Double) -> SigilGeometry {
        let finiteSegments = segments.filter {
            $0.startX.isFinite && $0.startY.isFinite && $0.endX.isFinite && $0.endY.isFinite
        }

        guard !finiteSegments.isEmpty else {
            return SigilGeometry(lines: [SigilLine(startX: 0.5, startY: 0.1, endX: 0.5, endY: 0.9)])
        }

        let xs = finiteSegments.flatMap { [$0.startX, $0.endX] }
        let ys = finiteSegments.flatMap { [$0.startY, $0.endY] }

        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return SigilGeometry(lines: [SigilLine(startX: 0.5, startY: 0.1, endX: 0.5, endY: 0.9)])
        }

        let width = max(maxX - minX, 0.000001)
        let height = max(maxY - minY, 0.000001)
        let centerX = (minX + maxX) / 2.0
        let centerY = (minY + maxY) / 2.0

        let pad = padding.clamped(to: 0...0.45)
        let drawableW = Double(canvas.width) * (1.0 - 2.0 * pad)
        let drawableH = Double(canvas.height) * (1.0 - 2.0 * pad)
        let scale = min(drawableW / width, drawableH / height)

        let safeScale = (scale.isFinite && scale > 0) ? scale : 1.0
        let targetCenterX = Double(canvas.width) / 2.0
        let targetCenterY = Double(canvas.height) / 2.0

        let normalizedLines = finiteSegments.map { segment in
            let start = transform(
                x: segment.startX,
                y: segment.startY,
                sourceCenterX: centerX,
                sourceCenterY: centerY,
                scale: safeScale,
                targetCenterX: targetCenterX,
                targetCenterY: targetCenterY,
                canvas: canvas
            )
            let end = transform(
                x: segment.endX,
                y: segment.endY,
                sourceCenterX: centerX,
                sourceCenterY: centerY,
                scale: safeScale,
                targetCenterX: targetCenterX,
                targetCenterY: targetCenterY,
                canvas: canvas
            )

            return SigilLine(
                startX: start.0,
                startY: start.1,
                endX: end.0,
                endY: end.1
            )
        }

        return SigilGeometry(lines: normalizedLines)
    }

    private func transform(
        x: Double,
        y: Double,
        sourceCenterX: Double,
        sourceCenterY: Double,
        scale: Double,
        targetCenterX: Double,
        targetCenterY: Double,
        canvas: CGSize
    ) -> (Double, Double) {
        let tx = ((x - sourceCenterX) * scale + targetCenterX) / Double(canvas.width)
        let ty = ((y - sourceCenterY) * scale + targetCenterY) / Double(canvas.height)

        return (
            quantize(tx.clamped(to: 0...1)),
            quantize(ty.clamped(to: 0...1))
        )
    }

    private func quantize(_ value: Double) -> Double {
        guard value.isFinite else { return 0.5 }
        return (value * 1_000_000.0).rounded() / 1_000_000.0
    }
}

private struct FNV1a64Hasher: StableHashing {
    func hashString(_ string: String) -> UInt64 {
        hashBytes(Data(string.utf8))
    }

    func hex(_ value: UInt64) -> String {
        String(format: "%016llx", value)
    }

    private func hashBytes(_ data: Data) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211

        for byte in data {
            hash ^= UInt64(byte)
            hash &*= prime
        }

        return hash
    }
}

private struct CelestialNameGenerator: CelestialNaming {
    private let pool = ["Thal", "Rion", "Kael", "Void", "Aeth", "Caus", "Shad", "Cel", "Ast", "Eth"]

    func generate(vector: CanonicalVector, includeFifthSyllable: Bool) -> String {
        let h = vector.H_entropy.clamped(to: 0...1)
        let k = vector.K_complexity.clamped(to: 0...1)
        let d = ((vector.D_fractal_dim - 1.0) / 2.0).clamped(to: 0...1)
        let s = vector.S_symmetry.clamped(to: 0...1)
        let l = (Double(vector.L_generator_length - 1) / 998.0).clamped(to: 0...1)

        var parts = [
            pool[index(for: h)],
            pool[index(for: k)],
            pool[index(for: d)],
            pool[index(for: s)]
        ]

        if includeFifthSyllable {
            parts.append(pool[index(for: l)])
        }

        return parts.joined(separator: " ")
    }

    private func index(for value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(floor(value * Double(pool.count - 1))).clamped(to: 0...(pool.count - 1))
    }
}

private struct DefaultCodexInsightsBuilder: CodexInsightsBuilding {
    func buildInsights(vector: CanonicalVector, dateReduction: Int, symmetryOrder: Int) -> CodexInsights {
        let plane = DefaultSigilPipelineService.estimatePlane(for: vector)
        let dominantPlaneCode = "P\(plane)"
        let safeSymmetry = vector.S_symmetry.finiteOr(0.5)
        let safeComplexity = vector.K_complexity.finiteOr(0.5)
        let safeFractal = vector.D_fractal_dim.finiteOr(2.0)
        let safeEntropy = vector.H_entropy.finiteOr(0.5)

        let wolfAlignment: String
        switch safeSymmetry {
        case let value where value >= 0.66:
            wolfAlignment = "white"
        case let value where value <= 0.34:
            wolfAlignment = "dark"
        default:
            wolfAlignment = "balanced"
        }

        var conditionsMet = 0
        if plane == 7 { conditionsMet += 1 }
        if wolfAlignment == "dark" || wolfAlignment == "balanced" { conditionsMet += 1 }
        if [6, 7, 9].contains(dateReduction) { conditionsMet += 1 }
        if safeComplexity > 0.75 { conditionsMet += 1 }
        if safeFractal > 1.6 { conditionsMet += 1 }

        let luciferianFlag = conditionsMet >= 3
        let publicDescription = luciferianFlag
            ? "Brother or Sister of Lucifer"
            : "Codex alignment remains within standard thresholds"

        let overlayType: String = {
            switch wolfAlignment {
            case "white":
                "clockwise_arc_overlay"
            case "dark":
                "counter_clockwise_arc_overlay"
            default:
                "dual_mirrored_arcs"
            }
        }()

        return CodexInsights(
            lifePathNumber: dateReduction,
            dominantPlaneCode: dominantPlaneCode,
            wolfAlignment: wolfAlignment,
            luciferianPublicDescription: publicDescription,
            luciferianPrivateFlag: luciferianFlag,
            branchingReflectionText: "Your higher self gathers wisdom from paths you never saw but always shaped.",
            sigilParameters: CodexSigilParameters(
                polygonSides: max(3, plane),
                radialLayers: (1 + Int(floor(safeFractal))).clamped(to: 1...4),
                symmetryOrder: symmetryOrder,
                distortionFactor: (safeEntropy * 0.2).clamped(to: 0...0.2),
                wolfOverlayType: overlayType
            )
        )
    }
}

private struct XorShift64Star: Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEAD_BEEF_CAFE_BABE : seed
    }

    mutating func nextUInt64() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2_685_821_657_736_338_717
    }

    mutating func nextDouble01() -> Double {
        let x = nextUInt64()
        return Double(x >> 11) / 9_007_199_254_740_992.0
    }

    mutating func nextInt(_ upperExclusive: Int) -> Int {
        guard upperExclusive > 0 else { return 0 }
        return Int(nextUInt64() % UInt64(upperExclusive))
    }
}

private extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

private extension Double {
    func finiteOr(_ fallback: Double) -> Double {
        isFinite ? self : fallback
    }
}

private extension SigilGeometry {
    func serialized() -> String {
        lines
            .map {
                String(
                    format: "%.6f,%.6f,%.6f,%.6f",
                    $0.startX,
                    $0.startY,
                    $0.endX,
                    $0.endY
                )
            }
            .joined(separator: "|")
    }
}
