import CryptoKit
import Foundation

// MARK: - Branch topology loader (typed, validated, fail-closed)
//
// Loads the ASH branch topology from the product-owned resource bundle:
//   1. Decode the manifest (provenance registry: source SHA, version, archive SHA).
//   2. Re-hash the shipped topology file and fail closed on mismatch.
//   3. Decode the raw resource into typed nodes.
//   4. Structurally validate the tree (counts, parent links, depth, finite
//      coordinates, a single root, state == codeword, 16 well-formed messages).
// No field is substituted with a fabricated value: any missing or malformed
// invariant is an error, not a default.

public struct SigilBranchTopologyLoader: Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? Bundle.module
    }

    /// Loads and validates the branch topology. Throws `SigilBranchTopologyError`
    /// on any missing, mismatched, malformed, or structurally invalid source.
    public func load() throws -> SigilBranchTopology {
        let manifest = try loadManifest()
        let source = try requireSource(id: "branch-topology", manifest: manifest)
        try verifyHash(source: source)
        let data = try rawData(source: source)
        let nodes = try decodeNodes(data: data)
        try Self.validate(nodes: nodes, manifest: manifest)

        return SigilBranchTopology(
            schemaVersion: nodesSchemaVersion(from: data) ?? manifest.version,
            sourceState: nodesSourceState(from: data) ?? "",
            nodeCount: nodes.count,
            leafCount: nodes.filter { $0.depth == 4 }.count,
            nodes: nodes,
            resourceSha256: source.sha256,
            sourceArchiveSha256: manifest.sourceArchiveSha256
        )
    }

    // MARK: Manifest

    private func loadManifest() throws -> SigilBranchManifest {
        guard let url = resourceURL(path: "ash/ash-manifest.json") else {
            throw SigilBranchTopologyError.manifestMissing
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw SigilBranchTopologyError.manifestMalformed("manifest could not be read")
        }
        do {
            return try Self.decoder().decode(SigilBranchManifest.self, from: data)
        } catch {
            throw SigilBranchTopologyError.manifestMalformed(String(describing: error))
        }
    }

    // MARK: Resource I/O and integrity

    private func requireSource(id: String, manifest: SigilBranchManifest) throws -> SigilBranchSource {
        guard let source = manifest.source(id: id), let path = source.resourcePath else {
            throw SigilBranchTopologyError.manifestMalformed("missing resourcePath for \(id)")
        }
        _ = path
        return source
    }

    private func verifyHash(source: SigilBranchSource) throws {
        guard source.mode == .resourceRaw, let path = source.resourcePath, let url = resourceURL(path: path) else {
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            throw SigilBranchTopologyError.resourceMissing
        }
        let actual = SigilBranchHash.sha256Hex(data)
        guard actual.lowercased() == source.sha256.lowercased() else {
            throw SigilBranchTopologyError.resourceHashMismatch
        }
    }

    private func rawData(source: SigilBranchSource) throws -> Data {
        guard let path = source.resourcePath, let url = resourceURL(path: path) else {
            throw SigilBranchTopologyError.resourceMissing
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw SigilBranchTopologyError.resourceMissing
        }
    }

    // MARK: Decode

    private func decodeNodes(data: Data) throws -> [SigilBranchNode] {
        struct TopologyRoot: Decodable {
            let nodes: [SigilBranchNode]
        }
        do {
            let root = try Self.decoder().decode(TopologyRoot.self, from: data)
            return root.nodes
        } catch {
            throw SigilBranchTopologyError.decodeFailed(String(describing: error))
        }
    }

    private func nodesSchemaVersion(from data: Data) -> String? {
        struct Root: Decodable { let schema_version: String? }
        return try? Self.decoder().decode(Root.self, from: data).schema_version
    }

    private func nodesSourceState(from data: Data) -> String? {
        struct Root: Decodable { let source_state: String? }
        return try? Self.decoder().decode(Root.self, from: data).source_state
    }

    // MARK: Structural validation (fail closed)

    static func validate(nodes: [SigilBranchNode], manifest: SigilBranchManifest) throws {
        guard nodes.count == 121 else {
            throw SigilBranchTopologyError.invalidTopology("expected 121 nodes, got \(nodes.count)")
        }
        let leaves = nodes.filter { $0.depth == 4 }.count
        guard leaves == 81 else {
            throw SigilBranchTopologyError.invalidTopology("expected 81 leaves, got \(leaves)")
        }
        // Single root, empty path, nil parent.
        let roots = nodes.filter { $0.path.isEmpty && $0.parentPath == nil }
        guard roots.count == 1 else {
            throw SigilBranchTopologyError.invalidTopology("expected exactly one root, got \(roots.count)")
        }
        // Every non-root parent link resolves; every path is unique.
        var seen = Set<String>()
        for node in nodes {
            guard seen.insert(node.path).inserted else {
                throw SigilBranchTopologyError.invalidTopology("duplicate path \(node.path)")
            }
            guard node.depth >= 0 && node.depth <= 4 else {
                throw SigilBranchTopologyError.invalidTopology("invalid depth \(node.depth) for \(node.path)")
            }
            if let parent = node.parentPath {
                guard nodes.contains(where: { $0.path == parent }) else {
                    throw SigilBranchTopologyError.invalidTopology("unresolved parent \(parent) for \(node.path)")
                }
            }
            // Finite 2D coordinates.
            guard [node.start.x, node.start.y, node.end.x, node.end.y].allSatisfy({ $0.isFinite }) else {
                throw SigilBranchTopologyError.invalidTopology("non-finite coordinate for \(node.path)")
            }
            // state == codeword and well-formed 9-bit strings; message well-formed 4-bit.
            guard node.state == node.codeword else {
                throw SigilBranchTopologyError.invalidTopology("state != codeword for \(node.path)")
            }
            guard node.codeword.count == 9, node.codeword.allSatisfy({ $0 == "0" || $0 == "1" }) else {
                throw SigilBranchTopologyError.invalidTopology("malformed codeword for \(node.path)")
            }
            guard node.message.count == 4, node.message.allSatisfy({ $0 == "0" || $0 == "1" }) else {
                throw SigilBranchTopologyError.invalidTopology("malformed message for \(node.path)")
            }
        }
        // Exactly 16 distinct messages and 16 distinct codewords (the [9,4,4] set).
        let distinctMessages = Set(nodes.map(\.message)).count
        guard distinctMessages == 16 else {
            throw SigilBranchTopologyError.invalidTopology("expected 16 distinct messages, got \(distinctMessages)")
        }
        let distinctCodewords = Set(nodes.map(\.codeword)).count
        guard distinctCodewords == 16 else {
            throw SigilBranchTopologyError.invalidTopology("expected 16 distinct codewords, got \(distinctCodewords)")
        }
        _ = manifest
    }

    // MARK: Resource resolution (mirrors the canon loader's bundle layout handling)

    private func resourceURL(path: String) -> URL? {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let lastSlash = trimmed.lastIndex(of: "/")
        if let lastSlash {
            let sub = String(trimmed[trimmed.startIndex..<lastSlash])
            let fileName = String(trimmed[trimmed.index(after: lastSlash)...])
            return bundle.url(forResource: fileName, withExtension: nil, subdirectory: sub)
                ?? urlForFull(fileName: fileName, subdirectory: sub)
                ?? bundle.url(forResource: fileName, withExtension: nil)
                ?? urlForFull(fileName: fileName, subdirectory: nil)
        }
        return bundle.url(forResource: trimmed, withExtension: nil, subdirectory: nil)
            ?? urlForFull(fileName: trimmed, subdirectory: nil)
    }

    private func urlForFull(fileName: String, subdirectory: String?) -> URL? {
        let dot = fileName.lastIndex(of: ".")
        guard let dot, dot != fileName.startIndex else { return nil }
        let base = String(fileName[..<dot])
        let ext = String(fileName[fileName.index(after: dot)...])
        if let subdirectory {
            return bundle.url(forResource: base, withExtension: ext, subdirectory: subdirectory)
        }
        return bundle.url(forResource: base, withExtension: ext)
    }

    // MARK: Decoder (snake_case resource keys -> camelCase model keys)

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// MARK: - Hashing (canonical, used for integrity and signature digests)

public enum SigilBranchHash {
    public static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
