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
    # Desktop banners from inside tmux (see hooks/tmux-notify.sh)
    hooks.Notification = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/tmux-notify.sh";
          }
        ];
      }
    ];
  };
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
  # Stop app/config writers during activation: atomic replace is not a lock.
  # run guards the whole helper, including redirection, mkdir and temp files.
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs-stable.python3}/bin/python3 ${./merge-settings.py} \
      defaults "$HOME/.claude/settings.json" ${lib.escapeShellArg settingsJson}
  '';

  # Force only teammateMode; all other runtime state remains Claude-owned.
  home.activation.claudeRuntimeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs-stable.python3}/bin/python3 ${./merge-settings.py} \
      runtime "$HOME/.claude.json"
  '';
}
