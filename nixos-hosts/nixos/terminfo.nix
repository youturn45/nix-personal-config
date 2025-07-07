{pkgs, ...}: {
  # Add terminfo database entries for modern terminals
  environment.systemPackages = with pkgs; [
    ncurses # Provides terminfo database
  ];

  # Set default TERM for SSH sessions to avoid ghostty issues
  environment.variables = {
    TERM = pkgs.lib.mkDefault "xterm-256color";
  };

  # Note: For Ghostty terminal, set TERM=xterm-256color in your terminal emulator
  # or add to your shell profile: export TERM=xterm-256color
}
