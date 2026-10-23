"""Regression tests for generated shell scripts and activation invariants.

Covers the mihomo activation bootstrap, the sole management command
`mihomo-sync`, and the NightOwl loginwindow autologin option.

Behavior tests run only against real pre-evaluated Nix output: set
RELIABILITY_GENERATED_JSON to a JSON file with the string keys
  "username"       config.system.primaryUser
  "activation"     config.system.activationScripts.script.text (NightOwl)
  "autoLoginUser"  config.system.defaults.loginwindow.autoLoginUser
  "mihomo_sync"    text of the mihomo-sync system package
  "management_commands" newline-separated evaluated management package names
See _tests/README.md for the exact `nix eval` command. Without it those tests
are skipped; nothing here renders or fabricates Nix output. Source invariant
tests read the .nix files directly and always run.

Every script is rewritten to run inside a temp sandbox: the home directory,
Git remote, sudo, launchctl, id, chown and the iCloud export helper are
all replaced by temp paths or recording fakes, and the rewritten script is
checked for leftover real targets before it runs. Git tests use disposable
local repositories only; nothing touches the network.
"""

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MIHOMO_NIX = REPO_ROOT / "modules/darwin/mihomo/default.nix"
RETIRED_MODULE = REPO_ROOT / "home/common/system/clash-sync/default.nix"
SERVER_NIX = REPO_ROOT / "hosts/darwin/NightOwl/server.nix"

GENERATED_ENV = "RELIABILITY_GENERATED_JSON"
GENERATED_KEYS = ("username", "activation", "autoLoginUser", "mihomo_sync", "management_commands")
REAL_REPO_URL = "git@github.com:youturn45/clash.meta.git"
MIHOMO_DAEMON_LOAD = (
    "launchctl load -w '/Library/LaunchDaemons/io.github.metacubex.mihomo.plist'"
)
ACTIVATION_ANCHOR = "system.activationScripts.launchd.text = lib.mkBefore ''"
STORE_TOOL = re.compile(r"/nix/store/[0-9a-z]{32}-[^/\s'\"]+/bin/(git|python3|mihomo)\b")
REAL_GIT = shutil.which("git")


# --- Generated (pre-evaluated) inputs ---------------------------------------

def load_generated():
    path = os.environ.get(GENERATED_ENV)
    if not path:
        return {}
    data = json.loads(Path(path).read_text())
    if not isinstance(data, dict):
        raise ValueError(f"{GENERATED_ENV}: expected a JSON object")
    for key, value in data.items():
        if not isinstance(value, str):
            raise ValueError(f"{GENERATED_ENV}: key {key!r} must be a string")
    return data


GENERATED = load_generated()


def require_generated(*keys):
    """Return the generated values for keys, or skip with how to produce them."""
    missing = [key for key in keys if key not in GENERATED]
    if missing:
        raise unittest.SkipTest(
            f"needs {GENERATED_ENV} with key(s) {', '.join(missing)}; "
            "generate it with the nix eval command in _tests/README.md"
        )
    return [GENERATED[key] for key in keys]


def mihomo_activation_block(text):
    """Cut the mihomo bootstrap block (bootout through clone) from a script."""
    start = text.rindex("\n", 0, text.index("mihomo_user=")) + 1
    i = text.index("FATAL: git clone", start)
    for _ in range(2):
        i = re.compile(r"^\s*fi\s*$", re.M).search(text, i).end()
    return text[start:i] + "\n"


def script_source(key):
    """Return (script text, username) from the generated JSON, or skip."""
    username, = require_generated("username")
    if key == "activation_block":
        text, = require_generated("activation")
        return mihomo_activation_block(text), username
    text, = require_generated(key)
    return text, username


def nix_activation_source():
    """The literal mihomo activation fragment as written in the .nix source."""
    source = MIHOMO_NIX.read_text()
    start = source.index(ACTIVATION_ANCHOR) + len(ACTIVATION_ANCHOR)
    return source[start:source.index("\n  '';", start)]


