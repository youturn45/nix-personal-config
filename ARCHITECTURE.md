# Nix Personal Configuration - Architecture Documentation

> **Generated**: January 2025  
> **Version**: Production-ready configuration (post-cleanup)  
> **System**: Multi-platform Nix configuration (macOS + NixOS)

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Root Configuration](#root-configuration)
- [Variables System](#variables-system)
- [Helper Libraries](#helper-libraries)
- [System Modules](#system-modules)
- [Home Manager Configuration](#home-manager-configuration)
- [Host Configurations](#host-configurations)
- [Utility Scripts](#utility-scripts)
- [Architecture Patterns](#architecture-patterns)
- [Development Workflow](#development-workflow)

## Overview

This is a sophisticated personal Nix configuration repository that provides a reproducible, modular computing environment across macOS (nix-darwin) and NixOS platforms. Built on Nix Flakes, it features automatic module discovery, centralized variable management, and comprehensive cross-platform support.

### Key Features
- 🏗️ **Modular Architecture**: Automatic module discovery with clean separation of concerns
- 🌐 **Cross-Platform**: Shared configuration between macOS and NixOS
- 🎨 **Consistent Theming**: Catppuccin Mocha theme throughout the system
- ⚡ **Modern Toolchain**: Contemporary CLI tools and development environment
- 🔧 **Centralized Management**: Single source of truth for system variables
- 🚀 **Developer Experience**: Productivity tools via Home Manager and Justfile

## Repository Structure

```
nix-personal-config/
├── flake.nix            # Flake entry point
├── Justfile             # Build/test/workflow commands
├── CLAUDE.md            # Claude Code integration notes
├── ARCHITECTURE.md      # This document
├── README.md            # Project overview
├── vars/                # Centralized variables and networking
│   ├── default.nix
│   └── _networking.nix
├── my-lib/              # Helper library
│   ├── default.nix
│   └── helpers.nix      # collectModulesRecursively
├── modules/
│   ├── common/          # Shared across Darwin and NixOS
│   │   ├── default.nix  # Common module entry point
│   │   └── fonts.nix    # Shared font configuration
│   ├── darwin/          # macOS-specific modules
│   │   └── default.nix  # Imports common + Darwin modules
│   └── nixos/           # NixOS-specific modules
│       ├── default.nix  # Imports common + NixOS modules
│       └── common/      # NixOS common system modules
├── home/                # Home Manager configuration
│   ├── default.nix      # Entry for Home Manager
│   ├── common/          # Cross-platform user configurations
│   │   ├── core.nix
│   │   ├── claude-code/
│   │   ├── dev-tools/
│   │   ├── editors/
│   │   ├── gui/
│   │   ├── python/
│   │   ├── system/
│   │   └── terminal/
│   ├── darwin/default.nix  # Imports ../default.nix (common)
│   └── nixos/default.nix   # Imports ../default.nix (common)
├── hosts/
│   ├── darwin/
│   │   ├── Rorschach.nix
│   │   ├── NightOwl.nix
│   │   └── SilkSpectre.nix
│   └── nixos/
│       ├── default.nix
│       └── hardware-configuration.nix
└── scripts/
    ├── darwin_set_proxy.py
    └── vnc_paste.py
```

## Root Configuration

### flake.nix - Core System Definition

The heart of the configuration, defining inputs, outputs, and system architectures.

**Key Components:**

#### Flake Inputs
```nix
inputs = {
  # official nix pkgs sources
  nixpkgs = {
    url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  nixpkgs-unstable = {
    url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  nixpkgs-stable = {
    url = "github:NixOS/nixpkgs/nixos-24.11";
  };
  nix-darwin = {
    url = "github:lnl7/nix-darwin";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # home-manager, used for managing user configuration
  home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # nix-homebrew, used for managing homebrew packages
  nix-homebrew = {
    url = "github:zhaofengli/nix-homebrew";
  };

  # haumea, used for managing flake imports
  haumea = {
    url = "github:nix-community/haumea/v0.2.2";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # ghostty, used for managing ghostty packages
  ghostty = {
    url = "github:ghostty-org/ghostty";
  };

  # agenix, used for managing secrets
  agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # nixvim, used for managing neovim configuration
  nixvim = {
    url = "github:nix-community/nixvim";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # nur-ryan4yin, custom packages used from ryan4yin
  nur-ryan4yin.url = "github:ryan4yin/nur-packages";
};
```

#### Package Set Creation
```nix
# Optimized helper function for consistent package sets
mkPkgs = nixpkgs: system: import nixpkgs {
  config.allowUnfree = true;
  inherit system;
  hostPlatform = system;
};
```

#### Development Shells
Currently, no `devShells` are defined in `flake.nix`.

Notes:
- Use system packages and Home Manager-provisioned tools for development.
- If desired, add `devShells` to `flake.nix` to enable `nix develop`.

### Justfile - Build Automation

Streamlined command interface for system management and development workflows.

#### Primary Commands
| Command | Description | Usage |
|---------|-------------|--------|
| `just darwin` | Build and switch to current host | Production deployment |
| `just darwin-debug` | Debug build with verbose output | Troubleshooting |
| `just build Rorschach` | Build Rorschach configuration | Host-specific build |
| `just ror` | Quick build for Rorschach | Host-specific alias |

#### Maintenance Commands
| Command | Description | Purpose |
|---------|-------------|---------|
| `just up` | Update all flake inputs | Dependency management |
| `just upp <input>` | Update specific input | Targeted updates |
| `just gc` | Garbage collect unused entries | Storage cleanup |
| `just clean` | Remove old generations (7+ days) | System maintenance |
| `just fmt` | Format Nix files | Code consistency |

#### Setup Commands (New Mac)
```bash
just brew           # Install Homebrew and just
just lix            # Install Lix (Nix alternative)
just darwin-channel # Setup Darwin channels
just dot            # Build and switch to configuration
```

**Integration Points:**
- Works with `darwin_set_proxy.py` for network configuration
- Integrates with nix-darwin rebuild process
- Supports both stable and development workflows

## Variables System

### vars/default.nix - Centralized Configuration

Single source of truth for all system variables with built-in validation.

```nix
{
  # User Information
  username = "youturn";
  userfullname = "David Liu";
  useremail = "youturn45@gmail.com";
  
  # System Configuration
  system = "aarch64-darwin";
  hostname = "Rorschach";
  timeZone = "Asia/Shanghai";
  
  # Darwin System Settings
  darwinStateVersion = 6;
  primaryUser = "youturn";
  
  # Home Manager Settings
  homeStateVersion = "25.05";
}
```

**Validation Features:**
- Username/hostname empty string checks
- System architecture validation
- primaryUser consistency enforcement
- Error messages for invalid configurations

**Benefits:**
- Single point of maintenance
- Type safety and validation
- Consistent variable usage across modules
- Easy environment adaptation

### vars/_networking.nix - Network Topology

Defines network infrastructure for homelab and development environments.

**Components:**
- Gateway and DNS server configuration
- Host address mapping with interface specifications
- SSH configuration generation (known_hosts, host aliases)
- Support for physical machines, VMs, and Kubernetes clusters

## Helper Libraries

### my-lib/helpers.nix - Module Discovery System

Automated Nix module collection with intelligent filtering.

#### collectModulesRecursively Function

**Purpose**: Automatically discover and import Nix modules from directory trees

**Rules:**
- Files/directories starting with `_` are ignored
- `default.nix` at root level is excluded
- Subdirectories with `default.nix` only include that file
- Other files in subdirectories are ignored if `default.nix` exists

**Example:**
```nix
collectModulesRecursively ./modules
# Returns: [
#   ./modules/network/nginx.nix
#   ./modules/network/acme/default.nix
#   ./modules/sshd.nix
# ]
```

**Integration**: Used throughout the module system for automatic imports, reducing manual maintenance.

### my-lib/default.nix - Configuration Templates

System configuration generators for different platforms.

**Available Templates:**
- `mkHome`: Home Manager configuration generator
- `mkNixos`: NixOS system generator with ISO support
- `mkDarwin`: Darwin system generator
- `forAllSystems`: Cross-platform system utilities

## System Modules

### modules/common/ - Cross-Platform Configuration

Shared settings that work across both NixOS and Darwin systems.

**Features:**
- Centralized timezone configuration
- Common system utilities
- Cross-platform compatibility layer
- Base security settings

### modules/darwin/ - macOS-Specific Configuration

#### apps.nix - Application Management
**Purpose**: Comprehensive application installation and management for macOS

##### System Packages (Nix)
```nix
environment.systemPackages = [
  # Core system tools
  curl wget git just
  # Compression utilities
  zip p7zip zstd
  # System utilities
  coreutils nano jq
  # Network tools
  httpie mtr
];
```

##### Homebrew Integration
- **Mac App Store Apps**: WeChat, TencentMeeting
- **Formulae**: libomp, batt, ffmpeg
- **Casks**: Browsers, productivity tools, terminals, media apps

**Management Features:**
- Automatic updates and cleanup
- Consistent application versioning
- GUI application support via Homebrew
- System-wide tool availability

#### system-settings.nix - macOS Preferences
**Purpose**: Comprehensive macOS defaults and UI configuration

##### Dock Configuration
```nix
dock = {
  orientation = "left";
  autohide = true;
  mru-spaces = false;
  show-recents = false;
  persistent-apps = [
    "/Applications/Arc.app"
    "/Applications/Obsidian.app"
    # ... more apps
  ];
};
```

##### System Preferences
- **UI/UX**: Dark mode, reduced motion, key repeat settings
- **Input**: Trackpad tap-to-click, three-finger drag
- **Finder**: Show extensions, search current folder
- **Security**: Touch ID for sudo authentication
- **Fonts**: Comprehensive font installation (Nerd Fonts, Chinese fonts)

#### nix-core.nix - Nix Configuration
**Purpose**: Nix daemon optimization and platform integration

**Features:**
- Flakes and nix-command experimental features
- Cross-platform support (x86_64-darwin, aarch64-darwin)
- Automatic optimization and garbage collection
- Zsh integration with Nix profile loading
- Unfree package allowance

#### host-users.nix - User Management
**Purpose**: Host and user account configuration

**Configuration:**
- Hostname and computer name from centralized variables
- User account creation with home directory setup
- SMB NetBIOS name configuration
- User shell assignment (zsh)

### modules/_nixos/ - NixOS-Specific Configuration

#### common/ - Shared NixOS Modules
**Purpose**: Shared NixOS settings used by all NixOS hosts

**Included:**
- Printing and other common services
- Cross-cutting configuration shared by bare-metal and VMs

## Home Manager Configuration

### home/default.nix - User Environment Entry Point

**Features:**
- User information from centralized variables
- Home Manager self-management and updates
- PATH configuration for Nix profiles
- Module discovery integration

### home/base/core.nix - Essential User Tools

#### core.nix - Modern CLI Toolchain
**Purpose**: Contemporary replacements for traditional Unix tools

##### Tool Categories

**File Operations:**
- `eza`/`lsd` → Modern `ls` with colors and icons
- `bat` → Enhanced `cat` with syntax highlighting
- `fd` → Fast `find` replacement
- `ripgrep` → Blazing fast `grep`

**System Monitoring:**
- `btop` → Modern `htop` with better visualization
- `gdu` → Disk usage analyzer with ncurses interface
- `du-dust` → Intuitive `du` replacement
- `duf` → Better `df` with colored output

**Development Tools:**
- `lazygit` → Terminal UI for Git
- `delta` → Enhanced Git diff viewer
- `hyperfine` → Command-line benchmarking tool
- `ast-grep` → Structural search and replace

**Nix Ecosystem:**
- `nix-output-monitor` → Better Nix build output
- `hydra-check` → Check Hydra build status
- `nix-tree` → Visualize Nix dependency trees
- `nix-melt` → Nix flake analysis

**Theme Integration:**
- Consistent Catppuccin Mocha theme across all tools
- Coordinated color schemes and styling
- Custom configuration for each tool

#### terminal/shells/default.nix - Advanced Shell Configuration
**Purpose**: Enhanced Zsh experience with modern features

**Plugin System (zplug):**
```nix
plugins = [
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-completions"
  "zsh-users/zsh-syntax-highlighting"
  "zsh-users/zsh-history-substring-search"
  "Aloxaf/fzf-tab"  # Enhanced tab completion
];
```

**PATH Management:**
- Local binary directories (`~/.local/bin`, `~/go/bin`, `~/.cargo/bin`)
- Development tool integration
- Custom script locations

#### dev/ - Development Environment

##### starship/default.nix - Advanced Prompt
**Purpose**: Three-line shell prompt with comprehensive information

**Layout:**
```
Line 1: 👤 user@host 🕐 time
Line 2: 📂 directory 🌿 git 🔧 languages
Line 3: ❯ command prompt
```

**Features:**
- Language detection (Node.js, Python, Rust, Java, Go)
- Cloud platform integration (AWS, GCloud)
- Container technology detection (Docker, Kubernetes)
- Git status with detailed branch and change indicators
- Performance-optimized display
- Emoji integration throughout

##### git/default.nix - Git Configuration
**Purpose**: Comprehensive Git setup with modern workflows

**Core Configuration:**
```nix
userName = vars.userfullname;
userEmail = vars.useremail;
defaultBranch = "main";
```

**Enhanced Features:**
- Delta integration for beautiful diffs
- Extensive alias collection for common operations
- Conditional configuration for work projects
- SSH URL replacement for GitHub
- Modern Git settings (auto-setup-remote, rebase pulls)

**Alias Categories:**
- Basic operations (`a`, `c`, `s`, `l`)
- Branch management (`co`, `b`, `bd`)
- Remote operations (`p`, `pf`, `pl`)
- History and inspection (`lg`, `ll`, `wip`)

##### yazi/default.nix - Terminal File Manager
**Purpose**: Modern file management with shell integration

**Features:**
- Multi-shell support (bash, nushell)
- Catppuccin theme integration
- Hidden file display
- Directory-first sorting
- Keyboard-driven interface

### home/base/system/_zellij/default.nix - Terminal Multiplexer
**Purpose**: Modern alternative to tmux with better UX

**Features:**
- Automatic startup in nushell (with conditions)
- Session management and persistence
- Tab and pane management
- Floating window support
- Plugin ecosystem

**Integration:**
- Shell aliases for quick access (`zl`, `za`)
- Automatic session attachment
- Exit handling configuration

### home/base/system/_container/default.nix - Container Tooling
Container-related helper configuration for development workflows.

### home/base/gui/ - GUI Applications

#### terminal/ghostty.nix - GPU-Accelerated Terminal
**Purpose**: High-performance terminal emulator configuration

**Features:**
- Catppuccin Mocha theme integration
- Fira Code font with optimized sizing
- Background transparency and blur effects
- GPU acceleration for smooth rendering
- Shell integration and cursor customization

**Configuration:**
```nix
theme = "catppuccin-mocha";
font-family = "FiraCode Nerd Font";
font-size = 13;
background-opacity = 0.95;
background-blur-radius = 20;
```

## Host Configurations

### hosts/darwin/*.nix - macOS Hosts
macOS host configurations using nix-darwin:
- `Rorschach.nix` — primary development machine (MacBook Air M4)
- `NightOwl.nix` — secondary macOS host
- `SilkSpectre.nix` — tertiary macOS host

### hosts/nixos/default.nix - NixOS Host
Defines the `nixos` system by composing:
- Hardware configuration (`hardware-configuration.nix`)
- Shared modules (`modules/common`, `modules/_nixos/common`)
- Home Manager user configuration (`home/`)
Sets `networking.hostName = "nixos"` for the NixOS target.

## Utility Scripts

### scripts/darwin_set_proxy.py - Network Configuration
**Purpose**: Configurable proxy setup for Nix daemon with multiple network modes

**Features:**
- Automatic nix-daemon plist modification
- Dual proxy mode support: local (127.0.0.1:7890) and network (10.0.0.5:7890)
- Command-line mode selection with intelligent defaults
- Service restart automation with status verification
- Error handling and usage instructions

**Usage:**
```bash
# Local proxy (default)
python3 scripts/darwin_set_proxy.py
python3 scripts/darwin_set_proxy.py local

# Network proxy
python3 scripts/darwin_set_proxy.py network
```

**Integration**: Works with shell proxy functions in .zshrc for consistent proxy management across shell and system-level operations

## Architecture Patterns

### Automatic Module Discovery

**Implementation**: Uses `collectModulesRecursively` function to automatically discover and import modules

**Benefits:**
- Reduces manual module management
- Consistent import patterns
- Easy addition of new modules
- Clear directory organization

**Conventions:**
- Files/directories starting with `_` are ignored
- `default.nix` files are handled intelligently
- Recursive discovery with filtering

### Centralized Variable Management

**Pattern**: Single source of truth in `vars/default.nix`

**Advantages:**
- Easy environment adaptation
- Consistent variable usage
- Input validation and error checking
- Single point of maintenance

**Implementation:**
```nix
# Usage throughout modules
{ vars, ... }: {
  time.timeZone = vars.timeZone;
  networking.hostName = vars.hostname;
}
```

### Cross-Platform Support

**Strategy**: Shared modules with platform-specific overrides

**Structure:**
- `modules/common/` - Universal settings (shared by both platforms)
- `modules/darwin/` - macOS-specific configuration (imports common)
- `modules/nixos/` - Linux-specific configuration (imports common)

**Import Hierarchy:**
```
Build (flake.nix/hosts/)
  ↓
OS-Specific (modules/darwin or modules/nixos)
  ↓
Common (modules/common)
```

**Benefits:**
- Code reuse across platforms
- Consistent experience
- Easy platform migration
- Reduced maintenance overhead
- Clear dependency flow

### Hierarchical Import Pattern

**Pattern**: Build → OS-Specific → Common

**System Modules:**
```nix
# flake.nix (Darwin)
./modules/darwin  # Imports ../common internally

# hosts/nixos/default.nix
../../modules/nixos  # Imports ../common internally
```

**Home Manager:**
```nix
# flake.nix (Darwin)
import ./home/darwin;  # Imports ../default.nix (common) internally

# hosts/nixos/default.nix
import ../../home/nixos;  # Imports ../default.nix (common) internally
```

**Benefits:**
- Single import point at build level
- OS-specific configs control what gets imported
- Clear dependency hierarchy
- No circular dependencies
- Consistent pattern across modules and home

### System-Level Packages

**Pattern**: Shared system packages in `modules/common/default.nix`

**Included Tools:**
- Compression: zip, p7zip, zstd
- Monitoring: htop, fastfetch
- Terminal: tmux
- Networking: curl, wget
- Development: gnumake, jq, just

**Benefits:**
- Available system-wide to all users
- Consistent across Darwin and NixOS
- Essential tools always present
- Reduced per-user package management

### Consistent Theming

**Theme**: Catppuccin Mocha throughout system

**Implementation:**
- Custom theme packages via nur-ryan4yin
- Coordinated color schemes across applications
- Dark mode preference enforcement
- Consistent visual experience

### Modern Toolchain Philosophy

**Approach**: Contemporary replacements for traditional Unix tools

**Benefits:**
- Enhanced user experience
- Better performance
- Improved functionality
- Consistent interface design

## Development Workflow

### Local Development
1. **Environment Setup**: Use system/Home Manager tools (no `nix develop` devShells defined)
2. **Make Changes**: Edit configurations in modular structure
3. **Test Build**: `just darwin-debug` for verbose testing
4. **Deploy**: `just darwin` for production deployment

### Maintenance Workflow
1. **Update Dependencies**: `just up` for all inputs
2. **Clean System**: `just gc` and `just clean`
3. **Format Code**: `just fmt` for consistency
4. **Backup**: Automatic generation management

### Adding New Components
1. Create module in appropriate directory
2. Module automatically discovered via `collectModulesRecursively`
3. Follow existing patterns and conventions
4. Test with debug build before deployment

---

*This documentation reflects the current production-ready state with all architectural improvements, cleanup, and optimizations completed (January 2025).*
