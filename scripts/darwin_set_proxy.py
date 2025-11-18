"""
  Set proxy for nix-daemon to speed up downloads
  You can safely ignore this file if you don't need a proxy.

  Usage: python3 darwin_set_proxy.py [local|network]
  - local: 127.0.0.1:7890 (default)
  - network: 10.0.0.5:7890

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

# Proxy configuration presets
PROXY_CONFIGS = {
    "local": "http://127.0.0.1:7890",
    "network": "http://10.0.0.5:7890"
}

# Get proxy mode from command line argument, default to local
proxy_mode = sys.argv[1] if len(sys.argv) > 1 else "local"

if proxy_mode not in PROXY_CONFIGS:
    print(f"Error: Invalid proxy mode '{proxy_mode}'. Use 'local' or 'network'.")
    print("Usage: python3 darwin_set_proxy.py [local|network]")
    sys.exit(1)

HTTP_PROXY = PROXY_CONFIGS[proxy_mode]
print(f"Setting nix-daemon proxy to {proxy_mode} mode: {HTTP_PROXY}")       

pl = plistlib.loads(NIX_DAEMON_PLIST.read_bytes())

# set http/https proxy
# NOTE: curl only accept the lowercase of `http_proxy`!
# NOTE: https://curl.se/libcurl/c/libcurl-env.html
pl["EnvironmentVariables"]["http_proxy"] = HTTP_PROXY
pl["EnvironmentVariables"]["https_proxy"] = HTTP_PROXY

# remove http proxyx``
# pl["EnvironmentVariables"].pop("http_proxy", None)
# pl["EnvironmentVariables"].pop("https_proxy", None)

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

