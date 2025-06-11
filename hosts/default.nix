{ config, pkgs, lib, ... }:

{
  # Common configuration for all hosts
  imports = [
    ../modules/common
    ../modules/darwin
  ];

  # System settings are handled in modules/darwin/system-unified.nix

  # Common user settings
  users.users.youturn = {
    name = "youturn";
    home = "/Users/youturn";
    shell = pkgs.zsh;
  };

  # Common home-manager settings
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [
      ../home
    ];
  };

  # Shell configuration is now handled in modules/darwin/system-unified.nix
} 