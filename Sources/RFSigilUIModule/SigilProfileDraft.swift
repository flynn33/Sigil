import Foundation
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilVisibleGlyph

// MARK: - Profile draft (UI-facing, distinct from the canonical input)
//
// Product policy `sigil-draft-vs-canonical.v1` (see docs/design/identity-input-treatment.md §7
// and docs/design/native-experience-export.md §3). A draft is *what the user has typed so far* —
// it may be incomplete, inconsistent, or contain placeholder values. A canonical
// `SigilProfileInput` is what the ASH pipeline consumes after domain-boundary validation
// has confirmed the required signals are present. Drafts and canonical inputs share
// neither state nor identity: promoting a draft produces a *new* canonical input.

public struct SigilProfileDraft: Equatable, Hashable, Sendable {
    /// Stable storage-scoped identifier. Defaults to a fresh UUID when the draft is
    /// first created; never changes for the lifetime of the draft.
    public var storageID: String
    public var firstName: String
    public var lastName: String
    public var birthDate: String        // `YYYY-MM-DD` (civil date, timezone-free)
    public var birthTime: String        // `HH:mm` (24-hour clock)
    public var birthCity: String
    public var birthOrder: String       // e.g. `"2 of 3"` or `"3/5"`
    public var eyes: String
    public var hair: String
    public var heritage: [String]
    public var ancestralSurnames: [String]
    /// `Side/ordinal/total` entries, one per parental side the user recorded.
    public var parentalOrder: [String]

    public init(
        storageID: String = UUID().uuidString,
        firstName: String = "",
        lastName: String = "",
        birthDate: String = "",
        birthTime: String = "",
        birthCity: String = "",
        birthOrder: String = "",
        eyes: String = "",
        hair: String = "",
        heritage: [String] = [],
        ancestralSurnames: [String] = [],
        parentalOrder: [String] = []
    ) {
        self.storageID = storageID
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthCity = birthCity
        self.birthOrder = birthOrder
        self.eyes = eyes
        self.hair = hair
        self.heritage = heritage
        self.ancestralSurnames = ancestralSurnames
        self.parentalOrder = parentalOrder
    }

    public var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Draft validation errors

public struct SigilDraftValidationError: Equatable, Sendable {
    public let field: String
    public let reason: String

    public init(field: String, reason: String) {
        self.field = field
        self.reason = reason
    }
}

/// Aggregated validation failure: carries *all* field errors at once so the
/// UI can display them under their respective form rows.
public struct SigilDraftValidationErrorBag: Error, Equatable, Sendable {
    public let errors: [SigilDraftValidationError]
    public init(errors: [SigilDraftValidationError]) { self.errors = errors }
}

/// A single failure in the journey pipeline (glyph or record).
/// `reason` is safe to surface to the user.
public struct SigilPipelineFailure: Error, Equatable, Sendable {
    public let reason: String
    public init(reason: String) { self.reason = reason }
}

// MARK: - Domain-boundary promotion
//
// Promotion is the only place a draft becomes a `SigilProfileInput`. Required
// fields: name (first or last), birthDate, birthCity. All other fields are
// optional and unknown is a legitimate state — the ASH pipeline will
// fail-closed on its own identity-core fields.

public enum SigilDraftPromoter {
    public static func promote(_ draft: SigilProfileDraft) -> Result<SigilProfileInput, SigilDraftValidationErrorBag> {
        var errors: [SigilDraftValidationError] = []
        if draft.fullName.isEmpty {
            errors.append(.init(field: "name", reason: "First or last name is required to derive a mortal name."))
        }
        let dateStr = draft.birthDate.trimmingCharacters(in: .whitespaces)
        if dateStr.isEmpty {
            errors.append(.init(field: "birthDate", reason: "Birth date is required."))
        } else if SigilCivilDate.parse(dateStr) == nil {
            errors.append(.init(field: "birthDate", reason: "Birth date must be a valid civil date in YYYY-MM-DD form."))
        }
        if draft.birthCity.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.init(field: "birthCity", reason: "Birth city (place name) is required; precision is recorded only."))
        }
        if !draft.birthOrder.trimmingCharacters(in: .whitespaces).isEmpty,
           SigilBirthOrder.parse(draft.birthOrder) == nil {
            errors.append(.init(field: "birthOrder", reason: "Birth order must be of the form '2 of 3' with ordinal ≤ total."))
        }
        if !errors.isEmpty {
            return .failure(SigilDraftValidationErrorBag(errors: errors))
        }
        let input = SigilProfileInput(
            id: draft.storageID,
            name: draft.fullName,
            birthDate: draft.birthDate,
            birthTime: draft.birthTime,
            birthCity: draft.birthCity,
            birthOrder: draft.birthOrder,
            eyes: draft.eyes,
            hair: draft.hair,
            heritage: draft.heritage,
            firstName: emptyToNil(draft.firstName),
            lastName: emptyToNil(draft.lastName),
            birthWeekday: weekdayName(from: draft.birthDate),
            parentalOrder: Self.parentalOrders(from: draft.parentalOrder),
            ancestralSurnames: draft.ancestralSurnames
        )
        return .success(input)
    }

    private static func emptyToNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private static func weekdayName(from civilDate: String) -> String? {
        guard let d = SigilCivilDate.parse(civilDate) else { return nil }
        let names = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return names[d.weekday]
    }

    private static func parentalOrders(from raw: [String]) -> [SigilParentalBirthOrder] {
        raw.compactMap { entry in
            let folded = entry.lowercased()
            let side: String
            let rest: String
            if let idx = folded.firstIndex(of: ":") {
                side = String(folded[..<idx]).trimmingCharacters(in: .whitespaces)
                rest = String(folded[folded.index(after: idx)...])
            } else if let idx = folded.firstIndex(of: " ") {
                side = String(folded[..<idx]).trimmingCharacters(in: .whitespaces)
                rest = String(folded[folded.index(after: idx)...])
            } else {
                return nil
            }
            guard side == "maternal" || side == "paternal" else { return nil }
            guard let o = SigilBirthOrder.parse(rest) else { return nil }
            return SigilParentalBirthOrder(side: side, ordinal: o.ordinal, total: o.total)
        }
    }
}

