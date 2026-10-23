{
  config,
  pkgs-stable,
  pkgs-unstable,
  lib,
  ...
}: {
  # Node.js and npm configuration
  home.packages = [
    pkgs-unstable.nodejs_latest
    pkgs-stable.pnpm
    pkgs-stable.bun
  ];

  # Create npm directories on activation
  home.activation.setupNpm = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
  '';

  # npm comes from the locked Node.js package above. Do not mutate a separate
  # npm installation or access the registry during Home Manager activation.
  # Existing user-global packages remain untouched and below Nix tools on PATH.

  # Set up npmrc for proper configuration
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
    cache=${config.home.homeDirectory}/.npm-cache
    init-author-name=youturn
    init-license=MIT
    fund=false
    audit=false
  '';

  # npm global bin goes on the END of PATH, never the front: home.sessionPath
  # would prepend it ahead of /etc/profiles, letting a stray `npm install -g`
  # shadow a Nix-managed tool of the same name (claude, codex, ...).
  programs.zsh.initContent = ''
    export PATH="$PATH:${config.home.homeDirectory}/.npm-global/bin"
  '';

  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };
}
