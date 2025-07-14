# Starship is managed by Home Manager (programs.starship.enableZshIntegration = true)

# Platform-specific initialization
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew initialization (Darwin only)
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:/opt/homebrew/share
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # NixOS-specific initialization
    export TERM="xterm-256color"
    
    # Fix key bindings for NixOS terminals
    bindkey "^?" backward-delete-char     # Mac delete key (DEL character)
    bindkey "^H" backward-delete-char     # Backspace (Ctrl+H)
    bindkey "\177" backward-delete-char   # DEL character (127) - Mac delete
    bindkey "\b" backward-delete-char     # Backspace alternative
    bindkey "\e[3~" delete-char           # Forward delete (fn+delete on Mac)
    bindkey "^[[3~" delete-char           # Forward delete alternative
    bindkey "^[3;5~" delete-char          # Ctrl+forward delete
    bindkey "^[[P" delete-char            # Forward delete alternative

    # Navigation keys
    bindkey "^[[H" beginning-of-line      # Home key
    bindkey "^[[F" end-of-line            # End key
    bindkey "^[[1~" beginning-of-line     # Home alternative
    bindkey "^[[4~" end-of-line           # End alternative

    # Set terminal options for compatibility
    stty erase '^?'
    stty werase '^W'
fi

# Proxy configuration presets
PROXY_LOCAL_HTTP="http://127.0.0.1:7890"
PROXY_LOCAL_SOCKS="socks5://127.0.0.1:7891"
PROXY_NETWORK_HTTP="http://10.0.0.5:7890"
PROXY_NETWORK_SOCKS="socks5://10.0.0.5:7891"

function proxy_on() {
    local mode="${1:-local}"  # Default to local if no argument provided
    
    if [[ "$mode" == "local" ]]; then
        # Local proxy settings (127.0.0.1)
        export http_proxy="$PROXY_LOCAL_HTTP"
        export https_proxy="$PROXY_LOCAL_HTTP"
        export HTTP_PROXY="$PROXY_LOCAL_HTTP"
        export HTTPS_PROXY="$PROXY_LOCAL_HTTP"
        export all_proxy="$PROXY_LOCAL_SOCKS"
        export ALL_PROXY="$PROXY_LOCAL_SOCKS"
        printf "本地代理已开启 (127.0.0.1)。\n"
    elif [[ "$mode" == "network" ]]; then
        # Network proxy settings (10.0.0.5)
        export http_proxy="$PROXY_NETWORK_HTTP"
        export https_proxy="$PROXY_NETWORK_HTTP"
        export HTTP_PROXY="$PROXY_NETWORK_HTTP"
        export HTTPS_PROXY="$PROXY_NETWORK_HTTP"
        export all_proxy="$PROXY_NETWORK_SOCKS"
        export ALL_PROXY="$PROXY_NETWORK_SOCKS"
        printf "网络代理已开启 (10.0.0.5)。\n"
    else
        printf "错误: 无效的代理模式。使用 'local' 或 'network'。\n"
        printf "用法: proxy_on [local|network]\n"
        return 1
    fi
    
    printf "当前代理设置：\n"
    printf "  HTTP  代理: $http_proxy\n"
    printf "  HTTPS 代理: $https_proxy\n"
    printf "  SOCKS 代理: $all_proxy\n"
}

function proxy_off() {
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY
    
    printf "终端代理已关闭。\n"
}

function proxy_status() {
    if [ -n "$http_proxy" ]; then
        printf "代理状态: 已开启\n"
        printf "  HTTP  代理: $http_proxy\n"
        printf "  HTTPS 代理: $https_proxy\n"
        printf "  SOCKS 代理: $all_proxy\n"
    else
        printf "代理状态: 已关闭\n"
    fi
}

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Enhanced ls (assuming exa is available via Home Manager)
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# System shortcuts
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safe rm
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'