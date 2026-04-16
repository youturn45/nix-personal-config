"""
  Set proxy for nix-daemon to speed up downloads
  You can safely ignore this file if you don't need a proxy.

  Usage: python3 darwin_set_proxy.py [<proxy_url>|local|off]
  - <proxy_url>: any full proxy URL, e.g. http://10.0.0.3:7890
  - local: shortcut for http://127.0.0.1:7890 (default)
  - off:   remove proxy from nix-daemon

  https://github.com/NixOS/nix/issues/1472#issuecomment-1532955973
"""
import os
import plistlib
import shlex
import subprocess
import sys
import time
from pathlib import Path


NIX_DAEMON_PLIST = Path("/Library/LaunchDaemons/org.nixos.nix-daemon.plist")
NIX_DAEMON_NAME = "org.nixos.nix-daemon"

arg = sys.argv[1] if len(sys.argv) > 1 else "local"

if arg == "local":
    HTTP_PROXY = "http://127.0.0.1:7890"
    print(f"Setting nix-daemon proxy to local: {HTTP_PROXY}")
elif arg == "off":
    HTTP_PROXY = None
    print("Removing proxy from nix-daemon")
elif arg.startswith(("http://", "https://", "socks5://")):
    HTTP_PROXY = arg
    print(f"Setting nix-daemon proxy to: {HTTP_PROXY}")
else:
    print(f"Error: Unrecognised argument '{arg}'.")
    print("Usage: python3 darwin_set_proxy.py [<proxy_url>|local|off]")
    sys.exit(1)

pl = plistlib.loads(NIX_DAEMON_PLIST.read_bytes())

# NOTE: curl only accepts lowercase `http_proxy`
# NOTE: https://curl.se/libcurl/c/libcurl-env.html
if HTTP_PROXY is None:
    pl["EnvironmentVariables"].pop("http_proxy", None)
    pl["EnvironmentVariables"].pop("https_proxy", None)
else:
    pl["EnvironmentVariables"]["http_proxy"] = HTTP_PROXY
    pl["EnvironmentVariables"]["https_proxy"] = HTTP_PROXY

original = NIX_DAEMON_PLIST.read_bytes()
new_bytes = plistlib.dumps(pl)

if original == new_bytes:
    print("nix-daemon proxy already up to date, skipping restart")
else:
    os.chmod(NIX_DAEMON_PLIST, 0o644)
    NIX_DAEMON_PLIST.write_bytes(new_bytes)
    os.chmod(NIX_DAEMON_PLIST, 0o444)

    for cmd in (
        f"launchctl unload {NIX_DAEMON_PLIST}",
        f"launchctl load {NIX_DAEMON_PLIST}",
    ):
        print(cmd)
        subprocess.run(shlex.split(cmd), capture_output=False)

    # Wait until the daemon accepts store connections (same check nix-darwin activation uses).
    # This prevents the activation's own wait loop from firing repeatedly.
    NIX_BASH = "/nix/store/ny5ngjbcqpn01bj3j8fxq1nbqiyaw78q-bash-5.3p3/bin/bash"
    print("Waiting for nix-daemon to accept connections...")
    for attempt in range(30):
        result = subprocess.run(
            ["nix-store", "--store", "daemon", "-q", "--hash", NIX_BASH],
            capture_output=True,
        )
        if result.returncode == 0:
            print("nix-daemon is ready")
            break
        time.sleep(1)
    else:
        print("Error: nix-daemon failed to become ready after 30s")
        sys.exit(1)

