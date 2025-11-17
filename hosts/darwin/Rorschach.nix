{
  config,
  pkgs,
  lib,
  ...
}: {
  # Host-specific settings
  networking.hostName = "Rorschach";
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add any Rorschach-specific packages here
  ];

  # Host-specific home-manager settings can be added here if needed
}
