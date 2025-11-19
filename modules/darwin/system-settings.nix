{
  config,
  pkgs,
  lib,
  myvars,
  ...
}:
###################################################################################
#
#  macOS System Settings & Defaults Configuration
#
#  Main configuration file for macOS system preferences, UI settings, and defaults.
#  Uses centralized variables from vars/default.nix for easy maintenance.
#
#  Documentation:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#    https://github.com/yannbertrand/macos-defaults
#
###################################################################################
{
  # Note: system.primaryUser and stateVersion are set in apps.nix for homebrew dependency
  system.defaults = {
    # Dock Configuration
    dock = {
      orientation = "left";
      tilesize = 96; # Smaller than system.nix (96) for more space
      autohide = true;
      autohide-delay = 0.0; # Instant hide (faster than system.nix 0.01)
      autohide-time-modifier = 0.0; # Instant animation (faster than system.nix 0.1)
      mineffect = "scale";
      show-recents = false;
      static-only = false;
      scroll-to-open = true;
      expose-group-apps = true;

      # Hot Corners - all disabled for clean experience
      wvous-tl-corner = 1; # top-left - nothing
      wvous-tr-corner = 1; # top-right - nothing
      wvous-bl-corner = 1; # bottom-left - nothing
      wvous-br-corner = 4; # bottom-right - Desktop (show desktop)

      # Persistent apps in dock
      persistent-apps = [
        "/Applications/Google Chrome.app"
        # "/Applications/WeChat.app"
        "/Applications/Obsidian.app"
        # "/Applications/Spotify.app"
      ];
    };

    # Finder Configuration
    finder = {
      AppleShowAllExtensions = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv"; # List view (system-defaults.nix) vs "clmv" (system.nix)
      QuitMenuItem = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
    };

    # Trackpad Configuration
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
      TrackpadThreeFingerVertSwipeGesture = 2; # 0=off, 2=Mission Control (show all windows from all apps)
      TrackpadThreeFingerHorizSwipeGesture = 2; # Switch between desktops/Spaces (swipe left/right)
    };

    # Activity Monitor
    ActivityMonitor = {
      IconType = 6; # CPU usage in graph view
    };

    # Global Domain Settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false; # Disabled for vim users
      "com.apple.sound.beep.feedback" = 0; # No beep sound
      "com.apple.swipescrolldirection" = false; # Traditional scrolling
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3;
      AppleSpacesSwitchOnActivate = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2; # Faster than system.nix (3) for vim users
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSTableViewDefaultSizeMode = 2;
    };

    # Spaces Configuration
    spaces = {
      "spans-displays" = false;
    };

    # Control Center
    controlcenter = {
      AirDrop = false;
      BatteryShowPercentage = true; # Keep battery percentage visible
      Bluetooth = false;
      Display = false;
      FocusModes = false;
      NowPlaying = false;
      Sound = false;
    };

    # Login Window
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
    };

    # Custom User Preferences
    CustomUserPreferences = {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 2.0;
        AppleSpacesSwitchOnActivate = true;
      };

      NSGlobalDomain = {
        WebKitDeveloperExtras = true;
      };

      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };

      "com.apple.ImageCapture" = {
        disableHotPlug = true;
      };

      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = false;
        StandardHideDesktopIcons = 0;
        HideDesktop = 0;
        StageManagerHideWidgets = 0;
        StandardHideWidgets = 0;
      };

      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      "com.apple.LaunchServices" = {
        LSQuarantine = false; # Disable "Are you sure you want to open" dialogs for downloaded files
      };

      "com.apple.dock" = {
        mru-spaces = false; # Don't automatically rearrange Spaces based on recent use
        showMissionControlGestureEnabled = true; # Enable Mission Control gesture (three-finger swipe up)
        showAppExposeGestureEnabled = false; # Disable App Exposé gesture in favor of Mission Control
      };

      "com.apple.menuextra.clock" = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 2;
        ShowDayOfWeek = true;
        ShowSeconds = true;
        FlashDateSeparators = true;
        DateFormat = "EEE d MMM HH:mm:ss";
      };

      "com.apple.screencapture" = {
        location = "~/Pictures/Screenshots"; # More organized than Desktop
        type = "png";
      };

      "com.apple.screensaver" = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      "com.apple.spaces" = {
        spans-displays = false;
      };

      "com.apple.symbolichotkeys" = {
        "AppleSymbolicHotKeys" = {
          # Disable Spotlight (Cmd+Space) - often conflicts with other tools
          "64" = {
            enabled = false;
          };
          # Enable Finder search (Cmd+Alt+Space)
          "65" = {
            enabled = true;
          };
          # Custom hotkey from system-defaults.nix
          "60" = {
            enabled = true;
            value = {
              parameters = [65535 33 0];
              type = "standard";
            };
          };
          # Mission Control
          "32" = {
            enabled = true;
            value = {
              parameters = [65535 126 8650752];
              type = "standard";
            };
          };
          "34" = {
            enabled = true;
            value = {
              parameters = [65535 125 8650752];
              type = "standard";
            };
          };
          # Move left a space (Ctrl+Left)
          "79" = {
            enabled = true;
            value = {
              parameters = [65535 123 8388864];
              type = "standard";
            };
          };
          # Move right a space (Ctrl+Right)
          "81" = {
            enabled = true;
            value = {
              parameters = [65535 124 8388864];
              type = "standard";
            };
          };
        };
      };

      "com.raycast.macos" = {
        "NSNavLastRootDirectory" = "~/Downloads";
        onboardingCompleted = 1;
        raycastGlobalHotkey = "Command-49";
        raycastIcon = false;
        raycastShouldFollowSystemAppearance = 1;
        useHyperKeyIcon = true;
        "onboarding_setupHotkey" = true;
        "NSStatusItem Visible raycastIcon" = false;
        "emojiPicker_skinTone" = "standard";
      };
    };
  };

  # Security Configuration
  security.pam.services.sudo_local.touchIdAuth = true;

  # Shell Configuration
  programs.zsh.enable = true;
  environment.shells = [pkgs.zsh];
}
