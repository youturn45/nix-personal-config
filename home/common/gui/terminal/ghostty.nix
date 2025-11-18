{
  config,
  lib,
  pkgs,
  ghostty,
  ...
}:
###########################################################
#
# Ghostty Configuration
# Cross-platform: Homebrew on Darwin, Nix package on Linux
#
###########################################################
{
  # Install Ghostty on Linux/NixOS only (macOS/Darwin uses Homebrew installation)
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    ghostty.packages.${pkgs.system}.default
  ];

  # Create Ghostty config file for both platforms
  home.file."${config.home.homeDirectory}/.config/ghostty/config".text = ''
    # Ghostty Configuration
    theme = catppuccin-mocha

    font-family = Fira Code
    font-size = 14

    background-opacity = 0.9
    background-blur-radius = 5
    scrollback-limit = 20000

    # Shell integration
    shell-integration = zsh

    # Window settings
    window-decoration = true
    window-theme = dark

    # Cursor settings
    cursor-style = block
    cursor-style-blink = true
  '';

  # Ensure the config directory exists
  home.activation.createGhosttyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/ghostty
  '';
}
