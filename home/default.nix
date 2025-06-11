{ myvars, myLib, ... }:

{
  # import sub modules
  # TODO correctly import neovim
  imports = myLib.collectModulesRecursively ./.;

  # intergrate catppuccin theme
  
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
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
