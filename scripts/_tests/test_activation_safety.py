"""Mutable-config contracts; only disposable homes and fault-injected writers."""
import importlib.util
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def load(relative):
    spec = importlib.util.spec_from_file_location('fixture_' + Path(relative).stem.replace('-', '_'), ROOT / relative)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # Codex's external serializer is mocked ONLY for filesystem fault tests;
    # parser/merge use real stdlib TOML, not a replacement production renderer.
    with patch.dict(sys.modules, {'tomli_w': types.SimpleNamespace(dumps=lambda _: 'fixture = "saved"\n')}):
        spec.loader.exec_module(module)
    return module


class MutableConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.claude = load('home/common/claude-code/merge-settings.py')
        self.codex = load('home/common/codex/merge-config.py')

    def test_defaults_live_values_win_recursive_and_arrays(self):
        live = self.root / 'settings.json'
        live.write_text(json.dumps({'env': {'own': 'keep'}, 'hooks': {'Notification': ['live']}, 'model': 'mine'}))
        defaults = {'env': {'own': 'default', 'new': 'added'}, 'hooks': {'Notification': ['default']}}
        self.claude.apply('defaults', live, defaults)
        self.assertEqual(json.loads(live.read_text()), {'env': {'own': 'keep', 'new': 'added'}, 'hooks': {'Notification': ['live']}, 'model': 'mine'})
        self.assertEqual(stat.S_IMODE(live.stat().st_mode), 0o600)

    def test_runtime_forces_only_teammate_mode(self):
        path = self.root / '.claude.json'
        path.write_text('{"teammateMode":"old","fixture":"keep"}')
        self.claude.apply('runtime', path)
        self.assertEqual(json.loads(path.read_text()), {'teammateMode': 'tmux', 'fixture': 'keep'})

    def test_absent_empty_and_symlink_keep_target(self):
        for kind in ('absent', 'empty', 'symlink'):
            with self.subTest(kind=kind):
                path = self.root / kind / 'config.json'
                path.parent.mkdir()
                target = self.root / (kind + '-original')
                if kind == 'empty':
                    path.write_text('  ')
                elif kind == 'symlink':
                    target.write_text('{"keep":true}')
                    path.symlink_to(target)
                self.claude.apply('defaults', path, {'new': True})
                self.assertFalse(path.is_symlink())
                self.assertEqual(json.loads(path.read_text())['new'], True)
                if kind == 'symlink':
                    self.assertEqual(target.read_text(), '{"keep":true}')

    def test_malformed_or_nonobject_json_unchanged(self):
        for value in ('{broken', '[]', 'null'):
            path = self.root / 'bad.json'
            path.write_text(value)
            with self.assertRaises((ValueError, json.JSONDecodeError)):
                self.claude.apply('defaults', path, {})
            self.assertEqual(path.read_text(), value)
            self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['bad.json'])

    def test_broken_symlink_refused_without_replacing_it(self):
        path = self.root / 'broken'
        path.symlink_to('missing')
        with self.assertRaises((OSError, ValueError)):
            self.claude.apply('defaults', path, {})
        self.assertTrue(path.is_symlink())

    def test_dryrun_no_files_or_directories_created_or_changed(self):
        existing = self.root / 'existing.json'
        existing.write_text('{"keep":true}')
        before = existing.read_bytes()
        for flag in ('DRY_RUN', 'DRY_RUN_CMD'):
            with patch.dict(os.environ, {flag: '1'}):
                self.claude.apply('runtime', existing)
                self.claude.apply('defaults', self.root / 'absent' / 'config.json', {})
            self.assertEqual(existing.read_bytes(), before)
            self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['existing.json'])

    def test_atomic_writer_failure_preserves_file_mode_and_cleans_temp(self):
        for module in (self.claude, self.codex):
            path = self.root / 'atomic'
            if path.exists():
                path.chmod(0o600)  # Reset only our read-only fixture between writers.
            path.write_text('original')
            path.chmod(0o400)
            with patch.object(module.os, 'replace', side_effect=OSError('fixture write failure')):
                with self.assertRaises(OSError):
                    module.atomic_write(path, 'new')
            self.assertEqual(path.read_text(), 'original')
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o400)
            self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['atomic'])

    def test_atomic_replace_is_sibling_and_private(self):
        path = self.root / 'config'
        replace = self.claude.os.replace
        def observe(source, destination):
            self.assertEqual(Path(source).parent, path.parent)
            self.assertEqual(stat.S_IMODE(Path(source).stat().st_mode), 0o600)
            return replace(source, destination)
        with patch.object(self.claude.os, 'replace', side_effect=observe):
            self.claude.atomic_write(path, 'new')
        self.assertEqual(path.read_text(), 'new')

    def test_codex_nix_wins_and_other_runtime_keys_survive(self):
        self.assertEqual(self.codex.merge({'model': 'live', 'projects': {'trust': 'keep'}, 'features': {'a': False}}, {'model': 'managed', 'features': {'a': True}}), {'model': 'managed', 'projects': {'trust': 'keep'}, 'features': {'a': True}})

    def test_codex_serializer_failure_leaves_symlink_and_target(self):
        original = self.root / 'original.toml'
        original.write_text('model = "live"\n')
        path = self.root / 'config.toml'
        path.symlink_to(original)
        managed = self.root / 'managed.toml'
        managed.write_text('model = "managed"\n')
        with patch.object(self.codex.tomli_w, 'dumps', side_effect=ValueError('fixture serialization failure')):
            with patch.object(sys, 'argv', ['merge-config.py', str(path), str(managed)]):
                with self.assertRaises(ValueError):
                    self.codex.main()
        self.assertTrue(path.is_symlink())
        self.assertEqual(original.read_text(), 'model = "live"\n')


