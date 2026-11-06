import CryptoKit
import Foundation
import RFSigilCanon
import RFSigilCoreModels
import RFSigilDiagnostics
import RFSigilPrivacySecurity
import RFSigilVisibleGlyph

// MARK: - PersonalCodex service (deterministic, canon-backed, redacted)
//
// Builds the readable PersonalCodex record from a profile by running the real
// identity pipeline (authoritative hidden geometry) and the deterministic
// celestial naming, then composing the WRW / mythic-map interpretation with full
// source provenance. The record is deterministic (no clock, no randomness), so
// the same input always yields the same record and the same digest.
//
// Diagnostics are redacted by construction: only coarse, non-sensitive facts
// (record type, outcome, failure category, a derived plane/wolf category) are
// ever handed to the collector. The profile name, birth date, profile hash, and
// wolf score are never recorded. There is no personal-data embedding.

public struct SigilPersonalCodexService: Sendable {
    private let visibleGlyph: SigilVisibleGlyphService
    private let canon: SigilCanonResource
    private let persistence: SigilSecurePersistenceService?
    private let diagnostics: (any SigilDiagnosticCollector)?
    private let nameGenerator: SigilCelestialNameGenerator

    public init(
        visibleGlyph: SigilVisibleGlyphService,
        canon: SigilCanonResource,
        persistence: SigilSecurePersistenceService? = nil,
        diagnostics: (any SigilDiagnosticCollector)? = nil
    ) {
        self.visibleGlyph = visibleGlyph
        self.canon = canon
        self.persistence = persistence
        self.diagnostics = diagnostics
        self.nameGenerator = SigilCelestialNameGenerator(model: canon.celestialGenerator.model)
    }

    // MARK: Readiness (pure, I/O-free, dashboard-safe)

    /// Pure readiness for the dashboard. Performs no I/O.
    public var readiness: SigilPersonalCodexReadiness {
        let persistNote = persistence == nil
            ? "Persistence not configured; records are built and validated in memory."
            : "Records persist locally as AES-GCM ciphertext."
        return SigilPersonalCodexReadiness(
            status: .pass,
            summary: "The PersonalCodex derives a readable, canon-backed interpretation and a deterministic celestial name from the ASH identity.",
            detail: "Canonical and Flare remain separate; no personal-data embedding. \(persistNote) Local only."
        )
    }

    // MARK: Build

