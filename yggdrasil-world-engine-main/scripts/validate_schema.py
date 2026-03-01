#!/usr/bin/env python3
import sys
import json

try:
    import jsonschema
except Exception:
    print("ERROR: python package 'jsonschema' is required. Install with: pip install jsonschema")
    sys.exit(2)


def load(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def main():
    if len(sys.argv) < 3:
        print("Usage: validate_schema.py <instance.json> <schema.json>")
        sys.exit(2)

    inst_path = sys.argv[1]
    schema_path = sys.argv[2]

    try:
        instance = load(inst_path)
    except Exception as e:
        print(f"Failed to load instance '{inst_path}': {e}")
        sys.exit(3)

    try:
        schema = load(schema_path)
    except Exception as e:
        print(f"Failed to load schema '{schema_path}': {e}")
        sys.exit(3)

    resolver = jsonschema.RefResolver(base_uri=f'file://{schema_path}', referrer=schema)
    validator = jsonschema.Draft7Validator(schema, resolver=resolver)
    errors = sorted(validator.iter_errors(instance), key=lambda e: e.path)

    if not errors:
        print(f"VALID: '{inst_path}' conforms to '{schema_path}'")
        sys.exit(0)

    print(f"INVALID: '{inst_path}' does NOT conform to '{schema_path}'. Found {len(errors)} error(s):")
    for e in errors:
        path = '.'.join([str(p) for p in e.path]) or '<root>'
        print(f" - {path}: {e.message}")

    sys.exit(1)


if __name__ == '__main__':
    main()
