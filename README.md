# Sigil (iOS Companion)

Sigil is a native iPhone app (`iOS 17+`) that generates a deterministic personal sigil locally on-device, based on user profile data and a pinned snapshot of Yggdrasil engine data.

## Implemented (Phase 1 Foundation)

- Native SwiftUI app target: `SigilApp`
- Modular local Swift packages:
  - `RFCoreModels`
  - `RFEngineData`
  - `RFSigilPipeline`
  - `RFMeaning`
  - `RFStorage`
  - `RFSecurity`
  - `RFGeocoding`
  - `RFRendering`
  - `RFEditor`
  - `RFExport`
  - `RFMythosCatalog`
- Core Data profile repository with encrypted payload blobs (AES-GCM via CryptoKit)
- Keychain master key with optional biometric gate
- Optional app-level lock overlay (Face ID / Passcode) on foreground resume
- Deterministic sigil pipeline (`rf.pipeline.v2`) and geometry export contract (`rf.geometry.v1`)
- Apple Maps birthplace lookup + manual coordinate override
- Advanced layered studio controls (order/transform/style/blend/mask/effects) and expanded 10+ mythos catalog packs
- Profile-scoped non-destructive studio presets (save/load/rename/duplicate/pin/delete) with thumbnail cards and one-tap apply
- Dynamic form builder for custom profile fields (typed definitions + values)
- PNG/JPEG image export + SVG/JSON geometry export with custom profile/resolution/quality/metadata controls

## Project Structure

- `RuneForge.xcodeproj` generated from `project.yml`
- `App/` SwiftUI app source
- `Packages/` local modules and tests
- `scripts/check_network_boundary.sh` enforces network isolation outside `RFGeocoding`
- `scripts/run_checks.sh` runs package tests + app build
- `docs/MythosImagePromptPack.md` contains stock-image prompt sets for Mythos asset generation
- `docs/MythosImageBatch01.md` contains the first 40 production filename+prompt entries

## Build

```bash
xcodegen generate
xcodebuild -project RuneForge.xcodeproj -scheme Sigil -destination 'generic/platform=iOS Simulator' build
```

## Test

```bash
./scripts/run_checks.sh
xcodebuild -project RuneForge.xcodeproj -scheme Sigil -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test
```

## Yggdrasil Data Snapshot

Pinned engine inputs are embedded under:

- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/agent/agent-sigil-creation.JSON`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/agent/public-gift-tables.json`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/cosmology/canonical-pattern-vectors.json`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/runes/elder-futhark-9bit.json`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/wrw-canon/nine-planes-of-existence.json`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/wrw-canon/axioms-of-existence.json`
- `Packages/RFEngineData/Sources/RFEngineData/Resources/data/wrw-canon/master-mythic-mapping.json`
