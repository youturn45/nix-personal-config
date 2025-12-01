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

    echo "Installing or updating Codex..."
    npm install -g @openai/codex@latest
  '';
}