    /// Builds the PersonalCodex record for a profile. Throws when the pipeline
    /// cannot resolve an identity (an identity-core signal is unavailable) or
    /// when a required canon table is missing.
    public func build(for profile: SigilProfileInput) throws -> SigilPersonalCodex {
        let diagnostic = diagnostics
        let operationID = diagnostic?.beginOperation(
            name: "sigil.personal_codex.build",
            expected: "A readable, canon-backed PersonalCodex record is derived deterministically from the ASH identity.",
            correlationID: nil
        )

        // 1. Authoritative identity pipeline (real hidden geometry).
        let artifact: SigilVisibleGlyphArtifact
        do {
            artifact = try visibleGlyph.generateArtifact(for: profile)
        } catch let error as SigilVisibleGlyphError {
            recordBuildFailure(diagnostic: diagnostic, operationID: operationID, error: error)
            throw error
        }
        let hidden = artifact.hiddenGeometry
        let numerology = hidden.numerologyVector
        let lifePathRoot = numerology.lifePathRoot

        // 2. Deterministic celestial naming from the same normalized signals.
        let hairKey = SigilHairCategory.normalize(profile.hair).category.generatorKey
        let eyeKey = SigilEyeCategory.normalize(profile.eyes).category.generatorKey
        let weekdayName = Self.weekdayName(numerology.weekday)
        let nameInput = SigilCelestialNameInput(
            heritage: profile.heritage,
            birthDate: profile.birthDate,
            birthWeekday: weekdayName,
            birthTime: profile.birthTime,
            hairColor: hairKey,
            eyeColor: eyeKey,
            mortalName: profile.name
        )
        let nameResult = try nameGenerator.generate(input: nameInput)
        let syllableCount = Int(nameResult.debugMetadata["syllable_count"] ?? "0") ?? 0

        // 3. Plane attunement (pipeline vector + canon math type + WRW pressure).
        let celestialPlanes = canon.celestialGenerator.model.planes
        let planeVector = hidden.planeAttunementVector
        let planeEntries = celestialPlanes.map { plane -> SigilPersonalCodex.PlaneAttunementSection.PlaneEntry in
            let taxo = canon.ninePlane(id: plane.id)
            let weight = planeVector.indices.contains(plane.id - 1) ? planeVector[plane.id - 1] : 0
            return SigilPersonalCodex.PlaneAttunementSection.PlaneEntry(
                id: plane.id,
                code: plane.code,
                name: plane.name,
                mathType: taxo?.mathType ?? "unknown",
                role: taxo?.role ?? "",
                weight: weight,
                pressureState: Self.pressureState(weight: weight, dominant: plane.id == lifePathRoot)
            )
        }
        let dominantPlane = celestialPlanes.first { $0.id == lifePathRoot }
        let dominantPlaneCode = dominantPlane?.code ?? "P\(lifePathRoot)"
        let dominantPlaneName = dominantPlane?.name ?? ""
        let dominantPlaneText = canon.celestialGenerator.model.numerologyFragments.planes[dominantPlaneCode] ?? ""

        // 4. Canon-derived celestial class (distinct from the pipeline's temporary basis).
        let wolfCategory = nameResult.wolfCategory
        let classId = Self.celestialClassId(dominantPlaneId: lifePathRoot, wolfCategory: wolfCategory)
        let mythic = canon.mythicMap
        let classNarrative = [
            mythic.lucifer.modelRole,
            mythic.angels.redemptionPath,
            mythic.trials.redemption
        ].filter { !$0.isEmpty }.joined(separator: " ")

        // 5. Wolf balance under both rules, divergence made explicit.
        let pipelineWolf = hidden.wolfBalance
        let sourceRule = SigilPersonalCodex.WolfBalanceSection.RuleReading(
            category: wolfCategory,
            score: nameResult.wolfScore,
            rule: "source (celestial generator v1.0.0): white if score >= 1.0, dark if score <= -1.0, else balanced"
        )
        let pipelineRule = SigilPersonalCodex.WolfBalanceSection.RuleReading(
            category: pipelineWolf.category,
            score: Self.quantize(pipelineWolf.whiteWeight - pipelineWolf.darkWeight),
            rule: "pipeline (sig.wolf.band.v1): balanced when |white - dark| <= 0.12"
        )
        let divergent = wolfCategory != pipelineWolf.category

        // 6. Bloodline / heritage resonance (lineage pressure, not destiny).
        let bloodlineWeights = hidden.ancestryWeights.map {
            SigilPersonalCodex.BloodlineHeritageResonance.Weight(family: $0.family, weight: $0.weight)
        }
        let primaryWeight = bloodlineWeights.first?.weight ?? 0
        let bloodlineStatus: String
        if primaryWeight >= 0.66 { bloodlineStatus = "active" }
        else if primaryWeight >= 0.34 { bloodlineStatus = "suspected" }
        else { bloodlineStatus = "dormant" }

        // 7. Bounded symbolic trials / branch echoes (never fabricated history).
        let significance: String
        if divergent { significance = "meaningful" } else { significance = "minor" }

        // 8. Bounded symbolic gifts / burdens / thresholds.
        let dominantKeywords = dominantPlane?.keywords ?? []

        // 9. Sections (human-readable first).
        let mortal = SigilPersonalCodex.MortalIncarnation(
            name: profile.name,
            firstName: profile.firstName,
            lastName: profile.lastName,
            birthDate: profile.birthDate,
            birthTime: profile.birthTime,
            birthCity: profile.birthCity,
            birthOrder: profile.birthOrder,
            heritage: profile.heritage,
            ancestralSurnames: profile.ancestralSurnames,
            weekdayName: weekdayName,
            prose: "Mortal incarnation: \(profile.name), born \(profile.birthDate) at \(profile.birthTime) in \(profile.birthCity) (\(profile.birthOrder)). Heritage: \(profile.heritage.joined(separator: ", "))."
        )
        let numerologySection = SigilPersonalCodex.NumerologySection(
            lifePathRoot: numerology.lifePathRoot,
            preservedMasterNumbers: numerology.preservedMasterNumbers,
            birthDayRoot: numerology.birthDayRoot,
            expressionDestinyRoot: numerology.expressionDestinyRoot,
            soulUrgeRoot: numerology.soulUrgeRoot,
            personalityRoot: numerology.personalityRoot,
            birthOrderOrdinal: numerology.birthOrderOrdinal,
            birthOrderTotal: numerology.birthOrderTotal,
            weekday: numerology.weekday,
            prose: "Life path \(numerology.lifePathRoot); expression \(numerology.expressionDestinyRoot); soul urge \(numerology.soulUrgeRoot); personality \(numerology.personalityRoot); birth day \(numerology.birthDayRoot).\(numerology.preservedMasterNumbers.isEmpty ? "" : " Preserved master numbers: " + numerology.preservedMasterNumbers.map(String.init).joined(separator: ", ") + ".")"
        )
        let ashSection = SigilPersonalCodex.ASHIdentitySection(
            statePacked: hidden.ashState.statePacked,
            stateBits: hidden.ashState.stateBits,
            isCodeword: hidden.ashState.isCodeword,
            orbitSize: hidden.ashState.orbitSize,
            classification: hidden.ashState.classification,
            stability: hidden.ashState.stability,
            dominantPlaneId: hidden.ashState.dominantPlaneId,
            stateDigest: hidden.ashState.stateDigest,
            algorithmIdentity: hidden.ashState.algorithmIdentity,
            canonicalGeometryDigest: hidden.canonicalGeometryDigest,
            prose: "ASH state \(hidden.ashState.stateBits.map { $0 == 1 ? "1" : "0" }.joined()) (packed \(hidden.ashState.statePacked)), \(hidden.ashState.classification), orbit of \(hidden.ashState.orbitSize), dominant plane P\(hidden.ashState.dominantPlaneId). One-way link to the canonical geometry digest."
        )
        let planeSection = SigilPersonalCodex.PlaneAttunementSection(
            vector: planeVector,
            planes: planeEntries,
            dominantPlaneCode: dominantPlaneCode,
            dominantPlaneName: dominantPlaneName,
            dominantPlaneText: dominantPlaneText,
            prose: "Attunement is strongest at P\(lifePathRoot) (\(dominantPlaneName)), the life-path plane; the remaining planes carry a deterministic, state-linked spread."
        )
        let classOrigin = SigilPersonalCodex.CelestialClassOrigin(
            id: classId,
            basis: "canon-derived (dominant plane \(dominantPlaneCode) + wolf category \(wolfCategory) + heritage)",
            dominantPlaneCode: dominantPlaneCode,
            wolfCategory: wolfCategory,
            heritage: nameResult.heritageUsed,
            narrative: classNarrative,
            pipelineBasisId: hidden.celestialClassBasis.id,
            prose: "Celestial class \(classId): a canon-derived attribution over the real dominant plane and wolf category. The pipeline's temporary basis id (\(hidden.celestialClassBasis.id)) is retained for provenance."
        )
        let nameSection = SigilPersonalCodex.CelestialNameSection(
            celestialName: nameResult.celestialName,
            epithet: nameResult.epithet,
            dominantPlaneCode: nameResult.dominantPlaneCode,
            dominantPlaneName: nameResult.dominantPlaneName,
            dominantPlaneText: nameResult.dominantPlaneText,
            wolfCategory: nameResult.wolfCategory,
            wolfScore: nameResult.wolfScore,
            wolfText: nameResult.wolfText,
            weekdayText: nameResult.weekdayText,
            heritageUsed: nameResult.heritageUsed,
            numerologyText: nameResult.numerologyText,
            syllableCount: syllableCount,
            prose: "Celestial name \(nameResult.celestialName), \(nameResult.epithet). The name is derived deterministically from the profile's signals (heritage, date, time, hair, eyes, and the mortal name as seed); it is never looked up from a reference character."
        )
        let wolfSection = SigilPersonalCodex.WolfBalanceSection(
            sourceRule: sourceRule,
            pipelineRule: pipelineRule,
            divergent: divergent,
            dualAttractorNarrative: [mythic.balancePrinciple.description, mythic.balancePrinciple.modelInterpretation].filter { !$0.isEmpty }.joined(separator: " "),
            prose: "The white and dark wolves are complementary attractors, not moral poles. \(divergent ? "The source rule and the pipeline rule assign different categories for this profile; both are recorded and the divergence is explicit." : "The source rule and the pipeline rule agree on the wolf category for this profile.")"
        )
        let bloodline = SigilPersonalCodex.BloodlineHeritageResonance(
            ancestryWeights: bloodlineWeights,
            heritage: profile.heritage,
            status: bloodlineStatus,
            stability: "stable",
            isDestinyClaim: false,
            notADestinyClaimNote: "Bloodline resonance is lineage pressure with per-signal status, never a deterministic biological destiny claim (WRW guardrail: bloodline_as_static_class_lock is forbidden).",
            prose: "Heritage resonance: \(bloodlineWeights.map { "\($0.family) \($0.weight)" }.joined(separator: ", ")). Status: \(bloodlineStatus). This is symbolic lineage pressure, not a destiny claim."
        )
        let trials = SigilPersonalCodex.TrialsBranchEchoes(
            boundedSymbolic: true,
            isFabricatedLifeHistory: false,
            significance: significance,
            qualifiers: Self.branchQualifiers(wolfCategory: wolfCategory, dominantPlaneId: lifePathRoot, divergent: divergent),
            trialsContext: [mythic.trials.description, mythic.trials.failureCondition, mythic.trials.redemption].filter { !$0.isEmpty }.joined(separator: " "),
            prose: "Trials and branch echoes are BOUNDED symbolic interpretation from the WRW branching semantics and the mythic trials. A static profile carries no runtime branch history, so nothing here is a fabricated or simulated life event."
        )
        let gifts = SigilPersonalCodex.GiftsBurdensThresholds(
            symbolic: true,
            gifts: dominantKeywords,
            burdens: Self.burdenFrames(wolfCategory: wolfCategory, shadowPlaneRole: canon.ninePlane(id: 7)?.role ?? ""),
            thresholds: Self.thresholdFrames(wolfCategory: wolfCategory, dominantPlaneCode: dominantPlaneCode),
            prose: "Gifts, burdens, and thresholds are bounded symbolic framing from the dominant plane's keywords and the wolf category; they are not factual claims about the person."
        )
        let reading = SigilPersonalCodex.SigilReadingSection(
            complete: false,
            completionNote: "Explicitly incomplete: the canonical branch geometry is realized in Package 05. This section links one-way to the pipeline's canonical geometry digest; the glyph does not hash back to the PersonalCodex.",
            canonicalGeometryDigest: hidden.canonicalGeometryDigest,
            prose: "The Sigil Reading is intentionally incomplete pending Package 05 canonical geometry. It records a one-way provenance link to the canonical geometry digest only."
        )
        let provenance = SigilPersonalCodex.Provenance(
            manifestVersion: canon.manifestVersion,
            algorithmSpecificationSha256: canon.algorithmSpecificationSha256,
            sources: canon.sources.map {
                SigilPersonalCodex.Provenance.SourceRef(id: $0.id, version: $0.version, sha256: $0.sha256, role: $0.role, mode: $0.mode.rawValue)
            },
            provenanceDigest: canon.provenanceDigest,
            prose: "Provenance: \(canon.sources.count) canon sources, manifest \(canon.manifestVersion); the provenance digest is a stable, order-independent hash of the source registry, so a source-version change is visible."
        )

        // 10. Acyclic digest over every section except the digest itself.
        let payload = SigilPersonalCodex.DigestPayload(
            schemaVersion: SigilPersonalCodex.schemaVersion,
            algorithmIdentity: SigilPersonalCodex.algorithmIdentity,
            profileStorageID: profile.id,
            mortalIncarnation: mortal,
            numerologyProfile: numerologySection,
            ashIdentity: ashSection,
            planeAttunement: planeSection,
            celestialClassOrigin: classOrigin,
            celestialName: nameSection,
            wolfBalance: wolfSection,
            bloodlineHeritageResonance: bloodline,
            trialsBranchEchoes: trials,
            giftsBurdensThresholds: gifts,
            sigilReading: reading,
            provenance: provenance
        )
        let digest = try SigilPersonalCodexEncoding.digest(payload)

        let record = SigilPersonalCodex(
            schemaVersion: SigilPersonalCodex.schemaVersion,
            algorithmIdentity: SigilPersonalCodex.algorithmIdentity,
            profileStorageID: profile.id,
            mortalIncarnation: mortal,
            numerologyProfile: numerologySection,
            ashIdentity: ashSection,
            planeAttunement: planeSection,
            celestialClassOrigin: classOrigin,
            celestialName: nameSection,
            wolfBalance: wolfSection,
            bloodlineHeritageResonance: bloodline,
            trialsBranchEchoes: trials,
            giftsBurdensThresholds: gifts,
            sigilReading: reading,
            provenance: provenance,
            digest: digest
        )

        if let diagnostic, let operationID {
            diagnostic.finishOperation(
                id: operationID,
                outcome: .success,
                context: [
                    "recordType": .string(SigilRecordType.personalCodex.rawValue),
                    "dominantPlane": .string(dominantPlaneCode),
                    "wolfCategory": .string(wolfCategory)
                ],
                durationSeconds: nil
            )
            diagnostic.record(
                SigilDiagnosticEventInput(
                    source: "sigil.personal_codex",
                    severity: .info,
                    type: "sigil.personal_codex.build.success",
                    message: "PersonalCodex record derived deterministically from the ASH identity; profile values are not recorded.",
                    operationID: operationID,
                    context: [
                        "recordType": .string(SigilRecordType.personalCodex.rawValue),
                        "dominantPlane": .string(dominantPlaneCode),
                        "wolfCategory": .string(wolfCategory)
                    ]
                )
            )
        }
        return record
    }

