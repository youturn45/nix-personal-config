{
  myvars,
  myLib,
  pkgs,
  ...
}: let
  # Define base modules for all platforms
  baseModules = myLib.collectModulesRecursively ./base;
in {
  # Import base modules for all platforms
  imports = baseModules;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}";
    stateVersion = myvars.homeStateVersion;

    # Essential packages for NixOS systems (Darwin gets packages from modules)
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
