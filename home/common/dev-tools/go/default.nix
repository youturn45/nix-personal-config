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

    # Smart proxy: honour shell-inherited proxy first, then detect via port check
    if [ -z "''${HTTP_PROXY:-}''${http_proxy:-}" ]; then
      if nc -z -G 1 127.0.0.1 7890 2>/dev/null; then
        export HTTP_PROXY="http://127.0.0.1:7890"
        export HTTPS_PROXY="http://127.0.0.1:7890"
        echo "Go install: using local proxy (127.0.0.1:7890)"
      elif nc -z -G 1 10.0.0.3 7890 2>/dev/null; then
        export HTTP_PROXY="http://10.0.0.3:7890"
        export HTTPS_PROXY="http://10.0.0.3:7890"
        echo "Go install: using network proxy (10.0.0.3:7890)"
      else
        echo "Go install: no proxy detected, proceeding directly"
      fi
    else
      echo "Go install: using inherited proxy (''${HTTP_PROXY:-$http_proxy})"
    fi

    echo "Installing or updating Go packages..."
    go install github.com/steipete/sonoscli/cmd/sonos@latest \
      || echo "[Warning] Failed to install sonos CLI — skipping, build continues"
  '';

  # Add Go bin to PATH for user-installed packages (via go install)
  home.sessionPath = [
    "$HOME/.go/bin"
  ];

  # Set GOPATH to user directory (keeps go install packages out of ~/go)
  home.sessionVariables = {
    GOPATH = "$HOME/.go";
  };
}
