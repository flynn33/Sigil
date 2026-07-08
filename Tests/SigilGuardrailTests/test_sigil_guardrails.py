import importlib.util
import json
import pathlib
import tempfile
import unittest


SCRIPT_PATH = pathlib.Path(__file__).resolve().parents[2] / "tools" / "sigil_guardrails" / "verify_sigil_guardrails.py"


def load_guardrails():
    spec = importlib.util.spec_from_file_location("sigil_guardrails", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def text(hex_value):
    return bytes.fromhex(hex_value).decode("utf-8")


def write_policy(root):
    policy = {
        "blocked_project_patterns": {
            "attribution_marker_hex": [
                "47656e657261746564206279",
                "41492d67656e657261746564",
                "436f646578",
            ],
            "ash_misuse_marker_hex": [
                "5b382c342c345d",
            ],
            "forsetti_internal_copy_paths": [
                "Sources/ForsettiCore",
            ],
        },
        "required_evidence_files": [
            "ProjectEvidence/source-authority-map.md",
        ],
    }
    policy_path = root / "tools" / "sigil_guardrails" / "sigil_guardrail_policy.json"
    policy_path.parent.mkdir(parents=True)
    policy_path.write_text(json.dumps(policy), encoding="utf-8")
    return policy_path


class SigilGuardrailTests(unittest.TestCase):
    def test_clean_project_passes(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)
            evidence = root / "ProjectEvidence" / "source-authority-map.md"
            evidence.parent.mkdir()
            evidence.write_text("source authority mapped\n", encoding="utf-8")

            failures = guardrails.verify_project(root, policy_path, strict=True, include_git=False)

        self.assertEqual(failures, [])

    def test_encoded_attribution_marker_fails(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)
            (root / "notes.md").write_text(text("47656e657261746564206279") + " tool\n", encoding="utf-8")

            failures = guardrails.verify_project(root, policy_path, strict=True, include_git=False)

        self.assertEqual([failure.code for failure in failures], ["blocked-attribution-marker", "missing-evidence"])

    def test_project_domain_compound_terms_do_not_trigger_attribution_marker(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)
            (root / "notes.md").write_text(
                text("506572736f6e616c436f6465782072656d61696e7320756e617661696c61626c652e") + "\n",
                encoding="utf-8",
            )

            failures = guardrails.verify_project(root, policy_path, strict=False, include_git=False)

        self.assertEqual(failures, [])

    def test_source_ash_misuse_marker_fails(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)
            source = root / "Sources" / "Example.swift"
            source.parent.mkdir(parents=True)
            source.write_text("let marker = \"{}\"\n".format(text("5b382c342c345d")), encoding="utf-8")

            failures = guardrails.verify_project(root, policy_path, strict=True, include_git=False)

        self.assertEqual([failure.code for failure in failures], ["blocked-ash-marker", "missing-evidence"])

    def test_copied_forsetti_internal_path_fails(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)
            source = root / "Sources" / "ForsettiCore" / "Internal.swift"
            source.parent.mkdir(parents=True)
            source.write_text("public enum Internal {}\n", encoding="utf-8")

            failures = guardrails.verify_project(root, policy_path, strict=True, include_git=False)

        self.assertEqual([failure.code for failure in failures], ["blocked-path", "missing-evidence"])

    def test_missing_required_evidence_fails_in_strict_mode(self):
        guardrails = load_guardrails()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            policy_path = write_policy(root)

            failures = guardrails.verify_project(root, policy_path, strict=True, include_git=False)

        self.assertEqual([failure.code for failure in failures], ["missing-evidence"])


if __name__ == "__main__":
    unittest.main()
