{
  lib,
  pkgs-stable,
  claude-code,
  ...
}: let
  claude-code-package = claude-code.packages.${pkgs-stable.stdenv.hostPlatform.system}.default;

  # Defaults for ~/.claude/settings.json. Permissions live in managed settings
  # (modules/common/claude-code); everything in this file belongs to Claude Code.
  settingsJson = builtins.toJSON {
    env = {
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
  };
  settingsFile = pkgs-stable.writeText "claude-settings-defaults.json" settingsJson;
in {
  programs.claude-code = {
    enable = true;
    package = claude-code-package;
  };

  home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;

  # All hook scripts deployed automatically — just add a script to hooks/ and it's live
  home.file.".claude/hooks" = {
    source = ./hooks;
    recursive = true;
  };

  # Slash commands
  home.file.".claude/commands" = {
    source = ./commands;
    recursive = true;
  };

  # Required empty directories for Claude Code's internal state
  home.file.".claude/.keep".text = "";
  home.file.".claude/projects/.keep".text = "";
  home.file.".claude/todos/.keep".text = "";
  home.file.".claude/statsig/.keep".text = "";
  home.file.".claude/commands/.keep".text = "";
  # Skills directory — not managed as a symlink so Claude can install skills freely at runtime
  home.file.".claude/skills/.keep".text = "";

  # settings.json stays a real, Claude-owned file. Nix only fills in missing
  # defaults (deep merge, the live file wins), so /model, /config and
  # "Always allow" edits survive rebuilds.
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    if [ -f "$_settings" ] && [ ! -L "$_settings" ]; then
      _tmp="$(mktemp)"
      ${pkgs-stable.jq}/bin/jq -s '.[1] * .[0]' "$_settings" ${settingsFile} > "$_tmp" && mv "$_tmp" "$_settings"
    else
      rm -f "$_settings"
      cat ${settingsFile} > "$_settings"
    fi
  '';

  # Merge Claude runtime config into ~/.claude.json without replacing it —
  # Claude Code writes auth tokens there, so we can't manage it as a read-only symlink
  home.activation.claudeRuntimeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _claude_json="$HOME/.claude.json"
    _tmp="$(mktemp)"
    if [ -f "$_claude_json" ]; then
      ${pkgs-stable.jq}/bin/jq '. + {"teammateMode": "tmux"}' "$_claude_json" > "$_tmp" && mv "$_tmp" "$_claude_json"
    else
      echo '{"teammateMode": "tmux"}' > "$_claude_json"
    fi
  '';
}
