{
  myLib,
  vars,
  pkgs,
  ...
}: {
  imports = myLib.collectModulesRecursively ./.;

  time.timeZone = vars.timeZone;

  # System-wide packages available to all users
  # Shared between Darwin and NixOS systems
  environment.systemPackages = with pkgs; [
    # Compression and archiving tools
    zip # Standard ZIP compression
    p7zip # 7-Zip compression (supports many formats)
    zstd # Zstandard compression (fast and efficient)

    # System monitoring & info
    htop # Basic system monitor
    fastfetch # System information display

    # Terminal utilities
    tmux # Terminal multiplexer

    # Essential networking & tools
    curl # Data transfer tool
    wget # File downloader

    # Build & development essentials
    gnumake # Build automation
    jq # JSON processor
    just # Command runner (for justfile)
  ];
}
