{ config, pkgs, lib, ... }:

{
  # Common configuration for all hosts
  imports = [
    ../modules/common
    ../modules/darwin
  ];

  # Common system settings
  system = {
    stateVersion = 4;
    primaryUser = "youturn";
    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
      };
      dock = {
        autohide = true;
        show-recents = false;
      };
    };
  };

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

  # Common shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
} 