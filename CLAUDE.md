# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Nix configuration repository supporting both macOS (nix-darwin) and NixOS systems. The repository uses Nix Flakes and follows a modular architecture pattern with automatic module discovery.

## Build and Development Commands

### Primary Build Commands
```bash
# Build and switch to current host configuration
just darwin

# Debug build with verbose output
just darwin-debug

# Host-specific builds (Rorschach is the main macOS host)
just rorschach        # Build Rorschach configuration
just rorschach-debug  # Debug build for Rorschach
just ror             # Quick build for Rorschach
just ror-switch      # Switch to Rorschach configuration
```

### Nix Management
```bash
just up               # Update all flake inputs
just upp <input>      # Update specific input (e.g., just upp nixpkgs)
just history          # List system generations
just clean            # Remove generations older than 7 days
just gc               # Garbage collect unused store entries
just fmt              # Format nix files in repository
just repl             # Open nix repl
```

### NixOS Build Commands
```bash
# Build and switch NixOS configuration
sudo nixos-rebuild switch --flake .

# Build specific NixOS host
sudo nixos-rebuild switch --flake .#nixos

# Test NixOS configuration without switching
sudo nixos-rebuild test --flake .

# Build NixOS configuration without switching
sudo nixos-rebuild build --flake .
```

### New Mac Setup (Initial Installation)
```bash
just brew             # Install Homebrew and just
just lix              # Install Lix (Nix alternative)
just darwin-channel   # Setup Darwin channels
just dot              # Build and switch to configuration
```

**Important**: Update the `hostname` variable in the Justfile before building (currently set to "Rorschach").

### Build Testing Commands (Recommended for Development)
```bash
# Safe build process - validates, tests, then switches
just safe-build          # Full safe build for current host
just safe-build-host rorschach  # Safe build for specific host

# Individual testing steps
just validate            # Pre-build validation (format + flake check)
just build-test          # Test build without switching
just current-gen         # Show current generation for reference

# Generation management
just generations         # List recent system generations
just rollback           # Rollback to previous generation
just emergency-rollback  # Quick emergency rollback

# Development workflow example:
# 1. Make changes to configuration
# 2. just validate        # Check format and validate flake
# 3. just build-test      # Test build without applying
# 4. just safe-build      # Apply changes if build test passes
# 5. just rollback        # Rollback if issues occur
```

### Build Testing Philosophy

This repository implements a safe-first approach to system configuration changes:

1. **Validation First**: Always check formatting and flake validity before building
2. **Test Before Apply**: Build configurations without switching to catch errors early  
3. **Generation Tracking**: Record current generation before changes for easy rollback
4. **Atomic Operations**: Either the entire build succeeds or fails cleanly
5. **Easy Recovery**: Simple rollback commands for quick recovery

**Recommended Development Workflow:**
- **Development**: Use `just safe-build` for normal development work
- **Experimentation**: Use `just build-test` to test risky changes without applying
- **Emergency**: Use `just emergency-rollback` if system becomes unstable
- **CI/CD**: Use `just validate` in automated pipelines

**Key Benefits:**
- **Prevents broken systems**: Build testing catches errors before they affect your system
- **Fast iteration**: Quick validation feedback loop for development
- **Easy recovery**: One-command rollback to working state
- **Documentation**: Generation history provides audit trail of changes

## Architecture

### Directory Structure
```
├── vars/                    # Global variables (hostname, username, system)
├── my-lib/                  # Custom helper functions
├── darwin-hosts/            # macOS host configurations
│   ├── NightOwl.nix        # NightOwl host configuration
│   ├── SilkSpectre.nix     # SilkSpectre host configuration
│   ├── rorschach.nix       # Rorschach host configuration
│   └── default.nix         # Darwin hosts entry point
├── modules/                 # System modules
│   ├── common/             # Shared between platforms
│   ├── darwin/             # macOS-specific modules
│   │   ├── apps.nix        # Core system settings and Homebrew
│   │   ├── system-settings.nix # macOS defaults and UI preferences
│   │   ├── host-users.nix  # User account management
│   │   └── nix-core.nix    # Core Nix configuration
│   └── _nixos/             # NixOS-specific modules
│       ├── common/         # Common NixOS modules
│       └── vm/             # VM-specific modules
├── home/                   # Home Manager configurations
│   ├── base/               # Base user configurations
│   │   ├── core/           # Core packages and tools
│   │   │   ├── dev/        # Development tools
│   │   │   ├── editors/    # Text editors (neovim)
│   │   │   ├── python/     # Python environment
│   │   │   └── shells/     # Shell configurations
│   │   ├── _tui/           # Terminal UI applications
│   │   │   ├── _gpg/       # GPG configuration
│   │   │   ├── _password-store/ # Password store
│   │   │   ├── editors/    # Terminal editors
│   │   │   ├── encryption/ # Encryption tools
│   │   │   └── zellij/     # Terminal multiplexer
│   │   └── gui/            # GUI applications
│   │       ├── media.nix   # Media applications
│   │       └── terminal/   # Terminal applications (Ghostty)
│   └── server/             # Server-specific configurations
├── nixos-hosts/            # NixOS host definitions
│   └── nixos/              # NixOS VM configuration
│       ├── boot.nix        # Boot configuration
│       ├── hardware-configuration.nix # Hardware settings
│       ├── proxy.nix       # Proxy configuration
│       └── terminfo.nix    # Terminal information
└── scripts/                # Utility scripts
    ├── darwin_set_proxy.py # Darwin proxy setup
    └── vnc_paste.py        # VNC paste utility
```

### Key Architecture Patterns

1. **Automatic Module Discovery**: Uses custom `collectModulesRecursively` function from `my-lib/helpers.nix` to automatically import modules. Files/directories starting with `_` are ignored.

2. **Modular Design**: Clear separation between system configuration (`modules/`), user configuration (`home/`), and host-specific settings (`hosts/`).

3. **Cross-Platform Support**: Shared modules in `modules/common/` with platform-specific overrides in `modules/darwin/` and `modules/_nixos/`.

4. **Centralized Variables**: All system variables (hostname, username, timezone) defined in `vars/default.nix`.

### Current Hosts
- **Rorschach**: MacBook Air M4 (primary Darwin host)
- **NightOwl**: Darwin host configuration
- **SilkSpectre**: Darwin host configuration
- **nixos**: NixOS VM for testing

## Development Environment

The repository includes a development shell with:
- Node.js 22 with npm configured for user-local packages
- claude-code automatically installed
- Minimal shell variant available for testing

Access via: `nix develop`

## Important Notes

- **Centralized Variables**: All system settings (versions, user info) are centralized in `vars/default.nix`
- **System Configuration**: 
  - `modules/darwin/apps.nix`: Core system settings and Homebrew
  - `modules/darwin/system-settings.nix`: macOS defaults and UI preferences
- **Proxy Configuration**: The build process includes proxy setup for Chinese networks (`darwin-set-proxy`)
- **Claude Code Integration**: Development shell automatically includes claude-code
- **Theme**: Uses Catppuccin Mocha theme throughout the system
- **File Naming**: Files/directories starting with `_` are excluded from automatic module discovery
- **Target Directory**: Configuration should be cloned to `~/Zero/nix-config` (per referenced architecture)

## Network Configuration

For builds in environments requiring proxy:
```bash
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
```

## Testing and Validation

Always run `just fmt` before committing to ensure proper Nix file formatting. The repository uses standard nixpkgs formatting conventions.
