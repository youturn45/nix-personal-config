"""Tests for sync-icloud.py using synthetic fixtures in temporary directories.

Run: python3 -m unittest discover -s modules/darwin/mihomo/_tests
"""

import contextlib
import importlib.util
import io
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HELPER = Path(__file__).resolve().parent.parent / "sync-icloud.py"
_spec = importlib.util.spec_from_file_location("sync_icloud", HELPER)
sync_icloud = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sync_icloud)

RULESETS = [f"ruleset/custom-{n:02d}.yaml" for n in range(10)] + [
    "ruleset/nested/extra.yml"
]
IGNORED = [
    "cache.db",
    "proxies/provider.yaml",
    "rules/remote.yaml",
    "geoip.dat",
    "GeoSite.dat",
    "country.mmdb",
    ".git/config",
    "logs/mihomo.log",
    "tailscale/state.yaml",
    "ruleset/notes.txt",
    "ruleset/cache.db",
    "other.yaml",
]


def snapshot(root):
    """Map relative path -> bytes (files) or None (dirs/symlinks marker)."""
    result = {}
    for current, dirnames, filenames in os.walk(root):
        for name in dirnames + filenames:
            path = Path(current) / name
            rel = str(path.relative_to(root))
            if path.is_symlink():
                result[rel] = ("link", os.readlink(path))
            elif path.is_dir():
                result[rel] = ("dir",)
            else:
                result[rel] = ("file", path.read_bytes())
    return result


class SyncTestCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.base = Path(tmp.name)
        self.source = self.base / "home" / ".config" / "clash.meta"
        self.cloud = self.base / "Mobile Documents" / "com~apple~CloudDocs"
        self.dest = self.cloud / "Mihomo"
        self.cloud.mkdir(parents=True)
        self.write(self.source / "config.yaml", "secret: synthetic-token\n")
        for rel in RULESETS:
            self.write(self.source / rel, f"payload: [{rel}]\n")
        for rel in IGNORED:
            self.write(self.source / rel, "ignored\n")

    def write(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def run_sync(self, *extra, source=None, dest=None):
        argv = [
            "--source",
            str(source or self.source),
            "--destination",
            str(dest or self.dest),
            *extra,
        ]
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = sync_icloud.main(argv)
        return code, out.getvalue(), err.getvalue()

    def assert_rejected(self, fragment, **kwargs):
        before_source = snapshot(self.source)
        before_cloud = snapshot(self.cloud)
        code, out, err = self.run_sync(**kwargs)
        self.assertEqual(code, 1, out + err)
        self.assertIn(fragment, err)
        self.assertNotIn("synthetic-token", out + err)
        self.assertEqual(snapshot(self.source), before_source)
        self.assertEqual(snapshot(self.cloud), before_cloud)


class SelectionTests(SyncTestCase):
    def test_exact_selection(self):
        code, out, _ = self.run_sync()
        self.assertEqual(code, 0)
        files = {k for k, v in snapshot(self.dest).items() if v[0] == "file"}
        self.assertEqual(files, {"config.yaml", *RULESETS})
        self.assertIn("12 file(s) selected, 12 copied, 0 unchanged", out)
        self.assertIn("does not upload", out)

    def test_content_modes_and_idempotence(self):
        self.run_sync()
        for rel in ["config.yaml", *RULESETS]:
            target = self.dest / rel
            self.assertEqual(target.read_bytes(), (self.source / rel).read_bytes())
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
        for directory in [self.dest, self.dest / "ruleset", self.dest / "ruleset/nested"]:
            self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)

        first = snapshot(self.dest)
        code, out, _ = self.run_sync()
        self.assertEqual(code, 0)
        self.assertIn("0 copied, 12 unchanged", out)
        self.assertEqual(snapshot(self.dest), first)

    def test_updates_changed_file(self):
        self.run_sync()
        self.write(self.source / "config.yaml", "secret: rotated\n")
        code, out, _ = self.run_sync()
        self.assertEqual(code, 0)
        self.assertIn("1 copied", out)
        self.assertEqual((self.dest / "config.yaml").read_text(), "secret: rotated\n")

    def test_no_reverse_writes(self):
        before = snapshot(self.source)
        self.run_sync()
        self.write(self.dest / "config.yaml", "edited in cloud\n")
        self.write(self.dest / "ruleset/cloud-only.yaml", "x\n")
        self.run_sync()
        self.assertEqual(snapshot(self.source), before)

    def test_stale_and_unrelated_destination_files_preserved(self):
        self.write(self.dest / "notes.md", "keep me\n")
        self.write(self.dest / "ruleset/removed-upstream.yaml", "stale\n")
        code, _, _ = self.run_sync()
        self.assertEqual(code, 0)
        self.assertEqual((self.dest / "notes.md").read_text(), "keep me\n")
        self.assertEqual(
            (self.dest / "ruleset/removed-upstream.yaml").read_text(), "stale\n"
        )

    def test_optional_ruleset_absent(self):
        for rel in RULESETS + ["ruleset/notes.txt", "ruleset/cache.db"]:
            (self.source / rel).unlink()
        (self.source / "ruleset/nested").rmdir()
        (self.source / "ruleset").rmdir()
        code, out, _ = self.run_sync()
        self.assertEqual(code, 0)
        self.assertIn("1 file(s) selected", out)
        self.assertEqual(
            {k for k, v in snapshot(self.dest).items() if v[0] == "file"},
            {"config.yaml"},
        )

    def test_dry_run_writes_nothing(self):
        before = snapshot(self.cloud)
        code, out, _ = self.run_sync("--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("dry run: 12 file(s) selected", out)
        self.assertEqual(snapshot(self.cloud), before)
        self.assertFalse(self.dest.exists())

    def test_paths_with_spaces(self):
        source = self.base / "src with spaces" / "clash meta"
        dest = self.cloud / "Mihomo Backup"
        self.write(source / "config.yaml", "a: 1\n")
        self.write(source / "ruleset/my rules.yaml", "b: 2\n")
        code, _, _ = self.run_sync(source=source, dest=dest)
        self.assertEqual(code, 0)
        self.assertEqual((dest / "ruleset/my rules.yaml").read_text(), "b: 2\n")

    def test_cli_entrypoint(self):
        result = subprocess.run(
            [sys.executable, str(HELPER), "--source", str(self.source),
             "--destination", str(self.dest), "--dry-run"],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("12 file(s) selected", result.stdout)


class RejectionTests(SyncTestCase):
    def test_missing_config(self):
        (self.source / "config.yaml").unlink()
        self.assert_rejected("primary config is missing")

    def test_empty_config(self):
        self.write(self.source / "config.yaml", "")
        self.assert_rejected("primary config is empty")

    def test_unreadable_ruleset_fails_before_writes(self):
        before_source = snapshot(self.source)
        before_cloud = snapshot(self.cloud)
        with mock.patch.object(
            sync_icloud.os, "scandir", side_effect=PermissionError("ruleset unreadable")
        ):
            code, out, err = self.run_sync()
        self.assertEqual(code, 1, out + err)
        self.assertIn("ruleset unreadable", err)
        self.assertEqual(snapshot(self.source), before_source)
        self.assertEqual(snapshot(self.cloud), before_cloud)

    def test_missing_source(self):
        self.assert_rejected("source does not exist", source=self.base / "nope")

    def test_missing_cloud_parent(self):
        dest = self.base / "no-icloud" / "com~apple~CloudDocs" / "Mihomo"
        self.assert_rejected("destination parent does not exist", dest=dest)
        self.assertFalse((self.base / "no-icloud").exists())

    def test_source_root_symlink(self):
        link = self.base / "linked-source"
        link.symlink_to(self.source)
        self.assert_rejected("source root is a symlink", source=link)

    def test_config_symlink(self):
        real = self.base / "elsewhere.yaml"
        self.write(real, "x: 1\n")
        (self.source / "config.yaml").unlink()
        (self.source / "config.yaml").symlink_to(real)
        self.assert_rejected("primary config is a symlink")

    def test_ruleset_root_symlink(self):
        real = self.base / "real-ruleset"
        (self.source / "ruleset").rename(real)
        (self.source / "ruleset").symlink_to(real)
        self.assert_rejected("ruleset directory is a symlink")

    def test_nested_ruleset_dir_symlink(self):
        real = self.base / "outside"
        self.write(real / "x.yaml", "x\n")
        (self.source / "ruleset/linked").symlink_to(real)
        self.assert_rejected("ruleset directory is a symlink")

    def test_selected_ruleset_file_symlink(self):
        real = self.base / "outside.yaml"
        self.write(real, "x\n")
        (self.source / "ruleset/zz-link.yaml").symlink_to(real)
        self.assert_rejected("ruleset file is a symlink")

    def test_destination_root_symlink(self):
        real = self.base / "real-dest"
        real.mkdir()
        self.dest.symlink_to(real)
        self.assert_rejected("destination root is a symlink")
        self.assertEqual(list(real.iterdir()), [])

    def test_destination_ancestor_symlink(self):
        real = self.base / "real-ruleset-dest"
        real.mkdir()
        self.dest.mkdir()
        (self.dest / "ruleset").symlink_to(real)
        self.assert_rejected("destination directory is a symlink")
        self.assertEqual(list(real.iterdir()), [])

    def test_destination_target_symlink(self):
        real = self.base / "victim.yaml"
        self.write(real, "untouched\n")
        self.dest.mkdir()
        (self.dest / "ruleset").mkdir()
        (self.dest / "ruleset/nested").mkdir()
        (self.dest / "ruleset/nested/extra.yml").symlink_to(real)
        self.assert_rejected("destination file is a symlink")
        self.assertEqual(real.read_text(), "untouched\n")
        self.assertFalse((self.dest / "config.yaml").exists())

    def test_destination_inside_source(self):
        dest = self.source / "backup"
        self.assert_rejected("overlap", dest=dest)
        self.assertFalse(dest.exists())

    def test_source_inside_destination(self):
        source = self.dest / "clash.meta"
        self.write(source / "config.yaml", "a: 1\n")
        self.assert_rejected("overlap", source=source)

    def test_same_path(self):
        self.assert_rejected("overlap", dest=self.source)


class AtomicCopyTests(SyncTestCase):
    def test_failed_replace_keeps_old_file_and_removes_temp(self):
        self.write(self.dest / "config.yaml", "old\n")
        with mock.patch.object(sync_icloud.os, "replace", side_effect=OSError("boom")):
            code, _, err = self.run_sync()
        self.assertEqual(code, 1)
        self.assertIn("boom", err)
        self.assertEqual((self.dest / "config.yaml").read_text(), "old\n")
        self.assertEqual(sorted(p.name for p in self.dest.iterdir()), ["config.yaml"])

    def test_temp_file_created_in_target_directory(self):
        seen = []
        real_mkstemp = sync_icloud.tempfile.mkstemp

        def recording_mkstemp(**kwargs):
            seen.append(Path(kwargs["dir"]))
            return real_mkstemp(**kwargs)

        with mock.patch.object(sync_icloud.tempfile, "mkstemp", recording_mkstemp):
            self.run_sync()
        self.assertIn(self.dest, seen)
        self.assertIn(self.dest / "ruleset/nested", seen)
        leftovers = [p for p in self.dest.rglob("*.tmp")]
        self.assertEqual(leftovers, [])


if __name__ == "__main__":
    unittest.main()
