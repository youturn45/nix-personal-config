{
  pkgs,
  lib,
  ...
}: {
  # Darwin-specific home manager configuration
  # This module is imported at build-level in flake.nix

  # Example Darwin-specific packages
  # home.packages = with pkgs; [
  #   # macOS-specific tools
  # ];

  # Example Darwin-specific settings
  # programs.foo.enable = lib.mkForce true;
}