    // MARK: Validation (record boundary)

    /// Validates a PersonalCodex record at its boundary: schema identity,
    /// required provenance, the incomplete Sigil Reading, and the acyclic
    /// digest (recomputed and compared).
    public func validate(_ record: SigilPersonalCodex) throws {
        guard record.schemaVersion == SigilPersonalCodex.schemaVersion else {
            throw SigilPersonalCodexError.invalidSchemaVersion(record.schemaVersion)
        }
        guard !record.provenance.sources.isEmpty, !record.provenance.provenanceDigest.isEmpty else {
            throw SigilPersonalCodexError.provenanceIncomplete
        }
        guard !record.ashIdentity.canonicalGeometryDigest.isEmpty else {
            throw SigilPersonalCodexError.missingSection("ashIdentity.canonicalGeometryDigest")
        }
        guard record.sigilReading.complete == false else {
            throw SigilPersonalCodexError.missingSection("sigilReading must remain incomplete until Package 05")
        }
        let recomputed = try SigilPersonalCodexEncoding.digest(record.digestPayload())
        guard recomputed == record.digest else {
            throw SigilPersonalCodexError.digestMismatch(recorded: record.digest, recomputed: recomputed)
        }
    }

    // MARK: Canonical data and storage

    /// Canonical (sorted-key) JSON for storage. Deterministic for a record.
    public func canonicalData(_ record: SigilPersonalCodex) throws -> Data {
        do {
            return try SigilPersonalCodexEncoding.canonicalJSON(record)
        } catch {
            throw SigilPersonalCodexError.canonicalEncodeFailed(String(describing: error))
        }
    }

