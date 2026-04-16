{lib, ...}: {
  options.youturn.roles = {
    common.enable = lib.mkEnableOption "shared NixOS baseline configuration";
    desktop.enable = lib.mkEnableOption "desktop-oriented NixOS configuration";
    server.enable = lib.mkEnableOption "server-oriented NixOS configuration";
  };
}
