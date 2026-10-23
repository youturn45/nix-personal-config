"""Strict CI entry point: actual generated input, all suites, no skips allowed."""
import json
import os
from pathlib import Path
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
REQUIRED_KEYS = (
    "username", "activation", "autoLoginUser", "mihomo_sync",
    "management_commands", "npm_setup", "npm_install_present",
    "git_activation", "claude_settings_activation", "claude_runtime_activation",
    "codex_activation", "shell_init", "shell_proxy_default", "mihomo_daemon",
)
SUITES = ("_tests", "scripts/_tests", "modules/darwin/mihomo/_tests")


def validate_input():
    path = os.environ.get("RELIABILITY_GENERATED_JSON")
    if not path:
        raise ValueError("RELIABILITY_GENERATED_JSON is required; see _tests/README.md")
    data = json.loads(Path(path).read_text())
    if not isinstance(data, dict):
        raise ValueError("generated input must be a JSON object")
    for key in REQUIRED_KEYS:
        if key not in data or not isinstance(data[key], str) or not data[key]:
            raise ValueError(f"generated input requires nonempty string key: {key}")
    for tool in ("git", "just"):
        if not shutil.which(tool):
            raise ValueError(f"{tool} is required for behavioral coverage")


def successful(result):
    return result.testsRun > 0 and result.wasSuccessful() and not result.skipped


def main():
    try:
        validate_input()
    except (OSError, ValueError) as exc:
        print(f"INCOMPLETE: {exc}", file=sys.stderr)
        return 2
    suite = unittest.TestSuite()
    for relative in SUITES:
        discovered = unittest.TestLoader().discover(str(ROOT / relative))
        if discovered.countTestCases() == 0:
            print(f"INCOMPLETE: no tests discovered in {relative}", file=sys.stderr)
            return 2
        suite.addTests(discovered)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.skipped:
        print("INCOMPLETE: strict checks reject skipped tests", file=sys.stderr)
    return 0 if successful(result) else 1


if __name__ == "__main__":
    raise SystemExit(main())