    /// Storage identity: the PersonalCodex record type, keyed by the profile's
    /// storage id (never the profile's mathematical hash).
    public func storageIdentity(for profile: SigilProfileInput) -> SigilRecordIdentity {
        SigilRecordIdentity(storageID: profile.id, recordType: .personalCodex)
    }

    /// Encrypts and persists the record via the local-only store. A nil
    /// persistence service is a truthful failure, never a success.
    @discardableResult
    public func persist(_ record: SigilPersonalCodex, for profile: SigilProfileInput) async -> SigilSaveOutcome {
        guard let persistence else {
            return SigilSaveOutcome(success: false, recordCount: 0, failureCategory: .unknown)
        }
        let data = (try? canonicalData(record)) ?? Data()
        let identity = storageIdentity(for: profile)
        return await persistence.save(data, id: identity)
    }

    // MARK: Deterministic interpretation helpers

    private static func weekdayName(_ weekday: Int) -> String {
        let names = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        guard weekday >= 1 && weekday <= names.count else { return "" }
        return names[weekday - 1]
    }

    /// A WRW plane-attunement pressure state derived from the plane weight and
    /// whether it is the dominant plane (a dynamic resonance state, not a fixed
    /// class).
    private static func pressureState(weight: Double, dominant: Bool) -> String {
        if dominant { return "dominant" }
        if weight >= 0.12 { return "rising" }
        if weight >= 0.05 { return "latent" }
        return "dormant"
    }

