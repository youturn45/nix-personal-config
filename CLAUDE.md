# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Nix configuration repository supporting both macOS (nix-darwin) and NixOS systems. The repository uses Nix Flakes and follows a modular architecture pattern with automatic module discovery.

## Build and Development Commands

### Primary Build Commands
```bash
# Unified build command - all-in-one with options
just build                    # Build current host (Rorschach)
just build NightOwl           # Build specific host
just build --debug            # Build current host with debug output
just build SilkSpectre --debug # Build specific host with debug output
just build --proxy network    # Build with specific proxy mode

# Quick host aliases (for convenience)
just ror                      # Quick build for Rorschach
just silk                     # Quick build for SilkSpectre
just owl                      # Quick build for NightOwl

# Available hosts: Rorschach, NightOwl, SilkSpectre
# Available proxy modes: auto, local, network, off
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
just safe-build              # Full safe build for current host
just safe-build NightOwl     # Safe build for specific host

# Individual testing steps
just validate                # Pre-build validation (format + flake check)
just build-test              # Test build without switching (current host)
just build-test SilkSpectre  # Test build for specific host
just current-gen             # Show current generation for reference

# Generation management
just generations             # List recent system generations
just rollback               # Rollback to previous generation
just emergency-rollback      # Quick emergency rollback

# Development workflow example:
# 1. Make changes to configuration
# 2. just validate            # Check format and validate flake
# 3. just build-test          # Test build without applying
# 4. just safe-build          # Apply changes if build test passes
# 5. just rollback            # Rollback if issues occur
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

### Incremental Configuration Development (NixVim Case Study)

When implementing complex configurations like NixVim, use this proven stepwise approach:

#### **The 7-Step Method:**
1. **Basic Options** - Start with fundamental vim settings (numbers, indentation, search)
2. **Colorscheme** - Add theme/appearance (ensures visual feedback works)
3. **Core Plugins** - Add essential functionality (treesitter for syntax highlighting)
4. **Language Support** - Add LSP servers and language-specific features
5. **Completion & Snippets** - Add autocompletion and snippet support
6. **File Management** - Add file explorer and fuzzy finder (neo-tree, telescope)
7. **Additional Plugins** - Add remaining plugins, UI enhancements, and keymaps

#### **Methodology:**
- **Test each step**: Run `just build-test` after each addition
- **Fix issues immediately**: Address deprecation warnings and errors before proceeding
- **Commit frequently**: Save working states to enable easy rollback
- **Document issues**: Record solutions for deprecated options and compatibility problems

#### **Common NixVim Issues & Solutions:**
- **Module Loading**: Use `home-manager.sharedModules = [nixvim.homeManagerModules.nixvim]`
- **Deprecated Options**: 
  - `tsserver` → `ts_ls`
  - `nvim-cmp` → `cmp` 
  - `lualine.theme` → `lualine.settings.options.theme`
- **Rust Analyzer**: Set `installCargo = false` and `installRustc = false`
- **Web Icons**: Explicitly enable `web-devicons.enable = true`
- **Unfree Packages**: Remove or configure `allowUnfree` for copilot-vim

#### **Benefits of Stepwise Approach:**
- **Pinpoint Issues**: Isolate problems to specific components
- **Maintain Progress**: Never lose working configurations
- **Learn Incrementally**: Understand each plugin's impact
- **Reduce Complexity**: Handle one concern at a time
- **Build Confidence**: See immediate results from each step

## Architecture

### Directory Structure
```
├── vars/                    # Global variables (hostname, username, system)
├── my-lib/                  # Custom helper functions
├── hosts/                   # Host configurations
│   ├── darwin/             # macOS host configurations
│   │   ├── NightOwl.nix    # NightOwl host configuration
│   │   ├── SilkSpectre.nix # SilkSpectre host configuration
│   │   ├── rorschach.nix   # Rorschach host configuration
│   │   └── default.nix     # Darwin hosts entry point
│   └── nixos/              # NixOS host configurations
│       ├── default.nix     # NixOS hosts entry point
│       └── nixos/          # NixOS VM configuration
│           ├── boot.nix    # Boot configuration
│           ├── hardware-configuration.nix # Hardware settings
│           ├── proxy.nix   # Proxy configuration
│           └── terminfo.nix # Terminal information
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
│   │   │   │   ├── git/    # Git configuration
│   │   │   │   ├── npm/    # Node.js and npm setup
│   │   │   │   ├── ssh/    # SSH configuration
│   │   │   │   ├── starship/ # Shell prompt configuration
│   │   │   │   ├── tex/    # LaTeX environment
│   │   │   │   └── _container/ # Container tools
│   │   │   ├── editors/    # Text editors
│   │   │   │   └── neovim/ # NixVim configuration (fully featured)
│   │   │   │       ├── default.nix # Complete NixVim setup with LSP, completion, plugins
│   │   │   │       ├── _default.nix.bak # Backup of previous config
│   │   │   │       ├── _nvim.bak/ # AstroNvim backup directory
│   │   │   │       └── README.md # NixVim setup documentation
│   │   │   ├── python/     # Python environment
│   │   │   ├── shells/     # Shell configurations (zsh, nushell)
│   │   │   └── core.nix    # Core packages and CLI tools
│   │   ├── _tui/           # Terminal UI applications (disabled with _)
│   │   │   ├── _gpg/       # GPG configuration
│   │   │   ├── _password-store/ # Password store
│   │   │   ├── editors/    # Terminal editors
│   │   │   ├── encryption/ # Encryption tools
│   │   │   └── zellij/     # Terminal multiplexer
│   │   └── gui/            # GUI applications
│   │       ├── media.nix   # Media applications
│   │       └── terminal/   # Terminal applications
│   │           └── ghostty.nix # Ghostty terminal emulator
│   ├── darwin/             # macOS-specific user configurations
│   │   └── default.nix     # Darwin user profile entry point
│   └── server/             # Server-specific configurations
└── scripts/                # Utility scripts
    ├── darwin_set_proxy.py # Darwin proxy setup
    └── vnc_paste.py        # VNC paste utility
