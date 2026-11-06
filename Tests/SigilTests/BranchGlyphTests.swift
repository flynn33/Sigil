import Foundation
import RFSigilCoreModels
import RFSigilVisibleGlyph
import XCTest

// MARK: - Package 05 (ASH-derived canonical glyph) source-backed tests
//
// These pin the Package 05 correctness properties that the visible glyph now
// derives from the canonical ASH branch topology (F-07) instead of digest bytes:
// the reference->APS message seam, deterministic branch projection, the real
// geometric crossing verification (F-11), the geometry-only collision signature,
// and the fail-closed integrity of the topology resource.

final class BranchGlyphTests: XCTestCase {
    private func topology() throws -> SigilBranchTopology {
        try SigilBranchTopologyLoader().load()
    }

    // MARK: Message seam (reference codeword -> APS-native codeword)

    /// The branch message seam is a well-defined 16<->16 bijection between the
    /// product's APS-native codeword set and the topology's 16 messages, and the
    /// derived APS words are exactly the product's [9,4,4] codewords (bit b8 == 0,
    /// minimum distance 4). This is the single most important correctness check.
    func testSeamIsA16To16BijectionOntoTheAPSCodewords() throws {
        let topology = try topology()
        let map = SigilVisibleGlyphService.apsToMessageMap(topology)

        // Sixteen distinct messages, sixteen distinct APS codewords.
        XCTAssertEqual(topology.messages.count, 16)
        XCTAssertEqual(map.count, 16, "the seam must produce 16 distinct APS codewords (no collision)")

        // Surjective onto the topology's messages: every message is reachable.
        XCTAssertEqual(Set(map.values), Set(topology.messages))

        // The derived APS words are valid APS codewords: nine-bit, b8 == 0.
        XCTAssertTrue(map.keys.allSatisfy { $0 < 0x200 && ($0 & 0x100) == 0 },
                      "every derived APS word must be nine-bit with b8 == 0")

        // And they form a [9,4,4] code: minimum Hamming distance is 4.
        let words = Array(map.keys)
        var minDistance = Int.max
        for i in words.indices {
            for j in (i + 1)..<words.count {
                minDistance = min(minDistance, hamming(words[i], words[j]))
            }
        }
        XCTAssertEqual(minDistance, 4, "the derived APS set must be a [9,4,4] code (dmin 4)")
    }

    // MARK: Deterministic, message-driven branch projection

    /// Different decoded ASH messages drive different branch geometry, and the
    /// projection is deterministic. The golden profiles decode to four distinct
    /// messages and therefore four distinct geometries.
    func testBranchGeometryIsDeterministicAndMessageDriven() throws {
        let service = SigilVisibleGlyphService()
        let profiles: [SigilProfileInput] = [
            SigilProfileInput(id: "g0", name: "Eira Voss", birthDate: "1991-02-11", birthTime: "03:42", birthCity: "Uppsala", birthOrder: "2 of 3", eyes: "gray", hair: "dark_blonde", heritage: ["Swedish", "German"]),
            SigilProfileInput(id: "g1", name: "Maeve Kellan", birthDate: "1988-10-30", birthTime: "21:08", birthCity: "Cork", birthOrder: "1 of 2", eyes: "green", hair: "black", heritage: ["Irish", "English"]),
            SigilProfileInput(id: "g2", name: "Nadia Kovalenko", birthDate: "2000-07-07", birthTime: "11:19", birthCity: "Krakow", birthOrder: "7 of 9", eyes: "hazel", hair: "brown", heritage: ["Polish", "Ukrainian"]),
            SigilProfileInput(id: "g3", name: "Julian Hart", birthDate: "1977-11-04", birthTime: "17:55", birthCity: "York", birthOrder: "3 of 5", eyes: "blue", hair: "red", heritage: ["English", "German"])
        ]

        let artifacts = try profiles.map { try service.generateArtifact(for: $0) }
        let signatures = artifacts.map { $0.visibleSigil.styleMetadata.geometryCollisionSignature }

        // Four distinct decoded messages -> four distinct branch geometries.
        XCTAssertEqual(Set(signatures).count, 4, "the golden profiles decode to distinct messages and must render distinct geometries")

        // Determinism: regenerating the same profile yields the identical geometry.
        let again = try service.generateArtifact(for: profiles[0])
        XCTAssertEqual(again.visibleSigil.vectorPaths, artifacts[0].visibleSigil.vectorPaths)
        XCTAssertEqual(again.visibleSigil.styleMetadata.geometryCollisionSignature, signatures[0])

        // Every projected geometry stays inside the presentation budget.
        for artifact in artifacts {
            XCTAssertTrue((10...14).contains(artifact.visibleSigil.vectorPaths.count))
        }
    }

