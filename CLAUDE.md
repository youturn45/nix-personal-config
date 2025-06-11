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

### New Mac Setup (Initial Installation)
```bash
just brew             # Install Homebrew and just
just lix              # Install Lix (Nix alternative)
just darwin-channel   # Setup Darwin channels
just dot              # Build and switch to configuration
```

**Important**: Update the `hostname` variable in the Justfile before building (currently set to "your-hostname").

## Architecture

### Directory Structure
```
├── vars/                    # Global variables (hostname, username, system)
├── my-lib/                  # Custom helper functions
├── hosts/                   # Host-specific configurations
├── modules/                 # System modules
│   ├── common/             # Shared between platforms
│   ├── darwin/             # macOS-specific modules
│   └── _nixos/             # NixOS-specific modules
├── home/                   # Home Manager configurations
│   ├── base/               # Base user configurations
│   │   ├── core/           # Core packages and tools
│   │   ├── _tui/           # Terminal UI applications
│   │   └── gui/            # GUI applications
└── _nixos-hosts/           # NixOS host definitions
```

### Key Architecture Patterns

1. **Automatic Module Discovery**: Uses custom `collectModulesRecursively` function from `my-lib/helpers.nix` to automatically import modules. Files/directories starting with `_` are ignored.

2. **Modular Design**: Clear separation between system configuration (`modules/`), user configuration (`home/`), and host-specific settings (`hosts/`).

3. **Cross-Platform Support**: Shared modules in `modules/common/` with platform-specific overrides in `modules/darwin/` and `modules/_nixos/`.

4. **Centralized Variables**: All system variables (hostname, username, timezone) defined in `vars/default.nix`.

### Current Hosts
- **Rorschach**: MacBook Air M4 (primary Darwin host)
- **myVm**: NixOS VM for testing

## Development Environment

The repository includes a development shell with:
- Node.js 22 with npm configured for user-local packages
- claude-code automatically installed
- Minimal shell variant available for testing

Access via: `nix develop`

## Important Notes

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