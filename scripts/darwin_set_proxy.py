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

os.chmod(NIX_DAEMON_PLIST, 0o644)
NIX_DAEMON_PLIST.write_bytes(plistlib.dumps(pl))
os.chmod(NIX_DAEMON_PLIST, 0o444)

# reload the plist
for cmd in (
	f"launchctl unload {NIX_DAEMON_PLIST}",
	f"launchctl load {NIX_DAEMON_PLIST}",
):
    print(cmd)
    subprocess.run(shlex.split(cmd), capture_output=False)

# Check if daemon is already running
print("Checking nix-daemon status...")
try:
    subprocess.run(["nix", "daemon", "--version"], check=True, capture_output=True)
    print("nix-daemon is running")
except subprocess.CalledProcessError:
    # Daemon not ready yet, wait and try again
    print("nix-daemon not ready, waiting 3 seconds...")
    time.sleep(3)
    try:
        subprocess.run(["nix", "daemon", "--version"], check=True, capture_output=True)
        print("nix-daemon is running")
    except subprocess.CalledProcessError:
        print("Error: nix-daemon failed to start")
        exit(1)

