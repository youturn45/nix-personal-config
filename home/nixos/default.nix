{
  pkgs,
  lib,
  ...
}: {
  # NixOS-specific home manager configuration
  # This module is imported at build-level in hosts/nixos/default.nix

  # Example NixOS-specific packages
  # home.packages = with pkgs; [
  #   # Linux-specific tools
  # ];

  # Example NixOS-specific settings
  # programs.foo.enable = lib.mkForce true;
}