    /// A canon-derived celestial class id over the real dominant plane and wolf
    /// category (distinct from, and refining, the pipeline's temporary basis id).
    private static func celestialClassId(dominantPlaneId: Int, wolfCategory: String) -> String {
        switch (dominantPlaneId, wolfCategory) {
        case (9, _): return "divine-origin"
        case (6, _): return "coherence-bearer"
        case (_, "dark_dominant"): return "root-walker"
        case (8, _): return "veil-crossing"
        case (_, "white_dominant"): return "light-bound"
        case (_, "balanced"): return "wolf-balanced"
        default: return "star-bound"
        }
    }

    /// Deterministic selection of WRW branch-echo qualifiers (no randomness).
    private static func branchQualifiers(wolfCategory: String, dominantPlaneId: Int, divergent: Bool) -> [String] {
        var qualifiers = ["wolf_resonance_shift"]
        if divergent { qualifiers.append("plane_attunement_threshold") }
        if wolfCategory == "dark_dominant" { qualifiers.append("shadow_void_celestial_threshold_event") }
        if dominantPlaneId == 8 { qualifiers.append("location_threshold_crossing") }
        if wolfCategory == "white_dominant" { qualifiers.append("truth_revealed_or_concealed") }
        return Array(qualifiers.prefix(3))
    }

