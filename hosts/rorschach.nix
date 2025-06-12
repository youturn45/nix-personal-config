{ config, pkgs, lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Host-specific settings
  networking.hostName = "Rorschach";
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # M4 MacBook Air specific settings
  system.architecture = "aarch64";
  system.machine = "m4";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add any Rorschach-specific packages here
  ];

  # Host-specific home-manager settings can be added here if needed
} 