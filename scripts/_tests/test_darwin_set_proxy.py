"""Tests for darwin_set_proxy.py with temp plists and fake subprocess calls.

No real launchctl, nix or /Library file is touched.
Run: python3 -m unittest discover -s scripts/_tests
"""

import contextlib
import importlib.util
import io
import plistlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parent.parent / "darwin_set_proxy.py"


def load_module():
    spec = importlib.util.spec_from_file_location("darwin_set_proxy", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


proxy = load_module()

BASE_PLIST = {
    "Label": "org.nixos.nix-daemon",
    "ProgramArguments": ["/bin/sh", "-c", "exec nix-daemon"],
    "EnvironmentVariables": {"OBJC_DISABLE_INITIALIZE_FORK_SAFETY": "YES"},
}


class FakeClock:
    """Monotonic clock advanced only by fake sleeps and probe timeouts."""

    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


LAUNCHCTL_NOT_FOUND = 113  # `launchctl print` exit status for an unknown service


class FakeRun:
    """Records commands; scripted results for launchctl and the daemon probe.

    launchctl_status maps an action (print/unload/load) to an exit status or
    "timeout"; probe_results lists daemon probe outcomes in order.
    """

    def __init__(self, clock, launchctl_status=None, probe_results=()):
        self.clock = clock
        self.calls = []
        self.launchctl_status = launchctl_status or {}
        self.probe_results = list(probe_results)

    def __call__(self, cmd, capture_output=False, timeout=None):
        self.calls.append((list(cmd), timeout))
        if cmd[0] == "launchctl":
            status = self.launchctl_status.get(cmd[1], 0)
            if status == "timeout":
                raise subprocess.TimeoutExpired(cmd, timeout)
            return subprocess.CompletedProcess(cmd, status)
        if cmd == proxy.DAEMON_PROBE:
            outcome = self.probe_results.pop(0) if self.probe_results else 1
            if outcome == "timeout":
                self.clock.now += timeout
                raise subprocess.TimeoutExpired(cmd, timeout)
            if outcome == "missing":
                raise FileNotFoundError("nix")
            return subprocess.CompletedProcess(cmd, outcome)
        raise AssertionError(f"unexpected command: {cmd}")

    def commands(self):
        return [cmd for cmd, _ in self.calls]

    def probes(self):
        return [call for call in self.calls if call[0] == proxy.DAEMON_PROBE]

    def launchctl(self):
        return [cmd[1] for cmd in self.commands() if cmd[0] == "launchctl"]


class ProxyTestCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.plist_path = Path(tmp.name) / "org.nixos.nix-daemon.plist"
        self.clock = FakeClock()

    def write(self, plist):
        if self.plist_path.exists():
            self.plist_path.chmod(0o644)
        self.plist_path.write_bytes(plistlib.dumps(plist))
        self.plist_path.chmod(0o444)

    def read(self):
        return plistlib.loads(self.plist_path.read_bytes())

    def run_main(self, argv, run):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            status = proxy.main(
                argv, plist_path=self.plist_path, run=run,
                sleep=self.clock.sleep, clock=self.clock, probe=lambda url: None,
            )
        return status, out.getvalue(), err.getvalue()


class ReachabilityTests(ProxyTestCase):
    def test_unreachable_proxy_preserves_plist_and_never_commands_daemon(self):
        self.write(BASE_PLIST)
        before = self.plist_path.read_bytes()
        run = FakeRun(self.clock)
        def unreachable(url):
            raise proxy.ProxyError("Proxy unavailable; use off explicitly for direct mode")
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            status = proxy.main(['local'], plist_path=self.plist_path, run=run,
                                probe=unreachable)
        self.assertEqual(status, 1)
        self.assertEqual(self.plist_path.read_bytes(), before)
        self.assertEqual(run.calls, [])
        self.assertIn('off explicitly', err.getvalue())

    def test_off_skips_proxy_probe(self):
        self.write(BASE_PLIST)
        probe = mock.Mock(side_effect=AssertionError('no proxy probe for off'))
        with contextlib.redirect_stdout(io.StringIO()):
            status = proxy.main(['off'], plist_path=self.plist_path,
                                run=FakeRun(self.clock, probe_results=[0]), probe=probe)
        self.assertEqual(status, 0)
        probe.assert_not_called()

    def test_probe_precedes_writes_and_all_daemon_commands(self):
        for initial in (BASE_PLIST, LOCAL_PLIST):
            with self.subTest(unchanged=initial == LOCAL_PLIST):
                self.write(initial)
                before = self.plist_path.read_bytes()
                run = FakeRun(self.clock, probe_results=[0])
                seen = []
                def reachable(url):
                    self.assertEqual(url, proxy.LOCAL_PROXY)
                    self.assertEqual(run.calls, [])
                    self.assertEqual(self.plist_path.read_bytes(), before)
                    seen.append(url)
                with contextlib.redirect_stdout(io.StringIO()):
                    status = proxy.main(['local'], plist_path=self.plist_path,
                                        run=run, probe=reachable)
                self.assertEqual(status, 0)
                self.assertEqual(seen, [proxy.LOCAL_PROXY])

    def test_invalid_url_never_probes_or_mutates_or_leaks_credentials(self):
        self.write(BASE_PLIST)
        before = self.plist_path.read_bytes()
        for value in ('http://user:secret@host:bad', 'http://:7890', 'http://bad..host:7890'):
            run = FakeRun(self.clock)
            probe = mock.Mock(side_effect=AssertionError('invalid URL must not probe'))
            err = io.StringIO()
            with contextlib.redirect_stderr(err):
                status = proxy.main([value], plist_path=self.plist_path, run=run, probe=probe)
            self.assertEqual(status, 1)
            self.assertNotIn('secret', err.getvalue())
            probe.assert_not_called()
            self.assertEqual(run.calls, [])
            self.assertEqual(self.plist_path.read_bytes(), before)

    def test_selected_proxy_printed(self):
        self.write(BASE_PLIST)
        status, out, err = self.run_main(['http://user:secret@proxy.example:80'],
                                       FakeRun(self.clock, probe_results=[0]))
        self.assertEqual(status, 0)
        self.assertIn('Setting nix-daemon proxy: http://user:secret@proxy.example:80', out)


class ModeTests(ProxyTestCase):
    def test_modes_set_expected_environment(self):
        cases = [
            ([], "http://127.0.0.1:7890"),
            (["local"], "http://127.0.0.1:7890"),
            (["http://10.0.0.3:7890"], "http://10.0.0.3:7890"),
            (["https://proxy.example:443"], "https://proxy.example:443"),
            (["socks5://127.0.0.1:7891"], "socks5://127.0.0.1:7891"),
        ]
        for argv, expected in cases:
            with self.subTest(argv=argv):
                self.write(BASE_PLIST)
                run = FakeRun(self.clock, probe_results=[0])
                status, _, _ = self.run_main(argv, run)
                self.assertEqual(status, 0)
                env = self.read()["EnvironmentVariables"]
                self.assertEqual(env["http_proxy"], expected)
                self.assertEqual(env["https_proxy"], expected)
                self.assertEqual(env["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"], "YES")
                self.assertEqual(self.plist_path.stat().st_mode & 0o777, 0o444)

    def test_off_removes_only_proxy_keys(self):
        env = dict(BASE_PLIST["EnvironmentVariables"], http_proxy="x", https_proxy="x")
        self.write(dict(BASE_PLIST, EnvironmentVariables=env))
        status, _, _ = self.run_main(["off"], FakeRun(self.clock, probe_results=[0]))
        self.assertEqual(status, 0)
        self.assertEqual(self.read()["EnvironmentVariables"], BASE_PLIST["EnvironmentVariables"])

    def test_invalid_argument_fails_without_touching_plist(self):
        self.write(BASE_PLIST)
        before = self.plist_path.read_bytes()
        run = FakeRun(self.clock)
        status, _, err = self.run_main(["ftp://nope"], run)
        self.assertEqual(status, 1)
        self.assertIn("Unrecognised argument", err)
        self.assertEqual(self.plist_path.read_bytes(), before)
        self.assertEqual(run.calls, [])


class MissingEnvironmentTests(ProxyTestCase):
    def test_set_creates_environment_variables(self):
        plist = {k: v for k, v in BASE_PLIST.items() if k != "EnvironmentVariables"}
        self.write(plist)
        status, _, _ = self.run_main(["local"], FakeRun(self.clock, probe_results=[0]))
        self.assertEqual(status, 0)
        self.assertEqual(
            self.read()["EnvironmentVariables"],
            {"http_proxy": proxy.LOCAL_PROXY, "https_proxy": proxy.LOCAL_PROXY},
        )

    def test_off_without_environment_is_a_no_op(self):
        plist = {k: v for k, v in BASE_PLIST.items() if k != "EnvironmentVariables"}
        self.write(plist)
        before = self.plist_path.read_bytes()
        run = FakeRun(self.clock, probe_results=[0])
        status, out, _ = self.run_main(["off"], run)
        self.assertEqual(status, 0)
        self.assertIn("already up to date", out)
        self.assertEqual(self.plist_path.read_bytes(), before)
        self.assertEqual(run.commands(), [proxy.DAEMON_PROBE])

    def test_missing_plist_is_clean_error(self):
        run = FakeRun(self.clock)
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("cannot read", err)
        self.assertEqual(run.calls, [])


LOCAL_ENV = dict(BASE_PLIST["EnvironmentVariables"],
                 http_proxy=proxy.LOCAL_PROXY, https_proxy=proxy.LOCAL_PROXY)
LOCAL_PLIST = dict(BASE_PLIST, EnvironmentVariables=LOCAL_ENV)


class NoChangeTests(ProxyTestCase):
    """An up-to-date plist is never rewritten; restart depends on daemon health."""

    def run_unchanged(self, run):
        self.write(LOCAL_PLIST)
        before = self.plist_path.read_bytes()
        mtime = self.plist_path.stat().st_mtime_ns
        with mock.patch.object(proxy, "write_plist") as write_plist:
            result = self.run_main(["local"], run)
        write_plist.assert_not_called()
        self.assertEqual(self.plist_path.read_bytes(), before)
        self.assertEqual(self.plist_path.stat().st_mtime_ns, mtime)
        return result

    def test_healthy_unchanged_skips_rewrite_and_restart(self):
        run = FakeRun(self.clock, probe_results=[0])
        status, out, _ = self.run_unchanged(run)
        self.assertEqual(status, 0)
        self.assertIn("skipping restart", out)
        self.assertEqual(run.commands(), [proxy.DAEMON_PROBE])
        self.assertLessEqual(run.probes()[0][1], proxy.PROBE_TIMEOUT_SECONDS)

    def test_unhealthy_unchanged_restarts_loaded_job(self):
        for first_probe in (1, "timeout"):
            with self.subTest(first_probe=first_probe):
                self.clock.now = 0.0
                run = FakeRun(self.clock, probe_results=[first_probe, 0])
                status, out, _ = self.run_unchanged(run)
                self.assertEqual(status, 0)
                self.assertIn("not responding, restarting", out)
                self.assertEqual(run.launchctl(), ["print", "unload", "load"])
                self.assertIn("nix-daemon is ready", out)

    def test_absent_job_is_loaded_without_unload(self):
        run = FakeRun(self.clock, launchctl_status={"print": LAUNCHCTL_NOT_FOUND},
                      probe_results=[1, 0])
        status, out, _ = self.run_unchanged(run)
        self.assertEqual(status, 0)
        self.assertIn("not loaded, skipping unload", out)
        self.assertEqual(run.launchctl(), ["print", "load"])

    def test_loaded_unload_failure_is_fatal(self):
        run = FakeRun(self.clock, launchctl_status={"unload": 5}, probe_results=[1])
        status, _, err = self.run_unchanged(run)
        self.assertEqual(status, 1)
        self.assertIn("launchctl unload", err)
        self.assertIn("exit 5", err)
        self.assertEqual(run.launchctl(), ["print", "unload"])


class RetryAfterFailureTests(ProxyTestCase):
    """A rerun after a failed restart recovers instead of skipping forever."""

    def test_rerun_recovers_after_failed_restart(self):
        cases = [
            # (first-run failure, job loaded on rerun?, expected rerun launchctl)
            ({"unload": 5}, 0, ["print", "unload", "load"]),
            ({"load": 3}, LAUNCHCTL_NOT_FOUND, ["print", "load"]),
        ]
        for failure, print_status, expected in cases:
            with self.subTest(failure=failure):
                self.clock.now = 0.0
                self.write(BASE_PLIST)
                first = FakeRun(self.clock, launchctl_status=failure)
                self.assertEqual(self.run_main(["local"], first)[0], 1)
                written = self.plist_path.read_bytes()
                self.assertEqual(self.read()["EnvironmentVariables"], LOCAL_ENV)

                rerun = FakeRun(self.clock, launchctl_status={"print": print_status},
                                probe_results=[1, 0])
                status, out, _ = self.run_main(["local"], rerun)
                self.assertEqual(status, 0)
                self.assertEqual(rerun.launchctl(), expected)
                self.assertIn("nix-daemon is ready", out)
                self.assertEqual(self.plist_path.read_bytes(), written)


class LaunchctlTests(ProxyTestCase):
    def test_restart_checks_job_then_unloads_then_loads(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, probe_results=[0])
        self.assertEqual(self.run_main(["local"], run)[0], 0)
        self.assertEqual(run.commands()[:3], [
            ["launchctl", "print", proxy.NIX_DAEMON_TARGET],
            ["launchctl", "unload", str(self.plist_path)],
            ["launchctl", "load", str(self.plist_path)],
        ])
        for cmd, timeout in run.calls[:3]:
            self.assertEqual(timeout, proxy.LAUNCHCTL_TIMEOUT_SECONDS)

    def test_unload_failure_stops_before_load(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, launchctl_status={"unload": 5})
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("launchctl unload", err)
        self.assertIn("exit 5", err)
        self.assertEqual(run.launchctl(), ["print", "unload"])

    def test_load_failure_skips_probe(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, launchctl_status={"load": 3})
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("launchctl load", err)
        self.assertEqual(run.probes(), [])

    def test_launchctl_timeouts_are_clean_errors(self):
        for action, expected in (("print", ["print"]),
                                 ("unload", ["print", "unload"]),
                                 ("load", ["print", "unload", "load"])):
            with self.subTest(action=action):
                self.write(BASE_PLIST)
                run = FakeRun(self.clock, launchctl_status={action: "timeout"})
                status, _, err = self.run_main(["local"], run)
                self.assertEqual(status, 1)
                self.assertIn(f"launchctl {action}", err)
                self.assertIn("timed out", err)
                self.assertEqual(run.launchctl(), expected)
                self.assertEqual(run.probes(), [])

    def test_missing_launchctl_is_clean_error(self):
        self.write(BASE_PLIST)

        def run(cmd, capture_output=False, timeout=None):
            raise FileNotFoundError("launchctl")

        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("could not run", err)


class WritePlistTests(ProxyTestCase):
    def test_write_failure_restores_read_only_mode(self):
        self.write(BASE_PLIST)
        before = self.plist_path.read_bytes()
        run = FakeRun(self.clock)
        with mock.patch.object(Path, "write_bytes", side_effect=OSError("disk full")):
            status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("cannot write", err)
        self.assertIn("disk full", err)
        self.assertEqual(self.plist_path.stat().st_mode & 0o777, 0o444)
        self.assertEqual(self.plist_path.read_bytes(), before)
        self.assertEqual(run.calls, [])


class DaemonProbeTests(ProxyTestCase):
    def test_probe_is_daemon_store_ping_not_a_store_path(self):
        self.assertEqual(proxy.DAEMON_PROBE[:4], ["nix", "--extra-experimental-features", "nix-command", "store"])
        self.assertIn("ping", proxy.DAEMON_PROBE)
        self.assertEqual(proxy.DAEMON_PROBE[-2:], ["--store", "daemon"])
        self.assertFalse(any(arg.startswith("/nix/store") for arg in proxy.DAEMON_PROBE))
        self.assertNotIn("--version", proxy.DAEMON_PROBE)

    def test_retry_until_success(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, probe_results=[1, 1, 0])
        status, out, _ = self.run_main(["local"], run)
        self.assertEqual(status, 0)
        self.assertIn("nix-daemon is ready", out)
        self.assertEqual(len(run.probes()), 3)
        for _, timeout in run.probes():
            self.assertIsNotNone(timeout)
            self.assertLessEqual(timeout, proxy.PROBE_TIMEOUT_SECONDS)

    def test_persistent_failure_is_bounded(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock)  # every probe fails
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("failed to become ready", err)
        self.assertLessEqual(len(run.probes()), int(proxy.READY_TIMEOUT_SECONDS) + 1)
        self.assertLessEqual(self.clock.now, proxy.READY_TIMEOUT_SECONDS + proxy.PROBE_INTERVAL_SECONDS)

    def test_hanging_probe_times_out_and_is_bounded(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, probe_results=["timeout"] * 100)
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("failed to become ready", err)
        self.assertLessEqual(self.clock.now, proxy.READY_TIMEOUT_SECONDS + proxy.PROBE_INTERVAL_SECONDS)
        for _, timeout in run.probes():
            self.assertLessEqual(timeout, proxy.PROBE_TIMEOUT_SECONDS)

    def test_timeout_then_success(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, probe_results=["timeout", 0])
        self.assertEqual(self.run_main(["local"], run)[0], 0)

    def test_missing_nix_binary_is_clean_error(self):
        self.write(BASE_PLIST)
        run = FakeRun(self.clock, probe_results=["missing"])
        status, _, err = self.run_main(["local"], run)
        self.assertEqual(status, 1)
        self.assertIn("`nix` could not run", err)
        self.assertEqual(len(run.probes()), 1)


class ImportSafetyTests(unittest.TestCase):
    def test_import_has_no_side_effects(self):
        with mock.patch.object(sys, "argv", ["darwin_set_proxy.py", "off"]), \
                mock.patch("subprocess.run") as run, \
                mock.patch("os.chmod") as chmod, \
                mock.patch.object(Path, "read_bytes") as read_bytes, \
                mock.patch.object(Path, "write_bytes") as write_bytes:
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                load_module()
        run.assert_not_called()
        chmod.assert_not_called()
        read_bytes.assert_not_called()
        write_bytes.assert_not_called()
        self.assertEqual(out.getvalue(), "")

    def test_no_historical_store_path_probe(self):
        source = SCRIPT.read_text()
        self.assertNotIn("/nix/store/", source)
        self.assertNotIn("nix-store", source)


if __name__ == "__main__":
    unittest.main()
