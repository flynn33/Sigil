import Foundation
import RFCoreModels
import Testing
@testable import RFExport

@Test
func geometryExportJSONConformsToStrictRFGeometryV1Schema() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportGeometryJSON(from: result)
    let object = try jsonObject(from: data)
    let errors = validateRFGeometryV1Envelope(object)

    #expect(errors.isEmpty)
}

@Test
func geometryExportJSONFailsSchemaWhenMissingRequiredField() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportGeometryJSON(from: result)
    var object = try jsonObject(from: data)
    object.removeValue(forKey: "schemaVersion")

    let errors = validateRFGeometryV1Envelope(object)
    #expect(!errors.isEmpty)
    #expect(errors.contains { $0.contains("schemaVersion") })
}

@Test
func geometryExportJSONFailsSchemaWhenUnknownFieldExists() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportGeometryJSON(from: result)
    var object = try jsonObject(from: data)
    object["unexpectedField"] = true

    let errors = validateRFGeometryV1Envelope(object)
    #expect(!errors.isEmpty)
    #expect(errors.contains { $0.contains("unexpectedField") })
}

@Test
func geometryExportJSONFailsSchemaWhenBitsParityMismatch() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportGeometryJSON(from: result)
    var object = try jsonObject(from: data)

    guard var bits9 = object["bits9"] as? [String: Any] else {
        Issue.record("Expected bits9 object in exported JSON")
        return
    }
    bits9["bits"] = "111111111" // odd popcount
    bits9["parity"] = "even"
    object["bits9"] = bits9
    object["parity"] = "even"

    let errors = validateRFGeometryV1Envelope(object)
    #expect(!errors.isEmpty)
    #expect(errors.contains { $0.contains("parity mismatch") })
}

@Test
func geometryExportEnvelopeContainsSchemaVersion() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportGeometryJSON(from: result)
    let string = String(decoding: data, as: UTF8.self)
    #expect(string.contains(RFConstants.geometrySchemaVersion))
    #expect(string.contains("bits"))
}

@Test
func metadataManifestContainsPipelineAndProfile() throws {
    let service = DefaultExportService()
    let result = sampleSigilResult()

    let data = try service.exportMetadataManifest(
        from: result,
        format: .png,
        settings: ImageExportSettings.settings(for: .social),
        exportedAt: Date(timeIntervalSince1970: 0)
    )

    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"pipelineVersion\""))
    #expect(text.contains(RFConstants.pipelineVersion))
    #expect(text.contains("\"preset\""))
    #expect(text.contains("\"social\""))
}

private func sampleSigilResult() -> SigilResult {
    SigilResult(
        profileID: UUID(),
        vector: CanonicalVector(
            H_entropy: 0.5,
            K_complexity: 0.4,
            D_fractal_dim: 2.0,
            S_symmetry: 0.7,
            L_generator_length: 300
        ),
        bits9: SigilBits9(bits: "101010101", parity: .odd),
        celestialName: "Thal Rion Kael Void",
        lsystem: LSystemDefinition(
            axiom: "X",
            rules: ["F": "F[+F][-F]F", "X": "X"],
            angle: 30,
            iterations: 4
        ),
        geometry: SigilGeometry(lines: [
            SigilLine(startX: 0, startY: 0, endX: 1, endY: 1),
            SigilLine(startX: 1, startY: 1, endX: 0.5, endY: 1.4)
        ]),
        geometryHash: "hash-abc",
        pipelineVersion: RFConstants.pipelineVersion,
        engineDataVersion: RFConstants.engineDataVersion
    )
}

private func jsonObject(from data: Data) throws -> [String: Any] {
    let json = try JSONSerialization.jsonObject(with: data)
    guard let object = json as? [String: Any] else {
        throw NSError(domain: "RFExportTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected top-level object"])
    }
    return object
}