# --- Sandbox -----------------------------------------------------------------

FAKES = {
    "mihomo": """#!/bin/bash
printf 'validate %s\\n' "$*" >> "$FAKE_LOG"
exit "${FAKE_VALIDATION_STATUS:-0}"
""",
    "sudo": """#!/bin/bash
printf 'sudo %s\\n' "$*" >> "$FAKE_LOG"
while [ $# -gt 0 ]; do
  case "$1" in -u|-g) shift 2 ;; --) shift; break ;; -*) shift ;; *) break ;; esac
done
exec env "$@"
""",
    "launchctl": """#!/bin/bash
printf 'launchctl %s\\n' "$*" >> "$FAKE_LOG"
exit "${FAKE_LAUNCHCTL_STATUS:-0}"
""",
    "id": """#!/bin/bash
printf 'id %s\\n' "$*" >> "$FAKE_LOG"
echo 501
""",
    "chown": """#!/bin/bash
printf 'chown %s\\n' "$*" >> "$FAKE_LOG"
exit "${FAKE_CHOWN_STATUS:-0}"
""",
    "python3": """#!/bin/bash
printf 'export %s\\n' "$*" >> "$FAKE_LOG"
exit "${FAKE_EXPORT_STATUS:-0}"
""",
}

GITCONFIG = """[user]
\tname = Reliability Test
\temail = test@example.invalid
[init]
\tdefaultBranch = main
[protocol "file"]
\tallow = always
[advice]
\tdetachedHead = false
"""


