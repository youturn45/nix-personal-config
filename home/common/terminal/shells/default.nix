{
  config,
  lib,
  pkgs,
  pkgs-stable,
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
    if pkgs-stable.stdenv.isLinux
    then baseAliases // nixosAliases
    else baseAliases;

  proxyCfg = config.youturn.proxy;
  proxyHelper = import ./proxy-helper.nix {inherit pkgs;};
  localBin = "${config.home.homeDirectory}/.local/bin";
  goBin = "${config.home.homeDirectory}/go/bin";
  rustBin = "${config.home.homeDirectory}/.cargo/bin";
in {
  options.youturn.proxy = {
    default = lib.mkOption {
      type = lib.types.enum ["off" "local" "network"];
      default =
        if pkgs.stdenv.isDarwin
        then "local"
        else "off";
      description = "Explicit shell proxy startup policy; unavailable proxies never select direct mode.";
    };
    localHttp = lib.mkOption {
      type = lib.types.strMatching ".+";
      default = "http://127.0.0.1:7890";
    };
    localSocks = lib.mkOption {
      type = lib.types.strMatching ".+";
      default = "socks5://127.0.0.1:7891";
    };
    networkHttp = lib.mkOption {
      type = lib.types.strMatching ".+";
      default = "http://10.0.0.3:7890";
    };
    networkSocks = lib.mkOption {
      type = lib.types.strMatching ".+";
      default = "socks5://10.0.0.3:7891";
    };
  };

  config = {
    home.shellAliases = shellAliases;

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      initContent =
        ''
          export PATH="$PATH:${localBin}:${goBin}:${rustBin}"
        ''
        + builtins.readFile ./.zshrc
        + ''
          _YOUTURN_PROXY_HELPER=${lib.escapeShellArg (toString proxyHelper)}
          PROXY_LOCAL_HTTP=${lib.escapeShellArg proxyCfg.localHttp}
          PROXY_LOCAL_SOCKS=${lib.escapeShellArg proxyCfg.localSocks}
          PROXY_NETWORK_HTTP=${lib.escapeShellArg proxyCfg.networkHttp}
          PROXY_NETWORK_SOCKS=${lib.escapeShellArg proxyCfg.networkSocks}
        ''
        + builtins.readFile ./proxy.zsh
        + ''
          _proxy_startup ${lib.escapeShellArg proxyCfg.default}
        '';

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
  };
}
