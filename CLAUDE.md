# CLAUDE.md

Nix configuration for macOS (nix-darwin) and NixOS. Uses Flakes with automatic module discovery.

**Claude cannot run Nix builds.** Review code only — user runs builds.

## Quick Reference

```bash
just fmt          # Format all Nix files — always run before committing
just build        # Build current host
just safe-build   # Validate, test, then build
```

## Module Placement

**System-level** (requires root) → `modules/`
**User-level** (dotfiles, packages) → `home/`

| Scope | Both platforms | macOS only | NixOS only |
|---|---|---|---|
| System | `modules/common/` | `modules/darwin/` | `modules/nixos/` |
| User | `home/common/` | `home/darwin/` | `home/nixos/` |

Cross-platform modules use `pkgs.stdenv.isDarwin` for platform-specific paths/groups.

## Key Patterns

**Automatic module discovery** — `collectModulesRecursively` in `my-lib/default.nix`:
- Files/dirs starting with `_` are ignored
- The root `default.nix` of an imported directory is excluded from recursive collection
- Nested `*/default.nix` replaces sibling files in that folder

**Double-import risk** — never both explicitly import a subdirectory and recursively collect it.

**Standard import pattern:**
```nix
imports = [
  ../common
] ++ (myLib.collectModulesRecursively ./.);
```

**Variables** — all in `vars/default.nix`, accessed as `myvars.*`. Never hardcode usernames or paths.

## Secrets (Agenix)

- `secrets/secrets.nix` — authorized SSH keys per secret
- `modules/common/secrets.nix` — system-level secret config (cross-platform)
- `secrets/*.age` — encrypted files, safe to commit

Never commit unencrypted secrets. Use `${homeDir}` and `${userGroup}` for cross-platform paths.

Adding a secret: define in `secrets/secrets.nix` → encrypt → add to `modules/common/secrets.nix` → build.

## Before Committing

- [ ] `just fmt` — format all Nix files
- [ ] Module is in the correct directory (common vs platform-specific)
- [ ] No hardcoded paths or usernames — use `myvars.*` and `${homeDir}`
- [ ] No unencrypted secrets committed
- [ ] Platform conditionals used in cross-platform modules

## Notes

- **Theme**: Catppuccin Mocha
- **NixVim**: loaded via `home-manager.sharedModules`
- **Proxy config**: do not modify
- **State versions**: in `vars/default.nix` — don't change without reason
- **File prefix `_`**: ignored by module loader

## Reference

- Nix language: https://nix.dev/
- nix-darwin options: https://daiderd.com/nix-darwin/manual/
- NixOS options: https://search.nixos.org/options
- Home Manager options: https://nix-community.github.io/home-manager/options.html
- Secrets: `secrets/README.md`
