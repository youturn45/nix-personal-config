# Proxy Setup

## Design

Mihomo (Clash Meta) runs as a nix-darwin launchd agent, replacing ClashX Meta as the system proxy.

**Config** is cloned from a private GitHub repo on every `just build`:
- First build: clones `git@github.com:youturn45/clash.meta.git` into `~/.config/clash.meta/`
- Subsequent builds: `git pull --ff-only` to sync latest changes
- SSH key used: `~/.ssh/Youturn`

**On startup**, the launchd agent:
1. Creates the log directory (`~/Library/Logs/mihomo/`)
2. Sets system proxy on all real network interfaces (Wi-Fi, USB LAN — skips Tailscale, Bridge, JTAG)
3. Launches mihomo pointing at `~/.config/clash.meta/`

**Ports** (defined in `~/.config/clash.meta/config.yaml`):

| Port | Protocol | Use |
|------|----------|-----|
| 7890 | HTTP/HTTPS mixed | System web proxy |
| 7893 | SOCKS5 | System SOCKS proxy |
| 9090 | HTTP API | External controller / dashboard |

**Key files:**
- Nix module: `modules/darwin/mihomo.nix`
- Config repo: `~/.config/clash.meta/`
- Logs: `~/Library/Logs/mihomo/`
- LaunchAgent plist: `/Library/LaunchAgents/io.github.metacubex.mihomo.plist`

---

## Debugging Ports

**See all listening ports (no sudo needed):**
```bash
netstat -an -p tcp | grep LISTEN | grep -E "7890|7891|7892|7893|9090|1053"
```

**See which process owns a port (requires sudo for root-owned processes):**
```bash
sudo lsof -nP -i :7890
sudo lsof -nP -i :9090
```

**Test if mihomo is actually serving on 7890:**
```bash
curl -s --max-time 5 -x http://127.0.0.1:7890 https://www.google.com -o /dev/null -w "%{http_code}\n"
# 200 or 302 = working
```

**Check current system proxy settings:**
```bash
networksetup -getwebproxy Wi-Fi
networksetup -getsecurewebproxy Wi-Fi
networksetup -getsocksfirewallproxy Wi-Fi
```

**List all proxy-related processes:**
```bash
ps aux | grep -iE "mihomo|clash|verge" | grep -v grep
```

**Identify port conflicts — check what ClashX Meta's cached config uses:**
```bash
ls ~/Library/Caches/com.MetaCubeX.ClashX.meta/cacheConfigs/
cat ~/Library/Caches/com.MetaCubeX.ClashX.meta/cacheConfigs/<uuid>.yaml | grep -E "port|external-controller"
```

---

## Useful Commands

### Process management

```bash
# Find mihomo PID
pgrep mihomo

# Check all proxy-related processes
ps aux | grep -iE "mihomo|clash|verge" | grep -v grep

# Kill mihomo (needs sudo — launchd will restart it automatically due to KeepAlive)
sudo kill $(pgrep mihomo)

# Kill mihomo and prevent restart (stop the service first)
launchctl stop io.github.metacubex.mihomo
sudo kill $(pgrep mihomo)
```

### LaunchAgent management

```bash
# Check launchd status (exit code 0 = running, 78 = failed to start, -9 = killed)
launchctl list | grep mihomo

# View the installed plist
cat /Library/LaunchAgents/io.github.metacubex.mihomo.plist

# Bootstrap the agent into your user session (if not loaded)
launchctl bootstrap gui/$(id -u) /Library/LaunchAgents/io.github.metacubex.mihomo.plist

# Unload the agent from your user session
launchctl bootout gui/$(id -u)/io.github.metacubex.mihomo

# Restart the agent (unload + reload in one command)
launchctl kickstart -k gui/$(id -u)/io.github.metacubex.mihomo

# List all LaunchAgents plists installed system-wide
ls /Library/LaunchAgents/
ls ~/Library/LaunchAgents/

# List all LaunchDaemons (system-level, run as root)
ls /Library/LaunchDaemons/ | grep -v apple
```

### Logs

```bash
# Live log tail
tail -f ~/Library/Logs/mihomo/mihomo.log
tail -f ~/Library/Logs/mihomo/mihomo.error.log

# Last 50 lines
tail -50 ~/Library/Logs/mihomo/mihomo.log
```

### Config reload (without restarting)

```bash
# Send SIGHUP — mihomo reloads config without dropping connections
sudo kill -HUP $(pgrep mihomo)

# Or via the API
curl -X PUT "http://127.0.0.1:9090/configs?force=true" \
  -H "Content-Type: application/json" \
  -d '{"path": "/Users/youturn/.config/clash.meta/config.yaml"}'
```

### Re-apply system proxy settings manually

Run this if you switch proxy apps and need to point back to mihomo:

```bash
networksetup -listallnetworkservices | tail -n +2 \
  | grep -viE "tailscale|bridge|jtag|bluetooth|vpn" \
  | while IFS= read -r svc; do
    networksetup -setwebproxy "$svc" 127.0.0.1 7890 2>/dev/null
    networksetup -setsecurewebproxy "$svc" 127.0.0.1 7890 2>/dev/null
    networksetup -setsocksfirewallproxy "$svc" 127.0.0.1 7893 2>/dev/null
  done
```

### Packaged commands

These are available system-wide after `just build`:

```bash
# Pull latest config from GitHub and reload mihomo
mihomo-sync

# Reload mihomo config without pulling (e.g. after manual edits)
mihomo-reload
```
