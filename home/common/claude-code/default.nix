{
  lib,
  pkgs,
  ...
}: {
  # All Claude Code settings inlined — no separate settings.json file needed
  home.file.".claude/settings.json".text = builtins.toJSON {
    hooks = {};
    env = {
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
    permissions = {
      allow = [
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
      ];
    };
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

  # Merge Claude runtime config into ~/.claude.json without replacing it —
  # Claude Code writes auth tokens there, so we can't manage it as a read-only symlink
  home.activation.claudeRuntimeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _claude_json="$HOME/.claude.json"
    _tmp="$(mktemp)"
    if [ -f "$_claude_json" ]; then
      ${pkgs.jq}/bin/jq '. + {"teammateMode": "tmux"}' "$_claude_json" > "$_tmp" && mv "$_tmp" "$_claude_json"
    else
      echo '{"teammateMode": "tmux"}' > "$_claude_json"
    fi
  '';

  # Install Claude Code on activation (requires Node.js from nodejs module)
  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$HOME/.npm-global/bin:$PATH"

    echo "Installing or updating Claude Code..."
    rm -rf "$HOME/.npm-global/lib/node_modules/@anthropic-ai/.claude-code-"* 2>/dev/null || true
    npm install -g @anthropic-ai/claude-code@latest
  '';
}
