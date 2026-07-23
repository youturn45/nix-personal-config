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
| `ozymandias` | NixOS VM         | x86_64-linux  | Testing | ✅ Ready  |

## ✨ Features

- 🔧 **Modular Architecture** - Automatic module discovery with clean separation of concerns
- 🌐 **Cross-Platform** - Shared configuration between macOS and NixOS
- 🔐 **Secrets Management** - Encrypted secrets with agenix (SSH key-based encryption)
- 🛡️ **Safe Build System** - Validation, testing, and rollback capabilities
- 🎨 **Consistent Theming** - Catppuccin Mocha throughout the system
- ⚡ **Modern Toolchain** - NixVim, Starship, modern CLI tools, and more
- 🌍 **Proxy Stack** - Mihomo (Clash Meta) with Zashboard UI, auto-managed via Git

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
# Unified build command: just build [HOST [PROXY_MODE [DEBUG]]]
just build                         # Build current host (Rorschach), auto proxy
just build NightOwl                # Build specific host
just build Rorschach local         # Build with local proxy (127.0.0.1:7890)
just build Rorschach auto true     # Build with debug/verbose output

# To use a remote/network proxy, set $http_proxy before building:
http_proxy=http://10.0.0.3:7890 just build   # auto mode picks it up

# Quick host aliases
just ror                           # Quick build for Rorschach
just silk                          # Quick build for SilkSpectre
just owl                           # Quick build for NightOwl
just ozy                           # Quick build for ozymandias (NixOS)

# Available hosts: Rorschach, NightOwl, SilkSpectre, ozymandias
# Proxy modes: auto (default, uses $http_proxy if set), local (127.0.0.1:7890), off
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
│   ├── common/         # Shared (packages, fonts, secrets)
│   ├── darwin/         # macOS-specific (Homebrew, defaults)
│   └── nixos/          # NixOS-specific (systemd, services)
├── home/               # Home Manager configurations
│   ├── common/         # Shared user configs
│   ├── darwin/         # macOS user configs
│   └── nixos/          # NixOS user configs
├── secrets/            # Encrypted secrets (agenix)
│   ├── secrets.nix     # Authorized SSH keys (agenix rules)
│   ├── README.md       # Secrets management guide
│   └── *.age           # Encrypted files (safe to commit)
├── vars/               # Centralized variables
└── my-lib/             # Custom helper functions
```

> **📖 For architecture and development guide**, see [**CLAUDE.md**](./CLAUDE.md)

## 🛠️ What's Included

### System-Level (modules/)
- **Common**: Shared packages, fonts, secrets (agenix), timezone
- **macOS**: Homebrew integration, system defaults, user management, Nix daemon config
- **NixOS**: System services, hardware configuration

### User-Level (home/)
- **Editors**: NixVim with 7+ LSP servers, Treesitter, autocompletion, formatting; VS Code
- **Development**: Git, SSH, Node.js, Python, Go, LaTeX, formatters, linters
- **Shell**: Zsh, Starship prompt, modern CLI tools
- **Terminal**: Ghostty, Kitty, btop, yazi file manager
- **Theming**: Catppuccin Mocha everywhere
- **Proxy UI**: Zashboard dashboard for Mihomo (cross-platform: launchd/systemd)

### Secrets Management
- **agenix**: SSH key-based encryption for secrets
- **GitHub Token**: Available at `~/.config/github/token`
- **Cross-platform**: Automatic path handling for Darwin/NixOS
- See [secrets/README.md](secrets/README.md) for setup guide

## 🔐 Secrets Management

This configuration uses [agenix](https://github.com/ryantm/agenix) for encrypted secrets management.

### Quick Start

```bash
# 1. Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "agenix-key-$(hostname)"

# 2. Update secrets/secrets.nix with your public key
cat ~/.ssh/id_ed25519.pub
# Copy and update the key in secrets/secrets.nix

# 3. Create and encrypt your GitHub token
RULES=secrets/secrets.nix agenix -e secrets/github-token.age -i ~/.ssh/id_ed25519

# 4. Build and apply
just safe-build

# 5. Verify
cat ~/.config/github/token
```

See [**secrets/README.md**](secrets/README.md) for comprehensive setup and usage guide.

## 📚 Documentation

- [**CLAUDE.md**](./CLAUDE.md) - Architecture guide and development workflows
- [**secrets/README.md**](secrets/README.md) - Secrets management with agenix
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
