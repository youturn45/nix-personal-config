# just is a command runner, Justfile is very similar to Makefile, but simpler.

# TODO update hostname here!
hostname := "your-hostname"

# List all the just commands
default:
  @just --list

############################################################################
#
#  Darwin related commands
#
############################################################################

#  TODO Feel free to remove this target if you don't need a proxy to speed up the build process
# set_proxy
[group('desktop')]
darwin-set-proxy:
  sudo python3 scripts/darwin_set_proxy.py

[group('desktop')]
darwin: darwin-set-proxy
  nix build .#darwinConfigurations.{{hostname}}.system \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}

[group('desktop')]
darwin-debug: darwin-set-proxy
  nix build .#darwinConfigurations.{{hostname}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}} --show-trace --verbose




# Justfile for new mac build
[group ('newmac')]
shproxy:
  export http_proxy="127.0.0.1:7890"
  export https_proxy="127.0.0.1:7890"

[group ('newmac')]
brew:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install just 

[group ('newmac')]
lix:
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install

[group ('newmac')]
darwin-channel:
  nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
  nix-channel --update
  nix-build '<darwin>' -A darwin-rebuild
  nix flake update

# Justfile for building dot
[group('newmac')]
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
#  Rorschach host configuration
#
############################################################################

# Build and switch to rorschach configuration
[group('rorschach')]
rorschach: darwin-set-proxy
  darwin-rebuild build .#darwinConfigurations.Rorschach.system \
    --extra-experimental-features 'nix-command flakes'
  ./result/sw/bin/darwin-rebuild switch --flake .#Rorschach

# Debug build for rorschach configuration
[group('rorschach')]
rorschach-debug: darwin-set-proxy
  nix build .#darwinConfigurations.Rorschach.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'
  ./result/sw/bin/darwin-rebuild switch --flake .#Rorschach --show-trace --verbose

[group('rorschach')]
ror: darwin-set-proxy
  darwin-rebuild build --flake .#Rorschach

[group('rorschach')]
ror-switch: darwin-set-proxy
  sudo darwin-rebuild switch --flake .#Rorschach