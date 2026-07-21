# Proxy Setup

## Overview

All mirrors have been dropped — every tool below hits origin directly, routing through the local mihomo proxy only when one is actually reachable.

| Tool | Strategy | Detection | Inherits shell `HTTP(S)_PROXY`? | Config location |
|---|---|---|---|---|
| Homebrew | Origin, via proxy if reachable | Dynamic (`nc` check on activation: inherited proxy, then `127.0.0.1:7890`) | Yes, by design — script reads it, then re-exports for curl/git | `modules/darwin/homebrew-proxy.nix` |
| Go (`go install`, `go get`) | Origin, via proxy if set | None — no activation-time detection | Yes — Go's `net/http.ProxyFromEnvironment` honors it natively; `GOPROXY` uses Go's built-in default (`https://proxy.golang.org,direct`) | `home/common/dev-tools/go/default.nix` |
| Nix (binary cache) | Origin only | None | No — daemon-level, see below | `modules/darwin/nix-core.nix` uses Nix's built-in default substituters (just `cache.nixos.org`) |
| uv | Origin only | None | Yes — reqwest/pip-style env detection, no config needed | `home/common/python/default.nix` (`index-url = https://pypi.org/simple`) |
| pip | Static mirror only | None | Yes — pip's vendored `requests` library auto-detects it, no config needed | `home/common/dev-tools/_pip/default.nix` (unchanged, out of scope) |
| npm/pnpm | Origin only | None | **No** — npm ignores raw `HTTP_PROXY`/`http_proxy`; needs `npm_config_proxy`/`npm_config_https_proxy` instead (now exported by the `proxy` zsh function) | `home/common/terminal/shells/.zshrc` |
| bun | Origin only | None | Yes — reads `HTTP_PROXY`/`HTTPS_PROXY` natively | n/a |

System proxy itself (Wi-Fi/LAN HTTP+SOCKS) is set by the Mihomo launchd agent — see below.

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

## Package Manager / Tooling Integration

### Homebrew

**File:** `modules/darwin/homebrew-proxy.nix` — runs as a `system.activationScripts.homebrew` block (root, on every build).

Decision order:
1. If `http_proxy`/`HTTP_PROXY` is inherited **and** reachable (`nc -z`) → use it.
2. Else if `127.0.0.1:7890` (local mihomo) is listening → use it directly, even without an inherited env var.
3. Else → unset every `HOMEBREW_*`/proxy env var and hit origin (Homebrew/GitHub) with no proxy at all.

No mirror env vars (`HOMEBREW_BOTTLE_DOMAIN`, `HOMEBREW_API_DOMAIN`, etc.) are ever set — they're only unset, defensively, in case they leaked in from an interactive shell.

**Env inheritance:** `curl` (used by `brew`'s downloader) and `git` both honor lowercase `http_proxy`/`https_proxy` natively. This has historically been inconsistent for uppercase `HTTPS_PROXY` and gets stripped under `sudo` without `-E` — which is why the activation script explicitly re-exports all four (`http_proxy`, `https_proxy`, `HTTP_PROXY`, `HTTPS_PROXY`) itself rather than relying on whatever the caller already has set.

### Go (`go install`, `go get`)

**File:** `home/common/dev-tools/go/default.nix`.

No detection logic at all. `GOPROXY` is left unset, so Go uses its own built-in default (`https://proxy.golang.org,direct`) — origin first, direct fallback, both native to the `go` binary. Go's standard `net/http` client calls `http.ProxyFromEnvironment`, which honors `HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY` (or lowercase) automatically — so whatever proxy the `proxy` zsh function exported is picked up with zero extra config.

### Nix (binary cache substituters)

**File:** `modules/darwin/nix-core.nix` — no longer overrides `nix.settings.substituters`; Nix's built-in default (`https://cache.nixos.org`) is used as-is.

Note: `flake.nix` has a commented-out `nixConfig` block referencing a USTC mirror — it's inactive and unrelated to the system substituters above.

**Env inheritance:** this is *not* a "does the tool honor env vars" question — substituter/store fetches run through `nix-daemon`, a system service that doesn't see your interactive shell's exported `HTTP_PROXY`/`http_proxy` (daemons don't inherit a user shell's environment). Proxying the daemon itself goes through a completely separate mechanism: `just build`/`just smart-proxy` calls `scripts/darwin_set_proxy.py`, which writes `http_proxy`/`https_proxy` directly into the nix-daemon's own launchd plist (`/Library/LaunchDaemons/org.nixos.nix-daemon.plist`) and restarts it. That's independent of `.zshrc` and already working — no change needed there.

### uv

**File:** `home/common/python/default.nix` — writes `~/.config/uv/uv.toml` with `index-url = "https://pypi.org/simple"` (origin, no mirror).

**Env inheritance:** uv is Rust/reqwest-based and follows pip's networking conventions — it honors `HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY` natively, no extra config needed.

### pip

**File:** `home/common/dev-tools/_pip/default.nix` — writes `~/.config/pip/pip.conf`.

Static mirror only, no fallback or detection: `index-url = https://mirror.nju.edu.cn/pypi/web/simple` (Nanjing University). Out of scope for the origin-only pass — left as-is. Commented-out alternatives in the same file: `mirror.nju.edu.cn` (dup), `mirrors.bfsu.edu.cn` (Beijing Foreign Studies University).

**Env inheritance:** pip's vendored `requests` library auto-detects `HTTP_PROXY`/`HTTPS_PROXY` (and lowercase) from the environment with no config needed.

### npm / pnpm / bun

**File:** `home/common/dev-tools/nodejs/default.nix` (packages/`.npmrc`), `home/common/terminal/shells/.zshrc` (proxy wiring).

No mirror config, `.npmrc` only sets `prefix`, `cache`, `init-author-name`, `init-license`, `fund=false`, `audit=false`. But npm/pnpm — unlike almost every other tool here — **do not** read raw `HTTP_PROXY`/`http_proxy` (a long-standing, still-open npm limitation). They do read `npm_config_proxy`/`npm_config_https_proxy` env vars, so the `proxy` zsh function now exports those too, mirrored to the same value as `http_proxy`/`https_proxy`, and unsets them in `proxy off`. `bun` is unaffected by this — it reads `HTTP_PROXY`/`HTTPS_PROXY` natively.

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
