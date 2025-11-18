# Personal Nix Configuration

> **A modern, modular Nix configuration for macOS and NixOS systems**

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000.svg?style=for-the-badge&logo=apple&logoColor=white)
![Neovim](https://img.shields.io/badge/Neovim-57A143.svg?style=for-the-badge&logo=neovim&logoColor=white)

</div>

This repository contains a comprehensive [Nix Flake](https://zero-to-nix.com/concepts/flakes) configuration supporting both macOS (nix-darwin) and NixOS systems. Built with modularity, reproducibility, and cross-platform compatibility in mind.

## 🏠 Managed Systems

| Hostname     | Platform         | CPU           | Role    | Status |
|:-------------|:-----------------|:--------------|:--------|:-------|
| `Rorschach`  | MacBook Air M4   | Apple M4      | Laptop  | ✅ Active |
| `NightOwl`   | Darwin Host      | -             | Desktop | 🚧 Ready  |
| `SilkSpectre`| Darwin Host      | -             | Laptop  | 🚧 Ready  |
| `nixos`      | NixOS VM         | x86_64-linux  | Testing | ✅ Ready  |

## 🏗️ Architecture

### Repository Structure

```
nix-personal-config/
├── 📁 Configuration Entry Points
│   ├── flake.nix              # Core flake definition
│   ├── Justfile               # Build commands and workflows
│   └── CLAUDE.md              # Claude Code integration guide
├── 📁 vars/                   # Centralized variable management
│   └── default.nix            # System variables with validation
├── 📁 my-lib/                 # Custom helper functions
│   ├── default.nix            # Core helper utilities
│   └── helpers.nix            # Module discovery system
├── 📁 hosts/                  # Host-specific configurations
│   ├── darwin/                # macOS host definitions
│   │   ├── Rorschach.nix      # Primary MacBook Air M4
│   │   ├── NightOwl.nix       # Desktop configuration
│   │   └── SilkSpectre.nix    # Laptop configuration
│   └── nixos/                 # NixOS host definitions
│       ├── default.nix        # NixOS system configuration
│       └── hardware-configuration.nix # Auto-generated hardware config
├── 📁 modules/                # System-level configurations
│   ├── common/                # Cross-platform shared settings
│   ├── darwin/                # macOS-specific modules
│   │   ├── apps.nix           # Application management (Nix + Homebrew)
│   │   ├── system-settings.nix # macOS defaults and preferences
│   │   ├── host-users.nix     # User account management
│   │   ├── nix-core.nix       # Core Nix configuration
│   │   └── _secrets.nix       # Secret management (agenix)
│   └── nixos/                 # NixOS-specific modules
│       └── common/            # NixOS common system modules
├── 📁 home/                   # Home Manager configurations
│   ├── common/                # Cross-platform user configurations
│   │   ├── dev-tools/         # Development tooling
│   │   │   ├── git/           # Git configuration
│   │   │   ├── npm/           # Node.js and npm setup
│   │   │   ├── pip/           # Python package management
│   │   │   ├── ssh/           # SSH configuration
│   │   │   └── tex/           # LaTeX environment
│   │   ├── editors/           # Text editors
│   │   │   └── neovim/        # Complete NixVim configuration
│   │   ├── gui/               # GUI applications
│   │   │   ├── media.nix      # Media applications
│   │   │   └── terminal/      # Terminal emulators
│   │   │       └── ghostty.nix # Cross-platform terminal config
│   │   ├── python/            # Python development environment
│   │   ├── system/            # System utilities
│   │   │   ├── btop/          # System monitor
│   │   │   └── _container/    # Container tools
│   │   └── terminal/          # Terminal environment
│   │       ├── shells/        # Shell configurations (zsh)
│   │       ├── starship/      # Prompt configuration
│   │       └── yazi/          # File manager
│   ├── darwin/                # macOS-specific user configurations
│   └── nixos/                 # NixOS-specific user configurations
└── 📁 scripts/                # Utility scripts
    ├── darwin_set_proxy.py    # Configurable proxy setup
    └── vnc_paste.py           # VNC clipboard utility
```

### Key Features

- 🔧 **Automatic Module Discovery**: Uses custom `collectModulesRecursively` function
- 🌐 **Cross-Platform Support**: Shared configurations between macOS and NixOS
- 📝 **Centralized Variables**: Single source of truth in `vars/default.nix`
- 🎨 **Consistent Theming**: Catppuccin Mocha throughout the system
- 🛡️ **Safe Build System**: Validation, testing, and rollback capabilities
- 🔌 **Configurable Proxy**: Local and network proxy modes
- ⚡ **Modern Development Environment**: Complete toolchain with LSP, formatters, and more

## 🚀 Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [just](https://github.com/casey/just) command runner
- Git for repository management

### Build Commands

```bash
# macOS (Darwin) builds
just build            # Build and switch to current host (Rorschach)
just build Rorschach  # Build specific host
just ror              # Quick alias for Rorschach
just safe-build       # Safe build with validation and testing

# NixOS builds
sudo nixos-rebuild switch --flake .#nixos

# Maintenance
just up                # Update all flake inputs
just fmt               # Format all Nix files
just gc                # Garbage collect unused store entries
just clean             # Remove old generations
```

### Safe Development Workflow

```bash
# 1. Make configuration changes
# 2. Validate changes
just validate

# 3. Test build without applying
just build-test

# 4. Apply changes if tests pass
just safe-build

# 5. Rollback if needed
just rollback
```

## 🛠️ Development Environment

### Editor Configuration

- **NixVim**: Complete Neovim configuration with LSP support
- **Supported Languages**: Nix, Lua, Rust, Python, TypeScript, Bash, Markdown
- **Features**: Auto-completion, syntax highlighting, formatting, debugging
- **Plugins**: Treesitter, telescope, neo-tree, which-key, and more

### Development Tools

- **Git**: Comprehensive configuration with aliases and delta pager
- **Shell**: Zsh with modern CLI replacements and starship prompt  
- **Terminal**: Cross-platform Ghostty configuration
- **Python**: Complete development environment with pip management
- **Node.js**: Version 22 with npm user-local configuration
- **Container Tools**: Docker and container development support

## 🌐 Network Configuration

### Proxy Support

The configuration includes flexible proxy support for different network environments:

```bash
# Shell proxy functions
proxy_on              # Enable local proxy (127.0.0.1:7890)
proxy_on local         # Explicit local proxy
proxy_on network       # Network proxy (10.0.0.5:7890)
proxy_off             # Disable proxy
proxy_status          # Check current proxy status

# System-level proxy (nix-daemon)
python3 scripts/darwin_set_proxy.py          # Local proxy
python3 scripts/darwin_set_proxy.py network  # Network proxy
```

## 📋 System Requirements

### macOS (Darwin)
- **Supported**: Apple Silicon (M1, M2, M3, M4) and Intel Macs
- **OS Version**: macOS 12.0+ (Monterey and later)
- **Dependencies**: Homebrew for GUI applications

### NixOS
- **Architecture**: x86_64-linux, aarch64-linux
- **VM Support**: QEMU guest utilities included
- **Hardware**: Automatic hardware detection

## 🎯 Design Philosophy

### Modular Architecture
- **Separation of Concerns**: Clear boundaries between system, user, and host configurations
- **Reusability**: Shared modules across platforms with platform-specific overrides
- **Maintainability**: Automatic module discovery reduces manual configuration

### Safe-First Approach
- **Validation**: Pre-build checks for syntax and configuration validity
- **Testing**: Build configurations without switching to catch errors early
- **Recovery**: Easy rollback to previous working generations

### Developer Experience
- **Incremental Development**: Step-by-step approach for complex configurations
- **Documentation**: Comprehensive guides and inline documentation
- **Automation**: Justfile commands for common operations

## 📚 Documentation

- [**CLAUDE.md**](./CLAUDE.md): Claude Code integration and usage instructions
- [**ARCHITECTURE.md**](./ARCHITECTURE.md): Detailed technical architecture documentation
- [**todo.md**](./todo.md): Current status and completed improvements

## 🤝 Contributing

This is a personal configuration repository, but feel free to:

- Use it as inspiration for your own Nix configuration
- Submit issues for bugs or suggestions
- Propose improvements via pull requests

## 📄 License

This configuration is provided as-is for educational and reference purposes. Individual components may have their own licenses.

---

*Built with ❤️ using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager)*