// MARK: - Generation journey state machine
//
// `SigilGenerationJourneyState` is the single source of truth for the journey.
// The `requestSequence` is an out-of-order completion guard: only an event
// whose sequence matches the state machine's expected sequence can change the
// terminal state. Events from older requests are dropped.

public enum SigilGenerationJourneyState: Equatable, Sendable {
    case idle
    case loading(requestSequence: UInt64)
    case success(requestSequence: UInt64, artifact: SigilVisibleGlyphArtifact, record: SigilPersonalCodex)
    case failure(requestSequence: UInt64, reason: String)
    case cancelled(requestSequence: UInt64)
}

public enum SigilGenerationEvent: Sendable {
    case start(UInt64)
    case succeeded(UInt64, SigilVisibleGlyphArtifact, SigilPersonalCodex)
    case failed(UInt64, String)
    case cancelled(UInt64)
}

public enum SigilGenerationJourney {
    /// Advances the journey based on an event. Out-of-order events are dropped.
    public static func advance(
        current: SigilGenerationJourneyState,
        with event: SigilGenerationEvent
    ) -> SigilGenerationJourneyState {
        switch (current, event) {
        case (.idle, .start(let seq)):
            return .loading(requestSequence: seq)
        case (.loading(let s), .start(let seq)) where seq > s:
            return .loading(requestSequence: seq)
        case (.loading(let s), .succeeded(let seq, let a, let c)) where seq == s:
            return .success(requestSequence: seq, artifact: a, record: c)
        case (.loading(let s), .failed(let seq, let reason)) where seq == s:
            return .failure(requestSequence: seq, reason: reason)
        case (.loading(let s), .cancelled(let seq)) where seq == s:
            return .cancelled(requestSequence: seq)
        default:
            return current
        }
    }
}

// MARK: - Generation journey view model
//
// Owns the state machine, an in-flight `Task`, and a monotonically increasing
// sequence. The pipeline runs off the main actor; the main actor only receives
// the final event, which is fed through the state machine (out-of-order safe).

@MainActor
public final class SigilGenerationJourneyViewModel: ObservableObject {
    @Published public private(set) var state: SigilGenerationJourneyState = .idle
    public let storageID: String

    public let glyphService: SigilVisibleGlyphService
    public let codexService: SigilPersonalCodexService
    /// Convenience alias so the experience view can access the glyph service
    /// without a separate reference.
    public var glyphServiceRef: SigilVisibleGlyphService { glyphService }
    private var inFlight: Task<Void, Never>?
    private var nextSequence: UInt64 = 1

    public init(
        storageID: String,
        glyphService: SigilVisibleGlyphService,
        codexService: SigilPersonalCodexService
    ) {
        self.storageID = storageID
        self.glyphService = glyphService
        self.codexService = codexService
    }

    public func generate(from draft: SigilProfileDraft) {
        switch SigilDraftPromoter.promote(draft) {
        case .failure(let bag):
            let seq = nextSequence
            nextSequence += 1
            state = .failure(
                requestSequence: seq,
                reason: "Validation: " + bag.errors.map { "\($0.field): \($0.reason)" }.joined(separator: "; ")
            )
            return
        case .success(let input):
            let seq = nextSequence
            nextSequence += 1
            state = .loading(requestSequence: seq)
            inFlight?.cancel()
            inFlight = Task { [glyphService, codexService] in
                let (artifactResult, codexResult) = await Self.runPipeline(
                    input: input,
                    glyphService: glyphService,
                    codexService: codexService
                )
                self.finish(seq: seq, artifact: artifactResult, record: codexResult)
            }
        }
    }

    private func finish(
        seq: UInt64,
        artifact: Result<SigilVisibleGlyphArtifact, SigilPipelineFailure>,
        record: Result<SigilPersonalCodex, SigilPipelineFailure>
    ) {
        guard case .loading(let currentSeq) = state, currentSeq == seq else { return }
        switch (artifact, record) {
        case (.success(let a), .success(let c)):
            state = .success(requestSequence: seq, artifact: a, record: c)
        case (.failure(let r), _):
            state = .failure(requestSequence: seq, reason: r.reason)
        case (_, .failure(let r)):
            state = .failure(requestSequence: seq, reason: r.reason)
        }
    }