    // MARK: Real geometric crossing verification (recomputed, not caller-provided)

    func testRealCrossingCountCountsOnlyProperInteriorIntersections() throws {
        func seg(_ a: (Double, Double), _ b: (Double, Double)) -> VisibleVectorPath {
            VisibleVectorPath(
                id: "t.\(a.0).\(a.1).\(b.0).\(b.1)",
                primitive: .dominantSpine,
                pathData: "M \(a.0) \(a.1) L \(b.0) \(b.1)",
                strokeRole: "test",
                semanticSource: "test"
            )
        }

        // Two diagonals that cross once in the interior.
        XCTAssertEqual(
            SigilVisibleGlyphService.realCrossingCount(from: [seg((0, 0), (10, 10)), seg((0, 10), (10, 0))]),
            1, "two crossing diagonals yield exactly one proper crossing"
        )

        // Two parallel segments: no crossing.
        XCTAssertEqual(
            SigilVisibleGlyphService.realCrossingCount(from: [seg((0, 0), (10, 0)), seg((0, 5), (10, 5))]),
            0, "parallel segments do not cross"
        )

        // Two segments sharing an endpoint meet at a joint, not a crossing.
        XCTAssertEqual(
            SigilVisibleGlyphService.realCrossingCount(from: [seg((0, 0), (5, 5)), seg((5, 5), (10, 0))]),
            0, "segments meeting at a shared endpoint are not a proper crossing"
        )

        // One horizontal crossed by two verticals: exactly two proper crossings
        // (the two verticals are parallel to each other).
        XCTAssertEqual(
            SigilVisibleGlyphService.realCrossingCount(from: [
                seg((0, 5), (10, 5)), seg((5, 0), (5, 10)), seg((2, 0), (2, 10))
            ]),
            2, "one horizontal crossed by two parallel verticals yields two crossings"
        )
    }

    // MARK: Geometry-only collision signature

    /// The collision signature depends only on the rendered geometry (order of the
    /// path list is irrelevant) and distinguishes different geometries. Two
    /// different profiles that decode to the same branch message share it while
    /// having different profile digests -- the signature is geometry-only, not
    /// the profile-linked artifact identity.
    func testGeometryCollisionSignatureIsGeometryOnlyAndOrderInvariant() throws {
        let service = SigilVisibleGlyphService()

        let base = try service.generateArtifact(for: profile(day: 1))
        let paths = base.visibleSigil.vectorPaths
        let canonical = SigilVisibleGlyphService.geometryCollisionSignature(for: paths)

        // Order invariance: permuting the path list does not change the signature.
        let permuted = Array(paths.reversed())
        XCTAssertEqual(
            SigilVisibleGlyphService.geometryCollisionSignature(for: permuted),
            canonical, "the signature must be invariant to the order of the path list"
        )

        // Distinction: a changed geometry yields a different signature.
        let changed = VisibleVectorPath(id: "x", primitive: .dominantSpine, pathData: "M 1 1 L 99 1", strokeRole: "test", semanticSource: "test")
        XCTAssertNotEqual(
            SigilVisibleGlyphService.geometryCollisionSignature(for: [changed]),
            canonical, "a different geometry must have a different signature"
        )

        // Cross-profile: some pair of distinct profiles decode to the same branch
        // message, hence the same geometry (equal signature) but different digests.
        // Record: (profile, digest, signature).
        var firstSeen: [String: (SigilProfileInput, String, String)] = [:]
        var found: ((SigilProfileInput, String, String), (SigilProfileInput, String, String))?
        for day in 1...28 {
            let profile = self.profile(day: day)
            let artifact = try service.generateArtifact(for: profile)
            let record = (profile, artifact.visibleSigil.profileDigest, artifact.visibleSigil.styleMetadata.geometryCollisionSignature)
            if let prior = firstSeen[record.2], prior.1 != record.1 {
                found = (record, prior)
                break
            } else {
                firstSeen[record.2] = record
            }
        }
        guard let (a, b) = found else {
            return XCTFail("expected two distinct profiles sharing a branch message (same geometry, different digest)")
        }
        XCTAssertEqual(a.2, b.2, "same geometry -> equal geometry-only collision signature")
        XCTAssertNotEqual(a.1, b.1, "distinct profiles -> distinct profile digests")
        XCTAssertNotEqual(a.0.id, b.0.id, "the two profiles are distinct")
    }

