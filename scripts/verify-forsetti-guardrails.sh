#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Forsetti consumer guardrails: package tests"
for package_dir in Packages/*; do
  if [[ -f "$package_dir/Package.swift" ]]; then
    echo "==> swift test --parallel --enable-code-coverage ($package_dir)"
    (
      cd "$package_dir"
      swift test --parallel --enable-code-coverage
    )
  fi
done

echo "==> Forsetti consumer guardrails: lint"
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "ERROR: swiftlint is required for Forsetti guardrails and is not installed." >&2
  exit 1
fi

swiftlint lint --strict --config .swiftlint.yml

echo "Forsetti guardrails passed."
