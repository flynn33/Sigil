#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/check_network_boundary.sh

packages=(
  RFCoreModels
  RFEngineData
  RFSecurity
  RFStorage
  RFSigilPipeline
  RFMeaning
  RFGeocoding
  RFRendering
  RFMythosCatalog
  RFEditor
  RFExport
)

for package in "${packages[@]}"; do
  echo "==> swift test $package"
  swift test --package-path "Packages/$package"
done

xcodebuild -project RuneForge.xcodeproj -scheme Sigil -destination 'generic/platform=iOS Simulator' build
