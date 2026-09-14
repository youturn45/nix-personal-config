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

  # Keep npm on the explicitly selected release instead of the version bundled
  # with Node.js. The Node-provided npm bootstraps this user-scoped installation.
  home.activation.installNpm = lib.hm.dag.entryAfter ["setupNpm"] ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs-unstable.nodejs_latest}/bin:$PATH"

    echo "Installing or updating npm 12.0.2..."
    ${pkgs-unstable.nodejs_latest}/bin/npm install -g npm@12.0.2
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

  # Add npm global bin to PATH for user-installed packages
  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };
}