```

### Key Architecture Patterns

1. **Automatic Module Discovery**: Uses custom `collectModulesRecursively` function from `my-lib/helpers.nix` to automatically import modules. Files/directories starting with `_` are ignored.

2. **Modular Design**: Clear separation between system configuration (`modules/`), user configuration (`home/`), and host-specific settings (`hosts/`).

3. **Cross-Platform Support**: Shared modules in `modules/common/` with platform-specific overrides in `modules/darwin/` and `modules/_nixos/`.

4. **Centralized Variables**: All system variables (hostname, username, timezone) defined in `vars/default.nix`.

5. **NixVim Integration**: Uses `home-manager.sharedModules` approach for proper module loading of NixVim within the Home Manager context.

6. **Incremental Development**: Configuration supports stepwise development with build testing at each stage.

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
  - `modules/darwin/apps.nix`: Core system settings and Homebrew packages
  - `modules/darwin/system-settings.nix`: macOS defaults and UI preferences
  - `modules/darwin/host-users.nix`: User account management
  - `modules/darwin/nix-core.nix`: Core Nix configuration and settings
- **Editor Configuration**: 
  - `home/base/core/editors/neovim/default.nix`: Complete NixVim setup with LSP, completion, treesitter, and essential plugins
  - Supports 7+ LSP servers (Nix, Lua, Rust, Python, TypeScript, Bash, Markdown)
  - Auto-formatting with conform-nvim for multiple languages
  - Full key binding setup for productivity
- **Development Tools**: Comprehensive development environment with formatters, linters, and language servers
- **Proxy Configuration**: Configurable proxy support with local (127.0.0.1) and network (10.0.0.5) modes for shell and nix-daemon
- **Claude Code Integration**: Development shell automatically includes claude-code
- **Theme**: Uses Catppuccin Mocha theme throughout the system (terminal, editor, UI)
- **File Naming**: Files/directories starting with `_` are excluded from automatic module discovery
- **Build Testing**: Comprehensive testing infrastructure with validation, build-test, and rollback capabilities

## Network Configuration

### Proxy Configuration

The repository supports configurable proxy settings with two modes:

#### Shell Proxy Functions (in .zshrc)
```bash
# Local proxy (default) - 127.0.0.1:7890
proxy_on
proxy_on local

# Network proxy - 10.0.0.5:7890  
proxy_on network

# Turn off proxy
proxy_off

# Check proxy status
proxy_status
```

#### Nix-daemon Proxy (for build acceleration)
```bash
# Local proxy (default)
python3 scripts/darwin_set_proxy.py
python3 scripts/darwin_set_proxy.py local

# Network proxy
python3 scripts/darwin_set_proxy.py network
```

**Proxy Presets:**
- **Local**: `127.0.0.1:7890` (HTTP/HTTPS), `127.0.0.1:7891` (SOCKS)
- **Network**: `10.0.0.5:7890` (HTTP/HTTPS), `10.0.0.5:7891` (SOCKS)

## Testing and Validation

Always run `just fmt` before committing to ensure proper Nix file formatting. The repository uses standard nixpkgs formatting conventions.
