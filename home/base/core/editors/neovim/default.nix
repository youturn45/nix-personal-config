{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
###############################################################################
#
#  NixVim configuration - migrated from AstroNvim
#
###############################################################################
let
  shellAliases = {
    v = "nvim";
    vdiff = "nvim -d";
  };
in {
  # Minimal NixVim configuration for testing
  programs.nixvim = {
    enable = true;
  };

  # Shell aliases
  home.shellAliases = shellAliases;
  programs.nushell.shellAliases = shellAliases;
}
