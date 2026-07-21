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

---

## Common issue: crash-looping with no logs (log dir owned by root)

**Symptom:** `launchctl print gui/$(id -u)/io.github.metacubex.mihomo` shows
`state = spawn scheduled` (or `waiting`), `active count = 0`, `last exit code = 1`,
and both `mihomo.log`/`mihomo.error.log` are empty or stuck at an old timestamp
(mihomo isn't even starting, so it never gets a chance to log anything itself).

**Cause:** `~/Library/Logs/mihomo/` and/or its log files got re-owned by `root`
(observed via `sudo ls -la ~/Library/Logs/mihomo/` — owner shows `root` instead
of your user). This can happen when a `darwin-rebuild`/`just build` activation
run recreates or reloads the launchd agent before the `mihomoSetup` activation
script's `chown -R` has taken effect. Since launchd runs the agent as your user
(not root), it can't open a root-owned log file, and the whole `/bin/sh -c '...'`
job fails before mihomo even execs.

**Check for it:**

```bash
sudo ls -la ~/Library/Logs/mihomo/   # look for owner != your username
log show --predicate 'eventMessage contains "mihomo"' --last 1h --info | grep FATAL
```

The second command surfaces the `logger`-based FATAL message the launchd job
emits via syslog when it detects the log dir isn't writable — this still shows
up even when the log *files themselves* can't be written to.

**Fix:**

```bash
sudo chown -R $(whoami):staff ~/Library/Logs/mihomo/
launchctl kickstart -k gui/$(id -u)/io.github.metacubex.mihomo
```