    /// Deterministic burden framing from the wolf category and the shadow-plane role.
    private static func burdenFrames(wolfCategory: String, shadowPlaneRole: String) -> [String] {
        var frames: [String] = []
        if wolfCategory == "dark_dominant" { frames.append("shadow integration") }
        if wolfCategory == "balanced" { frames.append("holding balance") }
        if wolfCategory == "white_dominant" { frames.append("integrating the dim") }
        if !shadowPlaneRole.isEmpty { frames.append(shadowPlaneRole) }
        return frames.isEmpty ? ["unresolved"] : frames
    }

    /// Deterministic threshold framing from the wolf category and dominant plane.
    private static func thresholdFrames(wolfCategory: String, dominantPlaneCode: String) -> [String] {
        var frames = ["plane attunement threshold (\(dominantPlaneCode))"]
        if wolfCategory != "balanced" { frames.append("wolf resonance threshold") }
        return frames
    }

    private static func quantize(_ value: Double) -> Double {
        (value * 10_000).rounded() / 10_000
    }

    private func recordBuildFailure(diagnostic: (any SigilDiagnosticCollector)?, operationID: String?, error: SigilVisibleGlyphError) {
        guard let diagnostic else { return }
        let missing: [String]
        switch error {
        case let .identityUnavailable(fields): missing = fields
        default: missing = []
        }
        if let operationID {
            diagnostic.finishOperation(
                id: operationID,
                outcome: .blocked,
                context: [
                    "recordType": .string(SigilRecordType.personalCodex.rawValue),
                    "failureCategory": .string("identity_unavailable")
                ],
                durationSeconds: nil
            )
        }
        diagnostic.record(
            SigilDiagnosticEventInput(
                source: "sigil.personal_codex",
                severity: .warning,
                type: "sigil.personal_codex.build.identity_unavailable",
                message: "PersonalCodex build blocked: an identity-core signal is unavailable (field names only; no profile values recorded).",
                operationID: operationID,
                context: [
                    "recordType": .string(SigilRecordType.personalCodex.rawValue),
                    "missingFields": .array(missing.map { .string($0) })
                ]
            )
        )
    }
}

// MARK: - PersonalCodex readiness (pure, dashboard-safe)

/// Pure readiness description for the dashboard (mirrors the persistence
/// readiness shape). Performs no I/O.
public struct SigilPersonalCodexReadiness: Equatable, Sendable {
    public let status: RFSigilStatusKind
    public let summary: String
    public let detail: String

    public init(status: RFSigilStatusKind, summary: String, detail: String) {
        self.status = status
        self.summary = summary
        self.detail = detail
    }
}
