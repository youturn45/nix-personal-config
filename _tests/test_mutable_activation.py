"""Exercise actual Nix-evaluated fragments only inside disposable homes."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EvaluatedMutableActivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = os.environ.get('RELIABILITY_GENERATED_JSON')
        if not source:
            raise unittest.SkipTest('Run the shared strict validator to supply actual evaluated fragments')
        cls.generated = json.loads(Path(source).read_text())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)

    def localized(self, key):
        body = self.generated[key].replace('/Users/' + self.generated['username'], str(self.home))
        for interpreter in ('python3', 'python'):
            body = re.sub(r'/nix/store/[^\s]+/bin/' + interpreter + r'\b', shlex.quote(sys.executable), body)
        for name, relative in (
            ('merge-settings.py', 'home/common/claude-code/merge-settings.py'),
            ('migrate-config.py', 'home/common/dev-tools/git/migrate-config.py'),
            ('merge-config.py', 'home/common/codex/merge-config.py'),
        ):
            body = re.sub(r'/nix/store/[^\s\'\"]*-' + re.escape(name), shlex.quote(str(ROOT / relative)), body)
        self.assertNotIn('/Users/', body.replace(str(ROOT), ''), 'Refusing a fragment with an unlocalized real home')
        return body

    def execute(self, key, **extra):
        # HM defines run before DAG entries. This minimal wrapper models only
        # command suppression; production helpers also guard direct dry runs.
        prelude = '''
run() {
  if [ -n "${DRY_RUN:-}${DRY_RUN_CMD:-}" ]; then return 0; fi
  "$@"
}
'''
        return subprocess.run([shutil.which('bash') or '/bin/bash', '-eu', '-c', prelude + self.localized(key)],
                              env=dict(os.environ, HOME=str(self.home), PYTHONDONTWRITEBYTECODE='1', **extra),
                              capture_output=True, text=True, timeout=15)

    def inventory(self):
        result = {}
        for path in self.home.rglob('*'):
            mode = stat.S_IMODE(path.lstat().st_mode)
            value = ('link', os.readlink(path)) if path.is_symlink() else ('dir',) if path.is_dir() else ('file', path.read_bytes())
            result[str(path.relative_to(self.home))] = (mode, value)
        return result

    def test_all_four_hooks_dryrun_preserves_bytes_modes_links_and_inventory(self):
        (self.home / '.claude').mkdir()
        (self.home / '.claude/settings.json').write_text('{"model":"fixture"}')
        (self.home / '.claude.json').write_text('{"fixture":"keep"}')
        (self.home / 'git-target').write_text('[fixture]\n keep = true\n')
        (self.home / '.gitconfig').symlink_to('git-target')
        (self.home / '.codex').mkdir()
        (self.home / '.codex/config.toml').write_text('model = "fixture"\n')
        before = self.inventory()
        for flag in ('DRY_RUN', 'DRY_RUN_CMD'):
            for key in ('git_activation', 'claude_settings_activation', 'claude_runtime_activation', 'codex_activation'):
                with self.subTest(flag=flag, fragment=key):
                    result = self.execute(key, **{flag: '1'})
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(self.inventory(), before)

    def test_actual_git_hook_preserves_legacy_configuration(self):
        legacy = self.home / '.gitconfig'
        legacy.write_bytes(b'[fixture]\n keep = true\n')
        result = self.execute('git_activation')
        self.assertEqual(result.returncode, 0, result.stderr)
        backups = list(self.home.glob('.gitconfig.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), b'[fixture]\n keep = true\n')
        self.assertFalse(legacy.exists())

    def test_actual_claude_defaults_and_runtime_ownership(self):
        (self.home / '.claude').mkdir()
        settings = self.home / '.claude/settings.json'
        settings.write_text('{"model":"fixture","env":{"fixture":"keep"}}')
        runtime = self.home / '.claude.json'
        runtime.write_text('{"fixture":"keep","teammateMode":"old"}')
        for key in ('claude_settings_activation', 'claude_runtime_activation'):
            result = self.execute(key)
            self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(settings.read_text())
        self.assertEqual(data['model'], 'fixture')
        self.assertEqual(data['env']['fixture'], 'keep')
        self.assertEqual(data['env']['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'], '1')
        self.assertIn('~/.claude/hooks/tmux-notify.sh', json.dumps(data['hooks']))
        self.assertEqual(json.loads(runtime.read_text()), {'fixture': 'keep', 'teammateMode': 'tmux'})

    def test_actual_claude_failure_preserves_original_and_hides_input(self):
        (self.home / '.claude').mkdir()
        settings = self.home / '.claude/settings.json'
        settings.write_text('{SYNTHETIC_PRIVATE_VALUE')
        before = self.inventory()
        result = self.execute('claude_settings_activation')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Claude config activation failed', result.stderr)
        self.assertNotIn('SYNTHETIC_PRIVATE_VALUE', result.stdout + result.stderr)
        self.assertEqual(self.inventory(), before)

    def test_actual_mihomo_startup_stops_before_engine_if_setup_fails(self):
        marker = self.home / 'engine-called'
        engine = self.home / 'fake-engine'
        engine.write_text('#!/bin/sh\n: > "' + str(marker) + '"\n')
        engine.chmod(0o700)
        helper = self.home / 'fake-proxy-helper'
        helper.write_text('#!/bin/sh\nexit 23\n')
        helper.chmod(0o700)
        body = self.generated['mihomo_daemon'].replace('/Users/' + self.generated['username'], str(self.home))
        body = re.sub(r'/nix/store/[^\s]+-youturn-proxy-private', shlex.quote(str(helper)), body)
        body = re.sub(r'/nix/store/[^\s]+/bin/mihomo', shlex.quote(str(engine)), body)
        self.assertNotIn('/Users/', body)
        self.assertNotIn('/nix/store/', body, 'Do not run unlocalized store commands in this fixture')
        result = subprocess.run(['/bin/sh', '-c', body], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertFalse(marker.exists())
        helper.write_text('#!/bin/sh\nexit 0\n')
        result = subprocess.run(['/bin/sh', '-c', body], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(marker.exists())


if __name__ == '__main__':
    unittest.main()
