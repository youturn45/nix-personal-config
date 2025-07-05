{ pkgs, ... }:

{
  # Add terminfo database entries for modern terminals
  environment.systemPackages = with pkgs; [
    ncurses # Provides terminfo database
  ];

  # Set default TERM for SSH sessions to avoid ghostty issues
  environment.variables = {
    TERM = pkgs.lib.mkDefault "xterm-256color";
  };

  # Simple fix: just create a symlink to xterm-256color for xterm-ghostty
  environment.etc."terminfo/x/xterm-ghostty".source = "${pkgs.ncurses}/share/terminfo/x/xterm-256color";
}