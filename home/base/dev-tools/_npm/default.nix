{
  config,
  pkgs,
  lib,
  ...
}: let
in {
  # Node.js and npm configuration
  home.packages = with pkgs; [
    nodejs_22 # Latest LTS version
    # npm comes bundled with nodejs
  ];

  # Create npm directories on activation
  home.activation.setupNpm = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
  '';

  # Set up npmrc for proper configuration
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
    cache=${config.home.homeDirectory}/.npm-cache
    init-author-name=youturn
    init-license=MIT
    fund=false
    audit=false
  '';
}
