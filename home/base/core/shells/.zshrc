eval "$(starship init zsh)"

# used for homebrew
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/opt/homebrew/share

function proxy_on() {
    # CLASH Settings    
    export https_proxy=http://127.0.0.1:7890 
    export http_proxy=http://127.0.0.1:7890
    # export all_proxy=socks5://127.0.0.1:7890
    echo -e "终端代理已开启。"
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}

function proxy_off(){
    unset http_proxy https_proxy all_proxy
    echo -e "终端代理已关闭。"
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}

function show_proxy() {
    echo -e "当前代理设置："
    echo -e "http_proxy: ${http_proxy:-未设置}"
    echo -e "https_proxy: ${https_proxy:-未设置}"
    echo -e "all_proxy: ${all_proxy:-未设置}"
}