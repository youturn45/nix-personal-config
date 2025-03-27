  ##########################################################################
  # 
  #  This file is for configuring Homebrew on macOS.
  #
  #  It allows you to manage applications and packages using Homebrew.
  #
  ##########################################################################

{ pkgs, ... }: {

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

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  # 
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas 
    masApps = {
      # TODO Feel free to add your favorite apps here.
      Wechat = 836500024;
      #TencentMeeting = 1484048379;
    };

    taps = [
      "homebrew/services"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "libomp"
      "batt"
      # "ffmpeg"
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.

    casks = [
      # Browsers
      "google-chrome"        # Web browser
      "firefox"              # Web browser

      # Development Tools
      "visual-studio-code"   # Code editor

      # Communication & Collaboration
      "discord"              # Voice, video, and text communication
      "element"              # Secure messaging app

      # Productivity Tools
      "obsidian"             # Markdown note-taking app
      "raycast"              # Quick launcher with plugins (HotKey: alt/option + space)
      "maccy"                # Clipboard manager

      # System Utilities
      "stats"                # System monitor with a beautiful interface
      "linearmouse"          # Invert scroll direction
      "hiddenbar"            # Alternative to hidden dock

      # Terminal Applications
      "iterm2"               # Terminal emulator
      "ghostty"              # Terminal emulator

      # Remote Tools
      "Moonlight"            # Remote desktop streaming
      "Zspace"               # NAS tools
      "Tailscale"            # Simple, secure VPN for private networks

      # Entertainment
      "Spotify"              # Music streaming app
    ];
  };
}
