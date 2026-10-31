{
  config,
  pkgs-stable,
  lib,
  agenix,
  myvars,
  ...
}: let
  homeRoot = if pkgs-stable.stdenv.isDarwin then "/Users" else "/home";
  encryptedConfig = ../../../secrets/github-nix.conf.age;
  configured = builtins.pathExists encryptedConfig;
in {
  environment.systemPackages = [
    agenix.packages.${pkgs-stable.stdenv.hostPlatform.system}.default
    pkgs-stable.age
  ];

  warnings = lib.optional (!configured) ''
    GitHub authentication is not configured. Run python3 scripts/github_nix_token.py encrypt,
    then git add secrets/github-nix.conf.age before rebuilding (see secrets/README.md).
  '';

  age.identityPaths = ["${homeRoot}/${myvars.username}/.ssh/${myvars.secretsIdentityName}"];
  age.secrets = lib.optionalAttrs configured {
    github-nix = {
      file = encryptedConfig;
      owner = myvars.username;
      group = if pkgs-stable.stdenv.isDarwin then "staff" else "users";
      mode = "0400";
    };
  };

  # Only the path enters the store. Both the invoking user and root can read
  # the runtime secret. !include allows startup before agenix's boot service.
  nix.extraOptions = lib.optionalString configured ''
    !include ${config.age.secrets.github-nix.path}
  '';
}
