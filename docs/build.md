# Build Workflow

## Overview

`just build` (and its per-host aliases `ror`/`owl`/`silk`/`ozy`) is the standard entry point for rebuilding a host. It runs two steps before handing off to `darwin-rebuild`/`nixos-rebuild`:

1. **Host resolution & validation** — `_validate-host` / `_resolve-host` normalize aliases (`owl` → `NightOwl`, etc.) and reject unknown hosts before anything else runs.
2. **Proxy configuration** — the `smart-proxy` dependency passes the selected URL (or `local`/`off`) to `scripts/darwin_set_proxy.py`. The helper checks reachability before applying an enabled proxy, and restarts the daemon only when settings change or an unchanged configuration is unhealthy. `auto` chooses inherited `http_proxy` when set, otherwise local; it does not silently select a different route if that choice is unreachable. See `docs/proxy.md` for the full strategy.

Then the actual switch:

```bash
sudo -E $REBUILD_CMD switch --flake .#$resolved_host
```

`-E` matters — it's what lets `sudo` preserve any inherited proxy env set earlier in the same script.

## Why flake inputs use tarball URLs, not `github:` shorthand

`flake.nix`'s `nixpkgs-darwin`, `nixpkgs-nixos`, `nixpkgs-unstable`, `nix-darwin`, `home-manager`, and `nixvim` inputs are written as plain tarball URLs:

```nix
nixpkgs-darwin.url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-26.05-darwin.tar.gz";
```

rather than the shorter `github:owner/repo/ref` form. This is deliberate. `github:` refs are resolved by Nix's github fetcher, which calls **`api.github.com`** (a separate host from `github.com`) to look up the ref before downloading. That API enforces an unauthenticated rate limit of 60 requests/hour **per source IP**, shared across everything behind the same proxy — easy to blow through during iterative rebuilds. Hitting it fails the build with:

```
error: unable to download 'https://api.github.com/repos/.../commits/...': HTTP error 403
response body: {"message":"API rate limit exceeded for <ip>. ..."}
```

A tarball URL is Nix's plain "tarball" fetcher instead — one ordinary HTTPS GET against `github.com` itself, no API host, no rate limit, no token needed.

Tarball URLs cover the inputs that actually got hit by rate limiting (`nixpkgs-darwin`, `nixpkgs-nixos`, `nixpkgs-unstable`, `nix-darwin`, `home-manager`, `nixvim`), reducing unauthenticated API traffic. Remaining `github:` inputs and transitive inputs can still hit API rate limits and use the agenix token below. The rest of the flake's inputs (`nix-homebrew`, `haumea`, `ghostty`, `nur-ryan4yin`) still use `github:` shorthand — they weren't part of the input restructuring and haven't needed to change.

**Tradeoff of tarball URLs:** they hardcode a branch name (`refs/heads/nixpkgs-26.05-darwin`) rather than treating it as a generic git ref, so if that branch is ever renamed/deleted the URL needs updating by hand — whereas `github:` would just need a new ref string. Both forms verify locked content, but these branch-addressed tarball inputs do **not** record a fixed Git revision. A cold fetch can fail after the branch moves even though a cached evaluation succeeds. Immutable input-address migration is separate work; it is not implemented by the validation fixes.

## GitHub authentication with agenix

GitHub API authentication is managed by `modules/common/secrets/default.nix`.
Agenix decrypts `secrets/github-nix.conf.age` to a runtime file containing
`access-tokens = github.com=…`. The system `nix.conf` includes that file using
`!include`; the token is never evaluated into a Nix derivation or stored in
plaintext in this checkout. Both the configured user and root can read it,
covering direct `nix` commands and the existing `sudo -E` rebuild recipe.

See [secrets setup](../secrets/README.md) for token creation, encryption,
SSH key requirements, and the first authenticated rebuild. Before that encrypted
file exists, evaluation emits a warning and leaves authentication unconfigured.
The obsolete `secrets/github-token.age` is unused.

The first rebuild needs the helper's `run` action: fetching inputs happens before
agenix activation. On Darwin, agenix decrypts through a launchd service at boot
and activation. `!include` tolerates the file being absent before that service
runs; authentication is available to subsequent Nix invocations once it finishes.
An already running daemon may need its normal configuration reload/restart to
pick up a rotated token. Ordinary flake evaluation uses the invoking client's
configuration.

## Troubleshooting

**`error: mismatch in field 'narHash' of input '...archive/refs/heads/BRANCH.tar.gz'`**

