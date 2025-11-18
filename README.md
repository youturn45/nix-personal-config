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

### Build Commands

```bash
# macOS (Darwin)
just build              # Build and switch (current host)
just build Rorschach    # Build specific host
just safe-build         # Safe build with validation

# NixOS
sudo nixos-rebuild switch --flake .#nixos

# Maintenance
just up     # Update flake inputs
just fmt    # Format Nix files
just gc     # Garbage collect
just clean  # Remove old generations
```

### Safe Development Workflow

```bash
# 1. Make configuration changes
# 2. Validate and test
just validate
just build-test

# 3. Apply if tests pass
just safe-build

# 4. Rollback if needed
just rollback
```

## 📁 Project Structure

```
nix-personal-config/
├── flake.nix           # Flake entry point
├── Justfile            # Build commands
├── hosts/              # Host-specific configurations
├── modules/            # System-level modules
│   ├── common/         # Shared (Darwin + NixOS)
│   ├── darwin/         # macOS-specific
│   └── nixos/          # NixOS-specific
├── home/               # Home Manager configurations
│   ├── common/         # Shared user configs
│   ├── darwin/         # macOS user configs
│   └── nixos/          # NixOS user configs
└── vars/               # Centralized variables
```

> **📖 For detailed architecture documentation**, see [**ARCHITECTURE.md**](./ARCHITECTURE.md)

## 🛠️ What's Included

### System-Level (modules/)
- Cross-platform shared packages (compression, monitoring, networking)
- macOS: Homebrew integration, system settings, user management
- NixOS: System services, hardware configuration

### User-Level (home/)
- **Editors**: NixVim with LSP, Treesitter, autocompletion
- **Development**: Git, SSH, Node.js, Python, LaTeX, formatters
- **Shell**: Zsh, Starship prompt, modern CLI tools
- **Terminal**: Ghostty, btop, yazi file manager
- **Theming**: Catppuccin Mocha everywhere

## 📚 Documentation

- [**ARCHITECTURE.md**](./ARCHITECTURE.md) - Detailed technical architecture and patterns
- [**CLAUDE.md**](./CLAUDE.md) - Claude Code integration guide
- [**todo.md**](./todo.md) - Development roadmap and completed tasks

## 🤝 Contributing

This is a personal configuration, but you're welcome to:
- Use it as inspiration for your own Nix configuration
- Submit issues for bugs or suggestions
- Propose improvements via pull requests

## 📄 License

Provided as-is for educational and reference purposes.

---

*Built with ❤️ using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager)*
