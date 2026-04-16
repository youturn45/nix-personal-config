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
    # Route through the local Clash proxy if it is reachable; fall back to direct.
    # Forces IPv4 so Go does not time out on broken IPv6 paths.
    export HTTPS_PROXY="http://127.0.0.1:7890"
    export HTTP_PROXY="http://127.0.0.1:7890"
    export GODEBUG="preferIPv4=1"

    echo "Installing or updating Go packages..."
    go install github.com/steipete/sonoscli/cmd/sonos@latest
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
