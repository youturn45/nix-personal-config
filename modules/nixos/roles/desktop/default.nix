{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.youturn.roles;
in {
  config = lib.mkIf cfg.desktop.enable {
    # Desktop baseline session.
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
    };

    # Wayland desktop tools can live in this role as you evolve it.
    environment.systemPackages = with pkgs; [
      hyprland
    ];
  };
}
