{lib, ...}: let
  # SJTUG (Shanghai Jiao Tong University) mirror — primary
  # Note: SJTUG does not provide HOMEBREW_API_DOMAIN; NO_INSTALL_FROM_API forces git-based installs
  sjtu_env = {
    HOMEBREW_NO_INSTALL_FROM_API = "1";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirror.sjtu.edu.cn/homebrew-bottles/bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.sjtug.sjtu.edu.cn/git/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.sjtug.sjtu.edu.cn/git/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://mirror.sjtu.edu.cn/pypi/web/simple";
  };

  # Tsinghua (TUNA) mirror — secondary fallback
  tuna_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };

  mkExports = lib.attrsets.foldlAttrs
    (acc: name: value: acc + "export ${name}=${value}\n")
    "";

  # Unsets for all vars across both mirror sets (union of keys)
  allKeys = lib.attrNames (sjtu_env // tuna_env);
  mkUnsets = lib.concatMapStrings (name: "unset ${name}\n") allKeys;

  sjtu_exports = mkExports sjtu_env;
  tuna_exports = mkExports tuna_env;

in {
  # Proxy set + reachable → origin via proxy
  # No proxy (or unreachable) → try SJTU first, fall back to TUNA
  system.activationScripts.homebrew.text = lib.mkBefore ''
    _PROXY="''${http_proxy:-''${HTTP_PROXY:-}}"

    if [ -n "$_PROXY" ]; then
      _PROXY_ADDR="''${_PROXY#http://}"
      _PROXY_HOST="''${_PROXY_ADDR%:*}"
      _PROXY_PORT="''${_PROXY_ADDR##*:}"
      if /usr/bin/nc -z "$_PROXY_HOST" "$_PROXY_PORT" 2>/dev/null; then
        echo >&2 "homebrew-proxy: proxy available ($_PROXY), using origin servers"
        ${mkUnsets}
        export http_proxy="$_PROXY" https_proxy="$_PROXY" HTTP_PROXY="$_PROXY" HTTPS_PROXY="$_PROXY"
        export no_proxy="localhost,127.0.0.1,::1" NO_PROXY="localhost,127.0.0.1,::1"
      elif /usr/bin/nc -z mirror.sjtu.edu.cn 443 2>/dev/null; then
        echo >&2 "homebrew-proxy: proxy unreachable, SJTU available — using SJTU mirror"
        ${sjtu_exports}
      else
        echo >&2 "homebrew-proxy: proxy and SJTU unreachable, falling back to Tsinghua mirror"
        ${tuna_exports}
      fi
    elif /usr/bin/nc -z mirror.sjtu.edu.cn 443 2>/dev/null; then
      echo >&2 "homebrew-proxy: no proxy, SJTU available — using SJTU mirror"
      ${sjtu_exports}
    else
      echo >&2 "homebrew-proxy: no proxy, SJTU unreachable — falling back to Tsinghua mirror"
      ${tuna_exports}
    fi
  '';
}
