{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  shellAliases = {
    k = "kubectl";

    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };

  localBin = "${config.home.homeDirectory}/.local/bin";
  goBin = "${config.home.homeDirectory}/go/bin";
  rustBin = "${config.home.homeDirectory}/.cargo/bin";
  claudeCodeDir = "${config.home.homeDirectory}/.local/share/claude-code";
in {
  home.shellAliases = shellAliases;

  # Add Node.js and npm to the environment
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initExtra = ''
      export PATH="$PATH:${localBin}:${goBin}:${rustBin}"
      
      # Install claude-code locally if not already installed
      if [ ! -d "${claudeCodeDir}/node_modules/.bin" ]; then
        mkdir -p "${claudeCodeDir}"
        cd "${claudeCodeDir}"
        npm install @anthropic-ai/claude-code
      fi
      export PATH="${claudeCodeDir}/node_modules/.bin:$PATH"
    '' + builtins.readFile ./.zshrc;

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-completions"; }
        { name = "zdharma-continuum/fast-syntax-highlighting"; }
        { name = "zsh-users/zsh-history-substring-search"; }
        { name = "Aloxaf/fzf-tab"; }
      ];
    };
  };
}
