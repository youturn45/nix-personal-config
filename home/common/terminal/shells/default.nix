{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  # Base aliases for all platforms
  baseAliases = {
    k = "kubectl";
    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };

  # Platform-specific aliases
  nixosAliases = {
    rebuild = "sudo nixos-rebuild switch";
    rebuild-test = "sudo nixos-rebuild test";
  };

  # Combine aliases based on platform
  shellAliases =
    if pkgs.stdenv.isLinux
    then baseAliases // nixosAliases
    else baseAliases;

  localBin = "${config.home.homeDirectory}/.local/bin";
  goBin = "${config.home.homeDirectory}/go/bin";
  rustBin = "${config.home.homeDirectory}/.cargo/bin";
in {
  home.shellAliases = shellAliases;

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    initContent =
      ''
        export PATH="$PATH:${localBin}:${goBin}:${rustBin}"
      ''
      + builtins.readFile ./.zshrc;

    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-users/zsh-autosuggestions";}
        {name = "zsh-users/zsh-completions";}
        {name = "zdharma-continuum/fast-syntax-highlighting";}
        {name = "zsh-users/zsh-history-substring-search";}
        {name = "Aloxaf/fzf-tab";}
      ];
    };
  };
}
