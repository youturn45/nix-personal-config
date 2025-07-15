{
  myvars,
  myLib,
  pkgs,
  ...
}: let
  # Define minimal modules for NixOS systems
  nixosModules = myLib.collectModulesRecursively ./base;
in {
  # Conditional imports based on system type
  imports =
    if pkgs.stdenv.isLinux
    then nixosModules
    else darwinModules;

  # intergrate catppuccin theme

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}";
    stateVersion = myvars.homeStateVersion;

    # Essential packages for NixOS systems
    packages =
      if pkgs.stdenv.isLinux
      then
        with pkgs; [
          git
          vim
          curl
          wget
          htop
          tmux
          openssh
          starship
          nodejs_22
        ]
      else [];
  };


  # Full modules for Darwin systems
  darwinModules = myLib.collectModulesRecursively ./base;
in {
  # Conditional imports based on system type
  imports =
    if pkgs.stdenv.isLinux
    then nixosModules
    else darwinModules;

  # intergrate catppuccin theme

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}";
    stateVersion = myvars.homeStateVersion;

    # Essential packages for NixOS systems
    packages =
      if pkgs.stdenv.isLinux
      then
        with pkgs; [
          git
          vim
          curl
          wget
          htop
          tmux
          openssh
          starship
          nodejs_22
        ]
      else [];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
    path = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };

  # Add home-manager to PATH
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];
}
