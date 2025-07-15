# just is a command runner, Justfile is very similar to Makefile, but simpler.

hostname := "Rorschach"

# List all the just commands
default:
  @just --list

############################################################################
#
#  Smart Proxy System
#
############################################################################

# Smart proxy detection and configuration
# Modes: auto (detect terminal proxy), local (127.0.0.1:7890), network (10.0.0.5:7890), off (no proxy)
[group('build')]
smart-proxy mode="auto":
  #!/usr/bin/env bash
  set -euo pipefail
  
  case "{{mode}}" in
    "auto")
      if [ -n "${http_proxy:-}" ]; then
        echo "🔍 Terminal proxy detected: $http_proxy"
        if [[ "$http_proxy" == *"127.0.0.1"* ]]; then
          echo "📡 Using terminal proxy (local mode)"
          sudo python3 scripts/darwin_set_proxy.py local
        elif [[ "$http_proxy" == *"10.0.0.5"* ]]; then
          echo "📡 Using terminal proxy (network mode)"
          sudo python3 scripts/darwin_set_proxy.py network
        else
          echo "📡 Unknown terminal proxy, defaulting to local mode"
          sudo python3 scripts/darwin_set_proxy.py local
        fi
      else
        echo "📡 No terminal proxy detected, using local mode"
        sudo python3 scripts/darwin_set_proxy.py local
      fi
      ;;
    "local")
      echo "📡 Forcing local proxy mode (127.0.0.1:7890)"
      sudo python3 scripts/darwin_set_proxy.py local
      ;;
    "network")
      echo "📡 Forcing network proxy mode (10.0.0.5:7890)"
      sudo python3 scripts/darwin_set_proxy.py network
      ;;
    "off")
      echo "📡 Skipping proxy configuration"
      ;;
    *)
      echo "❌ Invalid proxy mode: {{mode}}"
      echo "Valid modes: auto, local, network, off"
      exit 1
      ;;
  esac

############################################################################
#
#  Unified Build Command
#
############################################################################

# Unified build command with host selection, debug mode, and proxy configuration
# Usage: just build [HOST] [--debug] [--proxy MODE]
# Examples:
#   just build                    # Build current host (Rorschach)
#   just build NightOwl           # Build specific host
#   just build --debug            # Build current host with debug
#   just build SilkSpectre --debug # Build specific host with debug
#   just build --proxy network    # Build with specific proxy mode
[group('build')]
build host=hostname proxy_mode="auto" debug="false": (smart-proxy proxy_mode)
  #!/usr/bin/env bash
  set -euo pipefail
  
  # Validate host parameter
  case "{{host}}" in
    "Rorschach"|"NightOwl"|"SilkSpectre"|"rorschach"|"nightowl"|"silkspectre")
      # Normalize host name to match flake configuration
      case "{{host}}" in
        "rorschach") HOST="Rorschach" ;;
        "nightowl") HOST="NightOwl" ;;
        "silkspectre") HOST="SilkSpectre" ;;
        *) HOST="{{host}}" ;;
      esac
      ;;
    *)
      echo "❌ Invalid host: {{host}}"
      echo "Valid hosts: Rorschach, NightOwl, SilkSpectre"
      exit 1
      ;;
  esac
  
  # Build with or without debug flags
  if [ "{{debug}}" = "true" ]; then
    echo "🔧 Debug building $HOST with proxy mode: {{proxy_mode}}"
    sudo darwin-rebuild switch --flake .#$HOST --show-trace --verbose
  else
    echo "🏗️  Building $HOST with proxy mode: {{proxy_mode}}"
    sudo darwin-rebuild switch --flake .#$HOST
  fi

############################################################################
#
#  Quick Host Aliases (Optional - for convenience)
#
############################################################################

# Quick build aliases for each host
[group('build')]
ror proxy_mode="auto": (build "Rorschach" proxy_mode)

[group('build')]
silk proxy_mode="auto": (build "SilkSpectre" proxy_mode)

[group('build')]
owl proxy_mode="auto": (build "NightOwl" proxy_mode)

############################################################################
#
#  Enhanced Testing Commands
#
############################################################################

# Pre-build validation (format and flake check)
[group('test')]
validate:
  @echo "🔍 Running pre-build validation..."
  just fmt
  nix flake check --no-build

