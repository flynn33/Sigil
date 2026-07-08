#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY="$ROOT/tools/sigil_guardrails/sigil_guardrail_policy.json"

python3 "$ROOT/tools/sigil_guardrails/verify_sigil_guardrails.py" \
  --project-root "$ROOT" \
  --policy "$POLICY" \
  --strict

if command -v swift >/dev/null 2>&1 && [ -f "$ROOT/Package.swift" ]; then
  swift package dump-package >/dev/null
  swift test --parallel
fi

if command -v xcodebuild >/dev/null 2>&1 && [ -d "$ROOT/Sigil.xcodeproj" ]; then
  xcodebuild -list -project "$ROOT/Sigil.xcodeproj" >/dev/null
fi
