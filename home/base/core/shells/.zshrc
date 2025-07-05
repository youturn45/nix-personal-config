# Starship is managed by Home Manager (programs.starship.enableZshIntegration = true)

# Homebrew initialization
eval "$(/opt/homebrew/bin/brew shellenv)"
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
    export all_proxy=socks5://127.0.0.1:7891
    export ALL_PROXY=socks5://127.0.0.1:7891
    
    printf "终端代理已开启。\n"
    printf "当前代理设置：\n"
    printf "http_proxy: %s\n" "${http_proxy:-未设置}"
    printf "https_proxy: %s\n" "${https_proxy:-未设置}"
    printf "HTTP_PROXY: %s\n" "${HTTP_PROXY:-未设置}"
    printf "HTTPS_PROXY: %s\n" "${HTTPS_PROXY:-未设置}"
    printf "all_proxy: %s\n" "${all_proxy:-未设置}"
    printf "ALL_PROXY: %s\n" "${ALL_PROXY:-未设置}"
}

function proxy_off(){
    # Unset lowercase proxy variables
    unset http_proxy https_proxy all_proxy
    # Unset uppercase proxy variables
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    
    printf "终端代理已关闭。\n"
    printf "当前代理设置：\n"
    printf "http_proxy: %s\n" "${http_proxy:-未设置}"
    printf "https_proxy: %s\n" "${https_proxy:-未设置}"
    printf "HTTP_PROXY: %s\n" "${HTTP_PROXY:-未设置}"
    printf "HTTPS_PROXY: %s\n" "${HTTPS_PROXY:-未设置}"
    printf "all_proxy: %s\n" "${all_proxy:-未设置}"
    printf "ALL_PROXY: %s\n" "${ALL_PROXY:-未设置}"
}

function show_proxy() {
    printf "当前代理设置：\n"
    printf "http_proxy: %s\n" "${http_proxy:-未设置}"
    printf "https_proxy: %s\n" "${https_proxy:-未设置}"
    printf "HTTP_PROXY: %s\n" "${HTTP_PROXY:-未设置}"
    printf "HTTPS_PROXY: %s\n" "${HTTPS_PROXY:-未设置}"
    printf "all_proxy: %s\n" "${all_proxy:-未设置}"
    printf "ALL_PROXY: %s\n" "${ALL_PROXY:-未设置}"
}

function show_ip() {
    curl ip.im/info
}