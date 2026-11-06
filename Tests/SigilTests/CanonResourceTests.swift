import Foundation
import RFSigilCanon
import XCTest

final class CanonResourceTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a minimal directory-backed `Bundle` containing the given
    /// `relativePath: content` text resources plus an Info.plist, so the loader's
    /// resource lookup and fail-closed paths can be exercised in isolation.
    private func makeBundle(resources: [String: String]) throws -> (bundle: Bundle, directory: URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("canon-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>CFBundleIdentifier</key><string>test.canon.bundle</string><key>CFBundleName</key><string>canon</string></dict></plist>
        """
        try plist.write(to: dir.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        for (relativePath, content) in resources {
            let url = dir.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
        }
        guard let bundle = Bundle(path: dir.path) else {
            try? FileManager.default.removeItem(at: dir)
            throw XCTSkip("Could not create a directory-backed bundle for the test.")
        }
        return (bundle, dir)
    }

    // MARK: - Load and structural validation (real product resources)

    func testLoadSucceedsAndIsStructurallyValid() throws {
        let canon = try SigilCanonLoader().load()

        XCTAssertEqual(canon.ninePlanes.count, 9)
        for expected in 1...9 {
            XCTAssertNotNil(canon.ninePlane(id: expected), "Missing plane \(expected)")
        }
        XCTAssertEqual(canon.celestialGenerator.model.planes.count, 9)
        for code in (1...9).map({ "P\($0)" }) {
            XCTAssertFalse(canon.celestialGenerator.model.syllables.plane[code]?.isEmpty ?? true,
                           "Missing or empty plane syllables for \(code)")
        }
        XCTAssertEqual(canon.sources.count, 5, "The manifest must register all five canon sources")
        XCTAssertFalse(canon.provenanceDigest.isEmpty)
        XCTAssertEqual(canon.provenanceDigest.count, 64, "Provenance digest must be a SHA-256 hex string")
        XCTAssertFalse(canon.algorithmSpecificationSha256.isEmpty)
        XCTAssertEqual(canon.algorithmSpecificationSha256.count, 64)
    }

    func testNinePlaneTaxonomyHasNinePlanesInFixedOrder() throws {
        let canon = try SigilCanonLoader().load()
        XCTAssertEqual(canon.ninePlanes.map(\.id), Array(1...9), "Plane order must be the fixed P1-P9 order")
        XCTAssertEqual(canon.ninePlanes[4].id, 5)
        XCTAssertEqual(canon.ninePlanes[4].name, "Causal")
    }

    // MARK: - Provenance visibility

    func testProvenanceDigestIsDeterministicAndVersionSensitive() {
        func makeResource(sourceVersion: String) -> SigilCanonResource {
            let source = SigilCanonSource(
                id: "celestial-gen",
                displayName: "Celestial Name Generator",
                sha256: String(repeating: "a", count: 64),
                version: sourceVersion,
                mode: .resourceRaw,
                role: "celestial naming"
            )
            let generator = SigilCelestialGenerator(
                version: "1.0.0",
                model: SigilCelestialGeneratorModel(
                    modelName: "CelestialNameGenerator",
                    version: "1.0.0",
                    planes: [],
                    weekdayArchetypes: [:],
                    wolfBalanceRules: SigilWolfBalanceRules(
                        baseScore: 0,
                        hairModifiers: [:],
                        eyeModifiers: [:],
                        birthTimeModifiers: [:],
                        lifePathModifiers: [:],
                        thresholds: .init(whiteDominant: 1.0, balancedLower: -1.0, balancedUpper: 1.0, darkDominant: -1.0)
                    ),
                    heritageFamilies: [:],
                    syllables: .init(root: .init(neutral: []), plane: [:], wolf: .init(white: [], dark: [], balanced: [])),
                    nameStructureRules: .init(
                        celestialName: .init(parts: [], joinStyle: "camel", lengthPreference: .init(minSyllables: 2, maxSyllables: 4)),
                        epithet: .init(enabled: true, useTemplates: true)
                    ),
                    epithetTemplates: [],
                    numerologyFragments: .init(planes: [:], wolfBalance: [:], weekday: [:]),
                    exampleProfiles: [],
                    birthTimeBuckets: [:]
                ),
                algorithmVersion: "1.0.1"
            )
            return SigilCanonResource(
                celestialGenerator: generator,
                mythicMap: SigilMythicMap(
                    darkWolvesPrimordial: .init(description: "", symbolism: [], planes: [], function: []),
                    whiteWolvesPrimordial: .init(description: "", symbolism: [], planes: [], function: []),
                    balancePrinciple: .init(description: "", cosmicCycle: [], modelInterpretation: ""),
                    angels: .init(description: "", planeHome: "", planeTarget: "", punishment: "", redemptionPath: ""),
                    lucifer: .init(description: "", planes: [], duties: [], modelRole: ""),
                    trials: .init(description: "", planes: [], failureCondition: "", redemption: "")
                ),
                ninePlanes: SigilNinePlaneTaxonomy.planes,
                sources: [source],
                manifestVersion: "1.0.0",
                algorithmSpecificationSha256: String(repeating: "b", count: 64)
            )
        }

        let a = makeResource(sourceVersion: "1.0.0")
        let aAgain = makeResource(sourceVersion: "1.0.0")
        let b = makeResource(sourceVersion: "1.0.1")

        XCTAssertEqual(a.provenanceDigest, aAgain.provenanceDigest, "Provenance digest must be deterministic")
        XCTAssertNotEqual(a.provenanceDigest, b.provenanceDigest, "A source-version change must be visible in the provenance digest")
    }

    // MARK: - Fail-closed (malformed / tampered)

    func testManifestMissingFailsClosed() throws {
        let (bundle, dir) = try makeBundle(resources: [:])
        defer { try? FileManager.default.removeItem(at: dir) }

        XCTAssertThrowsError(try SigilCanonLoader(bundle: bundle).load()) { error in
            XCTAssertEqual(error as? SigilCanonError, .manifestMissing)
        }
    }

    func testTamperedResourceFailsHashMismatch() throws {
        let manifest = """
        {
          "manifest": "canon-manifest",
          "version": "1.0.0",
          "note": "test fixture",
          "sources": [
            {
              "id": "celestial-gen",
              "display_name": "Celestial Name Generator",
              "sha256": "\(String(repeating: "0", count: 64))",
              "version": "1.0.0",
              "mode": "resource-raw",
              "role": "celestial naming",
              "resource_path": "canon/celestial-name-generator.json"
            }
          ]
        }
        """
        let (bundle, dir) = try makeBundle(resources: [
            "canon/canon-manifest.json": manifest,
            "canon/celestial-name-generator.json": "{}"
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        XCTAssertThrowsError(try SigilCanonLoader(bundle: bundle).load()) { error in
            XCTAssertEqual(error as? SigilCanonError, .resourceHashMismatch(sourceID: "celestial-gen"))
        }
    }
}