# Comprehensive validation with extended checks
[group('test')]
validate-comprehensive:
  @echo "🔍 Running comprehensive validation..."
  just fmt
  nix flake check --no-build
  @echo "🔍 Checking flake inputs..."
  nix flake metadata
  @echo "🔍 Validating all configurations..."
  nix eval .#darwinConfigurations.Rorschach.config.system.build.toplevel --raw > /dev/null
  nix eval .#darwinConfigurations.SilkSpectre.config.system.build.toplevel --raw > /dev/null
  nix eval .#darwinConfigurations.NightOwl.config.system.build.toplevel --raw > /dev/null
  nix eval .#nixosConfigurations.nixos.config.system.build.toplevel --raw > /dev/null

# Build test without switching for specified host
[group('test')]
build-test host=hostname proxy_mode="auto": (smart-proxy proxy_mode) validate
  #!/usr/bin/env bash
  set -euo pipefail
  
  # Validate host parameter
  case "{{host}}" in
    "Rorschach"|"NightOwl"|"SilkSpectre"|"rorschach"|"nightowl"|"silkspectre")
      # Normalize host name to match flake configuration
      case "{{host}}" in
        "rorschach") HOST="Rorschach" ;;
        "nightowl") HOST="NightOwl" ;;
        "silkspectre") HOST="SilkSpectre" ;;
        *) HOST="{{host}}" ;;
      esac
      ;;
    *)
      echo "❌ Invalid host: {{host}}"
      echo "Valid hosts: Rorschach, NightOwl, SilkSpectre"
      exit 1
      ;;
  esac
  
  echo "🏗️  Testing build without switching for $HOST (proxy: {{proxy_mode}})..."
  darwin-rebuild build --flake .#$HOST

# Test multiple hosts with proxy mode
[group('test')]
test-hosts proxy_mode="auto":
  @echo "🔍 Testing all Darwin hosts with proxy mode: {{proxy_mode}}..."
  just smart-proxy {{proxy_mode}}
  @echo "Testing Rorschach..."
  @darwin-rebuild build --flake .#Rorschach >/dev/null 2>&1 && echo "✅ Rorschach build: PASS" || echo "❌ Rorschach build: FAIL"
  @echo "Testing SilkSpectre..."
  @darwin-rebuild build --flake .#SilkSpectre >/dev/null 2>&1 && echo "✅ SilkSpectre build: PASS" || echo "❌ SilkSpectre build: FAIL"
  @echo "Testing NightOwl..."
  @darwin-rebuild build --flake .#NightOwl >/dev/null 2>&1 && echo "✅ NightOwl build: PASS" || echo "❌ NightOwl build: FAIL"

# Test NixOS configurations
[group('test')]
test-nixos:
  @echo "🔍 Testing NixOS configurations..."
  @echo "Testing nixos configuration..."
  @nix build .#nixosConfigurations.nixos.config.system.build.toplevel >/dev/null 2>&1 && echo "✅ NixOS build: PASS" || echo "❌ NixOS build: FAIL"

# Comprehensive test suite with proxy mode
[group('test')]
test-all proxy_mode="auto":
  @echo "🚀 Running comprehensive test suite with proxy mode: {{proxy_mode}}..."
  just validate-comprehensive
  just test-hosts {{proxy_mode}}
  just test-nixos
  @echo "✅ All tests completed!"

# Show current generation for backup reference
[group('test')]
current-gen:
  @echo "📋 Current system generation:"
  @nix profile history --profile /nix/var/nix/profiles/system | head -n 5

# Safe build process: validate → build-test → switch (streamlined)
[group('test')]
safe-build host=hostname proxy_mode="auto": current-gen (build-test host proxy_mode)
  #!/usr/bin/env bash
  set -euo pipefail
  
  # Validate host parameter
  case "{{host}}" in
    "Rorschach"|"NightOwl"|"SilkSpectre"|"rorschach"|"nightowl"|"silkspectre")
      # Normalize host name to match flake configuration
      case "{{host}}" in
        "rorschach") HOST="Rorschach" ;;
        "nightowl") HOST="NightOwl" ;;
        "silkspectre") HOST="SilkSpectre" ;;
        *) HOST="{{host}}" ;;
      esac
      ;;
    *)
      echo "❌ Invalid host: {{host}}"
      echo "Valid hosts: Rorschach, NightOwl, SilkSpectre"
      exit 1
      ;;
  esac
  
  echo "✅ Build test passed! Proceeding with switch..."
  sudo darwin-rebuild switch --flake .#$HOST

# Build matrix testing with proxy modes
[group('test')]
build-matrix:
  @echo "🔍 Testing build matrix with different proxy modes..."
  @echo "Testing with auto proxy mode:"
  @just test-hosts auto
  @echo "Testing with local proxy mode:"
  @just test-hosts local
  @echo "Testing with network proxy mode:"
  @just test-hosts network
  @echo "Testing NixOS configurations:"
  @just test-nixos
  @echo "Validation tests:"
  @just validate-comprehensive

