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

  # Add ghostty terminfo if available
  environment.etc."terminfo/x/xterm-ghostty".source = "${pkgs.ghostty}/share/terminfo/x/xterm-ghostty";
}