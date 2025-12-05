{
  config,
  pkgs,
  lib,
  agenix,
  myvars,
  ...
}: let
  # Platform-agnostic home directory path
  # Darwin uses /Users, Linux uses /home
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${myvars.username}"
    else "/home/${myvars.username}";

  # Platform-specific group
  # Darwin uses "staff", NixOS uses "users"
  userGroup =
    if pkgs.stdenv.isDarwin
    then "staff"
    else "users";
in {
  # Install agenix CLI tool
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Helper script to read the GitHub token
    (pkgs.writeShellScriptBin "github-token" ''
      #!/usr/bin/env bash
      # Read and display the GitHub token (use with caution!)
      if [ -f "${config.age.secrets.github-token.path}" ]; then
        cat "${config.age.secrets.github-token.path}"
      else
        echo "GitHub token file not found at ${config.age.secrets.github-token.path}" >&2
        exit 1
      fi
    '')
  ];

  # Define secrets
  age.secrets = {
    # GitHub Personal Access Token
    # After decryption, the token will be available at the specified path
    # You can use it in scripts or environment variables
    github-token = {
      file = ../../secrets/github-token.age;
      path = "${homeDir}/.config/github/token";
      owner = myvars.username;
      group = userGroup;
      mode = "0400"; # Read-only for user
    };
  };

  # Set up environment variable for GitHub token
  # This makes the token path available as $GITHUB_TOKEN_FILE in your shell
  environment.variables = {
    GITHUB_TOKEN_FILE = config.age.secrets.github-token.path;
  };
}
