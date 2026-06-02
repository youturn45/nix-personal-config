# Mihomo Debug Guide

## How it works

Mihomo runs as a **per-user LaunchAgent** managed by nix-darwin. The `launchd.agents.mihomo` block in `default.nix` generates a plist at `~/Library/LaunchAgents/io.github.metacubex.mihomo.plist`.

**Key plist properties:**
- `RunAtLoad = true` — starts automatically at login
- `KeepAlive = true` — launchd restarts mihomo if it crashes
- `Label` — `io.github.metacubex.mihomo` (used in all `launchctl` commands)
- Logs go to `~/Library/Logs/mihomo/`

**Startup sequence** (what the plist's shell script does on each launch):
1. Creates the log directory if missing
2. Iterates all network services, skipping Tailscale/Bridge/JTAG/Bluetooth/VPN
3. Sets HTTP and HTTPS proxy to `127.0.0.1:7890` on each service
4. Sets SOCKS5 proxy to `127.0.0.1:7891` on each service
5. `exec`s mihomo with `~/.config/clash.meta` as the config directory

**Helper scripts:**
- `mihomo-reload` — sends SIGHUP to reload config in-place (no proxy gap)
- `mihomo-sync` — git-pulls `~/.config/clash.meta` from the private repo, then sends SIGHUP

**Activation script** (`system.activationScripts.mihomoSetup`) — runs on every `darwin-rebuild switch` to create the log directory and clone (first time) or pull (subsequent times) the config repo from GitHub over SSH using `~/.ssh/Youturn`.

---

## Check service status

```bash
launchctl list | grep mihomo
```

Output format: `PID  exit_code  label`
- `-` in PID column = not running
- Non-zero exit code = crashed (78 = config error, 1 = generic error)

---

## Start / stop / restart

```bash
# Restart (kills and restarts if already running)
launchctl kickstart -k gui/$(id -u)/io.github.metacubex.mihomo

# Stop
launchctl kill SIGTERM gui/$(id -u)/io.github.metacubex.mihomo

# Start (if registered but not running)
launchctl kickstart gui/$(id -u)/io.github.metacubex.mihomo
```

---

## Test config before starting

Run mihomo directly to see parse errors immediately:

```bash
/run/current-system/sw/bin/mihomo -d ~/.config/clash.meta
```

Common fatal errors:
- `proxy group[N]: 'XYZ' not found` — a group references a proxy name that doesn't exist
- `Parse config error` — YAML syntax issue in `config.yaml`

---

## View logs

```bash
# Live log
tail -f ~/Library/Logs/mihomo/mihomo.log

# Errors only
tail -f ~/Library/Logs/mihomo/mihomo.error.log

# Fix log permission issues (if owned by root)
sudo chown -R $(whoami):staff ~/Library/Logs/mihomo/
```

---

## Re-register plist after nix rebuild

After `just build`, if the service doesn't auto-start:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/io.github.metacubex.mihomo.plist
```

If it was previously unloaded and the plist is missing, copy it back from the nix store:

```bash
# Find the plist in the nix store
find /nix/store -name "io.github.metacubex.mihomo.plist" | head -1

# Copy it back
cp <path from above> ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/io.github.metacubex.mihomo.plist
```

---

## Sync config from remote

```bash
mihomo-sync   # git pull + reload
mihomo-reload # reload only (no git pull)
```

---

## Verify proxy is active

```bash
networksetup -getwebproxy Wi-Fi
networksetup -getsecurewebproxy Wi-Fi
networksetup -getsocksfirewallproxy Wi-Fi
```

All three should show `Enabled: Yes` and point to `127.0.0.1`.
