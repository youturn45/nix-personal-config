{
  myvars,
  myLib,
  pkgs,
  ...
}: {
  # Minimal server home configuration - only essential tools
  imports = [
    # Core essentials
    ../base/core.nix
    ../base/terminal/shells

    # Development tools (minimal)
    ../base/dev-tools/git
    ../base/dev-tools/ssh

    # Terminal tools only
    ../base/editors/neovim

    # Exclude heavy packages:
    # - No tex (17GB TeX Live)
    # - No python ML packages (PyTorch, TensorFlow)
    # - No GUI applications
    # - No development language servers
  ];

  home = {
    username = myvars.username;
    homeDirectory = "/home/${myvars.username}";
    stateVersion = myvars.homeStateVersion;
  };

  programs.home-manager.enable = true;

  # Server-specific minimal packages
  home.packages = with pkgs; [
    # Essential server tools
    htop
    tree
    wget
    curl
    git
    vim
    tmux

    # System monitoring
    iotop
    nethogs
    ncdu

    # Basic development
    gcc
    make

    # Exclude heavy packages that are in the full configuration
  ];
}
