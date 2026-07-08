#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable, NamedTuple


DEFAULT_EXCLUDES = {
    ".build",
    ".derivedData",
    ".git",
    ".swiftpm",
    ".xcode",
    ".vscode",
    "__MACOSX",
    "DerivedData",
}

TEXT_SUFFIXES = {
    ".entitlements",
    ".json",
    ".md",
    ".plist",
    ".ps1",
    ".sh",
    ".swift",
    ".txt",
    ".xcconfig",
    ".xml",
    ".yaml",
    ".yml",
}

TEXT_NAMES = {
    ".gitattributes",
    ".gitignore",
}

ASH_CODEWORDS = {
    (0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 1, 1, 1, 1, 0),
    (0, 0, 1, 1, 0, 0, 1, 1, 0),
    (0, 0, 1, 1, 1, 1, 0, 0, 0),
    (0, 1, 0, 1, 0, 1, 0, 1, 0),
    (0, 1, 0, 1, 1, 0, 1, 0, 0),
    (0, 1, 1, 0, 0, 1, 1, 0, 0),
    (0, 1, 1, 0, 1, 0, 0, 1, 0),
    (1, 0, 0, 1, 0, 1, 1, 0, 0),
    (1, 0, 0, 1, 1, 0, 0, 1, 0),
    (1, 0, 1, 0, 0, 1, 0, 1, 0),
    (1, 0, 1, 0, 1, 0, 1, 0, 0),
    (1, 1, 0, 0, 0, 0, 1, 1, 0),
    (1, 1, 0, 0, 1, 1, 0, 0, 0),
    (1, 1, 1, 1, 0, 0, 0, 0, 0),
    (1, 1, 1, 1, 1, 1, 1, 1, 0),
}

RULE_ID_PATTERN = re.compile(r"\bASH-[A-Z]+-[A-Z]+-\d{3}\b")


class Failure(NamedTuple):
    code: str
    message: str
    path: str | None = None


def decode_hex(value: str) -> str:
    return bytes.fromhex(value).decode("utf-8")


def decoded_values(values: Iterable[str]) -> list[str]:
    return [decode_hex(value) for value in values]


def marker_pattern(value: str) -> re.Pattern[str]:
    parts = re.findall(r"[A-Za-z0-9]+", value)
    if not parts:
        return re.compile(re.escape(value), re.IGNORECASE)
    return re.compile(
        r"\b" + r"[^A-Za-z0-9]+".join(re.escape(part) for part in parts) + r"\b",
        re.IGNORECASE,
    )