# Integration testing with proxy validation
[group('test')]
test-integration proxy_mode="auto":
  @echo "🔍 Running integration tests with proxy mode: {{proxy_mode}}..."
  @echo "Testing proxy configuration..."
  @just smart-proxy {{proxy_mode}}
  @echo "Testing flake operations..."
  @nix flake check --no-build
  @echo "Testing build process..."
  @just build-test {{hostname}} {{proxy_mode}}
  @echo "✅ Integration tests completed!"

############################################################################
#
#  Proxy Management Commands
#
############################################################################

# Show current proxy status
[group('proxy')]
proxy-status:
  @echo "🔍 Current proxy status:"
  @if [ -n "${http_proxy:-}" ]; then \
    echo "📡 Terminal proxy: ACTIVE"; \
    echo "  HTTP proxy: $http_proxy"; \
    echo "  HTTPS proxy: ${https_proxy:-}"; \
    echo "  SOCKS proxy: ${all_proxy:-}"; \
  else \
    echo "📡 Terminal proxy: INACTIVE"; \
  fi

# Test proxy connectivity
[group('proxy')]
test-proxy mode="auto":
  @echo "🔍 Testing proxy connectivity for mode: {{mode}}..."
  @just smart-proxy {{mode}}
  @echo "Testing HTTP connectivity..."
  @curl -s --connect-timeout 5 --proxy "${http_proxy:-}" https://httpbin.org/ip > /dev/null && echo "✅ HTTP proxy: WORKING" || echo "❌ HTTP proxy: FAILED"

############################################################################
#
#  Generation Management
#
############################################################################

# Rollback to previous generation
[group('rollback')]
rollback:
  @echo "⏪ Rolling back to previous generation..."
  sudo darwin-rebuild rollback

# List recent generations with details
[group('rollback')]
generations:
  @echo "📜 Recent system generations:"
  @nix profile history --profile /nix/var/nix/profiles/system | head -n 10

# Quick fix: rollback if current system has issues
[group('rollback')]
emergency-rollback:
  @echo "🚨 Emergency rollback to last known good generation..."
  sudo darwin-rebuild rollback
  @echo "✅ Rollback complete. Check system status."

############################################################################
#
#  Nix Management
#
############################################################################

# Update all the flake inputs
[group('nix')]
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
  nix flake update {{input}}

# List all generations of the system profile
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
  nix repl -f flake:nixpkgs

# Remove all generations older than 7 days (requires sudo for system profile)
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries (optimized sudo usage)
[group('nix')]
gc:
  @echo "🗑️  Running garbage collection..."
  # System-wide garbage collection (requires sudo)
  sudo nix-collect-garbage --delete-older-than 7d
  # User-specific garbage collection (home-manager)
  nix-collect-garbage --delete-older-than 7d

# Format the nix files in this repo
[group('nix')]
fmt:
  nix-shell -p alejandra --run "alejandra ."

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

############################################################################
#
#  NixOS VM Management
#
############################################################################

# Build and run NixOS VM
[group('nixos')]
nixos-vm:
  nix build .#nixosConfigurations.myVm.config.system.build.vm
  NIX_DISK_IMAGE=~/myVm.qcow2 ./result/bin/run-myVm-vm

# Build NixOS VM with debug output
[group('nixos')]
nixos-vm-debug:
  nix build .#nixosConfigurations.myVm.config.system.build.vm --show-trace --verbose
  NIX_DISK_IMAGE=~/myVm.qcow2 ./result/bin/run-myVm-vm

# Quick alias for VM
[group('nixos')]
vm: nixos-vm

# Generate ISO image for Proxmox VM installation
[group('nixos')]
iso:
  NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix run github:nix-community/nixos-generators --impure -- --format iso --flake .#myVm --system x86_64-linux

# Generate VMA image for Proxmox VM installation
[group('nixos')]
vma:
  NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix run github:nix-community/nixos-generators --impure -- --format proxmox --flake .#myVm --system x86_64-linux

############################################################################
#
#  Initial Setup Commands (for new Mac)
#
############################################################################

[group('setup')]
brew:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install just

[group('setup')]
lix:
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install

[group('setup')]
darwin-channel:
  nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
  nix-channel --update
  nix-build '<darwin>' -A darwin-rebuild
  nix flake update

[group('setup')]
dot:
  ~/result/bin/darwin-rebuild switch --flake .

############################################################################
#
#  Utility Commands
#
############################################################################

# Type clipboard content into VNC console (useful when paste doesn't work)
[group('utility')]
vnc-paste *ARGS='':
  python3 scripts/vnc_paste.py {{ARGS}}

