{
  lib,
  pkgs,
  ...
}: {
  # Install sonos CLI on activation via Go, mirroring the activation-managed CLI pattern
  home.activation.installSonosCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export GOPATH="$HOME/.go"
    export GOBIN="$HOME/.go/bin"
    export PATH="${pkgs.go}/bin:$GOBIN:$PATH"

    mkdir -p "$GOBIN"

    echo "Installing or updating Sonos CLI..."
    go install github.com/steipete/sonoscli/cmd/sonos@latest
  '';

  home.sessionPath = [
    "$HOME/.go/bin"
  ];
}
