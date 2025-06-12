{ config, pkgs, lib, ... }:

{
  # Node.js and npm configuration
  home.packages = with pkgs; [
    nodejs_22  # Latest LTS version
    # npm comes bundled with nodejs
  ];

  # Configure npm to use a user-writable directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    NPM_CONFIG_CACHE = "${config.home.homeDirectory}/.npm-cache";
  };

  # Add npm global bin to PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];

  # Create npm directories and install claude-code on activation
  home.activation.setupNpm = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
    
    if [[ ! -v DRY_RUN ]]; then
      # Check if npm is available and install claude-code
      if command -v npm >/dev/null 2>&1; then
        # Set npm config for this session
        export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
        export PATH="${config.home.homeDirectory}/.npm-global/bin:$PATH"
        
        # Check if claude-code is already installed
        if ! ${config.home.homeDirectory}/.npm-global/bin/claude-code --version >/dev/null 2>&1; then
          echo "Installing claude-code..."
          npm install -g @anthropic-ai/claude-code
          echo "✓ claude-code installed successfully"
        else
          echo "✓ claude-code already installed"
        fi
      else
        echo "⚠ npm not found, skipping claude-code installation"
      fi
    fi
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