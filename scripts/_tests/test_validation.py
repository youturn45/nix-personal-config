"""Recovery command spies and shared no-build validation contract."""
import importlib.util
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def load_validator():
    spec = importlib.util.spec_from_file_location("shared_validation", ROOT / "scripts/validate.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RecoveryTests(unittest.TestCase):
    def spy(self, platform, recipe):
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            log = tmp / "calls"
            for command in ("sudo", "nix", "nix-env", "darwin-rebuild"):
                script = tmp / command
                script.write_text('#!/bin/sh\nprintf "%s\\n" "' + command + ' $*" >> "$SPY_LOG"\n')
                script.chmod(0o700)
            uname = tmp / "uname"
            uname.write_text(f"#!/bin/sh\nprintf '%s\\n' {platform}\n")
            uname.chmod(0o700)
            env = dict(os.environ, PATH=f"{tmp}:{os.environ['PATH']}", SPY_LOG=str(log))
            just = shutil.which("just")
            self.assertIsNotNone(just, "just is required for recovery command-spy coverage")
            result = subprocess.run([str(just), "--justfile", str(ROOT / "Justfile"), recipe],
                                    cwd=ROOT, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return log.read_text()

    def test_darwin_rollback(self):
        self.assertEqual(self.spy("Darwin", "rollback"), "sudo darwin-rebuild --rollback\n")

    def test_linux_rollback(self):
        self.assertEqual(self.spy("Linux", "rollback"), "sudo nixos-rebuild switch --rollback\n")

    def test_darwin_generations(self):
        self.assertEqual(self.spy("Darwin", "generations"), "darwin-rebuild --list-generations\n")

    def test_linux_generations(self):
        self.assertEqual(self.spy("Linux", "generations"), "nix-env --list-generations --profile /nix/var/nix/profiles/system\n")


class ProxyRecipeTests(unittest.TestCase):
    def test_smart_proxy_never_echoes_endpoint_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sudo = root / 'sudo'
            sudo.write_text('#!/bin/sh\nexit 0\n')
            sudo.chmod(0o700)
            uname = root / 'uname'
            for platform in ('Darwin', 'Linux'):
                uname.write_text(f'#!/bin/sh\necho {platform}\n')
                uname.chmod(0o700)
                env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                           http_proxy='http://fixture:FIXTURE_CREDENTIAL@127.0.0.1:7890')
                result = subprocess.run(['just', '--justfile', str(ROOT / 'Justfile'), 'smart-proxy', 'auto'],
                                        env=env, cwd=ROOT, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn('FIXTURE_CREDENTIAL', result.stdout + result.stderr)


class ValidationTests(unittest.TestCase):
    def run_validator(self, args=(), fail=None):
        module = load_validator()
        calls = []
        temp_paths = []

        def run(command, **kwargs):
            calls.append(command)
            if "stdout" in kwargs:
                temp_paths.append(Path(kwargs["stdout"].name))
                self.assertEqual(temp_paths[-1].stat().st_mode & 0o777, 0o600)
                self.assertEqual(temp_paths[-1].parent.stat().st_mode & 0o777, 0o700)
            if "_tests/run.py" in command:
                self.assertEqual(kwargs["env"]["PYTHONDONTWRITEBYTECODE"], "1")
                self.assertEqual(kwargs["env"]["RELIABILITY_GENERATED_JSON"], str(temp_paths[-1]))
            if fail and fail(command):
                raise subprocess.CalledProcessError(23, command)
            return subprocess.CompletedProcess(command, 0)

        with patch.object(module.subprocess, "run", side_effect=run):
            status = module.main(list(args))
        self.assertTrue(all(not path.exists() for path in temp_paths), "generated data leaked")
        return status, calls

    def test_default_all_coverage_and_strict_tests(self):
        status, calls = self.run_validator()
        self.assertEqual(status, 0)
        text = "\n".join(" ".join(command) for command in calls)
        for target in ("Rorschach.system.drvPath", "NightOwl.system.drvPath", "SilkSpectre.system.drvPath",
                       "ozymandias.config.system.build.toplevel.drvPath", "ozymandias-iso.drvPath", "_tests/run.py"):
            self.assertIn(target, text)
        for command in calls:
            if command[0] == "nix":
                self.assertIn("--no-write-lock-file", command)
                self.assertNotIn("build", command)
                self.assertNotIn("fmt", command, "nix fmt may build a formatter")
        self.assertIn("--no-build", text)

    def test_scoped_host(self):
        status, calls = self.run_validator(["--host", "Rorschach"])
        self.assertEqual(status, 0)
        text = str(calls)
        self.assertIn("Rorschach.system.drvPath", text)
        self.assertNotIn("NightOwl.config", text)
        self.assertNotIn("ozymandias-iso", text)

    def test_linux_scope(self):
        status, calls = self.run_validator(["--platform", "linux", "--offline"])
        self.assertEqual(status, 0)
        self.assertNotIn("darwinConfigurations", str(calls))
        for command in calls:
            if command[0] == "nix":
                self.assertIn("--offline", command)

    def test_failure_propagates(self):
        for fail in (lambda c: "check" in c,
                     lambda c: "Rorschach.system.drvPath" in str(c),
                     lambda c: "SilkSpectre.system.drvPath" in str(c),
                     lambda c: "toplevel.drvPath" in str(c),
                     lambda c: "ozymandias-iso.drvPath" in str(c),
                     lambda c: "--apply" in c,
                     lambda c: "_tests/run.py" in str(c)):
            with self.subTest(fail=fail):
                status, _ = self.run_validator(fail=fail)
                self.assertEqual(status, 23)


class StrictContractTests(unittest.TestCase):
    def runner(self):
        spec = importlib.util.spec_from_file_location("strict_regressions", ROOT / "_tests/run.py")
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_projection_schema_and_docs_stay_synchronized(self):
        module = self.runner()
        projection = (ROOT / "_tests/generated-input.nix").read_text()
        docs = (ROOT / "_tests/README.md").read_text()
        for key in module.REQUIRED_KEYS:
            self.assertIn(f"{key} =", projection)
            self.assertIn(f"`{key}`", docs)
        self.assertEqual(module.SUITES, ("_tests", "scripts/_tests", "modules/darwin/mihomo/_tests"))

    def test_required_fields_reject_missing_empty_and_nonstring(self):
        module = self.runner()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "schema-fixture.json"
            with patch.dict(os.environ, RELIABILITY_GENERATED_JSON=str(path)):
                for key in module.REQUIRED_KEYS:
                    for invalid in (None, "", 1):
                        # This is a schema-only fixture, never generated configuration.
                        data: dict[str, object] = dict.fromkeys(module.REQUIRED_KEYS, "schema-test")
                        if invalid is None:
                            del data[key]
                        else:
                            data[key] = invalid
                        path.write_text(json.dumps(data))
                        with self.assertRaises(ValueError):
                            module.validate_input()

    def test_strict_runner_rejects_skips_empty_failures_and_errors(self):
        successful = self.runner().successful
        for kind in ("empty", "skip", "failure", "error", "pass"):
            result = unittest.TestResult()
            if kind != "empty":
                result.testsRun = 1
            if kind == "skip":
                result.skipped.append((self, "not allowed"))
            if kind == "failure":
                result.failures.append((self, "failure"))
            if kind == "error":
                result.errors.append((self, "error"))
            self.assertEqual(successful(result), kind == "pass", kind)


if __name__ == "__main__":
    unittest.main()