private func validateRFGeometryV1Envelope(_ root: [String: Any]) -> [String] {
    var errors: [String] = []

    let topKeys: Set<String> = [
        "schemaVersion", "engineDataVersion", "pipelineVersion", "vector",
        "bits9", "parity", "lsystem", "geometry"
    ]
    validateExactKeys(path: "$", object: root, expected: topKeys, errors: &errors)

    if let schemaVersion = root["schemaVersion"] as? String {
        if schemaVersion != RFConstants.geometrySchemaVersion {
            errors.append("$.schemaVersion must equal \(RFConstants.geometrySchemaVersion)")
        }
    } else {
        errors.append("$.schemaVersion must be a string")
    }

    validateNonEmptyString(path: "$.engineDataVersion", value: root["engineDataVersion"], errors: &errors)
    validateNonEmptyString(path: "$.pipelineVersion", value: root["pipelineVersion"], errors: &errors)

    if let vector = root["vector"] as? [String: Any] {
        let vectorKeys: Set<String> = ["H_entropy", "K_complexity", "D_fractal_dim", "S_symmetry", "L_generator_length"]
        validateExactKeys(path: "$.vector", object: vector, expected: vectorKeys, errors: &errors)

        validateNumber(path: "$.vector.H_entropy", value: vector["H_entropy"], range: 0...1, errors: &errors)
        validateNumber(path: "$.vector.K_complexity", value: vector["K_complexity"], range: 0...1, errors: &errors)
        validateNumber(path: "$.vector.D_fractal_dim", value: vector["D_fractal_dim"], range: 1...3, errors: &errors)
        validateNumber(path: "$.vector.S_symmetry", value: vector["S_symmetry"], range: 0...1, errors: &errors)
        validateInteger(path: "$.vector.L_generator_length", value: vector["L_generator_length"], range: 1...999, errors: &errors)
    } else {
        errors.append("$.vector must be an object")
    }

    var bitsString: String?
    var bitsParity: String?
    if let bits9 = root["bits9"] as? [String: Any] {
        validateExactKeys(path: "$.bits9", object: bits9, expected: ["bits", "parity"], errors: &errors)

        if let bits = bits9["bits"] as? String {
            bitsString = bits
            if bits.count != 9 || bits.contains(where: { $0 != "0" && $0 != "1" }) {
                errors.append("$.bits9.bits must be a 9-character binary string")
            }
        } else {
            errors.append("$.bits9.bits must be a string")
        }

        if let parity = bits9["parity"] as? String {
            bitsParity = parity
            if parity != "even" && parity != "odd" {
                errors.append("$.bits9.parity must be 'even' or 'odd'")
            }
        } else {
            errors.append("$.bits9.parity must be a string")
        }
    } else {
        errors.append("$.bits9 must be an object")
    }

    if let parity = root["parity"] as? String {
        if parity != "even" && parity != "odd" {
            errors.append("$.parity must be 'even' or 'odd'")
        }
        if let bitsParity, parity != bitsParity {
            errors.append("$.parity must match $.bits9.parity")
        }
    } else {
        errors.append("$.parity must be a string")
    }

    if let bitsString {
        let expectedParity = bitsString.filter { $0 == "1" }.count.isMultiple(of: 2) ? "even" : "odd"
        if let bitsParity, bitsParity != expectedParity {
            errors.append("bits9 parity mismatch with bits popcount")
        }
    }

    if let lsystem = root["lsystem"] as? [String: Any] {
        validateExactKeys(path: "$.lsystem", object: lsystem, expected: ["axiom", "rules", "angle", "iterations"], errors: &errors)
        validateNonEmptyString(path: "$.lsystem.axiom", value: lsystem["axiom"], errors: &errors)
        validateNumber(path: "$.lsystem.angle", value: lsystem["angle"], range: 0...360, errors: &errors)
        validateInteger(path: "$.lsystem.iterations", value: lsystem["iterations"], range: 1...64, errors: &errors)

        if let rules = lsystem["rules"] as? [String: Any] {
            if rules.isEmpty {
                errors.append("$.lsystem.rules must not be empty")
            }
            for (key, value) in rules {
                if key.isEmpty {
                    errors.append("$.lsystem.rules contains empty key")
                }
                if let ruleText = value as? String {
                    if ruleText.isEmpty {
                        errors.append("$.lsystem.rules[\(key)] must not be empty")
                    }
                } else {
                    errors.append("$.lsystem.rules[\(key)] must be a string")
                }
            }
        } else {
            errors.append("$.lsystem.rules must be an object")
        }
    } else {
        errors.append("$.lsystem must be an object")
    }

    if let geometry = root["geometry"] as? [String: Any] {
        validateExactKeys(path: "$.geometry", object: geometry, expected: ["lines"], errors: &errors)
        if let lines = geometry["lines"] as? [Any] {
            if lines.isEmpty {
                errors.append("$.geometry.lines must not be empty")
            }
            for (index, element) in lines.enumerated() {
                guard let line = element as? [String: Any] else {
                    errors.append("$.geometry.lines[\(index)] must be an object")
                    continue
                }
                validateExactKeys(
                    path: "$.geometry.lines[\(index)]",
                    object: line,
                    expected: ["startX", "startY", "endX", "endY"],
                    errors: &errors
                )
                validateFiniteNumber(path: "$.geometry.lines[\(index)].startX", value: line["startX"], errors: &errors)
                validateFiniteNumber(path: "$.geometry.lines[\(index)].startY", value: line["startY"], errors: &errors)
                validateFiniteNumber(path: "$.geometry.lines[\(index)].endX", value: line["endX"], errors: &errors)
                validateFiniteNumber(path: "$.geometry.lines[\(index)].endY", value: line["endY"], errors: &errors)
            }
        } else {
            errors.append("$.geometry.lines must be an array")
        }
    } else {
        errors.append("$.geometry must be an object")
    }

    return errors
}

