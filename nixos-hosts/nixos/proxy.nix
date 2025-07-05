{ ... }:

{
  # System-wide proxy environment variables (matching your zsh proxy_on function)
  environment.variables = {
    http_proxy = "http://10.0.0.5:7890";
    https_proxy = "http://10.0.0.5:7890";
    all_proxy = "socks5://10.0.0.5:7891";
    HTTP_PROXY = "http://10.0.0.5:7890";
    HTTPS_PROXY = "http://10.0.0.5:7890";
    ALL_PROXY = "socks5://10.0.0.5:7891";
    no_proxy = "localhost,127.0.0.1,::1";
    NO_PROXY = "localhost,127.0.0.1,::1";
  };

  # Ensure sudo preserves proxy environment variables
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY"
    Defaults env_keep += "no_proxy NO_PROXY"
  '';

  # Add proxy management functions to system-wide shell configuration
  environment.shellInit = ''
    # Proxy management functions (matching your zsh configuration)
    proxy_on() {
      export http_proxy="http://10.0.0.5:7890"
      export https_proxy="http://10.0.0.5:7890"
      export all_proxy="socks5://10.0.0.5:7891"
      export HTTP_PROXY="http://10.0.0.5:7890"
      export HTTPS_PROXY="http://10.0.0.5:7890"
      export ALL_PROXY="socks5://10.0.0.5:7891"
      echo "代理已开启"
    }

    proxy_off() {
      unset http_proxy
      unset https_proxy
      unset all_proxy
      unset HTTP_PROXY
      unset HTTPS_PROXY
      unset ALL_PROXY
      echo "代理已关闭"
    }

    show_proxy() {
      echo "http_proxy: $http_proxy"
      echo "https_proxy: $https_proxy"
      echo "all_proxy: $all_proxy"
      echo "HTTP_PROXY: $HTTP_PROXY"
      echo "HTTPS_PROXY: $HTTPS_PROXY"
      echo "ALL_PROXY: $ALL_PROXY"
    }

    show_ip() {
      curl ip.im/info
    }
  '';
}