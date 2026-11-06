import Foundation

// MARK: - ASH branch topology (typed, validated, fail-closed)
//
// The canonical semantic branch tree (a full ternary tree of depth 0..4: 121
// nodes, 81 leaves) that the visible glyph projects. Each node carries its own
// 9-bit ASH codeword state, the 4-bit message (the codeword index), the 2D
// segment endpoints, heading, length, and weight. The 16 distinct node states
// are the 16 codewords of a [9,4,4] code in the ASH-Model *reference*
// convention; the message is the index of that codeword.
//
// This is source data, not product interpretation: the loader re-hashes the
// shipped file against the manifest and structurally validates the tree. No
// field is substituted with a fabricated value.

/// One 2D coordinate pair (x, y) in the branch tree's native plane.
/// Decoded from the resource's `[x, y]` array form.
public struct SigilBranchPoint: Codable, Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let pair = try container.decode([Double].self)
        guard pair.count == 2 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "expected [x, y]")
        }
        self.x = pair[0]
        self.y = pair[1]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([x, y])
    }
}

/// One node of the branch topology (a single segment with its ASH identity).
public struct SigilBranchNode: Codable, Equatable, Hashable, Sendable {
    /// Structural action label: "root" for the origin, or "0"/"+"/"-" for a branch step.
    public let action: String
    /// The 9-bit codeword state (string), reference convention.
    public let codeword: String
    /// Tree depth, 0..4.
    public let depth: Int
    public let end: SigilBranchPoint
    public let headingRadians: Double
    /// The 4-bit message: the index of this node's codeword among the 16 codewords.
    public let message: String
    /// Parent node path (nil for the root).
    public let parentPath: String?
    /// The path label from the root to this node ("" for the root).
    public let path: String
    public let segmentLength: Double
    public let start: SigilBranchPoint
    /// The 9-bit state string (== codeword for every node).
    public let state: String
    public let weight: Double

    public init(
        action: String,
        codeword: String,
        depth: Int,
        end: SigilBranchPoint,
        headingRadians: Double,
        message: String,
        parentPath: String?,
        path: String,
        segmentLength: Double,
        start: SigilBranchPoint,
        state: String,
        weight: Double
    ) {
        self.action = action
        self.codeword = codeword
        self.depth = depth
        self.end = end
        self.headingRadians = headingRadians
        self.message = message
        self.parentPath = parentPath
        self.path = path
        self.segmentLength = segmentLength
        self.start = start
        self.state = state
        self.weight = weight
    }
}

/// The decoded, structurally validated branch topology.
public struct SigilBranchTopology: Equatable, Sendable {
    public let schemaVersion: String
    public let sourceState: String
    public let nodeCount: Int
    public let leafCount: Int
    public let nodes: [SigilBranchNode]
    /// SHA-256 of the shipped resource file (integrity).
    public let resourceSha256: String
    /// SHA-256 of the pinned ASH-Model source archive (provenance identity).
    public let sourceArchiveSha256: String

    public init(
        schemaVersion: String,
        sourceState: String,
        nodeCount: Int,
        leafCount: Int,
        nodes: [SigilBranchNode],
        resourceSha256: String,
        sourceArchiveSha256: String
    ) {
        self.schemaVersion = schemaVersion
        self.sourceState = sourceState
        self.nodeCount = nodeCount
        self.leafCount = leafCount
        self.nodes = nodes
        self.resourceSha256 = resourceSha256
        self.sourceArchiveSha256 = sourceArchiveSha256
        self.nodeIndex = Dictionary(uniqueKeysWithValues: nodes.map { ($0.path, $0) })
    }

    /// Index nodes by their path label for O(1) parent/ancestor lookups.
    public func nodeByPath(_ path: String) -> SigilBranchNode? {
        nodeIndex[path]
    }

    /// Deterministically ordered depth-4 leaves for a given 4-bit message.
    public func leaves(forMessage message: String) -> [SigilBranchNode] {
        nodes
            .filter { $0.message == message && $0.depth == 4 }
            .sorted { $0.path < $1.path }
    }

    /// The 16 distinct 4-bit messages present, ascending.
    public var messages: [String] {
        Array(Set(nodes.map(\.message))).sorted()
    }

    private let nodeIndex: [String: SigilBranchNode]
}

// MARK: - Branch topology manifest (product-owned provenance)
//
// A local source record (this module does not depend on RFSigilCanon, and no
// new target dependency is introduced for Package 05). Mirrors the canon
// source shape for provenance: id, display name, SHA-256, version, mode, role,
// and resource path.

public enum SigilBranchSourceMode: String, Codable, Equatable, Hashable, Sendable {
    case resourceRaw = "resource-raw"
    case typedEmbedded = "typed-embedded"
}

public struct SigilBranchSource: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let sha256: String
    public let version: String
    public let mode: SigilBranchSourceMode
    public let resourcePath: String?
    public let role: String

    public init(id: String, displayName: String, sha256: String, version: String, mode: SigilBranchSourceMode, resourcePath: String? = nil, role: String) {
        self.id = id
        self.displayName = displayName
        self.sha256 = sha256
        self.version = version
        self.mode = mode
        self.resourcePath = resourcePath
        self.role = role
    }
}

public struct SigilBranchManifest: Codable, Equatable, Hashable, Sendable {
    public let manifest: String
    public let version: String
    public let note: String
    public let sourceArchiveSha256: String
    public let sources: [SigilBranchSource]

    public init(manifest: String, version: String, note: String, sourceArchiveSha256: String, sources: [SigilBranchSource]) {
        self.manifest = manifest
        self.version = version
        self.note = note
        self.sourceArchiveSha256 = sourceArchiveSha256
        self.sources = sources
    }

    public func source(id: String) -> SigilBranchSource? {
        sources.first { $0.id == id }
    }
}

// MARK: - Fail-closed branch topology errors

public enum SigilBranchTopologyError: Error, Equatable, Sendable {
    case manifestMissing
    case manifestMalformed(String)
    case resourceMissing
    case resourceHashMismatch
    case decodeFailed(String)
    case invalidTopology(String)
}
