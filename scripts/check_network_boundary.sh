#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Allow network APIs only in RFGeocoding package.
PATTERN='URLSession|NWConnection|CFStreamCreatePairWithSocketToHost|HTTPClient|NSURLSession|NSURLConnection|Alamofire|Socket|WebSocket|URLRequest\('

matches=$(rg -n --glob '*.swift' "$PATTERN" Packages App || true)
if [[ -z "$matches" ]]; then
  echo "Network boundary check passed: no network APIs detected outside allowed module."
  exit 0
fi

violations=$(echo "$matches" | rg -v '^Packages/RFGeocoding/' || true)

if [[ -n "$violations" ]]; then
  echo "Network boundary violations found (only Packages/RFGeocoding is allowed):"
  echo "$violations"
  exit 1
fi

echo "Network boundary check passed."
