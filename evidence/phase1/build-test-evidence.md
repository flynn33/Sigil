# Phase 1 Build and Test Evidence

## Sigil SwiftPM

- `swift package dump-package`: passed; output captured to `/tmp/sigil-dump-package.json`, 11,120 bytes.
- `swift build`: passed.
- `swift test`: passed; 16 tests, 0 failures.

## Sigil Xcode

- Project generated with `xcodegen generate`.
- Project path: `/Volumes/NVME/GitHub/Sigil/Sigil.xcodeproj`
- Scheme discovered: `SigilApp`
- Simulator: `iPhone 17`, `01733E0D-F004-42EA-A24C-86C796EBB4DD`
- `build_sim` for `SigilApp`: passed.
- `test_sim` for `SigilApp`: passed; 16 tests, 0 failures.
- `xcodebuild analyze -project Sigil.xcodeproj -scheme SigilApp -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation -skipMacroValidation -quiet`: passed.

## APS

- `swift package --package-path MaciOS dump-package`: passed; output captured to `/tmp/sigil-aps-dump-package.json`, 2,421 bytes.
- `swift build --package-path MaciOS -c release`: passed.
- `swift test --package-path MaciOS`: passed; 42 tests, 0 failures.
- `xcodebuild -scheme ASHCore -destination 'generic/platform=macOS' -configuration Release build -quiet`: passed.
- `xcodebuild -scheme ASHPatternSystem -destination 'generic/platform=macOS' -configuration Release build -quiet`: passed.
- `xcodebuild -scheme ASHCore -destination 'generic/platform=iOS' -configuration Release build -quiet`: passed.
- `xcodebuild -scheme ASHPatternSystem -destination 'generic/platform=iOS' -configuration Release build -quiet`: passed.

## Aeostara

- Source root: `/tmp/sigil-aeostara-ios-validation`
- `swift build`: passed.
- `swift test`: passed; 62 tests, 0 failures.
- `xcodebuild -list`: passed; package schemes available were `Aeostara-Package`, `AeostaraDomain`, and `AeostaraServices`.
- `xcodebuild -scheme AeostaraDomain -destination 'generic/platform=iOS' -configuration Release build -quiet`: passed.
- `xcodebuild -scheme AeostaraServices -destination 'generic/platform=iOS' -configuration Release build -quiet`: passed.
- Source-stated app-shell limit: `Package.swift` does not define an archiveable app product.

## Visual Studio

Visual Studio: N/A — iOS-only implementation; no Windows project target in scope.
