{lib, ...}: let
  # Keep Homebrew on upstream by default. Mirror state can become stale enough
  # to break cask API parsing during nix-darwin activation.
  allKeys = [
    "HOMEBREW_API_DOMAIN"
    "HOMEBREW_BOTTLE_DOMAIN"
    "HOMEBREW_BREW_GIT_REMOTE"
    "HOMEBREW_CORE_GIT_REMOTE"
    "HOMEBREW_NO_INSTALL_FROM_API"
    "HOMEBREW_PIP_INDEX_URL"
  ];
  mkUnsets = lib.concatMapStrings (name: "unset ${name}\n") allKeys;
in {
  # Proxy set + reachable → origin via proxy.
  # No proxy, or proxy unreachable → origin without mirror environment.
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
      else
        echo >&2 "homebrew-proxy: proxy unreachable, using origin servers without proxy"
        ${mkUnsets}
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
      fi
    else
      echo >&2 "homebrew-proxy: no proxy, using origin servers"
      ${mkUnsets}
    fi
  '';
}
