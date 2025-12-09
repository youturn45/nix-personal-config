{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Wrapper script for codex command with proxy check
  home.packages = [
    (pkgs.writeShellScriptBin "codex" ''
      # Check if any proxy environment variable is set
      if [ -z "$http_proxy" ] && [ -z "$https_proxy" ] && \
         [ -z "$HTTP_PROXY" ] && [ -z "$HTTPS_PROXY" ] && \
         [ -z "$ALL_PROXY" ] && [ -z "$all_proxy" ]; then

        echo "⚠️  No proxy configuration detected."
        echo "Proxy environment variables (http_proxy, https_proxy, etc.) are not set."
        echo ""
        read -p "Do you want to continue starting Codex? (y/n): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Cancelled."
          exit 1
        fi
      fi

      # Run the actual codex command from npm installation
      exec "$HOME/.npm-global/bin/codex" "$@"
    '')
  ];

  # Install Codex on activation (requires Node.js from nodejs module)
  home.activation.installCodex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$HOME/.npm-global/bin:$PATH"

    echo "Installing or updating Codex..."
    npm install -g @openai/codex@latest
  '';
}
