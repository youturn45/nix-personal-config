# Proxy policy and ownership

## Explicit policy, not opportunistic direct fallback

Home Manager owns shell startup through `youturn.proxy.default`, an enum of
`off`, `local`, and `network`. Its platform default uses `pkgs.stdenv.isDarwin`:
Macs select **local**, Linux selects **off**. Override it in host/user Home Manager
configuration, for example:

```nix
youturn.proxy.default = "network";
# Optional endpoint overrides (URLs must contain an explicit port):
# youturn.proxy.networkHttp = "http://proxy.example:7890";
# youturn.proxy.networkSocks = "socks5://proxy.example:7891";
```

`localHttp/localSocks` default to loopback ports 7890/7891. The existing network
preset remains ports 7890/7891 at 10.0.0.3; nothing discovers a network proxy.
Do not put credentials in Nix options: generated scripts are store-readable.

All endpoint options require nonempty strings; empty values fail evaluation. A
runtime override to empty endpoints blocks the selection with unusable loopback
port-zero URLs rather than leaving a fresh shell in direct mode. For macOS system
settings specifically, only unauthenticated `http://` and `socks5://` endpoints are
supported. TLS-to-proxy, authenticated and role-mismatched URLs are rejected
before any setting is changed; they are never silently reduced to host/port.

Startup invokes the policy once, silently on success. `off` removes inherited
shell proxy variables, including npm and bypass variables. `local` and `network`
export the selection **before** bounded TCP checks. An unavailable endpoint
produces an actionable warning and nonzero function status but leaves the proxy
selected. It never silently changes to direct mode. This is a policy for tools
that honor proxy variables, not a firewall or guarantee against applications
which ignore them.

Both lowercase/uppercase HTTP(S)/ALL_PROXY and `npm_config_proxy` /
`npm_config_https_proxy` are maintained. `NO_PROXY` / `no_proxy` include only
`localhost,127.0.0.1,::1`, never RFC1918 networks. Both unconditional startup
calls previously in `.zshrc` have been removed.

## Existing interactive interface

- `proxy on [local|network]`: select shell proxy and check TCP endpoints.
- `proxy off`: explicitly opt into direct shell mode.
- `proxy show`: show the full selected HTTP and SOCKS proxy URLs; selection
  does not imply reachability.
- `proxy test`: bounded TCP checks followed by the existing explicit end-to-end
  curl check against `https://www.google.com` through the selected HTTP proxy.
  Only this user-invoked command makes that remote request; startup and daemon
  prechecks do not. Tests replace curl and do not make the request.
- `proxy macos-on [local|network]`, `proxy macos-off`: apply macOS system settings;
  permissions may be required. They do not alter the shell selection.

## macOS system settings: one private implementation

`home/common/terminal/shells/proxy-policy.py` is shared by the shell and root
Mihomo daemon via private `proxy-helper.nix`, not installed as a public command.
Deployment invokes absolute `/usr/sbin/networksetup`; tests inject a fake runner
or executable. Disabled `*` service lines and names containing Tailscale, Bridge,
JTAG, Bluetooth or VPN are deliberately skipped.

Each setter failure names its service and action; failures are counted and return
nonzero, never followed by a false “enabled” success. Partial settings may remain:
there is no unsafe automatic rollback/direct fallback. Correct permissions or
settings and retry the intended selection. System bypasses preserve loopback,
`*.local` and link-local `169.254/16`, without RFC1918 bypasses.

The root daemon applies settings **without a TCP precheck**, then starts the
engine only on success. Checking its socket before starting would deadlock first
startup. Failure is visible in its error log and exits the launcher; launchd's
existing KeepAlive may retry. This does not stop an already-running service.
Safe config sync/export/preflight and activation ownership are unchanged;
`mihomo-sync` remains the only public Mihomo management command.

## Nix daemon is a separate owner

Shell and system settings do not configure nix-daemon. The existing
`scripts/darwin_set_proxy.py [local|URL|off]` owns its plist environment. It safely
validates host/port and performs a bounded TCP probe of the chosen proxy before
any plist write or daemon command, including unchanged-plist health checks.
Unreachable proxies raise `ProxyError` with explicit `off` opt-in guidance; no
settings are silently cleared. Diagnostics show the full selected proxy URL. `off`
skips the proxy probe. Existing daemon health/readiness and failed-restart
recovery remain in force. Its injectable probe keeps unit tests offline.

## Other tools and scope

Go, uv, pip and bun retain their native environment handling. npm/pnpm get the
explicit npm variables above. Repository activation/download policies (including
Homebrew) are separate owners; this shell/system change does not claim to
rewrite those policies or remove their existing fallbacks. Nix binary cache
configuration is likewise distinct from daemon proxy environment.

## Verification and deployment boundary

Run offline unit tests with:

```sh
python3 -m unittest discover -s scripts/_tests -p 'test_*proxy*.py'
```

Tests use temporary plists, injected TCP checks, fake networksetup runners, and
`zsh -f` with only the private proxy fragment—not the user's full rc. Generated
Home Manager/daemon projections belong to the repository integration runner.
Source implementation and fixture validation are **not live deployment**: no
switch/build/install/restart, live network settings, private proxy configuration,
credentials or remote/model requests are part of this work.
