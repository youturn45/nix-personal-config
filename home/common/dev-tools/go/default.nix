{
  config,
  pkgs-stable,
  lib,
  ...
}: {
  # Go toolchain
  home.packages = with pkgs-stable; [
    go
    # Pinned by flake.lock, including its Go dependencies.
    sonoscli
  ];

  # Create Go workspace directories on activation
  home.activation.setupGo = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.go/bin
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.go/pkg
  '';

  # Add Go bin to PATH for user-installed packages (via go install)
  home.sessionPath = [
    # Prefer managed tools over binaries left by earlier go install activations.
    "${config.home.profileDirectory}/bin"
    "$HOME/.go/bin"
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/.go";
  };
}
