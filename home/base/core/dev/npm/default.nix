{ config, pkgs, lib, ... }:

let
  claudeCodeVersion = "latest"; # Change to specific version if needed
in
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
  home.activation.setupNpm = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/claude-code
    
    if [[ ! -v DRY_RUN ]]; then
      NODE_BIN_DIR="${pkgs.nodejs_22}/bin"
      
      if [[ -x "$NODE_BIN_DIR/npm" ]]; then
        export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
        export PATH="$NODE_BIN_DIR:${config.home.homeDirectory}/.npm-global/bin:$PATH"
        
        # Check if claude-code is already installed
        if ${config.home.homeDirectory}/.npm-global/bin/claude-code --version >/dev/null 2>&1; then
          CURRENT_VERSION=$(${config.home.homeDirectory}/.npm-global/bin/claude-code --version 2>/dev/null || echo "unknown")
          echo "✓ claude-code already installed (version: $CURRENT_VERSION)"
        else
          echo "Installing claude-code..."
          if "$NODE_BIN_DIR/npm" install -g @anthropic-ai/claude-code@${claudeCodeVersion}; then
            NEW_VERSION=$(${config.home.homeDirectory}/.npm-global/bin/claude-code --version 2>/dev/null || echo "unknown")
            echo "✓ claude-code installed successfully (version: $NEW_VERSION)"
          else
            echo "✗ Failed to install claude-code"
            exit 1
          fi
        fi
      else
        echo "⚠ npm not available, skipping claude-code installation"
      fi
    fi
  '';

  # Update claude-code when home-manager rebuilds
  home.activation.updateClaudeCode = lib.hm.dag.entryAfter ["setupNpm"] ''
    if [[ ! -v DRY_RUN ]]; then
      NODE_BIN_DIR="${pkgs.nodejs_22}/bin"
      export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
      export PATH="$NODE_BIN_DIR:${config.home.homeDirectory}/.npm-global/bin:$PATH"
      
      if [[ -x "${config.home.homeDirectory}/.npm-global/bin/claude-code" ]]; then
        echo "Checking for claude-code updates..."
        if "$NODE_BIN_DIR/npm" update -g @anthropic-ai/claude-code; then
          UPDATED_VERSION=$(${config.home.homeDirectory}/.npm-global/bin/claude-code --version 2>/dev/null || echo "unknown")
          echo "✓ claude-code update completed (version: $UPDATED_VERSION)"
        else
          echo "⚠ claude-code update check failed"
        fi
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

  # Optional: Claude-code configuration
  home.file.".config/claude-code/config.json".text = builtins.toJSON {
    # Add your preferred claude-code settings here
    # This is just an example - adjust based on actual claude-code config options
    editor = "code";
    theme = "dark";
  };

  # Shell aliases for convenience
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    cc = "claude-code";
    claude = "claude-code";
  };

  programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
    cc = "claude-code";
    claude = "claude-code";
  };
}