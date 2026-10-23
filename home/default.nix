{
  myvars,
  myLib,
  lib,
  osConfig,
  pkgs-stable,
  ...
}: let
  # macOS keeps its existing GUI tools; NixOS follows the desktop role.
  desktopEnabled = !(osConfig ? youturn.roles.desktop.enable) || osConfig.youturn.roles.desktop.enable;
  isGuiModule = path:
    lib.hasPrefix "${toString ./common/gui}/" (toString path)
    || path == ./common/editors/vscode/default.nix;
  commonModules =
    builtins.filter
    (path: desktopEnabled || !(isGuiModule path))
    (myLib.collectModulesRecursively ./common);
in {
  # Import common modules for all platforms
  imports = commonModules;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    homeDirectory =
      if pkgs-stable.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}";
    stateVersion = myvars.homeStateVersion;

    enableNixpkgsReleaseCheck = true;

    # Essential packages for NixOS systems (Darwin gets packages from modules)
    # Note: All common CLI tools are now provided via home/common/core.nix
    # Git via home/common/dev-tools/git, SSH via home/common/dev-tools/ssh
    packages = [];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
    path = "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
  };

  # Add home-manager to PATH
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];
}
