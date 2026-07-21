# Proxy Setup

## Overview

| Tool | Strategy | Detection | Inherits shell `HTTP(S)_PROXY`? | Config location |
|---|---|---|---|---|
| Homebrew | Proxy if reachable, else mirror fallback | Dynamic (`nc` check on activation) | Yes, by design — script reads it, then re-exports both cases for curl/git | `modules/darwin/homebrew-proxy.nix` |
| Go (`go install`) | Proxy if reachable, else mirror fallback | Dynamic (`nc` check on activation) | Yes — both the detection script *and* the `go` binary itself (`net/http.ProxyFromEnvironment`) honor it natively | `home/common/dev-tools/go/default.nix` |
| Nix (binary cache) | Static mirror, then official cache | None — fixed ordered list | **No** for substituter/store fetches — those run through `nix-daemon`, a system service that doesn't see interactive shell env unless explicitly wired into the daemon's own launchd environment | `modules/darwin/nix-core.nix` |
| pip | Static mirror only | None | Yes — pip's vendored `requests` library auto-detects it, no config needed | `home/common/dev-tools/_pip/default.nix` |
| npm | Inherits `HTTP(S)_PROXY`/`http(s)_proxy` from shell env automatically (npm built-in) | None — no `.npmrc` proxy config, relies on shell env | Yes — npm's `proxy`/`https-proxy` config falls back to env vars natively | `home/common/dev-tools/nodejs/default.nix` |

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
1. If `http_proxy`/`HTTP_PROXY` is inherited **and** reachable (`nc -z`) → export it for `http(s)_proxy`/`HTTP(S)_PROXY`, use origin Homebrew/GitHub servers.
2. Else if `mirror.sjtu.edu.cn:443` is reachable → use SJTU (Shanghai Jiao Tong) mirror env vars (`HOMEBREW_BOTTLE_DOMAIN`, `HOMEBREW_BREW_GIT_REMOTE`, `HOMEBREW_CORE_GIT_REMOTE`, `HOMEBREW_PIP_INDEX_URL`). SJTU doesn't serve `HOMEBREW_API_DOMAIN`, so `HOMEBREW_NO_INSTALL_FROM_API=1` forces git-based installs.
3. Else fall back to Tsinghua (TUNA) mirror env vars.

The selected `HOMEBREW_BREW_GIT_REMOTE` is also stamped directly into `/opt/homebrew`'s git config (`git remote set-url origin ...`) so it persists across all future `brew` invocations, not just the activation run.

**Env inheritance:** `curl` (used by `brew`'s downloader) and `git` both honor lowercase `http_proxy`/`https_proxy` natively. This has historically been inconsistent for uppercase `HTTPS_PROXY` and gets stripped under `sudo` without `-E` — which is why the activation script explicitly re-exports all four (`http_proxy`, `https_proxy`, `HTTP_PROXY`, `HTTPS_PROXY`) itself rather than relying on whatever the caller already has set.



### Go (`go install`)

**File:** `home/common/dev-tools/go/default.nix`, in `home.activation.installGoPackages`.

Decision order:
1. If `HTTP_PROXY`/`http_proxy` already inherited → keep it, set `GOPROXY=https://proxy.golang.org,direct`.
2. Else probe `127.0.0.1:7890` (local Mihomo) → use it, same `GOPROXY`.
3. Else probe `10.0.0.3:7890` (LAN Mihomo instance) → use it, same `GOPROXY`.
4. Else no proxy found → `GOPROXY=https://goproxy.cn,https://goproxy.io,direct` (China-friendly mirror chain).

`home.sessionVariables.GOPROXY` is also statically set to the goproxy.cn chain as the shell default outside of activation.

**Env inheritance:** the `go` binary itself uses Go's standard `net/http` client for both GOPROXY requests and direct VCS fetches, which calls `http.ProxyFromEnvironment` — this honors `HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY` (or lowercase) automatically. So the activation script's job is only to *decide which proxy URL to export*; once exported, `go` itself would have picked it up natively even without the script.

### Nix (binary cache substituters)

**File:** `modules/darwin/nix-core.nix` — `nix.settings.substituters`.

Static ordered list, no runtime detection:
1. `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store` (signed with the same key as `cache.nixos.org`)
2. `https://cache.nixos.org` (official, fallback)

Note: `flake.nix` has a commented-out `nixConfig` block referencing a USTC mirror — it's inactive and only would affect flake evaluation itself (not the system substituters above) if uncommented.

**Env inheritance:** unlike the other tools here, this is *not* a simple "does the tool honor env vars" question. Substituter/store fetches run through `nix-daemon`, a system service — it does not see your interactive shell's exported `HTTP_PROXY`/`https_proxy`, since daemons don't inherit a user shell's environment. Setting `export HTTP_PROXY=...` in a terminal has **no effect** on `nix build`/`nix copy` substituter downloads. To proxy the daemon itself you'd need to inject the variable into the daemon's own launchd environment (e.g. `launchctl setenv` + restart, or wiring it into the daemon's plist) — this repo doesn't currently do that, which is why it relies purely on the static mirror order instead. (Flake input fetches like `fetchTarball`/`fetchGit`, which can run client-side rather than through the daemon, may behave differently — not verified here.)

### pip

**File:** `home/common/dev-tools/_pip/default.nix` — writes `~/.config/pip/pip.conf`.

Static mirror only, no fallback or detection: `index-url = https://mirror.nju.edu.cn/pypi/web/simple` (Nanjing University). Commented-out alternatives in the same file: `mirror.nju.edu.cn` (dup), `mirrors.bfsu.edu.cn` (Beijing Foreign Studies University).

**Env inheritance:** pip's vendored `requests` library auto-detects `HTTP_PROXY`/`HTTPS_PROXY` (and lowercase) from the environment with no config needed. So even with the static mirror set, an exported `HTTP_PROXY` in the shell will still be used by pip alongside/instead of the mirror domain.

### npm

**File:** `home/common/dev-tools/nodejs/default.nix`.

No explicit proxy/mirror config in `.npmrc` (only `prefix`, `cache`, `init-author-name`, `init-license`, `fund=false`, `audit=false`) — but npm itself automatically honors proxy env vars per its [config docs](https://docs.npmjs.com/cli/v11/using-npm/config/):
- `proxy` (HTTP): honors `HTTP_PROXY`/`http_proxy` if set.
- `https-proxy` (HTTPS — relevant since the default registry is `https://registry.npmjs.org`): honors `HTTPS_PROXY`/`https_proxy`/`HTTP_PROXY`/`http_proxy` if set (checks both cases).

So whether `npm install` actually goes through Mihomo depends entirely on whether the *current shell* has those env vars exported — unlike Go/Homebrew, there's no activation script here that detects and exports them, so an interactive shell without `HTTP_PROXY` set will go direct with no mirror fallback. Candidate for adding the same dynamic detect-then-fallback pattern used by Go/Homebrew if `npm install` proves slow/unreachable without a proxy.

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
