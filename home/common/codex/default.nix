{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Install Codex on activation (requires Node.js from nodejs module)
  home.activation.installCodex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$HOME/.npm-global/bin:$PATH"

    if ! command -v codex >/dev/null 2>&1; then
      echo "Installing Codex..."
      npm install -g @openai/codex
    else
      echo "Codex is already installed at $(command -v codex)"
    fi
  '';
}
