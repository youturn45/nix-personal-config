{
  myLib,
  vars,
  pkgs,
  ...
}: {
  imports = myLib.collectModulesRecursively ./.;

  time.timeZone = vars.timeZone;

  # Compression and archiving tools
  # Shared between Darwin and NixOS systems
  environment.systemPackages = with pkgs; [
    zip # Standard ZIP compression
    p7zip # 7-Zip compression (supports many formats)
    zstd # Zstandard compression (fast and efficient)
  ];
}
