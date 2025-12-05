# CLAUDE.md

This file provides guidance to Claude Code when working with this Nix configuration repository.

## Repository Overview

Personal Nix configuration supporting both macOS (nix-darwin) and NixOS systems. Uses Nix Flakes with automatic module discovery and a modular architecture pattern.

**Important**: Claude cannot run Nix build commands. For build instructions, refer to README.md. This document focuses on code architecture and organization.

## Quick Reference

```bash
# Format Nix files (always do this before committing)
just fmt

# User can run builds with:
# just build [hostname]     # Build specific or current host
# just safe-build           # Validate, test, then build
```

## Architecture

### Module Organization Rules

The repository follows a strict module organization pattern:

#### `modules/common/` - Cross-Platform Modules
**Purpose**: Configuration shared between macOS and NixOS

**Rules**:
- ✅ **Include**: System packages, fonts, secrets, time zones, core utilities
- ✅ **Platform-agnostic**: Use conditional logic when paths/groups differ
- ❌ **Exclude**: Platform-specific settings (Homebrew, systemd, macOS defaults)

**Pattern for Platform Detection**:
```nix
let
  homeDir = if pkgs.stdenv.isDarwin
    then "/Users/${username}"
    else "/home/${username}";

  userGroup = if pkgs.stdenv.isDarwin
    then "staff"
    else "users";
in
```

**Current Common Modules**:
- `default.nix` - Shared system packages (compression, monitoring, networking)
- `fonts.nix` - Font packages (Nerd Fonts, Source fonts, icons)
- `secrets.nix` - Agenix secrets configuration (cross-platform)

#### `modules/darwin/` - macOS-Specific Modules
**Purpose**: Configuration exclusive to macOS/nix-darwin

**Rules**:
- ✅ **Include**: Homebrew, macOS system defaults, Aqua settings, Darwin-only services
- ✅ **Darwin APIs**: `system.defaults.*`, `homebrew.*`, Darwin-specific services
- ❌ **Exclude**: Anything that could work on Linux

**Current Darwin Modules**:
- `apps.nix` - Homebrew packages and casks
- `system-settings.nix` - macOS defaults (dock, finder, keyboard, trackpad)
- `host-users.nix` - User account management
- `nix-core.nix` - Nix daemon configuration

#### `modules/nixos/` - NixOS-Specific Modules
**Purpose**: Configuration exclusive to NixOS/Linux

**Rules**:
- ✅ **Include**: systemd services, NixOS system settings, Linux-only services
- ✅ **NixOS APIs**: `systemd.*`, `services.*`, NixOS-specific options
- ❌ **Exclude**: Anything that could work on Darwin

#### `home/` - Home Manager Configurations
**Purpose**: User-level configuration (dotfiles, user packages, user services)

**Organization**:
- `home/common/` - Shared user configs (shell, editors, dev tools)
- `home/darwin/` - macOS-specific user configs
- `home/nixos/` - NixOS-specific user configs

**Decision Tree - Where Does Configuration Go?**:
1. **System-level** (requires root/admin)? → `modules/`
   - Works on both platforms? → `modules/common/`
   - macOS only? → `modules/darwin/`
   - NixOS only? → `modules/nixos/`

2. **User-level** (dotfiles, user packages)? → `home/`
   - Works on both platforms? → `home/common/`
   - Platform-specific? → `home/darwin/` or `home/nixos/`

### Directory Structure
```
├── vars/default.nix        # Global variables (username, system, timezone)
├── my-lib/                 # Custom helper functions
│   ├── default.nix
│   └── helpers.nix         # collectModulesRecursively function
├── hosts/                  # Host-specific configurations
│   ├── darwin/
│   │   ├── Rorschach.nix   # MacBook Air M4
│   │   ├── NightOwl.nix
│   │   └── SilkSpectre.nix
│   └── nixos/
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/                # System configuration
│   ├── common/             # Cross-platform (packages, fonts, secrets)
│   ├── darwin/             # macOS-specific (Homebrew, defaults)
│   └── nixos/              # NixOS-specific (systemd, services)
├── home/                   # Home Manager (user config)
│   ├── common/             # Cross-platform user config
│   │   ├── core.nix
│   │   ├── dev-tools/      # git, ssh, nodejs
│   │   ├── editors/        # neovim (NixVim)
│   │   ├── terminal/       # shells, starship, yazi
│   │   └── gui/            # terminal emulators
│   ├── darwin/
│   └── nixos/
└── secrets/                # Encrypted secrets (agenix)
    ├── secrets.nix         # Authorized SSH keys for secrets
    ├── README.md
    ├── .gitignore
    └── *.age               # Encrypted files
```

### Key Patterns

1. **Automatic Module Discovery**
   - Uses `collectModulesRecursively` from `my-lib/helpers.nix`
   - Files/directories starting with `_` are ignored
   - Each directory's `default.nix` is excluded from recursive import

2. **Centralized Variables**
   - All system variables in `vars/default.nix`
   - Access via `myvars` or `vars` in modules
   - Includes: username, system arch, timezone, state versions

3. **Module Imports Pattern**
   ```nix
   # In modules/darwin/default.nix or modules/nixos/default.nix
   imports = [
     ../common  # Import common modules first
   ] ++ (myLib.collectModulesRecursively ./.);
   ```

4. **Flake Structure**
   - Darwin hosts: `darwinConfigurations.<hostname>`
   - NixOS hosts: `nixosConfigurations.<hostname>`
   - Agenix module included via `agenix.darwinModules.default` or `agenix.nixosModules.default`
   - NixVim loaded via `home-manager.sharedModules`

## Secrets Management (Agenix)

