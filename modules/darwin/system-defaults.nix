{ config, pkgs, lib, ... }:

{
  system.primaryUser = "youturn";

  system.defaults = {
    NSGlobalDomain = lib.mkForce {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.swipescrolldirection" = false;
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3;
      AppleSpacesSwitchOnActivate = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSTableViewDefaultSizeMode = 2;
    };

    dock = lib.mkForce {
      autohide = true;
      "autohide-delay" = 0.0;
      "autohide-time-modifier" = 0.0;
      "expose-group-apps" = true;
      mineffect = "scale";
      orientation = "left";
      "persistent-apps" = [ ];
      "scroll-to-open" = true;
      "show-recents" = false;
      "static-only" = false;
      tilesize = 48;
      "wvous-bl-corner" = 1;
      "wvous-br-corner" = 1;
      "wvous-tl-corner" = 1;
      "wvous-tr-corner" = 1;
    };

    finder = lib.mkForce {
      AppleShowAllExtensions = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
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

    trackpad = lib.mkForce {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    spaces = lib.mkForce {
      "spans-displays" = false;
    };

    controlcenter = lib.mkForce {
      AirDrop = true;
      BatteryShowPercentage = true;
      Bluetooth = true;
      Display = true;
      FocusModes = true;
      NowPlaying = true;
      Sound = true;
    };

    CustomUserPreferences = lib.mkForce {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 2.0;
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.ImageCapture" = {
        disableHotPlug = true;
      };
      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = false;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.menuextra.clock" = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 2;
        ShowDayOfWeek = true;
        ShowSeconds = true;
      };
      "com.apple.screencapture" = {
        location = "~/Pictures/Screenshots";
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
          "60" = {
            enabled = true;
            value = {
              parameters = [ 65535 33 0 ];
              type = "standard";
            };
          };
        };
      };
      "com.raycast.macos" = {
        "NSNavLastRootDirectory" = "~/Downloads";
      };
    };
  };
} 