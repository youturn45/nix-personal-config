{
  myvars,
  myLib,
  pkgs,
  ...
}: let
  # Define common modules for all platforms
  commonModules = myLib.collectModulesRecursively ./common;
in {
  # Import common modules for all platforms
  imports = commonModules;

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
    # Note: All common CLI tools are now provided via home/common/core.nix
    # Git via home/common/dev-tools/git, SSH via home/common/dev-tools/ssh
    packages = [];
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
