{ pkgs, ... }: {

  ##########################################################################
  # 
  #  Install all apps and packages here.
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    # system tools
    curl # curl
    ripgrep # recursively searches directories for a regex pattern
    git # git
    just # use Justfile to simplify nix-darwin's commands
    zip # zip files
    p7zip # 7zip files
    zstd # zstd compression

    # monitoring
    duf # Better disk usage viewer
    btop # better than htop
    coreutils
    
    # text editor
    neovim # neovim
    nano # nano

    # gui tools in terminal 
    yazi # terminal file manager
    yq-go # yaml processer https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder
    jq # json processor
    glow # markdown previewer in terminal

    # development tools
    gh       # GitHub CLI
    delta    # Better git diff
    lazygit  # Terminal UI for git

    # network tools
    wget
    httpie
    mtr      # network diagnostic tool
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
    #  "ffmpeg"
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
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
      # "aldente" # battery management app # replace with command line batt
    ];
  };
}
