import importlib.util
import pathlib
import tempfile
import textwrap
import unittest


SCRIPT_PATH = pathlib.Path(__file__).resolve().parents[2] / "scripts" / "version_guard.py"


def load_guard():
    spec = importlib.util.spec_from_file_location("version_guard", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class VersionGuardTests(unittest.TestCase):
    def test_valid_version_and_changelog_pass(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            (root / "VERSION").write_text("PA.0.1.0\n", encoding="utf-8")
            (root / "CHANGELOG.md").write_text(
                textwrap.dedent(
                    """
                    # Changelog

                    ## PA.0.1.0 - 2026-07-08

                    - Initial foundation.
                    """
                ).lstrip(),
                encoding="utf-8",
            )

            issues = guard.validate_repository(root, changed_paths=[])

        self.assertEqual(issues, [])

    def test_invalid_version_prefix_fails(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            (root / "VERSION").write_text("B.0.1.0\n", encoding="utf-8")
            (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")

            issues = guard.validate_repository(root, changed_paths=[])

        self.assertEqual([issue.code for issue in issues], ["invalid-version"])

    def test_missing_changelog_entry_fails(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            (root / "VERSION").write_text("PA.0.1.0\n", encoding="utf-8")
            (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")

            issues = guard.validate_repository(root, changed_paths=[])

        self.assertEqual([issue.code for issue in issues], ["missing-changelog-entry"])

    def test_material_change_requires_changelog_update(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            (root / "VERSION").write_text("PA.0.1.0\n", encoding="utf-8")
            (root / "CHANGELOG.md").write_text(
                "# Changelog\n\n## PA.0.1.0 - 2026-07-08\n\n- Initial foundation.\n",
                encoding="utf-8",
            )

            issues = guard.validate_repository(root, changed_paths=["Sources/App.swift"])

        self.assertEqual([issue.code for issue in issues], ["missing-changelog-change"])

    def test_feature_version_progression_passes(self):
        guard = load_guard()

        issues = guard.validate_version_progression("PA.0.1.0", "PA.0.2.0")

        self.assertEqual(issues, [])

    def test_version_downgrade_fails(self):
        guard = load_guard()

        issues = guard.validate_version_progression("PA.0.2.0", "PA.0.1.0")

        self.assertEqual([issue.code for issue in issues], ["invalid-version-progression"])


if __name__ == "__main__":
    unittest.main()
