{
  pkgs,
  lib,
  ...
}: {
  # Darwin-specific home manager configuration
  # This module is imported at build-level in flake.nix
  # It imports the common home configuration and adds Darwin-specific settings

  imports = [
    ../default.nix # Import common home configuration
  ];

  # Darwin-specific packages
  # home.packages = with pkgs; [
  #   # macOS-specific tools
  # ];

  # Darwin-specific settings
  # programs.foo.enable = lib.mkForce true;
}
