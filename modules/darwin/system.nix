{ pkgs, ... }:

  ###################################################################################
  #
  #  macOS's System configuration
  #
  #  All the configuration options are documented here:
  #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
  #  Incomplete list of macOS `defaults` commands :
  #    https://github.com/yannbertrand/macos-defaults
  #
  ###################################################################################
{
  system = {


    stateVersion = 6;
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      # menuExtraClock.Show24Hour = true; # show 24 hour clock
      # customize dock
      dock = {
        orientation = "left";
        tilesize = 96;
        autohide = true;
        autohide-time-modifier = 0.1;
        autohide-delay = 0.01;
        mineffect = "scale";
        show-recents = false;  # disable recent apps
        static-only = false; # show only active apps
        scroll-to-open = true;
        
        # customize Hot Corners(触发角, 鼠标移动到屏幕角落时触发的动作)
        #wvous-tl-corner = 2;  # top-left - Mission Control
        #wvous-tr-corner = 13;  # top-right - Lock Screen
        #wvous-bl-corner = 3;  # bottom-left - Application Windows
        
        wvous-tl-corner = 1;  # top-left - nothing
        wvous-tr-corner = 1;  # top-right - nothing
        wvous-bl-corner = 1;  # bottom-left - nothing
        wvous-br-corner = 4;  # bottom-right - Desktop
        expose-group-apps = true;
        persistent-apps = [
          "/Applications/Google Chrome.app"
          "/Applications/Ghostty.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/WeChat.app"
          "/Applications/Obsidian.app"
          "/Applications/Spotify.app"
        ];
        /*entries = [ 
          { path = "/Applications/Google Chrome.app"; }
          { path = "/Applications/Ghostty.app"; }
          { path = "/Applications/WeChat.app"; }
          { path = "/Applications/Cursor.app"; }
          { path = "/Applications/Obsidian.app"; }
        ];*/
      };

      # customize finder
      finder = {
        # Finder Appearance
        _FXShowPosixPathInTitle = true;      # show full path in finder title
        AppleShowAllExtensions = true;      # show all file extensions
        FXPreferredViewStyle = "clmv";      # column view 
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        ShowPathbar = true;                # show path bar
        ShowStatusBar = true;              # show status bars
        QuitMenuItem = true;              # enable quit menu item

        # Desktop Visibility
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        _FXSortFoldersFirstOnDesktop = true; # Check if this is needed if _FXSortFoldersFirst is set
        _FXSortFoldersFirst = true;         # Check if this setting also affects the desktop
      };

      # customize trackpad
      trackpad = {
        Clicking = true;  # enable tap to click(轻触触摸板相当于点击)
        TrackpadRightClick = true;  # enable two finger right click
        TrackpadThreeFingerDrag = true;  # enable three finger drag
      };

      ActivityMonitor = {
        IconType = 6;  # show CPU usage in graph view
      };

      # customize settings that not supported by nix-darwin directly
      # Incomplete list of macOS `defaults` commands :
      #   https://github.com/yannbertrand/macos-defaults
      NSGlobalDomain = {
        # `defaults read NSGlobalDomain "xxx"`
        "com.apple.swipescrolldirection" = true;  # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" = 1;  # beep sound when pressing volume up/down key
        AppleInterfaceStyle = "Dark";  # dark mode
        AppleKeyboardUIMode = 3;  # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = true;  # enable press and hold
        AppleSpacesSwitchOnActivate = true;
        # This is very useful for vim users, they use `hjkl` to move cursor.
        # sets how long it takes before it starts repeating.
        InitialKeyRepeat = 15;  # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts. 
        KeyRepeat = 3;  # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

        NSAutomaticCapitalizationEnabled = false;  # disable auto capitalization(自动大写)
        NSAutomaticDashSubstitutionEnabled = false;  # disable auto dash substitution(智能破折号替换)
        NSAutomaticPeriodSubstitutionEnabled = false;  # disable auto period substitution(智能句号替换)
        NSAutomaticQuoteSubstitutionEnabled = false;  # disable auto quote substitution(智能引号替换)
        NSAutomaticSpellingCorrectionEnabled = false;  # disable auto spelling correction(自动拼写检查)
        NSNavPanelExpandedStateForSaveMode = true;  # expand save panel by default(保存文件时的路径选择/文件名输入页)
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSTableViewDefaultSizeMode = 2;     # smaller text size (1=small, 2=medium, 3=large)
      };

      spaces = {
        spans-displays = false;  # Display have seperate spaces
      };

      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = true;
        Bluetooth = false;
        Display = false;
        FocusModes = false;
        NowPlaying = false;
        Sound = false;
        # Wi-fi = false;
        # Spotlight = false;
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      # 
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };

        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;  
        };

        "com.apple.spaces" = {
          "spans-displays" = 0; # Display have seperate spaces
        };

        "com.apple.menuextra.clock" = {
          FlashDateSeparators = true;
          DateFormat = "EEE d MMM HH:mm:ss";
        };

        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };

        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };

        "com.apple.screencapture" = {
          location = "~/Desktop/screenshots";
          type = "png";
        };

        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };

        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;

        "com.raycast.macos" = {
          onboardingCompleted = 1;
          raycastGlobalHotkey = "Command-49";
          raycastIcon = false;
          raycastShouldFollowSystemAppearance = 1;
          useHyperKeyIcon = true;
          "onboarding_setupHotkey" = true;
          "NSStatusItem Visible raycastIcon" = false;
          "emojiPicker_skinTone" = "standard";
        };

        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable 'Cmd + Space' for Spotlight Search
            "64" = {
              enabled = false;
            };
            # Disable 'Cmd + Alt + Space' for Finder search window
            "65" = {
              # Set to false to disable
              enabled = true;
            };
          };
        };
      };



      loginwindow = {
        GuestEnabled = false;  # disable guest user
        SHOWFULLNAME = true;  # show full name in login window
      };
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;
  # programs.fish.enable = true;
  environment.shells = [
    # pkgs.zsh
    pkgs.zsh
  ];

  # Fonts
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.space-mono
      
      # 思源系列字体是 Adobe 主导的。其中汉字部分被称为「思源黑体」和「思源宋体」，是由 Adobe + Google 共同开发的
      source-sans # 无衬线字体，不含汉字。字族名叫 Source Sans 3 和 Source Sans Pro，以及带字重的变体，加上 Source Sans 3 VF
      source-serif # 衬线字体，不含汉字。字族名叫 Source Code Pro，以及带字重的变体
      source-han-sans # 思源黑体
      source-han-serif # 思源宋体
    ];
  };
}

