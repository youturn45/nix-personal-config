{
  config,
  pkgs,
  lib,
  ...
}: {
  # Go toolchain
  home.packages = with pkgs; [
    go
  ];

  # Create Go workspace directories on activation
  home.activation.setupGo = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.go/bin
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.go/pkg
  '';

  # Install Go packages on activation
  home.activation.installGoPackages = lib.hm.dag.entryAfter ["setupGo"] ''
    export GOPATH="$HOME/.go"
    export PATH="${pkgs.go}/bin:$HOME/.go/bin:$PATH"
    export GODEBUG="preferIPv4=1"

    # Origin only. go's net/http transport already honours inherited
    # http_proxy/https_proxy (set by the `proxy` zsh function) automatically.
    echo "Installing or updating Go packages..."
    go install github.com/steipete/sonoscli/cmd/sonos@latest \
      || echo "[Warning] Failed to install sonos CLI — skipping, build continues"
  '';

  # Add Go bin to PATH for user-installed packages (via go install)
  home.sessionPath = [
    "$HOME/.go/bin"
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/.go";
  };
}
