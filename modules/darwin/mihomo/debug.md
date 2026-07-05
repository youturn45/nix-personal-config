# Mihomo Debug Guide

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
