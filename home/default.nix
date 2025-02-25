{ username, pkgs, ... }:

{
  # import sub modules
  imports = [
    ./shell.nix
    ./core.nix
    # ./git.nix
    ./starship.nix
  ];

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