private func validateExactKeys(
    path: String,
    object: [String: Any],
    expected: Set<String>,
    errors: inout [String]
) {
    let actual = Set(object.keys)
    for missing in expected.subtracting(actual).sorted() {
        errors.append("\(path) missing required key '\(missing)'")
    }
    for unexpected in actual.subtracting(expected).sorted() {
        errors.append("\(path) has unknown key '\(unexpected)'")
    }
}

private func validateNonEmptyString(path: String, value: Any?, errors: inout [String]) {
    guard let string = value as? String else {
        errors.append("\(path) must be a string")
        return
    }
    if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        errors.append("\(path) must not be empty")
    }
}

private func validateNumber(path: String, value: Any?, range: ClosedRange<Double>, errors: inout [String]) {
    guard let number = value as? NSNumber else {
        errors.append("\(path) must be a number")
        return
    }
    let scalar = number.doubleValue
    if !scalar.isFinite {
        errors.append("\(path) must be finite")
    } else if !range.contains(scalar) {
        errors.append("\(path) must be within \(range.lowerBound)...\(range.upperBound)")
    }
}

private func validateInteger(path: String, value: Any?, range: ClosedRange<Int>, errors: inout [String]) {
    guard let number = value as? NSNumber else {
        errors.append("\(path) must be an integer")
        return
    }
    let scalar = number.doubleValue
    let intValue = number.intValue
    if !scalar.isFinite || scalar.rounded() != scalar {
        errors.append("\(path) must be an integer")
        return
    }
    if !range.contains(intValue) {
        errors.append("\(path) must be within \(range.lowerBound)...\(range.upperBound)")
    }
}

private func validateFiniteNumber(path: String, value: Any?, errors: inout [String]) {
    guard let number = value as? NSNumber else {
        errors.append("\(path) must be a number")
        return
    }
    if !number.doubleValue.isFinite {
        errors.append("\(path) must be finite")
    }
}
