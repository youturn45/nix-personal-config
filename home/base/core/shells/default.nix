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
in {
  # only works in bash/zsh, not nushell
  home.shellAliases = shellAliases;

  programs.nushell = {
    enable = true;
    package = pkgs-unstable.nushell;
    configFile.source = ./config.nu;
    inherit shellAliases;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:${localBin}:${goBin}:${rustBin}"
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initExtra = ''
      export PATH="$PATH:${localBin}:${goBin}:${rustBin}"
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
