{ myvars, myLib, pkgs, ... }:

{
  # import sub modules - only base folder for cross-platform compatibility
  imports = myLib.collectModulesRecursively ./base;

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
