{
  pkgs,
  lib,
  ...
}: {
  # NixOS-specific home manager configuration
  # This module is imported at build-level in hosts/nixos/default.nix
  # It imports the common home configuration and adds NixOS-specific settings

  imports = [
    ../default.nix # Import common home configuration
  ];

  # NixOS-specific packages
  # home.packages = with pkgs; [
  #   # Linux-specific tools
  # ];

  # NixOS-specific settings
  # programs.foo.enable = lib.mkForce true;
}