### Architecture
- **secrets/secrets.nix** - Defines authorized SSH keys per secret (rules file)
- **modules/common/secrets.nix** - Cross-platform secret configuration (system module)
- **secrets/*.age** - Encrypted files (safe to commit)

### Platform-Agnostic Design
The secrets module automatically handles platform differences:
```nix
let
  homeDir = if pkgs.stdenv.isDarwin
    then "/Users/${myvars.username}"
    else "/home/${myvars.username}";
  userGroup = if pkgs.stdenv.isDarwin
    then "staff"  # macOS
    else "users"; # NixOS
in
```

### Current Secrets
- `github-token.age` → `~/.config/github/token` (mode: 0400)
  - Environment variable: `$GITHUB_TOKEN_FILE`
  - Helper command: `github-token`
- `ssh-key-rorschach.age` → `~/.ssh/rorschach_agenix` (mode: 0600)

### Adding New Secrets
1. Define in `secrets/secrets.nix` with authorized keys
2. Create encrypted file: `RULES=secrets/secrets.nix agenix -e secrets/name.age -i ~/.ssh/id_ed25519`
3. Add to `modules/common/secrets.nix` with path and permissions
4. Build system to decrypt

See `secrets/README.md` for detailed instructions.

## Code Review Guidelines

Since Nix builds cannot be tested by Claude, follow these review practices:

### 1. Syntax and Structure Review
- **Check Nix syntax**: Proper use of `let...in`, attribute sets, lists
- **Validate imports**: Ensure paths are correct and modules exist
- **Review conditionals**: Platform detection logic is sound
- **Check for typos**: Variable names, paths, package names

### 2. Architecture Compliance
- **Module placement**: Verify code is in correct directory (common vs platform-specific)
- **No duplication**: Check if functionality already exists elsewhere
- **Platform conditionals**: Cross-platform modules use `if pkgs.stdenv.isDarwin`
- **Variable usage**: Use `myvars.*` for centralized variables

### 3. Security Review
- **Secrets**: Never commit unencrypted secrets
- **Permissions**: File modes are appropriate (0400, 0600, 0644)
- **Paths**: No hardcoded usernames or absolute paths (use variables)
- **Groups**: Use platform-specific group variables

### 4. Common Issues to Check
- **Path separators**: Use `/` not backslashes
- **Home directory**: Use `${homeDir}` not hardcoded `/Users/` or `/home/`
- **Package names**: Verify against nixpkgs (common mistakes: `nodejs` vs `node`)
- **Deprecated options**: Check for NixOS/nix-darwin deprecated options
- **Missing dependencies**: Ensure required packages are installed

### 5. Linting Checklist
```bash
# User runs these before committing
just fmt               # Format all Nix files (nixpkgs-fmt)
just validate          # Run flake check (if available)
```

**Your Role**: Before suggesting changes, mentally verify:
1. ✅ Nix syntax is valid
2. ✅ File is in the correct module directory
3. ✅ Platform conditionals are used where needed
4. ✅ No hardcoded paths or usernames
5. ✅ No security issues (exposed secrets, wrong permissions)

## Development Workflow for Claude

### When Making Changes:

1. **Read First**: Always read files before editing
2. **Check Architecture**: Verify correct module location (common vs platform)
3. **Review Pattern**: Follow existing patterns in similar modules
4. **Use Variables**: Reference `myvars.*` instead of hardcoding
5. **Format Aware**: Maintain consistent Nix formatting
6. **Document**: Add comments for complex logic or platform conditionals

### Common Tasks:

**Adding System Package** (available to all users):
- ✅ Cross-platform? → `modules/common/default.nix`
- ✅ macOS only? → `modules/darwin/apps.nix`
- ✅ NixOS only? → Add to appropriate NixOS module

**Adding User Package** (per-user):
- ✅ Goes in `home/common/` if cross-platform
- ✅ Goes in `home/darwin/` or `home/nixos/` if platform-specific

**Adding Configuration**:
1. Determine: System-level or user-level?
2. Determine: Cross-platform or platform-specific?
3. Place in appropriate module directory
4. Use platform conditionals if needed

**Modifying Secrets**:
- Edit `secrets/secrets.nix` to change authorized keys
- Edit `modules/common/secrets.nix` for system configuration
- Never commit unencrypted secrets (`.txt`, `.key`, `.token`)
- Use `${homeDir}` and `${userGroup}` variables for cross-platform paths

## Important Notes

- **No Build Testing**: Claude cannot run Nix builds - rely on code review
- **Formatting Required**: Always format before committing (`just fmt`)
- **Centralized Variables**: Use `vars/default.nix` for system settings
- **Automatic Discovery**: Files starting with `_` are ignored by module loader
- **State Versions**: Defined in `vars/default.nix` (don't change without reason)
- **NixVim**: Uses `home-manager.sharedModules` pattern
- **Proxy Config**: Available but not for Claude to modify
- **Theme**: Catppuccin Mocha (terminal, editor, UI)

## File Naming Conventions

- `default.nix` - Module entry point (auto-imported by parent)
- `_filename.nix` - Ignored by automatic module discovery
- `secrets/secrets.nix` - Authorized keys for agenix (rules file)
- `*.age` - Encrypted secrets (safe to commit)

## Reference Documentation

- Build commands and user workflows → `README.md` (to be created)
- Secrets setup and troubleshooting → `secrets/README.md`
- Nix language → https://nix.dev/
- nix-darwin options → https://daiderd.com/nix-darwin/manual/
- NixOS options → https://search.nixos.org/options
- Home Manager options → https://nix-community.github.io/home-manager/options.html
