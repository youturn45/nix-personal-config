{
  config,
  lib,
  pkgs-stable,
  ...
}: let
  cfg = config.youturn.roles;
in {
  config = lib.mkIf cfg.server.enable {
    # Server baseline: remote access enabled.
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Server-side tools (expand over time: airflow/overleaf stacks, etc.).
    environment.systemPackages = with pkgs-stable; [
      duckdb
    ];
  };
}
