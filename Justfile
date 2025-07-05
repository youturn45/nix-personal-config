# just is a command runner, Justfile is very similar to Makefile, but simpler.

hostname := "Rorschach"

# List all the just commands
default:
  @just --list

############################################################################
#
#  Main Build Commands
#
############################################################################

# Set proxy for Chinese networks (remove if not needed)
[group('build')]
set-proxy:
  sudo python3 scripts/darwin_set_proxy.py

# Build and switch to current host configuration
[group('build')]
darwin: set-proxy
  sudo darwin-rebuild switch --flake .#{{hostname}}

# Debug build with verbose output
[group('build')]
darwin-debug: set-proxy
  darwin-rebuild switch --flake .#{{hostname}} --show-trace --verbose

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
#  nix related commands
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

# remove all generations older than 7 days
# on darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  # garbage collect all unused nix store entries(system-wide)
  sudo nix-collect-garbage --delete-older-than 7d
  # garbage collect all unused nix store entries(for the user - home-manager)
  # https://github.com/NixOS/nix/issues/8508
  nix-collect-garbage --delete-older-than 7d

[group('nix')]
fmt:
  # format the nix files in this repo
  nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

############################################################################
#
#  Host-Specific Shortcuts
#
############################################################################

# Quick build for Rorschach (alias for darwin)
[group('host')]
rorschach: darwin

# Quick build for Rorschach (shorter alias)
[group('host')]
ror: darwin

# Switch to Rorschach configuration (shorter alias)
[group('host')]
ror-switch: darwin

# Build and switch to SilkSpectre configuration
[group('host')]
silkspectre: set-proxy
  sudo darwin-rebuild switch --flake .#SilkSpectre

# Debug build for SilkSpectre
[group('host')]
silkspectre-debug: set-proxy
  darwin-rebuild switch --flake .#SilkSpectre --show-trace --verbose

# Quick build for SilkSpectre (shorter alias)
[group('host')]
silk:
  sudo darwin-rebuild switch --flake .#SilkSpectre

# Build and switch to NightOwl configuration
[group('host')]
nightowl: set-proxy
  sudo darwin-rebuild switch --flake .#NightOwl

# Debug build for NightOwl
[group('host')]
nightowl-debug: set-proxy
  darwin-rebuild switch --flake .#NightOwl --show-trace --verbose

# Quick build for NightOwl (shorter alias)
[group('host')]
owl: set-proxy
  sudo darwin-rebuild switch --flake .#NightOwl

############################################################################
#
#  Utility Commands
#
############################################################################

# Type clipboard content into VNC console (useful when paste doesn't work)
[group('utility')]
vnc-paste *ARGS='':
  python3 scripts/vnc_paste.py {{ARGS}}

# Generate ISO image for Proxmox VM installation
[group('nixos')]
iso:
  NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix run github:nix-community/nixos-generators --impure -- --format iso --flake .#myVm --system x86_64-linux

# Generate VMA image for Proxmox VM installation  
[group('nixos')]
vma:
  NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix run github:nix-community/nixos-generators --impure -- --format proxmox --flake .#myVm --system x86_64-linux