def load_policy(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def is_text_file(path: Path) -> bool:
    return path.suffix in TEXT_SUFFIXES or path.name in TEXT_NAMES


def iter_project_files(root: Path):
    for path in root.rglob("*"):
        if any(part in DEFAULT_EXCLUDES for part in path.parts):
            continue
        if path.is_file():
            yield path


def display_path(root: Path, path: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str | None:
    if not is_text_file(path):
        return None
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None


def blocked_values(policy: dict, legacy_key: str, hex_key: str) -> list[str]:
    blocked = policy.get("blocked_project_patterns", {})
    values = list(blocked.get(legacy_key, []))
    values.extend(decoded_values(blocked.get(hex_key, [])))
    return values


def add_failure(failures: list[Failure], code: str, message: str, path: str | None = None) -> None:
    failures.append(Failure(code=code, message=message, path=path))


def validate_json(root: Path, failures: list[Failure]) -> None:
    for path in iter_project_files(root):
        if path.suffix != ".json":
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as error:
            add_failure(
                failures,
                "invalid-json",
                f"Invalid JSON: {error}",
                display_path(root, path),
            )


def scan_blocked_markers(root: Path, policy: dict, failures: list[Failure]) -> None:
    attribution_patterns = [
        marker_pattern(marker)
        for marker in blocked_values(policy, "attribution_markers", "attribution_marker_hex")
    ]
    ash_patterns = [
        marker_pattern(marker)
        for marker in blocked_values(policy, "ash_misuse_markers_in_source", "ash_misuse_marker_hex")
    ]

    for path in iter_project_files(root):
        text = read_text(path)
        if text is None:
            continue
        relative_path = display_path(root, path)

        for pattern in attribution_patterns:
            if pattern.search(text):
                add_failure(
                    failures,
                    "blocked-attribution-marker",
                    "Attribution marker is prohibited.",
                    relative_path,
                )

        if path.suffix == ".swift" or "Sources" in path.parts or "Tests" in path.parts:
            for pattern in ash_patterns:
                if pattern.search(text):
                    add_failure(
                        failures,
                        "blocked-ash-marker",
                        "Superseded ASH marker is prohibited in source and test surfaces.",
                        relative_path,
                    )


def scan_blocked_paths(root: Path, policy: dict, failures: list[Failure]) -> None:
    blocked = policy.get("blocked_project_patterns", {})
    for relative_path in blocked.get("forsetti_internal_copy_paths", []):
        if (root / relative_path).exists():
            add_failure(
                failures,
                "blocked-path",
                "Forsetti internal source tree must not be copied into Sigil.",
                relative_path,
            )


def validate_ash_codeword_literals(root: Path, failures: list[Failure]) -> None:
    tuple_pattern = re.compile(r"\((?:\s*[01]\s*,){8}\s*[01]\s*\)")

    for path in iter_project_files(root):
        if not (path.suffix == ".swift" or "ASH" in path.name):
            continue
        text = read_text(path)
        if not text:
            continue

        for match in tuple_pattern.finditer(text):
            vector = tuple(int(item) for item in re.findall(r"[01]", match.group(0)))
            if len(vector) == 9 and vector not in ASH_CODEWORDS:
                add_failure(
                    failures,
                    "invalid-ash-codeword",
                    "9-bit vector literal is outside the canonical ASH codeword set.",
                    display_path(root, path),
                )


def validate_diagnostic_rule_ids(root: Path, failures: list[Failure]) -> None:
    for path in iter_project_files(root):
        if path.suffix not in {".swift", ".json"}:
            continue
        text = read_text(path)
        if not text:
            continue
        if "rule_ids" in text and not RULE_ID_PATTERN.search(text):
            add_failure(
                failures,
                "missing-ash-rule-id",
                "Diagnostic surface appears without canonical ASH rule ID pattern.",
                display_path(root, path),
            )


def validate_forsetti_manifests(root: Path, failures: list[Failure]) -> None:
    for path in iter_project_files(root):
        if path.suffix != ".json":
            continue
        if "manifest" not in str(path).lower():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        text = json.dumps(data).lower()
        if "forsetti" not in text:
            continue
        required_fields = ["min_forsetti_version", "module_id", "module_type"]
        missing = [field for field in required_fields if field not in text]
        if missing:
            add_failure(
                failures,
                "invalid-forsetti-manifest",
                f"Forsetti manifest missing expected fields: {', '.join(missing)}.",
                display_path(root, path),
            )


def validate_required_evidence(root: Path, policy: dict, failures: list[Failure]) -> None:
    for relative_path in policy.get("required_evidence_files", []):
        if not (root / relative_path).is_file():
            add_failure(
                failures,
                "missing-evidence",
                "Required evidence file is missing.",
                relative_path,
            )


def check_git_metadata(root: Path, policy: dict, failures: list[Failure]) -> None:
    if not (root / ".git").exists():
        return

    markers = blocked_values(policy, "attribution_markers", "attribution_marker_hex")
    try:
        branch = subprocess.check_output(
            ["git", "branch", "--show-current"],
            cwd=root,
            text=True,
        ).strip()
        messages = subprocess.check_output(
            ["git", "log", "--format=%B", "-n", "25"],
            cwd=root,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except Exception:
        return

    for marker in markers:
        pattern = marker_pattern(marker)
        if pattern.search(branch):
            add_failure(
                failures,
                "blocked-attribution-marker",
                "Attribution marker is prohibited in branch name.",
                "git branch",
            )
        if pattern.search(messages):
            add_failure(
                failures,
                "blocked-attribution-marker",
                "Attribution marker is prohibited in recent commit messages.",
                "git log",
            )


def verify_project(
    project_root: Path,
    policy_path: Path,
    strict: bool,
    include_git: bool = True,
) -> list[Failure]:
    root = project_root.resolve()
    policy_file = policy_path if policy_path.is_absolute() else root / policy_path
    failures: list[Failure] = []

    if not policy_file.exists():
        return [
            Failure(
                code="missing-policy",
                message="Policy file is missing.",
                path=display_path(root, policy_file),
            )
        ]

    try:
        policy = load_policy(policy_file)
    except Exception as error:
        return [
            Failure(
                code="invalid-policy",
                message=f"Unable to load policy: {error}",
                path=display_path(root, policy_file),
            )
        ]

    validate_json(root, failures)
    scan_blocked_markers(root, policy, failures)
    scan_blocked_paths(root, policy, failures)
    validate_ash_codeword_literals(root, failures)
    validate_diagnostic_rule_ids(root, failures)
    validate_forsetti_manifests(root, failures)
    if strict:
        validate_required_evidence(root, policy, failures)
    if include_git:
        check_git_metadata(root, policy, failures)

    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify Sigil project guardrails.")
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    parser.add_argument("--policy", type=Path, default=Path("tools/sigil_guardrails/sigil_guardrail_policy.json"))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    failures = verify_project(args.project_root, args.policy, strict=args.strict)

    if not failures:
        print("SIGIL PROJECT GUARDRAILS PASSED")
        return 0

    print("SIGIL PROJECT GUARDRAILS FAILED")
    for failure in failures:
        location = f"{failure.path}: " if failure.path else ""
        print(f"- {failure.code}: {location}{failure.message}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
