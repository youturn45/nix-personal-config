{ username, myLib, ... }:

{
  # import sub modules
  # TODO correctly import neovim
  imports = myLib.collectModulesRecursively ./.;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