class Sandbox:
    """Temp home, fake tools, a bare 'remote' repo and a working upstream clone."""

    def __init__(self, root):
        self.root = Path(root).resolve()
        self.home = self.root / "home"
        self.fakebin = self.root / "fakebin"
        self.log = self.root / "fake.log"
        self.remote = self.root / "remote.git"
        self.upstream = self.root / "upstream-work"
        self.home.mkdir()
        self.fakebin.mkdir()
        self.log.touch()
        for name, body in FAKES.items():
            path = self.fakebin / name
            path.write_text(body)
            path.chmod(0o755)
        (self.root / "gitconfig").write_text(GITCONFIG)
        self.env = {
            "PATH": f"{self.fakebin}:{os.environ.get('PATH', '/usr/bin:/bin')}",
            "HOME": str(self.home),
            "FAKE_LOG": str(self.log),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": str(self.root / "gitconfig"),
            "GIT_TERMINAL_PROMPT": "0",
            "LANG": "C",
            "TMPDIR": str(self.root),
        }

    @property
    def config_dir(self):
        return self.home / ".config/clash.meta"

    @property
    def icloud_drive(self):
        return self.home / "Library/Mobile Documents/com~apple~CloudDocs"

    def git(self, cwd, *args, check=True):
        return subprocess.run(
            [REAL_GIT, *args], cwd=cwd, env=self.env, check=check,
            capture_output=True, text=True,
        )

    def head(self, repo, ref="HEAD"):
        return self.git(repo, "rev-parse", ref).stdout.strip()

    def init_remote(self):
        self.git(self.root, "init", "--bare", "-q", str(self.remote))
        self.git(self.root, "clone", "-q", str(self.remote), str(self.upstream))
        (self.upstream / "ruleset").mkdir()
        self.commit_upstream({"config.yaml": "mode: rule\n",
                              "ruleset/a.yaml": "payload: []\n"}, "initial")

    def commit_upstream(self, files, message, branch="main"):
        current = self.git(self.upstream, "symbolic-ref", "--short", "HEAD").stdout.strip()
        if current != branch:
            exists = self.git(self.upstream, "rev-parse", "--verify", "-q",
                              f"refs/heads/{branch}", check=False).returncode == 0
            self.git(self.upstream, "checkout", "-q", *([] if exists else ["-b"]), branch)
        for rel, content in files.items():
            (self.upstream / rel).write_text(content)
        self.git(self.upstream, "add", "-A")
        self.git(self.upstream, "commit", "-q", "-m", message)
        self.git(self.upstream, "push", "-q", "origin", f"HEAD:{branch}")
        return self.head(self.upstream)

    def clone_local(self):
        self.config_dir.parent.mkdir(parents=True, exist_ok=True)
        self.git(self.root, "clone", "-q", str(self.remote), str(self.config_dir))

    def localize(self, script, username, repo_url=None):
        """Point every real target in a script at sandbox paths or fakes."""
        replacements = {
            "/usr/bin/sudo": str(self.fakebin / "sudo"),
            "/bin/launchctl": str(self.fakebin / "launchctl"),
            "/usr/bin/id": str(self.fakebin / "id"),
            "/usr/sbin/chown": str(self.fakebin / "chown"),
            REAL_REPO_URL: str(repo_url or self.remote),
            f"/Users/{username}": str(self.home),
        }
        for old, new in replacements.items():
            script = script.replace(old, new)
        tools = {"git": REAL_GIT, "python3": str(self.fakebin / "python3"),
                 "mihomo": str(self.fakebin / "mihomo")}
        script = STORE_TOOL.sub(lambda m: tools[m.group(1)], script)
        self.assert_sandboxed(script, username)
        return script

    def assert_sandboxed(self, script, username):
        stripped = script.replace(str(self.root), "<sandbox>")
        for target in ("/usr/bin/sudo", "/bin/launchctl", "/usr/sbin/chown",
                       "/usr/bin/id", "github.com", f"/Users/{username}"):
            if target in stripped:
                raise AssertionError(f"script still references real target {target}")
        if STORE_TOOL.search(stripped):
            raise AssertionError("script still references a Nix store tool")

    def run(self, script, extra_env=None, prelude=""):
        path = self.root / "under-test.sh"
        path.write_text(prelude + script)
        env = dict(self.env, **(extra_env or {}))
        return subprocess.run(
            ["bash", str(path)], cwd=self.root, env=env,
            capture_output=True, text=True, timeout=120,
        )

    def calls(self, prefix=None):
        lines = self.log.read_text().splitlines()
        return [line for line in lines if prefix is None or line.startswith(prefix + " ")]


@unittest.skipUnless(REAL_GIT, "git is required for disposable repositories")
class SandboxTestCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.box = Sandbox(tmp.name)
        self.box.init_remote()


# --- Canonical mihomo-sync Git safety ----------------------------------------

