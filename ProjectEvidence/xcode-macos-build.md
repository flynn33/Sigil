# Xcode macOS Build Evidence

## Environment

- Date/time: `2026-07-08 11:33:54 CDT`
- Xcode version: `26.6`
- Xcode build version: `17F113`
- Project: `Sigil.xcodeproj`
- Scheme: `SigilApp`
- Destination used for Xcode build: `id=00008132-001A058621FA401C` (`My Mac`, Designed for iPad/iPhone)

## Commands

- `xcodebuild -version`
- `xcodebuild -list -project Sigil.xcodeproj`
- `xcodebuild -project Sigil.xcodeproj -scheme SigilApp -showdestinations`
- `xcodebuild -project Sigil.xcodeproj -scheme SigilApp -destination 'id=00008132-001A058621FA401C' -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation -skipMacroValidation build`
- `swift package dump-package`
- `swift test --parallel`

## Results

- Xcode inventory: passed.
- Xcode My Mac build: passed.
- SwiftPM package dump: passed; output captured at `/tmp/sigil-guardrail-dump-package.json`, 11,120 bytes.
- SwiftPM macOS-host tests: passed; 16 tests executed, 0 failures.

## Recorded Limitation

`xcodebuild ... test` on the `My Mac` Designed for iPad/iPhone destination was attempted and did not complete because local installation of the unsigned iOS app failed signature verification. The project has iOS application signing disabled for deterministic local builds, so macOS-host test coverage is recorded through SwiftPM.

## Warnings

- Generic iOS-family build output included AppIntents metadata notices for absent AppShortcuts; no build failure resulted.
