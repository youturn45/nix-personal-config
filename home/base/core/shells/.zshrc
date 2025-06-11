eval "$(starship init zsh)"

# used for homebrew
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/opt/homebrew/share

function proxy_on() {
    # CLASH Settings    
    # Lowercase proxy settings
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    # Uppercase proxy settings
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    # Optional SOCKS proxy
    # export all_proxy=socks5://127.0.0.1:7890
    # export ALL_PROXY=socks5://127.0.0.1:7890
    
    echo -e "终端代理已开启。"
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "HTTP_PROXY: ${HTTP_PROXY:-未设置}"
    echo -e "HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}

function proxy_off(){
    # Unset lowercase proxy variables
    unset http_proxy https_proxy all_proxy
    # Unset uppercase proxy variables
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    
    echo -e "终端代理已关闭。"
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "HTTP_PROXY: ${HTTP_PROXY:-未设置}"
    echo -e "HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}

function show_proxy() {
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "HTTP_PROXY: ${HTTP_PROXY:-未设置}"
    echo -e "HTTPS_PROXY: ${HTTPS_PROXY:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}

function show_ip() {
    curl ip.im/info
}