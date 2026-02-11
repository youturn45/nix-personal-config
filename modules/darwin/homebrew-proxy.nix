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

  proxy_default = "http://127.0.0.1:7890";
  mirror_probe_url = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
in {
  # Mirror env vars for interactive `brew` use in new shells
  environment.variables = mirror_env;

  # Inject mirror-with-fallback + proxy into the homebrew activation script
  # Order: probe mirror raw (domestic, no proxy) → fallback to origin via proxy
  system.activationScripts.homebrew.text = lib.mkBefore ''
    _PROXY="''${http_proxy:-${proxy_default}}"

    # Helper to enable proxy (only needed for international/origin servers)
    _enable_proxy() {
      export http_proxy="$_PROXY"
      export https_proxy="$_PROXY"
      export HTTP_PROXY="$_PROXY"
      export HTTPS_PROXY="$_PROXY"
      export no_proxy="localhost,127.0.0.1,::1"
      export NO_PROXY="localhost,127.0.0.1,::1"
      echo >&2 "homebrew-proxy: proxy enabled ($_PROXY)"
    }

    # --- homebrew-proxy: probe mirror BEFORE proxy (domestic, directly reachable) ---
    if /usr/bin/curl -sfL --max-time 5 -o /dev/null "${mirror_probe_url}"; then
      echo >&2 "homebrew-proxy: mirror reachable, enabling Tsinghua mirror"
      ${mirror_env_exports}
      # Wrapper: on per-package failure, enable proxy + unset mirror, retry with origin
      brew() {
        local real_brew
        real_brew="$(/usr/bin/which brew)"
        if ! "$real_brew" "$@"; then
          echo >&2 "homebrew-proxy: mirror failed, retrying with origin + proxy..."
          ${mirror_env_unsets}
          _enable_proxy
          "$real_brew" "$@"
        fi
      }
    else
      echo >&2 "homebrew-proxy: mirror unreachable, using origin servers with proxy"
      ${mirror_env_unsets}
      _enable_proxy
    fi
  '';
}
