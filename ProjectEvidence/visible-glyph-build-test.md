# Visible Glyph Build And Test Evidence

## SwiftPM

- Red test command: `swift test --filter VisibleGlyphGenerationTests/testCanonicalProfileGeneratesDeterministicHiddenAndVisibleArtifacts`
- Red result: failed because module `RFSigilVisibleGlyph` did not exist.
- Targeted green command: `swift test --filter VisibleGlyphGenerationTests`
- Targeted green result: 6 tests passed, 0 failed.
- Full command: `swift test`
- Full result: 22 tests passed, 0 failed.

## Xcode

- Project: `Sigil.xcodeproj`
- Scheme: `SigilApp`
- Simulator: `iPhone 17`
- Command: configured simulator test profile for `SigilApp`
- Result: 22 tests passed, 0 failed, 0 skipped.
