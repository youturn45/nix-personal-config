
{ pkgs, lib, ... }:

{
  # using nix determinate, disable nix-daemon
  nix.enable = true;
  nix.package = pkgs.nix;

  # enable flakes globally
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Disable auto-optimise-store because of this issue:
    #   https://github.com/NixOS/nix/issues/7273
    # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
    extra-platforms = [ "x86_64-darwin" "aarch64-darwin" ];
  };
  
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
  #nix.settings.trusted-substituters = [
  #  "https://mirrors.ustc.edu.cn/nix-channels/store"
  #  "https://cache.nixos.org"
  #];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}