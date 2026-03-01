#!/usr/bin/env bash
set -euo pipefail

# Run a full local validation pipeline:
# 1) install python deps (user-local)
# 2) validate canonical-pattern-vectors.json against schema
# 3) run pytest
# 4) generate visualization (out/plane_hist.png)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REQ="$ROOT_DIR/scripts/requirements.txt"

echo "[run_checks] root: $ROOT_DIR"

if [ -f "$REQ" ]; then
  echo "[run_checks] installing requirements..."
  python3 -m pip install --user -r "$REQ"
else
  echo "[run_checks] requirements file not found: $REQ"
fi

echo "[run_checks] validating canonical-pattern-vectors.json against schema..."
python3 -m scripts.validate_schema "data/cosmology/canonical-pattern-vectors.json" "data/cosmology/cosmology_schema.json"

echo "[run_checks] running pytest..."
python3 -m pytest -q

echo "[run_checks] generating visualization..."
python3 -m scripts.visualize_planes --n 5000 --out out/plane_hist.png --canonical

echo "[run_checks] all done. output: out/plane_hist.png"
