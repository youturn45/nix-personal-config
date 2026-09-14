# Build Workflow

## Overview

`just build` (and its per-host aliases `ror`/`owl`/`silk`/`ozy`) is the standard entry point for rebuilding a host. It runs two steps before handing off to `darwin-rebuild`/`nixos-rebuild`:

1. **Host resolution & validation** — `_validate-host` / `_resolve-host` (justfile:31-61) normalize aliases (`owl` → `NightOwl`, etc.) and reject unknown hosts before anything else runs.
2. **Proxy configuration** — the `smart-proxy` dependency (justfile:112-146) writes proxy settings into the nix-daemon's launchd plist via `scripts/darwin_set_proxy.py`, restarting the daemon if the setting changed. See `docs/proxy.md` for the full per-tool proxy strategy.

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

Tarball URLs cover the inputs that actually got hit by rate limiting (`nixpkgs-darwin`, `nixpkgs-nixos`, `nixpkgs-unstable`, `nix-darwin`, `home-manager`, `nixvim`), so builds no longer *depend* on GitHub auth at all. The rest of the flake's inputs (`nix-homebrew`, `haumea`, `ghostty`, `nur-ryan4yin`) still use `github:` shorthand — they weren't part of the input restructuring and haven't needed to change.

**Tradeoff of tarball URLs:** they hardcode a branch name (`refs/heads/nixpkgs-26.05-darwin`) rather than treating it as a generic git ref, so if that branch is ever renamed/deleted the URL needs updating by hand — whereas `github:` would just need a new ref string. Both forms still lock to a specific revision in `flake.lock` either way.

## GitHub token / secrets management (disabled)

This repo has `agenix`-based secrets management (`modules/common/_secrets.nix`, `secrets/github-token.age`), originally meant to authenticate `github:`-shorthand flake input fetches against `api.github.com`. It's disabled by default, not deleted — the `agenix` flake input, its `outputs`/`specialArgs` wiring, and the `agenix.darwinModules.default`/`agenix.nixosModules.default` imports are all commented out (search for "DISABLED" in `flake.nix`, `modules/darwin/default.nix`, `modules/nixos/default.nix`), and the module itself lives at `modules/common/_secrets.nix` — underscore-prefixed so `collectModulesRecursively` skips it (see CLAUDE.md's module-discovery rules), rather than deleted.

Why it's off:

- The secret (`secrets/github-token.age`) was encrypted for a different SSH key than the one actually present on these machines (`~/.ssh/Youturn`), so it could never be decrypted here anyway.
- `agenix` (the CLI) is itself installed by this Nix config, so it can't exist before a machine's first successful build — any pre-build script depending on it is circular.
- Tarball URLs (above) already eliminate the need for GitHub auth on the inputs that actually mattered.

**To re-enable:** rename `modules/common/_secrets.nix` back to `secrets.nix`, uncomment the `agenix` input block in `flake.nix` (input definition, `outputs` destructuring, both `specialArgs` `inherit` lines), uncomment `agenix.darwinModules.default`/`agenix.nixosModules.default` in `modules/darwin/default.nix`/`modules/nixos/default.nix`, and re-encrypt `secrets/github-token.age` for whichever SSH key will actually be present on every target machine.

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

## Other build-related recipes

| Recipe | What it does |
|---|---|
| `just build [host] [proxy_mode] [debug]` | Full pipeline described above. `debug=true` adds `--show-trace --verbose`. |
| `just ror` / `just owl` / `just silk` / `just ozy` | Aliases for `build` pinned to a specific host. |
| `just build-test [host]` | `validate` (fmt + `nix flake check`) then `nixos-rebuild`/`darwin-rebuild build` (no switch). Runs `smart-proxy`. |
| `just safe-build [host]` | `current-gen` → `build-test` → switch. Darwin-only. |
| `just test-all` | Builds (not switches) every Darwin host in sequence, reporting pass/fail. |
| `just iso` | Builds the NixOS installer ISO via `nix build`, not `nixos-rebuild`. |
| `just rollback` / `just emergency-rollback` | Roll back to the previous system generation. |
| `just current-gen` / `just generations` / `just history` | Inspect system generations. |
