# Xcode iOS Build Evidence

## Environment

- Date/time: `2026-07-08 11:33:54 CDT`
- Xcode version: `26.6`
- Xcode build version: `17F113`
- Project: `Sigil.xcodeproj`
- Scheme: `SigilApp`
- Simulator: `iPhone 17`
- Simulator ID: `01733E0D-F004-42EA-A24C-86C796EBB4DD`

## Commands

- XcodeBuildMCP `session_show_defaults`
- XcodeBuildMCP `build_sim` with `-skipPackagePluginValidation -skipMacroValidation`
- XcodeBuildMCP `test_sim` with `-skipPackagePluginValidation -skipMacroValidation`
- `xcodebuild -project Sigil.xcodeproj -scheme SigilApp -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation -skipMacroValidation build`

## Results

- XcodeBuildMCP defaults: project `Sigil.xcodeproj`, scheme `SigilApp`, simulator `iPhone 17`.
- iOS simulator build: passed.
- iOS simulator tests: passed; 16 tests passed, 0 failed, 0 skipped.
- Generic iOS Xcode build: passed.

## Warnings

- Generic iOS build output included AppIntents metadata notices for absent AppShortcuts; no build failure resulted.
