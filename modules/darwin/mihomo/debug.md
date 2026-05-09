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