class MihomoGitSafetyTests(SandboxTestCase):
    def setUp(self):
        text, username = script_source("mihomo_sync")
        super().setUp()
        self.script = self.box.localize(text, username)

    def run_sync(self):
        return self.box.run(self.script)

    def assert_stopped_before_copy(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Nothing was copied or restarted", result.stderr)
        self.assertEqual(self.box.calls("export"), [])
        self.assertEqual(self.box.calls("launchctl"), [])

    def test_dirty_tracked_change_preserved_and_stops(self):
        self.box.clone_local()
        old_head = self.box.head(self.box.config_dir)
        self.box.commit_upstream({"config.yaml": "mode: global\n"}, "update")
        (self.box.config_dir / "config.yaml").write_text("mode: local-edit\n")
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertIn("uncommitted or untracked", result.stderr)
        self.assertEqual((self.box.config_dir / "config.yaml").read_text(), "mode: local-edit\n")
        self.assertEqual(self.box.head(self.box.config_dir), old_head)

    def test_dirty_untracked_file_preserved_and_stops(self):
        self.box.clone_local()
        old_head = self.box.head(self.box.config_dir)
        self.box.commit_upstream({"config.yaml": "mode: global\n"}, "update")
        (self.box.config_dir / "ruleset/mine.yaml").write_text("payload: [x]\n")
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertEqual((self.box.config_dir / "ruleset/mine.yaml").read_text(), "payload: [x]\n")
        self.assertEqual(self.box.head(self.box.config_dir), old_head)

    def test_divergent_history_preserved_and_stops(self):
        self.box.clone_local()
        (self.box.config_dir / "config.yaml").write_text("mode: local-commit\n")
        self.box.git(self.box.config_dir, "commit", "-q", "-am", "local")
        local_head = self.box.head(self.box.config_dir)
        self.box.commit_upstream({"config.yaml": "mode: global\n"}, "upstream")
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertEqual(self.box.head(self.box.config_dir), local_head)
        self.assertEqual((self.box.config_dir / "config.yaml").read_text(), "mode: local-commit\n")

    def test_failed_remote_stops_before_copy(self):
        self.box.clone_local()
        old_head = self.box.head(self.box.config_dir)
        self.box.git(self.box.config_dir, "remote", "set-url", "origin",
                     str(self.box.root / "missing-remote.git"))
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertEqual(self.box.head(self.box.config_dir), old_head)

    def test_uses_current_branch_upstream_without_guessing(self):
        self.box.commit_upstream({"feature.yaml": "a: 1\n"}, "feature", branch="feature")
        self.box.clone_local()
        self.box.git(self.box.config_dir, "checkout", "-q", "-b", "feature", "origin/feature")
        main_before = self.box.head(self.box.config_dir, "main")
        feature_head = self.box.commit_upstream({"feature.yaml": "a: 2\n"}, "f2", branch="feature")
        self.box.commit_upstream({"config.yaml": "mode: main-moved\n"}, "m2", branch="main")
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.head(self.box.config_dir), feature_head)
        self.assertEqual(self.box.head(self.box.config_dir, "main"), main_before)

    def test_detached_head_without_upstream_stops(self):
        self.box.clone_local()
        self.box.git(self.box.config_dir, "checkout", "-q", "--detach")
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertIn("no upstream", result.stderr)

    def test_first_use_clones(self):
        head = self.box.head(self.box.upstream)
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.head(self.box.config_dir), head)
        self.assertEqual(len(self.box.calls("export")), 1)
        self.assertTrue(self.box.calls("launchctl"))

    def test_failed_first_clone_stops_before_copy(self):
        text, username = script_source("mihomo_sync")
        script = self.box.localize(text, username,
                                   repo_url=self.box.root / "missing-remote.git")
        result = self.box.run(script)
        self.assert_stopped_before_copy(result)

    def test_existing_non_git_config_is_not_overwritten(self):
        self.box.config_dir.mkdir(parents=True)
        config = self.box.config_dir / "config.yaml"
        config.write_text("mode: personal-config\n")
        result = self.run_sync()
        self.assert_stopped_before_copy(result)
        self.assertEqual(config.read_text(), "mode: personal-config\n")
        self.assertFalse((self.box.config_dir / ".git").exists())

    def test_ignored_runtime_cache_does_not_block_sync(self):
        self.box.commit_upstream({".gitignore": "cache.db\n"}, "ignore runtime cache")
        self.box.clone_local()
        cache = self.box.config_dir / "cache.db"
        cache.write_text("runtime state\n")
        expected = self.box.commit_upstream({"config.yaml": "mode: global\n"}, "update")
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.head(self.box.config_dir), expected)
        self.assertEqual(cache.read_text(), "runtime state\n")
        self.assertEqual(len(self.box.calls("export")), 1)

    def test_no_destructive_git_or_copy_flags(self):
        for pattern in (r"--delete", r"reset\s+--hard", r"\bgit\b[^\n]*\bclean\b",
                        r"\bstash\b", r"pull origin (main|master)", r"fetch origin"):
            self.assertNotRegex(self.script, pattern)
        self.assertIn("pull --ff-only", self.script)

