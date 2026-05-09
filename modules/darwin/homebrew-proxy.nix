{lib, ...}: let
  # Tsinghua University mirror for Homebrew (faster in China)
  mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };

  mirror_env_exports =
    lib.attrsets.foldlAttrs
    (acc: name: value: acc + "export ${name}=${value}\n")
    ""
    mirror_env;

  mirror_env_unsets =
    lib.attrsets.foldlAttrs
    (acc: name: _: acc + "unset ${name}\n")
    ""
    mirror_env;

in {
  # Inject proxy-or-mirror logic into the homebrew activation script
  # Proxy set in env → origin servers via proxy; no proxy → TUNA mirror directly
  system.activationScripts.homebrew.text = lib.mkBefore ''
    _PROXY="''${http_proxy:-''${HTTP_PROXY:-}}"

    if [ -n "$_PROXY" ]; then
      _PROXY_ADDR="''${_PROXY#http://}"
      _PROXY_HOST="''${_PROXY_ADDR%:*}"
      _PROXY_PORT="''${_PROXY_ADDR##*:}"
      if /usr/bin/nc -z "$_PROXY_HOST" "$_PROXY_PORT" 2>/dev/null; then
        echo >&2 "homebrew-proxy: proxy available ($_PROXY), using origin servers"
        ${mirror_env_unsets}
        export http_proxy="$_PROXY" https_proxy="$_PROXY" HTTP_PROXY="$_PROXY" HTTPS_PROXY="$_PROXY"
        export no_proxy="localhost,127.0.0.1,::1" NO_PROXY="localhost,127.0.0.1,::1"
      else
        echo >&2 "homebrew-proxy: proxy set but unreachable, using Tsinghua mirror"
        ${mirror_env_exports}
      fi
    else
      echo >&2 "homebrew-proxy: no proxy set, using Tsinghua mirror"
      ${mirror_env_exports}
    fi
  '';
}
