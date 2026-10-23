"""
  Set proxy for nix-daemon to speed up downloads
  You can safely ignore this file if you don't need a proxy.

  Usage: python3 darwin_set_proxy.py [<proxy_url>|local|off]
  - <proxy_url>: any full proxy URL, e.g. http://10.0.0.3:7890
  - local: shortcut for http://127.0.0.1:7890 (default)
  - off:   remove proxy from nix-daemon

  https://github.com/NixOS/nix/issues/1472#issuecomment-1532955973
"""
import importlib.util
import os
import plistlib
import subprocess
import sys
import time
from pathlib import Path


NIX_DAEMON_PLIST = Path("/Library/LaunchDaemons/org.nixos.nix-daemon.plist")
NIX_DAEMON_NAME = "org.nixos.nix-daemon"
NIX_DAEMON_TARGET = f"system/{NIX_DAEMON_NAME}"
LOCAL_PROXY = "http://127.0.0.1:7890"
USAGE = "Usage: python3 darwin_set_proxy.py [<proxy_url>|local|off]"
PROXY_SCHEMES = ("http://", "https://", "socks5://")

# Opens a real connection to the daemon socket; independent of any store path.
DAEMON_PROBE = [
    "nix", "--extra-experimental-features", "nix-command",
    "store", "ping", "--store", "daemon",
]
READY_TIMEOUT_SECONDS = 30.0
PROBE_TIMEOUT_SECONDS = 5.0
PROBE_INTERVAL_SECONDS = 1.0
LAUNCHCTL_TIMEOUT_SECONDS = 30.0


_spec = importlib.util.spec_from_file_location(
    'proxy_policy', Path(__file__).resolve().parents[1] / 'home/common/terminal/shells/proxy-policy.py'
)
assert _spec is not None and _spec.loader is not None
_policy = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_policy)
ProxyError = _policy.ProxyError
probe_proxy = _policy.probe_proxy


def parse_proxy(arg):
    """Return the proxy URL for a CLI argument, or None for `off`."""
    if arg == "local":
        return LOCAL_PROXY
    if arg == "off":
        return None
    if arg.startswith(PROXY_SCHEMES):
        _policy.endpoint(arg)
        return arg
    raise ProxyError(f"Unrecognised argument.\n{USAGE}")


def with_proxy(plist, proxy):
    """Return a copy of the daemon plist dict with the proxy applied.

    NOTE: curl only accepts lowercase `http_proxy`
    NOTE: https://curl.se/libcurl/c/libcurl-env.html
    """
    updated = dict(plist)
    env = dict(updated.get("EnvironmentVariables") or {})
    if proxy is None:
        env.pop("http_proxy", None)
        env.pop("https_proxy", None)
    else:
        env["http_proxy"] = proxy
        env["https_proxy"] = proxy
    if env or "EnvironmentVariables" in plist:
        updated["EnvironmentVariables"] = env
    return updated


def write_plist(path, plist):
    """Rewrite the read-only daemon plist, keeping it 0444 even if writing fails."""
    os.chmod(path, 0o644)
    try:
        path.write_bytes(plistlib.dumps(plist))
    finally:
        os.chmod(path, 0o444)


def run_command(cmd, run, capture_output):
    """Run a bounded subprocess, turning launch failures and hangs into ProxyError."""
    try:
        return run(cmd, capture_output=capture_output, timeout=LAUNCHCTL_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as err:
        raise ProxyError(
            f"`{' '.join(cmd)}` timed out after {LAUNCHCTL_TIMEOUT_SECONDS:.0f}s"
        ) from err
    except OSError as err:
        raise ProxyError(f"`{' '.join(cmd)}` could not run: {err}") from err


def daemon_job_loaded(run):
    """Return whether launchd currently has the nix-daemon job loaded."""
    result = run_command(["launchctl", "print", NIX_DAEMON_TARGET], run, capture_output=True)
    return result.returncode == 0


def run_launchctl(action, plist_path, run):
    cmd = ["launchctl", action, str(plist_path)]
    print(" ".join(cmd))
    result = run_command(cmd, run, capture_output=False)
    if result.returncode != 0:
        raise ProxyError(
            f"launchctl {action} {plist_path} failed (exit {result.returncode}); "
            f"the plist is current, rerun this script or restart {NIX_DAEMON_NAME} manually"
        )


def restart_daemon(plist_path, run):
    """Unload the job only if launchd has it loaded, then load it."""
    if daemon_job_loaded(run):
        run_launchctl("unload", plist_path, run)
    else:
        print(f"{NIX_DAEMON_TARGET} is not loaded, skipping unload")
    run_launchctl("load", plist_path, run)


def daemon_accepts_connections(run, timeout):
    try:
        result = run(DAEMON_PROBE, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return False
    except OSError as err:
        raise ProxyError(f"cannot probe nix-daemon, `nix` could not run: {err}") from err
    return result.returncode == 0


def wait_for_daemon(run, sleep, clock):
    """Probe the daemon until it answers, bounded by READY_TIMEOUT_SECONDS."""
    print("Waiting for nix-daemon to accept connections...")
    deadline = clock() + READY_TIMEOUT_SECONDS
    while True:
        remaining = deadline - clock()
        if remaining <= 0:
            break
        if daemon_accepts_connections(run, min(PROBE_TIMEOUT_SECONDS, remaining)):
            print("nix-daemon is ready")
            return
        remaining = deadline - clock()
        if remaining <= 0:
            break
        sleep(min(PROBE_INTERVAL_SECONDS, remaining))
    raise ProxyError(
        f"nix-daemon failed to become ready after {READY_TIMEOUT_SECONDS:.0f}s"
    )


def describe(proxy):
    if proxy is None:
        return "Removing proxy from nix-daemon"
    return "Setting nix-daemon proxy (endpoint credentials hidden)"


def read_plist(plist_path):
    try:
        return plistlib.loads(plist_path.read_bytes())
    except (OSError, plistlib.InvalidFileException) as err:
        raise ProxyError(f"cannot read {plist_path}: {err}") from err


def set_proxy(proxy, plist_path, run, sleep, clock, probe=None):
    """Apply the proxy, then restart and wait for the daemon.

    An unchanged plist is never rewritten, and the restart is skipped only
    when the daemon answers a bounded probe; otherwise a previous failed
    restart would leave the daemon down on every rerun.
    """
    print(describe(proxy))
    current = read_plist(plist_path)
    if proxy is not None:
        _policy.endpoint(proxy)
        (probe or probe_proxy)(proxy)
    updated = with_proxy(current, proxy)
    if updated == current:
        if daemon_accepts_connections(run, PROBE_TIMEOUT_SECONDS):
            print("nix-daemon proxy already up to date and daemon healthy, skipping restart")
            return
        print("nix-daemon proxy already up to date but daemon is not responding, restarting")
    else:
        try:
            write_plist(plist_path, updated)
        except OSError as err:
            raise ProxyError(f"cannot write {plist_path}: {err}") from err
    restart_daemon(plist_path, run)
    wait_for_daemon(run, sleep, clock)


def main(argv, plist_path=NIX_DAEMON_PLIST, run=subprocess.run,
         sleep=time.sleep, clock=time.monotonic, probe=None):
    """CLI entry point; returns the process exit status."""
    try:
        proxy = parse_proxy(argv[0] if argv else "local")
        set_proxy(proxy, plist_path, run, sleep, clock, probe=probe)
    except ProxyError as err:
        print(f"Error: {err}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
