
{ pkgs, lib, ... }:

{
  # using nix determinate, disable nix-daemon
  nix.enable = false;
  # enable flakes globally
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Disable auto-optimise-store because of this issue:
    #   https://github.com/NixOS/nix/issues/7273
    # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
    auto-optimise-store = true;
    extra-platforms = [ "x86_64-darwin" "aarch64-darwin" ];
  };

  nix.settings.trusted-substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.

  nix.package = pkgs.nix;
}