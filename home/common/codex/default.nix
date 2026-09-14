{
  codex-cli-nix,
  pkgs-stable,
  config,
  lib,
  ...
}: let
  codex = codex-cli-nix.packages.${pkgs-stable.stdenv.hostPlatform.system}.default;

  # Settings owned by Nix. Codex's runtime state (projects.*.trust_level,
  # tui.*, notice.*) is left alone and survives rebuilds.
  settings = {
    model = "gpt-5.6-sol";
    model_reasoning_effort = "high";
    service_tier = "default";
    features.remote_control = true;
    plugins."github@openai-curated".enabled = true;
  };

  managedConfig = (pkgs-stable.formats.toml {}).generate "codex-managed-config.toml" settings;
  python = pkgs-stable.python3.withPackages (ps: [ps.tomli-w]);
  configPath = "${config.home.homeDirectory}/.codex/config.toml";
in {
  programs.codex = {
    enable = true;
    package = codex;
    inherit settings;
  };

  # Codex writes to config.toml at runtime, so it must stay a real file rather
  # than a read-only store symlink; the activation step below merges instead.
  home.file.".codex/config.toml".enable = lib.mkForce false;

  home.activation.codexMergeConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${python}/bin/python ${./merge-config.py} \
      ${lib.escapeShellArg configPath} ${managedConfig}
  '';

  # Stable path the codex wrapper advertises, so macOS permissions survive updates
  home.file.".local/bin/codex".source = "${codex}/bin/codex";
}
