#!/usr/bin/env python3
"""Validate Yggdrasil Engine core invariants.

Checks all critical data files for structural and semantic correctness.
Run as: python -m scripts.validate_invariants
"""
import json
import os
import sys

try:
    import jsonschema
except ImportError:
    print("ERROR: python package 'jsonschema' is required. Install with: pip install jsonschema")
    sys.exit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")

PASS = "\u2713"
FAIL = "\u2717"


def load_json(path):
    """Load a JSON file, returning (data, None) or (None, error_message)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f), None
    except json.JSONDecodeError as e:
        return None, f"JSON parse error: {e}"
    except FileNotFoundError:
        return None, "File not found"
    except Exception as e:
        return None, str(e)


class CheckRunner:
    """Runs named checks and tracks results."""

    def __init__(self):
        self.results = []

    def record(self, name, passed, detail=""):
        self.results.append((name, passed, detail))
        status = PASS if passed else FAIL
        line = f"  [{status}] {name}"
        if detail:
            line += f" -- {detail}"
        print(line)

    def summary(self):
        total = len(self.results)
        passed = sum(1 for _, p, _ in self.results if p)
        failed = total - passed
        print(f"\n{'=' * 50}")
        print(f"  {passed}/{total} checks passed", end="")
        if failed:
            print(f"  ({failed} FAILED)")
        else:
            print("  (all clear)")
        print(f"{'=' * 50}")
        return 0 if failed == 0 else 1


def check_json_parseable(runner):
    """Every .json and .JSON file under data/ must parse without error."""
    for dirpath, _dirs, files in os.walk(DATA):
        for fname in sorted(files):
            if not fname.lower().endswith(".json"):
                continue
            path = os.path.join(dirpath, fname)
            rel = os.path.relpath(path, ROOT)
            data, err = load_json(path)
            runner.record(f"JSON parseable: {rel}", data is not None, err or "")


def check_schema_validation(runner):
    """Validate canonical-pattern-vectors.json and timeline.json against the cosmology schema."""
    schema_path = os.path.join(DATA, "cosmology", "cosmology_schema.json")
    schema, err = load_json(schema_path)
    if schema is None:
        runner.record("Load cosmology schema", False, err)
        return

    targets = [
        os.path.join(DATA, "cosmology", "canonical-pattern-vectors.json"),
        os.path.join(DATA, "cosmology", "timeline.json"),
    ]
    for path in targets:
        rel = os.path.relpath(path, ROOT)
        instance, err = load_json(path)
        if instance is None:
            runner.record(f"Schema validation: {rel}", False, err)
            continue
        resolver = jsonschema.RefResolver(base_uri=f"file://{schema_path}", referrer=schema)
        validator = jsonschema.Draft7Validator(schema, resolver=resolver)
        errors = list(validator.iter_errors(instance))
        if errors:
            detail = "; ".join(e.message for e in errors[:3])
            runner.record(f"Schema validation: {rel}", False, detail)
        else:
            runner.record(f"Schema validation: {rel}", True)


def check_timeline_invariants(runner):
    """Timeline must have exactly 9 phases with IDs T0-T8 in order."""
    path = os.path.join(DATA, "cosmology", "timeline.json")
    data, err = load_json(path)
    if data is None:
        runner.record("Timeline: load", False, err)
        return

    phases = data.get("phases", [])
    runner.record("Timeline: exactly 9 phases", len(phases) == 9, f"found {len(phases)}")

    expected_ids = [f"T{i}" for i in range(9)]
    actual_ids = [p.get("id") for p in phases]
    runner.record("Timeline: IDs are T0-T8 in order", actual_ids == expected_ids,
                  f"got {actual_ids}" if actual_ids != expected_ids else "")

    for phase in phases:
        pv = phase.get("pattern_vector", {})
        has_keys = all(k in pv for k in ("H", "K", "D", "S", "L"))
        if not has_keys:
            runner.record(f"Timeline: {phase.get('id')} has H,K,D,S,L", False, f"keys: {list(pv.keys())}")
            return
    runner.record("Timeline: all phases have H,K,D,S,L pattern vectors", True)


def check_entity_planes(runner):
    """All entity primary_plane values must be in [1, 9]."""
    path = os.path.join(DATA, "cosmology", "canonical-pattern-vectors.json")
    data, err = load_json(path)
    if data is None:
        runner.record("Entities: load", False, err)
        return

    entities = data.get("entities", [])
    bad = []
    for e in entities:
        pp = e.get("primary_plane")
        if pp is None or not (1 <= pp <= 9):
            bad.append(f"{e.get('id')}={pp}")
        sp = e.get("secondary_plane")
        if sp is not None and not (1 <= sp <= 9):
            bad.append(f"{e.get('id')}.secondary={sp}")
        at = e.get("ascent_target")
        if at is not None and not (1 <= at <= 9):
            bad.append(f"{e.get('id')}.ascent_target={at}")

    runner.record("Entities: all planes in [1, 9]", len(bad) == 0,
                  f"out of range: {', '.join(bad)}" if bad else "")


def check_rune_invariants(runner):
    """Elder Futhark: exactly 24 runes, 9-bit codes, correct parity, unique IDs."""
    path = os.path.join(DATA, "runes", "elder-futhark-9bit.json")
    data, err = load_json(path)
    if data is None:
        runner.record("Runes: load", False, err)
        return

    runes = data.get("runes", [])

    # Exactly 24 runes
    runner.record("Runes: exactly 24 runes", len(runes) == 24, f"found {len(runes)}")

    # Unique IDs
    ids = [r.get("id") for r in runes]
    runner.record("Runes: unique IDs", len(ids) == len(set(ids)),
                  f"duplicates: {[x for x in ids if ids.count(x) > 1]}" if len(ids) != len(set(ids)) else "")

    # 9-bit codes
    bit_errors = []
    for r in runes:
        rid = r.get("id", "?")
        bits = r.get("bits", "")
        if len(bits) != 9 or not all(c in "01" for c in bits):
            bit_errors.append(rid)
    runner.record("Runes: all bits are 9-char binary strings", len(bit_errors) == 0,
                  f"bad: {bit_errors}" if bit_errors else "")

    # Parity field must be "even" or "odd"
    parity_invalid = []
    for r in runes:
        if r.get("parity") not in ("even", "odd"):
            parity_invalid.append(r.get("id", "?"))
    runner.record("Runes: parity values are even/odd", len(parity_invalid) == 0,
                  f"invalid: {parity_invalid}" if parity_invalid else "")

    # Wolf alignment must match parity (even=White Wolf, odd=Dark Wolf)
    wolf_errors = []
    for r in runes:
        parity = r.get("parity", "")
        wolf = r.get("wolf", "")
        if parity == "even" and wolf != "White Wolf":
            wolf_errors.append(f"{r.get('id')}: parity=even but wolf={wolf}")
        elif parity == "odd" and wolf != "Dark Wolf":
            wolf_errors.append(f"{r.get('id')}: parity=odd but wolf={wolf}")
    runner.record("Runes: wolf alignment matches parity (even=White, odd=Dark)", len(wolf_errors) == 0,
                  f"mismatches: {wolf_errors}" if wolf_errors else "")


def main():
    print("Yggdrasil Engine -- Invariant Validation")
    print("=" * 50)
    runner = CheckRunner()

    check_json_parseable(runner)
    check_schema_validation(runner)
    check_timeline_invariants(runner)
    check_entity_planes(runner)
    check_rune_invariants(runner)

    sys.exit(runner.summary())


if __name__ == "__main__":
    main()
