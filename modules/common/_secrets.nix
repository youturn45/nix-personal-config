# DISABLED: `_`-prefixed so collectModulesRecursively skips it (see CLAUDE.md).
#
# agenix-based secrets management, disabled repo-wide as of 2026-08. Two
# reasons: secrets/github-token.age was encrypted for an SSH key that isn't
# present on any actual machine here, so it never decrypted; and `agenix`
# (the CLI) is itself Nix-installed by this very module, so it can't be used
# in any pre-build tooling without being circular. See docs/build.md for the
# fix that replaced its original purpose (authenticating flake input fetches).
#
# To re-enable: rename this file back to secrets.nix, re-add the `agenix`
# flake input in flake.nix (input block + outputs destructuring + both
# specialArgs `inherit` lines), restore `agenix.darwinModules.default` /
# `agenix.nixosModules.default` in modules/darwin/default.nix and
# modules/nixos/default.nix, and re-encrypt secrets/github-token.age for
# whichever SSH key will actually be present on every target machine.
{
  config,
  pkgs-stable,
  lib,
  agenix,
  myvars,
  ...
}: let
  # Platform-agnostic home directory path
  # Darwin uses /Users, Linux uses /home
  homeDir =
    if pkgs-stable.stdenv.isDarwin    then "/Users/${myvars.username}"
    else "/home/${myvars.username}";

  # Platform-specific group
  # Darwin uses "staff", NixOS uses "users"
  userGroup =
    if pkgs-stable.stdenv.isDarwin    then "staff"
    else "users";
in {
  # Install agenix CLI tool
  environment.systemPackages = with pkgs-stable; [
    agenix.packages.${pkgs-stable.stdenv.hostPlatform.system}.default

    # Helper script to read the GitHub token
    (pkgs-stable.writeShellScriptBin "github-token" ''
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