    // MARK: Fail-closed integrity of the topology resource

    /// A tampered topology resource (file whose SHA-256 does not match the
    /// manifest) must fail closed with `.resourceHashMismatch`, never substitute
    /// or default. The check fires before any decode, so the topology body need
    /// not be valid for the integrity failure to be reported.
    func testLoaderFailsClosedOnTamperedResourceSha() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sigil-branch-tamper-\(UUID().uuidString)")
        let ashDir = tempDir.appendingPathComponent("ash")
        try FileManager.default.createDirectory(at: ashDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manifestJSON = """
        {
          "manifest": "sigil-branch-topology-manifest",
          "version": "1.0.0",
          "note": "tampered-for-test",
          "source_archive_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "sources": [
            {
              "id": "branch-topology",
              "display_name": "ASH Cosmology Branch Topology",
              "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
              "version": "1.0.0",
              "mode": "resource-raw",
              "resource_path": "ash/branch-topology.json",
              "role": "canonical-branch-tree"
            }
          ]
        }
        """
        try manifestJSON.write(to: ashDir.appendingPathComponent("ash-manifest.json"), atomically: true, encoding: .utf8)
        // Body is intentionally not the canonical file: only the SHA must disagree.
        try Data("not-the-canonical-topology\n".utf8)
            .write(to: ashDir.appendingPathComponent("branch-topology.json"))

        guard let bundle = Bundle(path: tempDir.path) else {
            return XCTFail("could not construct a temporary directory bundle")
        }

        XCTAssertThrowsError(try SigilBranchTopologyLoader(bundle: bundle).load()) { error in
            XCTAssertEqual(error as? SigilBranchTopologyError, .resourceHashMismatch)
        }
    }

    /// The shipped, validated topology is structurally well-formed: a full ternary
    /// tree of depth 0..4 with 121 nodes, 81 leaves, a single root, and 16 messages.
    func testShippedTopologyIsStructurallyWellFormed() throws {
        let topology = try topology()
        XCTAssertEqual(topology.nodeCount, 121)
        XCTAssertEqual(topology.leafCount, 81)
        XCTAssertEqual(topology.messages.count, 16)
        XCTAssertEqual(topology.nodes.filter { $0.path.isEmpty && $0.parentPath == nil }.count, 1, "exactly one root")
        // Every depth layer has the expected node count (1, 3, 9, 27, 81).
        for (depth, expected) in [0: 1, 1: 3, 2: 9, 3: 27, 4: 81] {
            XCTAssertEqual(topology.nodes.filter { $0.depth == depth }.count, expected, "depth \(depth) node count")
        }
    }

    // MARK: Helpers

    private func profile(day: Int) -> SigilProfileInput {
        SigilProfileInput(
            id: "bglyph_day_\(day)",
            name: "Sam Doe",
            birthDate: "1990-05-\(String(format: "%02d", day))",
            birthTime: "08:00",
            birthCity: "Test",
            birthOrder: "1 of 2",
            eyes: "brown",
            hair: "black",
            heritage: ["English"]
        )
    }

    private func hamming(_ a: UInt16, _ b: UInt16) -> Int {
        var x = (a ^ b) & 0x1FF
        var count = 0
        while x != 0 { count += Int(x & 1); x >>= 1 }
        return count
    }
}