# --- mihomo-sync (iCloud export preserved, mocked) ---------------------------

class MihomoSyncTests(SandboxTestCase):
    def setUp(self):
        text, username = script_source("mihomo_sync")
        super().setUp()
        self.script = self.box.localize(text, username)
        self.box.clone_local()

    def test_pull_then_export_then_restart(self):
        new_head = self.box.commit_upstream({"config.yaml": "mode: global\n"}, "update")
        result = self.box.run(self.script)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.head(self.box.config_dir), new_head)
        exports = self.box.calls("export")
        self.assertEqual(len(exports), 1)
        self.assertIn(f"--source {self.box.config_dir}", exports[0])
        self.assertIn(str(self.box.icloud_drive / "Mihomo"), exports[0])
        self.assertTrue(any("kickstart" in c for c in self.box.calls("launchctl")))
        calls = self.box.calls()
        validation = next(i for i, line in enumerate(calls) if line.startswith("validate "))
        export = next(i for i, line in enumerate(calls) if line.startswith("export "))
        service = next(i for i, line in enumerate(calls) if line.startswith("launchctl "))
        self.assertLess(validation, export)
        self.assertLess(export, service)

    def test_invalid_config_skips_export_and_restart_without_resetting_checkout(self):
        expected = self.box.commit_upstream({"config.yaml": "mode: [\n"}, "invalid config")
        result = self.box.run(self.script, {"FAKE_VALIDATION_STATUS": "4"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("config validation failed", result.stderr)
        self.assertEqual(self.box.calls("export"), [])
        self.assertEqual(self.box.calls("launchctl"), [])
        self.assertEqual(len(self.box.calls("validate")), 1)
        self.assertIn(f"-t -d {self.box.config_dir}", self.box.calls("validate")[0])
        self.assertEqual(self.box.head(self.box.config_dir), expected)

    def test_failed_pull_skips_export_and_restart(self):
        (self.box.config_dir / "config.yaml").write_text("mode: local-commit\n")
        self.box.git(self.box.config_dir, "commit", "-q", "-am", "local")
        self.box.commit_upstream({"config.yaml": "mode: global\n"}, "upstream")
        result = self.box.run(self.script)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.box.calls("validate"), [])
        self.assertEqual(self.box.calls("export"), [])
        self.assertEqual(self.box.calls("launchctl"), [])

    def test_export_failure_still_restarts_but_fails(self):
        result = self.box.run(self.script, {"FAKE_EXPORT_STATUS": "3"})
        self.assertEqual(result.returncode, 3)
        self.assertIn("iCloud copy failed", result.stderr)
        self.assertTrue(any("kickstart" in c for c in self.box.calls("launchctl")))


# --- mihomo activation bootstrap (behavior) ----------------------------------

class MihomoActivationBlockTests(SandboxTestCase):
    # nix-darwin runs activation with these options.
    PRELUDE = "set -e\nset -o pipefail\n"

    def setUp(self):
        text, username = script_source("activation_block")
        super().setUp()
        self.username = username
        self.script = self.box.localize(text, username)
        self.log_dir = self.box.home / "Library/Logs/mihomo"
        (self.box.home / ".ssh").mkdir()
        (self.box.home / ".ssh/Youturn").write_text("fake key\n")

    def run_block(self, extra_env=None, script=None):
        return self.box.run(script or self.script, extra_env, prelude=self.PRELUDE)

    def expected_chown(self):
        return (f"chown {self.username}:staff {self.log_dir} "
                f"{self.log_dir}/mihomo.log {self.log_dir}/mihomo.error.log")

    def assert_log_setup_refused(self, result, reason):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("FATAL: could not prepare log directory", result.stderr)
        self.assertIn(reason, result.stderr)
        self.assertEqual(self.box.calls("chown"), [])
        self.assertEqual(self.box.calls("sudo"), [])

    def test_bootout_logs_and_clone_once(self):
        result = self.run_block()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        launchctl = self.box.calls("launchctl")
        self.assertIn("launchctl bootout gui/501/io.github.metacubex.mihomo", launchctl)
        self.assertTrue((self.log_dir / "mihomo.log").is_file())
        self.assertTrue((self.log_dir / "mihomo.error.log").is_file())
        self.assertEqual(self.box.calls("chown"), [self.expected_chown()])
        self.assertTrue((self.box.config_dir / ".git").is_dir())
        self.assertEqual(len([c for c in self.box.calls("sudo") if " clone " in c]), 1)

    def test_unrelated_log_content_is_not_chowned(self):
        (self.log_dir / "archive").mkdir(parents=True)
        (self.log_dir / "archive/old.log").write_text("old\n")
        (self.log_dir / "mihomo.log").write_text("existing\n")
        result = self.run_block()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.calls("chown"), [self.expected_chown()])
        self.assertEqual((self.log_dir / "mihomo.log").read_text(), "existing\n")

    def test_symlinked_log_root_is_refused(self):
        elsewhere = self.box.root / "elsewhere"
        elsewhere.mkdir()
        self.log_dir.parent.mkdir(parents=True)
        self.log_dir.symlink_to(elsewhere)
        result = self.run_block()
        self.assert_log_setup_refused(result, "symlink or not a directory")
        self.assertEqual(list(elsewhere.iterdir()), [])

    def test_non_directory_log_root_is_refused(self):
        self.log_dir.parent.mkdir(parents=True)
        self.log_dir.write_text("not a dir\n")
        result = self.run_block()
        self.assert_log_setup_refused(result, "symlink or not a directory")

    def test_symlinked_log_file_is_refused(self):
        for name in ("mihomo.log", "mihomo.error.log"):
            with self.subTest(name=name):
                shutil.rmtree(self.log_dir, ignore_errors=True)
                self.box.log.write_text("")
                target = self.box.root / f"target-{name}"
                target.write_text("not yours\n")
                self.log_dir.mkdir(parents=True)
                (self.log_dir / name).symlink_to(target)
                result = self.run_block()
                self.assert_log_setup_refused(result, "symlink or not a regular file")
                self.assertEqual(target.read_text(), "not yours\n")

    def test_non_regular_log_file_is_refused(self):
        (self.log_dir / "mihomo.error.log").mkdir(parents=True)
        result = self.run_block()
        self.assert_log_setup_refused(result, "symlink or not a regular file")

    def test_existing_checkout_is_not_recloned_or_updated(self):
        self.box.clone_local()
        old_head = self.box.head(self.box.config_dir)
        self.box.commit_upstream({"config.yaml": "mode: global\n"}, "update")
        result = self.run_block()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.box.calls("sudo"), [])
        self.assertEqual(self.box.head(self.box.config_dir), old_head)

    def test_missing_ssh_key_is_fatal(self):
        (self.box.home / ".ssh/Youturn").unlink()
        result = self.run_block()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FATAL", result.stderr)
        self.assertIn("SSH key", result.stderr)
        self.assertEqual(self.box.calls("sudo"), [])

    def test_clone_failure_is_fatal(self):
        text, username = script_source("activation_block")
        script = self.box.localize(text, username,
                                   repo_url=self.box.root / "missing-remote.git")
        result = self.run_block(script=script)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FATAL: git clone", result.stderr)
        self.assertFalse((self.box.config_dir / ".git").exists())

    def test_log_ownership_failure_is_fatal(self):
        result = self.run_block({"FAKE_CHOWN_STATUS": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FATAL: could not prepare log directory", result.stderr)
        self.assertIn("chown", result.stderr)
        self.assertEqual(self.box.calls("sudo"), [])

    def test_obsolete_user_job_bootout_failure_is_tolerated(self):
        result = self.run_block({"FAKE_LAUNCHCTL_STATUS": "3"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


# --- Generated activation ordering and loginwindow ---------------------------

class GeneratedActivationTests(unittest.TestCase):
    def setUp(self):
        self.text, self.username = require_generated("activation", "username")

    def test_mihomo_setup_runs_before_daemon_load(self):
        load = self.text.index(MIHOMO_DAEMON_LOAD)
        bootout = self.text.index('bootout "gui/$mihomo_user_uid/io.github.metacubex.mihomo"')
        logs = self.text.index("mihomo: preparing log directory")
        clone = self.text.index("mihomo: cloning config repo")
        launchd_header = self.text.index("setting up launchd services")
        self.assertLess(bootout, logs)
        self.assertLess(logs, clone)
        self.assertLess(clone, launchd_header)
        self.assertLess(launchd_header, load)

    def test_autologin_user_written_by_defaults(self):
        pattern = (r"defaults write /Library/Preferences/com\.apple\.loginwindow "
                   r"'?autoLoginUser'? '[^']*<string>" + re.escape(self.username)
                   + r"</string>")
        self.assertRegex(self.text, pattern)
        self.assertNotIn(f'autoLoginUser "{self.username}" || true', self.text)
        self.assertNotIn("kcpassword", self.text)


class GeneratedLoginwindowTests(unittest.TestCase):
    def test_option_is_username(self):
        auto_login_user, username = require_generated("autoLoginUser", "username")
        self.assertTrue(auto_login_user)
        self.assertEqual(auto_login_user, username)


# --- Source invariants (always run) ------------------------------------------

class SourceInvariantTests(unittest.TestCase):
    def test_mihomo_setup_lives_in_recognized_launchd_script(self):
        source = MIHOMO_NIX.read_text()
        self.assertNotIn("activationScripts.mihomoSetup", source)
        self.assertNotIn("postActivation", source)
        self.assertEqual(source.count(ACTIVATION_ANCHOR), 1)
        block = nix_activation_source()
        order = [block.index(marker) for marker in (
            "bootout", "preparing log directory", "chown", "cloning config repo")]
        self.assertEqual(order, sorted(order))
        self.assertIn("exit 1", block)

    def test_mihomo_log_setup_is_not_recursive(self):
        block = nix_activation_source()
        self.assertNotRegex(block, r"chown\s+-R")
        self.assertIn('[ -L "$mihomo_log_dir" ]', block)
        self.assertIn('[ -L "$mihomo_log" ]', block)

    def test_mihomo_icloud_export_preserved(self):
        source = MIHOMO_NIX.read_text()
        for needle in ("./sync-icloud.py", "com~apple~CloudDocs/Mihomo",
                       "icloud_status", "pull --ff-only"):
            self.assertIn(needle, source)

    def test_nightowl_autologin_is_declarative(self):
        source = SERVER_NIX.read_text()
        self.assertRegex(source, r"system\.defaults\.loginwindow\.autoLoginUser\s*=\s*myvars\.username;")
        self.assertNotIn("activationScripts", source)
        self.assertNotIn("defaults write", source)
        self.assertIn("kcpassword", source)

    def test_only_canonical_management_wrapper_is_declared(self):
        source = MIHOMO_NIX.read_text()
        self.assertFalse(RETIRED_MODULE.exists())
        self.assertEqual(re.findall(r'writeShellScriptBin "([^"]+)"', source), ["mihomo-sync"])
        self.assertNotIn("--delete", source)
        self.assertNotRegex(source, r"reset\s+--hard|\bstash\b|origin (main|master)")
        self.assertIn("pull --ff-only", source)


class GeneratedCommandSurfaceTests(unittest.TestCase):
    def test_only_mihomo_sync_is_installed_by_evaluated_configuration(self):
        names, = require_generated("management_commands")
        self.assertEqual(names.splitlines(), ["mihomo-sync"])


if __name__ == "__main__":
    unittest.main()
