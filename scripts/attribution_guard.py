#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys
from typing import Iterable, NamedTuple


PHRASE_HEX = (
    "47656e657261746564206279204149",
    "43726561746564206279204149",
    "41492d6173736973746564",
    "41737369737465642062792043686174475054",
    "417373697374656420627920436f646578",
    "417373697374656420627920436c61756465",
    "5772697474656e2062792043686174475054",
    "5772697474656e20627920436f646578",
    "5772697474656e206279204149",
    "436f2d617574686f7265642d62793a204149",
    "436f2d617574686f7265642d62793a2043686174475054",
    "436f2d617574686f7265642d62793a20436f646578",
    "436f2d617574686f7265642d62793a204f70656e4149",
    "4c4c4d2d67656e657261746564",
    "4d6f64656c2d67656e657261746564",
    "4d616368696e652d67656e657261746564",
    "4167656e742d67656e657261746564",
)

TOKEN_HEX = (
    "4149",
    "4c4c4d",
    "43686174475054",
    "436f646578",
    "4f70656e4149",
    "436c61756465",
    "416e7468726f706963",
    "47726f6b",
    "784149",
)


class Violation(NamedTuple):
    surface: str
    value: str
    rule: str
    line: int | None = None


def decode_hex(value: str) -> str:
    return bytes.fromhex(value).decode("utf-8")


def normalized_words(value: str) -> list[str]:
    return [part for part in re.split(r"[^a-z0-9]+", value.lower()) if part]


def normalized_phrase(value: str) -> str:
    return " ".join(normalized_words(value))


def phrase_pattern(value: str) -> re.Pattern[str]:
    parts = re.findall(r"[A-Za-z0-9]+", value)
    return re.compile(r"\b" + r"[^A-Za-z0-9]+".join(map(re.escape, parts)) + r"\b", re.IGNORECASE)


PHRASES = tuple(decode_hex(value) for value in PHRASE_HEX)
TOKENS = tuple(decode_hex(value).lower() for value in TOKEN_HEX)
NORMALIZED_PHRASES = tuple(normalized_phrase(value) for value in PHRASES)
CONTENT_PATTERNS = tuple((value, phrase_pattern(value)) for value in PHRASES)
TOKEN_PATTERNS = tuple(
    (value, re.compile(r"\b" + re.escape(value) + r"\b", re.IGNORECASE))
    for value in (decode_hex(item) for item in TOKEN_HEX)
)


def scan_label(surface: str, value: str) -> list[Violation]:
    normalized = normalized_phrase(value)
    words = set(normalized_words(value))
    results: list[Violation] = []

    for phrase in NORMALIZED_PHRASES:
        if phrase and phrase in normalized:
            results.append(Violation(surface=surface, value=value, rule="blocked phrase"))
            return results

    for token in TOKENS:
        if token in words:
            results.append(Violation(surface=surface, value=value, rule="blocked token"))
            return results

    return results


def scan_text(surface: str, value: str, content: str) -> list[Violation]:
    for line_number, line in enumerate(content.splitlines(), start=1):
        for _, pattern in CONTENT_PATTERNS:
            if pattern.search(line):
                return [
                    Violation(
                        surface=surface,
                        value=value,
                        rule="blocked phrase",
                        line=line_number,
                    )
                ]
        for _, pattern in TOKEN_PATTERNS:
            if pattern.search(line):
                return [
                    Violation(
                        surface=surface,
                        value=value,
                        rule="blocked token",
                        line=line_number,
                    )
                ]

    return []


def is_binary(data: bytes) -> bool:
    return b"\0" in data[:4096]


def scan_content(path: pathlib.Path, repo_root: pathlib.Path) -> list[Violation]:
    if not path.exists() or not path.is_file():
        return []

    data = path.read_bytes()
    if is_binary(data):
        return []

    content = data.decode("utf-8", errors="ignore")
    display_path = str(path.relative_to(repo_root)) if path.is_relative_to(repo_root) else str(path)

    return scan_text("content", display_path, content)


def coerce_repo_path(path: pathlib.Path, repo_root: pathlib.Path) -> pathlib.Path:
    if path.is_absolute():
        return path
    return repo_root / path


def scan_targets(
    branch_name: str | None,
    paths: Iterable[pathlib.Path],
    repo_root: pathlib.Path,
    text_targets: Iterable[tuple[str, str]] = (),
) -> list[Violation]:
    results: list[Violation] = []

    if branch_name:
        results.extend(scan_label("branch", branch_name))

    for surface, content in text_targets:
        results.extend(scan_text(surface, surface, content))

    for original_path in paths:
        path = coerce_repo_path(original_path, repo_root)
        display_path = str(path.relative_to(repo_root)) if path.is_relative_to(repo_root) else str(path)
        results.extend(scan_label("path", display_path))
        results.extend(scan_content(path, repo_root))

    return results


def run_git(args: list[str], repo_root: pathlib.Path) -> bytes:
    return subprocess.check_output(["git", *args], cwd=repo_root)


def paths_from_git(repo_root: pathlib.Path, base_ref: str | None, head_ref: str | None) -> list[pathlib.Path]:
    if base_ref and head_ref:
        output = run_git(["diff", "--name-only", "-z", f"{base_ref}...{head_ref}"], repo_root)
    else:
        output = run_git(["ls-files", "-z", "--cached", "--others", "--exclude-standard"], repo_root)

    return [pathlib.Path(item.decode("utf-8")) for item in output.split(b"\0") if item]


def paths_from_file(path: pathlib.Path) -> list[pathlib.Path]:
    data = path.read_bytes()
    return [pathlib.Path(item.decode("utf-8")) for item in data.split(b"\0") if item]


def text_targets_from_files(values: Iterable[str]) -> list[tuple[str, str]]:
    targets: list[tuple[str, str]] = []

    for value in values:
        surface, separator, path_value = value.partition("=")
        if not separator or not surface or not path_value:
            raise ValueError("--text-from values must use SURFACE=PATH")
        path = pathlib.Path(path_value)
        targets.append((surface, path.read_text(encoding="utf-8", errors="ignore")))

    return targets


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Reject blocked attribution markers.")
    parser.add_argument("--branch", default=None)
    parser.add_argument("--base-ref", default=None)
    parser.add_argument("--head-ref", default=None)
    parser.add_argument("--paths-from", type=pathlib.Path, default=None)
    parser.add_argument("--text-from", action="append", default=[])
    parser.add_argument("--repo-root", type=pathlib.Path, default=pathlib.Path.cwd())
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()

    if args.paths_from:
        paths = paths_from_file(args.paths_from)
    else:
        paths = paths_from_git(repo_root, args.base_ref, args.head_ref)

    violations = scan_targets(args.branch, paths, repo_root, text_targets_from_files(args.text_from))
    if not violations:
        print("Attribution guard passed.")
        return 0

    print("Attribution guard failed.")
    for item in violations:
        location = item.value if item.line is None else f"{item.value}:{item.line}"
        print(f"::error title=Attribution guard::{item.surface} rejected: {location} ({item.rule})")
    return 1


if __name__ == "__main__":
    sys.exit(main())