    public func cancel() {
        guard case .loading(let seq) = state else { return }
        inFlight?.cancel()
        inFlight = nil
        state = .cancelled(requestSequence: seq)
    }

    public func reset() {
        inFlight?.cancel()
        inFlight = nil
        state = .idle
    }

    private static func runPipeline(
        input: SigilProfileInput,
        glyphService: SigilVisibleGlyphService,
        codexService: SigilPersonalCodexService
    ) async -> (Result<SigilVisibleGlyphArtifact, SigilPipelineFailure>, Result<SigilPersonalCodex, SigilPipelineFailure>) {
        do {
            let artifact = try await Task.detached(priority: .userInitiated) {
                try glyphService.generateArtifact(for: input)
            }.value
            let record = try await Task.detached(priority: .userInitiated) {
                try codexService.build(for: input)
            }.value
            return (.success(artifact), .success(record))
        } catch {
            let failure = SigilPipelineFailure(reason: Self.describe(error))
            return (.failure(failure), .failure(failure))
        }
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case let SigilVisibleGlyphError.identityUnavailable(fields):
            return "Required identity fields unavailable: \(fields.joined(separator: ", "))."
        case SigilVisibleGlyphError.branchTopologyUnavailable:
            return "The canonical branch topology is unavailable on this device; no glyph can be generated."
        case SigilVisibleGlyphError.qualityUnsatisfied:
            return "The glyph did not satisfy the quality gate."
        default:
            return "Generation failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Records store (CRUD over the real secure persistence service)
//
// An `actor` so concurrent mutations from the UI are serialized. The store is
// deliberately generic: it stores any `Codable` payload keyed by
// `(storageID, recordType)`.

public actor SigilRecordsStore {
    private let persistence: SigilSecurePersistenceService

    public init(persistence: SigilSecurePersistenceService) {
        self.persistence = persistence
    }

    public func upsert<Payload: Codable>(
        _ payload: Payload,
        storageID: String,
        recordType: SigilRecordType
    ) async -> Result<String, SigilRecordsStore.Failure> {
        do {
            let data = try JSONEncoder().encode(payload)
            let outcome = await persistence.save(data, id: SigilRecordIdentity(storageID: storageID, recordType: recordType))
            if outcome.success {
                return .success(storageID)
            }
            let category = outcome.failureCategory ?? .unknown
            return .failure(.init(category: category, message: "Save failed: \(category.rawValue)."))
        } catch {
            return .failure(.init(category: .writeFailed, message: "Save failed: \(error.localizedDescription)"))
        }
    }

    public func open<Payload: Codable>(
        storageID: String,
        recordType: SigilRecordType,
        as type: Payload.Type
    ) async -> Result<Payload, SigilRecordsStore.Failure> {
        do {
            let data = try await persistence.load(SigilRecordIdentity(storageID: storageID, recordType: recordType))
            do {
                return .success(try JSONDecoder().decode(Payload.self, from: data))
            } catch {
                return .failure(.init(category: .corruptRecord, message: "Record could not be decoded."))
            }
        } catch let error as SigilSecureStorageError {
            let category: SigilPersistenceFailureCategory
            switch error {
            case .keyUnavailable: category = .keyUnavailable
            case .notFound: category = .notFound
            case .corruptRecord: category = .corruptRecord
            case .decryptionFailed: category = .decryptionFailed
            case .envelopeVersionUnsupported: category = .unsupportedVersion
            case .ioError: category = .writeFailed
            }
            return .failure(.init(category: category, message: "Open failed: \(category.rawValue)."))
        } catch {
            return .failure(.init(category: .unknown, message: "Open failed: \(error.localizedDescription)"))
        }
    }

    public func delete(storageID: String, recordType: SigilRecordType) async -> Result<Void, SigilRecordsStore.Failure> {
        do {
            try await persistence.delete(SigilRecordIdentity(storageID: storageID, recordType: recordType))
            return .success(())
        } catch let error as SigilSecureStorageError {
            let category: SigilPersistenceFailureCategory
            switch error {
            case .notFound: category = .notFound
            case .keyUnavailable: category = .keyUnavailable
            case .ioError: category = .writeFailed
            default: category = .unknown
            }
            return .failure(.init(category: category, message: "Delete failed: \(category.rawValue)."))
        } catch {
            return .failure(.init(category: .unknown, message: "Delete failed: \(error.localizedDescription)"))
        }
    }

    public func list() async -> Result<[SigilRecordIdentity], SigilRecordsStore.Failure> {
        do {
            return .success(try await persistence.list())
        } catch {
            return .failure(.init(category: .unknown, message: "List failed: \(error.localizedDescription)"))
        }
    }

    public struct Failure: Error, Equatable, Sendable {
        public let category: SigilPersistenceFailureCategory
        public let message: String
        public init(category: SigilPersistenceFailureCategory, message: String) {
            self.category = category
            self.message = message
        }
    }
}
