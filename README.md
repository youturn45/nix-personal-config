# Personal Nix Configuration

> **A modern, modular Nix configuration for macOS and NixOS systems**

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000.svg?style=for-the-badge&logo=apple&logoColor=white)
![Neovim](https://img.shields.io/badge/Neovim-57A143.svg?style=for-the-badge&logo=neovim&logoColor=white)

</div>

A comprehensive [Nix Flake](https://zero-to-nix.com/concepts/flakes) configuration supporting both macOS (nix-darwin) and NixOS systems. Built with modularity, reproducibility, and cross-platform compatibility in mind.

## 🏠 Managed Systems

| Hostname     | Platform         | CPU           | Role    | Status |
|:-------------|:-----------------|:--------------|:--------|:-------|
| `Rorschach`  | MacBook Air M4   | Apple M4      | Laptop  | ✅ Active |
| `NightOwl`   | Darwin Host      | -             | Desktop | 🚧 Ready  |
| `SilkSpectre`| Darwin Host      | -             | Laptop  | 🚧 Ready  |
| `nixos`      | NixOS VM         | x86_64-linux  | Testing | ✅ Ready  |

## ✨ Features

- 🔧 **Modular Architecture** - Automatic module discovery with clean separation of concerns
- 🌐 **Cross-Platform** - Shared configuration between macOS and NixOS
- 🛡️ **Safe Build System** - Validation, testing, and rollback capabilities
- 🎨 **Consistent Theming** - Catppuccin Mocha throughout the system
- ⚡ **Modern Toolchain** - NixVim, Starship, modern CLI tools, and more

## 🚀 Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [just](https://github.com/casey/just) command runner (optional, for convenient builds)

### Initial Setup (New Mac)

```bash
# Install Homebrew and just
just brew

# Install Nix (or Lix variant)
just lix

# Setup Darwin channels
just darwin-channel

# Build and switch to configuration
just dot
```

**Important**: Update the `hostname` variable in the Justfile before building.

### Regular Build Commands

```bash
# Unified build command - all-in-one with options
just build                    # Build current host (Rorschach)
just build NightOwl           # Build specific host
just build --debug            # Build with debug output
just build --proxy network    # Build with specific proxy mode

# Quick host aliases
just ror                      # Quick build for Rorschach
just silk                     # Quick build for SilkSpectre
just owl                      # Quick build for NightOwl

# Available hosts: Rorschach, NightOwl, SilkSpectre
# Available proxy modes: auto, local, network, off
```

### Safe Development Workflow

```bash
# Full safe build (validates, tests, then switches)
just safe-build              # For current host
just safe-build NightOwl     # For specific host

# Individual testing steps
just validate                # Pre-build validation (format + flake check)
just build-test              # Test build without switching
just build-test SilkSpectre  # Test build for specific host
just current-gen             # Show current generation

# Generation management
just generations             # List recent system generations
just rollback               # Rollback to previous generation
just emergency-rollback      # Quick emergency rollback
```

### Recommended Workflow

1. Make changes to configuration
2. `just validate` - Check format and validate flake
3. `just build-test` - Test build without applying
4. `just safe-build` - Apply changes if build test passes
5. `just rollback` - Rollback if issues occur

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

### Maintenance Commands

```bash
just up               # Update all flake inputs
just upp <input>      # Update specific input (e.g., just upp nixpkgs)
just history          # List system generations
just clean            # Remove generations older than 7 days
just gc               # Garbage collect unused store entries
just fmt              # Format nix files in repository
just repl             # Open nix repl
```

## 📁 Project Structure

```
nix-personal-config/
├── flake.nix           # Flake entry point
├── Justfile            # Build commands
├── hosts/              # Host-specific configurations
│   ├── darwin/         # macOS hosts (Rorschach, NightOwl, SilkSpectre)
│   └── nixos/          # NixOS hosts
├── modules/            # System-level modules
│   ├── common/         # Shared (packages, fonts; secrets support present but disabled, see below)
│   ├── darwin/         # macOS-specific (Homebrew, defaults)
│   └── nixos/          # NixOS-specific (systemd, services)
├── home/               # Home Manager configurations
│   ├── common/         # Shared user configs
│   ├── darwin/         # macOS user configs
│   └── nixos/          # NixOS user configs
├── secrets/            # Encrypted secrets (agenix) -- inert, agenix disabled by default
├── vars/               # Centralized variables
└── my-lib/             # Custom helper functions
```

> **📖 For architecture and development guide**, see [**CLAUDE.md**](./CLAUDE.md)

## 🛠️ What's Included

### System-Level (modules/)
- **Common**: Shared packages, fonts, timezone
- **macOS**: Homebrew integration, system defaults, user management, Nix daemon config
- **NixOS**: System services, hardware configuration

### User-Level (home/)
- **Editors**: NixVim with 7+ LSP servers, Treesitter, autocompletion, formatting
- **Development**: Git, SSH, Node.js, Python, LaTeX, formatters, linters
- **Shell**: Zsh, Starship prompt, modern CLI tools
- **Terminal**: Ghostty, Kitty, btop, yazi file manager
- **Theming**: Catppuccin Mocha everywhere

### Secrets Management (disabled)
This repo has agenix-based secrets support (`modules/common/_secrets.nix`, `secrets/`), but it's disabled by default — the `agenix` flake input is commented out in `flake.nix`. See `docs/build.md` for why (the encrypted secret didn't match any SSH key actually present on these machines) and how to re-enable it.

## 📚 Documentation

- [**CLAUDE.md**](./CLAUDE.md) - Architecture guide and development workflows
- [**docs/build.md**](docs/build.md) - Build pipeline, flake input strategy, disabled secrets management
- [**Justfile**](./Justfile) - Available build commands and automation

## 🤝 Contributing

This is a personal configuration, but you're welcome to:
- Use it as inspiration for your own Nix configuration
- Submit issues for bugs or suggestions
- Propose improvements via pull requests

## 📄 License

Provided as-is for educational and reference purposes.

---

*Built with ❤️ using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager)*
