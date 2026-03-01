{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: let
  cfg = config.youturn.roles;
in {
  config = lib.mkIf cfg.common.enable {
    system.stateVersion = "24.11";

    # Enable flakes and nix-command globally.
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [myvars.username];
    };

    users.users.${myvars.username} = {
      isNormalUser = true;
      description = myvars.userfullname;
      extraGroups = ["wheel" "networkmanager" "video" "audio"];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;
    programs.ssh.startAgent = true;

    # Keep key baseline tools available at system scope.
    environment.systemPackages = with pkgs; [
      btop
    ];

    services.dbus.enable = true;
  };
}
