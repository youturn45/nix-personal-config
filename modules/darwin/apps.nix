{ pkgs, myvars, ... }: {

  ##########################################################################
  # 
  #  Install all apps and packages here.
  #
  # Feel free to modify this file to fit your needs.
  #
  ##########################################################################

  # Required system configuration (using centralized variables)
  system = {
    primaryUser = myvars.primaryUser;  # Required for homebrew functionality
    stateVersion = myvars.darwinStateVersion;  # Required for nix-darwin
  };

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    # Core system tools - available system-wide
    curl
    wget
    git # Keep at system level for system-wide availability
    just # Keep for build commands
    zip
    p7zip
    zstd
    coreutils
    nano # Simple editor for system-level editing
    
    # Basic system utilities
    jq # Keep for system scripts
    
    # Network tools
    httpie
    mtr
  ];

  /*programs = {
    # modern vim
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
    };

    # terminal file manager
    yazi = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_dir_first = true;
        };
      };
    };
  };*/

  environment.variables.EDITOR = "nvim";

  # To make this work, homebrew needs to be installed manually, see https://brew.sh
  # 
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Skip fetching updates for faster builds
      upgrade = false; # Skip upgrading packages for faster builds
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas 
    masApps = {
      # Feel free to add your favorite apps here.
      Wechat = 836500024;
      #TencentMeeting = 1484048379;
    };

    taps = [
      "homebrew/services"
    ];

    # `brew install`
    # Feel free to add your favorite apps here.
    brews = [
      "libomp"
      "batt"
    #  "ffmpeg"
    ];

    # `brew install --cask`
    # Feel free to add your favorite apps here.
    casks = [
      # browser
      "google-chrome"
      "visual-studio-code"
      
      # IM & audio & remote desktop & meeting
      "discord"

      # Tools
      "raycast" # (HotKey: alt/option + space)search, caculate and run scripts(with many plugins)
      "stats" # beautiful system monitor
      "obsidian" # markdown note app
      "linearmouse" # invert roll
      "hiddenbar" # hidden dock alternative
      "maccy" # clipboard manager
      "iterm2" # terminal
      "ghostty" # terminal
      "Moonlight" # remote desktop
      "Spotify" # music app
      # "tailscale" # VPN
    ];
  };
}