The tarball-URL inputs (`nixpkgs-darwin`, `nixpkgs-nixos`, `nixpkgs-unstable`, `nix-darwin`, `home-manager`, `nixvim`) point at branch names, not fixed commits — GitHub regenerates that archive fresh every time the branch gets new commits, same URL, different bytes. `flake.lock` records a checksum (`narHash`) from whenever it was last locked; if upstream has since pushed to that branch (and this repo's own `nix.gc.automatic` 7-day cleanup evicted the old cached copy, forcing a live re-fetch), the freshly-fetched content won't match the old checksum and Nix refuses it rather than silently building something different than what's locked. This is expected, routine drift, not a bug — accepted tradeoff for avoiding `api.github.com` on these inputs. Fix by re-locking just the input named in the error:

```bash
nix flake update <input-name>   # e.g. nix flake update nixvim
```

**Don't reach for a bare `nix flake update` to fix this** — it re-locks *every* input, including the ones still on `github:` shorthand (`nix-homebrew`, `haumea`, `ghostty`, `nur-ryan4yin`), which calls `api.github.com` and can hit the same rate limit this whole tarball-URL setup was meant to avoid:

```
error: unable to download 'https://api.github.com/repos/.../commits/HEAD': HTTP error 403
```

Scope the update to the specific input that actually drifted instead.

## No-build validation and regression tests

`just validate`, `just test`, and `python3 scripts/validate.py` share one entry
point. The default evaluates **all** three Darwin `.system.drvPath` attributes,
Linux's toplevel, and the ISO derivation, in addition to
`nix flake check --no-build --no-write-lock-file`. Flake check alone does not
force Darwin system evaluation. NightOwl's real evaluated projection is passed
through a private mode-0600 temporary file to all three strict regression suites;
empty suites, missing fields, failures and skips fail the run. Temporary data is
removed on success/failure. See [_tests/README.md](../_tests/README.md).

Scopes support CI's existing matrix, not a claim of full local coverage:

```bash
just test --offline                     # all coverage, cached locked inputs
just validate --host NightOwl           # one Darwin host + all strict suites
python3 scripts/validate.py --platform linux # Linux toplevel + ISO
```

Normal locked-input fetching is allowed by default. No package/system build,
lock rewrite, sudo, proxy update or service restart is performed. Formatting is
separate: `just fmt-check` (also explicit in CI) may realize a formatter package
and is therefore not part of this no-build validation.

## Recovery commands (user-run only)

`just rollback` selects the installed platform's supported syntax:
`sudo darwin-rebuild --rollback` on Darwin, and
`sudo nixos-rebuild switch --rollback` on Linux. The Linux flag/action contract
is documented in the pinned nixpkgs source under
`pkgs/by-name/ni/nixos-rebuild-ng/nixos-rebuild.8.scd` (synopsis and `--rollback`).
`emergency-rollback` delegates to the same recipe; it does not bypass failures.
These commands change the live system and are tested only with command spies.

`just generations`, `just history`, and `just current-gen` share the read-only
platform-specific listing: `darwin-rebuild --list-generations` on Darwin,
`nix-env --list-generations --profile /nix/var/nix/profiles/system` on Linux.
They do not use `nix profile history`, whose manifest format differs from
these system profiles.

## First-machine bootstrap

Install upstream Nix with flakes using the current
[Nix instructions](https://nixos.org/download/), then follow
[nix-darwin's flake instructions](https://github.com/nix-darwin/nix-darwin#flakes)
with this checkout and the explicit Darwin host. Inspect the pinned
`nix-darwin` input and configuration first; bootstrap builds and activation are
user actions, not automated validation. Once `darwin-rebuild` is available,
use `just build HOST`. Do not add Darwin channels or update the lock just to
bootstrap. The obsolete `lix`, `darwin-channel` and channel-era `dot` recipes
now fail with guidance and perform no installation or update.

## Other build-related recipes

| Recipe | What it does |
|---|---|
| `just build [host] [proxy_mode] [debug]` | Full pipeline described above. `debug=true` adds `--show-trace --verbose`. |
| `just ror` / `just owl` / `just silk` / `just ozy` | Aliases for `build` pinned to a specific host. |
| `just build-test [host]` | Shared no-build `validate`, then `nixos-rebuild`/`darwin-rebuild build` (no switch). Runs `smart-proxy`. |
| `just safe-build [host]` | `current-gen` → `build-test` → switch. Darwin-only. |
| `just test-all` | Builds (not switches) every Darwin host in sequence, reporting pass/fail. |
| `just iso` | Builds the NixOS installer ISO via `nix build`, not `nixos-rebuild`. |
| `just rollback` / `just emergency-rollback` | Roll back to the previous system generation. |
| `just current-gen` / `just generations` / `just history` | Inspect system generations. |
