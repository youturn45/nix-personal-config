# Tmux: vi-mode multiplexer themed to match the flake (Catppuccin Mocha)
#
# A running tmux server does not re-read config on rebuild — reload with
# `prefix + r`, or `tmux kill-server` to start fresh.
{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    mouse = true;
    focusEvents = true; # nvim autoread/gitsigns rely on these
    keyMode = "vi";
    terminal = "tmux-256color";
    escapeTime = 10; # default 500ms delays ESC in nvim
    historyLimit = 50000;
    baseIndex = 1; # also sets pane-base-index

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_flavour "mocha" # pre-v2 plugin option name
        '';
      }
      vim-tmux-navigator # C-h/j/k/l across nvim splits and tmux panes
      yank # copy-mode selections land in the macOS clipboard
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents "on"
        '';
      }
      {
        # must load last: hooks into status-right for the autosave timer
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore "on"
          set -g @continuum-save-interval "15"
        '';
      }
    ];

    extraConfig = ''
      # True color passthrough from the outer terminal
      set -as terminal-features ",*:RGB"

      # Programs inside tmux (nvim, SSH sessions) may set the clipboard via OSC52
      set -g set-clipboard on

      set -g renumber-windows on

      # Splits keep the current pane's directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vi-style selection in copy mode (y handled by tmux-yank)
      bind -T copy-mode-vi v send -X begin-selection

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
    '';
  };
}
