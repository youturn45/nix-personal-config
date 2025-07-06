{ myvars, myLib, pkgs, ... }:
{
  # Minimal server home configuration - only essential tools
  imports = [
    # Core essentials
    ../base/core/core.nix
    ../base/core/shells
    
    # Development tools (minimal)
    ../base/core/dev/git
    ../base/core/dev/ssh
    
    # Terminal tools only
    ../base/core/editors/neovim
    
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