class GitMigrationTests(unittest.TestCase):
    def setUp(self):
        self.module = load('home/common/dev-tools/git/migrate-config.py')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / '.gitconfig'

    def test_regular_preserved_in_unique_private_backups(self):
        backups = []
        for _ in range(2):
            self.path.write_bytes(b'[fixture]\n value = keep\n')
            backups.append(self.module.migrate(self.path))
            self.assertFalse(self.path.exists())
        self.assertNotEqual(backups[0], backups[1])
        for backup in backups:
            self.assertEqual(backup.read_bytes(), b'[fixture]\n value = keep\n')
            self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o600)

    def test_relative_symlink_preserved_without_touching_target(self):
        target = self.root / 'target'
        target.write_text('keep')
        self.path.symlink_to('target')
        backup = self.module.migrate(self.path)
        self.assertTrue(backup.is_symlink())
        self.assertEqual(os.readlink(backup), 'target')
        self.assertEqual(target.read_text(), 'keep')
        self.assertEqual(backup.read_text(), 'keep')

    def test_dryrun_no_backup_no_changes(self):
        self.path.write_text('keep')
        with patch.dict(os.environ, {'DRY_RUN': '1'}):
            self.module.migrate(self.path)
        self.assertEqual(self.path.read_text(), 'keep')
        self.assertEqual(list(self.root.iterdir()), [self.path])

    def test_failure_after_promotion_never_deletes_preserved_data(self):
        self.path.write_text('keep after interruption')
        replace = self.module.os.replace
        def interrupted(source, destination):
            replace(source, destination)
            raise OSError('fixture interruption after promotion')
        with patch.object(self.module.os, 'replace', side_effect=interrupted):
            with self.assertRaises(OSError):
                self.module.migrate(self.path)
        backups = list(self.root.glob('.gitconfig.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'keep after interruption')

    def test_directory_refused(self):
        self.path.mkdir()
        with self.assertRaises(ValueError):
            self.module.migrate(self.path)
        self.assertTrue(self.path.is_dir())

    def test_missing_noop(self):
        self.assertIsNone(self.module.migrate(self.path))
        self.assertEqual(list(self.root.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
