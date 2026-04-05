# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Variables
#
############################################################################

# Default hostname for builds
hostname := "Rorschach"

# Available Darwin hosts
darwin_hosts := "Rorschach NightOwl SilkSpectre"

# Available NixOS hosts
nixos_hosts := "ozymandias"

# All hosts including NixOS
all_hosts := darwin_hosts + " " + nixos_hosts

# Proxy configuration (local fallback only — network proxy is read from $http_proxy at runtime)
proxy_local := "127.0.0.1:7890"

############################################################################
#
#  Helper Recipes (Internal)
#
############################################################################

# Resolve host aliases to canonical host names (internal helper)
[private]
_resolve-host host:
  #!/usr/bin/env bash
  set -euo pipefail
  case "{{host}}" in
    Rorschach|rorschach|rorshach|ror)
      echo "Rorschach"
      ;;
    NightOwl|nightowl|night-owl|owl)
      echo "NightOwl"
      ;;
    SilkSpectre|silkspectre|silk-spectre|silk)
      echo "SilkSpectre"
      ;;
    ozymandias|Ozymandias|oz|ozy)
      echo "ozymandias"
      ;;
    *)
      echo "❌ Invalid host: {{host}}" >&2
      echo "Valid hosts: {{all_hosts}}" >&2
      echo "Aliases: ror, owl, silk, oz, ozy, rorshach" >&2
      exit 1
      ;;
  esac

# Validate host parameter (internal helper)
[private]
_validate-host host:
  #!/usr/bin/env bash
  set -euo pipefail
  just _resolve-host "{{host}}" >/dev/null

# Get rebuild command for host (internal helper)
[private]
_rebuild-cmd host:
  #!/usr/bin/env bash
  case "{{host}}" in
    Rorschach|NightOwl|SilkSpectre)
      echo "darwin-rebuild"
      ;;
    *)
      echo "nixos-rebuild"
      ;;
  esac

# Validate Darwin-only host (internal helper)
[private]
_validate-darwin-host host:
  #!/usr/bin/env bash
  set -euo pipefail
  resolved_host="$(just _resolve-host "{{host}}")"
  case "$resolved_host" in
    Rorschach|NightOwl|SilkSpectre)
      exit 0
      ;;
    *)
      echo "❌ Invalid Darwin host: {{host}} (resolved: $resolved_host)"
      echo "Valid Darwin hosts: {{darwin_hosts}}" >&2
      exit 1
      ;;
  esac

############################################################################
#
#  Main Commands
#
############################################################################

# List all available commands
default:
  @just --list

############################################################################
#
#  Proxy Management
#
############################################################################

# Smart proxy detection and configuration
# Modes: auto (use $http_proxy if set, else local), local ({{proxy_local}}), off (disabled)
[group('proxy')]
smart-proxy mode="auto":
  #!/usr/bin/env bash
  set -euo pipefail

  # Skip on non-Darwin platforms
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "📡 Non-Darwin platform, skipping nix-daemon proxy configuration"
    [ -n "${http_proxy:-}" ] && echo "🔍 Terminal proxy detected: $http_proxy (shell-only)"
    exit 0
  fi

  case "{{mode}}" in
    auto)
      if [ -n "${http_proxy:-}" ]; then
        echo "🔍 Terminal proxy detected: $http_proxy"
        sudo python3 scripts/darwin_set_proxy.py "$http_proxy"
      else
        echo "📡 No proxy detected, using local mode"
        sudo python3 scripts/darwin_set_proxy.py local
      fi
      ;;
    local)
      echo "📡 Using local proxy ({{proxy_local}})"
      sudo python3 scripts/darwin_set_proxy.py local
      ;;
    off)
      echo "📡 Proxy disabled"
      sudo python3 scripts/darwin_set_proxy.py off
      ;;
    *)
      echo "❌ Invalid proxy mode: {{mode}}"
      echo "Valid modes: auto, local, off"
      exit 1
      ;;
  esac

############################################################################
#
#  Build Commands
#
############################################################################

# Build and switch to configuration
# Usage: just build [HOST] [PROXY_MODE] [DEBUG]
[group('build')]
build host=hostname proxy_mode="auto" debug="false": (_validate-host host) (smart-proxy proxy_mode)
  #!/usr/bin/env bash
  set -euo pipefail

  resolved_host="$(just _resolve-host "{{host}}")"
  REBUILD_CMD=$(just _rebuild-cmd "$resolved_host")

  if [ "{{debug}}" = "true" ]; then
    echo "🔧 Debug building $resolved_host (proxy: {{proxy_mode}})"
    sudo -E $REBUILD_CMD switch --flake .#$resolved_host --show-trace --verbose
  else
    echo "🏗️  Building $resolved_host (proxy: {{proxy_mode}})"
    sudo -E $REBUILD_CMD switch --flake .#$resolved_host
  fi

