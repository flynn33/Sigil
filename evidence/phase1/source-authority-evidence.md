# Phase 1 Source Authority Evidence

## Forsetti

- Source root inspected: `/tmp/sigil-source-authority/Forsetti-Framework-Mac-iOS-main`
- Public package products: `ForsettiCore`, `ForsettiPlatform`, `ForsettiHostTemplate`
- Observed version: `0.1.4`
- Remote source used by Sigil: `https://github.com/flynn33/Forsetti-Framework-Mac-iOS.git`
- Pinned revision: `43eef7a739f3b78253c64aa4b070521ab5b1f43c`
- Sigil usage: `ForsettiCore` public contracts only.

## APS

- Source root inspected: `/tmp/sigil-source-authority/ASH-Pattern-System-Mac-iOS-main`
- Package path: `MaciOS/Package.swift`
- Package products: `ASHCore`, `ASHPatternSystem`
- Required evidence read: invariant spec, five conformance categories, per-module contracts, diagnostic schema, rule ID taxonomy, full `F2^9` state space, XOR-by-codeword transformation, materialization boundary, fallback policy registry, containment `SAFE_HALT`, recoverability, monotonic escalation, no silent healing, and no invented codewords.
- Caveat: two package-listed wiki files were absent locally, and equivalent source coverage was taken from current specs under `specs/interfaces`, `specs/core`, `specs/algorithms`, and `specs/registries`.
- Caveat: fallback registry source carries older wording while the broader APS baseline uses the full 9D foundation. Sigil records this as `CONFORMANT WITH CAVEATS` and does not reinterpret APS semantics.

## Aeostara

- Local root archive inspected: `/tmp/sigil-source-authority/Aeostara-Mac-iOS-main`
- Remote iOS branch inspected: `flynn33/Aeostara-Mac-iOS@platform/ios`
- Branch commit: `33e9154c36ef4eb38f827973c110ecf7c98ace77`
- Tree: `9678567f221c9bd1e5963634b15f8b43a25dfcd0`
- Products: `AeostaraDomain`, `AeostaraServices`
- Test target: `AeostaraTests`
- Baseline release pin: `v1.0.0`
- Baseline commit: `774b981ef2267a41c1b1a59497b2b0746a86f32b`
- Migration commit: `0c931a7cbac349c6be93a6aeb4a253dd2268178f`

## YWE / WRW

- Source root inspected: `/tmp/sigil-source-authority/yggdrasil-world-engine-main`
- Required authority sources read from `/Users/flynn/Downloads/yggdrasil-world-engine-main.zip`
- Sigil status model preserves the hierarchy: ASH Model foundation, YWE simulation framework, APS as YWE component, WRW narrative/product interpretation layer, and Sigil iOS product layer.
- Phase 1 status confirms no WRW lore, PersonalCodex, or final pipeline generation is implemented.
