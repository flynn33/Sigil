import importlib.util
import pathlib
import tempfile
import unittest


SCRIPT_PATH = pathlib.Path(__file__).resolve().parents[2] / "scripts" / "attribution_guard.py"


def load_guard():
    spec = importlib.util.spec_from_file_location("attribution_guard", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def text(hex_value):
    return bytes.fromhex(hex_value).decode("utf-8")


class AttributionGuardTests(unittest.TestCase):
    def test_branch_name_rejects_encoded_token(self):
        guard = load_guard()

        result = guard.scan_targets(
            branch_name=text("666561747572652f61692d68656c706572"),
            paths=[],
            repo_root=pathlib.Path.cwd(),
        )

        self.assertEqual([item.surface for item in result], ["branch"])

    def test_file_name_rejects_encoded_phrase(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            path = root / text("646f63732f67656e6572617465642d62792d61692e6d64")
            path.parent.mkdir(parents=True)
            path.write_text("plain text\n", encoding="utf-8")

            result = guard.scan_targets(branch_name="main", paths=[path], repo_root=root)

        self.assertEqual([item.surface for item in result], ["path"])

    def test_file_content_rejects_encoded_phrase(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            path = root / "notes.md"
            path.write_text(text("47656e657261746564206279204149") + "\n", encoding="utf-8")

            result = guard.scan_targets(branch_name="main", paths=[path], repo_root=root)

        self.assertEqual([item.surface for item in result], ["content"])

    def test_pull_request_text_rejects_encoded_phrase(self):
        guard = load_guard()

        result = guard.scan_targets(
            branch_name="main",
            paths=[],
            repo_root=pathlib.Path.cwd(),
            text_targets=[("pull request title", text("417373697374656420627920436f646578"))],
        )

        self.assertEqual([item.surface for item in result], ["pull request title"])

    def test_project_domain_terms_do_not_trigger(self):
        guard = load_guard()

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            path = root / "notes.md"
            path.write_text(text("506572736f6e616c436f6465782072656d61696e7320756e617661696c61626c6520696e20506861736520312e") + "\n", encoding="utf-8")

            result = guard.scan_targets(branch_name="main", paths=[path], repo_root=root)

        self.assertEqual(result, [])


if __name__ == "__main__":
    unittest.main()