# Quick build aliases for Darwin hosts
[group('build')]
ror proxy_mode="auto": (build "Rorschach" proxy_mode)

[group('build')]
owl proxy_mode="auto": (build "NightOwl" proxy_mode)

[group('build')]
silk proxy_mode="auto": (build "SilkSpectre" proxy_mode)

# Quick build alias for NixOS host
[group('build')]
ozy proxy_mode="auto": (build "ozymandias" proxy_mode)

# Build NixOS installer ISO image
[group('build')]
iso proxy_mode="auto": (smart-proxy proxy_mode)
  #!/usr/bin/env bash
  set -euo pipefail

  out_link="result-iso-ozymandias"
  echo "💿 Building NixOS ISO (proxy: {{proxy_mode}})..."
  nix build ".#packages.x86_64-linux.ozymandias-iso" --out-link "$out_link"
  echo "✅ ISO build complete: $out_link"

############################################################################
#
#  Testing & Validation
#
############################################################################

# Format Nix files and validate flake
[group('test')]
validate:
  @echo "🔍 Running validation..."
  @just fmt
  @nix flake check --no-build

# Build test without switching
[group('test')]
build-test host=hostname proxy_mode="auto": (_validate-host host) (smart-proxy proxy_mode) validate
  #!/usr/bin/env bash
  set -euo pipefail

  resolved_host="$(just _resolve-host "{{host}}")"
  REBUILD_CMD=$(just _rebuild-cmd "$resolved_host")
  echo "🏗️  Testing build for $resolved_host (proxy: {{proxy_mode}})..."
  $REBUILD_CMD build --flake .#$resolved_host

# Show current generation before building
[group('test')]
current-gen:
  @echo "📋 Current system generation:"
  @nix profile history --profile /nix/var/nix/profiles/system | head -n 5

# Safe build: validate → build-test → switch
[group('test')]
safe-build host=hostname proxy_mode="auto": (_validate-darwin-host host) current-gen (build-test host proxy_mode)
  #!/usr/bin/env bash
  set -euo pipefail
  resolved_host="$(just _resolve-host "{{host}}")"
  echo "✅ Build test passed! Proceeding with switch..."
  sudo darwin-rebuild switch --flake .#$resolved_host

# Test all Darwin hosts
[group('test')]
test-all proxy_mode="auto":
  @echo "🚀 Testing all Darwin hosts..."
  @just smart-proxy {{proxy_mode}}
  @for host in {{darwin_hosts}}; do \
    echo "Testing $host..."; \
    darwin-rebuild build --flake .#$host >/dev/null 2>&1 && \
      echo "✅ $host: PASS" || echo "❌ $host: FAIL"; \
  done

############################################################################
#
#  Generation Management
#
############################################################################

# Rollback to previous generation
[group('rollback')]
rollback:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "⏪ Rolling back to previous generation..."
  if [ "$(uname -s)" = "Darwin" ]; then
    sudo darwin-rebuild rollback
  else
    sudo nixos-rebuild rollback
  fi

# List recent generations
[group('rollback')]
generations:
  @echo "📜 Recent system generations:"
  @nix profile history --profile /nix/var/nix/profiles/system | head -n 10

# Emergency rollback
[group('rollback')]
emergency-rollback:
  @echo "🚨 Emergency rollback to last known good generation..."
  @just rollback
  @echo "✅ Rollback complete. Check system status."

############################################################################
#
#  Nix Management
#
############################################################################

# Update all flake inputs
[group('nix')]
up:
  nix flake update

# Update specific input
[group('nix')]
upp input:
  nix flake update {{input}}

# List all generations
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open nix repl
[group('nix')]
repl:
  nix repl -f flake:nixpkgs

# Remove generations older than 7 days
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect unused store entries
[group('nix')]
gc:
  @echo "🗑️  Running garbage collection..."
  @sudo nix-collect-garbage --delete-older-than 7d
  @nix-collect-garbage --delete-older-than 7d

# Format Nix files
[group('nix')]
fmt:
  nix-shell -p alejandra --run "alejandra ."

# Show GC roots
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

############################################################################
#
#  Initial Setup (for new Mac)
#
############################################################################

# Install Homebrew and just
[group('setup')]
brew:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install just

# Install Lix (Nix alternative)
[group('setup')]
lix:
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# Setup Darwin channels
[group('setup')]
darwin-channel:
  nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
  nix-channel --update
  nix-build '<darwin>' -A darwin-rebuild
  nix flake update

# Build and switch to configuration
[group('setup')]
dot:
  ~/result/bin/darwin-rebuild switch --flake .

############################################################################
#
#  Utilities
#
############################################################################

# Type clipboard into VNC console
[group('utility')]
vnc-paste *ARGS='':
  python3 scripts/vnc_paste.py {{ARGS}}
