# Starship is managed by Home Manager (programs.starship.enableZshIntegration = true)

# Ghostty compatibility: fall back to a known terminfo
if [[ "$TERM" == "xterm-ghostty" ]]; then
    export TERM="xterm-256color"
fi

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
PROXY_NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,*.local"

function proxy() {
    local cmd="${1:-help}"

    case "$cmd" in
        on)
            local mode="${2:-local}"
            local proxy_http proxy_socks label
            if [[ "$mode" == "local" ]]; then
                proxy_http="$PROXY_LOCAL_HTTP"
                proxy_socks="$PROXY_LOCAL_SOCKS"
                label="local (127.0.0.1)"
            elif [[ "$mode" == "network" ]]; then
                proxy_http="$PROXY_NETWORK_HTTP"
                proxy_socks="$PROXY_NETWORK_SOCKS"
                label="network (10.0.0.5)"
            else
                printf "Error: invalid mode '%s'. Use 'local' or 'network'.\n" "$mode"
                return 1
            fi
            export http_proxy="$proxy_http"
            export https_proxy="$proxy_http"
            export HTTP_PROXY="$proxy_http"
            export HTTPS_PROXY="$proxy_http"
            export all_proxy="$proxy_socks"
            export ALL_PROXY="$proxy_socks"
            export no_proxy="$PROXY_NO_PROXY"
            export NO_PROXY="$PROXY_NO_PROXY"
            printf "Proxy enabled — %s\n" "$label"
            printf "  HTTP:  %s\n" "$proxy_http"
            printf "  SOCKS: %s\n" "$proxy_socks"
            ;;
        off)
            unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
            unset all_proxy ALL_PROXY
            unset no_proxy NO_PROXY
            printf "Proxy disabled.\n"
            ;;
        show)
            if [[ -n "$http_proxy" ]]; then
                printf "Proxy: enabled\n"
                printf "  HTTP:  %s\n" "$http_proxy"
                printf "  HTTPS: %s\n" "$https_proxy"
                printf "  SOCKS: %s\n" "$all_proxy"
                printf "  Skip:  %s\n" "$no_proxy"
            else
                printf "Proxy: disabled\n"
            fi
            ;;
        test)
            if [[ -z "$http_proxy" ]]; then
                printf "Proxy is not enabled. Run 'proxy on' first.\n"
                return 1
            fi
            printf "Testing connection through %s ...\n" "$http_proxy"
            if curl -sf --max-time 5 --proxy "$http_proxy" https://www.google.com > /dev/null 2>&1; then
                printf "Connection successful.\n"
            else
                printf "Connection failed.\n"
                return 1
            fi
            ;;
        help|*)
            printf "Usage: proxy <command> [options]\n\n"
            printf "Commands:\n"
            printf "  on [local|network]  Enable proxy (default: local)\n"
            printf "  off                 Disable proxy\n"
            printf "  show                Show current proxy status\n"
            printf "  test                Test proxy connectivity\n"
            printf "  help                Show this help message\n"
            ;;
    esac
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
