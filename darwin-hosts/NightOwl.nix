{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./default.nix
  ];

  # Host-specific settings
  networking.hostName = "NightOwl";
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add any NightOwl-specific packages here
  ];

  # Host-specific home-manager settings can be added here if needed
}
