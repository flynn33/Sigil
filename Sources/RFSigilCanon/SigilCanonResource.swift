import CryptoKit
import Foundation

// MARK: - Canon manifest and aggregate resource
//
// `SigilCanonManifest` is decoded from the shipped canon-manifest resource and is
// the single source of truth for canon provenance (one entry per upstream source:
// SHA-256, version, shipping mode, role). `SigilCanonResource` is the assembled,
// validated aggregate the PersonalCodex consumes: the decoded celestial generator
// and mythic map (re-hashed against the manifest), the typed nine-plane taxonomy,
// and the source registry.

/// The shipping mode of a canon source.
public enum SigilCanonSourceMode: String, Codable, Equatable, Hashable, Sendable {
    /// Shipped as a resource file and re-hashed at load.
    case resourceRaw = "resource-raw"
    /// Encoded as typed product models; upstream file identity recorded for provenance.
    case typedEmbedded = "typed-embedded"
}

/// One upstream canon source with its identity and role.
public struct SigilCanonSource: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let sha256: String
    public let version: String
    public let mode: SigilCanonSourceMode
    public let role: String
    public let resourcePath: String?

    public init(id: String, displayName: String, sha256: String, version: String, mode: SigilCanonSourceMode, role: String, resourcePath: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.sha256 = sha256
        self.version = version
        self.mode = mode
        self.role = role
        self.resourcePath = resourcePath
    }
}

/// The shipped canon manifest (product-owned provenance).
public struct SigilCanonManifest: Codable, Equatable, Hashable, Sendable {
    public let manifest: String
    public let version: String
    public let note: String
    public let sources: [SigilCanonSource]

    public init(manifest: String, version: String, note: String, sources: [SigilCanonSource]) {
        self.manifest = manifest
        self.version = version
        self.note = note
        self.sources = sources
    }
}

/// The assembled, validated canon resource.
public struct SigilCanonResource: Equatable, Sendable {
    public let celestialGenerator: SigilCelestialGenerator
    public let mythicMap: SigilMythicMap
    public let ninePlanes: [SigilNinePlane]
    public let sources: [SigilCanonSource]
    public let manifestVersion: String
    /// The SHA-256 of the celestial-name-generator algorithm specification
    /// (provenance for the deterministic-selection rule).
    public let algorithmSpecificationSha256: String

    public init(
        celestialGenerator: SigilCelestialGenerator,
        mythicMap: SigilMythicMap,
        ninePlanes: [SigilNinePlane],
        sources: [SigilCanonSource],
        manifestVersion: String,
        algorithmSpecificationSha256: String
    ) {
        self.celestialGenerator = celestialGenerator
        self.mythicMap = mythicMap
        self.ninePlanes = ninePlanes
        self.sources = sources
        self.manifestVersion = manifestVersion
        self.algorithmSpecificationSha256 = algorithmSpecificationSha256
    }

    public func source(id: String) -> SigilCanonSource? {
        sources.first { $0.id == id }
    }

    public func ninePlane(id: Int) -> SigilNinePlane? {
        ninePlanes.first { $0.id == id }
    }

    public func ninePlane(code: String) -> SigilNinePlane? {
        ninePlanes.first { $0.code == code }
    }

    /// A stable, order-independent provenance digest over the source registry
    /// (ids + versions + SHAs). A source-version change is therefore visible.
    public var provenanceDigest: String {
        let items = sources
            .sorted { $0.id < $1.id }
            .map { "\($0.id)=\($0.version):\($0.sha256)" }
        return SigilCanonHash.sha256Hex(Data(items.joined(separator: "|").utf8))
    }
}

// MARK: - Fail-closed canon errors

public enum SigilCanonError: Error, Equatable, Sendable {
    case resourceMissing(String)
    case manifestMissing
    case manifestMalformed(String)
    case resourceHashMismatch(sourceID: String)
    case decodeFailed(sourceID: String, detail: String)
    case invalidTable(sourceID: String, table: String, reason: String)
}

// MARK: - Hashing (canonical, used for the provenance digest and loader checks)

public enum SigilCanonHash {
    public static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
