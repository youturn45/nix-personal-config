# Mihomo Debug Guide

## How it works

Mihomo runs as a single **root-owned LaunchDaemon** managed by nix-darwin. The `launchd.daemons.mihomo` block in `default.nix` generates `/Library/LaunchDaemons/io.github.metacubex.mihomo.plist`.

**Key plist properties:**
- `RunAtLoad = true` — starts automatically at boot
- `KeepAlive = true` — launchd restarts mihomo if it crashes
- `Label` — `io.github.metacubex.mihomo` (used in all `launchctl` commands)
- Logs go to `~/Library/Logs/mihomo/`

**Startup sequence** (what the plist's shell script does on each launch):
1. Creates the log directory if missing
2. Iterates all network services, skipping Tailscale/Bridge/JTAG/Bluetooth/VPN
3. Sets HTTP and HTTPS proxy to `127.0.0.1:7890` on each service
4. Sets SOCKS5 proxy to `127.0.0.1:7891` on each service
5. `exec`s mihomo with `~/.config/clash.meta` as the config directory

**Management command:**
- `mihomo-sync` — clones or safely fast-forwards `~/.config/clash.meta`, exports important config/rules to the personal iCloud `Mihomo` folder, then restarts the system service. Export and restart helpers are private, not separate commands.

**Activation setup** (prepended to nix-darwin's `launchd` activation script, before the daemon is loaded) — runs on every `darwin-rebuild switch`. It stops any obsolete GUI-domain job, creates the log directory and the two log files, and chowns only those three paths to you; it aborts if any of them is a symlink or the wrong file type. It clones the config repo from GitHub over SSH using `~/.ssh/Youturn` only if the checkout is missing. Existing checkouts are updated explicitly with `mihomo-sync`, which uses the same SSH key and reloads Mihomo after a successful pull. Nix rollbacks do not roll back this separate config checkout.

---

## Check service status

```bash
sudo launchctl print system/io.github.metacubex.mihomo
```

Look for the `state`, `pid`, and `last exit code` fields.

---

## Start / stop / restart

```bash
# Restart (kills and restarts if already running)
sudo launchctl kickstart -k system/io.github.metacubex.mihomo

# Stop
sudo launchctl kill SIGTERM system/io.github.metacubex.mihomo

# Start (if registered but not running)
sudo launchctl kickstart system/io.github.metacubex.mihomo
```

---

## Test config before starting

Run mihomo directly to see parse errors immediately:

```bash
/run/current-system/sw/bin/mihomo -t -d ~/.config/clash.meta
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
```

---

## Re-register plist after nix rebuild

After `just build`, if the service doesn't auto-start:

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/io.github.metacubex.mihomo.plist
```

---

## Sync config from remote

```bash
mihomo-sync   # safe update + engine validation + selective iCloud export + restart
```

---

## Verify proxy is active

```bash
networksetup -getwebproxy Wi-Fi
networksetup -getsecurewebproxy Wi-Fi
networksetup -getsocksfirewallproxy Wi-Fi
```

All three should show `Enabled: Yes` and point to `127.0.0.1`.

If a stale GUI-domain job from an older configuration is still loaded, remove it
before restarting the daemon:

```bash
launchctl bootout gui/$(id -u)/io.github.metacubex.mihomo
sudo launchctl kickstart -k system/io.github.metacubex.mihomo
```

The Nix activation script performs this GUI cleanup automatically during the
migration to the daemon.
