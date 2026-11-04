import Foundation

/// Redaction applied before diagnostic persistence and re-checked at the
/// export boundary.
///
/// The primary mechanism is an allowlisted typed context model plus a
/// key-based sensitive-field blocklist, so that structured fields are what
/// get captured. Nested JSON string payloads are decoded and redacted field
/// by field. A conservative, high-confidence value pattern pass is applied
/// as defense in depth; it is documented as not being a complete secret
/// detector, which is why context is allowlisted structured data in the
/// first place.
enum SigilDiagnosticRedactor {
    /// Key fragments that mark a structured context field as sensitive.
    /// Matching is case-insensitive substring matching on the key name;
    /// over-redaction is the safe direction.
    static let sensitiveKeyFragments: [String] = [
        "password",
        "passwd",
        "secret",
        "token",
        "api_key",
        "apikey",
        "access_key",
        "accesskey",
        "authorization",
        "authheader",
        "cookie",
        "credential",
        "private_key",
        "privatekey"
    ]

    struct RedactionResult {
        var value: SigilDiagnosticValue
        var redactionCount: Int
    }

    /// Redacts a single value, including nested structures and nested JSON
    /// string payloads. Returns the redacted value and the number of
    /// redactions applied.
    static func redact(_ value: SigilDiagnosticValue) -> RedactionResult {
        switch value {
        case .string(let raw):
            return redactString(raw)
        case .number(let number):
            guard number.isFinite else {
                return RedactionResult(value: .string("[non-finite-number]"), redactionCount: 0)
            }
            return RedactionResult(value: .number(number), redactionCount: 0)
        case .boolean:
            return RedactionResult(value: value, redactionCount: 0)
        case .array(let elements):
            var count = 0
            var redacted: [SigilDiagnosticValue] = []
            redacted.reserveCapacity(elements.count)
            for element in elements {
                let result = redact(element)
                redacted.append(result.value)
                count += result.redactionCount
            }
            return RedactionResult(value: .array(redacted), redactionCount: count)
        case .object(let fields):
            var count = 0
            var redacted: [String: SigilDiagnosticValue] = [:]
            redacted.reserveCapacity(fields.count)
            for (key, nested) in fields {
                if isSensitiveKey(key) {
                    redacted[key] = .string("[redacted]")
                    count += 1
                } else {
                    let result = redact(nested)
                    redacted[key] = result.value
                    count += result.redactionCount
                }
            }
            return RedactionResult(value: .object(redacted), redactionCount: count)
        }
    }

    /// Redacts an event context object.
    static func redactContext(_ context: [String: SigilDiagnosticValue]) -> RedactionResult {
        redact(.object(context))
    }

    /// Normalizes an error for retention: messages and locations are scrubbed
    /// with the value pattern pass; the underlying chain is preserved.
    static func redactError(
        _ error: SigilDiagnosticError
    ) -> (value: SigilDiagnosticError, redactionCount: Int) {
        var count = 0
        func scrub(_ text: String?) -> String? {
            guard let text else { return nil }
            let result = scrubText(text)
            count += result.redactionCount
            return result.text
        }
        var underlying: SigilDiagnosticError?
        if let nested = error.underlyingError {
            let result = redactError(nested)
            underlying = result.value
            count += result.redactionCount
        }
        let redacted = SigilDiagnosticError(
            domain: error.domain,
            code: error.code,
            message: scrub(error.message) ?? error.message,
            underlyingError: underlying,
            sourceLocation: scrub(error.sourceLocation)
        )
        return (redacted, count)
    }

    static func isSensitiveKey(_ key: String) -> Bool {
        let lowered = key.lowercased()
        return sensitiveKeyFragments.contains { lowered.contains($0) }
    }

    static func redactString(_ raw: String) -> RedactionResult {
        if let nested = nestedJSONValue(raw) {
            let result = redact(nested)
            let encoded = encodeValue(result.value) ?? "[redacted-nested]"
            return RedactionResult(value: .string(encoded), redactionCount: result.redactionCount)
        }
        let scrubbed = scrubText(raw)
        return RedactionResult(value: .string(scrubbed.text), redactionCount: scrubbed.redactionCount)
    }

    /// Decodes a string that is itself a JSON object or array so nested
    /// sensitive fields can be redacted field by field.
    private static func nestedJSONValue(_ raw: String) -> SigilDiagnosticValue? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return nil }
        guard let data = trimmed.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return value(fromJSON: parsed)
    }

    private static func value(fromJSON object: Any) -> SigilDiagnosticValue? {
        switch object {
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            // Distinguish Bool from Int/Double NSNumber boxes.
            if number === kCFBooleanTrue as NSNumber || number === kCFBooleanFalse as NSNumber {
                return .boolean(number.boolValue)
            }
            return .number(number.doubleValue)
        case let bool as Bool:
            return .boolean(bool)
        case let array as [Any]:
            var elements: [SigilDiagnosticValue] = []
            elements.reserveCapacity(array.count)
            for element in array {
                guard let value = value(fromJSON: element) else { return nil }
                elements.append(value)
            }
            return .array(elements)
        case let dict as [String: Any]:
            var fields: [String: SigilDiagnosticValue] = [:]
            for (key, nested) in dict {
                guard let value = value(fromJSON: nested) else { return nil }
                fields[key] = value
            }
            return .object(fields)
        default:
            return nil
        }
    }

    private static func encodeValue(_ value: SigilDiagnosticValue) -> String? {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    struct ScrubbedText {
        var text: String
        var redactionCount: Int
    }

    /// Conservative value pattern pass. Patterns are limited to
    /// high-confidence secret forms; this is defense in depth, not a
    /// guarantee that no secret can leak, which is why context capture is
    /// allowlisted structured data.
    static func scrubText(_ raw: String) -> ScrubbedText {
        var text = raw
        var count = 0
        // Count matches against the original text, then replace.
        func replaceCounted(
            _ pattern: String,
            _ replacement: String,
            options: NSRegularExpression.Options = []
        ) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            guard !matches.isEmpty else { return }
            text = regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: range,
                withTemplate: replacement
            )
            count += matches.count
        }
        replaceCounted("Bearer\\s+[A-Za-z0-9._~+/=-]{8,}", "Bearer [redacted]")
        replaceCounted("Basic\\s+[A-Za-z0-9+/=]{8,}", "Basic [redacted]")
        replaceCounted(
            "-----BEGIN[ A-Z]*PRIVATE KEY-----.*?-----END[ A-Z]*PRIVATE KEY-----",
            "[redacted-private-key]",
            options: [.dotMatchesLineSeparators]
        )
        replaceCounted("\\bgh[pousr]_[A-Za-z0-9]{20,}\\b", "[redacted-github-token]")
        replaceCounted("\\beyJ[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9._-]{8,}", "[redacted-jwt]")
        return ScrubbedText(text: text, redactionCount: count)
    }
}
