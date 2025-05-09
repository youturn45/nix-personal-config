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
    stateVersion = "25.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
