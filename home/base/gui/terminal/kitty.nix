{
  config,
  lib,
  pkgs,
  ...
}:
###########################################################
#
# Kitty Terminal Configuration
# Cross-platform: Using programs.kitty for proper app bundle on Darwin
#
###########################################################
{
  # Enable Kitty via Home Manager programs module
  programs.kitty = {
    enable = true;

    # Font configuration
    font = {
      name = "Fira Code";
      size = 14;
    };

    themeFile = "Catppuccin-Mocha";

    keybindings = {
      "kitty_mod" = "ctrl+shift";
      # Keep default macOS clipboard behavior
      "cmd+c" = "copy_to_clipboard";
      "cmd+v" = "paste_from_clipboard";
      # Also map Ctrl+V for consistency in terminal apps
      "ctrl+v" = "paste_from_clipboard";
      # Also allow kitty modifier versions
      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";
      "kitty_mod+s" = "launch --type=overlay --cwd=current cursor -";
      "kitty_mod+l" = "clear_terminal scrollback active";
      "kitty_mod+t" = "new_tab";
      "kitty_mod+1" = "goto_tab 1";
      "kitty_mod+2" = "goto_tab 2";
      "kitty_mod+3" = "goto_tab 3";
      "kitty_mod+4" = "goto_tab 4";
      "kitty_mod+5" = "goto_tab 5";
      "kitty_mod+6" = "goto_tab 6";
      "kitty_mod+shift+]" = "next_tab";
      "kitty_mod+shift+[" = "previous_tab";
      # macOS-specific tab shortcuts
      "cmd+1" = "goto_tab 1";
      "cmd+2" = "goto_tab 2";
      "cmd+3" = "goto_tab 3";
      "cmd+4" = "goto_tab 4";
      "cmd+left" = "previous_tab";
      "cmd+right" = "next_tab";
      "cmd+enter" = "no_op";
      "cmd+shift+enter" = "no_op";
      "kitty_mod+h" = "kitty_scrollback_nvim";
      "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
    };

    # Main configuration settings
    settings = {
      # Background and transparency
      background_opacity = "0.9";
      background_blur = 5;

      # Window settings
      remember_window_size = true;
      initial_window_width = 1200;
      initial_window_height = 800;
      window_padding_width = 8;
      hide_window_decorations = "titlebar-only";

      # Tab configuration
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "round";

      # Cursor settings
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";

      # Mouse settings
      mouse_hide_wait = "3.0";
      url_color = "#0087bd";
      url_style = "curly";

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;

      # Shell integration
      shell_integration = "enabled";
      shell = "zsh";

      # Scrollback
      scrollback_lines = 10000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";

      # Advanced
      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty";
      startup_session = "none";
      clipboard_control = "write-clipboard write-primary";
      term = "xterm-kitty";
      disable_ligatures = "never";

      # Catppuccin Mocha colors
      foreground = "#CDD6F4";
      background = "#1E1E2E";
      selection_foreground = "#1E1E2E";
      selection_background = "#F5E0DC";

      # Cursor colors
      cursor = "#F5E0DC";
      cursor_text_color = "#1E1E2E";

      # Kitty window border colors
      active_border_color = "#B4BEFE";
      inactive_border_color = "#6C7086";
      bell_border_color = "#F9E2AF";

      # OS Window titlebar colors
      wayland_titlebar_color = "system";
      macos_titlebar_color = "system";

      # Tab bar colors
      active_tab_foreground = "#11111B";
      active_tab_background = "#CBA6F7";
      inactive_tab_foreground = "#CDD6F4";
      inactive_tab_background = "#181825";
      tab_bar_background = "#11111B";

      # Colors for marks (marked text in the terminal)
      mark1_foreground = "#1E1E2E";
      mark1_background = "#B4BEFE";
      mark2_foreground = "#1E1E2E";
      mark2_background = "#CBA6F7";
      mark3_foreground = "#1E1E2E";
      mark3_background = "#74C7EC";

      # The 16 terminal colors
      # black
      color0 = "#45475A";
      color8 = "#585B70";

      # red
      color1 = "#F38BA8";
      color9 = "#F38BA8";

      # green
      color2 = "#A6E3A1";
      color10 = "#A6E3A1";

      # yellow
      color3 = "#F9E2AF";
      color11 = "#F9E2AF";

      # blue
      color4 = "#89B4FA";
      color12 = "#89B4FA";

      # magenta
      color5 = "#F5C2E7";
      color13 = "#F5C2E7";

      # cyan
      color6 = "#94E2D5";
      color14 = "#94E2D5";

      # white
      color7 = "#BAC2DE";
      color15 = "#A6ADC8";
    };

    # Enable shell integration for zsh
    shellIntegration = {
      enableZshIntegration = true;
      mode = "enabled";
    };
  };
}
