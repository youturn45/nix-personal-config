"""Private proxy policy: no real network or macOS settings are touched."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / 'home/common/terminal/shells/proxy-policy.py'


def load_helper():
    spec = importlib.util.spec_from_file_location('proxy_policy', HELPER)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PolicyTests(unittest.TestCase):
    def test_failed_actions_are_counted_named_and_nonzero(self):
        policy = load_helper()
        calls = []
        def run(cmd, **kwargs):
            calls.append(cmd)
            if cmd[1] == '-listallnetworkservices':
                return subprocess.CompletedProcess(cmd, 0, 'An asterisk denotes disabled services.\nWi-Fi\nUSB LAN\n*Disabled LAN\nTailscale\nBridge\nJTAG\nBluetooth PAN\nVPN\n')
            return subprocess.CompletedProcess(cmd, 5 if cmd[1] == '-setwebproxy' else 0)
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            status = policy.configure_system('on', 'http://127.0.0.1:7890', 'socks5://127.0.0.1:7891', run=run, executable='/fake/networksetup')
        self.assertEqual(status, 1)
        self.assertIn('2 action(s) failed', err.getvalue())
        self.assertIn('Wi-Fi: -setwebproxy', err.getvalue())
        self.assertIn('USB LAN: -setwebproxy', err.getvalue())
        self.assertEqual({cmd[2] for cmd in calls[1:]}, {'Wi-Fi', 'USB LAN'})
        self.assertTrue(all(cmd[0] == '/fake/networksetup' for cmd in calls))
        bypass = next(cmd for cmd in calls if cmd[1] == '-setproxybypassdomains')
        self.assertIn('169.254/16', bypass)
        self.assertNotIn('10.0.0.0/8', bypass)

    def test_off_uses_only_state_actions(self):
        policy = load_helper()
        calls = []
        def run(cmd, **kwargs):
            calls.append(cmd)
            return subprocess.CompletedProcess(cmd, 0, 'header\nWi-Fi\n')
        self.assertEqual(policy.configure_system('off', run=run), 0)
        self.assertEqual(calls[0][0], '/usr/sbin/networksetup')
        self.assertEqual([c[1] for c in calls[1:]], ['-setwebproxystate', '-setsecurewebproxystate', '-setsocksfirewallproxystate'])

    def test_system_setup_does_not_probe_engine_before_start(self):
        policy = load_helper()
        def run(cmd, **kwargs):
            return subprocess.CompletedProcess(cmd, 0, 'header\nWi-Fi\n')
        from unittest import mock
        with mock.patch.object(policy, 'probe_proxy', side_effect=AssertionError('must not probe')):
            self.assertEqual(policy.configure_system('on', 'http://127.0.0.1:7890', 'socks5://127.0.0.1:7891', run=run), 0)

    def test_tcp_probe_is_bounded_and_no_credentials_in_error(self):
        policy = load_helper()
        calls = []
        def refused(address, timeout):
            calls.append((address, timeout))
            raise OSError('secret must not escape')
        with self.assertRaises(policy.ProxyError) as err:
            policy.probe_proxy('http://user:secret@127.0.0.1:7890', connect=refused)
        self.assertEqual(calls, [(('127.0.0.1', 7890), 2.0)])
        self.assertNotIn('secret', str(err.exception))
        self.assertIn('off explicitly', str(err.exception))
        import time
        def hangs(address, timeout):
            time.sleep(0.2)
            raise OSError()
        start = time.monotonic()
        with self.assertRaises(policy.ProxyError):
            policy.probe_proxy('http://127.0.0.1:7890', timeout=0.01, connect=hangs)
        self.assertLess(time.monotonic() - start, 0.15)

    def test_shell_selection_fail_closed_off_quiet_and_single_startup(self):
        import os
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            helper = Path(tmp) / 'helper'
            helper.write_text('#!/bin/sh\nprintf "called\\n" >> "$PROXY_TEST_LOG"\nexit "${PROXY_TEST_STATUS:-0}"\n')
            helper.chmod(0o755)
            env = dict(os.environ, PROXY_TEST_LOG=str(Path(tmp) / 'calls'))
            prelude = '''
                source "$1"
                _YOUTURN_PROXY_HELPER="$2"
                PROXY_LOCAL_HTTP=http://127.0.0.1:7890
                PROXY_LOCAL_SOCKS=socks5://127.0.0.1:7891
                PROXY_NETWORK_HTTP=http://192.0.2.1:7890
                PROXY_NETWORK_SOCKS=socks5://192.0.2.1:7891
                curl() { return 0; } # never contact a remote endpoint in tests
            '''
            def shell(body, status='0'):
                return subprocess.run(['zsh', '-f', '-c', prelude + body, 'test', str(HELPER.with_name('proxy.zsh')), str(helper)], env=dict(env, PROXY_TEST_STATUS=status), text=True, capture_output=True)
            result = shell('_proxy_startup local; [[ "$http_proxy" == "$PROXY_LOCAL_HTTP" && "$npm_config_https_proxy" == "$http_proxy" && "$NO_PROXY" == "localhost,127.0.0.1,::1" ]]')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout + result.stderr, '')
            self.assertEqual(Path(env['PROXY_TEST_LOG']).read_text(), 'called\n')
            result = shell('proxy on network; code=$?; [[ $code != 0 && "$http_proxy" == "$PROXY_NETWORK_HTTP" && "$npm_config_proxy" == "$http_proxy" ]]', '7')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('selection retained', result.stderr)
            self.assertNotIn('enabled', result.stdout)
            result = shell('PROXY_LOCAL_HTTP=""; _proxy_startup local; code=$?; [[ $code != 0 && "$http_proxy" == "http://127.0.0.1:0" && "$ALL_PROXY" == "socks5://127.0.0.1:0" ]]')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('blocked', result.stderr)
            result = shell('export HTTP_PROXY=old npm_config_proxy=old NO_PROXY=old; _proxy_startup off; [[ -z "$HTTP_PROXY$npm_config_proxy$NO_PROXY" ]]')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout + result.stderr, '')
            result = shell('proxy on local >/dev/null; proxy test')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('Connection successful', result.stdout)
            result = shell('curl() { return 22; }; proxy on local >/dev/null; proxy test')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('selection retained', result.stderr)
            result = shell('OSTYPE=darwin; proxy macos-on local', '5')
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('enabled', result.stdout)
        rc = HELPER.with_name('.zshrc').read_text()
        self.assertNotIn('proxy on', rc)
        source = HELPER.with_name('default.nix').read_text()
        self.assertEqual(source.count('_proxy_startup ${'), 1)

    def test_system_urls_reject_unsupported_roles_before_any_changes(self):
        policy = load_helper()
        calls = []
        def run(cmd, **kwargs):
            calls.append(cmd)
            return subprocess.CompletedProcess(cmd, 0, 'header\nWi-Fi\n')
        for http, socks in (
            ('https://proxy.example:443', 'socks5://127.0.0.1:7891'),
            ('http://fixture:fixture-secret@127.0.0.1:7890', 'socks5://127.0.0.1:7891'),
            ('http://127.0.0.1:7890', 'http://127.0.0.1:7891'),
            ('http://127.0.0.1:7890', 'socks5h://127.0.0.1:7891'),
        ):
            with self.subTest(http=http, socks=socks), self.assertRaises(policy.ProxyError) as error:
                policy.configure_system('on', http, socks, run=run)
            self.assertNotIn('fixture-secret', str(error.exception))
            self.assertEqual(calls, [])

    def test_safe_url_validation(self):
        policy = load_helper()
        for value in ['http://', 'http://host:0', 'http://host:99999', 'http://host:abc', 'http://bad host:80', 'http://host:80/path', 'ftp://host:80', 'http://user:secret@host:bad']:
            with self.subTest(value=value), self.assertRaises(policy.ProxyError) as error:
                policy.endpoint(value)
            self.assertNotIn('secret', str(error.exception))
        self.assertEqual(policy.endpoint('http://[::1]:7890'), ('::1', 7890))


if __name__ == '__main__':
    unittest.main()
