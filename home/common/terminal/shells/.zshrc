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
    bindkey "^?" backward-delete-char
    bindkey "^H" backward-delete-char
    bindkey "\177" backward-delete-char
    bindkey "\b" backward-delete-char
    bindkey "\e[3~" delete-char
    bindkey "^[[3~" delete-char
    bindkey "^[3;5~" delete-char
    bindkey "^[[P" delete-char

    # Navigation keys
    bindkey "^[[H" beginning-of-line
    bindkey "^[[F" end-of-line
    bindkey "^[[1~" beginning-of-line
    bindkey "^[[4~" end-of-line

    stty erase '^?'
    stty werase '^W'
fi

# Proxy functions and the single platform-aware startup selection are injected
# by default.nix. Do not auto-enable proxy here.

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
