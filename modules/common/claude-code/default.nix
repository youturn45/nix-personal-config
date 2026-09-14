# Nix-owned Claude Code permissions, installed as system-level managed settings.
# Claude Code unions permissions.allow across settings scopes, so these rules
# stack with ~/.claude/settings.json, which stays fully writable ("Always allow",
# /model, /config keep working). Only put list-valued keys here: scalar keys in
# managed settings (model, effortLevel, env) cannot be overridden by the user.
{
  config,
  lib,
  myvars,
  pkgs-stable,
  ...
}: let
  inherit (pkgs-stable.stdenv) isDarwin;
  homeDirectory = config.users.users.${myvars.username}.home;

  managedSettings = {
    permissions.allow = [
      "Bash(cat *)"
      "Bash(ls *)"
      "Bash(ll *)"
      "Bash(head *)"
      "Bash(tail *)"
      "Bash(wc *)"
      "Bash(grep *)"
      "Bash(rg *)"
      "Bash(find *)"
      "Bash(fd *)"
      "Bash(tree *)"
      "Bash(stat *)"
      "Bash(file *)"
      "Bash(du *)"
      "Bash(diff *)"
      "Bash(sort *)"
      "Bash(uniq *)"
      "Bash(cut *)"
      "Bash(awk *)"
      "Bash(sed *)"
      "Bash(jq *)"
      "Bash(yq *)"
      "Bash(echo *)"
      "Bash(printf *)"
      "Bash(which *)"
      "Bash(whereis *)"
      "Bash(pwd)"
      "Bash(whoami)"
      "Bash(id)"
      "Bash(hostname)"
      "Bash(uname *)"
      "Bash(date *)"
      "Bash(env)"
      "Bash(printenv *)"
      "Bash(git status)"
      "Bash(git status *)"
      "Bash(git log *)"
      "Bash(git diff *)"
      "Bash(git branch *)"
      "Bash(git show *)"
      "Bash(git blame *)"
      "Bash(git ls-files *)"
      "Bash(git remote *)"
      "Bash(git tag *)"
      "Bash(git stash list)"
      "Bash(git config --list)"
      "Bash(git config --get *)"
      "Bash(launchctl list *)"
      "Bash(launchctl getenv *)"
      "Bash(launchctl print *)"
      "Bash(git -C * status *)"
      "Bash(git -C * log *)"
      "Bash(git -C * diff *)"
      "Bash(git -C * show *)"
      "Bash(git -C * remote *)"
      "Bash(git -C * config *)"
      "Bash(git -C * branch *)"
      "Bash(nix eval *)"
      "Bash(nix flake check *)"
      "Bash(nix search *)"
      "Bash(nix-env *)"
      "Bash(home-manager generations *)"
      "WebSearch(*)"
      "WebFetch(*)"
      "Read(//nix/store/**)"
      "Read(~/.config/**)"
      "Read(~/.nix-profile/etc/**)"
      "Read(~/.local/state/nix/profiles/**)"
      "Read(//opt/homebrew/etc/**)"
      "Bash(git -C /opt/homebrew remote *)"
      "Bash(git -C /opt/homebrew config --list)"
      "Bash(/opt/homebrew/bin/brew shellenv *)"
      "Bash(env -i HOME=${homeDirectory} PATH=/opt/homebrew/bin:/usr/bin:/bin brew --version)"
    ];
  };

  managedSettingsFile = (pkgs-stable.formats.json {}).generate "claude-code-managed-settings.json" managedSettings;
  darwinSettingsDir = "/Library/Application Support/ClaudeCode";
in {
  config = lib.mkMerge [
    (lib.mkIf isDarwin {
      # nix-darwin's environment.etc only targets /etc, so copy on activation.
      # 0644 matters: an unreadable managed-settings file blocks Claude Code startup.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "installing Claude Code managed settings..." >&2
        mkdir -p "${darwinSettingsDir}"
        /usr/bin/install -m 0644 ${managedSettingsFile} "${darwinSettingsDir}/managed-settings.json"
      '';
    })
    (lib.mkIf (!isDarwin) {
      environment.etc."claude-code/managed-settings.json".source = managedSettingsFile;
    })
  ];
}
