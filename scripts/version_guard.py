#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Iterable, NamedTuple


VERSION_PATTERN = re.compile(
    r"^(PA|A|R)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$"
)
STAGE_ORDER = {"PA": 0, "A": 1, "R": 2}


class Version(NamedTuple):
    stage: str
    major: int
    feature: int
    patch: int


class ValidationIssue(NamedTuple):
    code: str
    message: str


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_version(value: str) -> Version | None:
    match = VERSION_PATTERN.fullmatch(value.strip())
    if not match:
        return None

    stage, major, feature, patch = match.groups()
    return Version(stage=stage, major=int(major), feature=int(feature), patch=int(patch))


def version_text(version: Version) -> str:
    return f"{version.stage}.{version.major}.{version.feature}.{version.patch}"


def changelog_has_entry(changelog: str, version: Version) -> bool:
    pattern = re.compile(
        rf"^##\s+{re.escape(version_text(version))}(\s+-\s+\d{{4}}-\d{{2}}-\d{{2}})?\s*$"
    )
    return any(pattern.match(line) for line in changelog.splitlines())


def material_paths(changed_paths: Iterable[str]) -> list[str]:
    results: list[str] = []

    for raw_path in changed_paths:
        path = raw_path
        if not path or path in {"CHANGELOG.md", "VERSION"}:
            continue
        results.append(path)

    return results


def validate_version_progression(base_text: str | None, current_text: str) -> list[ValidationIssue]:
    if base_text is None or not base_text.strip():
        return []

    base = parse_version(base_text)
    current = parse_version(current_text)
    if base is None or current is None:
        return []

    if base == current:
        return []

    base_stage = STAGE_ORDER[base.stage]
    current_stage = STAGE_ORDER[current.stage]

    if current_stage > base_stage:
        return []

    if current_stage < base_stage:
        return [
            ValidationIssue(
                "invalid-version-progression",
                f"Version stage moved backward from {version_text(base)} to {version_text(current)}.",
            )
        ]

    major_bump = current.major == base.major + 1 and current.feature == 0 and current.patch == 0
    feature_bump = (
        current.major == base.major
        and current.feature == base.feature + 1
        and current.patch == 0
    )
    patch_bump = (
        current.major == base.major
        and current.feature == base.feature
        and current.patch == base.patch + 1
    )

    if major_bump or feature_bump or patch_bump:
        return []

    return [
        ValidationIssue(
            "invalid-version-progression",
            f"Version moved from {version_text(base)} to {version_text(current)} outside the allowed sequence.",
        )
    ]


def validate_repository(
    repo_root: pathlib.Path,
    changed_paths: Iterable[str],
    base_version_text: str | None = None,
) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []
    version_path = repo_root / "VERSION"
    changelog_path = repo_root / "CHANGELOG.md"

    if not version_path.exists():
        issues.append(ValidationIssue("missing-version", "VERSION is missing."))
        return issues

    current_version_text = read_text(version_path).strip()
    current_version = parse_version(current_version_text)
    if current_version is None:
        issues.append(
            ValidationIssue(
                "invalid-version",
                "VERSION must use STAGE.major.feature.patch with STAGE as PA, A, or R.",
            )
        )
        return issues

    if not changelog_path.exists():
        issues.append(ValidationIssue("missing-changelog", "CHANGELOG.md is missing."))
    else:
        changelog = read_text(changelog_path)
        if not changelog_has_entry(changelog, current_version):
            issues.append(
                ValidationIssue(
                    "missing-changelog-entry",
                    f"CHANGELOG.md must include an entry for {version_text(current_version)}.",
                )
            )

    paths = list(changed_paths)
    if material_paths(paths) and "CHANGELOG.md" not in paths:
        issues.append(
            ValidationIssue(
                "missing-changelog-change",
                "Material repository changes must include CHANGELOG.md.",
            )
        )

    issues.extend(validate_version_progression(base_version_text, current_version_text))
    return issues


def paths_from_file(path: pathlib.Path | None) -> list[str]:
    if path is None:
        return []

    data = path.read_bytes()
    return [item.decode("utf-8") for item in data.split(b"\0") if item]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate repository version and changelog policy.")
    parser.add_argument("--repo-root", type=pathlib.Path, default=pathlib.Path.cwd())
    parser.add_argument("--changed-paths-from", type=pathlib.Path, default=None)
    parser.add_argument("--base-version-file", type=pathlib.Path, default=None)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    changed_paths = paths_from_file(args.changed_paths_from)
    base_version_text = (
        read_text(args.base_version_file)
        if args.base_version_file and args.base_version_file.exists()
        else None
    )
    issues = validate_repository(repo_root, changed_paths, base_version_text)

    if not issues:
        print("Version guard passed.")
        return 0

    print("Version guard failed.")
    for issue in issues:
        print(f"::error title=Version guard::{issue.code}: {issue.message}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
