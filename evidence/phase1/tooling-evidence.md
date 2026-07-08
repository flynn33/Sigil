# Phase 1 Tooling Evidence

## Local Toolchain

- Xcode path: `/Applications/Xcode.app/Contents/Developer`
- Xcode version: `26.6`
- Xcode build version: `17F113`
- Swift version: `6.3.3`
- Host: macOS Darwin arm64
- XcodeGen version: `2.45.4`

## IDE Validation

- Xcode project generated at `/Volumes/NVME/GitHub/Sigil/Sigil.xcodeproj`
- Schemes discovered through Xcode validation: `SigilApp` and module schemes.
- Simulator build and test were executed through the Xcode validation layer with local derived data at `/Volumes/NVME/GitHub/Sigil/.derivedData`.

## Source Access

- Local archives were used for Forsetti, APS, and YWE/WRW.
- GitHub connector access was used for Aeostara `platform/ios` because the local root archive did not contain the branch implementation.
- A temporary read-only Aeostara validation clone was created at `/tmp/sigil-aeostara-ios-validation`.

## Local Orchestration

- Local orchestration was available and used for independent read-only source inspections.
- All inspections were reconciled against direct local command output before implementation decisions were made.
