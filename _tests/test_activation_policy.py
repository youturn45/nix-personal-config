"""Activation policy and strict-runner tests. Fixtures never touch a real home."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
NODE_MODULE = ROOT / "home/common/dev-tools/nodejs/default.nix"


class NpmSourcePolicyTests(unittest.TestCase):
    def test_no_registry_installer_in_activation(self):
        source = NODE_MODULE.read_text()
        self.assertNotIn("home.activation.installNpm", source)
        self.assertNotIn("npm install -g npm@", source)
        self.assertIn("pkgs-unstable.nodejs_latest", source)
        self.assertIn('export PATH="$PATH:', source)


class NpmActivationTests(unittest.TestCase):
    def setUp(self):
        path = os.environ.get("RELIABILITY_GENERATED_JSON")
        if not path:
            self.skipTest("requires actual generated input; see _tests/README.md")
        self.generated = json.loads(Path(path).read_text())
        if not all(key in self.generated for key in ("username", "npm_setup", "npm_install_present")):
            self.skipTest("generated input lacks npm activation fields")
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name).resolve() / "home"
        self.home.mkdir()
        self.script = self.generated["npm_setup"].replace(
            "/Users/" + self.generated["username"], str(self.home))
        self.assertNotIn("/Users/", self.script)

    def run_setup(self, dry_run):
        return subprocess.run(
            [shutil.which("bash") or "/bin/bash", "-eu", "-c", self.script],
            env={"HOME": str(self.home), "PATH": "/usr/bin:/bin", "DRY_RUN_CMD": dry_run},
            cwd=self.home, text=True, capture_output=True, check=True,
        )

    def test_no_effective_npm_install_activation(self):
        self.assertEqual(self.generated["npm_install_present"], "no")

    def test_dry_run_does_not_create_directories(self):
        self.run_setup("echo")
        self.assertFalse((self.home / ".npm-global").exists())
        self.assertFalse((self.home / ".npm-cache").exists())

    def test_normal_setup_creates_only_npm_directories(self):
        self.run_setup("")
        self.assertEqual(sorted(p.name for p in self.home.iterdir()), [".npm-cache", ".npm-global"])


class StrictRunnerTests(unittest.TestCase):
    def test_results_require_execution_and_no_skips(self):
        spec = importlib.util.spec_from_file_location("strict_reliability_runner", ROOT / "_tests/run.py")
        assert spec is not None and spec.loader is not None
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        for count, skipped, ok, expected in (
            (0, [], True, False), (1, [("case", "missing prerequisite")], True, False),
            (1, [], False, False), (1, [], True, True),
        ):
            with self.subTest(count=count, skipped=skipped, ok=ok):
                result = type("Result", (), {"testsRun": count, "skipped": skipped,
                    "wasSuccessful": lambda self, value=ok: value})()
                self.assertEqual(runner.successful(result), expected)

    def test_missing_generated_input_fails_before_discovery(self):
        env = dict(os.environ)
        env.pop("RELIABILITY_GENERATED_JSON", None)
        result = subprocess.run([sys.executable, str(ROOT / "_tests/run.py")],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("INCOMPLETE", result.stderr)


if __name__ == "__main__":
    unittest.main()
