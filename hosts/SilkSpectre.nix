{ config, pkgs, lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Host-specific settings
  networking.hostName = "SilkSpectre";
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # MacBook specific settings (adjust architecture/machine as needed)
  system.architecture = "aarch64";
  system.machine = "macbook";

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add any SilkSpectre-specific packages here
  ];

  # Host-specific home-manager settings can be added here if needed
}